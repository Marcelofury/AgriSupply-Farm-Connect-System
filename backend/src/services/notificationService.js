import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase.dart';
import '../utils/logger.dart';

/**
 * Firebase Admin SDK for Push Notifications
 * 
 * Note: You need to install firebase-admin package:
 * npm install firebase-admin
 * 
 * And set up Firebase service account credentials in your environment
 */

// Firebase Admin initialization (add this to index.js or a separate firebase-admin.js file)
// const admin = require('firebase-admin');
// const serviceAccount = require('./path-to-serviceAccountKey.json');
//
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

class NotificationService {
  /**
   * Send push notification via Firebase Cloud Messaging
   * @param {string} deviceToken - FCM device token
   * @param {Object} notification - Notification data
   * @returns {Promise<boolean>}
   */
  async sendPushNotification(deviceToken, notification) {
    try {
      // Using Firebase Admin SDK (recommended)
      if (typeof admin !== 'undefined' && admin.messaging) {
        const message = {
          token: deviceToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            type: notification.type || 'general',
            referenceId: notification.referenceId || '',
            ...notification.data,
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'default',
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().send(message);
        logger.info('Push notification sent successfully:', response);
        return true;
      }

      // Fallback: Using FCM REST API
      const fcmApiKey = process.env.FIREBASE_SERVER_KEY;
      if (!fcmApiKey) {
        throw new Error('Firebase server key not configured');
      }

      const response = await http.post(
        'https://fcm.googleapis.com/fcm/send',
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${fcmApiKey}`,
          },
          body: JSON.stringify({
            to: deviceToken,
            notification: {
              title: notification.title,
              body: notification.body,
              sound: 'default',
            },
            data: {
              type: notification.type || 'general',
              referenceId: notification.referenceId || '',
              ...notification.data,
            },
            priority: 'high',
          }),
        }
      );

      if (response.status === 200) {
        logger.info('Push notification sent via REST API');
        return true;
      } else {
        logger.error('FCM API error:', response.data);
        return false;
      }
    } catch (error) {
      logger.error('Send push notification error:', error);
      return false;
    }
  }

  /**
   * Send email notification
   * @param {string} email - Recipient email
   * @param {Object} emailData - Email content
   * @returns {Promise<boolean>}
   */
  async sendEmailNotification(email, emailData) {
    try {
      // Using SendGrid, Mailgun, or similar service
      const emailService = process.env.EMAIL_SERVICE; // 'sendgrid' or 'mailgun'
      
      if (emailService === 'sendgrid') {
        // SendGrid implementation
        const sgMail = require('@sendgrid/mail');
        sgMail.setApiKey(process.env.SENDGRID_API_KEY);

        const msg = {
          to: email,
          from: process.env.FROM_EMAIL || 'noreply@agrisupply.com',
          subject: emailData.subject,
          text: emailData.text,
          html: emailData.html,
        };

        await sgMail.send(msg);
        logger.info('Email sent successfully via SendGrid');
        return true;
      } else if (emailService === 'mailgun') {
        // Mailgun implementation
        const mailgun = require('mailgun-js')({
          apiKey: process.env.MAILGUN_API_KEY,
          domain: process.env.MAILGUN_DOMAIN,
        });

        const data = {
          from: process.env.FROM_EMAIL || 'AgriSupply <noreply@agrisupply.com>',
          to: email,
          subject: emailData.subject,
          text: emailData.text,
          html: emailData.html,
        };

        await mailgun.messages().send(data);
        logger.info('Email sent successfully via Mailgun');
        return true;
      } else {
        logger.warn('No email service configured');
        return false;
      }
    } catch (error) {
      logger.error('Send email notification error:', error);
      return false;
    }
  }

  /**
   * Send SMS notification
   * @param {string} phone - Phone number in E.164 format
   * @param {string} message - SMS message
   * @returns {Promise<boolean>}
   */
  async sendSMSNotification(phone, message) {
    try {
      const smsService = process.env.SMS_SERVICE; // 'twilio' or 'africas_talking'

      if (smsService === 'twilio') {
        // Twilio implementation
        const twilio = require('twilio');
        const client = twilio(
          process.env.TWILIO_ACCOUNT_SID,
          process.env.TWILIO_AUTH_TOKEN
        );

        await client.messages.create({
          body: message,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phone,
        });

        logger.info('SMS sent successfully via Twilio');
        return true;
      } else if (smsService === 'africas_talking') {
        // Africa's Talking implementation (popular in Uganda)
        const AfricasTalking = require('africastalking')({
          apiKey: process.env.AFRICAS_TALKING_API_KEY,
          username: process.env.AFRICAS_TALKING_USERNAME,
        });

        const sms = AfricasTalking.SMS;
        const result = await sms.send({
          to: [phone],
          message: message,
          from: process.env.AFRICAS_TALKING_SENDER_ID,
        });

        logger.info('SMS sent successfully via Africa\'s Talking:', result);
        return true;
      } else {
        logger.warn('No SMS service configured');
        return false;
      }
    } catch (error) {
      logger.error('Send SMS notification error:', error);
      return false;
    }
  }

  /**
   * Send notification to user based on their preferences
   * @param {string} userId - User ID
   * @param {Object} notification - Notification content
   * @returns {Promise<void>}
   */
  async sendNotificationToUser(userId, notification) {
    try {
      // Get user's notification preferences
      const { data: preferences } = await supabase
        .from('notification_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: user } = await supabase
        .from('users')
        .select('email, phone')
        .eq('id', userId)
        .single();

      // Send push notification if enabled
      if (preferences?.push_enabled) {
        const { data: devices } = await supabase
          .from('user_devices')
          .select('device_token')
          .eq('user_id', userId);

        for (const device of devices || []) {
          await this.sendPushNotification(device.device_token, notification);
        }
      }

      // Send email if enabled
      if (preferences?.email_enabled && user?.email) {
        await this.sendEmailNotification(user.email, {
          subject: notification.title,
          text: notification.body,
          html: `<h2>${notification.title}</h2><p>${notification.body}</p>`,
        });
      }

      // Send SMS if enabled
      if (preferences?.sms_enabled && user?.phone) {
        await this.sendSMSNotification(
          user.phone,
          `${notification.title}: ${notification.body}`
        );
      }
    } catch (error) {
      logger.error('Send notification to user error:', error);
    }
  }
}

module.exports = new NotificationService();

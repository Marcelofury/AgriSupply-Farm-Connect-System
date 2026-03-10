const multer = require('multer');

/**
 * Optional file upload middleware
 * Allows requests to pass through even if no files are uploaded
 * This handles both multipart/form-data and application/json content types
 */
const optionalUploadMultiple = (fieldName = 'files', maxCount = 5) => {
  return (req, res, next) => {
    const contentType = req.get('Content-Type') || '';
    
    // If it's not multipart, skip multer and continue
    if (!contentType.includes('multipart/form-data')) {
      return next();
    }
    
    // Otherwise, use multer to handle the multipart upload
    const upload = multer({
      storage: multer.memoryStorage(),
      fileFilter: (req, file, cb) => {
        const constants = require('../config/constants');
        if (constants.upload.allowedTypes.includes(file.mimetype)) {
          cb(null, true);
        } else {
          cb(new Error(`Invalid file type. Allowed types: ${constants.upload.allowedTypes.join(', ')}`), false);
        }
      },
      limits: {
        fileSize: require('../config/constants').upload.maxFileSize,
        files: maxCount,
      },
    }).array(fieldName, maxCount);
    
    upload(req, res, next);
  };
};

module.exports = {
  ...require('./uploadMiddleware'),
  optionalUploadMultiple,
};

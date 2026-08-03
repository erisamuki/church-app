const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

async function sendPasswordResetEmail(toEmail, firstName, resetCode) {
  const mailOptions = {
    from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
    to: toEmail,
    subject: 'GraceHub - Password Reset Code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #EA580C;">Password Reset Request</h2>
        <p>Hi ${firstName || 'there'},</p>
        <p>We received a request to reset your GraceHub password. Use the code below in the app to set a new password:</p>
        <div style="background: #F1F5F9; padding: 16px; border-radius: 8px; text-align: center; margin: 20px 0;">
          <span style="font-size: 28px; font-weight: 700; letter-spacing: 4px; color: #1E293B;">${resetCode}</span>
        </div>
        <p>This code expires in 1 hour. If you didn't request this, you can safely ignore this email.</p>
        <p style="color: #94A3B8; font-size: 12px; margin-top: 32px;">GraceHub - Blessed Christian Church</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
}

module.exports = { sendPasswordResetEmail };
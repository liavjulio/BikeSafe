//bikesafe-backend/utils/emailSender.js
const sgMail = require('@sendgrid/mail');

// Set the SendGrid API key
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

/**
 * Sends a verification email to the specified recipient.
 * @param {string} recipientEmail - The recipient's email address.
 */
const sendVerificationEmail = async (recipientEmail, verificationCode) => {
  const msg = {
    to: recipientEmail, 
    from: process.env.FROM_EMAIL, 
    subject: 'Verify Your Account',
    text: `Your verification code is: ${verificationCode}`,
    html: `<strong>Your verification code is: ${verificationCode}</strong>`,
  };

  try {
    await sgMail.send(msg);
    console.log(`Verification email sent to ${recipientEmail}`);
  } catch (error) {
    console.error('Error sending email:', error.response ? error.response.body : error.message);
    throw new Error('Failed to send verification email');
  }
};

/**
 * Sends a password reset email to the specified recipient.
 * @param {string} recipientEmail - The recipient's email address.
 * @param {string} resetToken - The password reset token.
 */
const sendPasswordResetEmail = async (recipientEmail, resetToken) => {
  const resetLink = `http://<your-frontend-domain>/reset-password?token=${resetToken}`;
  const msg = {
    to: recipientEmail, // Recipient email
    from: process.env.FROM_EMAIL, // Sender email (must be verified in SendGrid)
    subject: 'Password Reset Request',
    text: `You requested a password reset. Use the following link to reset your password: ${resetLink}`,
    html: `
      <p>You requested a password reset. Use the following link to reset your password:</p>
      <a href="${resetLink}" target="_blank">Reset Password</a>
      <p>If you did not request this, please ignore this email.</p>
    `,
  };

  try {
    await sgMail.send(msg);
    console.log(`Password reset email sent to ${recipientEmail}`);
  } catch (error) {
    console.error('Error sending email:', error.response ? error.response.body : error.message);
    throw new Error('Failed to send password reset email');
  }
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
};
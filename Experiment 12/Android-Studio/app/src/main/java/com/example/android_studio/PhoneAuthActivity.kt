package com.example.android_studio

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.android_studio.databinding.ActivityPhoneAuthBinding
import com.google.firebase.FirebaseException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import java.util.concurrent.TimeUnit

class PhoneAuthActivity : AppCompatActivity() {

    private val TAG = "PhoneAuthActivity"
    private lateinit var binding: ActivityPhoneAuthBinding
    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore // Added Firestore

    private var storedVerificationId: String? = null
    private lateinit var resendingToken: PhoneAuthProvider.ForceResendingToken

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityPhoneAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance() // Initialize Firestore

        binding.btnSendOtp.setOnClickListener {
            sendOtp()
        }

        binding.btnVerifyOtp.setOnClickListener {
            verifyOtp()
        }
    }

    private fun sendOtp() {
        val phoneNumber = binding.etPhoneNumber.text.toString().trim()
        if (phoneNumber.isEmpty()) {
            Toast.makeText(this, "Please enter a phone number", Toast.LENGTH_SHORT).show()
            return
        }

        // --- FIX 1: Add a loading toast ---
        Toast.makeText(this, "Sending OTP, please wait...", Toast.LENGTH_SHORT).show()
        binding.btnSendOtp.isEnabled = false // Prevent re-clicking

        PhoneAuthProvider.getInstance().verifyPhoneNumber(
            phoneNumber,        // Phone number to verify
            60L,                // Timeout
            TimeUnit.SECONDS,   // Unit of timeout
            this,               // Activity (for callback)
            verificationCallbacks // OnVerificationStateChangedCallbacks
        )
    }

    private val verificationCallbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

        override fun onVerificationCompleted(credential: PhoneAuthCredential) {
            Log.d(TAG, "onVerificationCompleted:$credential")
            signInWithPhoneAuthCredential(credential)
        }

        override fun onVerificationFailed(e: FirebaseException) {
            Log.w(TAG, "onVerificationFailed", e)
            Toast.makeText(this@PhoneAuthActivity, "Verification failed: ${e.message}", Toast.LENGTH_LONG).show()
            binding.btnSendOtp.isEnabled = true
        }

        override fun onCodeSent(
            verificationId: String,
            token: PhoneAuthProvider.ForceResendingToken
        ) {
            Log.d(TAG, "onCodeSent:$verificationId")
            Toast.makeText(this@PhoneAuthActivity, "OTP Sent Successfully", Toast.LENGTH_SHORT).show()

            storedVerificationId = verificationId
            resendingToken = token

            // Show the OTP fields
            binding.etOtp.visibility = View.VISIBLE
            binding.btnVerifyOtp.visibility = View.VISIBLE
            binding.btnSendOtp.isEnabled = true
        }
    }

    private fun verifyOtp() {
        val otpCode = binding.etOtp.text.toString().trim()
        if (otpCode.isEmpty() || otpCode.length < 6) {
            Toast.makeText(this, "Please enter the 6-digit OTP", Toast.LENGTH_SHORT).show()
            return
        }

        if (storedVerificationId == null) {
            Toast.makeText(this, "Error: Verification ID is not set. Please send OTP again.", Toast.LENGTH_LONG).show()
            return
        }

        val credential = PhoneAuthProvider.getCredential(storedVerificationId!!, otpCode)
        signInWithPhoneAuthCredential(credential)
    }

    private fun signInWithPhoneAuthCredential(credential: PhoneAuthCredential) {
        auth.signInWithCredential(credential)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Sign in success
                    Log.d(TAG, "signInWithCredential:success")
                    val user = task.result?.user
                    Toast.makeText(this, "Login successful: ${user?.phoneNumber}", Toast.LENGTH_SHORT).show()

                    // --- FIX 2: Check if user is new, same as LoginActivity ---
                    val isNewUser = task.result?.additionalUserInfo?.isNewUser == true
                    if (isNewUser && user != null) {
                        // If new, save their phone number to Firestore
                        savePhoneUserToFirestore(user.uid, user.phoneNumber)
                    } else {
                        goToMainActivity() // Just go to main if they are a returning user
                    }
                } else {
                    // Sign in failed
                    Log.w(TAG, "signInWithCredential:failure", task.exception)
                    Toast.makeText(this, "Login failed: ${task.exception?.message}", Toast.LENGTH_LONG).show()
                }
            }
    }

    // --- NEW FUNCTION: Save new phone user to Firestore ---
    private fun savePhoneUserToFirestore(userId: String, phoneNumber: String?) {
        val userMap = hashMapOf(
            "fullName" to "", // No name provided yet
            "email" to "",    // No email provided
            "phone" to (phoneNumber ?: ""), // Save the phone number
            "dateOfBirth" to "",
            "gender" to ""
        )
        db.collection("users").document(userId)
            .set(userMap) // Use .set() to create or overwrite
            .addOnSuccessListener {
                Log.d(TAG, "New phone user saved to Firestore")
                goToMainActivity() // Now go to main
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Error saving new phone user", e)
                Toast.makeText(this, "Error saving user data. Logging in anyway.", Toast.LENGTH_SHORT).show()
                goToMainActivity() // Go to main anyway, but log the error
            }
    }

    // --- Helper function to navigate to MainActivity ---
    private fun goToMainActivity() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish() // Close PhoneAuthActivity
    }
}


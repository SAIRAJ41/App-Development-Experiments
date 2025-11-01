package com.example.android_studio

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.example.android_studio.databinding.ActivityLoginBinding
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore

class LoginActivity : AppCompatActivity() {

    private val TAG = "LoginActivity"
    private lateinit var binding: ActivityLoginBinding
    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore
    private lateinit var googleSignInClient: GoogleSignInClient

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()

        // --- Configure Google Sign-In ---
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(getString(R.string.default_web_client_id))
            .requestEmail()
            .build()
        googleSignInClient = GoogleSignIn.getClient(this, gso)
        // ------------------------------

        setupClickListeners()
    }

    // New Activity Result Launcher for Google Sign-In
    private val googleSignInLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            try {
                // Google Sign In was successful, authenticate with Firebase
                val account = task.getResult(ApiException::class.java)!!
                Log.d(TAG, "firebaseAuthWithGoogle:" + account.id)
                firebaseAuthWithGoogle(account.idToken!!)
            } catch (e: ApiException) {
                // Google Sign In failed
                Log.w(TAG, "Google sign in failed", e)
                Toast.makeText(this, "Google sign-in failed.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // Authenticate with Firebase using the Google ID token
    private fun firebaseAuthWithGoogle(idToken: String) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        auth.signInWithCredential(credential)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Sign in success
                    Log.d(TAG, "Google signInWithCredential:success")
                    val user = task.result?.user
                    if (user == null) {
                        Log.w(TAG, "User was null after successful sign in.")
                        Toast.makeText(this, "Login failed. Please try again.", Toast.LENGTH_SHORT).show()
                        return@addOnCompleteListener
                    }

                    // Check if this is a new user
                    val isNewUser = task.result?.additionalUserInfo?.isNewUser == true
                    if (isNewUser) {
                        // If new, save their Google name/email to Firestore
                        // Navigation happens *after* this save
                        saveGoogleUserToFirestore(user.uid, user.displayName, user.email)
                    } else {
                        // If returning user, navigate immediately
                        goToMainActivity()
                    }
                } else {
                    // Sign in failed
                    Log.w(TAG, "Google signInWithCredential:failure", task.exception)
                    Toast.makeText(this, "Firebase login failed: ${task.exception?.message}", Toast.LENGTH_SHORT).show()
                }
            }
    }

    // Save Google user's info to Firestore so Profile Page can read it
    private fun saveGoogleUserToFirestore(userId: String, fullName: String?, email: String?) {
        val userMap = hashMapOf(
            "fullName" to (fullName ?: "Google User"),
            "email" to (email ?: "No Email"),
            "phone" to "", // Google sign-in doesn't provide a phone number
            "dateOfBirth" to "",
            "gender" to ""
        )
        db.collection("users").document(userId)
            .set(userMap) // Use .set() to create or overwrite
            .addOnSuccessListener {
                Log.d(TAG, "New Google user saved to Firestore")
                goToMainActivity() // Now go to main
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Error saving new Google user", e)
                Toast.makeText(this, "Failed to save user data. Logging in anyway.", Toast.LENGTH_SHORT).show()
                goToMainActivity() // Go to main anyway, but log the error
            }
    }

    private fun setupClickListeners() {
        binding.btnLogin.setOnClickListener { loginUser() }
        binding.btnGuestLogin.setOnClickListener { signInAsGuest() }
        binding.tvCreateAccount.setOnClickListener {
            startActivity(Intent(this, RegisterActivity::class.java))
        }

        binding.btnGoogleSignIn.setOnClickListener {
            Log.d(TAG, "Google Sign-In clicked")
            val signInIntent = googleSignInClient.signInIntent
            googleSignInLauncher.launch(signInIntent)
        }

        binding.btnMobileLogin.setOnClickListener {
            Log.d(TAG, "Mobile Login clicked")
            startActivity(Intent(this, PhoneAuthActivity::class.java))
        }
        binding.tvForgotPassword.setOnClickListener {
            Log.d(TAG, "Forgot Password clicked")
            Toast.makeText(this, "Forgot Password clicked", Toast.LENGTH_SHORT).show()
        }
    }

    private fun signInAsGuest() {
        auth.signInAnonymously()
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    Log.d(TAG, "signInAnonymously:success")
                    Toast.makeText(this, "Signed in as Guest", Toast.LENGTH_SHORT).show()
                    goToMainActivity()
                } else {
                    Log.w(TAG, "signInAnonymously:failure", task.exception)
                    Toast.makeText(this, "Guest login failed: ${task.exception?.message}",
                        Toast.LENGTH_SHORT).show()
                }
            }
    }

    private fun loginUser() {
        val email = binding.etLoginEmail.text.toString().trim()
        val password = binding.etLoginPassword.text.toString().trim()

        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Email and password cannot be empty", Toast.LENGTH_SHORT).show()
            return
        }

        auth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    Log.d(TAG, "signInWithEmail:success")
                    goToMainActivity()
                } else {
                    Log.w(TAG, "signInWithEmail:failure", task.exception)
                    Toast.makeText(this, "Authentication failed: ${task.exception?.message}", Toast.LENGTH_LONG).show()
                }
            }
    }

    // Helper function to navigate to MainActivity
    private fun goToMainActivity() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish() // Close LoginActivity
    }
}


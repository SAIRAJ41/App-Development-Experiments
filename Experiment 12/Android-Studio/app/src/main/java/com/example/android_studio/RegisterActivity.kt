package com.example.android_studio

import android.app.DatePickerDialog
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.RadioButton
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.android_studio.databinding.ActivityRegisterBinding // Import View Binding
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Calendar

class RegisterActivity : AppCompatActivity() {

    private val TAG = "RegisterActivity"

    // Use View Binding
    private lateinit var binding: ActivityRegisterBinding

    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Set up View Binding
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Initialize Firebase
        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()

        // --- Set up Click Listeners ---

        // Date Picker for Age
        binding.etAge.setOnClickListener {
            showDatePickerDialog()
        }

        // Register Button
        binding.btnRegister.setOnClickListener {
            registerUser()
        }
    }

    private fun showDatePickerDialog() {
        val c = Calendar.getInstance()
        val year = c.get(Calendar.YEAR)
        val month = c.get(Calendar.MONTH)
        val day = c.get(Calendar.DAY_OF_MONTH)

        val dpd = DatePickerDialog(this, { _, year, monthOfYear, dayOfMonth ->
            // Display Selected date in EditText
            binding.etAge.setText("$dayOfMonth/${monthOfYear + 1}/$year")
        }, year, month, day)

        // Don't allow future dates
        dpd.datePicker.maxDate = System.currentTimeMillis()
        dpd.show()
    }

    private fun registerUser() {
        // 1. Get all user data from the UI (using binding)
        val fullName = binding.etFullName.text.toString().trim()
        val phone = binding.etPhoneNumber.text.toString().trim()
        val email = binding.etEmail.text.toString().trim()
        val dob = binding.etAge.text.toString().trim()
        val password = binding.etPassword.text.toString().trim()

        // Get selected gender
        val selectedGenderId = binding.rgGender.checkedRadioButtonId
        val gender = if (selectedGenderId != -1) {
            findViewById<RadioButton>(selectedGenderId).text.toString()
        } else {
            "" // No gender selected
        }

        // 2. Validate input
        if (fullName.isEmpty() || phone.isEmpty() || email.isEmpty() || dob.isEmpty() || password.isEmpty() || gender.isEmpty()) {
            Toast.makeText(this, "Please fill in all fields", Toast.LENGTH_SHORT).show()
            return
        }

        // 3. Create user with Email and Password
        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Authentication successful
                    Log.d(TAG, "createUserWithEmail:success")
                    val firebaseUser = auth.currentUser
                    val userId = firebaseUser!!.uid

                    // 4. Create a 'user' object to save to Firestore
                    val userMap = hashMapOf(
                        "fullName" to fullName,
                        "phone" to phone,
                        "email" to email,
                        "dateOfBirth" to dob,
                        "gender" to gender
                    )

                    // 5. Save the user object to Firestore
                    db.collection("users").document(userId)
                        .set(userMap)
                        .addOnSuccessListener {
                            Log.d(TAG, "DocumentSnapshot added with ID: $userId")
                            Toast.makeText(this, "Registration successful!", Toast.LENGTH_SHORT).show()

                            // --- THIS IS THE NAVIGATION CODE ---
                            // It will only run if the save is successful
                            val intent = Intent(this, MainActivity::class.java)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                            startActivity(intent)
                            finish()
                        }
                        .addOnFailureListener { e ->
                            Log.w(TAG, "Error adding document", e)
                            Toast.makeText(this, "Error saving user data: ${e.message}", Toast.LENGTH_LONG).show()
                            // **NOTE: Navigation does NOT happen if it fails here!**
                        }

                } else {
                    // Authentication failed
                    Log.w(TAG, "createUserWithEmail:failure", task.exception)
                    Toast.makeText(this, "Authentication failed: ${task.exception?.message}", Toast.LENGTH_LONG).show()
                }
            }
    }
}


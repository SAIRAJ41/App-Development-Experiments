package com.example.android_studio

import android.app.DatePickerDialog
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import coil.load
import coil.transform.CircleCropTransformation
import com.example.android_studio.databinding.ActivityProfileBinding
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Calendar // IMPORT for Date Picker

class ProfileActivity : AppCompatActivity() {

    private val TAG = "ProfileActivity"
    private lateinit var binding: ActivityProfileBinding
    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()

        loadUserProfile()

        // --- Edit Button Logic ---
        binding.btnEditProfile.setOnClickListener {
            toggleEditState(true)
        }

        // --- Save Button Logic ---
        binding.btnSaveProfile.setOnClickListener {
            saveUserProfile()
        }

        // --- Date Picker Logic ---
        binding.etDateOfBirth.setOnClickListener {
            // Only show date picker if in edit mode
            if (binding.etDateOfBirth.isEnabled) {
                showDatePickerDialog()
            }
        }

        binding.btnSignOut.setOnClickListener {
            auth.signOut()
            Toast.makeText(this, "Signed Out", Toast.LENGTH_SHORT).show()
            goToLoginActivity()
        }

        binding.tvChangeProfilePic.setOnClickListener {
            // TODO: Add logic to open image gallery
            Toast.makeText(this, "Gallery functionality coming soon!", Toast.LENGTH_SHORT).show()
        }
    }

    private fun loadUserProfile() {
        val user = auth.currentUser
        if (user == null) {
            goToLoginActivity()
            return
        }

        // 1. Load data from FirebaseAuth (Email, Phone, Google Photo/Name)
        binding.tvEmail.text = "Email: ${user.email ?: "Not set"}"
        binding.tvPhone.text = "Phone: ${user.phoneNumber ?: "Not set"}"

        if (user.photoUrl != null) {
            binding.ivProfilePicture.load(user.photoUrl) {
                crossfade(true)
                placeholder(android.R.drawable.ic_menu_myplaces)
                transformations(CircleCropTransformation())
            }
        } else {
            binding.ivProfilePicture.load(android.R.drawable.ic_menu_myplaces)
        }

        // 2. Load data from Firestore (Full Name & DOB)
        db.collection("users").document(user.uid)
            .get()
            .addOnSuccessListener { document ->
                if (document != null && document.exists()) {
                    val fullName = document.getString("fullName")
                    val dob = document.getString("dateOfBirth")

                    // Load into the new EditTexts
                    binding.etFullName.setText(fullName ?: user.displayName ?: "Not set")
                    binding.etDateOfBirth.setText(dob ?: "Not set")
                } else {
                    // No Firestore doc, just use Google Auth info
                    binding.etFullName.setText(user.displayName ?: "Not set")
                    binding.etDateOfBirth.setText("Not set")
                }
            }
            .addOnFailureListener { exception ->
                Log.w(TAG, "Error getting document: ", exception)
                // Fallback to Auth data on error
                binding.etFullName.setText(user.displayName ?: "Not set")
                binding.etDateOfBirth.setText("Not set")
            }
    }

    // --- Function to save the updated data ---
    private fun saveUserProfile() {
        val user = auth.currentUser
        if (user == null) {
            goToLoginActivity()
            return
        }

        val newFullName = binding.etFullName.text.toString().trim()
        val newDob = binding.etDateOfBirth.text.toString().trim()

        if (newFullName.isEmpty() || newDob.isEmpty() || newDob == "Not set") {
            Toast.makeText(this, "Fields cannot be empty", Toast.LENGTH_SHORT).show()
            return
        }

        // Create a map of the data to update in Firestore
        // We use .set with merge to create the doc if it's missing
        val updatedData = mapOf(
            "fullName" to newFullName,
            "dateOfBirth" to newDob
        )

        db.collection("users").document(user.uid)
            .set(updatedData, com.google.firebase.firestore.SetOptions.merge()) // Use merge to avoid overwriting other fields
            .addOnSuccessListener {
                Log.d(TAG, "User profile updated successfully")
                Toast.makeText(this, "Profile Saved!", Toast.LENGTH_SHORT).show()
                toggleEditState(false) // Go back to read-only mode
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Error updating document", e)
                Toast.makeText(this, "Error saving: ${e.message}", Toast.LENGTH_LONG).show()
                toggleEditState(false) // Go back to read-only mode
            }
    }

    // --- Helper function to toggle UI state ---
    private fun toggleEditState(isEditable: Boolean) {
        binding.etFullName.isEnabled = isEditable
        binding.etDateOfBirth.isEnabled = isEditable // This enables the click listener

        // Change background to give visual cue
        val editableBg = androidx.appcompat.R.drawable.abc_edit_text_material
        val nonEditableBg = android.R.color.transparent

        binding.etFullName.setBackgroundResource(if (isEditable) editableBg else nonEditableBg)
        binding.etDateOfBirth.setBackgroundResource(if (isEditable) editableBg else nonEditableBg)


        if (isEditable) {
            binding.btnEditProfile.visibility = View.GONE
            binding.btnSaveProfile.visibility = View.VISIBLE
            binding.etFullName.requestFocus() // Put cursor in name field
        } else {
            binding.btnEditProfile.visibility = View.VISIBLE
            binding.btnSaveProfile.visibility = View.GONE
        }
    }

    // --- Date Picker Dialog (copied from RegisterActivity) ---
    private fun showDatePickerDialog() {
        val c = Calendar.getInstance()
        val year = c.get(Calendar.YEAR)
        val month = c.get(Calendar.MONTH)
        val day = c.get(Calendar.DAY_OF_MONTH)

        val dpd = DatePickerDialog(this, DatePickerDialog.OnDateSetListener { _, year, monthOfYear, dayOfMonth ->
            binding.etDateOfBirth.setText("$dayOfMonth/${monthOfYear + 1}/$year")
        }, year, month, day)

        dpd.datePicker.maxDate = System.currentTimeMillis()
        dpd.show()
    }

    private fun goToLoginActivity() {
        val intent = Intent(this, LoginActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}


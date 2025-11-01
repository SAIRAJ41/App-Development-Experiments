package com.example.android_studio

import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.android_studio.databinding.ActivityMainBinding
import com.google.firebase.auth.FirebaseAuth

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var auth: FirebaseAuth

    // In-memory list to hold the notes (no database)
    private val notesList = ArrayList<String>()
    private lateinit var notesAdapter: ArrayAdapter<String>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        auth = FirebaseAuth.getInstance()

        // Check if user is logged in
        if (auth.currentUser == null) {
            // If no user, send them back to Login
            goToLoginActivity()
        } else {
            // If logged in, set up the dashboard
            setupDashboard()
        }
    }

    private fun setupDashboard() {
        // Display a welcome message
        val user = auth.currentUser
        val identifier = user?.email ?: user?.phoneNumber ?: "Guest User"
        binding.tvWelcome.text = "Welcome, $identifier"

        // Set up the simple in-memory list for notes
        notesAdapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, notesList)
        binding.lvNotes.adapter = notesAdapter

        // Set up "Add Note" button
        binding.btnAddNote.setOnClickListener {
            addNote()
        }

        // --- NEW: Set up "Profile" button ---
        binding.btnProfile.setOnClickListener {
            // Navigate to the ProfileActivity
            val intent = Intent(this, ProfileActivity::class.java)
            startActivity(intent)
        }

        // --- REMOVED: Sign Out Button ---
        // The btnSignOut.setOnClickListener block has been removed.
    }

    private fun addNote() {
        val note = binding.etNote.text.toString().trim()
        if (note.isNotEmpty()) {
            notesList.add(note)
            notesAdapter.notifyDataSetChanged() // Update the list view
            binding.etNote.text.clear() // Clear the input field
        } else {
            Toast.makeText(this, "Note cannot be empty", Toast.LENGTH_SHORT).show()
        }
    }

    private fun goToLoginActivity() {
        val intent = Intent(this, LoginActivity::class.java)
        // Clear the back stack so user can't press "back" to go to the dashboard
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish() // Close MainActivity
    }
}


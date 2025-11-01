/******************************************************************
 * PLEASE NOTE: This is a React Native app.
 * The "Preview" button in this tool WILL NOT WORK
 * and will show errors like "Could not resolve 'react-native'".
 *
 * To run this app, you MUST use your terminal:
 * npx react-native run-android
 ******************************************************************/

/**
 * Sample React Native App
 *
 * @format
 */

import React, {useState, useEffect} from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  StatusBar,
  useColorScheme,
  Alert,
  ScrollView,
  Image, // Import Image for profile picture
  FlatList, // Import FlatList for notes
} from 'react-native';

// --- Firebase ---
// Import both the auth function and the types
import auth, {FirebaseAuthTypes} from '@react-native-firebase/auth';
// Import Storage for file uploads
import storage from '@react-native-firebase/storage';
// Import Firestore for database
import firestore from '@react-native-firebase/firestore';

// --- Native Modules (Needs Installation) ---
import {GoogleSignin} from '@react-native-google-signin/google-signin';
import {launchImageLibrary} from 'react-native-image-picker';

// Type definition for auth confirmation result
type PhoneAuthConfirmation =
  | (FirebaseAuthTypes.ConfirmationResult & {
      // Add any additional properties if needed
    })
  | null;

// Type for the User object from Firebase Auth
type User = FirebaseAuthTypes.User | null;

// Type for our Firestore User data
type UserData = {
  fullName: string;
  email: string;
  birthDate: string;
  phone: string;
  gender: string;
};

// Type for a Note
type Note = {
  id: string;
  text: string;
  createdAt: any;
};

// --- 1. Login Page Component ---
function LoginPage({
  setPage,
}: {
  setPage: (page: string) => void;
}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // --------------------------------------------------------------------------
  // !!! CRITICAL CONFIGURATION !!!
  // This is the CORRECT Web Client ID found in your google-services.json for com.experiment_12
  const FIREBASE_WEB_CLIENT_ID =
    '352317964714-9kgbp236aiijk7b4f63tjsj9f01ecp8j.apps.googleusercontent.com'; 
  // --------------------------------------------------------------------------

  const handleEmailLogin = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please enter both email and password.');
      return;
    }
    try {
      // Sign-in successful, onAuthStateChanged will handle navigation
      await auth().signInWithEmailAndPassword(email, password);
    } catch (error: any) {
      console.error(error);
      Alert.alert('Login Error', error.message);
    }
  };

  const handleGoogleLogin = async () => {
    try {
      GoogleSignin.configure({
        webClientId: FIREBASE_WEB_CLIENT_ID,
      });

      await GoogleSignin.hasPlayServices();

      // Sign in to prompt the user and then retrieve tokens (idToken/accessToken)
      await GoogleSignin.signIn();
      const {idToken} = await GoogleSignin.getTokens(); // Get idToken from tokens

      if (!idToken) {
        throw new Error('No idToken returned from Google Sign-In.');
      }
      const googleCredential = auth.GoogleAuthProvider.credential(idToken);
      // Sign-in successful, onAuthStateChanged will handle navigation
      await auth().signInWithCredential(googleCredential);
    } catch (error: any) {
      if (error.code === 'DEVELOPER_ERROR') {
        Alert.alert(
          'Google Sign-In Error',
          'Developer error. Have you configured the webClientId? Have you added the google-services.json to android/app/? Have you added your SHA keys to Firebase?',
        );
      } else {
        Alert.alert('Google Sign-In Error', error.message);
      }
    }
  };

  const handleGuestLogin = async () => {
    try {
      // Sign-in successful, onAuthStateChanged will handle navigation
      await auth().signInAnonymously();
    } catch (error: any) {
      console.error(error);
      Alert.alert('Guest Login Error', error.message);
    }
  };

  return (
    <ScrollView style={styles.scrollView}>
      <View style={styles.container}>
        <Text style={styles.title}>Welcome Back</Text>
        <Text style={styles.subtitle}>Sign in to your account</Text>

        <TextInput
          style={styles.input}
          placeholder="Email Address"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
        />
        <TextInput
          style={styles.input}
          placeholder="Password"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
        />
        <TouchableOpacity
          style={styles.buttonPrimary}
          onPress={handleEmailLogin}>
          <Text style={styles.buttonPrimaryText}>Login</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.linkButtonSmall}
          onPress={() => setPage('forgotPassword')}>
          <Text style={styles.linkButtonText}>Forgot Password?</Text>
        </TouchableOpacity>
        <Text style={styles.orText}>— or sign in with —</Text>
        <View style={styles.socialButtonContainer}>
          <TouchableOpacity
            style={styles.buttonSocial}
            onPress={handleGoogleLogin}>
            <Text style={styles.buttonSocialText}>G</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.buttonSocial}
            onPress={() => setPage('phoneInput')}>
            <Text style={styles.buttonSocialText}>#</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.buttonSocial}
            onPress={handleGuestLogin}>
            <Text style={styles.buttonSocialText}>?</Text>
          </TouchableOpacity>
        </View>
        <TouchableOpacity
          style={styles.linkButton}
          onPress={() => setPage('signup')}>
          <Text style={styles.linkButtonText}>
            Don't have an account?{' '}
            <Text style={styles.linkButtonTextBold}>Sign Up</Text>
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

// --- 2. Sign Up Page Component ---
function SignUpPage({
  setPage,
}: {
  setPage: (page: string) => void;
}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);

  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [gender, setGender] = useState(''); // Updated to empty string for radio default
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // Helper component for radio buttons
  const GenderOption = ({
    value,
    current,
    set,
  }: {
    value: string;
    current: string;
    set: (v: string) => void;
  }) => (
    <TouchableOpacity
      style={styles.radioContainer}
      onPress={() => set(value)}>
      <View style={styles.radioOuter}>
        {current === value && <View style={styles.radioInner} />}
      </View>
      <Text style={styles.radioText}>{value}</Text>
    </TouchableOpacity>
  );

  const handleSignUp = async () => {
    if (!email || !password || !fullName || !gender) {
      Alert.alert(
        'Error',
        'Please fill in all required fields (Full Name, Gender, Email, and Password).',
      );
      return;
    }
    try {
      // 1. Create the user in Firebase Auth
      const userCredential = await auth().createUserWithEmailAndPassword(
        email,
        password,
      );

      // 2. Update their Auth profile
      await userCredential.user.updateProfile({
        displayName: fullName,
      });

      // 3. Create their user document in Firestore
      await firestore().collection('users').doc(userCredential.user.uid).set({
        fullName: fullName,
        email: email,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        createdAt: firestore.FieldValue.serverTimestamp(),
      });

      // onAuthStateChanged will handle navigation
    } catch (error: any) {
      if (error.code === 'auth/email-already-in-use') {
        Alert.alert('Error', 'That email address is already in use!');
      } else if (error.code === 'auth/weak-password') {
        Alert.alert('Error', 'Password should be at least 6 characters.');
      } else {
        Alert.alert('Sign Up Error', error.message);
      }
    }
  };

  return (
    <ScrollView style={styles.scrollView}>
      <View style={styles.container}>
        <Text style={styles.title}>Create Account</Text>
        <Text style={styles.subtitle}>Let's get you started</Text>
        <TextInput
          style={styles.input}
          placeholder="Full Name"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={fullName}
          onChangeText={setFullName}
        />
        <TextInput
          style={styles.input}
          placeholder="Phone Number (e.g. +919876543210)"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={phone}
          onChangeText={setPhone}
          keyboardType="phone-pad"
        />
        <TextInput
          style={styles.input}
          placeholder="Birth Date (YYYY-MM-DD)"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={birthDate}
          onChangeText={setBirthDate}
        />
        
        {/* --- New Gender Selection UI --- */}
        <Text style={[styles.subtitle, {marginBottom: 8, marginTop: 8, textAlign: 'left'}]}>Gender</Text>
        <View style={styles.radioGroup}>
          <GenderOption value="Male" current={gender} set={setGender} />
          <GenderOption value="Female" current={gender} set={setGender} />
          <GenderOption value="Other" current={gender} set={setGender} />
        </View>
        
        <TextInput
          style={styles.input}
          placeholder="Email Address"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
        />
        <TextInput
          style={styles.input}
          placeholder="Password (min. 6 characters)"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
        />
        <TouchableOpacity style={styles.buttonPrimary} onPress={handleSignUp}>
          <Text style={styles.buttonPrimaryText}>Sign Up</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.linkButton}
          onPress={() => setPage('login')}>
          <Text style={styles.linkButtonText}>
            Already have an account?{' '}
            <Text style={styles.linkButtonTextBold}>Log In</Text>
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

// --- 3. Phone Input Page Component ---
function PhoneInputPage({
  setPage,
  setConfirm,
}: {
  setPage: (page: string) => void;
  setConfirm: (confirm: PhoneAuthConfirmation) => void;
}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [localPhone, setLocalPhone] = useState('');

  const handleSendCode = async () => {
    if (!localPhone) {
      Alert.alert('Error', 'Please enter a phone number.');
      return;
    }
    const formattedPhone = localPhone.startsWith('+')
      ? localPhone
      : `+91${localPhone}`;
    Alert.alert(
      'Sending Code',
      `Sending verification code to ${formattedPhone}...`,
    );

    try {
      const confirmation = await auth().signInWithPhoneNumber(formattedPhone);
      setConfirm(confirmation);
      setPage('otpInput');
    } catch (error: any) {
      Alert.alert('Phone Sign-In Error', error.message);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Phone Login</Text>
      <Text style={styles.subtitle}>Enter your phone number</Text>
      <TextInput
        style={styles.input}
        placeholder="Phone Number (e.g. +919876543210)"
        placeholderTextColor={isDarkMode ? '#999' : '#777'}
        value={localPhone}
        onChangeText={setLocalPhone}
        keyboardType="phone-pad"
      />
      <TouchableOpacity style={styles.buttonPrimary} onPress={handleSendCode}>
        <Text style={styles.buttonPrimaryText}>Send Code</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.linkButton}
        onPress={() => setPage('login')}>
        <Text style={styles.linkButtonText}>
          <Text style={styles.linkButtonTextBold}>Back to Login</Text>
        </Text>
      </TouchableOpacity>
    </View>
  );
}

// --- 4. OTP Input Page Component ---
function OtpInputPage({
  setPage,
  confirm,
}: {
  setPage: (page: string) => void;
  confirm: PhoneAuthConfirmation;
}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [code, setCode] = useState('');

  const handleConfirmCode = async () => {
    if (!confirm) {
      Alert.alert('Error', 'No confirmation code sent. Please go back.');
      return;
    }
    if (!code) {
      Alert.alert('Error', 'Please enter the 6-digit code.');
      return;
    }
    try {
      // Sign-in successful, onAuthStateChanged will handle navigation
      await confirm.confirm(code);
    } catch (error: any) {
      if (error.code === 'auth/invalid-verification-code') {
        Alert.alert('Error', 'Invalid code. Please try again.');
      } else {
        Alert.alert('OTP Error', error.message);
      }
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Verify Code</Text>
      <Text style={styles.subtitle}>Enter the 6-digit code</Text>
      <TextInput
        style={styles.input}
        placeholder="123456"
        placeholderTextColor={isDarkMode ? '#999' : '#777'}
        value={code}
        onChangeText={setCode}
        keyboardType="number-pad"
        maxLength={6}
      />
      <TouchableOpacity style={styles.buttonPrimary} onPress={handleConfirmCode}>
        <Text style={styles.buttonPrimaryText}>Verify</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.linkButton}
        onPress={() => setPage('phoneInput')}>
        <Text style={styles.linkButtonText}>
          <Text style={styles.linkButtonTextBold}>Change Number</Text>
        </Text>
      </TouchableOpacity>
    </View>
  );
}

// --- 5. Forgot Password Page Component ---
function ForgotPasswordPage({
  setPage,
}: {
  setPage: (page: string) => void;
}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [email, setEmail] = useState('');

  const handleSendResetLink = async () => {
    if (!email) {
      Alert.alert('Error', 'Please enter your email address.');
      return;
    }
    try {
      await auth().sendPasswordResetEmail(email);
      Alert.alert(
        'Check Your Email',
        `A password reset link has been sent to ${email}.`,
      );
      setPage('login');
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        Alert.alert('Error', 'No user found with that email address.');
      } else {
        Alert.alert('Error', error.message);
      }
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Forgot Password</Text>
      <Text style={styles.subtitle}>
        Enter your email to receive a reset link
      </Text>
      <TextInput
        style={styles.input}
        placeholder="Email Address"
        placeholderTextColor={isDarkMode ? '#999' : '#777'}
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
      />
      <TouchableOpacity
        style={styles.buttonPrimary}
        onPress={handleSendResetLink}>
        <Text style={styles.buttonPrimaryText}>Send Reset Link</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.linkButton}
        onPress={() => setPage('login')}>
        <Text style={styles.linkButtonText}>
          <Text style={styles.linkButtonTextBold}>Back to Login</Text>
        </Text>
      </TouchableOpacity>
    </View>
  );
}

// --- (NEW) Logged-out screen manager ---
// This component manages the 'login', 'signup', etc. pages
function AuthStack(): React.JSX.Element {
  const [page, setPage] = useState('login');
  const [confirm, setConfirm] = useState<PhoneAuthConfirmation>(null);

  switch (page) {
    case 'login':
      return <LoginPage setPage={setPage} />;
    case 'signup':
      return <SignUpPage setPage={setPage} />;
    case 'phoneInput':
      return <PhoneInputPage setPage={setPage} setConfirm={setConfirm} />;
    case 'otpInput':
      return <OtpInputPage setPage={setPage} confirm={confirm} />;
    case 'forgotPassword':
      return <ForgotPasswordPage setPage={setPage} />;
    default:
      return <LoginPage setPage={setPage} />;
  }
}

// --- (NEW) Dashboard Page ---
function DashboardPage({user}: {user: User}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [notes, setNotes] = useState<Note[]>([]);
  const [newNote, setNewNote] = useState('');

  const userId = user?.uid;

  // Effect to load notes from Firestore in real-time
  useEffect(() => {
    if (!userId) return;

    const unsubscribe = firestore()
      .collection('users')
      .doc(userId)
      .collection('notes')
      .orderBy('createdAt', 'desc') // Show newest notes first
      .onSnapshot(querySnapshot => {
        const notesData: Note[] = [];
        querySnapshot.forEach(doc => {
          notesData.push({id: doc.id, ...doc.data()} as Note);
        });
        setNotes(notesData);
      });

    // Unsubscribe when component unmounts
    return () => unsubscribe();
  }, [userId]);

  const handleAddNote = async () => {
    if (!newNote.trim() || !userId) return;
    try {
      await firestore().collection('users').doc(userId).collection('notes').add({
        text: newNote,
        createdAt: firestore.FieldValue.serverTimestamp(),
      });
      setNewNote(''); // Clear input
    } catch (error) {
      console.error('Error adding note:', error);
      Alert.alert('Error', 'Could not add note.');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>My Notes</Text>
      <View style={styles.noteInputContainer}>
        <TextInput
          style={styles.input}
          placeholder="Add a new note..."
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={newNote}
          onChangeText={setNewNote}
        />
        <TouchableOpacity style={styles.buttonPrimary} onPress={handleAddNote}>
          <Text style={styles.buttonPrimaryText}>Add</Text>
        </TouchableOpacity>
      </View>
      <FlatList
        data={notes}
        keyExtractor={item => item.id}
        renderItem={({item}) => (
          <View style={styles.noteItem}>
            <Text style={styles.noteText}>{item.text}</Text>
          </View>
        )}
        style={styles.noteList}
      />
    </View>
  );
}

// --- (NEW) Profile Page ---
function ProfilePage({user}: {user: User}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);

  // Auth data (email, photoURL, default name)
  const authUser = auth().currentUser;

  // Firestore data (custom name, birthdate, etc.)
  const [userData, setUserData] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

  // Editable fields
  const [fullName, setFullName] = useState(authUser?.displayName || '');
  const [birthDate, setBirthDate] = useState('');
  const [photoURL, setPhotoURL] = useState(authUser?.photoURL || '');

  // Effect to load user data from Firestore
  useEffect(() => {
    if (!authUser) return;

    const unsubscribe = firestore()
      .collection('users')
      .doc(authUser.uid)
      .onSnapshot(doc => {
        if (doc.exists()) {
          const data = doc.data() as UserData;
          setUserData(data);
          setFullName(data.fullName || authUser.displayName || '');
          setBirthDate(data.birthDate || '');
        }
        setLoading(false);
      });

    return () => unsubscribe();
  }, [authUser]);

  const handleImageUpload = async () => {
    if (!authUser) return;
    try {
      const result = await launchImageLibrary({
        mediaType: 'photo',
        quality: 0.8,
      });

      if (result.didCancel || !result.assets || result.assets.length === 0) {
        return;
      }

      const uri = result.assets[0].uri;
      if (!uri) return;

      // 1. Upload to Firebase Storage
      const filename = `profile.jpg`;
      const storageRef = storage().ref(`users/${authUser.uid}/${filename}`);
      await storageRef.putFile(uri);

      // 2. Get the download URL
      const downloadURL = await storageRef.getDownloadURL();

      // 3. Update Firebase Auth Profile
      await authUser.updateProfile({
        photoURL: downloadURL,
      });

      // 4. Update local state
      setPhotoURL(downloadURL);

      Alert.alert('Success', 'Profile picture updated!');
    } catch (error) {
      console.error('Image upload error:', error);
      Alert.alert('Error', 'Could not upload image.');
    }
  };

  const handleUpdateProfile = async () => {
    if (!authUser) return;
    try {
      // 1. Update Firebase Auth profile
      await authUser.updateProfile({
        displayName: fullName,
      });

      // 2. Update Firestore document
      await firestore().collection('users').doc(authUser.uid).update({
        fullName: fullName,
        birthDate: birthDate,
      });

      Alert.alert('Success', 'Profile updated!');
    } catch (error: any) {
      console.error('Error updating profile:', error);
      Alert.alert('Error', 'Could not update profile.');
    }
  };

  const handleSignOut = async () => {
    try {
      // Sign-out successful, onAuthStateChanged will handle navigation
      await auth().signOut();
    } catch (error: any) {
      console.error('Sign out error:', error);
      Alert.alert('Error', 'Could not sign out.');
    }
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.subtitle}>Loading Profile...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.scrollView}>
      <View style={styles.container}>
        <Text style={styles.title}>My Profile</Text>
        
        {/* Profile Image with Upload Button */}
        <TouchableOpacity onPress={handleImageUpload}>
          <Image
            style={styles.profileImage}
            source={{
              uri:
                photoURL ||
                authUser?.photoURL ||
                `https://placehold.co/150x150/007AFF/FFFFFF?text=${fullName
                  .charAt(0)
                  .toUpperCase()}`,
            }}
          />
        </TouchableOpacity>
        <Text style={styles.profileHintText}>(Tap image to change)</Text>

        <TextInput
          style={styles.input}
          placeholder="Full Name"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={fullName}
          onChangeText={setFullName}
        />
        <TextInput
          style={styles.input}
          placeholder="Birth Date (YYYY-MM-DD)"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={birthDate}
          onChangeText={setBirthDate}
        />
        <TextInput
          style={styles.input}
          placeholder="Email Address"
          placeholderTextColor={isDarkMode ? '#999' : '#777'}
          value={authUser?.email || ''}
          editable={false} // Email is not editable
        />

        <TouchableOpacity
          style={styles.buttonPrimary}
          onPress={handleUpdateProfile}>
          <Text style={styles.buttonPrimaryText}>Save Changes</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.buttonPrimary, styles.buttonDanger]}
          onPress={handleSignOut}>
          <Text style={styles.buttonPrimaryText}>Sign Out</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

// --- (NEW) Logged-in screen manager ---
// This component shows Dashboard/Profile and the bottom nav bar
function AppStack({user}: {user: User}): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const styles = getStyles(isDarkMode);
  const [appPage, setAppPage] = useState('dashboard'); // 'dashboard' or 'profile'

  return (
    <View style={{flex: 1}}>
      <View style={{flex: 1}}>
        {appPage === 'dashboard' ? (
          <DashboardPage user={user} />
        ) : (
          <ProfilePage user={user} />
        )}
      </View>

      {/* Bottom Nav Bar */}
      <View style={styles.navBar}>
        <TouchableOpacity
          style={styles.navButton}
          onPress={() => setAppPage('dashboard')}>
          <Text
            style={[
              styles.navButtonText,
              appPage === 'dashboard' && styles.navButtonTextActive,
            ]}>
            Dashboard
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.navButton}
          onPress={() => setAppPage('profile')}>
          <Text
            style={[
              styles.navButtonText,
              appPage === 'profile' && styles.navButtonTextActive,
            ]}>
            Profile
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

// --- Main App Component (Router) ---
// This component decides which page to show
function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  // --- !! NEW AUTH STATE !! ---
  const [initializing, setInitializing] = useState(true);
  const [user, setUser] = useState<User>(null);

  // Handle user state changes
  function onAuthStateChanged(user: User) {
    setUser(user);
    if (initializing) setInitializing(false);
  }

  useEffect(() => {
    const subscriber = auth().onAuthStateChanged(onAuthStateChanged);
    return subscriber; // unsubscribe on unmount
  }, []);
  // --- END NEW AUTH STATE ---

  const backgroundStyle = {
    backgroundColor: isDarkMode ? '#1e1e1e' : '#FFFFFF',
    flex: 1,
  };

  if (initializing) {
    // We are checking auth state, show a loading screen
    return (
      <SafeAreaView style={backgroundStyle}>
        <View style={getStyles(isDarkMode).container}>
          <Text style={getStyles(isDarkMode).title}>Loading...</Text>
        </View>
      </SafeAreaView>
    );
  }

  // If user is null, show Logged-Out screens.
  // Otherwise, show Logged-In screens.
  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      {!user ? <AuthStack /> : <AppStack user={user} />}
    </SafeAreaView>
  );
}

// --- Styles ---
// Moved to the bottom so all components can access it
const getStyles = (isDarkMode: boolean) =>
  StyleSheet.create({
    scrollView: {
      flex: 1,
      backgroundColor: isDarkMode ? '#1e1e1e' : '#FFFFFF',
    },
    container: {
      flex: 1,
      justifyContent: 'center',
      padding: 24,
      backgroundColor: isDarkMode ? '#1e1e1e' : '#FFFFFF',
      minHeight: '100%',
    },
    title: {
      fontSize: 32,
      fontWeight: 'bold',
      color: isDarkMode ? '#FFFFFF' : '#000000',
      marginBottom: 8,
      textAlign: 'center',
    },
    subtitle: {
      fontSize: 16,
      color: isDarkMode ? '#AAAAAA' : '#666666',
      marginBottom: 32,
      textAlign: 'center',
    },
    input: {
      backgroundColor: isDarkMode ? '#333333' : '#F0F0F0',
      color: isDarkMode ? '#FFFFFF' : '#000000',
      height: 50,
      borderRadius: 8,
      paddingHorizontal: 16,
      marginBottom: 16,
      fontSize: 16,
      borderWidth: 1,
      borderColor: isDarkMode ? '#555' : '#DDD',
    },
    buttonPrimary: {
      backgroundColor: '#007AFF', // Blue
      height: 50,
      borderRadius: 8,
      justifyContent: 'center',
      alignItems: 'center',
      marginTop: 8,
    },
    buttonPrimaryText: {
      color: '#FFFFFF',
      fontSize: 18,
      fontWeight: '600',
    },
    buttonDanger: {
      backgroundColor: '#FF3B30', // Red
      marginTop: 16,
    },
    orText: {
      color: isDarkMode ? '#999' : '#777',
      textAlign: 'center',
      marginVertical: 24,
      fontSize: 14,
    },
    socialButtonContainer: {
      flexDirection: 'row',
      justifyContent: 'center',
      gap: 16,
    },
    buttonSocial: {
      width: 60,
      height: 60,
      borderRadius: 30, // Circle
      backgroundColor: isDarkMode ? '#333' : '#F0F0F0',
      justifyContent: 'center',
      alignItems: 'center',
      borderWidth: 1,
      borderColor: isDarkMode ? '#555' : '#DDD',
    },
    buttonSocialText: {
      fontSize: 24,
      fontWeight: 'bold',
      color: isDarkMode ? '#FFF' : '#000',
    },
    linkButton: {
      marginTop: 24,
      alignItems: 'center',
    },
    linkButtonSmall: {
      marginTop: 12,
      alignItems: 'flex-end',
      marginRight: 4,
      marginBottom: 12,
    },
    linkButtonText: {
      fontSize: 14,
      color: isDarkMode ? '#AAA' : '#555',
    },
    linkButtonTextBold: {
      fontWeight: 'bold',
      color: '#007AFF',
    },
    // --- New Styles ---
    profileImage: {
      width: 150,
      height: 150,
      borderRadius: 75,
      alignSelf: 'center',
      marginBottom: 24,
      backgroundColor: isDarkMode ? '#555' : '#EEE',
    },
    profileHintText: {
      textAlign: 'center',
      color: isDarkMode ? '#888' : '#666',
      fontSize: 12,
      marginBottom: 24,
      marginTop: -16, // pull it up close to the image
    },
    navBar: {
      flexDirection: 'row',
      height: 60,
      backgroundColor: isDarkMode ? '#111' : '#F8F8F8',
      borderTopWidth: 1,
      borderTopColor: isDarkMode ? '#333' : '#DDD',
    },
    navButton: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
    },
    navButtonText: {
      fontSize: 16,
      color: isDarkMode ? '#888' : '#777',
    },
    navButtonTextActive: {
      color: '#007AFF',
      fontWeight: 'bold',
    },
    noteInputContainer: {
      flexDirection: 'row',
      gap: 8,
      marginBottom: 16,
    },
    noteList: {
      flex: 1,
    },
    noteItem: {
      backgroundColor: isDarkMode ? '#222' : '#F8F8F8',
      padding: 16,
      borderRadius: 8,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: isDarkMode ? '#444' : '#EEE',
    },
    noteText: {
      fontSize: 16,
      color: isDarkMode ? '#FFF' : '#000',
    },
    radioGroup: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      marginBottom: 16,
      marginTop: 4,
      paddingHorizontal: 16,
    },
    radioContainer: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    radioOuter: {
      height: 20,
      width: 20,
      borderRadius: 10,
      borderWidth: 2,
      borderColor: '#007AFF',
      alignItems: 'center',
      justifyContent: 'center',
      marginRight: 8,
    },
    radioInner: {
      height: 12,
      width: 12,
      borderRadius: 6,
      backgroundColor: '#007AFF',
    },
    radioText: {
      color: isDarkMode ? '#FFFFFF' : '#000000',
      fontSize: 16,
    },
  });

export default App;

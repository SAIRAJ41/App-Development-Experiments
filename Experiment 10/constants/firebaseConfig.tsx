import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyD4iFhixl44pZ-fhmcqZ5pHflGj9p6WMas",
  authDomain: "to-do-app-6da54.firebaseapp.com",
  projectId: "to-do-app-6da54",
  storageBucket: "to-do-app-6da54.firebasestorage.app",
  messagingSenderId: "942641990475",
  appId: "1:942641990475:web:b14c4dd63f24bf54ea36ce",
  measurementId: "G-PX18GCEYZ2"
};
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { app, db };

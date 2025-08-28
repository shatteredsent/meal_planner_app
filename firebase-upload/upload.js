const admin = require('firebase-admin');
const serviceAccount = require('./mealplannerapp-65b06-firebase-adminsdk-fbsvc-78f8aa3318.json');
const recipes = require('./recipes.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadRecipes() {
  if (!Array.isArray(recipes) || recipes.length === 0) {
    console.log('No recipes found in recipes.json. Exiting.');
    return;
  }

  const collectionRef = db.collection('recipes');
  const batch = db.batch();

  recipes.forEach(recipe => {
    // Firestore will generate a unique ID for each document
    const docRef = collectionRef.doc();
    batch.set(docRef, recipe);
  });

  console.log(`Uploading ${recipes.length} recipes...`);

  try {
    await batch.commit();
    console.log('Successfully uploaded all recipes!');
  } catch (error) {
    console.error('Failed to upload recipes:', error);
  }
}

uploadRecipes();
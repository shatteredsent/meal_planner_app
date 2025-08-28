const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- Configuration ---
// Path to your service account key file
const serviceAccountPath = path.join(__dirname, 'mealplannerapp-65b06-firebase-adminsdk-fbsvc-78f8aa3318.json');
// Path to your recipes data file
const recipesPath = path.join(__dirname, 'recipes.json');
// The name of the collection you want to upload to in Firestore
const collectionName = 'recipes';
// ---------------------

try {
    const serviceAccount = require(serviceAccountPath);
    const recipes = require(recipesPath);

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    const db = admin.firestore();
    const recipesCollection = db.collection(collectionName);

    async function uploadRecipes() {
        if (!Array.isArray(recipes)) {
            console.error(`Error: The file at ${recipesPath} is not a valid JSON array.`);
            return;
        }

        if (recipes.length === 0) {
            console.log('No recipes found in recipes.json. Nothing to upload.');
            return;
        }

        console.log(`Found ${recipes.length} recipes. Starting upload to "${collectionName}" collection...`);

        // Firestore allows a maximum of 500 operations in a single batch.
        const batchSize = 500;
        for (let i = 0; i < recipes.length; i += batchSize) {
            const batch = db.batch();
            const chunk = recipes.slice(i, i + batchSize);
            
            console.log(`Processing batch ${Math.floor(i / batchSize) + 1}...`);

            chunk.forEach(recipe => {
                // Let Firestore auto-generate a document ID
                const docRef = recipesCollection.doc();
                batch.set(docRef, recipe);
            });

            await batch.commit();
            console.log(`Batch ${Math.floor(i / batchSize) + 1} successfully uploaded.`);
        }

        console.log('All recipes have been successfully uploaded!');
    }

    uploadRecipes().catch(error => {
        console.error('An error occurred during the upload process:', error);
    });

} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error(`Error: Could not find a required file. Make sure the following files exist in the 'firebase-upload' directory:`);
        console.error(`- mealplannerapp-65b06-firebase-adminsdk-fbsvc-78f8aa3318.json`);
        console.error(`- recipes.json`);
    } else {
        console.error('An unexpected error occurred:', error);
    }
}
module.exports = {
  preset: "jest-expo",
  testEnvironment: "jsdom",
  transform: {
    "^.+\\.(js|jsx|ts|tsx)$": "babel-jest",
  },
  transformIgnorePatterns: [
    "node_modules/(?!(@react-native|react-native|expo(nent)?|@expo(nent)?|expo-modules-core)/)",
  ],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json", "node"],
};

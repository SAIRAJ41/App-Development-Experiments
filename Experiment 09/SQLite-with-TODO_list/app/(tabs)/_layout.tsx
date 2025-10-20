import { Stack } from "expo-router";

export default function RootLayout() {
  return (
    <Stack>
      {/* Hide the header for the main todo list page */}
      <Stack.Screen name="index" options={{ headerShown: false }} />
      
      {/* Example of a screen with a custom header, e.g., for a settings page */}
      <Stack.Screen
        name="settings"
        options={{
          headerShown: true,
          headerTitle: "Settings",
          headerStyle: {
            backgroundColor: "#4630EB",
          },
          headerTintColor: "#fff",
        }}
      />
    </Stack>
  );
}
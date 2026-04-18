import React from "react";
import ReactDOM from "react-dom/client";
import { Auth0Provider } from "@auth0/auth0-react";
import App from "./App";
import "./index.css";

/**
 * Auth0Provider is the bridge between your frontend and Auth0.
 *
 * - domain:    your Auth0 tenant (dev-wbpt56q04xs2migc.us.auth0.com)
 * - clientId:  the Client ID of TDSE_App_Posts (your SPA in Auth0)
 * - audience:  tells Auth0 to issue an access token for YOUR API specifically
 * - scope:     the permissions the frontend requests for the user
 *
 * When a user clicks "Log in", the SDK redirects to Auth0's Universal Login.
 * After login, Auth0 redirects back here with an authorization code.
 * The SDK exchanges it for an access token — that's the JWT your backend validates.
 */
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <Auth0Provider
      domain={import.meta.env.VITE_AUTH0_DOMAIN}
      clientId={import.meta.env.VITE_AUTH0_CLIENT_ID}
      authorizationParams={{
        redirect_uri: window.location.origin,
        audience: import.meta.env.VITE_AUTH0_AUDIENCE,
        scope: "openid profile email read:posts write:posts read:profile",
      }}
    >
      <App />
    </Auth0Provider>
  </React.StrictMode>
);

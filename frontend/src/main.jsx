import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'
import { Auth0Provider } from '@auth0/auth0-react'

// TODO: Replace with actual Auth0 domain and client ID from environment variables
const domain = import.meta.env.VITE_AUTH0_DOMAIN || "YOUR_AUTH0_DOMAIN";
const clientId = import.meta.env.VITE_AUTH0_CLIENT_ID || "YOUR_AUTH0_CLIENT_ID";
const audience = import.meta.env.VITE_AUTH0_AUDIENCE || "YOUR_AUTH0_AUDIENCE";

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Auth0Provider
      domain={domain}
      clientId={clientId}
      authorizationParams={{
        redirect_uri: window.location.hostname === 'localhost'
          ? window.location.origin
          : window.location.origin + '/index.html',
        audience: audience
      }}
    >
      <App />
    </Auth0Provider>
  </React.StrictMode>,
)

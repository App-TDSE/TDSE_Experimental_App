import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useAuth0 } from '@auth0/auth0-react';
import './App.css';

const API_URL = 'https://it7ac1vh10.execute-api.us-east-1.amazonaws.com/api';

function App() {
  const { loginWithRedirect, logout, user, isAuthenticated, isLoading, getAccessTokenSilently } = useAuth0();
  const [posts, setPosts] = useState([]);
  const [newPost, setNewPost] = useState('');

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      const response = await axios.get(`${API_URL}/stream`);
      setPosts(response.data);
    } catch (error) {
      console.error('Error fetching posts', error);
    }
  };

  const handlePostSubmit = async (e) => {
    e.preventDefault();
    if (!newPost.trim() || newPost.length > 140) return;

    try {
      let token = null;
      if (isAuthenticated) {
        token = await getAccessTokenSilently();
      }
      
      const config = token ? {
        headers: { Authorization: `Bearer ${token}` }
      } : {};

      await axios.post(`${API_URL}/posts`, { content: newPost }, config);
      setNewPost('');
      fetchPosts();
    } catch (error) {
      console.error('Error creating post', error);
    }
  };

  if (isLoading) {
    return <div>Cargando...</div>;
  }

  return (
    <div className="App">
      <header className="header">
        <h1>Mini-Twitter</h1>
        <div className="auth-buttons">
          {!isAuthenticated ? (
            <button onClick={() => loginWithRedirect()}>Iniciar Sesión</button>
          ) : (
            <div className="user-info">
              <span>{user.name}</span>
              <button onClick={() => logout({ logoutParams: { returnTo: window.location.hostname === 'localhost' ? window.location.origin : window.location.origin + '/index.html' } })}>Cerrar Sesión</button>
            </div>
          )}
        </div>
      </header>

      <main className="main-content">
        {isAuthenticated && (
          <form className="post-form" onSubmit={handlePostSubmit}>
            <textarea
              value={newPost}
              onChange={(e) => setNewPost(e.target.value)}
              placeholder="¿Qué está pasando? (máx 140 carácteres)"
              maxLength={140}
            />
            <div className="form-footer">
              <span className={newPost.length === 140 ? 'limit-reached' : ''}>
                {newPost.length}/140
              </span>
              <button type="submit" disabled={!newPost.trim()}>Postear</button>
            </div>
          </form>
        )}

        <div className="feed">
          <h2>Stream Público</h2>
          {posts.length === 0 ? (
            <p>No hay posts aún.</p>
          ) : (
            posts.map(post => (
              <div key={post.id} className="post-card">
                <div className="post-header">
                  <strong>{post.authorName || post.authorId}</strong>
                  <span className="timestamp">{new Date(post.timestamp).toLocaleString()}</span>
                </div>
                <p className="post-content">{post.content}</p>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}

export default App;

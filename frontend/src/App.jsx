import { useAuth0 } from "@auth0/auth0-react";
import { useState, useEffect, useCallback } from "react";

const API_BASE = import.meta.env.VITE_API_BASE || "";
const USERS_API_BASE = import.meta.env.VITE_USERS_API_BASE || API_BASE;
const POSTS_API_BASE = import.meta.env.VITE_POSTS_API_BASE || API_BASE;
const STREAM_API_BASE = import.meta.env.VITE_STREAM_API_BASE || API_BASE;
const MAX_CHARS = 140;

function buildApiUrl(base, path) {
  const normalizedBase = base.replace(/\/$/, "");
  return `${normalizedBase}${path}`;
}

function timeAgo(iso) {
  const seconds = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (seconds < 60) return "just now";
  const mins = Math.floor(seconds / 60);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

function PostCard({ post, onDelete, currentUserId, deleting }) {
  const isOwner = currentUserId && post.userId === currentUserId;
  return (
    <article className="post-card">
      <div className="post-header">
        <span className="post-author">@{post.username}</span>
        <span className="post-time">{timeAgo(post.createdAt)}</span>
      </div>
      <p className="post-content">{post.content}</p>
      {isOwner && (
        <button
          className="btn-delete"
          onClick={() => onDelete(post.postId)}
          disabled={deleting}
          aria-label="Delete post"
        >
          delete
        </button>
      )}
    </article>
  );
}

export default function App() {
  const {
    loginWithRedirect,
    logout,
    isAuthenticated,
    isLoading,
    user,
    getAccessTokenSilently,
  } = useAuth0();

  const [posts, setPosts] = useState([]);
  const [draft, setDraft] = useState("");
  const [posting, setPosting] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState(null);
  const [feedLoading, setFeedLoading] = useState(true);

  // Auth0 sub is the userId stored on posts
  const currentUserId = isAuthenticated ? user?.sub : null;

  const fetchFeed = useCallback(async () => {
    try {
      setFeedLoading(true);
      setError(null);
      const res = await fetch(buildApiUrl(STREAM_API_BASE, "/api/stream"));
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
      setPosts(await res.json());
    } catch {
      setError("Could not load feed. Is the backend running?");
    } finally {
      setFeedLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchFeed();
  }, [fetchFeed]);

  useEffect(() => {
  if (!isAuthenticated) return;
  (async () => {
    try {
      const token = await getAccessTokenSilently();
      await fetch(buildApiUrl(USERS_API_BASE, "/api/users/me"), {
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch (e) {
      console.error("Could not sync profile:", e);
    }
  })();
}, [isAuthenticated, getAccessTokenSilently]);

  const handlePost = async (e) => {
    e.preventDefault();
    if (!draft.trim() || draft.length > MAX_CHARS) return;
    try {
      setPosting(true);
      setError(null);
      const token = await getAccessTokenSilently();
      const res = await fetch(buildApiUrl(POSTS_API_BASE, "/api/posts"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ content: draft.trim() }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.message || `${res.status} ${res.statusText}`);
      }
      setDraft("");
      await fetchFeed();
    } catch (e) {
      setError(e.message);
    } finally {
      setPosting(false);
    }
  };

  const handleDelete = async (postId) => {
    try {
      setDeleting(true);
      setError(null);
      const token = await getAccessTokenSilently();
      const res = await fetch(buildApiUrl(POSTS_API_BASE, `/api/posts/${postId}`), {
        method: "DELETE",
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok && res.status !== 204) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.message || `${res.status}`);
      }
      await fetchFeed();
    } catch (e) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const remaining = MAX_CHARS - draft.length;

  if (isLoading) {
    return (
      <div className="shell">
        <p className="loading-text">Loading…</p>
      </div>
    );
  }

  return (
    <div className="shell">
      {/* Top bar */}
      <header className="topbar">
        <h1 className="logo">tdse</h1>
        {isAuthenticated ? (
          <div className="topbar-right">
            {user?.picture && (
              <img src={user.picture} alt="" className="topbar-avatar" />
            )}
            <span className="topbar-user">{user?.name || user?.email}</span>
            <button
              className="btn btn-outline"
              onClick={() =>
                logout({ logoutParams: { returnTo: window.location.origin } })
              }
            >
              Log out
            </button>
          </div>
        ) : (
          <button className="btn btn-primary" onClick={() => loginWithRedirect()}>
            Log in
          </button>
        )}
      </header>

      <main className="main">
        {/* Compose */}
        {isAuthenticated && (
          <form className="compose" onSubmit={handlePost}>
            <textarea
              className="compose-input"
              placeholder="What's happening?"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              maxLength={MAX_CHARS}
              rows={3}
            />
            <div className="compose-footer">
              <span className={`char-count${remaining < 20 ? " warn" : ""}`}>
                {remaining}
              </span>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={posting || !draft.trim()}
              >
                {posting ? "Posting…" : "Post"}
              </button>
            </div>
          </form>
        )}

        {/* Error */}
        {error && (
          <div className="error-banner">
            <p>{error}</p>
            <button className="btn-dismiss" onClick={() => setError(null)}>
              ×
            </button>
          </div>
        )}

        {/* Feed */}
        <section className="feed">
          <div className="feed-header">
            <h2 className="feed-title">Global Feed</h2>
            <button
              className="btn btn-ghost"
              onClick={fetchFeed}
              aria-label="Refresh feed"
            >
              ↻
            </button>
          </div>

          {feedLoading ? (
            <p className="loading-text">Loading feed…</p>
          ) : posts.length === 0 ? (
            <p className="empty-text">No posts yet. Be the first!</p>
          ) : (
            <div className="feed-list">
              {posts.map((p) => (
                <PostCard
                  key={p.postId}
                  post={p}
                  onDelete={handleDelete}
                  currentUserId={currentUserId}
                  deleting={deleting}
                />
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}

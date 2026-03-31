import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './styles/globals.css';

class RootErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    console.error('[Sambhasha] Unhandled error:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          justifyContent: 'center', height: '100vh', background: '#0a0a0a',
          color: '#e0e0e0', fontFamily: 'sans-serif', padding: '2rem', textAlign: 'center',
        }}>
          <h1 style={{ color: '#25d366', fontSize: '2rem', marginBottom: '1rem' }}>Sambhasha</h1>
          <p style={{ color: '#ff6b6b', marginBottom: '0.5rem' }}>Something went wrong.</p>
          <pre style={{
            background: '#1a1a1a', padding: '1rem', borderRadius: '8px',
            fontSize: '0.8rem', color: '#aaa', maxWidth: '600px', overflowX: 'auto',
          }}>
            {this.state.error?.message}
          </pre>
          <button
            onClick={() => window.location.reload()}
            style={{
              marginTop: '1.5rem', padding: '0.6rem 1.4rem', background: '#25d366',
              color: '#000', border: 'none', borderRadius: '24px', cursor: 'pointer',
              fontWeight: '600', fontSize: '0.95rem',
            }}
          >
            Reload
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <RootErrorBoundary>
      <App />
    </RootErrorBoundary>
  </React.StrictMode>
);

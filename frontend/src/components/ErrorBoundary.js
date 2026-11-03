import React from 'react';

export default class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { failed: false };
  }

  static getDerivedStateFromError() {
    return { failed: true };
  }

  componentDidCatch(error) {
    console.error('Page rendering failed', error);
  }

  render() {
    if (this.state.failed) {
      return (
        <main className="render-error" role="alert">
          <h1>We could not display this page</h1>
          <p>Something went wrong while loading the page. Refresh and try again.</p>
          <button onClick={() => window.location.reload()}>Refresh page</button>
        </main>
      );
    }
    return this.props.children;
  }
}

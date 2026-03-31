import React, { useEffect, useRef } from 'react';
import useWebRTC from '../hooks/useWebRTC.js';

export default function VideoCall({ currentUser, peerId, chatId, onEndCall }) {
  const localVideoRef = useRef(null);
  const remoteVideoRef = useRef(null);

  const {
    localStream,
    remoteStream,
    callState,
    isMuted,
    isCameraOff,
    signalingError,
    startCall,
    endCall,
    toggleMute,
    toggleCamera,
  } = useWebRTC({
    currentUserId: currentUser.uid,
    peerId,
    chatId,
    enabled: true,
  });

  // Attach streams to video elements
  useEffect(() => {
    if (localVideoRef.current && localStream) {
      localVideoRef.current.srcObject = localStream;
    }
  }, [localStream]);

  useEffect(() => {
    if (remoteVideoRef.current && remoteStream) {
      remoteVideoRef.current.srcObject = remoteStream;
    }
  }, [remoteStream]);

  // Auto-start call and auto-close when ended
  useEffect(() => {
    startCall();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (callState === 'ended') {
      onEndCall();
    }
  }, [callState, onEndCall]);

  const handleEndCall = () => {
    endCall();
    onEndCall();
  };

  return (
    <div className="video-call-overlay" role="dialog" aria-label="Video call">
      <div className="video-call-container">
        {/* Remote video (full screen) */}
        <video
          ref={remoteVideoRef}
          className="remote-video"
          autoPlay
          playsInline
          aria-label="Remote video"
        />

        {/* Placeholder when remote stream is not yet available */}
        {!remoteStream && (
          <div className="video-placeholder">
            <div className="call-status-icon">
              {callState === 'calling' ? '📞' : '🎥'}
            </div>
            <p className="call-status-text">
              {callState === 'calling' ? 'Calling…' : 'Connecting…'}
            </p>
          </div>
        )}

        {/* Local video (picture-in-picture) */}
        <video
          ref={localVideoRef}
          className={`local-video ${isCameraOff ? 'camera-off' : ''}`}
          autoPlay
          playsInline
          muted
          aria-label="Local video"
        />

        {/* Signaling / permission errors */}
        {signalingError && (
          <div className="call-error-banner" role="alert">
            ⚠️ {signalingError}
          </div>
        )}

        {/* Call controls */}
        <div className="call-controls">
          <button
            className={`call-ctrl-btn ${isMuted ? 'ctrl-active' : ''}`}
            onClick={toggleMute}
            title={isMuted ? 'Unmute' : 'Mute'}
            aria-label={isMuted ? 'Unmute microphone' : 'Mute microphone'}
            aria-pressed={isMuted}
          >
            {isMuted ? '🔇' : '🎤'}
          </button>

          <button
            className={`call-ctrl-btn ${isCameraOff ? 'ctrl-active' : ''}`}
            onClick={toggleCamera}
            title={isCameraOff ? 'Turn camera on' : 'Turn camera off'}
            aria-label={isCameraOff ? 'Turn camera on' : 'Turn camera off'}
            aria-pressed={isCameraOff}
          >
            {isCameraOff ? '🚫' : '📷'}
          </button>

          <button
            className="call-ctrl-btn end-call-btn"
            onClick={handleEndCall}
            title="End call"
            aria-label="End call"
          >
            📵
          </button>
        </div>
      </div>
    </div>
  );
}

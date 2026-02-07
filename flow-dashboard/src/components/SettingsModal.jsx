import React, { useState } from 'react';
import { X } from 'lucide-react';
import './SettingsModal.css';
import { useToast } from './ToastContext';

const SettingsModal = ({ isOpen, onClose }) => {
  const [activeTab, setActiveTab] = useState('general');
  const { addToast } = useToast();

  const handleSave = () => {
    addToast('Settings saved successfully', 'success');
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">Settings</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <div className="modal-body">
          <div className="settings-tabs">
            <button 
              className={`tab-btn ${activeTab === 'general' ? 'active' : ''}`}
              onClick={() => setActiveTab('general')}
            >
              General
            </button>
            <button 
              className={`tab-btn ${activeTab === 'api' ? 'active' : ''}`}
              onClick={() => setActiveTab('api')}
            >
              API Keys
            </button>
            <button 
              className={`tab-btn ${activeTab === 'build' ? 'active' : ''}`}
              onClick={() => setActiveTab('build')}
            >
              Build Config
            </button>
          </div>

          {activeTab === 'general' && (
            <div className="settings-form">
              <div className="form-group">
                <label className="form-label">Project Name</label>
                <input type="text" className="form-input" defaultValue="Flow Dashboard" />
              </div>
              <div className="form-group">
                <label className="form-label">Language</label>
                <input type="text" className="form-input" defaultValue="English (US)" />
              </div>
            </div>
          )}

          {activeTab === 'api' && (
            <div className="settings-form">
              <div className="form-group">
                <label className="form-label">OpenAI API Key</label>
                <input type="password" className="form-input" placeholder="sk-..." />
              </div>
              <div className="form-group">
                <label className="form-label">Anthropic API Key</label>
                <input type="password" className="form-input" placeholder="sk-ant-..." />
              </div>
            </div>
          )}

          {activeTab === 'build' && (
            <div className="settings-form">
               <div className="form-group">
                <label className="form-label">Environment</label>
                <input type="text" className="form-input" defaultValue="Production" />
              </div>
              <div className="form-group">
                <label className="form-label">Build Command</label>
                <input type="text" className="form-input" defaultValue="npm run build" />
              </div>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={handleSave}>Save Changes</button>
        </div>
      </div>
    </div>
  );
};

export default SettingsModal;

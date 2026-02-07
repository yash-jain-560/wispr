import React, { useState } from 'react';
import Sidebar from './Sidebar';
import SettingsModal from './SettingsModal';

const Layout = ({ children }) => {
  const [showSettings, setShowSettings] = useState(false);

  return (
    <div style={{ display: 'flex' }}>
      <Sidebar onSettingsClick={() => setShowSettings(true)} />
      <main style={{ 
        marginLeft: '250px', 
        width: 'calc(100% - 250px)', 
        minHeight: '100vh',
        backgroundColor: '#FFFFFF',
        position: 'relative'
      }}>
        {children}
      </main>
      <SettingsModal isOpen={showSettings} onClose={() => setShowSettings(false)} />
    </div>
  );
};

export default Layout;

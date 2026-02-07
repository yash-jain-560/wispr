import React, { useState } from 'react';
import { 
  BarChart2, 
  LayoutGrid, 
  Book, 
  Scissors, 
  Type, 
  StickyNote, 
  Users, 
  Gift, 
  Settings, 
  HelpCircle 
} from 'lucide-react';
import './Sidebar.css';
import { useToast } from './ToastContext';

const Sidebar = ({ onSettingsClick }) => {
  const [activeItem, setActiveItem] = useState('Home');
  const { addToast } = useToast();

  const handleUpgrade = () => {
    addToast('Redirecting to payment portal...', 'info');
  };

  const navItems = [
    { label: 'Home', icon: LayoutGrid },
    { label: 'Dictionary', icon: Book },
    { label: 'Snippets', icon: Scissors },
    { label: 'Style', icon: Type },
    { label: 'Notes', icon: StickyNote },
  ];

  const footerItems = [
    { label: 'Invite your team', icon: Users },
    { label: 'Get a free month', icon: Gift },
    { label: 'Settings', icon: Settings, action: onSettingsClick },
    { label: 'Help', icon: HelpCircle },
  ];

  return (
    <aside className="sidebar">
      {/* Header */}
      <div className="sidebar-header">
        <div className="logo-container">
          <BarChart2 className="logo-icon" size={24} style={{ transform: 'rotate(90deg)' }} />
          <span>Flow</span>
        </div>
        <span className="pro-badge">Pro Trial</span>
      </div>

      {/* Main Navigation */}
      <nav className="nav-list">
        {navItems.map((item) => (
          <div 
            key={item.label}
            className={`nav-item ${activeItem === item.label ? 'active' : ''}`}
            onClick={() => setActiveItem(item.label)}
          >
            <item.icon className="nav-icon" size={20} />
            <span>{item.label}</span>
          </div>
        ))}
      </nav>

      {/* Pro Trial Object */}
      <div className="pro-card">
        <div className="pro-card-header">
          <span>Flow Pro Trial</span>
          <span className="hand-icon">👋</span>
        </div>
        <div className="usage-text">6 of 14 days used</div>
        <div className="progress-bar-bg">
          <div className="progress-bar-fill" style={{ width: '42%' }}></div>
        </div>
        <p className="pro-desc">
          Upgrade to Flow Pro to keep unlimited words and Pro features
        </p>
        <button className="upgrade-btn" onClick={handleUpgrade}>Upgrade to Pro</button>
      </div>

      {/* Footer Navigation */}
      <div className="footer-actions">
        {footerItems.map((item) => (
          <div 
            key={item.label} 
            className="nav-item"
            onClick={item.action ? item.action : undefined}
          >
            <item.icon className="nav-icon" size={20} />
            <span>{item.label}</span>
          </div>
        ))}
      </div>
    </aside>
  );
};

export default Sidebar;

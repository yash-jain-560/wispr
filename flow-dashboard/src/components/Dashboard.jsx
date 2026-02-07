import React from 'react';
import { Flame, Rocket, Trophy } from 'lucide-react';
import './Dashboard.css';
import { useToast } from './ToastContext';

const Dashboard = () => {
  const { addToast } = useToast();

  const handleShowMeHow = () => {
    addToast('Tutorial feature initiated!', 'info');
  };

  const timelineData = [
    {
      time: '10:41 PM',
      content: 'Bum-sick!'
    },
    {
      time: '10:33 PM',
      content: 'Even if you have to work entirely through the night, you have to work in and get this done. Create a full implementation plan for each section on the UI and then build one by one.'
    },
    {
      time: '10:32 PM',
      content: 'Extract each component and work on it thoroughly. I just want the exact same UI from my platform.'
    },
    {
      time: '10:31 PM',
      content: 'I can see you have a lot on this, but I\'m not able to add the API key. The UI is looking terrible right now. Please work on the UI. There should be an interesting startup and with all the functionality written, this is doing like a full marketing strategy. Good how would it be in terms of UI where everything is segregated with the proper UI design? If you want, I can share one. I\'ll attach a screenshot; you can just refer it.'
    }
  ];

  return (
    <div className="dashboard-container">
      {/* Header Row */}
      <div className="dashboard-header-row">
        <h1 className="welcome-text">Welcome back, Yash</h1>
        
        <div className="stats-bar">
          <div className="stat-item">
            <Flame size={18} fill="#FB923C" color="#FB923C" />
            <span>2 days</span>
          </div>
          <div className="stat-item">
            <Rocket size={18} fill="#A78BFA" color="#A78BFA" /> {/* Using fill for better visual match? Or just color */}
            <span>3,885 words</span>
          </div>
          <div className="stat-item">
            <Trophy size={18} fill="#FBBF24" color="#FBBF24" />
            <span>135 WPM</span>
          </div>
        </div>
      </div>

      {/* Hero Card */}
      <div className="hero-card">
        <h2 className="hero-title">
          Hold <span className="hero-strong">fn</span> to dictate and let Flow format for you
        </h2>
        <p className="hero-description">
          Press and hold <span className="hero-strong-sans">fn</span> to dictate in any app. Flow's <span className="hero-strong-sans">Smart Formatting</span> and <span className="hero-strong-sans">Backtrack</span> will handle punctuation, new lines, lists, and adjust when you change your mind mid-sentence.
        </p>
        <button className="hero-btn" onClick={handleShowMeHow}>Show me how</button>
      </div>

      {/* Timeline */}
      <div className="timeline-section">
        <div className="timeline-header">Today</div>
        <div className="timeline-feed">
          {timelineData.map((item, index) => (
            <div key={index} className="timeline-item">
              <div className="timeline-time">{item.time}</div>
              <div className="timeline-content">{item.content}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

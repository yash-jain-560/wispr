import React, { createContext, useContext, useState, useEffect } from 'react';
import { X, CheckCircle, Info, AlertTriangle } from 'lucide-react';

const ToastContext = createContext();

export const useToast = () => useContext(ToastContext);

export const ToastProvider = ({ children }) => {
  const [toasts, setToasts] = useState([]);

  const addToast = (message, type = 'info') => {
    const id = Date.now();
    setToasts((prev) => [...prev, { id, message, type }]);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
      removeToast(id);
    }, 3000);
  };

  const removeToast = (id) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  };

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      <div className="toast-container">
        {toasts.map((toast) => (
          <div key={toast.id} className={`toast toast-${toast.type}`}>
            {toast.type === 'success' && <CheckCircle size={18} />}
            {toast.type === 'info' && <Info size={18} />}
            {toast.type === 'error' && <AlertTriangle size={18} />}
            <span>{toast.message}</span>
            <button onClick={() => removeToast(toast.id)} className="toast-close">
              <X size={14} />
            </button>
          </div>
        ))}
      </div>
      <style>{`
        .toast-container {
          position: fixed;
          bottom: 24px;
          right: 24px;
          display: flex;
          flex-direction: column;
          gap: 12px;
          z-index: 2000;
        }
        .toast {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 16px;
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          font-size: 0.875rem;
          font-weight: 500;
          color: #1F2937;
          border: 1px solid #E5E7EB;
          animation: slideIn 0.3s ease-out;
          min-width: 300px;
        }
        .toast-success { border-left: 4px solid #10B981; }
        .toast-info { border-left: 4px solid #3B82F6; }
        .toast-error { border-left: 4px solid #EF4444; }
        
        .toast-close {
          margin-left: auto;
          color: #9CA3AF;
        }
        .toast-close:hover { color: #4B5563; }

        @keyframes slideIn {
          from { transform: translateX(100%); opacity: 0; }
          to { transform: translateX(0); opacity: 1; }
        }
      `}</style>
    </ToastContext.Provider>
  );
};

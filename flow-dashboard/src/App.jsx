import Layout from './components/Layout'
import Dashboard from './components/Dashboard'
import { ToastProvider } from './components/ToastContext'

function App() {
  return (
    <ToastProvider>
      <Layout>
        <Dashboard />
      </Layout>
    </ToastProvider>
  )
}

export default App

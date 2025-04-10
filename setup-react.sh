#!/bin/bash

# Exit on error
set -e

echo "Setting up React in the project..."

# Step 1: Initialize React app in 'client' folder
if [ ! -d "client" ]; then
    echo "Creating React app..."
    npx create-react-app client --use-npm
else
    echo "React app already exists in 'client'. Skipping initialization."
fi

# Step 2: Install dependencies in 'client'
cd client
echo "Installing dependencies..."
npm install plotly.js-dist-min react-router-dom --save

# Step 3: Move existing assets to 'client/src'
echo "Moving style.css and profile.jpg to client/src..."
mv ../style.css ../profile.jpg src/ || echo "Files already moved or not found."

# Step 4: Create React components
echo "Creating React components..."

# App.js
cat > src/App.js << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Dashboard from './Dashboard';
import Charts from './Charts';
import ChartDetail from './ChartDetail';
import IvrBucket from './IvrBucket';
import TfnWise from './TfnWise';
import Detail from './Detail';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/charts" element={<Charts />} />
        <Route path="/charts/:type" element={<ChartDetail />} />
        <Route path="/ivr-bucket" element={<IvrBucket />} />
        <Route path="/tfn-wise" element={<TfnWise />} />
        <Route path="/detail" element={<Detail />} />
      </Routes>
    </Router>
  );
}

export default App;
EOF

# Dashboard.js
cat > src/Dashboard.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import Plotly from 'plotly.js-dist-min';
import './style.css';

const Dashboard = () => {
  const [stats, setStats] = useState({});
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [portal, setPortal] = useState('');
  const [tfnType, setTfnType] = useState('');

  const fetchStats = async () => {
    const queryParams = new URLSearchParams({
      startDate,
      endDate,
      startTime,
      endTime,
      portal,
      tfn: tfnType
    }).toString();
    try {
      const response = await fetch(`/api/stats?${queryParams}`);
      if (!response.ok) throw new Error('Network response not ok');
      const data = await response.json();
      setStats(data);
      updateChart(data);
      updatePieChart(data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    }
  };

  useEffect(() => {
    const today = new Date();
    const day = String(today.getDate()).padStart(2, '0');
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const year = today.getFullYear();
    setStartDate(`${year}-${month}-${day}`);
    setEndDate(`${year}-${month}-${day}`);
    fetchStats();
  }, []);

  const handleFilter = () => fetchStats();

  const updateChart = (data) => {
    const barData = [{
      x: ['IVR Offered', 'IVR Abandoned', 'Queue Abandoned', 'Closed by IVR', 'Abandoned in 10 Sec', 'Abandoned in >10 Sec', 'Answered Calls'],
      y: [data.ivr_offered || 0, data.ivr_abandoned || 0, data.queue_abandoned || 0, data.closed_by_ivr || 0, data.abandoned_in_10_sec || 0, data.abandoned_in_over_10_sec || 0, data.answered_calls || 0],
      z: [0, 0, 0, 0, 0, 0, 0],
      type: 'bar',
      marker: { color: 'rgba(75, 192, 192, 0.6)', line: { color: 'rgba(75, 192, 192, 1)', width: 1 } },
      text: [data.ivr_offered || 0, data.ivr_abandoned || 0, data.queue_abandoned || 0, data.closed_by_ivr || 0, data.abandoned_in_10_sec || 0, data.abandoned_in_over_10_sec || 0, data.answered_calls || 0],
      textposition: 'auto'
    }];
    const layout = { title: 'Call Statistics (3D Bar)', scene: { xaxis: { title: 'Categories' }, yaxis: { title: 'Count', rangemode: 'tozero' }, zaxis: { title: 'Depth', range: [-1, 1] } }, margin: { l: 50, r: 30, t: 50, b: 50 } };
    Plotly.newPlot('summaryChart', barData, layout);
  };

  const updatePieChart = (data) => {
    const pieData = [{
      labels: ['IVR Offered', 'IVR Abandoned', 'Queue Abandoned', 'Closed by IVR', 'Abandoned in 10 Sec', 'Abandoned in > 10 Sec', 'Answered Calls'],
      values: [data.ivr_offered || 0, data.ivr_abandoned || 0, data.queue_abandoned || 0, data.closed_by_ivr || 0, data.abandoned_in_10_sec || 0, data.abandoned_in_over_10_sec || 0, data.answered_calls || 0],
      type: 'pie',
      hole: 0.4,
      marker: {
        colors: ['rgba(75, 192, 192, 0.6)', 'rgba(255, 99, 132, 0.6)', 'rgba(255, 206, 86, 0.6)', 'rgba(54, 162, 235, 0.6)', 'rgba(153, 102, 255, 0.6)', 'rgba(201, 203, 207, 0.6)', 'rgba(255, 159, 64, 0.6)'],
        line: { color: ['rgba(75, 192, 192, 1)', 'rgba(255, 99, 132, 1)', 'rgba(255, 206, 86, 1)', 'rgba(54, 162, 235, 1)', 'rgba(153, 102, 255, 1)', 'rgba(201, 203, 207, 1)', 'rgba(255, 159, 64, 1)'], width: 2 }
      },
      textinfo: 'percent+label',
      hoverinfo: 'label+percent+value',
      rotation: 45,
      direction: 'clockwise'
    }];
    const layout = { title: 'Call Statistics (3D-like Pie)', showlegend: true, legend: { x: 1, y: 0.5, traceorder: 'normal', font: { family: 'sans-serif', size: 12, color: '#000' }, bgcolor: '#E2E2E2', bordercolor: '#FFFFFF', borderwidth: 2 }, margin: { l: 40, r: 30, t: 50, b: 50 } };
    Plotly.newPlot('pieChart', pieData, layout);
  };

  const openDetailPage = (category) => {
    window.open(`/detail?category=${category}&startDate=${startDate}&endDate=${endDate}&portal=${portal}&tfn=${tfnType}`, '_blank');
  };

  return (
    <div>
      <header>
        <div class="logo"><i class="fas fa-headset"></i> Contact Center Dashboard</div>
        <nav>
          <ul>
            <li><Link to="/charts"><i class="fas fa-chart-bar"></i> Charts</Link></li>
            <li><Link to="/ivr-bucket"><i class="fas fa-phone-square-alt"></i> IVR Bucket</Link></li>
            <li><Link to="/tfn-wise"><i class="fas fa-list-alt"></i> TFN-Wise</Link></li>
          </ul>
        </nav>
        <div class="profile">
          <img src="profile.jpg" alt="User Profile" class="profile-img" />
          <span class="username">Admin</span>
          <div class="dropdown">
            <button class="dropbtn"><i class="fas fa-cog"></i> Settings</button>
            <div class="dropdown-content">
              <a href="#"><i class="fas fa-user"></i> Profile</a>
              <a href="#"><i class="fas fa-sign-out-alt"></i> Logout</a>
            </div>
          </div>
        </div>
      </header>
      <div class="container">
        <section class="search-bar">
          <input type="text" id="searchInput" placeholder="Search data..." onkeyup="searchTable()" />
        </section>
        <section class="filter-panel">
          <div class="filter">
            <div class="filter-item">
              <label for="start-date"><i class="fas fa-calendar-alt"></i> Start Date:</label>
              <input type="date" id="start-date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
            </div>
            <div class="filter-item">
              <label for="end-date"><i class="fas fa-calendar-alt"></i> End Date:</label>
              <input type="date" id="end-date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
            </div>
            <div class="filter-item">
              <label for="start-time"><i class="fas fa-clock"></i> Start Time:</label>
              <input type="time" id="start-time" value={startTime} onChange={(e) => setStartTime(e.target.value)} />
            </div>
            <div class="filter-item">
              <label for="end-time"><i class="fas fa-clock"></i> End Time:</label>
              <input type="time" id="end-time" value={endTime} onChange={(e) => setEndTime(e.target.value)} />
            </div>
            <div class="filter-item">
              <label for="portal"><i class="fas fa-globe"></i> Portal:</label>
              <select id="portal" value={portal} onChange={(e) => setPortal(e.target.value)}>
                <option value="">Select</option>
                <option value="CDA">CheapOair</option>
                <option value="OT">OneTravel</option>
                <option value="CDA SP">CheapOairSP</option>
                <option value="COA CA">CheapOairCA</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div class="filter-item">
              <label for="tfn-type"><i class="fas fa-phone-alt"></i> TFN Type:</label>
              <select id="tfn-type" value={tfnType} onChange={(e) => setTfnType(e.target.value)}>
                <option value="">Select</option>
                <option value="Mkt">Marketing</option>
                <option value="NM">NonMarketing</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div class="filter-item">
              <button class="btn" onClick={handleFilter}><i class="fas fa-filter"></i> Apply Filter</button>
            </div>
          </div>
        </section>
        <section class="summary-cards">
          <div class="card" onClick={() => openDetailPage('ivr_offered')}>
            <h3>IVR Offered</h3>
            <div class="card-content">
              <span class="card-icon ivr-offered-icon"><i class="fas fa-phone-volume"></i></span>
              <p id="ivroffered">{stats.ivr_offered || 0}</p>
              <span class="tooltip">Total calls offered by IVR</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('ivr_abandoned')}>
            <h3>IVR Abandoned</h3>
            <div class="card-content">
              <span class="card-icon ivr-abandoned-icon"><i class="fas fa-user-slash"></i></span>
              <p id="ivrAbandoned">{stats.ivr_abandoned || 0}</p>
              <span class="tooltip">Total calls abandoned in IVR</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('queue_abandoned')}>
            <h3>Queue Abandoned</h3>
            <div class="card-content">
              <span class="card-icon queue-abandoned-icon"><i class="fas fa-times-circle"></i></span>
              <p id="queueAbandoned">{stats.queue_abandoned || 0}</p>
              <span class="tooltip">Total calls abandoned in queue</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('closed_by_ivr')}>
            <h3>Closed by IVR</h3>
            <div class="card-content">
              <span class="card-icon closed-by-ivr-icon"><i class="fas fa-lock"></i></span>
              <p id="closedByIvr">{stats.closed_by_ivr || 0}</p>
              <span class="tooltip">Total calls closed by IVR</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('abandoned_under_10')}>
            <h3>Abandoned in 10 Sec</h3>
            <div class="card-content">
              <span class="card-icon abandoned-under-10-icon"><i class="fas fa-stopwatch"></i></span>
              <p id="abandonedUnder10">{stats.abandoned_in_10_sec || 0}</p>
              <span class="tooltip">Calls abandoned within 10 seconds</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('abandoned_over_10')}>
            <h3>Abandoned in &gt;10 Sec</h3>
            <div class="card-content">
              <span class="card-icon abandoned-over-10-icon"><i class="fas fa-hourglass-end"></i></span>
              <p id="abandonedOver10">{stats.abandoned_in_over_10_sec || 0}</p>
              <span class="tooltip">Calls abandoned after 10 seconds</span>
            </div>
          </div>
          <div class="card" onClick={() => openDetailPage('answered_calls')}>
            <h3>Answered calls</h3>
            <div class="card-content">
              <span class="card-icon answered-calls-icon"><i class="fas fa-phone-alt"></i></span>
              <p id="answeredCalls">{stats.answered_calls || 0}</p>
              <span class="tooltip">Total answered calls</span>
            </div>
          </div>
        </section>
        <section class="chart-container side-by-side-charts">
          <div id="summaryChart" class="chart"></div>
          <div id="pieChart" class="chart"></div>
        </section>
      </div>
      <footer>
        <div class="footer-content">
          <p>&copy; 2025 Contact Center Dashboard. All rights reserved.</p>
          <ul>
            <li><a href="#"><i class="fas fa-envelope"></i> Contact</a></li>
            <li><a href="#"><i class="fas fa-shield-alt"></i> Privacy Policy</a></li>
            <li><a href="#"><i class="fas fa-file-contract"></i> Terms of Service</a></li>
          </ul>
        </div>
      </footer>
    </div>
  );
};

export default Dashboard;
EOF

# Charts.js
cat > src/Charts.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';
import './style.css';

const Charts = () => {
  const chartTypes = [
    { type: 'queueStatus', title: 'Queue Status Distribution', icon: 'pie-chart' },
    { type: 'avgQueueTime', title: 'Average Queue Time Per Campaign', icon: 'bar-chart' },
    { type: 'topAgents', title: 'Top 5 Agents By Call Volume', icon: 'bar-chart' },
    { type: 'avgHandleTime', title: 'Agent Average Handle Time', icon: 'bar-chart' },
    { type: 'endReason', title: 'Calls By End Reason', icon: 'pie-chart' },
    { type: 'shortVsCompleted', title: 'Short Abandon Vs Completed Calls', icon: 'pie-chart' },
    { type: 'callsPerCampaign', title: 'Calls Per Campaign', icon: 'bar-chart' },
    { type: 'transferType', title: 'Transfer Type Breakdown', icon: 'pie-chart' },
    { type: 'callsBySkill', title: 'Calls Routed By Skill', icon: 'bar-chart' }
  ];

  return (
    <div>
      <header>
        <div class="logo">Charts & Graphs</div>
        <nav>
          <ul>
            <li><Link to="/">Dashboard</Link></li>
          </ul>
        </nav>
      </header>
      <div class="container">
        <section class="chart-icons">
          <h2>Explore Charts</h2>
          <div class="icon-grid">
            {chartTypes.map(chart => (
              <Link key={chart.type} to={`/charts/${chart.type}`} className="chart-icon">
                <img src={`https://img.icons8.com/ios-filled/50/000000/${chart.icon}.png`} alt={`${chart.icon} Chart Icon`} className="square-icon" onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'block'; }} />
                <span class="icon-fallback">{chart.icon === 'pie-chart' ? 'Pie' : 'Bar'}</span>
                <p>{chart.title}</p>
              </Link>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};

export default Charts;
EOF

# ChartDetail.js
cat > src/ChartDetail.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import Plotly from 'plotly.js-dist-min';
import './style.css';

const ChartDetail = () => {
  const { type } = useParams();
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [chartData, setChartData] = useState(null);

  const fetchChartData = async (start = '', end = '') => {
    const url = start && end
      ? `/api/charts?startDate=${encodeURIComponent(start)}&endDate=${encodeURIComponent(end)}`
      : '/api/charts';
    console.log('Fetching URL:', url);
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`Network response failed: ${response.status}`);
      const data = await response.json();
      console.log('Fetched Data:', data);
      setChartData(data);
    } catch (error) {
      console.error('Fetch Error:', error);
    }
  };

  useEffect(() => {
    fetchChartData();
  }, [type]);

  const handleFilter = () => {
    console.log('Filter Applied - Start Date:', startDate, 'End Date:', endDate);
    fetchChartData(startDate, endDate);
  };

  const chartConfigs = {
    queueStatus: {
      title: 'Queue Status Distribution',
      type: 'pie',
      data: {
        type: 'pie',
        values: chartData?.queueStatus.map(row => parseFloat(row.count) || 0) || [],
        labels: chartData?.queueStatus.map(row => row.status || 'Unknown') || [],
        textinfo: 'label+percent+value',
        hoverinfo: 'label+percent+value',
        marker: { colors: ['#FF6384', '#36A2EB', '#FFCE56'] }
      },
      annotation: 'Percentage and count of calls: Abandoned, Answered, or IVR Completed'
    },
    avgQueueTime: {
      title: 'Average Queue Time Per Campaign',
      type: 'bar',
      data: {
        x: chartData?.avgQueueTime.map(row => row.campaign || 'Unknown') || [],
        y: chartData?.avgQueueTime.map(row => parseFloat(row.avg_queue_time) || 0) || [],
        type: 'bar',
        marker: { color: '#36A2EB' },
        text: chartData?.avgQueueTime.map(row => `${parseFloat(row.avg_queue_time || 0).toFixed(2)}s`) || [],
        textposition: 'auto'
      },
      yAxis: 'Average Queue Time (seconds)',
      annotation: 'Average time calls spent in queue per campaign'
    },
    topAgents: {
      title: 'Top 5 Agents By Call Volume',
      type: 'bar',
      data: {
        x: chartData?.topAgents.map(row => row.agent || 'Unknown') || [],
        y: chartData?.topAgents.map(row => parseFloat(row.call_volume) || 0) || [],
        type: 'bar',
        marker: { color: '#FF6384' },
        text: chartData?.topAgents.map(row => row.call_volume) || [],
        textposition: 'auto'
      },
      yAxis: 'Call Count',
      annotation: 'Top 5 agents with the highest number of calls handled'
    },
    avgHandleTime: {
      title: 'Agent Average Handle Time',
      type: 'bar',
      data: {
        x: chartData?.avgHandleTime.map(row => row.agent || 'Unknown') || [],
        y: chartData?.avgHandleTime.map(row => parseFloat(row.avg_handle_time) || 0) || [],
        type: 'bar',
        marker: { color: '#FFCE56' },
        text: chartData?.avgHandleTime.map(row => `${parseFloat(row.avg_handle_time || 0).toFixed(2)}s`) || [],
        textposition: 'auto'
      },
      yAxis: 'Average Handle Time (seconds)',
      annotation: 'Average time agents spend handling calls'
    },
    endReason: {
      title: 'Calls By End Reason',
      type: 'pie',
      data: {
        type: 'pie',
        values: chartData?.endReason.map(row => parseFloat(row.count) || 0) || [],
        labels: chartData?.endReason.map(row => row.end_reason || 'Unknown') || [],
        textinfo: 'label+percent+value',
        hoverinfo: 'label+percent+value',
        marker: { colors: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF'] }
      },
      annotation: 'Distribution of reasons why calls ended'
    },
    shortVsCompleted: {
      title: 'Short Abandon Vs Completed Calls',
      type: 'pie',
      data: {
        type: 'pie',
        values: chartData?.shortVsCompleted.map(row => parseFloat(row.count) || 0) || [],
        labels: chartData?.shortVsCompleted.map(row => row.status || 'Unknown') || [],
        textinfo: 'label+percent+value',
        hoverinfo: 'label+percent+value',
        marker: { colors: ['#FF6384', '#36A2EB', '#FFCE56'] }
      },
      annotation: 'Short abandons (<10s) vs completed calls'
    },
    callsPerCampaign: {
      title: 'Calls Per Campaign',
      type: 'bar',
      data: {
        x: chartData?.callsPerCampaign.map(row => row.campaign || 'Unknown') || [],
        y: chartData?.callsPerCampaign.map(row => parseFloat(row.count) || 0) || [],
        type: 'bar',
        marker: { color: '#4BC0C0' },
        text: chartData?.callsPerCampaign.map(row => row.count) || [],
        textposition: 'auto'
      },
      yAxis: 'Call Count',
      annotation: 'Total number of calls per campaign'
    },
    transferType: {
      title: 'Transfer Type Breakdown',
      type: 'pie',
      data: {
        type: 'pie',
        values: chartData?.transferType.map(row => parseFloat(row.count) || 0) || [],
        labels: chartData?.transferType.map(row => row.transfer_type || 'Unknown') || [],
        textinfo: 'label+percent+value',
        hoverinfo: 'label+percent+value',
        marker: { colors: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0'] }
      },
      annotation: 'Distribution of call transfer types'
    },
    callsBySkill: {
      title: 'Calls Routed By Skill',
      type: 'bar',
      data: {
        x: chartData?.callsBySkill.map(row => row.skill || 'Unknown') || [],
        y: chartData?.callsBySkill.map(row => parseFloat(row.count) || 0) || [],
        type: 'bar',
        marker: { color: '#9966FF' },
        text: chartData?.callsBySkill.map(row => row.count) || [],
        textposition: 'auto'
      },
      yAxis: 'Call Count',
      annotation: 'Total calls routed per skill'
    }
  };

  useEffect(() => {
    if (chartData && chartConfigs[type]) {
      const config = chartConfigs[type];
      const layout = {
        title: { text: config.title, font: { size: 20 } },
        showlegend: true,
        legend: { x: 1, y: 0.5, font: { size: 12 } },
        yaxis: config.yAxis ? { title: config.yAxis, titlefont: { size: 14 } } : {},
        annotations: [{
          x: 0.5,
          y: -0.15,
          xref: 'paper',
          yref: 'paper',
          text: config.annotation,
          showarrow: false,
          font: { size: 12, color: '#333' }
        }],
        margin: { b: 100, t: 50, l: 50, r: 50 },
        autosize: true,
        plot_bgcolor: '#f9f9f9',
        paper_bgcolor: '#f9f9f9'
      };
      Plotly.newPlot('chart', [config.data], layout, { responsive: true, displayModeBar: false });
    }
  }, [chartData, type]);

  return (
    <div>
      <header>
        <div class="logo" id="chart-title">{chartConfigs[type]?.title || 'Chart Details'}</div>
        <nav>
          <ul>
            <li><Link to="/">Dashboard</Link></li>
            <li><Link to="/charts">Back to Charts</Link></li>
          </ul>
        </nav>
      </header>
      <div class="container">
        <div class="filter-section">
          <label htmlFor="startDate">Start Date:</label>
          <input type="date" id="startDate" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          <label htmlFor="endDate">End Date:</label>
          <input type="date" id="endDate" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          <button onClick={handleFilter}>Apply Filter</button>
        </div>
        <div id="chart" class="chart"></div>
      </div>
    </div>
  );
};

export default ChartDetail;
EOF

# IvrBucket.js
cat > src/IvrBucket.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import './style.css';

const IvrBucket = () => {
  const [data, setData] = useState([]);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const fetchIVRBucketData = async () => {
    const queryParams = new URLSearchParams({ startDate, endDate }).toString();
    const url = `/api/ivr-bucket?${queryParams}`;
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Network response was not ok');
      const data = await response.json();
      setData(data);
    } catch (error) {
      console.error('Error fetching IVR Bucket data:', error);
    }
  };

  useEffect(() => {
    fetchIVRBucketData();
  }, []);

  const handleFilter = () => fetchIVRBucketData();

  return (
    <div>
      <header>
        <div class="logo">IVR Bucket</div>
        <nav>
          <ul>
            <li><Link to="/">Dashboard</Link></li>
            <li><Link to="/charts">Charts</Link></li>
          </ul>
        </nav>
      </header>
      <div class="container">
        <div class="filter-panel">
          <h3>Filters</h3>
          <div class="filter-item">
            <label for="start-date"><i class="fas fa-calendar-alt"></i> Start Date:</label>
            <input type="date" id="start-date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div class="filter-item">
            <label for="end-date"><i class="fas fa-calendar-alt"></i> End Date:</label>
            <input type="date" id="end-date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
          <button class="apply-filter-btn" onClick={handleFilter}><i class="fas fa-filter"></i> Apply Filter</button>
        </div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Hour</th>
              <th>Total Offered Calls</th>
              <th>Total IVR Abandoned</th>
              <th>Calls in 0-30 Sec</th>
              <th>Calls in 30-60 Sec</th>
              <th>Calls in 60-120 Sec</th>
              <th>Calls Over 120 Sec</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row, index) => (
              <tr key={index}>
                <td>{row.date}</td>
                <td>{row.time}</td>
                <td>{row.offered_calls}</td>
                <td>{row.ivr_abandon}</td>
                <td>{row["0-30 Seconds"]}</td>
                <td>{row["30-60 Seconds"]}</td>
                <td>{row["60-120 Seconds"]}</td>
                <td>{row[">120 Seconds"]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default IvrBucket;
EOF

# TfnWise.js
cat > src/TfnWise.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import './style.css';

const TfnWise = () => {
  const [data, setData] = useState([]);
  const [tfnSearch, setTfnSearch] = useState('');

  const fetchTFNWiseData = async () => {
    const queryParams = new URLSearchParams({ tfnSearch }).toString();
    const url = `/api/tfn-wise?${queryParams}`;
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Network response was not ok');
      const data = await response.json();
      setData(data);
    } catch (error) {
      console.error('Error fetching TFN-Wise data:', error);
    }
  };

  useEffect(() => {
    fetchTFNWiseData();
  }, []);

  const handleFilter = () => fetchTFNWiseData();

  return (
    <div>
      <header>
        <div class="logo">TFN Wise Data</div>
        <nav>
          <ul>
            <li><Link to="/">Dashboard</Link></li>
            <li><Link to="/charts">Charts</Link></li>
          </ul>
        </nav>
      </header>
      <div class="container">
        <div class="filter-panel">
          <h3>Filters</h3>
          <div class="filter-item">
            <label for="tfn-search"><i class="fas fa-search"></i> TFN Search:</label>
            <input type="text" id="tfn-search" value={tfnSearch} onChange={(e) => setTfnSearch(e.target.value)} placeholder="Enter TFN..." />
          </div>
          <button class="apply-filter-btn" onClick={handleFilter}><i class="fas fa-filter"></i> Apply Filter</button>
        </div>
        <table class="data-table">
          <thead>
            <tr>
              <th>TFN Number</th>
              <th>Total Offered Calls</th>
              <th>IVR Abandoned Calls</th>
              <th>Queue Abandoned Calls</th>
              <th>Polite Disconnect Calls</th>
              <th>Agent Answered Calls</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row, index) => (
              <tr key={index}>
                <td>{row["Number (toAddress)"] || 'N/A'}</td>
                <td>{row.offered_calls || 0}</td>
                <td>{row.ivr_abandon || 0}</td>
                <td>{row.queue_abandon || 0}</td>
                <td>{row.polite_disconnect || 0}</td>
                <td>{row.answered || 0}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default TfnWise;
EOF

# Detail.js
cat > src/Detail.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import './style.css';

const Detail = () => {
  const [data, setData] = useState([]);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [portal, setPortal] = useState('');
  const [tfn, setTfn] = useState('');
  const [tfnSearch, setTfnSearch] = useState('');
  const urlParams = new URLSearchParams(window.location.search);
  const category = urlParams.get('category');

  const fetchDetailData = async () => {
    const queryParams = new URLSearchParams({
      category,
      startDate,
      endDate,
      portal,
      tfn,
      tfnSearch
    }).toString();
    const url = `/api/detail?${queryParams}`;
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Network response was not ok');
      const data = await response.json();
      setData(data);
    } catch (error) {
      console.error('Error fetching detail data:', error);
    }
  };

  useEffect(() => {
    fetchDetailData();
  }, []);

  const handleFilter = () => fetchDetailData();

  const downloadCSV = () => {
    const rows = data.map(row => [
      row.TFN,
      row.Description,
      row.ivr_offered,
      row.ivr_abandoned,
      row.queue_abandoned,
      row.closed_by_ivr,
      row.answered_calls,
      row.Portal,
      row["TFN Type"]
    ]);
    const csvContent = [
      ['TFN Number', 'TFN Description', 'IVR Offered Calls', 'IVR Abandoned Calls', 'Queue Abandoned Calls', 'Closed by IVR Calls', 'Agent Answered Calls', 'Portal Name', 'TFN Category'],
      ...rows
    ].map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'detail_data.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  };

  return (
    <div>
      <header>
        <div class="logo">Detail Data</div>
        <nav>
          <ul>
            <li><Link to="/">Dashboard</Link></li>
            <li><Link to="/charts">Charts</Link></li>
          </ul>
        </nav>
      </header>
      <div class="container">
        <div class="filter-panel">
          <h3>Filters</h3>
          <div class="filter-item">
            <label for="start-date"><i class="fas fa-calendar-alt"></i> Start Date:</label>
            <input type="date" id="start-date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div class="filter-item">
            <label for="end-date"><i class="fas fa-calendar-alt"></i> End Date:</label>
            <input type="date" id="end-date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
          <div class="filter-item">
            <label for="portal"><i class="fas fa-globe"></i> Portal:</label>
            <select id="portal" value={portal} onChange={(e) => setPortal(e.target.value)}>
              <option value="">All</option>
              <option value="CDA">CDA</option>
              <option value="VDA">VDA</option>
            </select>
          </div>
          <div class="filter-item">
            <label for="tfn-type"><i class="fas fa-phone"></i> TFN Type:</label>
            <select id="tfn-type" value={tfn} onChange={(e) => setTfn(e.target.value)}>
              <option value="">All</option>
              <option value="Mkt">Mkt</option>
              <option value="Non-Mkt">Non-Mkt</option>
            </select>
          </div>
          <div class="filter-item">
            <label for="tfn-search"><i class="fas fa-search"></i> TFN Search:</label>
            <input type="text" id="tfn-search" value={tfnSearch} onChange={(e) => setTfnSearch(e.target.value)} placeholder="Enter TFN..." />
          </div>
          <button class="apply-filter-btn" onClick={handleFilter}><i class="fas fa-filter"></i> Apply Filter</button>
          <button class="download-btn" onClick={downloadCSV}><i class="fas fa-download"></i> Download CSV</button>
        </div>
        <table class="data-table">
          <thead>
            <tr>
              <th>TFN Number</th>
              <th>TFN Description</th>
              <th>IVR Offered Calls</th>
              <th>IVR Abandoned Calls</th>
              <th>Queue Abandoned Calls</th>
              <th>Closed by IVR Calls</th>
              <th>Agent Answered Calls</th>
              <th>Portal Name</th>
              <th>TFN Category</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row, index) => (
              <tr key={index}>
                <td>{row.TFN}</td>
                <td>{row.Description}</td>
                <td>{row.ivr_offered}</td>
                <td>{row.ivr_abandoned}</td>
                <td>{row.queue_abandoned}</td>
                <td>{row.closed_by_ivr}</td>
                <td>{row.answered_calls}</td>
                <td>{row.Portal}</td>
                <td>{row["TFN Type"]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Detail;
EOF

# Step 5: Update script.js to serve React build
echo "Updating script.js..."
cd ..
cat > script.js << 'EOF'
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const path = require('path');
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'client', 'build')));

const pool = new Pool({
    host: '10.7.32.134',
    user: 'postgres',
    password: 'automation@123',
    database: 'postgres',
    port: 5432
});

app.get('/api/stats', async (req, res) => {
    try {
        const { startDate, endDate, portal, tfn } = req.query;
        let query = `
            SELECT
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4') AS ivr_offered,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = 'False' AND "preQueueSeconds"::numeric > 1  AND "endReason" = 'Contact Hung Up') AS ivr_abandoned,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric > 0 AND "abandoned" = 'True' AND "preQueueSeconds"::numeric > 0) AS queue_abandoned,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = 'False' AND "preQueueSeconds"::numeric > 1 AND "endReason" = 'Contact Hang Up via Script') AS closed_by_ivr,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "abandoned" = 'True' AND "preQueueSeconds"::numeric < 10) AS abandoned_in_10_sec,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "abandoned" = 'True' AND "preQueueSeconds"::numeric > 10) AS abandoned_in_over_10_sec,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "abandoned" = 'False' AND "agentSeconds"::numeric > 0) AS answered_calls
            FROM contact_mapped_data
        `;

        const queryParams = [];

        if (startDate && endDate) {
            query += ' WHERE to_date("contactStartDate", \'YYYY-MM-DD\') BETWEEN $1 AND $2';
            queryParams.push(startDate, endDate);
        }

        if (portal) {
            query += queryParams.length ? ' AND' : ' WHERE';
            query += ' "Portal" ILIKE $3'; 
            queryParams.push(portal);
        }
        if (tfn) {
            query += queryParams.length ? ' AND' : ' WHERE';
            query += ' "TFN Type" ILIKE $4';
            queryParams.push(tfn);
        }

        const result = await pool.query(query, queryParams);
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching stats:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/api/detail', async (req, res) => {
    try {
        const { category, startDate, endDate, portal, tfn, tfnSearch } = req.query;
        let query = `
            SELECT "toAddress" AS "TFN", "Description", 
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4') AS ivr_offered,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = 'False' AND "preQueueSeconds"::numeric > 1  AND "endReason" = 'Contact Hung Up') AS ivr_abandoned,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric > 0 AND "abandoned" = 'True' AND "preQueueSeconds"::numeric > 0) AS queue_abandoned,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = 'False' AND "preQueueSeconds"::numeric > 1 AND "endReason" = 'Contact Hang Up via Script') AS closed_by_ivr,
            COUNT(*) FILTER (WHERE "masterContactId" = "contactId" AND "isOutbound" = 'False' AND "mediaTypeId" = '4' AND "abandoned" = 'False' AND "agentSeconds"::numeric > 0) AS answered_calls,
            "Portal", "TFN Type"
            FROM contact_mapped_data
        `;

        const queryParams = [];
        let paramIndex = 1;

        if (startDate && endDate) {
            query += ' WHERE to_date("contactStartDate", \'YYYY-MM-DD\') BETWEEN $' + paramIndex++ + ' AND $' + paramIndex++;
            queryParams.push(startDate, endDate);
        }

        if (portal) {
            query += queryParams.length ? ' AND' : ' WHERE';
            query += ' "Portal" = $' + paramIndex++;
            queryParams.push(portal);
        }

        if (tfn) {
            query += queryParams.length ? ' AND' : ' WHERE';
            query += ' "TFN Type" = $' + paramIndex++;
            queryParams.push(tfn);
        }

        const validCategories = [
            'ivr_offered',
            'ivr_abandoned',
            'queue_abandoned',
            'closed_by_ivr',
            'abandoned_under_10',
            'abandoned_over_10',
            'answered_calls'
        ];
        if (tfnSearch && validCategories.includes(category)) {
            query += queryParams.length ? ' AND' : ' WHERE';
            query += ' "toAddress" ILIKE $' + paramIndex++;
            queryParams.push(`%${tfnSearch}%`);
        }

        switch(category) {
            case 'ivr_offered':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\'';
                break;
            case 'ivr_abandoned':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = \'False\' AND "preQueueSeconds"::numeric > 1 AND "endReason" = \'Contact Hung Up\'';
                break;
            case 'queue_abandoned':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric > 0 AND "abandoned" = \'True\' AND "preQueueSeconds"::numeric > 0';
                break;
            case 'closed_by_ivr':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "agentSeconds"::numeric = 0 AND "inQueueSeconds"::numeric = 0 AND "abandoned" = \'False\' AND "preQueueSeconds"::numeric > 1 AND "endReason" = \'Contact Hang Up via Script\'';
                break;
            case 'abandoned_under_10':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "abandoned" = \'True\' AND "preQueueSeconds"::numeric < 10';
                break;
            case 'abandoned_over_10':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "abandoned" = \'True\' AND "preQueueSeconds"::numeric > 10';
                break;
            case 'answered_calls':
                query += ' AND "masterContactId" = "contactId" AND "isOutbound" = \'False\' AND "mediaTypeId" = \'4\' AND "abandoned" = \'False\' AND "agentSeconds"::numeric > 0';
                break;
            default:
                return res.status(400).json({ error: 'Invalid category' });
        }

        query += ' GROUP BY "toAddress", "Description", "Portal", "TFN Type"';
        const result = await pool.query(query, queryParams);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching detail data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/api/tfn-wise', async (req, res) => {
    try {
        const { tfnSearch } = req.query;
        console.log('TFN-Wise Request Params:', { tfnSearch });

        let query = `
            SELECT 
                "toAddress" AS "Number (toAddress)",  
                COUNT(*) FILTER (WHERE 
                    "masterContactId" = "contactId" 
                    AND "isOutbound" = 'False' 
                    AND "mediaTypeId" = '4'
                ) AS offered_calls,
                COUNT(*) FILTER (WHERE 
                    "masterContactId" = "contactId" 
                    AND "isOutbound" = 'False' 
                    AND "mediaTypeId" = '4' 
                    AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) = 0
                    AND COALESCE(NULLIF("inQueueSeconds", '')::FLOAT, 0) = 0
                    AND COALESCE(NULLIF("preQueueSeconds", '')::FLOAT, 0) > 1
                    AND COALESCE(NULLIF("abandoned", ''), 'False') = 'False'
                    AND "endReason" = 'Contact Hung Up'
                ) AS ivr_abandon,
                COUNT(*) FILTER (WHERE 
                    "masterContactId" = "contactId" 
                    AND "isOutbound" = 'False' 
                    AND "mediaTypeId" = '4' 
                    AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) = 0
                    AND COALESCE(NULLIF("inQueueSeconds", '')::FLOAT, 0) > 0
                    AND COALESCE(NULLIF("preQueueSeconds", '')::FLOAT, 0) > 0
                    AND COALESCE(NULLIF("abandoned", ''), 'True') = 'True'
                ) AS queue_abandon,
                COUNT(*) FILTER (WHERE 
                    "masterContactId" = "contactId" 
                    AND "isOutbound" = 'False' 
                    AND "mediaTypeId" = '4' 
                    AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) = 0
                    AND COALESCE(NULLIF("inQueueSeconds", '')::FLOAT, 0) = 0
                    AND COALESCE(NULLIF("preQueueSeconds", '')::FLOAT, 0) > 1
                    AND COALESCE(NULLIF("abandoned", ''), 'False') = 'False'
                    AND "endReason" = 'Contact Hang Up via Script'
                ) AS polite_disconnect,
                COUNT(*) FILTER (WHERE 
                    "masterContactId" = "contactId" 
                    AND "isOutbound" = 'False' 
                    AND "mediaTypeId" = '4' 
                    AND COALESCE(NULLIF("abandoned", ''), 'False') = 'False' 
                    AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) > 0
                ) AS answered
            FROM contact_mapped_data
        `;

        const queryParams = [];
        let paramIndex = 1;

        if (tfnSearch) {
            query += ' WHERE "toAddress" ILIKE $' + paramIndex++;
            queryParams.push(`%${tfnSearch}%`);
        }

        query += ' GROUP BY "toAddress" ORDER BY offered_calls DESC';

        console.log('Executing Query:', query);
        console.log('Query Params:', queryParams);

        const result = await pool.query(query, queryParams);
        console.log('Query Result:', result.rows);

        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching TFN-Wise data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/api/ivr-bucket', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        let query = `
            WITH processed_data AS (
                SELECT 
                    TO_TIMESTAMP("contactStartDate", 'YYYY-MM-DD HH24:MI:SS') AS contact_start_time,
                    "toAddress",
                    "abandoned",
                    COALESCE(NULLIF("preQueueSeconds", '')::FLOAT::INTEGER, 0) AS ivr_duration
                FROM contact_mapped_data
                WHERE "contactStartDate" IS NOT NULL
            )
            SELECT 
                TO_CHAR(DATE_TRUNC('hour', contact_start_time), 'YYYY-MM-DD') AS date,  
                TO_CHAR(DATE_TRUNC('hour', contact_start_time), 'HH24:MI') AS time,  
                COUNT(*) AS offered_calls,  
                SUM(CASE WHEN abandoned = 'true' THEN 1 ELSE 0 END) AS ivr_abandon,
                SUM(CASE WHEN ivr_duration BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS "0-30 Seconds",
                SUM(CASE WHEN ivr_duration BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS "30-60 Seconds",
                SUM(CASE WHEN ivr_duration BETWEEN 61 AND 120 THEN 1 ELSE 0 END) AS "60-120 Seconds",
                SUM(CASE WHEN ivr_duration > 120 THEN 1 ELSE 0 END) AS ">120 Seconds"
            FROM processed_data
        `;

        const queryParams = [];

        if (startDate && endDate) {
            query += ' WHERE to_date(contact_start_time::TEXT, \'YYYY-MM-DD\') BETWEEN $1 AND $2';
            queryParams.push(startDate, endDate);
        }

        query += ' GROUP BY date, time ORDER BY date, time';
        const result = await pool.query(query, queryParams);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching IVR Bucket data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('/api/charts', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        console.log('Received Query Params:', { startDate, endDate });
        const chartsData = {};
        
        let dateFilter = '';
        const queryParams = [];
        if (startDate && endDate) {
            dateFilter = ' AND DATE("contactStartDate") BETWEEN $1 AND $2';
            queryParams.push(startDate, endDate);
        } else {
            console.log('No date filter applied');
        }

        const queries = {
            queueStatus: `SELECT CASE WHEN COALESCE(NULLIF("abandoned", ''), 'False') = 'True' THEN 'Abandoned' WHEN COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) > 0 THEN 'Answered' ELSE 'IVR Completed' END AS status, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY status`,
            avgQueueTime: `SELECT COALESCE("campaignId", 'Unknown') AS campaign, AVG(COALESCE(NULLIF("inQueueSeconds", '')::FLOAT, 0)) AS avg_queue_time FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY "campaignId"`,
            topAgents: `SELECT COALESCE("agentId", 'Unknown') AS agent, COUNT(*) AS call_volume FROM contact_mapped_data WHERE "mediaTypeId" = '4' AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) > 0${dateFilter} GROUP BY "agentId" ORDER BY call_volume DESC LIMIT 5`,
            avgHandleTime: `SELECT COALESCE("agentId", 'Unknown') AS agent, AVG(COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0)) AS avg_handle_time FROM contact_mapped_data WHERE "mediaTypeId" = '4' AND COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) > 0${dateFilter} GROUP BY "agentId"`,
            endReason: `SELECT COALESCE("endReason", 'Unknown') AS end_reason, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY "endReason"`,
            shortVsCompleted: `SELECT CASE WHEN COALESCE(NULLIF("abandoned", ''), 'False') = 'True' AND COALESCE(NULLIF("preQueueSeconds", '')::FLOAT, 0) < 10 THEN 'Short Abandon' WHEN COALESCE(NULLIF("agentSeconds", '')::FLOAT, 0) > 0 THEN 'Completed' ELSE 'Other' END AS status, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY status`,
            callsPerCampaign: `SELECT COALESCE("campaignId", 'Unknown') AS campaign, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY "campaignId"`,
            transferType: `SELECT COALESCE("transferIndicatorId", 'No Transfer') AS transfer_type, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY "transferIndicatorId"`,
            callsBySkill: `SELECT COALESCE("skillId", 'Unknown') AS skill, COUNT(*) AS count FROM contact_mapped_data WHERE "mediaTypeId" = '4'${dateFilter} GROUP BY "skillId"`
        };

        for (const [key, query] of Object.entries(queries)) {
            const result = await pool.query(query, queryParams);
            chartsData[key] = result.rows;
            console.log(`Query Result for ${key}:`, result.rows);
        }

        console.log('Charts API Response:', chartsData);
        res.json(chartsData);
    } catch (err) {
        console.error('Error fetching charts data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'client', 'build', 'index.html'));
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
EOF

# Step 6: Install backend dependencies
echo "Installing backend dependencies..."
npm install express pg cors || echo "Backend dependencies already installed."

# Step 7: Build React app
echo "Building React app..."
cd client
npm run build

echo "Setup complete! Run 'node ../script.js' from the project root to start the server."
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const pool = new Pool({
    host: '10.7.32.134',
    user: 'postgres',
    password: 'automation@123',
    database: 'postgres',
    port: 5432
});

// Endpoint for Queue Status Distribution
app.get('/api/queueStatusDistribution', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "contactId", 
                "preQueueSeconds"::numeric, 
                "inQueueSeconds"::numeric, 
                "postQueueSeconds"::numeric 
            FROM contact_mapped_data
        `);
        const data = result.rows.reduce((acc, row) => {
            acc.labels.push(row.contactId);
            acc.preQueueSeconds.push(row.preQueueSeconds);
            acc.inQueueSeconds.push(row.inQueueSeconds);
            acc.postQueueSeconds.push(row.postQueueSeconds);
            return acc;
        }, { labels: [], preQueueSeconds: [], inQueueSeconds: [], postQueueSeconds: [] });

        console.log('Queue Status Distribution Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching queue status distribution data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Average Queue Time Per Campaign
app.get('/api/averageQueueTimePerCampaign', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "campaignName", 
                AVG("preQueueSeconds"::numeric) AS avgPreQueue,
                AVG("inQueueSeconds"::numeric) AS avgInQueue,
                AVG("postQueueSeconds"::numeric) AS avgPostQueue
            FROM contact_mapped_data
            GROUP BY "campaignName"
        `);
        const data = result.rows.reduce((acc, row) => {
            acc.labels.push(row.campaignName);
            acc.avgPreQueue.push(row.avgprequeue);
            acc.avgInQueue.push(row.avginqueue);
            acc.avgPostQueue.push(row.avgpostqueue);
            return acc;
        }, { labels: [], avgPreQueue: [], avgInQueue: [], avgPostQueue: [] });

        console.log('Average Queue Time Per Campaign Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching average queue time per campaign data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Top 5 Agents by Call Volume
app.get('/api/top5AgentsByCallVolume', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "agentId", 
                COUNT("contactId") AS callVolume
            FROM contact_mapped_data
            GROUP BY "agentId"
            ORDER BY callVolume DESC
            LIMIT 5
        `);
        const data = { labels: [], callVolume: [] };
        result.rows.forEach(row => {
            data.labels.push(row.agentId);
            data.callVolume.push(row.callVolume);
        });

        console.log('Top 5 Agents By Call Volume Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching top 5 agents by call volume data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Agent Average Handle Time
app.get('/api/agentAverageHandleTime', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "agentId", 
                AVG("agentSeconds"::numeric) AS avgHandleTime
            FROM contact_mapped_data
            GROUP BY "agentId"
        `);
        const data = { labels: [], avgHandleTime: [] };
        result.rows.forEach(row => {
            data.labels.push(row.agentId);
            data.avgHandleTime.push(row.avgHandleTime);
        });

        console.log('Agent Average Handle Time Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching agent average handle time data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Calls by End Reason
app.get('/api/callsByEndReason', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "endReason", 
                COUNT("contactId") AS callCount
            FROM contact_mapped_data
            GROUP BY "endReason"
        `);
        const data = { labels: [], callCount: [] };
        result.rows.forEach(row => {
            data.labels.push(row.endReason);
            data.callCount.push(row.callCount);
        });

        console.log('Calls By End Reason Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching calls by end reason data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Short Abandon vs Completed Calls
app.get('/api/shortAbandonVsCompletedCalls', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "isShortAbandon", 
                COUNT("contactId") AS callCount,
                "endReason"
            FROM contact_mapped_data
            GROUP BY "isShortAbandon", "endReason"
        `);
        const data = result.rows.reduce((acc, row) => {
            if (row.isShortAbandon === 'True') {
                acc.shortAbandon[row.endReason] = row.callCount;
            } else {
                acc.completed[row.endReason] = row.callCount;
            }
            return acc;
        }, { shortAbandon: {}, completed: {} });

        console.log('Short Abandon Vs Completed Calls Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching short abandon vs completed calls data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Calls Per Campaign
app.get('/api/callsPerCampaign', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "campaignName", 
                COUNT("contactId") AS callCount
            FROM contact_mapped_data
            GROUP BY "campaignName"
        `);
        const data = { labels: [], callCount: [] };
        result.rows.forEach(row => {
            data.labels.push(row.campaignName);
            data.callCount.push(row.callCount);
        });

        console.log('Calls Per Campaign Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching calls per campaign data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Transfer Type Breakdown
app.get('/api/transferTypeBreakdown', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "transferIndicatorName", 
                COUNT("contactId") AS callCount
            FROM contact_mapped_data
            GROUP BY "transferIndicatorName"
        `);
        const data = { labels: [], callCount: [] };
        result.rows.forEach(row => {
            data.labels.push(row.transferIndicatorName);
            data.callCount.push(row.callCount);
        });

        console.log('Transfer Type Breakdown Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching transfer type breakdown data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Endpoint for Calls Routed by Skill
app.get('/api/callsRoutedBySkill', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                "skillName", 
                COUNT("contactId") AS callCount
            FROM contact_mapped_data
            GROUP BY "skillName"
        `);
        const data = { labels: [], callCount: [] };
        result.rows.forEach(row => {
            data.labels.push(row.skillName);
            data.callCount.push(row.callCount);
        });

        console.log('Calls Routed By Skill Data:', data); // Debugging line
        res.json(data);
    } catch (err) {
        console.error('Error fetching calls routed by skill data:', err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
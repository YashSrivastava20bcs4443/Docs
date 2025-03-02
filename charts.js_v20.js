async function fetchData(endpoint) {
    const response = await fetch(`http://localhost:3000/api/${endpoint}`);
    const data = await response.json();
    console.log(`Data fetched from ${endpoint}:`, data); // Debugging line
    return data;
}

function renderQueueStatusDistribution(data) {
    const trace1 = {
        x: data.labels,
        y: data.preQueueSeconds,
        name: 'Pre Queue',
        type: 'bar'
    };

    const trace2 = {
        x: data.labels,
        y: data.inQueueSeconds,
        name: 'In Queue',
        type: 'bar'
    };

    const trace3 = {
        x: data.labels,
        y: data.postQueueSeconds,
        name: 'Post Queue',
        type: 'bar'
    };

    const layout = {
        barmode: 'stack',
        title: 'Queue Status Distribution'
    };

    const dataPlot = [trace1, trace2, trace3];

    Plotly.newPlot('queueStatusDistribution', dataPlot, layout);
}

function renderAverageQueueTimePerCampaign(data) {
    const trace1 = {
        x: data.labels,
        y: data.avgPreQueue,
        name: 'Avg Pre Queue',
        type: 'bar'
    };

    const trace2 = {
        x: data.labels,
        y: data.avgInQueue,
        name: 'Avg In Queue',
        type: 'bar'
    };

    const trace3 = {
        x: data.labels,
        y: data.avgPostQueue,
        name: 'Avg Post Queue',
        type: 'bar'
    };

    const layout = {
        barmode: 'stack',
        title: 'Average Queue Time Per Campaign'
    };

    const dataPlot = [trace1, trace2, trace3];

    Plotly.newPlot('averageQueueTimePerCampaign', dataPlot, layout);
}

function renderTop5AgentsByCallVolume(data) {
    const trace = {
        x: data.callVolume,
        y: data.labels,
        type: 'bar',
        orientation: 'h'
    };

    const layout = {
        title: 'Top 5 Agents By Call Volume'
    };

    Plotly.newPlot('top5AgentsByCallVolume', [trace], layout);
}

function renderAgentAverageHandleTime(data) {
    const trace = {
        x: data.labels,
        y: data.avgHandleTime,
        type: 'bar'
    };

    const layout = {
        title: 'Agent Average Handle Time'
    };

    Plotly.newPlot('agentAverageHandleTime', [trace], layout);
}

function renderCallsByEndReason(data) {
    const trace = {
        labels: data.labels,
        values: data.callCount,
        type: 'pie'
    };

    const layout = {
        title: 'Calls By End Reason'
    };

    Plotly.newPlot('callsByEndReason', [trace], layout);
}

function renderShortAbandonVsCompletedCalls(data) {
    const trace1 = {
        x: Object.keys(data.shortAbandon),
        y: Object.values(data.shortAbandon),
        name: 'Short Abandon',
        type: 'bar'
    };

    const trace2 = {
        x: Object.keys(data.completed),
        y: Object.values(data.completed),
        name: 'Completed',
        type: 'bar'
    };

    const layout = {
        barmode: 'stack',
        title: 'Short Abandon Vs Completed Calls'
    };

    const dataPlot = [trace1, trace2];

    Plotly.newPlot('shortAbandonVsCompletedCalls', dataPlot, layout);
}

function renderCallsPerCampaign(data) {
    const trace = {
        x: data.labels,
        y: data.callCount,
        type: 'bar'
    };

    const layout = {
        title: 'Calls Per Campaign'
    };

    Plotly.newPlot('callsPerCampaign', [trace], layout);
}

function renderTransferTypeBreakdown(data) {
    const trace = {
        labels: data.labels,
        values: data.callCount,
        type: 'pie'
    };

    const layout = {
        title: 'Transfer Type Breakdown'
    };

    Plotly.newPlot('transferTypeBreakdown', [trace], layout);
}

function renderCallsRoutedBySkill(data) {
    const trace = {
        x: data.labels,
        y: data.callCount,
        type: 'bar'
    };

    const layout = {
        title: 'Calls Routed By Skill'
    };

    Plotly.newPlot('callsRoutedBySkill', [trace], layout);
}

async function renderCharts() {
    const queueStatusDistributionData = await fetchData('queueStatusDistribution');
    renderQueueStatusDistribution(queueStatusDistributionData);

    const averageQueueTimePerCampaignData = await fetchData('averageQueueTimePerCampaign');
    renderAverageQueueTimePerCampaign(averageQueueTimePerCampaignData);

    const top5AgentsByCallVolumeData = await fetchData('top5AgentsByCallVolume');
    renderTop5AgentsByCallVolume(top5AgentsByCallVolumeData);

    const agentAverageHandleTimeData = await fetchData('agentAverageHandleTime');
    renderAgentAverageHandleTime(agentAverageHandleTimeData);

    const callsByEndReasonData = await fetchData('callsByEndReason');
    renderCallsByEndReason(callsByEndReasonData);

    const shortAbandonVsCompletedCallsData = await fetchData('shortAbandonVsCompletedCalls');
    renderShortAbandonVsCompletedCalls(shortAbandonVsCompletedCallsData);

    const callsPerCampaignData = await fetchData('callsPerCampaign');
    renderCallsPerCampaign(callsPerCampaignData);

    const transferTypeBreakdownData = await fetchData('transferTypeBreakdown');
    renderTransferTypeBreakdown(transferTypeBreakdownData);

    const callsRoutedBySkillData = await fetchData('callsRoutedBySkill');
    renderCallsRoutedBySkill(callsRoutedBySkillData);
}

window.onload = renderCharts;
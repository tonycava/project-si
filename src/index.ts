import { DescribeClusterCommand, EKSClient } from '@aws-sdk/client-eks';
import axios from 'axios';

type Event = {
	clusterName: string;
}

export const handler = async (event: Event) => {
	const eks = new EKSClient({ region: 'eu-west-3' });

	const clusterName = event.clusterName;

	try {
		const describeClusterCommand = new DescribeClusterCommand({
			name: clusterName,
		});

		const describeClusterResponse = await eks.send(describeClusterCommand);

		if (describeClusterResponse.cluster) {
			const cluster = describeClusterResponse.cluster;
			const clusterStatus = cluster.status;

			// Perform your logic based on the cluster status
			if (clusterStatus === 'ACTIVE') {
				await sendDiscordMessage('Cluster is alive!');
				console.log('Cluster is alive!');
			} else {
				await sendDiscordMessage('Cluster is not alive!');
				console.log('Cluster is not alive!');
			}
		} else {
			await sendDiscordMessage('Cluster is not alive!');
			console.log('Cluster not found.');
		}

		return {
			statusCode: 200,
			body: 'Success',
		};
	} catch (error) {
		console.error('Error:', error);
		return {
			statusCode: 500,
			body: 'Error',
		};
	}
};

const sendDiscordMessage = async (message: string) => {
	await axios.post(process.env.WEBHOOK_DISCORD_URL!, { content: message })
		.then(() => {
			console.log('Message sent successfully');
		})
		.catch(error => {
			console.error('Error sending message:', error);
		});
};

// { "clusterName": "tonycava-cluster" }
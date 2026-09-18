export type PushPayload = {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
};

interface PushProvider {
  send(payload: PushPayload): Promise<void>;
}

class ConsolePushProvider implements PushProvider {
  async send(payload: PushPayload): Promise<void> {
    console.log('Push notification payload:', payload);
  }
}

const provider: PushProvider = new ConsolePushProvider();

export async function sendPush(payload: PushPayload): Promise<void> {
  await provider.send(payload);
}

import Prelude from "@prelude.so/sdk";

const client = new Prelude({
  apiToken: process.env.PRELUDE_API_KEY_DEV,
});

export default {
  start: async (phone: string) =>
    await client.verification.create({
      target: {
        type: "phone_number",
        value: phone,
      },
    }),
  check: async ({ phone, code }: { phone: string; code: string }) =>
    await client.verification.check({
      code,
      target: { type: "phone_number", value: phone },
    }),
};

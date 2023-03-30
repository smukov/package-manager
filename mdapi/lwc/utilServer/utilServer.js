/**
 * Parse ServerResponse object
 */
const parseServerResponse = (result) => {
  const { success } = result;

  if (success) {
    const { data } = result;
    return data;
  }

  const { message } = result.error;
  console.error(JSON.parse(JSON.stringify(message)));
  throw message;
};

export { parseServerResponse };

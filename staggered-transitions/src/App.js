export const randomHeights = (n) => () => {
  const arr = [];
  for (let i = 0; i < n; i++) {
    arr.push(40 + Math.floor(Math.random() * 180));
  }
  return arr;
};

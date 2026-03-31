export const rafOnce = (callback) => () => {
  window.requestAnimationFrame((now) => callback(now)());
};

export const performanceNow = () => performance.now();

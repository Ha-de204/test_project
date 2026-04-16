const { createWorker } = require('tesseract.js');

let worker;

const initWorker = async () => {
  worker = await createWorker('vie+eng');
  await worker.setParameters({
    tessedit_pageseg_mode: 6,
  });
};

const getWorker = () => worker;

module.exports = { initWorker, getWorker };
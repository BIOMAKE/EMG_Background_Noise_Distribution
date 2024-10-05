# Rethinking Noise Floor Characterisation in Motor-Evoked Potential

## Introduction

Motor-evoked potentials (MEPs) are crucial for assessing responses to noninvasive brain stimulation. However, EMG signals used to measure MEPs are susceptible to background noise, which can significantly impact readings, especially for small responses. This study investigates the statistical properties of EMG background noise in MEP measurements, challenging common assumptions and proposing more accurate models.

## Key Findings

1. The peak-to-peak voltage (Vpp) distribution of EMG background noise is highly right-skewed with a long tail, contradicting the common assumption of normality.

2. Four probability distribution models were compared:
   - Generalized Extreme Value (GEV)
   - Gamma
   - Log-normal
   - Normal (Gaussian)

3. The GEV distribution model consistently outperformed other models in describing both experimental and simulated data.

4. The Gamma distribution emerged as the second-best option.

5. Log-normal and normal distributions proved inadequate due to poor goodness-of-fit.

## Significance

- Challenges the widespread use of normal distribution models in MEP analysis.
- Recommends adopting the GEV distribution for more accurate characterisation of EMG background noise.
- Potential to enhance the precision of MEP-based assessments in clinical and research settings.
- May lead to the development of more effective noise reduction techniques and improved signal clarity in MEP recordings.

## Conclusion

This study provides evidence for rethinking the statistical approach to noise floor characterisation in MEP measurements. By adopting more accurate models like the GEV distribution, researchers and clinicians can potentially improve the reliability and interpretability of MEP data, advancing our understanding of neurophysiological processes and enhancing clinical outcomes.

## Files
`Supplementary Code` contains several MATLAB code files and a corresponding experimental dataset of the background noise distribution for Subject A05. `Figure_experimental_data.m` uses dataset `A05_Background_Noise_MEP.mat` and function `mygevfit.m` to generate a figure of the data distribution and calibrate the aforementioned four models.

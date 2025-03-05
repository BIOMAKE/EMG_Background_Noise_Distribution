import numpy as np
from scipy.stats import norm, laplace

def sample_mixture(n_samples, mixture_weights, 
                  gaussian_params=[(0, 1)],  # list of (mean, std) tuples
                  laplace_params=[(0, 1)],   # list of (loc, scale) tuples
                  shuffle=True):             # whether to shuffle the samples
    """
    Generate random samples from a mixture of Gaussian and Laplace distributions.
    
    Parameters:
    -----------
    n_samples : int
        Number of samples to generate
    mixture_weights : list
        List of weights for each component. Must sum to 1.
        First k weights correspond to Gaussian components,
        remaining weights correspond to Laplace components.
    gaussian_params : list of tuples
        List of (mean, std) parameters for each Gaussian component
    laplace_params : list of tuples
        List of (loc, scale) parameters for each Laplace component
    shuffle : bool
        If True, randomly shuffle the samples before returning
        
    Returns:
    --------
    numpy.ndarray
        Array of samples from the mixture distribution
    """
    
    # Validate inputs
    n_gaussian = len(gaussian_params)
    n_laplace = len(laplace_params)
    assert len(mixture_weights) == n_gaussian + n_laplace, "Number of weights must match number of components"
    assert np.isclose(sum(mixture_weights), 1), "Weights must sum to 1"
    
    # Generate component assignments
    component_indices = np.random.choice(
        len(mixture_weights), 
        size=n_samples, 
        p=mixture_weights
    )
    
    # Initialize output array
    samples = np.zeros(n_samples)
    
    # Generate samples for each component
    for i in range(n_gaussian):
        mask = component_indices == i
        mean, std = gaussian_params[i]
        samples[mask] = np.random.normal(mean, std, size=mask.sum())
    
    for i in range(n_laplace):
        mask = component_indices == (i + n_gaussian)
        loc, scale = laplace_params[i]
        samples[mask] = np.random.laplace(loc, scale, size=mask.sum())
    
    # Shuffle samples if requested
    if shuffle:
        return np.random.permutation(samples)  # Return a shuffled copy
    else:
        return samples


def mixture_pdf(x, mixture_weights, gaussian_params, laplace_params):
   """Calculate PDF values for mixture of Gaussian and Laplace distributions"""
   total_pdf = np.zeros_like(x)
   
   # Add Gaussian components
   for i, (mean, std) in enumerate(gaussian_params):
       weight = mixture_weights[i]
       total_pdf += weight * norm.pdf(x, mean, std)
   
   # Add Laplace components 
   n_gaussian = len(gaussian_params)
   for i, (loc, scale) in enumerate(laplace_params):
       weight = mixture_weights[i + n_gaussian]
       total_pdf += weight * laplace.pdf(x, loc, scale)
       
   return total_pdf





# Example usage:
if __name__ == "__main__":
    # Example: Mixture of 2 Gaussians and 1 Laplace
    n_samples = 1000
    mixture_weights = [0.4, 0.3, 0.3]  # Must sum to 1
    gaussian_params = [(0, 1), (3, 0.5)]  # (mean, std)
    laplace_params = [(5, 1)]  # (loc, scale)
    
    # Generate shuffled samples
    samples_shuffled = sample_mixture(
        n_samples, 
        mixture_weights, 
        gaussian_params, 
        laplace_params,
        shuffle=True
    )
    
    # Generate non-shuffled samples
    samples_ordered = sample_mixture(
        n_samples, 
        mixture_weights, 
        gaussian_params, 
        laplace_params,
        shuffle=False
    )
    
    # Visualize the mixtures
    import matplotlib.pyplot as plt
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 10))
    
    ax1.hist(samples_ordered, bins=50, density=True, alpha=0.7)
    ax1.set_title("Original Order")
    ax1.set_xlabel("Value")
    ax1.set_ylabel("Density")
    ax1.grid(True)
    
    ax2.plot(samples_shuffled)
    ax2.set_title("Shuffled Order")
    ax2.set_xlabel("Value")
    ax2.set_ylabel("Density")
    ax2.grid(True)
    
    plt.tight_layout()
    plt.show()
import numpy as np
from scipy.stats import norm, laplace
from scipy.optimize import minimize
import warnings

class GaussianLaplaceMixture:
    def __init__(self, n_gaussian, n_laplace, random_state=None):
        """
        Initialize mixture model with specified number of components
        
        Parameters:
        -----------
        n_gaussian : int
            Number of Gaussian components
        n_laplace : int
            Number of Laplace components
        random_state : int, optional
            Random seed for reproducibility
        """
        self.n_gaussian = n_gaussian
        self.n_laplace = n_laplace
        self.n_components = n_gaussian + n_laplace
        self.random_state = random_state
        
        if random_state is not None:
            np.random.seed(random_state)
  
    def get_weights(self):
        """Return mixture weights"""
        return self.weights
    
    def get_gaussian_params(self):
        """Return list of tuples of (mean, std) for Gaussian components"""
        return self.gaussian_params

    def get_laplace_params(self):
        """Return list of tuples of (loc, scale) for Laplace components"""
        return self.laplace_params
    
    def _initialize_parameters(self, X):
        """Initialize model parameters using data statistics"""
        # Initialize mixture weights
        self.weights = np.ones(self.n_components) / self.n_components
        
        # Use data percentiles for initial means/locations
        percentiles = np.linspace(10, 90, self.n_components)
        locations = np.percentile(X, percentiles)
        
        # Initialize Gaussian parameters
        self.gaussian_params = []
        for i in range(self.n_gaussian):
            mean = locations[i]
            std = np.std(X) / np.sqrt(self.n_components)
            self.gaussian_params.append((mean, std))
            
        # Initialize Laplace parameters
        self.laplace_params = []
        for i in range(self.n_laplace):
            loc = locations[i + self.n_gaussian]
            scale = np.std(X) / np.sqrt(self.n_components)
            self.laplace_params.append((loc, scale))
    
    def _e_step(self, X):
        """
        Expectation step: Calculate responsibilities
        
        Parameters:
        -----------
        X : array-like
            Input data
        
        Returns:
        --------
        responsibilities : ndarray
            Matrix of component responsibilities for each data point
        """
        n_samples = len(X)
        responsibilities = np.zeros((n_samples, self.n_components))
        
        # Calculate responsibilities for Gaussian components
        for i, (mean, std) in enumerate(self.gaussian_params):
            responsibilities[:, i] = self.weights[i] * norm.pdf(X, mean, std)
            
        # Calculate responsibilities for Laplace components
        for i, (loc, scale) in enumerate(self.laplace_params):
            idx = i + self.n_gaussian
            responsibilities[:, idx] = self.weights[idx] * laplace.pdf(X, loc, scale)
            
        # Normalize responsibilities
        row_sums = responsibilities.sum(axis=1)
        responsibilities /= row_sums[:, np.newaxis]
        
        return responsibilities
    
    def _m_step(self, X, responsibilities):
        """
        Maximization step: Update parameters using current responsibilities
        
        Parameters:
        -----------
        X : array-like
            Input data
        responsibilities : ndarray
            Matrix of component responsibilities
        """
        n_samples = len(X)
        
        # Update mixture weights
        self.weights = responsibilities.sum(axis=0) / n_samples
        
        # Update Gaussian parameters
        for i in range(self.n_gaussian):
            resp_i = responsibilities[:, i]
            weight_sum = resp_i.sum()
            
            # Update mean
            mean = (resp_i * X).sum() / weight_sum
            
            # Update standard deviation
            diff_sq = (X - mean) ** 2
            std = np.sqrt((resp_i * diff_sq).sum() / weight_sum)
            
            self.gaussian_params[i] = (mean, std)
        
        # Update Laplace parameters
        for i in range(self.n_laplace):
            idx = i + self.n_gaussian
            resp_i = responsibilities[:, idx]
            weight_sum = resp_i.sum()
            
            # Update location (using median for Laplace)
            def neg_log_likelihood(params):
                loc, scale = params
                return -np.sum(resp_i * laplace.logpdf(X, loc, scale))
            
            # Initial guess
            initial_loc = np.average(X, weights=resp_i)
            initial_scale = np.sqrt(np.average((X - initial_loc)**2, weights=resp_i))
            
            # Optimize parameters
            result = minimize(neg_log_likelihood, 
                           [initial_loc, initial_scale],
                           method='Nelder-Mead')
            
            self.laplace_params[i] = tuple(result.x)
    
    def fit(self, X, max_iter=500, tol=1e-6, verbose=False):
        """
        Fit the mixture model using EM algorithm
        
        Parameters:
        -----------
        X : array-like
            Input data
        max_iter : int, optional
            Maximum number of iterations
        tol : float, optional
            Convergence tolerance
        verbose : bool, optional
            Whether to print convergence information
        
        Returns:
        --------
        self : object
            Returns the instance itself
        """
        X = np.asarray(X)
        
        # Initialize parameters
        self._initialize_parameters(X)
        
        # Initialize log likelihood
        prev_log_likelihood = -np.inf
        
        # EM iterations
        for iteration in range(max_iter):
            # E-step
            responsibilities = self._e_step(X)
            
            # M-step
            self._m_step(X, responsibilities)
            
            # Calculate log likelihood
            log_likelihood = self.compute_log_likelihood(X)
            
            # Check convergence
            change = log_likelihood - prev_log_likelihood
            if verbose:
                print(f"Iteration {iteration+1}: log-likelihood = {log_likelihood:.6f}")
            
            if abs(change) < tol:
                if verbose:
                    print("Converged!")
                break
                
            prev_log_likelihood = log_likelihood
            
        return self
    
    def compute_log_likelihood(self, X):
        """Calculate the log-likelihood of the data"""
        pdf_values = self.pdf(X)
        return np.sum(np.log(pdf_values))
    
    def pdf(self, X):
        """Calculate PDF values for the mixture model"""
        return self.mixture_pdf(X, self.weights, self.gaussian_params, self.laplace_params)
    
    def sample(self, n_samples, shuffle = True):
        """
        Generate random samples from the mixture model
        
        Parameters:
        -----------
        n_samples : int
            Number of samples to generate
            
        Returns:
        --------
        samples : ndarray
            Generated samples
        """
        # Choose components based on weights
        component_indices = np.random.choice(
            self.n_components, 
            size=n_samples, 
            p=self.weights
        )
        
        samples = np.zeros(n_samples)
        
        # Generate samples from Gaussian components
        for i in range(self.n_gaussian):
            mask = component_indices == i
            n = mask.sum()
            if n > 0:
                mean, std = self.gaussian_params[i]
                samples[mask] = np.random.normal(mean, std, n)
        
        # Generate samples from Laplace components
        for i in range(self.n_laplace):
            idx = i + self.n_gaussian
            mask = component_indices == idx
            n = mask.sum()
            if n > 0:
                loc, scale = self.laplace_params[i]
                samples[mask] = np.random.laplace(loc, scale, n)
        
        # Shuffle samples if requested
        if shuffle:
            return np.random.permutation(samples)  # Return a shuffled copy
        else:
            return samples
        
        return samples
    
    @staticmethod
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
    # Generate synthetic data
    np.random.seed(42)
    n_samples = 10000
    
    # True parameters
    true_weights = [0.3, 0.7]
    true_gaussian_params = [(0.5, 1)]
    true_laplace_params = [(0, 0.7)]
    
    # Generate mixture data
    components = np.random.choice(2, size=n_samples, p=true_weights)
    X = np.zeros(n_samples)
    
    # Generate from Gaussians
    mask = components == 0
    X[mask] = np.random.normal(true_gaussian_params[0][0], true_gaussian_params[0][1], mask.sum())
    mask = components == 1
    X[mask] = np.random.laplace(true_laplace_params[0][0], true_laplace_params[0][1], mask.sum())
    
    
    # Fit model
    model = GaussianLaplaceMixture(n_gaussian=1, n_laplace=1, random_state=42)
    model.fit(X, verbose=True, max_iter = 5000)
    
    # Print results
    print("\nEstimated parameters:")
    print("Weights:", model.weights)
    print("Gaussian parameters:", model.gaussian_params)
    print("Laplace parameters:", model.laplace_params)

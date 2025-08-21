/**
 * Symptom Tracker Support Page JavaScript
 * Handles interactive elements and user engagement
 */

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeAnimations();
    initializeScrollEffects();
    initializeContactForms();
    initializeAnalytics();
});

/**
 * FAQ Toggle Functionality
 */
function toggleFAQ(questionElement) {
    const answer = questionElement.nextElementSibling;
    const icon = questionElement.querySelector('.toggle-icon');
    
    // Close other open FAQ items
    const allAnswers = document.querySelectorAll('.faq-answer');
    const allIcons = document.querySelectorAll('.toggle-icon');
    
    allAnswers.forEach((item, index) => {
        if (item !== answer && item.classList.contains('active')) {
            item.classList.remove('active');
            allIcons[index].classList.remove('rotated');
        }
    });
    
    // Toggle current FAQ item
    answer.classList.toggle('active');
    icon.classList.toggle('rotated');
    
    // Smooth scroll to question if opening
    if (answer.classList.contains('active')) {
        setTimeout(() => {
            questionElement.scrollIntoView({
                behavior: 'smooth',
                block: 'nearest'
            });
        }, 300);
    }
}

/**
 * Initialize smooth animations for page elements
 */
function initializeAnimations() {
    // Animate feature cards on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe all feature cards and sections
    const elementsToAnimate = document.querySelectorAll('.feature-card, .contact-card, .step');
    elementsToAnimate.forEach((el, index) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = `opacity 0.6s ease ${index * 0.1}s, transform 0.6s ease ${index * 0.1}s`;
        observer.observe(el);
    });
}

/**
 * Handle scroll effects and navigation
 */
function initializeScrollEffects() {
    let ticking = false;
    
    function updateScrollEffects() {
        const scrolled = window.pageYOffset;
        const rate = scrolled * -0.5;
        
        // Parallax effect for header
        const header = document.querySelector('.header');
        if (header) {
            header.style.transform = `translate3d(0, ${rate}px, 0)`;
        }
        
        ticking = false;
    }
    
    function requestTick() {
        if (!ticking) {
            requestAnimationFrame(updateScrollEffects);
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', requestTick);
    
    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

/**
 * Enhanced contact form handling
 */
function initializeContactForms() {
    // GitHub Issue Creation
    const githubButtons = document.querySelectorAll('a[href="#"]');
    githubButtons.forEach(button => {
        if (button.textContent.includes('Issue') || button.textContent.includes('Bug')) {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                handleGitHubIssue(button.textContent.includes('Bug'));
            });
        }
    });
    
    // Email support with pre-filled information
    const emailButtons = document.querySelectorAll('a[href^="mailto:"]');
    emailButtons.forEach(button => {
        button.addEventListener('click', function() {
            trackEvent('support', 'email_clicked');
        });
    });
}

/**
 * Handle GitHub issue creation
 */
function handleGitHubIssue(isBugReport = false) {
    const deviceInfo = getDeviceInfo();
    const issueTitle = isBugReport ? '[Bug Report] ' : '[Feature Request] ';
    const issueBody = isBugReport ? getBugReportTemplate() : getFeatureRequestTemplate();
    
    // Direct to the actual GitHub repository for issue creation
    const githubURL = `https://github.com/stovalldav/SymptomTrackerSupport/issues/new?title=${encodeURIComponent(issueTitle)}&body=${encodeURIComponent(issueBody)}`;
    
    // For now, show a modal with instructions
    showGitHubModal(githubURL, isBugReport);
    
    trackEvent('support', isBugReport ? 'bug_report_started' : 'feature_request_started');
}

/**
 * Get device information for bug reports
 */
function getDeviceInfo() {
    return {
        userAgent: navigator.userAgent,
        screenResolution: `${screen.width}x${screen.height}`,
        timestamp: new Date().toISOString(),
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
    };
}

/**
 * Bug report template
 */
function getBugReportTemplate() {
    const deviceInfo = getDeviceInfo();
    return `## Bug Description
Please describe the bug in detail.

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Screenshots
If applicable, add screenshots to help explain the problem.

## Device Information
- User Agent: ${deviceInfo.userAgent}
- Screen Resolution: ${deviceInfo.screenResolution}
- Timestamp: ${deviceInfo.timestamp}
- Timezone: ${deviceInfo.timezone}

## Additional Context
Add any other context about the problem here.`;
}

/**
 * Feature request template
 */
function getFeatureRequestTemplate() {
    return `## Feature Description
Please describe the feature you'd like to see added.

## Use Case
Describe the problem this feature would solve or the improvement it would bring.

## Proposed Solution
Describe how you envision this feature working.

## Additional Context
Add any other context, screenshots, or examples about the feature request.`;
}

/**
 * Show GitHub modal with instructions
 */
function showGitHubModal(githubURL, isBugReport) {
    const modal = document.createElement('div');
    modal.className = 'github-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fab fa-github"></i> ${isBugReport ? 'Report a Bug' : 'Request a Feature'}</h3>
                <button class="close-modal" onclick="closeModal(this)">&times;</button>
            </div>
            <div class="modal-body">
                <p>Click the button below to open a pre-filled ${isBugReport ? 'bug report' : 'feature request'} on GitHub:</p>
                <a href="${githubURL}" class="btn" target="_blank" rel="noopener noreferrer">
                    <i class="fab fa-github"></i> Open on GitHub
                </a>
                <p class="modal-note">
                    <i class="fas fa-info-circle"></i>
                    You'll need a GitHub account to create an issue. Don't have one? 
                    <a href="https://github.com/join" target="_blank" rel="noopener noreferrer">Sign up for free</a>.
                </p>
            </div>
        </div>
        <div class="modal-backdrop" onclick="closeModal(this)"></div>
    `;
    
    // Add modal styles
    const styles = `
        <style>
            .github-modal {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                z-index: 1000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            .modal-backdrop {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0,0,0,0.5);
                backdrop-filter: blur(5px);
            }
            .modal-content {
                background: white;
                border-radius: 15px;
                max-width: 500px;
                width: 90%;
                max-height: 80vh;
                overflow-y: auto;
                position: relative;
                z-index: 1001;
                box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            }
            .modal-header {
                padding: 25px 25px 0;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .modal-header h3 {
                margin: 0;
                color: #333;
                display: flex;
                align-items: center;
                gap: 10px;
            }
            .close-modal {
                background: none;
                border: none;
                font-size: 24px;
                cursor: pointer;
                color: #666;
                padding: 0;
                width: 30px;
                height: 30px;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
                transition: background 0.3s ease;
            }
            .close-modal:hover {
                background: #f0f0f0;
            }
            .modal-body {
                padding: 25px;
            }
            .modal-body p {
                margin-bottom: 20px;
                line-height: 1.6;
            }
            .modal-note {
                font-size: 0.9em;
                color: #666;
                background: #f8f9fa;
                padding: 15px;
                border-radius: 8px;
                margin-top: 20px;
            }
            .modal-note i {
                color: #007bff;
                margin-right: 5px;
            }
        </style>
    `;
    
    document.head.insertAdjacentHTML('beforeend', styles);
    document.body.appendChild(modal);
    
    // Animate in
    setTimeout(() => {
        modal.style.opacity = '1';
        modal.querySelector('.modal-content').style.transform = 'scale(1)';
    }, 10);
    
    modal.style.opacity = '0';
    modal.querySelector('.modal-content').style.transform = 'scale(0.8)';
    modal.querySelector('.modal-content').style.transition = 'transform 0.3s ease';
    modal.style.transition = 'opacity 0.3s ease';
}

/**
 * Close modal
 */
function closeModal(element) {
    const modal = element.closest('.github-modal');
    modal.style.opacity = '0';
    modal.querySelector('.modal-content').style.transform = 'scale(0.8)';
    setTimeout(() => {
        modal.remove();
    }, 300);
}

/**
 * Initialize privacy-friendly analytics
 */
function initializeAnalytics() {
    // Simple, privacy-friendly page analytics
    // No personal data collection, just basic usage stats
    
    // Track page load
    trackEvent('page', 'loaded');
    
    // Track section visibility
    const sections = document.querySelectorAll('.section');
    const sectionObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const sectionTitle = entry.target.querySelector('h2').textContent.trim();
                trackEvent('section', 'viewed', sectionTitle);
            }
        });
    }, { threshold: 0.5 });
    
    sections.forEach(section => sectionObserver.observe(section));
}

/**
 * Privacy-friendly event tracking
 */
function trackEvent(category, action, label = null) {
    // In a real implementation, you might send this to a privacy-friendly analytics service
    // For now, just log to console (remove in production)
    console.log(`Analytics: ${category} - ${action}${label ? ` - ${label}` : ''}`);
    
    // Example of how you might implement this with a privacy-friendly service:
    // if (window.analytics && window.analytics.track) {
    //     window.analytics.track(action, {
    //         category: category,
    //         label: label,
    //         timestamp: Date.now()
    //     });
    // }
}

/**
 * Enhanced user experience features
 */

// Keyboard navigation support
document.addEventListener('keydown', function(e) {
    // ESC to close modals
    if (e.key === 'Escape') {
        const modal = document.querySelector('.github-modal');
        if (modal) {
            closeModal(modal);
        }
    }
    
    // Enter to toggle FAQ items
    if (e.key === 'Enter' && e.target.classList.contains('faq-question')) {
        toggleFAQ(e.target);
    }
});

// Touch and gesture support for mobile
let touchStartY = 0;
document.addEventListener('touchstart', function(e) {
    touchStartY = e.touches[0].clientY;
}, { passive: true });

document.addEventListener('touchend', function(e) {
    const touchEndY = e.changedTouches[0].clientY;
    const diff = touchStartY - touchEndY;
    
    // Subtle pull-to-refresh hint (visual feedback only)
    if (diff < -100 && window.scrollY === 0) {
        // Show a subtle animation or message
        console.log('Pull to refresh detected (for future implementation)');
    }
}, { passive: true });

// Copy to clipboard functionality
function copyToClipboard(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => {
            showToast('Copied to clipboard!');
        }).catch(() => {
            fallbackCopyToClipboard(text);
        });
    } else {
        fallbackCopyToClipboard(text);
    }
}

function fallbackCopyToClipboard(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.top = '-1000px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
        document.execCommand('copy');
        showToast('Copied to clipboard!');
    } catch (err) {
        showToast('Copy failed. Please copy manually.');
    }
    
    document.body.removeChild(textArea);
}

// Toast notification system
function showToast(message, duration = 3000) {
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: #333;
        color: white;
        padding: 12px 20px;
        border-radius: 25px;
        z-index: 10000;
        transform: translateY(100px);
        transition: transform 0.3s ease;
        font-size: 14px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.3);
    `;
    
    document.body.appendChild(toast);
    
    // Animate in
    setTimeout(() => {
        toast.style.transform = 'translateY(0)';
    }, 10);
    
    // Animate out and remove
    setTimeout(() => {
        toast.style.transform = 'translateY(100px)';
        setTimeout(() => {
            toast.remove();
        }, 300);
    }, duration);
}

// Performance monitoring
function monitorPerformance() {
    if ('performance' in window) {
        window.addEventListener('load', () => {
            setTimeout(() => {
                const perfData = performance.getEntriesByType('navigation')[0];
                const loadTime = perfData.loadEventEnd - perfData.loadEventStart;
                
                // Log performance data (privacy-friendly)
                console.log(`Page load time: ${loadTime}ms`);
                
                if (loadTime > 3000) {
                    console.warn('Slow page load detected');
                }
            }, 0);
        });
    }
}

monitorPerformance();

// Service Worker registration for offline support (if needed)
if ('serviceWorker' in navigator && window.location.protocol === 'https:') {
    navigator.serviceWorker.register('/sw.js')
        .then(registration => {
            console.log('Service Worker registered successfully');
        })
        .catch(error => {
            console.log('Service Worker registration failed');
        });
}
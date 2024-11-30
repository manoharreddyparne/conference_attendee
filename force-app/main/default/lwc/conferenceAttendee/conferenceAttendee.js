import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateRegistration from '@salesforce/apex/AttendeeController.initiateRegistration';
import verifyOTP from '@salesforce/apex/AttendeeController.verifyOTP';
import getSessions from '@salesforce/apex/AttendeeController.getSessions';

export default class AttendeeRegistration extends LightningElement {
    name = '';
    email = '';
    affiliation = '';
    sessionId = '';
    enteredOTP = '';
    showOTPSection = false;
    sessionOptions = [];

    connectedCallback() {
        getSessions()
            .then(result => {
                this.sessionOptions = result.map(session => ({
                    label: session.Name,
                    value: session.Id
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Unable to fetch sessions.',
                    variant: 'error',
                }));
            });
    }

    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field === 'name') {
            this.name = event.target.value;
        } else if (field === 'email') {
            this.email = event.target.value;
        } else if (field === 'affiliation') {
            this.affiliation = event.target.value;
        } else if (field === 'otp') {
            this.enteredOTP = event.target.value;
        }
    }

    handleSessionChange(event) {
        this.sessionId = event.detail.value;
    }

    async handleRegister() {
        try {
            if (!this.sessionId) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a session.',
                    variant: 'error',
                }));
                return;
            }
        
            await initiateRegistration({
                name: this.name, 
                email: this.email, 
                affiliation: this.affiliation, 
                sessionId: this.sessionId 
            });
            
            this.showOTPSection = true;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'OTP sent to your email. Please enter it below.',
                variant: 'success',
            }));
        } catch (error) {
            let errorMessage = error.body && error.body.message ? error.body.message : 'An unknown error occurred.';
            if (errorMessage.includes('already registered')) {
                errorMessage = 'An attendee with this email is already registered.';
            }
    
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error',
            }));
        }
    }

    handleVerifyOTP() {
        verifyOTP({
            email: this.email,
            enteredOTP: this.enteredOTP,
            name: this.name,
            affiliation: this.affiliation,
            sessionId: this.sessionId
        })
        .then(result => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: result,
                variant: 'success',
            }));
            
            // Reset form fields and hide OTP section after successful registration
            this.resetForm();

        })
        .catch(error => {
            let errorMessage = error.body && error.body.message ? error.body.message : 'An unknown error occurred.';
            if (errorMessage.includes('Wrong OTP')) {
                errorMessage = 'Wrong OTP. Please enter the correct OTP from your email.';
            }
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error',
            }));
        });
    }

    // Method to reset the form after successful registration
    resetForm() {
        // Clear form properties
        this.name = '';
        this.email = '';
        this.affiliation = '';
        this.sessionId = '';
        this.enteredOTP = '';

        // Hide OTP section
        this.showOTPSection = false;

        // Manually clear each input field
        const inputFields = this.template.querySelectorAll('lightning-input');
        inputFields.forEach(field => {
            field.value = '';
        });
        
        const comboBox = this.template.querySelector('lightning-combobox');
        if (comboBox) {
            comboBox.value = '';
        }

        this.dispatchEvent(new ShowToastEvent({
            title: 'Ready for New Registration',
            message: 'The form is now ready for the next registration.',
            variant: 'success',
        }));
    }
}

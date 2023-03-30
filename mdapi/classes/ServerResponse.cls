/**
 * @description Standardized Aura Server Response
 *
 * @author M.Smukov
 * @since  05-05-2019
 */
public class ServerResponse {
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public Map<String, Object> data { get; set; }
    @AuraEnabled
    public Map<String, Object> error { get; set; }

    public ServerResponse() {
        this.success = true;
    }

    public ServerResponse(Map<String, Object> data) {
        this.success = true;
        this.data = data;
    }

    public ServerResponse(Exception ex) {
        this.success = false;
        this.error = new Map<String, Object>{ 'message' => ex.getMessage() };
    }

    public ServerResponse(String errorMessage) {
        this.success = false;
        this.error = new Map<String, Object>{ 'message' => errorMessage };
    }

    public ServerResponse(Boolean success, String message) {
        if (success) {
            this(new Map<String, Object>{ 'message' => message });
        } else {
            this(message);
        }
    }
}
/* solium-disable security/no-block-members */
pragma solidity ^0.4.24;

contract Requests {
    enum RequestStatus {
        // Initial status of a request
        Initial,
        // Request approved by the user, at this step an IPFS locator is included in the request
        UserApproved,
        // Request is denied by the user, at this point Seeker&#39;s deposit becomes refundable
        UserDenied,
        // Certificate is received by the Seeker and successfully verified against the certificate hash
        SeekerCompleted,
        // Certificate is received by the Seeker, but the hash doesnt match; 
        // TODO: some remediation action is needed here
        SeekerFailed,
        // Request is cancelled by the Seeker - only possible if the request status is Initial
        SeekerCancelled
    }

    struct DataRequest {
        address seeker; // 20
        // Request status
        RequestStatus status; // 1
        // Certificate hash
        bytes32 certificateHash; // 32
        // The date the request was submitted
        uint48 requestTimestamp; // 6
    }

    mapping (address => DataRequest[]) requests;

    function addRequest (address _user, address _seeker, bytes32 _hash) public {
        DataRequest memory dr = DataRequest({
            seeker: _seeker,
            status: RequestStatus.Initial,
            certificateHash: _hash,
            requestTimestamp: uint48(block.timestamp)
        });

        requests[_user].push(dr);
    }

    // Retrurn the count of all requests for a user
    function getUserRequestCount(address _user) public view returns (uint) {
        return requests[_user].length;
    }

    function getRequest(address _user, uint index) public view returns (address seeker, bytes32 certificateHash) {
        require(requests[_user].length > index, &quot;Index out of range&quot;);

        DataRequest storage req = requests[_user][index];

        seeker = req.seeker;
        certificateHash = req.certificateHash;
    }
}
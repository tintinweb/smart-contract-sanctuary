// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./Owned.sol";
import "./Policy.sol";

contract PolicyFactory is Owned {

    mapping(string => address[]) public clientPolicies;

    event PolicyCreated(address policy, string clientUuid);

    function createPolicy(
        address _paymentProvider,
        Policy.PolicyDetail memory _policyDetail
    ) external onlyOwner {
        Policy policy = new Policy(msg.sender, _paymentProvider);
        policy.setDetail(_policyDetail);
        address policyAddress = address(policy);
        clientPolicies[_policyDetail.clientUuid].push(policyAddress);
        emit PolicyCreated(policyAddress, _policyDetail.clientUuid);
    }

    function getPolicy(string calldata _clientUuid, uint _index) external view returns (address) {
        return clientPolicies[_clientUuid][_index];
    }
}
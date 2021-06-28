/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity >=0.4.16 <0.9.0;

contract CropChain {
    mapping (uint => address) public policyIdToOwner;
    
    function newApplication() public {
        // create a new application
    }
    
    function payPremium(uint premium) public {
        // allow user to make a premium payment
    }
    
    function newClaim() public {
        // allow user to make a new claim
    }
    
    function _underwrite() private {
        // private function to assess new application
    }
    
    function _decline() private {
        // private function to decline an application
    }
    
    function _newClaim() private {
        // private function to add a new claim to blockchain
    }
    
    function _confirmClaim() private {
        // confirm claim
    }
    
    function _declineClaim() private {
        // decline claim
    }
    
    function _payout() private {
        // payout on valid claim
    }
}
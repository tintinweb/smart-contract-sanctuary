/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

pragma solidity ^0.7.0;
// pragma experimental ABIEncoderV2;

abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    // function versionRecipient() external virtual view returns (string memory);
}

abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
    
}

contract Mock_Forwarder is BaseRelayRecipient {
    
    uint256 private count;
    mapping(address => string) private username;
    
    /** 
     * Set the trustedForwarder address either in constructor or 
     * in other init function in your contract
     */ 
    constructor(address _trustedForwarder) public {
        trustedForwarder = _trustedForwarder;
    }
    
    function setTrustedForwarder(address _trustedForwarder) public returns (bool){
        trustedForwarder = _trustedForwarder;
        return true;
    }
    
    function setLatestUsername(string memory _username) public returns (bool){
        username[_msgSender()] = _username;
        count++;
        return true;
    }
    
    function increaseCount() public returns (bool){
        count++;
        return true;
    }
    
    function getCountOfUsers() public view returns (uint256){
        return count;
    }
    
    function getLatestUsername(address userAddress) public view returns (string memory){
        return username[userAddress];
    }
    
}
// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";


interface callingContract{
    function trustedForwarderRefundFee(address payer,uint256 gasClaim) external;
}


contract Forwarder {
    using ECDSA for bytes32;    
    
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }
    
    mapping(address => uint256) private nonces;
    mapping(address => bool) private whitelist;
    
    address private admin;
    uint256 private _overhead;
    address private tokenX;
    receive() external payable {}


    function getNonce(address from)
    public view
    returns (uint256) {
        return nonces[from];
    }

    constructor() public {

        admin = msg.sender;
        whitelist[admin]=true;
    }
    
    function getAdmin()
    public view 
    returns (address) {
        return admin;
    }
    
    function getOverhead()
    public view
    returns (uint256) {
        return _overhead;
    }
    
    function getWhitelist(address user)
    public view
    returns (bool) {
        return whitelist[user];
    }
    
    function getTokenX()
    public view
    returns (address) {
        return tokenX;
    }

    function verify(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        uint256 nonce,
        bytes memory data,
        bytes calldata sig)
    external view {

        _verifyNonce(from, nonce);
        _verifySig(from,to,value,gas,nonce,data, sig);
    }
    
    
    
    function setTokenX(address token)
    public virtual {
        require(msg.sender == admin && token == address(0), "Permission Denied");
        tokenX = token;
    }
    
    function updateWhitelist(address user,
        bool permission)
    public virtual {
        require(msg.sender == admin, "Permission Denied");
        whitelist[user] = permission;
    }
    
    function setOverhead(uint256 overhead)
    public virtual {
        require(msg.sender == admin && _overhead == 0, "Permission Denied");
        _overhead = overhead;
    }

    function execute(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        uint256 nonce,
        bytes memory data,
        bytes calldata sig
    )
    external payable
    returns (bool success, bytes memory ret) {
        require(whitelist[msg.sender], "Not whitelisted.");
        _verifyNonce(from,nonce);
        _verifySig(from,to,value,gas,nonce,data, sig);
        _updateNonce(from);

        callingContract(tokenX).trustedForwarderRefundFee(from, gas+_overhead);
        (success,ret) = to.call{gas : gas, value : value}(abi.encodePacked(data, from));
        
        if ( address(this).balance>0 ) {
            
            payable(from).transfer(address(this).balance);
        }
        return (success,ret);
    }


    function _verifyNonce(address from,
        uint256 nonce)
    internal view {
        require(nonces[from] == nonce, "nonce mismatch");
    }

    function _updateNonce(address from)
    internal {
        nonces[from]++;
    }

   

    function _verifySig(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        uint256 nonce,
        bytes memory data,
        bytes memory sig)
    public
    pure
    {
        bytes32 digest = keccak256(abi.encodePacked(from,to,value,gas,nonce,data));
        require(digest.recover(sig) == from, "signature mismatch");
    }
    
    
    
    
    function _getHashToSign(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        uint256 nonce,
        bytes memory data)
    public
    pure
    returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked(from,to,value,gas,nonce,data));
        return digest;
    }
    
    
    
}
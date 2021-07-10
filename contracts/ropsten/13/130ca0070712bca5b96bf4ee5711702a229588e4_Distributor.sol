/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Distributor {
    address public owner;
    address public signer;
    bool public allowContracts;
        
    mapping(address => uint256) public nonces;
    mapping (address => uint256) public claimed;
    
    event Claim(address user, uint256 amount);
    
    constructor(address newSigner){
        owner = msg.sender;
        signer = newSigner;
        allowContracts = false;
    }
    
    
    function claim(address payable user, uint256 amount, bytes memory signature, uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(nonce, user, amount))));
        address signedBy = recoverSigner(hash, signature);
        
        require(signedBy == signer, 'Not signed by signer');
        require(nonces[user] == nonce, 'Nonce does not match');
        if (!allowContracts) require(msg.sender == tx.origin, 'No smart contracts allowed');
        
        nonces[user] += 1;
        claimed[user] += amount;
        
        user.transfer(amount);

        emit Claim(user, amount);
    }
    
    function settings(address _owner, address _signer, bool _allowContracts) external {
        require(msg.sender == owner, '!owner');
        require(_owner != address(0), "Owner != 0x0");
        require(_signer != address(0), "Signer != 0x0");
        
        owner = _owner;
        allowContracts = _allowContracts;
        signer = _signer;
    }
    
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }
    
    function getClaimed(address user) external view returns (uint256) {
        return claimed[user];
    }
    
    function recoverSigner(bytes32 hash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        if (_signature.length != 65) {
            return (address(0));
        }
        
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}
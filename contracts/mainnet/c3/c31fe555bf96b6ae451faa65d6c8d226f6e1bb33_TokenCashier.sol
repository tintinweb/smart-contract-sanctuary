/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.6.0;

// TokenCashier - allow a truste microservice to generate reciepts to be redeemed for tokens
//
// SPDX-License-Identifier: Apache-2.0
// heckles to @deanpierce

contract TokenCashier {
    
    address public token = 0x382f5DfE9eE6e309D1B9D622735e789aFde6BADe; // GST
    //address public token = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // ropDAI (testing)
    ERC20 erc20 = ERC20(token);

    address public owner = 0x7ab874Eeef0169ADA0d225E9801A3FfFfa26aAC3; // me
    mapping (address => bool) public signers;

    uint public nonce = 0;

    // for interacting with the token well
    address public wellAddr=0xFAF829Ee3AFd9641C40076B0eaebd58CCf1CC6ba;
    TokenWell tokenWell = TokenWell(wellAddr);

    function getBalance() public view returns(uint balance) {
        balance = erc20.balanceOf(address(this));
    }

    function pumpWell() public {
        tokenWell.pump();
    }
    
    function redeemVoucher(bytes calldata message, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public {

        // ensure the signature comes from a valid signer
        require(signers[voucherCheck(message,hash, v, r, s)],"INVALID SIGNATURE");

        uint newNonce;
        uint amount;
        address dest;
        (newNonce, amount, dest) = decodeMsg(message); // decode signed message
        
        require(nonce+1==newNonce, "BAD NONCE"); // verify the nonce
        nonce+=1;
        
        erc20.transfer(dest,amount); // send the tokens
    }

    function voucherCheck(bytes memory message, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(address signer) {
        
        bytes memory prefix = "\x19Ethereum Signed Message:\n96"; // 96 bytes long
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));

        require(prefixedHash==hash,"MESSAGE HASH MISMATCH");
    
        // malleability check from OZ ECDSA.sol 
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }
    
        // ensure the signature comes from a valid signer
        return ecrecover(hash, v, r, s);
    }
    
    // thanks 3esmit
    function decodeMsg(bytes memory _data) public pure returns(uint newNonce, uint amount, address dest){
        assembly {
            newNonce := mload(add(_data, 32))
            amount   := mload(add(_data, 64))
            dest     := mload(add(_data, 96))
        }
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender==owner,"NOT YOU");
        owner = newOwner;
    }
    
    function addSigner(address newAddr) public {
        require(msg.sender==owner,"NOT YOU");
        signers[newAddr]=true;
    }
    
    function delSigner(address badAddr) public {
        require(msg.sender==owner,"NOT YOU");
        signers[badAddr]=false;
    }
}


interface TokenWell{
    function pump() external returns (uint256 balance);
}

interface ERC20{
    //function approve(address spender, uint256 value)external returns(bool);
    //function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}
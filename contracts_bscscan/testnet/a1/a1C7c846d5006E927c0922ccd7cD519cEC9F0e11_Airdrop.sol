// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface Token {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external  returns (bool);
}

contract Airdrop is Ownable {
    
    mapping (uint => mapping (address => uint)) public withdrawals;
    
    function isWithdrawn(uint roundId, address to) public view returns(bool) {
        return withdrawals[roundId][to] > 0;
    }

    function withdraw(uint roundId, address tokenAddress, address payable to, uint amount, bytes memory signature) public {
        
        // Check that address already withdrawn in this round
        require(withdrawals[roundId][to] == 0, 'WithdrawalHelper: Already withdrawn');
        
        Token token = Token(tokenAddress);
        
        // Check balance
        require(token.balanceOf(address(this)) >= amount, "WithdrawalHelper: Not enough tokens");
        
        // Check signature
        bytes32 message = prefixed(keccak256(abi.encodePacked(roundId, to, amount)));
        require(recoverSigner(message, signature) == owner(), 'WithdrawalHelper: Signature sincorrect');
        
        // Transfer
        (bool success) = token.transfer(to, amount);
        require(success, 'WithdrawalHelper: WITHDRAWAL_FAILED');
        
        // Mark as withdrawn
        withdrawals[roundId][to] = amount;
    }
    
    /// signature methods.
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        
        if ( v < 2 ) {
            v += 27;
        }

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
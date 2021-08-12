/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

// Author: Osman Kuzucu
// https://github.com/open-money
// [email protected]

// Open Money Teknoloji ve Yatırım A.Ş.
// Omlira Kurucu ve Ekip Payı Zaman Kilitli Akıllı Kontratı
// 2021

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimeLocked {

    address private _tokenAddress;
    address[] private _signers;
    mapping (address => bool) _signersMap;
    address private _transferTo;
    uint256 private _amount;
    uint8 private _sigCount;
    mapping (address => bool) _hasSigned;

    modifier onlySigner {
        require(_signersMap[msg.sender],"You are not a signer");
        _;
    }

    modifier onlyOnce {
        require(!_hasSigned[msg.sender],"You already signed");
        _;
    }

    modifier onlyAfter {
        require(block.timestamp > 1704056400, "Time hasn't arrived yet");
        _;
    }
    
    constructor(address[] memory signers) {
        for(uint i=0; i<signers.length; i++) {
            _signers.push(signers[i]);
            _signersMap[signers[i]] = true;
        }
    }

    function getSigner (uint id) public view returns (address) {
        return _signers[id];
    }

    function getSignersCount () public view returns (uint) {
        return _signers.length;
    }

    function initializeTransfer (address transferTo, address tokenAddress, uint256 amount) public onlySigner {
        _transferTo = transferTo;
        _tokenAddress = tokenAddress;
        _amount = amount;
        _sigCount = 0;
        for(uint i=0; i<_signers.length; i++) {
            _hasSigned[_signers[i]] = false;
        }
    }

    function approveTransfer () public onlySigner onlyOnce {
        _sigCount++;
        _hasSigned[msg.sender] = true;
    }

    function finalizeTransfer () public onlySigner onlyAfter {
        require(2*_sigCount > _signers.length, "Not enough signers");
        Token(_tokenAddress).transfer(_transferTo, _amount);
    }
    
    function recoverEth () public {
        require(_signers[0] == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

}
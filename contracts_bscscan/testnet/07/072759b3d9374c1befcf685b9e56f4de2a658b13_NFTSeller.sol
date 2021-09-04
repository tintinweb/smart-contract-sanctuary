/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* A contract to automatically forward Coin to main address and create the payment event
*/
contract NFTSeller {
    address payable public owner;
    address public NftContractAddr;
    address public NftOwner;
    uint256 public unitPrice = 0.01 * 10**18; // 0.01 BNB
    uint256 currentTokenId = 0;
    event payment(address _from, uint256 _numberOfToken, uint256 _value);

    constructor(address payable _owner, address _nftContractAddr, address _nftOwner) {
        owner = _owner;
        NftContractAddr = _nftContractAddr;
        NftOwner = _nftOwner;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Forbidden");
        _;
    }

    function transferOwner(address payable _newOwner) public onlyOwner() {
        owner = _newOwner;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        require(_newPrice > 0, "Zero price!");
        unitPrice = _newPrice;
    }
    
    function updateTokenId(uint256 _newPos) public onlyOwner() {
        currentTokenId = _newPos;
    }

    function buyToken(uint256 _numberOfToken) public payable {
        require(msg.value > 0, 'Zero price');
        require(msg.value == _numberOfToken * unitPrice, 'Unexpected coin balance');
    
        NftContract nftContract = NftContract(NftContractAddr);
        for(uint256 i = 0; i < _numberOfToken; i++) {
            nftContract.safeTransferFrom(NftOwner, msg.sender, currentTokenId);
            currentTokenId = currentTokenId + 1;
        }

        owner.transfer(msg.value);
        emit payment(msg.sender, _numberOfToken, msg.value);
    }
}

abstract contract NftContract {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) virtual public;
}
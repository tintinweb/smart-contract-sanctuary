/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.1;



// Part: INFTBoxes

interface INFTBoxes {
	function buyManyBoxes(uint256 _id, uint128 _quantity) external payable;
    function setApprovalForAll(address operator, bool _approved) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// File: NFTPool.sol

//@author => owen.eth
contract NFTPool {

    struct Request {
        uint256 amountETH;
        uint128 amountNFT;
    }

    address _owner;
    uint256 boxPrice;
    uint128 amountBoxesBought;
    mapping(address => Request) requests;
    mapping(uint256 => uint256) NFTBalance;

    modifier onlyOwner {
        require(msg.sender == _owner, "You are not the owner!");
        _;
    }

    receive() external payable {

        uint256 tax = (msg.value * 10) / 100;
        uint256 value = msg.value - tax;
        payable(_owner).transfer(tax);

        requests[msg.sender].amountETH += value;
        requests[msg.sender].amountNFT = uint128(div(requests[msg.sender].amountETH, boxPrice));

    }

    INFTBoxes NFTBox;
    constructor(address _NFTBoxes, uint256 _boxPrice) {
        NFTBox = INFTBoxes(_NFTBoxes);
        _owner = msg.sender;
        boxPrice = _boxPrice;
    }

    function buyBoxes(uint256 _id, uint128 _quantityPerTx) external payable onlyOwner {
        uint128 amountReq =  uint128(div(address(this).balance, boxPrice));

        if(amountReq % 2 != 0)  {
            amountReq = amountReq - 1;
        }
        while(amountBoxesBought < amountReq) {
            NFTBox.buyManyBoxes{value: boxPrice * _quantityPerTx}(_id, _quantityPerTx);
            amountBoxesBought = amountBoxesBought + _quantityPerTx;
        }
    }

    //withdraw NFTs to multiple accounts given an address list and quantity per account.
    function withdrawManyNFT(address[] memory _accounts, uint128 _quantityPerAccount) external payable {
        require(mul(_accounts.length, _quantityPerAccount) <= requests[msg.sender].amountNFT); //require amount of accounts * amount per account <= req NFT amount per user
        require(requests[msg.sender].amountETH > 0);
        getOwnedBoxes();
        uint128 c = 0;
        for(uint i = 0; i < _accounts.length; i++) {
            NFTBox.setApprovalForAll(_accounts[i], true);
            for(uint128 x = 0; x < _quantityPerAccount; x++) {
                NFTBox.safeTransferFrom(address(this), _accounts[i], NFTBalance[c]);
                requests[msg.sender].amountNFT -= 1;
                requests[msg.sender].amountETH -= boxPrice;
                amountBoxesBought -= 1;
                c = c + 1;
            }
        }
    }

    function safeWithdrawNFT(uint128 _quantity) external payable {
        require(requests[msg.sender].amountNFT <= _quantity);
        require(requests[msg.sender].amountETH > 0);

        getOwnedBoxes();
        NFTBox.setApprovalForAll(msg.sender, true);
        for(uint i = 0; i < _quantity; i++)
        {
            NFTBox.safeTransferFrom(address(this), msg.sender, NFTBalance[i]);
        }

        amountBoxesBought -= _quantity;
        requests[msg.sender].amountNFT -= _quantity; //remove NFT from req
        requests[msg.sender].amountETH -= uint256(_quantity) * boxPrice; //remove equal ETH amount
    }

    //withdraws users leftover eth balance given all NFTs are withdrawn
    function safeWithdrawETH() external {
        if(requests[msg.sender].amountNFT !=  0)
        {
            requests[_owner].amountNFT +=requests[msg.sender].amountNFT;
        }
        uint256 userBalance = requests[msg.sender].amountETH; //get users balance
        uint128 userNFTBalance = requests[msg.sender].amountNFT; //get users NFT balance
        payable(msg.sender).transfer(userBalance); //transfer ETH
        requests[msg.sender].amountETH = 0; //set user balance to zero
        requests[msg.sender].amountNFT =  0; //remove NFT amount from user request

    }

    //get mapping of NFTs owned by this contract
    function getOwnedBoxes() internal {
        uint256 nfts = NFTBox.balanceOf(address(this));
        for(uint i = 0; i < nfts; i++) {
            NFTBalance[i] = NFTBox.tokenOfOwnerByIndex(address(this), i);
        }
    }

    //get info about the users request (for use on frontend)
    function getUser(address _user) external view returns(uint256, uint128) {
        return (requests[_user].amountETH, requests[_user].amountNFT);
    }

    // SAFE MATH
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
}
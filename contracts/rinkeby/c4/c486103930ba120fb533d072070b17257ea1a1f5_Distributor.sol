pragma solidity^0.7.0;
// SPDX-License-Identifier: UNLICENSED

import './nft.sol';

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Distributor is Owned{
    
    MovieNFTs public NFTContract;
    address public investerAddress;
    uint public investorAmount;
    
    address[] tokenHolders;
    
    constructor(address payable _NFTAddress, address _investorAddress, uint _investorAmount) {
        NFTContract = MovieNFTs(_NFTAddress);
        owner = msg.sender;
        investerAddress = _investorAddress;
        investorAmount = _investorAmount;
    }
    
    receive() external payable {
        distributeRoyaties();
    }
    
    fallback() external payable {
        distributeRoyaties();
    }
    
    function getNFTHolders() internal returns (address[] memory) {
        uint256 supply = NFTContract.totalSupply();
        address[] memory holders;
        tokenHolders = holders;
        for (uint i = 0; i < supply; i++) {
            tokenHolders.push(NFTContract.ownerOf(i));
        }
        return tokenHolders;
    }
    
    function distributeRoyaties() public payable returns (bool) {
        require(msg.value >= investorAmount, "The payment amount should be more than the initial investment");
        address[] memory holders = getNFTHolders();
        uint totalCount = holders.length;
        require(totalCount > 0, "No holders found");
        uint payableAmount = msg.value;
        payable(investerAddress).transfer(investorAmount);
        payableAmount -= investorAmount;
        for (uint i = 0; i < totalCount; i++){
            payable(holders[i]).transfer(payableAmount/totalCount);
        }
        return true;
        
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './FluidensityNft.sol';

contract SellNft {
    FluidensityNft fluidensity;
    address owner;

    mapping(address => bool) whitelistUsers;

    event tokenTransfered(address indexed _from, address indexed _to, uint _tokenId);
    event withdrawBalance(address indexed _to, uint indexed _value );
    event whitelistedUser(address indexed _user);

    constructor (){
        owner = msg.sender;
        whitelistUsers[owner] = true;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"You do not have authority to perform this action.");
        _;
    }

    modifier onlyWhitelistUser(address _user){
        require(whitelistUsers[_user],"The user is not white listed.");
        _;
    }


    function transferToken(address nftAddress, address _from, address _to, uint _tokenId) public onlyOwner onlyWhitelistUser(_to){
        fluidensity = FluidensityNft(nftAddress);
        fluidensity.safeTransferFrom(_from,_to,_tokenId);
        emit tokenTransfered(_from, _to, _tokenId);
    }

    function setWhitelistUsers(address _user) external {
        whitelistUsers[_user] = true;
        emit whitelistedUser(_user);
    }

    function getBalance() public view returns (uint _balance){
        return address(this).balance;
    }

    function withdraw(address payable _receiver, uint _value) public {
        //checking balance of contract
        require(address(this).balance >= _value,"Requested balance is higher than available balance.");
        _receiver.transfer(_value);
        emit withdrawBalance(_receiver,_value);
    }
    receive () external payable{

    }
}
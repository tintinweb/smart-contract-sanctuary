/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

contract nftwhitelist
{
   
    struct balance
    {
       uint256 amount;
       uint256 timeperiod;
       uint256 stackid;
    }
        
    uint256 public tokenid;
    uint256 public nftfees= 80000000000000000;
    address [] whitelistaddressarray;
    uint256 ownerpercentage=uint256(90);
    uint256 devwalletpercentage=uint256(10);
    address devwallet;
    address owner;
    mapping(address => bool) whitelistaddress;
    mapping(uint256 => mapping(address => balance)) record;
    mapping(address => uint256[]) linknft;
 
    constructor(address _address,address _owner)
    { 
        owner = _owner;
        devwallet = _address;
    }

    function Createwhitelist(address _address) internal
    {
       whitelistaddress[_address] = true;  
       whitelistaddressarray.push(_address);
    }

    function setfees(address _address,uint256 count) external payable
    {
       require(msg.value>=(nftfees*count),"amount is small");
       for(uint256 i=0;i<=count;i++)
       {
          tokenid+=1;
          record[tokenid][_address] = balance(msg.value,block.timestamp,0);
          linknft[_address].push(tokenid);
          if(!whitelistaddress[_address])
          {
             Createwhitelist(_address);
          }
       }
       amounttransfer(msg.value);
    }
    
    function setfiatfees(address _address,uint256 count,uint256 _id) external payable 
    {
       require(msg.value>=(nftfees*count),"amount is small");
       for(uint256 i=0;i<=count;i++)
       {
          tokenid+=1;
          record[tokenid][_address] = balance(msg.value,block.timestamp,_id);
          linknft[_address].push(tokenid);
          if(!whitelistaddress[_address])
          {
             Createwhitelist(_address);
          }
       } 
       amounttransfer(msg.value); 
    }

    function amounttransfer(uint256 amount) internal
    {
       uint256 owneramount = (amount*ownerpercentage)/uint256(100);
       uint256 devamount = (amount*devwalletpercentage)/uint256(100);
       (bool success,)  = owner.call{value:owneramount}("");
       require(success, "refund failed");
       (bool devsuccess,)  = devwallet.call{value:devamount}("");
       require(devsuccess, "refund failed");
    }

    function nftsaleamount(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        nftfees = amount;
    }
    
    function withdraweth(uint256 amount) external
    {
        require(msg.sender == owner,"not devwallet");
        (bool success,)  = owner.call{value:amount}("");
        require(success, "refund failed");
    }   
    
    function contractbalance() external view returns(uint256)
    { 
        return address(this).balance;
    }   
    
    function getwhitelistaddress() external view returns(address [] memory)
    {
        return whitelistaddressarray;
    }

    function holderdetails(uint256 _tokenid) external view returns(uint256,uint256,uint256)
    {
         return (record[_tokenid][msg.sender].amount,record[_tokenid][msg.sender].timeperiod,record[_tokenid][msg.sender].stackid);
    }

    function userid() external view returns(uint256 [] memory)
    {
        return linknft[msg.sender];
    }
 
    receive() payable external {}
         
}
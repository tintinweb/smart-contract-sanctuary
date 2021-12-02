/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

interface IController {
    function isAdmin(address account) external view returns (bool);
    function isRegistrar(address account) external view returns (bool);
    function isOracle(address account) external view returns (bool);
    function isValidator(address account) external view returns (bool);
    function owner() external view returns (address);
    
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract settings{
    IController controller;
     mapping(uint256 => uint256) public networkFee;
     uint256 public minValidations;
     address payable public   feeRemitance;
     uint256 public railRegistrationFee = 5000 * 10**18;
     uint256 public railOwnerFeeShare = 20;
     uint256 public minWithdrawableFee = 1 * 10**17;
     bool public onlyOwnableRail = true;
     address public brgToken;
     uint256[]  networkSupportedChains;
     mapping(uint256 =>  bool) public isNetworkSupportedChain;
     
     constructor(IController _controller) {
        controller = _controller;
    }
     function onlyAdmin() internal view{
        require(controller.isAdmin(msg.sender) || msg.sender == controller.owner() );
    }
     function getNetworkSupportedChains() external view returns(uint256[] memory){
     return networkSupportedChains;
    }
    
    function setbrgToken(address token) public {
        onlyAdmin();
       require(token != address(0) , "zero_A");
       brgToken = token;
   }
    function setminWithdrawableFee(uint256 _minWithdrawableFee) public {
        onlyAdmin();
       minWithdrawableFee = _minWithdrawableFee;
   }
   function setNetworkSupportedChains(uint256[] memory chains, uint256[] memory fees , bool add) public {
        onlyAdmin();
        if(add){
          require(chains.length == fees.length , "invalid");
          for(uint256 index ; index < chains.length ; index++){
           if(!isNetworkSupportedChain[chains[index]]){
               networkSupportedChains.push(chains[index]);
               isNetworkSupportedChain[chains[index]] = true;
               networkFee[chains[index]] = fees[index];
           }
       }  
        }else{
           for(uint256 index ; index < chains.length ; index++){
           if(isNetworkSupportedChain[chains[index]]){
               networkSupportedChains.push(chains[index]);
           for(uint256 index1; index1 <networkSupportedChains.length ; index1++){
           if(networkSupportedChains[index1] == chains[index]){
               networkSupportedChains[index1] = networkSupportedChains[networkSupportedChains.length - 1];
               networkSupportedChains.pop();
               
                }
               }
               
               isNetworkSupportedChain[chains[index]] = false;
           }
       } 
        }
       
   }
  
     function setRailOwnerFeeShare(uint256 share) public {
         onlyAdmin();
       require(share < 100 , "err");
       railOwnerFeeShare = share;
       
   }
    function setOnlyOwnableRailState(bool status) public  {
        onlyAdmin();
        require(status != onlyOwnableRail , "err");
        onlyOwnableRail = status;
    }
      function setrailRegistrationFee(uint256 registrationFee) public {
          onlyAdmin();
       railRegistrationFee = registrationFee;
   }
      function setFeeRemitanceAddress(address payable account) public  {
          onlyAdmin();
       require(account != address(0) , "zero_A");
       require(account != feeRemitance , "err");
       feeRemitance = account;
       
   }
}
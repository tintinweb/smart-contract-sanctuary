pragma solidity ^0.4.13;

contract owned {
 address public owner;

 function owned() {
     owner = msg.sender;
 }

 modifier onlyOwner {
     require(msg.sender == owner);
     _;
 }

 function transferOwnership(address newOwner) onlyOwner {
     owner = newOwner;
 }
}

contract ICO_CONTRACT is owned {

   event WithdrawEther (address indexed from, uint256 amount, uint256 balance);
   event ReceivedEther (address indexed sender, uint256 amount);  
   
   uint256 minimunInputEther;
   uint256 maximumInputEther;
   
   uint icoStartTime;
   uint icoEndTime;
   
   bool isStopFunding;
   
   function ICO_CONTRACT() {
       minimunInputEther = 1 ether;
       maximumInputEther = 500 ether;
       
       icoStartTime = now;
       icoEndTime = now + 14 * 1 days;
       
       isStopFunding = false;
   }
   
   function getBalance() constant returns (uint256){
       return address(this).balance;
   }
   
   function withdrawEther(uint256 _amount) onlyOwner returns (bool){
       
       if(_amount > getBalance()) {
           return false;
       }
       owner.transfer(_amount);
       WithdrawEther(msg.sender, _amount, getBalance());
       return true;
   }
   
   function withdrawEtherAll() onlyOwner returns (bool){
       uint256 _tempBal = getBalance();
       owner.transfer(getBalance());
       WithdrawEther(msg.sender, _tempBal, getBalance());
       return true;
   }

   function setMiniumInputEther (uint256 _minimunInputEther) onlyOwner {
       minimunInputEther = _minimunInputEther;
   }
   
   function getMiniumInputEther() constant returns (uint256) {
       return minimunInputEther;
   }
   
   function setMaxiumInputEther (uint256 _maximumInputEther) onlyOwner {
       maximumInputEther = _maximumInputEther;
   }
   
   function getMaxiumInputEther() constant returns (uint256) {
       return maximumInputEther;
   }
   
   function setIcoStartTime(uint _startTime) onlyOwner {
       icoStartTime = _startTime;
   }
   
   function setIcoEndTime(uint _endTime) onlyOwner {
       icoEndTime = _endTime;
   }
   
   function setIcoTimeStartEnd(uint _startTime, uint _endTime) onlyOwner {
       if(_startTime > _endTime) {
           return;
       }
       
       icoStartTime = _startTime;
       icoEndTime = _endTime;
   }
   
   function setStopFunding(bool _isStopFunding) onlyOwner {
       isStopFunding = _isStopFunding;
   }
   
   function getIcoTime() constant returns (uint, uint) {
       return (icoStartTime, icoEndTime);
   }

   function () payable {
       
       if(msg.value < minimunInputEther) {
           throw;
       }
       
       if(msg.value > maximumInputEther) {
           throw;
       }
       
       if(!isFundingNow()) {
           throw;
       }
       
       if(isStopFunding) {
           throw;
       }
       
       ReceivedEther(msg.sender, msg.value);
   }
   
   function isFundingNow() constant returns (bool) {
       return (now > icoStartTime && now < icoEndTime);
   }
   
   function getIsStopFunding() constant returns (bool) {
       return isStopFunding;
   }
}
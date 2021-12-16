/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.4.25;

contract Donation {
    struct DonorInfo{
        address[] donors;
        mapping (address => uint) ledger;
        
    }
    mapping (address => DonorInfo) DonationHistory;
    
    event LogDonate(
        address streamer,address donor,string nickname,uint value,string message);
        
    function donate(address _streamer,string _nickname,string _message) public payable {
      
        require(msg.value >0);
        _streamer.transfer(msg.value);
          
        if (DonationHistory[_streamer].ledger[msg.sender] == 0) {
            DonationHistory[_streamer].donors.push(msg.sender);
        } 
        
        DonationHistory[_streamer].ledger[msg.sender] += msg.value;
        
        emit LogDonate(
            _streamer,
            msg.sender,
            _nickname,
            msg.value,
            _message);
    }
   
   function getDonorList() public view returns (address[]) {
       return DonationHistory[msg.sender].donors;
   }
   
   event LogListDonorInfo(address streamer,address user,uint value);
   function listDonorInfo() public {
      for(uint i = 0;i< DonationHistory[msg.sender].donors.length;i++){
          address user = DonationHistory[msg.sender].donors[i];
          emit LogListDonorInfo(msg.sender,user,DonationHistory[msg.sender].ledger[user]);
      }
   }
}
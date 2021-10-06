/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.0;

contract DegenDataAccess {
    
    address private owner;
    uint256 public registrationFee;
    mapping(address => bool) public isUserRegistered; 
    
 
     constructor(){
         owner = msg.sender;
         registrationFee = 0.1 ether; 
     }
     
     //modifiers
     modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Can Perform this function");
         _;
    }
    
    //fallback
    fallback() external payable
    {
        revert();
    }
     
     
     //Getters
     function getRegistrationFee() public view returns(uint256){
         return(registrationFee);
     }
     
     function getOwner() public view returns(address){
         return owner;
     }
     
     //Setters
     function setNewOwner(address _newOwner) public onlyOwner {
         owner = _newOwner;
     }
     
     function setNewRegistrationPrice(uint256 _newFee) public onlyOwner{
         registrationFee = _newFee;
     }
     
     function register() public payable {
      require(msg.value >= registrationFee, "Insufficient funds sent");
      require(isUserRegistered[msg.sender] == false, "You already registered you knucklehead"); 
      isUserRegistered[msg.sender] = true;
    }
     
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
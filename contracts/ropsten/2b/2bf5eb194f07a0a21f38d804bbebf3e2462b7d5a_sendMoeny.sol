/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.5.13;

contract sendMoeny{
    uint public balanceReceived;
    address owner;
    bool paused;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function receiveMoney() public payable{
        balanceReceived += msg.value;
        
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function pauseTransaction(bool _paused) public{
         require(msg.sender== owner, 'You are not the owner');
         paused = _paused;
    }
    
    function withdrawMoeny() public{
        require(msg.sender== owner, 'You are not the owner');
        require(!paused, 'Contract is paused');
        address payable to = msg.sender;
        to.transfer(this.getBalance());
        
}

  function withdrawMoenyTo(address payable _to) public{
      require(msg.sender== owner, 'You are not the owner');
      require(!paused,'Contract is paused');
      _to.transfer(this.getBalance());
  }
  
  function deleteSmartContract(address payable _to) public{
            require(msg.sender== owner, 'You are not the owner');
            selfdestruct(_to);
  }
}
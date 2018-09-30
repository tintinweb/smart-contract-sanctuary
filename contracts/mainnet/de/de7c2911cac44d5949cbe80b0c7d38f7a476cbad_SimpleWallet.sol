pragma solidity ^0.4.25;
 

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = 0x2C43dfBAc5FC1808Cb8ccEbCc9E24BEaB1aaa816;//msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract SimpleWallet is Ownable {

    address public wallet1 = 0xf038F656b511Bf37389b8Ae22D44fB3395327007;
    address public wallet2 = 0xf038F656b511Bf37389b8Ae22D44fB3395327007;
    
    address public newWallet1 = 0xf038F656b511Bf37389b8Ae22D44fB3395327007;
    address public newWallet2 = 0xf038F656b511Bf37389b8Ae22D44fB3395327007;
    
    function setNewWallet1(address _newWallet1) public onlyOwner {
        newWallet1 = _newWallet1;
    }    
    
    function setNewWallet2(address _newWallet2) public onlyOwner {
        newWallet2 = _newWallet2;
    }  
    
    function setWallet1(address _wallet1) public {
        require(msg.sender == wallet1);
        require(newWallet1 == _wallet1);
        
        wallet1 = _wallet1;
    }    
    
    function setWallet2(address _wallet2) public {
        require(msg.sender == wallet2);
        require(newWallet2 == _wallet2);
        
        wallet2 = _wallet2;
    }  
    
    
    function withdraw() public{
        require( (msg.sender == wallet1)||(msg.sender == wallet2) );
        uint half = address(this).balance/2;
        wallet1.send(half);
        wallet2.send(half);
    } 
    
      function () public payable {
        
      }     
    
}
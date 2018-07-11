pragma solidity 0.4.24;

contract Ownable {

   address public owner;

   constructor() public {
       owner = msg.sender;
   }

   function setOwner(address _owner) public onlyOwner {
       owner = _owner;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

}

contract Vault is Ownable {

   function () public payable {

   }

   function getBalance() public view returns (uint) {
       return address(this).balance;
   }

   function withdraw(uint amount) public onlyOwner {
       require(address(this).balance >= amount);
       owner.transfer(amount);
   }

   function withdrawAll() public onlyOwner {
       withdraw(address(this).balance);
   }
}

contract CappedVault is Vault { 

    uint public limit;
    uint withdrawn = 0;

    constructor() public {
        limit = 33333 ether;
    }

    function () public payable {
        require(total() + msg.value <= limit);
    }

    function total() public view returns(uint) {
        return getBalance() + withdrawn;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
        withdrawn += amount;
    }

}
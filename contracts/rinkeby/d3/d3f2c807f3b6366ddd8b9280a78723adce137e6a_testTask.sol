pragma solidity ^0.8.10;

contract Ownable {

  address payable public owner;

  modifier onlyOwner {
    require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
    _;
  }

  constructor () payable {
    owner = payable(msg.sender);
  }
}

contract testTask is Ownable{
    event usersWhoDonatedList(address _address, uint _value);
    function deposit() public payable {
      emit usersWhoDonatedList(msg.sender, msg.value);
    }
    
    function contractBalance() public view returns(uint256 _contractBalance){
      _contractBalance = address(this).balance;
      return _contractBalance;
    }

    function userBalance() public view returns(uint256 _userBalance){
      _userBalance = msg.sender.balance;
      return _userBalance;
    }
   
    function transfer(address payable _to, uint _amount) public onlyOwner{
      (bool success, ) = _to.call{value: _amount}("");
      require(success, "Failed to send Ether");
    }

    function withdraw() public onlyOwner{
      uint amount = address(this).balance;
      (bool success, ) = owner.call{value: amount}("");
      require(success, "Failed to send Ether");
    }
}
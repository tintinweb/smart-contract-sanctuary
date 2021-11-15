//SPDX-Licencse-Identfier: MIT

pragma solidity^0.8.0;
// @title PayableContact
contract PayableContract{

  address public owner;

  address public admin;

  //indexed makes it easier for us to search for this event using the parameter.
  event Transfer(address indexed _to, uint _value);

  event Receive(address indexed _from, uint _value);

  modifier onlyAdmin() {
    require(msg.sender == admin, "Admin privilege only");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Owner privilege only");
    _;
  }

  /**
  * @notice Set the default admin and owner as the
  * adress which deployed the contract
  */
  constructor() {
    admin = msg.sender;
    owner = admin;
  }

  /**
  * @param _newOwner payable adress of new owner
  * @return status
  * @dev previous owner cannot be made new owner
  */
  function transferOwnership(address _newOwner) public onlyAdmin returns(bool status){
    require(_newOwner != address(0));

    address previousOwner = owner;

    require(previousOwner != _newOwner);

    owner = _newOwner;

    return true;
  }

  /**
  * @dev Withdraw all funds
  */
  function withdrawAll() public onlyOwner {
    uint amount = address(this).balance;

    (bool success,) = msg.sender.call{value: amount}("");

    require(success, "withdrawAll: Transfer Failed");

    emit Transfer(msg.sender, amount);

  }

  function callRevert() public payable{
    triggerRevert(msg.value);
  }

  function triggerRevert(uint amount) private pure {
    require(amount % 2e18 == 0, "Not Even");
  }

  /**
  * @param amount Amount to be withdrawn in wei
  */
  function withdrawPartial(uint amount) public onlyOwner {
    (bool success,) = msg.sender.call{value: amount}("");

    require(success, "withdrawPartial: Transfer Failed");

    emit Transfer(msg.sender, amount);
  }

  /**
  *@dev We can only rely on 2300 gas so just simple logging.
  */
  receive() external payable {
    emit Receive(msg.sender, msg.value);
  }

  function killSwitch() public onlyAdmin() {
    address payable _owner = payable(owner);
    selfdestruct(_owner);
  }

}


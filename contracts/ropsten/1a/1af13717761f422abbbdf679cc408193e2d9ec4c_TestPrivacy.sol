pragma solidity ^0.4.24;


contract TestPrivacy {
  //storage
  address public owner;
  mapping(address => bool) allowedUsers;
  string private hiddenValue;
  
  //modifiers
  modifier onlyOwner
  {
    require(owner == msg.sender);
    _;
  }
  
  modifier isAllowedUser
  {
      require(true == allowedUsers[msg.sender]);
      _;
  }

  //Events
  event newUserAdded(address indexed newUser);

  constructor() public {
      owner = msg.sender;
      hiddenValue = "first action";
      allowedUsers[msg.sender] = true;
  }
  
  // add new user to allowedUsers array 
  function addNewUser(address newUser)
  public
  onlyOwner
  {
      allowedUsers[newUser] = true;
      emit newUserAdded(newUser);
  }
  
  // show hiddenValue
  function showHiddenValue()
  public
  constant
  isAllowedUser
  returns (string _hiddenValue)
  {
      return hiddenValue;
  }

  // change hiddenValue
  function changeHiddenValue(string newValue)
  public
  onlyOwner
  {
      hiddenValue = newValue;
  }
  
  //check is user in allowed list
  function isUserInAllowedList()
  public
  constant
  returns (bool isUserAllowed)
  {
      return allowedUsers[msg.sender];
  }
}
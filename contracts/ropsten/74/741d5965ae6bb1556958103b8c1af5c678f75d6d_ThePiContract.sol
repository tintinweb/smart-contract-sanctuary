pragma solidity ^0.4.11;

contract ThePiContract {

  address owner;
  uint public start;

  // Constructor
  function ThePiContract() {
    owner = msg.sender;
    start = now;
  }

  UserStruct[] public people;

  struct UserStruct {
    bytes32 fullName;
    bytes32 userEmail;
    bytes32 projectName;
    uint projectDuration;
    uint index;
  }

  mapping(address => UserStruct) private userStructs;
  mapping(address => uint) clientBalance;
  address[] private userIndex;


  event LogNewUser   (address indexed userAddress, uint index, bytes32 userEmail, bytes32 projectName, uint projectDuration);
  event LogUpdateUser(address indexed userAddress, uint index, bytes32 fullName, bytes32 userEmail, bytes32 projectName, uint projectDuration);

  modifier contractOwnerPerms() {
      require(owner == msg.sender);
      _;
  }

  function isUser(address userAddress)
    public
    constant
    returns(bool isIndeed)
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  function insertUser(
    address userAddress,
    bytes32 fullName,
    bytes32 userEmail,
    bytes32 projectName,
    uint projectDuration)
    contractOwnerPerms
    returns(uint index)
  {
    if(isUser(userAddress)) revert();
    userStructs[userAddress].fullName = fullName;
    userStructs[userAddress].userEmail = userEmail;
    userStructs[userAddress].projectName = projectName;
    userStructs[userAddress].projectDuration = projectDuration;
    userStructs[userAddress].index     = userIndex.push(userAddress)-1;
    people.push(userStructs[userAddress]);
    LogNewUser(
        userAddress,
        userStructs[userAddress].index,
        userEmail,
        projectName,
        projectDuration);
    return userIndex.length-1;
  }

  function getUser(address userAddress)
    public
    constant
    contractOwnerPerms
    returns(bytes32 fullName, bytes32 userEmail, bytes32 projectName, uint projectDuration, uint index)
  {
    if(!isUser(userAddress)) revert();
    return(
      userStructs[userAddress].fullName,
      userStructs[userAddress].userEmail,
      userStructs[userAddress].projectName,
      userStructs[userAddress].projectDuration,
      userStructs[userAddress].index);
  }

  function updateUserEmail(address userAddress, bytes32 userEmail)
    contractOwnerPerms
    returns(bool success)
  {
    if(!isUser(userAddress)) revert();
    userStructs[userAddress].userEmail = userEmail;
    LogUpdateUser(
        userAddress,
        userStructs[userAddress].index,
        userStructs[userAddress].fullName,
        userEmail,
        userStructs[userAddress].projectName,
        userStructs[userAddress].projectDuration);
    return true;
  }

  function updateUserFullName(address userAddress, bytes32 fullName)
    contractOwnerPerms
    returns(bool success)
  {
    if(!isUser(userAddress)) revert();
    userStructs[userAddress].fullName = fullName;
    LogUpdateUser(
      userAddress,
      userStructs[userAddress].index,
      fullName,
      userStructs[userAddress].userEmail,
      userStructs[userAddress].projectName,
      userStructs[userAddress].projectDuration);
    return true;
  }

  function updateprojectDuration(address userAddress, uint _projectDuration)
    contractOwnerPerms
    returns(bool success)
  {
    if(!isUser(userAddress)) revert();
    userStructs[userAddress].projectDuration = _projectDuration;
    LogUpdateUser(
      userAddress,
      userStructs[userAddress].index,
      userStructs[userAddress].fullName,
      userStructs[userAddress].userEmail,
      userStructs[userAddress].projectName,
      _projectDuration);
    return true;
  }


  function getUserCount()
    public
    constant
    returns(uint count)
  {
    return userIndex.length;
  }

  function getUserAtIndex(uint index)
    constant
    contractOwnerPerms
    returns(address userAddress)
  {
    return userIndex[index];
  }

  function getAllPeople() constant contractOwnerPerms returns (bytes32[], bytes32[], bytes32[], uint[], uint[]) {

        uint length = getUserCount();

        bytes32[] memory fullNames = new bytes32[](length);
        bytes32[] memory userEmails = new bytes32[](length);
        bytes32[] memory projectNames = new bytes32[](length);
        uint[] memory projectDurations = new uint[](length);
        uint[] memory indexes = new uint[](length);

        for(uint i=0; i<length; i++) {
            UserStruct memory currentPerson;
            currentPerson = people[i];

            fullNames[i] = currentPerson.fullName;
            userEmails[i] = currentPerson.userEmail;
            projectNames[i] = currentPerson.projectName;
            projectDurations[i] = currentPerson.projectDuration;
            indexes[i] = currentPerson.index;
        }

        return (fullNames, userEmails, projectNames, projectDurations, indexes);

    }


    // This will take the value of the transaction and add to the senders account.
    function deposit(address userAddress) payable returns (bool res) {
        // If the amount they send is 0, return false.
        if (msg.value == 0) {
            return false;
        }
        clientBalance[userAddress] += msg.value;
        return true;
    }

    // Send payment to client.
    function tranfer(address _to, uint _value) contractOwnerPerms returns (bool success) {
        if ((clientBalance[msg.sender] + _value  > clientBalance[msg.sender]) && (clientBalance[msg.sender] >=_value) && (_value > 0)) {
            clientBalance[msg.sender] -= _value;
            clientBalance[_to] += _value;
            return true;
        }
        return false;
    }

    function withdraw() {
        uint amount = clientBalance[msg.sender];
        if(amount > 0) {
            // Remember to zero the pending refund before
            // sending to prevent re-entrancy attacks
            clientBalance[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    // Set payment clock
    function payAfter(address userAddress, uint _amount) contractOwnerPerms {
        uint daysAfter = userStructs[userAddress].projectDuration;
        if (now >= start + daysAfter * 1) {
           if(!tranfer(userAddress, _amount)) revert();
        }
    }


    function showBal() constant returns (uint) {
        return clientBalance[msg.sender];
    }

    // Delete contract
    function removeContract() contractOwnerPerms {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }


}
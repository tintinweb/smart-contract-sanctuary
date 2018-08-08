pragma solidity ^0.4.13;

contract BtzReceiver {
    using SafeMath for *;

    // BTZReceiver state variables
    BtzToken BTZToken;
    address public tokenAddress = 0x0;
    address public owner;
    uint numUsers;

    // Struct to store user info
    struct UserInfo {
        uint totalDepositAmount;
        uint totalDepositCount;
        uint lastDepositAmount;
        uint lastDepositTime;
    }

    event DepositReceived(uint indexed _who, uint _value, uint _timestamp);
    event Withdrawal(address indexed _withdrawalAddress, uint _value, uint _timestamp);

    // mapping of user info indexed by the user ID
    mapping (uint => UserInfo) userInfo;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _addr) public onlyOwner {
        owner = _addr;
    }

    /*
    * @dev Gives admin the ability to update the address of BTZ223
    *
    * @param _tokenAddress The new address of BTZ223
    **/
    function setTokenContractAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        BTZToken = BtzToken(_tokenAddress);
    }

    /*
    * @dev Returns the information of a user
    *
    * @param _uid The id of the user whose info to return
    **/
    function userLookup(uint _uid) public view returns (uint, uint, uint, uint){
        return (userInfo[_uid].totalDepositAmount, userInfo[_uid].totalDepositCount, userInfo[_uid].lastDepositAmount, userInfo[_uid].lastDepositTime);
    }

    /*
    * @dev The function BTZ223 uses to update user info in this contract
    *
    * @param _id The users Bunz Application User ID
    * @param _value The number of tokens to deposit
    **/
    function receiveDeposit(uint _id, uint _value) public {
        require(msg.sender == tokenAddress);
        userInfo[_id].totalDepositAmount = userInfo[_id].totalDepositAmount.add(_value);
        userInfo[_id].totalDepositCount = userInfo[_id].totalDepositCount.add(1);
        userInfo[_id].lastDepositAmount = _value;
        userInfo[_id].lastDepositTime = now;
        emit DepositReceived(_id, _value, now);
    }

    /*
    * @dev The withdrawal function for admin
    *
    * @param _withdrawalAddr The admins address to withdraw the BTZ223 tokens to
    **/
    function withdrawTokens(address _withdrawalAddr) public onlyOwner{
        uint tokensToWithdraw = BTZToken.balanceOf(this);
        BTZToken.transfer(_withdrawalAddr, tokensToWithdraw);
        emit Withdrawal(_withdrawalAddr, tokensToWithdraw, now);
    }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20 {
  using SafeMath for *;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    require(_value <= balances[msg.sender]);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract ERC223 is ERC20 {
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transferFrom(address from, address to, uint value, bytes data) returns (bool ok);
}

contract Standard223Token is ERC223, StandardToken {
  //function that is called when a user or another contract wants to transfer funds
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    //filtering if the target is a contract with bytecode inside it
    if (!super.transfer(_to, _value)) throw; // do a normal token transfer
    if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value, bytes _data) returns (bool success) {
    if (!super.transferFrom(_from, _to, _value)) revert(); // do a normal token transfer
    if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    return transfer(_to, _value, new bytes(0));
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    return transferFrom(_from, _to, _value, new bytes(0));
  }

  //function that is called when transaction target is a contract
  function contractFallback(address _origin, address _to, uint _value, bytes _data) private returns (bool success) {
    ERC223Receiver reciever = ERC223Receiver(_to);
    return reciever.tokenFallback(msg.sender, _origin, _value, _data);
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
    // retrieve the size of the code on target address, this needs assembly
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
}

contract BtzToken is Standard223Token {
  using SafeMath for *;
  address public owner;

  // BTZ Token parameters
  string public name = "BTZ by Bunz";
  string public symbol = "BTZ";
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
  uint256 public constant totalSupply = 200000000000 * decimalFactor;

  // Variables for deposit functionality
  bool public prebridge;
  BtzReceiver receiverContract;
  address public receiverContractAddress = 0x0;

  event Deposit(address _to, uint _value);

  /**
  * @dev Constructor function for BTZ creation
  */
  constructor() public {
    owner = msg.sender;
    balances[owner] = totalSupply;
    prebridge = true;
    receiverContract = BtzReceiver(receiverContractAddress);

    Transfer(address(0), owner, totalSupply);
  }

  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }

  function setOwner(address _addr) public onlyOwner {
      owner = _addr;
  }

  /**
  * @dev Gives admin the ability to switch prebridge states.
  *
  */
  function togglePrebrdige() onlyOwner {
      prebridge = !prebridge;
  }

  /**
  * @dev Gives admin the ability to update the address of reciever contract
  *
  * @param _newAddr The address of the new receiver contract
  */
  function setReceiverContractAddress(address _newAddr) onlyOwner {
      receiverContractAddress = _newAddr;
      receiverContract = BtzReceiver(_newAddr);
  }

  /**
  * @dev Deposit function for users to send tokens to Bunz Application
  *
  * @param _value A uint representing the amount of BTZ to deposit
  */
  function deposit(uint _id, uint _value) public {
      require(prebridge &&
              balances[msg.sender] >= _value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[receiverContractAddress] = balances[receiverContractAddress].add(_value);
      emit Transfer(msg.sender, receiverContractAddress, _value);
      receiverContract.receiveDeposit(_id, _value);
  }
}

contract ERC223Receiver {
  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
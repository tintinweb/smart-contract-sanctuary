pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// Receive approval and then execute function
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract MyBitToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



// ---------------------------------------------------------------------------------
// This contract holds all long-term data for the MyBit smart-contract systems
// All values are stored in mappings using a bytes32 keys.
// The bytes32 is derived from keccak256(variableName, uniqueID) => value
// ---------------------------------------------------------------------------------
interface Database {

    // --------------------Set Functions------------------------

    function setAddress(bytes32 _key, address _value)
    external;

    function setUint(bytes32 _key, uint _value)
    external;

    function setString(bytes32 _key, string _value)
    external;

    function setBytes(bytes32 _key, bytes _value)
    external;

    function setBytes32(bytes32 _key, bytes32 _value)
    external;

    function setBool(bytes32 _key, bool _value)
    external;

    function setInt(bytes32 _key, int _value)
    external;


     // -------------- Deletion Functions ------------------

    function deleteAddress(bytes32 _key)
    external;

    function deleteUint(bytes32 _key)
    external;

    function deleteString(bytes32 _key)
    external;

    function deleteBytes(bytes32 _key)
    external;

    function deleteBytes32(bytes32 _key)
    external;

    function deleteBool(bytes32 _key)
    external;

    function deleteInt(bytes32 _key)
    external;

    // ----------------Variable Getters---------------------

    function uintStorage(bytes32 _key)
    external
    returns (uint);

    function stringStorage(bytes32 _key)
    external
    returns (string);

    function addressStorage(bytes32 _key)
    external
    returns (address);

    function bytesStorage(bytes32 _key)
    external
    returns (bytes);

    function bytes32Storage(bytes32 _key)
    external
    returns (bytes32);

    function boolStorage(bytes32 _key)
    external
    returns (bool);

    function intStorage(bytes32 _key)
    external
    returns (bool);
}


// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol

  //--------------------------------------------------------------------------------------------------
  // Math operations with safety checks that throw on error
  //--------------------------------------------------------------------------------------------------
library SafeMath {

  //--------------------------------------------------------------------------------------------------
  // Multiplies two numbers, throws on overflow.
  //--------------------------------------------------------------------------------------------------
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  //--------------------------------------------------------------------------------------------------
  // Integer division of two numbers, truncating the quotient.
  //--------------------------------------------------------------------------------------------------
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  //--------------------------------------------------------------------------------------------------
  // Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  //--------------------------------------------------------------------------------------------------
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  //--------------------------------------------------------------------------------------------------
  // Adds two numbers, throws on overflow.
  //--------------------------------------------------------------------------------------------------
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// @notice Registers users and provides them with a minimum amount of MYB and Ether
// Note: Not secure. Use for test-net only.
contract TokenFaucet {
  using SafeMath for uint; 

  MyBitToken public mybToken;
  Database public database; 

  uint public mybTokensInFaucet;
  uint public balanceWEI; 

  uint public dripAmountMYB = uint(10e21);     // User should have at least 10,000 MYB
  uint public dripAmountWEI = 500 finney;    // User should have at least .5 Ether 

  bytes32 private accessPass; 

  uint public oneYear = uint(31536000);    // 365 days in seconds


  constructor(address _database, address _mybTokenAddress, bytes32 _accessPass)
  public  {
    database = Database(_database); 
    mybToken = MyBitToken(_mybTokenAddress);
    accessPass = _accessPass; 
  }

  // For owner to deposit mybTokens easier
  // @dev call myBitmybToken.receiveAndCall(_spender=mybFaucet.address, _amount * 10^18, mybitmybToken.address, 0x0) 
  function receiveApproval(address _from, uint _amount, address _mybToken, bytes _data)
  external {
    require(_mybToken == msg.sender && _mybToken == address(mybToken));
    require(mybToken.transferFrom(_from, this, _amount));
    mybTokensInFaucet = mybTokensInFaucet.add(_amount);
    emit LogMYBDeposited(_from, _amount, _data);
  }

  // Can deposit more WEI in here
  function depositWEI()
  external 
  payable { 
    balanceWEI = balanceWEI.add(msg.value); 
    emit LogEthDeposited(msg.sender, msg.value); 
  }

    // Lazy defence. accessPass is mild deterent, not secure. 
  function withdraw(string _pass)
  external {
    require (keccak256(abi.encodePacked(_pass)) == accessPass); 
    uint expiry = now.add(oneYear);
    uint accessLevel = database.uintStorage(keccak256(abi.encodePacked("userAccess", msg.sender))); 
    if (accessLevel < 1){ 
      database.setUint(keccak256(abi.encodePacked("userAccess", msg.sender)), 1);   
      database.setUint(keccak256(abi.encodePacked("userAccessExpiration", msg.sender)), expiry);
      emit LogNewUser(msg.sender);
    }
    if (mybToken.balanceOf(msg.sender) < dripAmountMYB) { 
      uint amountMYB = dripAmountMYB.sub(mybToken.balanceOf(msg.sender)); 
      mybTokensInFaucet = mybTokensInFaucet.sub(amountMYB);
      mybToken.transfer(msg.sender, amountMYB); 
    }
    if (msg.sender.balance < dripAmountWEI) { 
      uint amountWEI = dripAmountWEI.sub(msg.sender.balance); 
      balanceWEI = balanceWEI.sub(amountWEI); 
      msg.sender.transfer(amountWEI);
    }
    emit LogWithdraw(msg.sender, amountMYB, amountWEI);
  }

  function changePass(bytes32 _newPass)
  external 
  anyOwner
  returns (bool) { 
    accessPass = _newPass; 
    return true; 
  }

  function changeDripAmounts(uint _newAmountWEI, uint _newAmountMYB)
  external 
  anyOwner
  returns (bool) { 
    dripAmountWEI = _newAmountWEI; 
    dripAmountMYB = _newAmountMYB; 
    return true; 
  }

  //------------------------------------------------------------------------------------------------------------------
  // Verify that the sender is a registered owner
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

  event LogWithdraw(address _sender, uint _amountMYB, uint _amountWEI);
  event LogMYBDeposited(address _depositer, uint _amount, bytes _data);
  event LogEthDeposited(address _depositer, uint _amountWEI); 
  event LogEthWithdraw(address _withdrawer, uint _amountWEI); 
  event LogNewUser(address _user); 
}
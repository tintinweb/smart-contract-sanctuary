pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Database interface
interface DBInterface {

  function setContractManager(address _contractManager)
  external;

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
    view
    returns (uint);

    function stringStorage(bytes32 _key)
    external
    view
    returns (string);

    function addressStorage(bytes32 _key)
    external
    view
    returns (address);

    function bytesStorage(bytes32 _key)
    external
    view
    returns (bytes);

    function bytes32Storage(bytes32 _key)
    external
    view
    returns (bytes32);

    function boolStorage(bytes32 _key)
    external
    view
    returns (bool);

    function intStorage(bytes32 _key)
    external
    view
    returns (bool);
}

contract Events {
  DBInterface public database;

  constructor(address _database) public{
    database = DBInterface(_database);
  }

  function message(string _message)
  external
  onlyApprovedContract {
      emit LogEvent(_message, keccak256(abi.encodePacked(_message)), tx.origin);
  }

  function transaction(string _message, address _from, address _to, uint _amount, address _token)
  external
  onlyApprovedContract {
      emit LogTransaction(_message, keccak256(abi.encodePacked(_message)), _from, _to, _amount, _token, tx.origin);
  }

  function registration(string _message, address _account)
  external
  onlyApprovedContract {
      emit LogAddress(_message, keccak256(abi.encodePacked(_message)), _account, tx.origin);
  }

  function contractChange(string _message, address _account, string _name)
  external
  onlyApprovedContract {
      emit LogContractChange(_message, keccak256(abi.encodePacked(_message)), _account, _name, tx.origin);
  }

  function asset(string _message, string _uri, address _assetAddress, address _manager)
  external
  onlyApprovedContract {
      emit LogAsset(_message, keccak256(abi.encodePacked(_message)), _uri, keccak256(abi.encodePacked(_uri)), _assetAddress, _manager, tx.origin);
  }

  function escrow(string _message, address _assetAddress, bytes32 _escrowID, address _manager, uint _amount)
  external
  onlyApprovedContract {
      emit LogEscrow(_message, keccak256(abi.encodePacked(_message)), _assetAddress, _escrowID, _manager, _amount, tx.origin);
  }

  function order(string _message, bytes32 _orderID, uint _amount, uint _price)
  external
  onlyApprovedContract {
      emit LogOrder(_message, keccak256(abi.encodePacked(_message)), _orderID, _amount, _price, tx.origin);
  }

  function exchange(string _message, bytes32 _orderID, address _assetAddress, address _account)
  external
  onlyApprovedContract {
      emit LogExchange(_message, keccak256(abi.encodePacked(_message)), _orderID, _assetAddress, _account, tx.origin);
  }

  function operator(string _message, bytes32 _id, string _name, string _ipfs, address _account)
  external
  onlyApprovedContract {
      emit LogOperator(_message, keccak256(abi.encodePacked(_message)), _id, _name, _ipfs, _account, tx.origin);
  }

  function consensus(string _message, bytes32 _executionID, bytes32 _votesID, uint _votes, uint _tokens, uint _quorum)
  external
  onlyApprovedContract {
    emit LogConsensus(_message, keccak256(abi.encodePacked(_message)), _executionID, _votesID, _votes, _tokens, _quorum, tx.origin);
  }

  //Generalized events
  event LogEvent(string message, bytes32 indexed messageID, address indexed origin);
  event LogTransaction(string message, bytes32 indexed messageID, address indexed from, address indexed to, uint amount, address token, address origin); //amount and token will be empty on some events
  event LogAddress(string message, bytes32 indexed messageID, address indexed account, address indexed origin);
  event LogContractChange(string message, bytes32 indexed messageID, address indexed account, string name, address indexed origin);
  event LogAsset(string message, bytes32 indexed messageID, string uri, bytes32 indexed assetID, address asset, address manager, address indexed origin);
  event LogEscrow(string message, bytes32 indexed messageID, address asset, bytes32  escrowID, address indexed manager, uint amount, address indexed origin);
  event LogOrder(string message, bytes32 indexed messageID, bytes32 indexed orderID, uint amount, uint price, address indexed origin);
  event LogExchange(string message, bytes32 indexed messageID, bytes32 orderID, address indexed asset, address account, address indexed origin);
  event LogOperator(string message, bytes32 indexed messageID, bytes32 id, string name, string ipfs, address indexed account, address indexed origin);
  event LogConsensus(string message, bytes32 indexed messageID, bytes32 executionID, bytes32 votesID, uint votes, uint tokens, uint quorum, address indexed origin);


  // --------------------------------------------------------------------------------------
  // Caller must be registered as a contract through ContractManager.sol
  // --------------------------------------------------------------------------------------
  modifier onlyApprovedContract() {
      require(database.boolStorage(keccak256(abi.encodePacked("contract", msg.sender))));
      _;
  }

}

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// @title SafeMath: overflow/underflow checks
// @notice Math operations with safety checks that throw on error
library SafeMath {

  // @notice Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  // @notice Integer division of two numbers, truncating the quotient.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  // @notice Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  // @notice Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  // @notice Returns fractional amount
  function getFractionalAmount(uint256 _amount, uint256 _percentage)
  internal
  pure
  returns (uint256) {
    return div(mul(_amount, _percentage), 100);
  }

}

interface DToken {
  function withdraw() external returns (bool);
  function getAmountOwed(address _user) external view returns (uint);
  function balanceOf(address _tokenHolder) external view returns (uint);
  function transfer(address _to, uint _amount) external returns (bool success);
  function getERC20() external  view returns (address);
}

// @title A dividend-token holding contract that locks tokens and retrieves dividends for assetManagers
// @notice This contract receives newly minted tokens and retrieves Ether or ERC20 tokens received from the asset
// @author Kyle Dewhurst & Peter Phillips, MyBit Foundation
contract AssetManagerFunds {
  using SafeMath for uint256;

  DBInterface public database;
  Events public events;

  uint256 private transactionNumber;

  // @notice constructor: initializes database
  constructor(address _database, address _events)
  public {
    database = DBInterface(_database);
    events = Events(_events);
  }

  // @notice asset manager can withdraw his dividend fee from assets here
  // @param : address _assetAddress = the address of this asset on the platform
  function withdraw(address _assetAddress)
  external
  nonReentrant
  returns (bool) {
    require(_assetAddress != address(0));
    require(msg.sender == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress))));
    DToken token = DToken( _assetAddress);
    uint amountOwed;
    uint balanceBefore;
    if (token.getERC20() == address(0)){
      balanceBefore = address(this).balance;
      amountOwed = token.getAmountOwed(address(this));
      require(amountOwed > 0);
      uint balanceAfter = balanceBefore.add(amountOwed);
      require(token.withdraw());
      require(address(this).balance == balanceAfter);
      msg.sender.transfer(amountOwed);
    }
    else {
      amountOwed = token.getAmountOwed(address(this));
      require(amountOwed > 0);
      DToken fundingToken = DToken(token.getERC20());
      balanceBefore = fundingToken.balanceOf(address(this));
      require(token.withdraw());
      require(fundingToken.balanceOf(address(this)).sub(amountOwed) == balanceBefore);
      fundingToken.transfer(msg.sender, amountOwed);
    }
    return true;
  }

  function retrieveAssetManagerTokens(address[] _assetAddress)
  external
  nonReentrant
  returns (bool) {
    require(_assetAddress.length <= 42);
    uint[] memory payoutAmounts = new uint[](_assetAddress.length);
    address[] memory tokenAddresses = new address[](_assetAddress.length);
    uint8 numEntries;
    for(uint8 i = 0; i < _assetAddress.length; i++){
      require(msg.sender == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress[i]))) );
      DToken token = DToken(_assetAddress[i]);
      require(address(token) != address(0));
      uint tokensOwed = token.getAmountOwed(address(this));
      if(tokensOwed > 0){
        DToken fundingToken = DToken(token.getERC20());
        uint balanceBefore = fundingToken.balanceOf(address(this));
        uint8 tokenIndex = containsAddress(tokenAddresses, address(token));
        if (tokenIndex < _assetAddress.length) {  payoutAmounts[tokenIndex] = payoutAmounts[tokenIndex].add(tokensOwed); }
        else {
          tokenAddresses[numEntries] = address(fundingToken);
          payoutAmounts[numEntries] = tokensOwed;
          numEntries++;
        }
        require(token.withdraw());
        require(fundingToken.balanceOf(address(this)).sub(tokensOwed) == balanceBefore);
      }
    }

    for(i = 0; i < numEntries; i++){
      require(ERC20(tokenAddresses[i]).transfer(msg.sender, payoutAmounts[i]));
    }
    return true;
  }


  function retrieveAssetManagerETH(address[] _assetAddress)
  external
  nonReentrant
  returns (bool) {
    require(_assetAddress.length <= 93);
    uint weiOwed;
    for(uint8 i = 0; i < _assetAddress.length; i++){
      require(msg.sender == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress[i]))));
      DToken token = DToken(_assetAddress[i]);
      uint balanceBefore = address(this).balance;
      uint amountOwed = token.getAmountOwed(address(this));
      if(amountOwed > 0){
        uint balanceAfter = balanceBefore.add(amountOwed);
        require(token.withdraw());
        require(address(this).balance == balanceAfter);
        weiOwed = weiOwed.add(amountOwed);
      }
    }
    msg.sender.transfer(weiOwed);
    return true;
  }

  function viewBalance(address _assetAddress, address _assetManager)
  external
  view
  returns (uint){
    require(_assetAddress != address(0), 'Empty address passed');
    require(_assetManager == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress))), 'That user does not manage the asset');
    DToken token = DToken( _assetAddress);
    uint balance = token.balanceOf(address(this));
    return balance;
  }

  function viewAmountOwed(address _assetAddress, address _assetManager)
  external
  view
  returns (uint){
    require(_assetAddress != address(0), 'Empty address passed');
    require(_assetManager == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress))), 'That user does not manage the asset');
    DToken token = DToken( _assetAddress);
    uint amountOwed = token.getAmountOwed(address(this));
    return amountOwed;
  }

  // @notice returns the index if the address is in the list, otherwise returns list length + 1
  function containsAddress(address[] _addressList, address _addr)
  internal
  pure
  returns (uint8) {
    for (uint8 i = 0; i < _addressList.length; i++){
      if (_addressList[i] == _addr) return i;
    }
    return uint8(_addressList.length + 1);
  }

  // @notice platform owners can destroy contract here
  function destroy()
  onlyOwner
  external {
    events.transaction('AssetManagerFunds destroyed', address(this), msg.sender, address(this).balance, address(0));
    selfdestruct(msg.sender);
  }

  // @notice prevents calls from re-entering contract
  modifier nonReentrant() {
    transactionNumber += 1;
    uint256 localCounter = transactionNumber;
    _;
    require(localCounter == transactionNumber);
  }

  // @notice reverts if caller is not the owner
  modifier onlyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))) == true);
    _;
  }

  function ()
  payable
  public {
    emit EtherReceived(msg.sender, msg.value);
  }

  event EtherReceived(address sender, uint amount);

}
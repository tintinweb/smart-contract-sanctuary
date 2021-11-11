/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/erc20/SafeERC20.sol

pragma solidity >=0.4.21 <0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/erc20/ERC20Impl.sol

pragma solidity >=0.4.21 <0.6.0;


contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes memory _data
    ) public;
}
contract TransferEventCallBack{
  function onTransfer(address _from, address _to, uint256 _amount) public;
}

contract ERC20Base {
    string public name;                //The Token's name: e.g. GTToken
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "GTT_0.1"; //An arbitrary versioning scheme

    using AddressArray for address[];
    address[] public transferListeners;

////////////////
// Events
////////////////
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

    event NewTransferListener(address _addr);
    event RemoveTransferListener(address _addr);

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {
        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;
        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    ERC20Base public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a ERC20Base
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    constructor(
        ERC20Base _parentToken,
        uint _parentSnapShotBlock,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // The standard ERC 20 transferFrom functionality
        if (allowed[_from][msg.sender] < _amount)
            return false;
        allowed[_from][msg.sender] -= _amount;
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != address(0)) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
        // Then update the balance array with the new value for the address
        //  receiving the tokens
        uint256 previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        // An event to make the transfer easy to find on the blockchain
        
        emit Transfer(_from, _to, _amount);
        onTransferDone(_from, _to, _amount);
        return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes memory _extraData) public returns (bool success) {
        require(approve(address(_spender), _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public view returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function _generateTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(address(0), _owner, _amount);
        onTransferDone(address(0), _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function _destroyTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, address(0), _amount);
        onTransferDone(_owner, address(0), _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function _enableTransfers(bool _transfersEnabled) internal {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function onTransferDone(address _from, address _to, uint256 _amount) internal {
      for(uint i = 0; i < transferListeners.length; i++){
        TransferEventCallBack t = TransferEventCallBack(transferListeners[i]);
        t.onTransfer(_from, _to, _amount);
      }
    }

    function _addTransferListener(address _addr) internal {
      transferListeners.push(_addr);
      emit NewTransferListener(_addr);
    }
    function _removeTransferListener(address _addr) internal{
      transferListeners.remove(_addr);
      emit RemoveTransferListener(_addr);
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    //function () external payable {
        //require(false, "cannot transfer ether to this contract");
    //}
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: contracts/utils/ContractPool.sol

pragma solidity >=0.4.21 <0.6.0;



contract IContractPool{
  function get_contract(bytes32 key) public returns(address);

  function recycle_contract(bytes32 key, address addr) public returns(bool);
  function add_using_contract(bytes32 key, address addr) public returns(bool);
  function add_nouse_contract(bytes32 key, address addr) public returns(bool);
}

contract ContractPool is TrustListTools{

  mapping (bytes32 => address[]) public available_contracts;
  mapping (address => bytes32) public used_contracts;

  constructor(address _tlist) TrustListTools(_tlist) public{
  }

  function get_contract(bytes32 key) public
  is_trusted(msg.sender) returns(address){
    address[] storage s = available_contracts[key];
    if(s.length == 0){
      return address(0x0);
    }
    address r = s[s.length - 1];
    s.length = s.length - 1;
    used_contracts[r] = key;
    Ownable(r).transferOwnership(msg.sender);
    return r;
  }

  function recycle_contract(bytes32 key, address addr) public
  is_trusted(msg.sender) returns(bool){
    require(used_contracts[addr] == key, "cannot recycle");
    require(Ownable(addr).owner() == address(this), "incorrect owner");

    delete used_contracts[addr];
    available_contracts[key].push(addr);
    return true;
  }
  function add_using_contract(bytes32 key, address addr) public is_trusted(msg.sender)
  returns(bool){
    //! Sanity check may increase gas cost, so we ignore it
    used_contracts[addr] = key;
    return true;
  }
  function add_nouse_contract(bytes32 key, address addr) public is_trusted(msg.sender)
  returns(bool){
    require(used_contracts[addr] == bytes32(0x0), "already in use");
    require(Ownable(addr).owner() == address(this), "incorrect owner");
    available_contracts[key].push(addr);
    return true;
  }
}

// File: contracts/core/HToken.sol

pragma solidity >=0.4.21 <0.6.0;







contract HToken is ERC20Base, Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public target;
  uint256 public ratio_to_target;
  //uint256 public types; // 1 for in,2 for out, 3 for long term
  mapping (bytes32 => uint256) public extra;//record extra information of the token, including the round, type and ratio

  constructor(string memory _name, string memory _symbol, bool _transfersEnabled)
  ERC20Base(ERC20Base(address(0x0)), 0, _name, 18, _symbol, _transfersEnabled) public{}

  function reconstruct(string memory _name, string memory _symbol, bool _transfersEnabled) public onlyOwner{
    name = _name;
    symbol = _symbol;
    transfersEnabled = _transfersEnabled;
  }

  function mint(address addr, uint256 amount) onlyOwner public{
    _generateTokens(addr, amount);
  }
  function burnFrom(address addr, uint256 amount) onlyOwner public{
    _destroyTokens(addr, amount);
  }

  function set_extra(bytes32 _target, uint256 _value) onlyOwner public{
    extra[_target] = _value;
  }

  function set_target(address _target) onlyOwner public{
    target = _target;
  }

  function addTransferListener(address _addr) public {
    _addTransferListener(_addr);
  }
  function removeTransferListener(address _addr) public {
    _removeTransferListener(_addr);
  }

  event HTokenSetRatioToTarget(uint256 ratio_to);
  function set_ratio_to_target(uint256 _ratio_to) onlyOwner public{
    ratio_to_target = _ratio_to;
    emit HTokenSetRatioToTarget(_ratio_to);
  }
}

contract HTokenFactoryInterface{
  function createHToken(string memory _name, string memory _symbol, bool _transfersEnabled) public returns(address);
  function destroyHToken(address addr) public;
}

contract HTokenFactory is HTokenFactoryInterface{
  event NewHToken(address addr);
  event DestroyHToken(address addr);
  function createHToken(string memory _name, string memory _symbol, bool _transfersEnabled) public returns(address){
    HToken pt = new HToken(_name, _symbol, _transfersEnabled);
    pt.transferOwnership(msg.sender);
    emit NewHToken(address(pt));
    return address(pt);
  }
  function destroyHToken(address addr) public{
    //TODO, we choose do nothing here
    emit DestroyHToken(addr);
  }
}

contract CachedHTokenFactory is HTokenFactoryInterface, TrustListTools{
  event NewCachedHToken(address addr);
  event DestroyCachedHToken(address addr);
  HTokenFactoryInterface public normal_factory;
  IContractPool public contract_pool;

  constructor(address factory, address pool, address _tlist) TrustListTools(_tlist) public{
    normal_factory = HTokenFactoryInterface(factory);
    contract_pool = IContractPool(pool);
  }

  function createHToken(string memory _name, string memory _symbol, bool _transfersEnabled) public returns(address){
    HToken pt = HToken(contract_pool.get_contract(keccak256("HToken")));
    if(pt == HToken(0x0)){
      pt = new HToken(_name, _symbol, _transfersEnabled);
      contract_pool.add_using_contract(keccak256("HToken"), address(pt));
    }else{
      pt.reconstruct(_name, _symbol, _transfersEnabled);
    }
    pt.transferOwnership(msg.sender);
    emit NewCachedHToken(address(pt));
    return address(pt);
  }

  function destroyHToken(address addr) public is_trusted(msg.sender){
    require(IERC20(addr).totalSupply() == 0, "totalSupply is not 0");
    Ownable(addr).transferOwnership(address(contract_pool));
    contract_pool.recycle_contract(keccak256("HToken"), addr);
    emit DestroyCachedHToken(addr);
  }

  function cacheHToken(uint num) public{
    bytes32 k = keccak256("HToken");
    for(uint i = 0; i < num; i++){
      HToken pt = new HToken("no use", "no use", true);
      pt.transferOwnership(address(contract_pool));
      contract_pool.add_nouse_contract(k, address(pt));
    }
  }

}

// File: contracts/core/HPeriod.sol

pragma solidity >=0.4.21 <0.6.0;


contract HPeriod{
  using SafeMath for uint;

  uint256 period_start_block;//the start block of the first round
  uint256 period_block_num;//the length in block of a round

  mapping (uint256 => uint256) public all_rounds_start_block;//the start block of all rounds
  uint256 current_round;//the index of current round

  constructor(uint256 _start_block, uint256 _period_block_num) public{
    period_start_block = _start_block;
    period_block_num = _period_block_num;

    current_round = 0;
  }

  function _end_current_and_start_new_round() internal returns(bool){
    require(block.number >= period_start_block, "1st period not start yet");
    if(current_round == 0 || block.number.safeSub(all_rounds_start_block[current_round]) >= period_block_num){
      current_round = current_round + 1;
      all_rounds_start_block[current_round] = block.number;
      return true;
    }
    return false;
  }


  //event HPeriodChanged(uint256 old, uint256 new_period);
  //function _change_period(uint256 _period) internal{
    //uint256 old = period_block_num;
    //period_block_num = _period;
    //emit HPeriodChanged(old, period_block_num);
  //}

  function getCurrentRoundStartBlock() public view returns(uint256){
    return all_rounds_start_block[current_round];
  }

  function getParamPeriodStartBlock() public view returns(uint256){
    return period_start_block;
  }

  function getParamPeriodBlockNum() public view returns(uint256){
    return period_block_num;
  }

  function getCurrentRound() public view returns(uint256){
    return current_round;
  }

  function getRoundLength(uint256 _round) public view returns(uint256){
    require(isRoundEnd(_round), "HPeriod: round not end");
    return all_rounds_start_block[_round + 1].safeSub(all_rounds_start_block[_round]);
  }

  function isRoundEnd(uint256 _round) public view returns(bool){
    return all_rounds_start_block[_round + 1] > 0;
  }

  function isRoundStart(uint256 _round) public view returns(bool){
    return all_rounds_start_block[_round] != 0;
  }

}

// File: contracts/core/HLongTerm.sol

pragma solidity >=0.4.21 <0.6.0;








contract HTokenInterfaceLT{
  function mint(address addr, uint256 amount)public;
  function burnFrom(address addr, uint256 amount) public;
  function set_ratio_to_target(uint256 _balance) public;
  function set_extra(bytes32 _target, uint256 _value) public;
  function set_target(address _target) public;
  mapping (bytes32 => uint256) public extra;
  uint256 public ratio_to_target;
  function transferOwnership(address addr) public;
}
/// @notice Longterm contract maintain the period and generate/destroy all tokens.
contract HLongTerm is HPeriod, Ownable{

  //this struct maps the token info, including the correspoinding target token (the market),
  // the period (e.g., 1 week, 2 weeks), the ratio, the round and the type ("in", "out" or "long")
  // to the address of the token
  struct round_token_info{
    mapping(bytes32 => address) hash_to_tokens;
  }

  mapping (uint256 => round_token_info) all_round_tokens;//recording the information in a round
  mapping (uint256 => address) long_term_tokens;//maps the ratio to correspounding longterm token address
  mapping (address => bool) long_term_token_bool;//identidy that whether an address is a valie longterm address

  HTokenFactoryInterface public token_factory;//the factory for all types of token
  address public target_token;//the address of target token, e.g. yycurve


  constructor(address _target_token, uint256 _start_block, uint256 _period, address _token_factory)
    HPeriod(_start_block, _period) public{
    target_token = _target_token;
    token_factory = HTokenFactoryInterface(_token_factory);
  }

  function uint2str(uint256 i) internal pure returns (string memory c) {
    if (i == 0) return "0";
    uint256 j = i;
    uint256 length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length - 1;
    while (i != 0){
      bstr[k--] = byte(48 + uint8(i % 10));
      i /= 10;
    }
    c = string(bstr);
  }

  function get_long_term_token_with_ratio(uint256 _ratio) public view returns(address){
    return long_term_tokens[_ratio];
  }

  function _getOrCreateToken(uint ratio, string memory in_out, string memory prefix, uint256 _type) internal returns(address, bool){
    if(_type != 3){
      _end_current_and_start_new_round();
    }

    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), ratio, getCurrentRound() + 1, in_out));

    round_token_info storage pi = all_round_tokens[getCurrentRound() + 1];

    if(pi.hash_to_tokens[h] == address(0x0)){
      string memory _postfix = uint2str(getParamPeriodBlockNum());
      string memory name = string(abi.encodePacked("horizon_", in_out, "_", ERC20Base(target_token).name(), "_", _postfix, "_", ratio > 0 ? uint2str(ratio) : "floating", "_", uint2str(getCurrentRound() + 1)));
      string memory symbol = string(abi.encodePacked(prefix, ERC20Base(target_token).symbol(), "_", _postfix, "_", ratio > 0 ? uint2str(ratio) : "f", "w", uint2str(getCurrentRound() + 1)));

      HTokenInterfaceLT pt = HTokenInterfaceLT(token_factory.createHToken(name, symbol, _type == 3));

      if(_type != 3){
        pt.set_extra(keccak256("round"), getCurrentRound() + 1);
      }
      pt.set_extra(keccak256("ratio"), ratio);
      pt.set_extra(keccak256("type"), _type);
      pt.set_target(long_term_tokens[ratio]);

      pt.transferOwnership(msg.sender);
      if (_type != 3){
      pi.hash_to_tokens[h] = address(pt);
      }
      else{
        long_term_tokens[ratio] = address(pt);
        long_term_token_bool[address(pt)] = true;
      }
      return (pi.hash_to_tokens[h], true);
    }
    return (pi.hash_to_tokens[h], false);
  }

  function getOrCreateInToken(uint ratio) public onlyOwner returns(address, bool){
    return _getOrCreateToken(ratio, "in", "hi", 1);
  }

  function getOrCreateOutToken(uint ratio) public onlyOwner returns(address, bool){
    return _getOrCreateToken(ratio, "out", "ho", 2);
  }


  function getOrCreateLongTermToken(uint ratio) public onlyOwner returns(address, bool){
    return _getOrCreateToken(ratio, "long", "hl", 3);
  }

  function updatePeriodStatus() public onlyOwner returns(bool){
    return _end_current_and_start_new_round();
  }

  function isLongTermTokenValid(address _addr) public view returns(bool){
    return long_term_token_bool[_addr];
  }

  function isPeriodInTokenValid(address _token_addr) public view returns(bool){
    if (_token_addr == address(0)) return false;
    HTokenInterfaceLT hti = HTokenInterfaceLT(_token_addr);
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), hti.extra(keccak256("ratio")), hti.extra(keccak256("round")),"in"));
    round_token_info storage pi = all_round_tokens[hti.extra(keccak256("round"))];
    if(pi.hash_to_tokens[h] == _token_addr){
      return true;
    }
    return false;
  }
  function isPeriodOutTokenValid(address _token_addr) public view returns(bool){
    if (_token_addr == address(0)) return false;
    HTokenInterfaceLT hto = HTokenInterfaceLT(_token_addr);
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), hto.extra(keccak256("ratio")), hto.extra(keccak256("round")),"out"));
    round_token_info storage pi = all_round_tokens[hto.extra(keccak256("round"))];
    if(pi.hash_to_tokens[h] == _token_addr){
      return true;
    }
    return false;
  }

  function totalInAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(uint256) {
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period,"in"));
    round_token_info storage pi = all_round_tokens[_period];
    address c = pi.hash_to_tokens[h];
    if(c == address(0x0)) return 0;

    IERC20 e = IERC20(c);
    return e.totalSupply();
  }

  function hintokenAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(address){
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period,"in"));
    round_token_info storage pi = all_round_tokens[_period];
    address c = pi.hash_to_tokens[h];
    return c;
  }

  function totalOutAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(uint256) {
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period, "out"));
    round_token_info storage pi = all_round_tokens[_period];
    address c = pi.hash_to_tokens[h];
    if(c == address(0x0)) return 0;

    IERC20 e = IERC20(c);
    return e.totalSupply();
  }

  function houttokenAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(address){
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period,"out"));
    round_token_info storage pi = all_round_tokens[_period];
    address c = pi.hash_to_tokens[h];
    return c;
  }
}

contract HLongTermFactory{

  event NewLongTerm(address addr);
  function createLongTerm(address _target_token, uint256 _start_block, uint256 _period, address _token_factory) public returns(address){
    HLongTerm pt = new HLongTerm(_target_token, _start_block, _period, _token_factory);

    pt.transferOwnership(msg.sender);
    emit NewLongTerm(address(pt));
    return address(pt);
  }
}
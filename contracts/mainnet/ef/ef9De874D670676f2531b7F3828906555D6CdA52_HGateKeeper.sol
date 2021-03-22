/**
 *Submitted for verification at Etherscan.io on 2021-03-22
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

// File: contracts/ystream/IYieldStream.sol

pragma solidity >=0.4.21 <0.6.0;

contract IYieldStream{

  string public name;

  function target_token() public view returns(address);

  function getVirtualPrice() public view returns(uint256);

  function getDecimal() public pure returns(uint256);

  function getPriceDecimal() public pure returns(uint256);
}

// File: contracts/core/HEnv.sol

pragma solidity >=0.4.21 <0.6.0;


contract HEnv is Ownable{

  address public token_addr;

  address public fee_pool_addr;

  uint256 public ratio_base;
  uint256 public bid_fee_ratio;
  uint256 public withdraw_fee_ratio;
  uint256 public cancel_fee_ratio;

  constructor(address _target_token) public{
    token_addr = _target_token;
    ratio_base = 100000000;
  }

  function changeFeePoolAddr(address _new) public onlyOwner{
    fee_pool_addr = _new;
  }

  function changeBidFeeRatio(uint256 _ratio) public onlyOwner{
    bid_fee_ratio = _ratio;
  }

  function changeWithdrawFeeRatio(uint256 _ratio) public onlyOwner{
    withdraw_fee_ratio = _ratio;
  }

  function changeCancelFeeRatio(uint256 _ratio) public onlyOwner{
    cancel_fee_ratio = _ratio;
  }
}


contract HEnvFactory{
  event NewHEnv(address addr);
  function createHEnv(address _target_token) public returns (address){
    HEnv env = new HEnv(_target_token);
    env.transferOwnership(msg.sender);
    emit NewHEnv(address(env));
    return address(env);
  }
}

// File: contracts/core/HPeriod.sol

pragma solidity >=0.4.21 <0.6.0;


contract HPeriod{
  using SafeMath for uint;

  uint256 period_start_block;
  uint256 period_block_num;
  uint256 period_gap_block;

  struct period_info{
    uint256 period;
    uint256 start_block;
    uint256 end_block;    // [start_block, end_block)
  }

  mapping (uint256 => period_info) all_periods;
  uint256 current_period;

  bool is_gapping;

  constructor(uint256 _start_block, uint256 _period_block_num, uint256 _gap_block_num) public{
    period_start_block = _start_block;
    period_block_num = _period_block_num;

    period_gap_block = _gap_block_num;
    current_period = 0;
    is_gapping = true;
  }

  function _end_current_and_start_new_period() internal returns(bool){
    require(block.number >= period_start_block, "1st period not start yet");

    if(is_gapping){
      if(current_period == 0 || block.number.safeSub(all_periods[current_period].end_block) >= period_gap_block){
        current_period = current_period + 1;
        all_periods[current_period].period = current_period;
        all_periods[current_period].start_block = block.number;
        is_gapping = false;
        return true;
      }
    }else{
      if(block.number.safeSub(all_periods[current_period].start_block) >= period_block_num){
        all_periods[current_period].end_block = block.number;
        is_gapping = true;
      }
    }
    return false;
  }


  event HPeriodChanged(uint256 old, uint256 new_period);
  function _change_period(uint256 _period) internal{
    uint256 old = period_block_num;
    period_block_num = _period;
    emit HPeriodChanged(old, period_block_num);
  }

  function getCurrentPeriodStartBlock() public view returns(uint256){
    (, uint256 s, ) = getPeriodInfo(current_period);
    return s;
  }

  function getPeriodInfo(uint256 period) public view returns(uint256 p, uint256 s, uint256 e){
    p = all_periods[period].period;
    s = all_periods[period].start_block;
    e = all_periods[period].end_block;
  }

  function getParamPeriodStartBlock() public view returns(uint256){
    return period_start_block;
  }

  function getParamPeriodBlockNum() public view returns(uint256){
    return period_block_num;
  }

  function getParamPeriodGapNum() public view returns(uint256){
    return period_gap_block;
  }

  function getCurrentPeriod() public view returns(uint256){
    return current_period;
  }

  function isPeriodEnd(uint256 _period) public view returns(bool){
    return all_periods[_period].end_block != 0;
  }

  function isPeriodStart(uint256 _period) public view returns(bool){
    return all_periods[_period].start_block != 0;
  }

}

// File: contracts/core/HPeriodToken.sol

pragma solidity >=0.4.21 <0.6.0;





contract HTokenFactoryInterface{
  function createFixedRatioToken(address _token_addr, uint256 _period, uint256 _ratio, string memory _postfix) public returns(address);
  function createFloatingToken(address _token_addr, uint256 _period, string memory _postfix) public returns(address);
}

contract HTokenInterface{
  function mint(address addr, uint256 amount)public;
  function burnFrom(address addr, uint256 amount) public;
  uint256 public period_number;
  uint256 public ratio; // 0 is for floating
  uint256 public underlying_balance;
  function setUnderlyingBalance(uint256 _balance) public;
  function setTargetToken(address _target) public;
}

contract HPeriodToken is HPeriod, Ownable{

  struct period_token_info{
    address[] period_tokens;

    mapping(bytes32 => address) hash_to_tokens;
  }

  mapping (uint256 => period_token_info) all_period_tokens;

  HTokenFactoryInterface public token_factory;
  address public target_token;


  constructor(address _target_token, uint256 _start_block, uint256 _period, uint256 _gap, address _factory)
    HPeriod(_start_block, _period, _gap) public{
    target_token = _target_token;
    token_factory = HTokenFactoryInterface(_factory);
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

  function getOrCreateToken(uint ratio) public onlyOwner returns(address, bool){

    _end_current_and_start_new_period();

    uint256 p = getCurrentPeriod();
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), ratio, p + 1));
    address c = address(0x0);

    period_token_info storage pi = all_period_tokens[p + 1];

    bool s  = false;
    if(pi.hash_to_tokens[h] == address(0x0)){
      if(ratio == 0){
        c = token_factory.createFloatingToken(target_token, p + 1, uint2str(getParamPeriodBlockNum()));
      }
      else{
        c = token_factory.createFixedRatioToken(target_token, p + 1, ratio, uint2str(getParamPeriodBlockNum()));
      }
      HTokenInterface(c).setTargetToken(target_token);
      Ownable ow = Ownable(c);
      ow.transferOwnership(owner());
      pi.period_tokens.push(c);
      pi.hash_to_tokens[h] = c;
      s = true;
    }
    c = pi.hash_to_tokens[h];

    return(c, s);
  }

  function updatePeriodStatus() public onlyOwner returns(bool){
    return _end_current_and_start_new_period();
  }

  function isPeriodTokenValid(address _token_addr) public view returns(bool){
    HTokenInterface hti = HTokenInterface(_token_addr);
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), hti.ratio(), hti.period_number()));
    period_token_info storage pi = all_period_tokens[hti.period_number()];
    if(pi.hash_to_tokens[h] == _token_addr){
      return true;
    }
    return false;
  }

  function totalAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(uint256) {
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period));
    period_token_info storage pi = all_period_tokens[_period];
    address c = pi.hash_to_tokens[h];
    if(c == address(0x0)) return 0;

    IERC20 e = IERC20(c);
    return e.totalSupply();
  }

  function htokenAtPeriodWithRatio(uint256 _period, uint256 _ratio) public view returns(address){
    bytes32 h = keccak256(abi.encodePacked(target_token, getParamPeriodBlockNum(), _ratio, _period));
    period_token_info storage pi = all_period_tokens[_period];
    address c = pi.hash_to_tokens[h];
    return c;
  }
}

contract HPeriodTokenFactory{

  event NewPeriodToken(address addr);
  function createPeriodToken(address _target_token, uint256 _start_block, uint256 _period, uint256 _gap, address _token_factory) public returns(address){
    HPeriodToken pt = new HPeriodToken(_target_token, _start_block, _period, _gap, _token_factory);

    pt.transferOwnership(msg.sender);
    emit NewPeriodToken(address(pt));
    return address(pt);
  }

}

// File: contracts/core/HGateKeeper.sol

pragma solidity >=0.4.21 <0.6.0;








contract HDispatcherInterface{
  function getYieldStream(address _token_addr) public view returns (IYieldStream);
}
contract TokenBankInterface{
  function issue(address payable _to, uint _amount) public returns(bool success);
}

contract ClaimHandlerInterface{
  function handle_create_contract(address from, address lop_token_addr) public;
  function handle_claim(address from, address lp_token_addr, uint256 amount) public;
}

contract HGateKeeper is Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  HDispatcherInterface public dispatcher;
  address public target_token;
  HEnv public env;

  HPeriodToken public period_token;
  ClaimHandlerInterface public claim_handler;
  address public yield_interest_pool;

  uint256 public settled_period;
  uint256 public max_amount;
  struct period_price_info{
    uint256 start_price;
    uint256 end_price;
  }

  mapping (uint256 => uint256) public period_token_amount;
  mapping (uint256 => period_price_info) public period_prices;


  constructor(address _token_addr, address _env, address _dispatcher, address _period_token) public{
    target_token = _token_addr;
    env = HEnv(_env);
    dispatcher = HDispatcherInterface(_dispatcher);
    period_token = HPeriodToken(_period_token);
    settled_period = 0;
  }

  event ChangeClaimHandler(address old, address _new);
  function changeClaimHandler(address handler) public onlyOwner{
    address old = address(claim_handler);
    claim_handler = ClaimHandlerInterface(handler);
    emit ChangeClaimHandler(old, handler);
  }

  event ChangeMaxAmount(uint256 old, uint256 _new);
  function set_max_amount(uint _amount) public onlyOwner{
    uint256 old = max_amount;
    max_amount = _amount;
    emit ChangeMaxAmount(old, max_amount);
  }

  event HorizonBid(address from, uint256 amount, uint256 ratio, address lp_token_addr);
  function bidRatio(uint256 _amount, uint256 _ratio) public returns(address lp_token_addr){
    require(_ratio == 0 || isSupportRatio(_ratio), "not support ratio");
    (address addr, bool created) = period_token.getOrCreateToken(_ratio);

    if(created){
      if(claim_handler != ClaimHandlerInterface(0x0)){
        claim_handler.handle_create_contract(msg.sender, addr);
      }
    }

    if(max_amount > 0){
      require(_amount <= max_amount, "too large amount");
      require(_amount.safeAdd(IERC20(addr).balanceOf(msg.sender)) <= max_amount, "please use another wallet");
    }


    _check_period();

    ///*
    require(IERC20(target_token).allowance(msg.sender, address(this)) >= _amount, "not enough allowance");
    uint _before = IERC20(target_token).balanceOf(address(this));
    IERC20(target_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = IERC20(target_token).balanceOf(address(this));
    _amount = _after.safeSub(_before); // Additional check for deflationary tokens

    uint256 decimal = dispatcher.getYieldStream(target_token).getDecimal();
    require(decimal <= 1e18, "decimal too large");
    uint256 shares = _amount.safeMul(1e18).safeDiv(decimal);

    uint256 period = HTokenInterface(addr).period_number();
    period_token_amount[period] = period_token_amount[period].safeAdd(_amount);


    HTokenInterface(addr).mint(msg.sender, shares);

    emit HorizonBid(msg.sender, _amount, _ratio, addr);
    return addr;
    //*/
  }

  function bidFloating(uint256 _amount) public returns(address lp_token_addr){
    return bidRatio(_amount, 0);
  }

  event CancelBid(address from, uint256 amount, uint256 fee, address _lp_token_addr);
  function cancelBid(address _lp_token_addr) public{
    bool is_valid = period_token.isPeriodTokenValid(_lp_token_addr);
    require(is_valid, "invalid lp token address");
    uint256 amount = IERC20(_lp_token_addr).balanceOf(msg.sender);
    require(amount > 0, "no bid at this period");

    _check_period();

    uint256 period = HTokenInterface(_lp_token_addr).period_number();
    require(period_token.getCurrentPeriod() < period,
           "period sealed already");

    HTokenInterface(_lp_token_addr).burnFrom(msg.sender, amount);

    uint256 decimal = dispatcher.getYieldStream(target_token).getDecimal();

    uint256 target_amount = amount.safeMul(decimal).safeDiv(1e18);

    period_token_amount[period] = period_token_amount[period].safeSub(target_amount);
    if(env.cancel_fee_ratio() != 0 && env.fee_pool_addr() != address(0x0)){
      uint256 fee = target_amount.safeMul(env.cancel_fee_ratio()).safeDiv(env.ratio_base());
      uint256 recv = target_amount.safeSub(fee);
      IERC20(target_token).safeTransfer(msg.sender, recv);
      IERC20(target_token).safeTransfer(env.fee_pool_addr(), fee);
      emit CancelBid(msg.sender, recv, fee, _lp_token_addr);
    }else{
      IERC20(target_token).safeTransfer(msg.sender, target_amount);
      emit CancelBid(msg.sender, target_amount, 0, _lp_token_addr);
    }

  }

  function changeBid(address _lp_token_addr, uint256 _new_amount, uint256 _new_ratio) public{
    cancelBid(_lp_token_addr);
    bidRatio(_new_amount, _new_ratio);
  }

  event HorizonClaim(address from, address _lp_token_addr, uint256 amount, uint256 fee);
  function claim(address _lp_token_addr, uint256 _amount) public {
    bool is_valid = period_token.isPeriodTokenValid(_lp_token_addr);
    require(is_valid, "invalid lp token address");
    uint256 amount = IERC20(_lp_token_addr).balanceOf(msg.sender);
    require(amount >= _amount, "no enough bid at this period");

    _check_period();
    require(period_token.isPeriodEnd(HTokenInterface(_lp_token_addr).period_number()), "period not end");

    uint total = IERC20(_lp_token_addr).totalSupply();
    uint underly = HTokenInterface(_lp_token_addr).underlying_balance();
    HTokenInterface(_lp_token_addr).burnFrom(msg.sender, _amount);
    uint t = _amount.safeMul(underly).safeDiv(total);
    HTokenInterface(_lp_token_addr).setUnderlyingBalance(underly.safeSub(t));

    if(env.withdraw_fee_ratio() != 0 && env.fee_pool_addr() != address(0x0)){
      uint256 fee = t.safeMul(env.withdraw_fee_ratio()).safeDiv(env.ratio_base());
      uint256 recv = t.safeSub(fee);
      IERC20(target_token).safeTransfer(msg.sender, recv);
      IERC20(target_token).safeTransfer(env.fee_pool_addr(), fee);
      emit HorizonClaim(msg.sender, _lp_token_addr, recv, fee);
    }else{
      IERC20(target_token).safeTransfer(msg.sender, t);
      emit HorizonClaim(msg.sender, _lp_token_addr, t, 0);
    }

    if(claim_handler != ClaimHandlerInterface(0x0)){
      claim_handler.handle_claim(msg.sender, _lp_token_addr, _amount);
    }
  }

  function claimAllAndBidForNext(address _lp_token_addr,  uint256 _ratio, uint256 _next_bid_amount) public{

    uint256 amount = IERC20(_lp_token_addr).balanceOf(msg.sender);
    claim(_lp_token_addr, amount);

    uint256 new_amount = IERC20(target_token).balanceOf(msg.sender);
    if(new_amount > _next_bid_amount){
      new_amount = _next_bid_amount;
    }
    bidRatio(new_amount, _ratio);
  }

  function _check_period() internal{
    period_token.updatePeriodStatus();

    uint256 new_period = period_token.getCurrentPeriod();
    if(period_prices[new_period].start_price == 0){
      period_prices[new_period].start_price = dispatcher.getYieldStream(target_token).getVirtualPrice();
    }
    if(period_token.isPeriodEnd(settled_period + 1)){
      _settle_period(settled_period + 1);
    }
  }

  mapping (uint256 => bool) public support_ratios;
  uint256[] public sratios;

  event SupportRatiosChanged(uint256[] rs);
  function resetSupportRatios(uint256[] memory rs) public onlyOwner{
    for(uint i = 0; i < sratios.length; i++){
      delete support_ratios[sratios[i]];
    }
    delete sratios;
    for(uint i = 0; i < rs.length; i++){
      if(i > 0){
        require(rs[i] > rs[i-1], "should be ascend");
      }
      sratios.push(rs[i]);
      support_ratios[rs[i]] = true;
    }
    emit SupportRatiosChanged(sratios);
  }

  function isSupportRatio(uint256 r) public view returns(bool){
    for(uint i = 0; i < sratios.length; i++){
      if(sratios[i] == r){
        return true;
      }
    }
    return false;
  }

  function updatePeriodStatus() public{
    _check_period();
  }

  function _settle_period(uint256 _period) internal{
    if(period_prices[_period].end_price== 0){
      period_prices[_period].end_price= dispatcher.getYieldStream(target_token).getVirtualPrice();
    }


    uint256 tdecimal = dispatcher.getYieldStream(target_token).getDecimal();
    uint256 left = period_token_amount[_period].safeMul(period_prices[_period].end_price.safeSub(period_prices[_period].start_price));

    uint256 s = 0;
    address fht = period_token.htokenAtPeriodWithRatio(_period, 0);

    for(uint256 i = 0; i < sratios.length; i++){
      uint256 t = period_token.totalAtPeriodWithRatio(_period, sratios[i]).safeMul(tdecimal).safeDiv(1e18);
      uint256 nt = t.safeMul(period_prices[_period].start_price).safeMul(sratios[i]).safeDiv(env.ratio_base());

      address c = period_token.htokenAtPeriodWithRatio(_period, sratios[i]);
      if(c != address(0x0)){
        if(nt > left){
          nt = left;
        }
        left = left.safeSub(nt);
        t = t.safeMul(period_prices[_period].start_price).safeAdd(nt).safeDiv(period_prices[_period].end_price);
        HTokenInterface(c).setUnderlyingBalance(t);
        s = s.safeAdd(t);
      }
    }

    if(fht != address(0x0)){
      left = period_token_amount[_period].safeSub(s);
      HTokenInterface(fht).setUnderlyingBalance(left);
      s = s.safeAdd(left);
    }
    if(s < period_token_amount[_period]){
      s = period_token_amount[_period].safeSub(s);
      require(yield_interest_pool != address(0x0), "invalid yield interest pool");
      IERC20(target_token).safeTransfer(yield_interest_pool, s);
    }

    settled_period = _period;
  }

  event ChangeYieldInterestPool(address old, address _new);
  function changeYieldPool(address _pool) onlyOwner public{
    require(_pool != address(0x0), "invalid pool");
    address old = yield_interest_pool;
    yield_interest_pool = _pool;
    emit ChangeYieldInterestPool(old, _pool);
  }

}

contract HGateKeeperFactory is Ownable{
  event NewGateKeeper(address addr);

  function createGateKeeperForPeriod(address _env_addr, address _dispatcher, address _period_token) public returns(address){
    HEnv e = HEnv(_env_addr);
    HGateKeeper gk = new HGateKeeper(e.token_addr(), _env_addr, _dispatcher, _period_token);
    gk.transferOwnership(msg.sender);
    emit NewGateKeeper(address(gk));
    return address(gk);
  }
}
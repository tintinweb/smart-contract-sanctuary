/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// File: contracts/assets/TokenBankInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract TokenBankInterface{
  function issue(address token_addr, address payable _to, uint _amount) public returns (bool success);
}

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
    string public version = "AET_0.1"; //An arbitrary versioning scheme

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
    mapping (address => Checkpoint[]) public balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] public totalSupplyHistory;

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
    }function getCheckPointAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
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
        return min;
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

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        uint balance = IERC20(_token).balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/plugins/TokenAuction.sol

pragma solidity >=0.4.21 <0.6.0;








contract TokenAuction is Ownable, TokenClaimer{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public bank;
  address public target_token;
  address public recv_token;
  address public yield_pool;
  uint256 public start_price;
  uint256 public last_duration_in_blocknum;
  uint256 public minimal_bumpup;
  uint256 public minimal_amount;
  uint256 public ratio_base;

  bool public paused;


  struct round_info{
    uint256 last_auction_block;
    uint256 highest_price;
    uint256 highest_amount;
    address payable highest_sender;
    bool settled;
  }

  round_info[] public all_rounds;

  constructor(address _bank, address _target_token, address _recv_token, address _yield_pool, uint256 _start_price,
              uint256 _last_duration_in_blocknum, uint256 _minimal_bumpup, uint256 _minimal_amount) public{

    bank = _bank;
    target_token = _target_token;
    recv_token = _recv_token;
    start_price = _start_price;
    last_duration_in_blocknum = _last_duration_in_blocknum;
    minimal_bumpup = _minimal_bumpup;
    minimal_amount = _minimal_amount;
    yield_pool = _yield_pool;
    ratio_base = 10000;
    paused = false;
  }

  event PlaceAuction(address newAuctioner, uint256 newAmount, uint256 newPrice, address oldAuctioner, uint256 oldAmount, uint256 oldPrice);
  function auction(uint256 amount, uint256 price) public returns(bool){
    require(!paused, "auction already paused");
    require(amount >= minimal_amount, "less than minimal amount");
    require(price >= start_price, "less than start price");

    if(all_rounds.length == 0){
      round_info memory ri;
      ri.last_auction_block == block.number;
      all_rounds.push(ri);
    }

    round_info storage ri = all_rounds[all_rounds.length - 1];
    if(block.number > ri.last_auction_block.safeAdd(last_duration_in_blocknum)){
      if(!ri.settled){
        _end_current_auction();
      }
      round_info memory ti;
      ti.last_auction_block == block.number;
      all_rounds.push(ti);
      ri = all_rounds[all_rounds.length - 1];
    }
    //require(price >= ri.highest_price.safeMul(ratio_base + minimal_bumpup).safeDiv(ratio_base), "price bump up too small");

    uint256 t = amount.safeMul(price).safeDiv(uint256(10)**ERC20Base(target_token).decimals());
    uint256 h = ri.highest_amount.safeMul(ri.highest_price).safeDiv(uint256(10)**ERC20Base(target_token).decimals());

    require(t >= h.safeMul(ratio_base + minimal_bumpup).safeDiv(ratio_base), "total payment bump up too small");
    require(amount <= IERC20(target_token).balanceOf(bank), "bank doesn't have enough token");

    if(ri.highest_sender != address(0x0)){
      IERC20(recv_token).safeTransfer(ri.highest_sender, h);
    }
    emit PlaceAuction(msg.sender, amount, price, ri.highest_sender, ri.highest_amount, ri.highest_price);

    IERC20(recv_token).safeTransferFrom(msg.sender, address(this), t);
    ri.last_auction_block = block.number;
    ri.highest_price = price;
    ri.highest_amount = amount;
    ri.highest_sender = msg.sender;
    ri.settled = false;
    return true;
  }

  event AuctionDone(address bidder, uint256 price, uint256 amount);
  function _end_current_auction() internal{
    round_info storage ri = all_rounds[all_rounds.length - 1];
    if(ri.settled) return;
    //require(ri.settled == false, "already settled");
    ri.settled = true;
    TokenBankInterface(bank).issue(target_token, ri.highest_sender, ri.highest_amount);
    IERC20(recv_token).safeTransfer(yield_pool, ri.highest_price.safeMul(ri.highest_amount).safeDiv(uint256(10)**ERC20Base(target_token).decimals()));
    emit AuctionDone(ri.highest_sender, ri.highest_price, ri.highest_amount);
  }

  function end_current_auction() public {
    if(all_rounds.length == 0){
      return ;
    }
    round_info storage ri = all_rounds[all_rounds.length - 1];
    if(ri.settled){
      return ;
    }
    require(block.number > ri.last_auction_block.safeAdd(last_duration_in_blocknum), "not ready to end");
    _end_current_auction();
  }

  function pause_auction() public onlyOwner{
    _end_current_auction();
    paused = true;
  }

  function resume_auction() public onlyOwner{
    paused = false;
  }

  function claimStdTokens(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }

  event SetStartPrice(uint256 start_price);
  function set_start_price(uint256 _start_price) public onlyOwner{
    start_price = _start_price;
    emit SetStartPrice(start_price);
  }

  event SetMinimalAmount(uint256 minimal_amount);
  function set_minimal_amount(uint256 _minimal_amount) public onlyOwner{
    minimal_amount = _minimal_amount;
    emit SetMinimalAmount(minimal_amount);
  }

  event SetMinimalBumpup(uint256 minimal_bumpup);
  function set_minimal_bumpup(uint256 _minimal_bumpup) public onlyOwner{
    minimal_bumpup = _minimal_bumpup;
    emit SetMinimalBumpup(minimal_bumpup);
  }
  
  event SetDuration(uint256 last_duration_in_blocknum);
  function set_duration(uint256 _last_duration_in_blocknum) public onlyOwner{
    last_duration_in_blocknum = _last_duration_in_blocknum;
    emit SetDuration(last_duration_in_blocknum);
  }

  event ChangeYieldPool(address yield_pool);
  function change_yield_pool(address _yield_pool) public onlyOwner{
    yield_pool = _yield_pool;
    emit ChangeYieldPool(yield_pool);
  }

  event ChangeBank(address bank);
  function change_bank(address _bank) public onlyOwner{
    bank = _bank;
    emit ChangeBank(bank);
  }

  function get_current_auction_round() public view returns(uint256){
    return all_rounds.length;
  }

  function get_current_auction_info() public view returns(uint256 last_auction_block, uint256 highest_price, uint256 highest_amount, address payable highest_sender){
    return get_auction_info(get_current_auction_round() - 1);
  }
  function get_auction_info(uint256 index) public view returns(uint256 last_auction_block, uint256 highest_price, uint256 highest_amount, address payable highest_sender){
    round_info storage ri = all_rounds[index];
    last_auction_block = ri.last_auction_block;
    highest_price = ri.highest_price;
    highest_amount = ri.highest_amount;
    highest_sender = ri.highest_sender;
  }
}

contract TokenAuctionFactory{
  event NewTokenAuction(address addr);

  function createTokenAuction(address bank, address target_token, address recv_token, address yield_pool, uint256 start_price,
                        uint256 last_duration_in_blocknum, uint256 minimal_bumpup, uint256 minimal_amount) public returns(address){
    TokenAuction newAuction = new TokenAuction(bank, target_token, recv_token, yield_pool, start_price, last_duration_in_blocknum, minimal_bumpup, minimal_amount);

    emit NewTokenAuction(address(newAuction));
    newAuction.transferOwnership(msg.sender);
    return address(newAuction);
  }
}
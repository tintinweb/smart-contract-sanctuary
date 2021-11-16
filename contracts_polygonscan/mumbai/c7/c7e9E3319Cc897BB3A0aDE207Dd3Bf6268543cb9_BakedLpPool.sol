/**
 *Submitted for verification at polygonscan.com on 2021-11-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

//import "./nft.sol";


library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
    }
    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    
    return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    
    return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    
    return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    
    return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
    }
}

contract Context1 {
    constructor()  {}
    
    function _msgSender_() internal view returns (address payable) {
    return payable(msg.sender);
    }
    
    function _msgData_() internal view returns (bytes memory) {
    this;
    return msg.data;
    }
}

contract Ownable is Context1 {
    address private _owner;
    
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
    constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
    return _owner;
    }
    
    modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
    }
    
    function isOwner() public view returns (bool) {
    return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
    require(
    newOwner != address(0),
    "Ownable: new owner is the zero address"
    );
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    }
}

/**
* @dev Interface of the ERC20 standard as defined in the EIP. Does not include
* the optional functions; to access them see {ERC20Detailed}.
*/
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8);
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);
    
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);
    
    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);
    
    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint256);
    
    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address _owner, address spender) external view returns (uint256);
    
    /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(
    address sender,
    address recipient,
    uint256 amount
    ) external returns (bool);
    
    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    * a call to {approve}. `value` is the new allowance.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address1 {
    /**
    * @dev Returns true if `account` is a contract.
    *
    * This test is non-exhaustive, and there may be false-negatives: during the
    * execution of a contract's constructor, its address will be reported as
    * not containing a contract.
    *
    * IMPORTANT: It is unsafe to assume that an address for which this
    * function returns false is an externally-owned account (EOA) and not a
    * contract.
    */
    function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
    }
    
    /**
    * @dev Converts an `address` into `address payable`. Note that this is
    * simply a type cast: the actual underlying value is not changed.
    *
    * Available since v2.4.0.
    */
    function toPayable(address account) internal pure returns (address payable) {
    return payable(address(uint160(account)));
    }
    
    /**
    * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    * `recipient`, forwarding all available gas and reverting on errors.
    *
    * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    * of certain opcodes, possibly making contracts go over the 2300 gas limit
    * imposed by `transfer`, making them unable to receive funds via
    * `transfer`. {sendValue} removes this limitation.
    *
    * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    *
    * IMPORTANT: because control is transferred to `recipient`, care must be
    * taken to not create reentrancy vulnerabilities. Consider using
    * {ReentrancyGuard} or the
    * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    *
    * Available since v2.4.0.
    */
    function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    
    // solhint-disable-next-line avoid-call-value
    (bool success, ) = recipient.call{value:amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// interface IPool {
//     function notifyReward() external payable ;
//     }

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
* @title SafeERC20
* @dev Wrappers around ERC20 operations that throw on failure (when the token
* contract returns false). Tokens that return no value (and instead revert or
* throw on failure) are also supported, non-reverting calls are assumed to be
* successful.
* To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
* which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
*/
library SafeERC20 {
    using SafeMath for uint256;
    using Address1 for address;
    
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0),
    "SafeERC20: approve from non-zero to non-zero allowance"
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    /**
    * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
    * on the return value: the return value is optional (but if data is returned, it must not be false).
    * @param token The token targeted by the call.
    * @param data The call data (encoded using abi.encode or one of its variants).
    */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    
    // A Solidity high level call has three parts:
    // 1. The target address is checked to verify it contains contract code
    // 2. The call itself is made, and success asserted
    // 3. The return value is decoded, which in turn checks the size of the returned data.
    // solhint-disable-next-line max-line-length
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

contract LPTokenWrapper is Ownable {
    
    
    uint256 counter;
    struct Stakepool {
        uint256 timestamp;
        uint256 amount;
        address walletaddress;
        bool iswhitelisted;
        uint256 participationCount;
        bool stakeStatus;
        uint256 initialStakeTime;
    }
    
    uint256 participationCount=0;
    mapping(address => uint256)  Stakecount;
    
    mapping (uint256 => Stakepool) Stakemap;
    uint256[] public stakeAccts;
    
    mapping (address => uint256[]) public toCheckList;

    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //IERC20 public BAKED;
    
    IERC20 public BAKED = IERC20(0xF562802e40569408540B7Dc2EFF5b72a43D7314D); // BAKED Token
    

    
    uint256 private _totalSupply;
    //uint256 public counter=0;
    mapping(address => uint256) private _balances;
    
    function totalSupply() public view returns (uint256) {
    return _totalSupply.div(10 **18);
    }
    
    function _balanceOf(address account) public view returns (uint256) {
    return _balances[account].div(10**18);
    }
    
    function stake(uint256 _stkId,uint256 amount) public virtual {
        amount = amount.mul(10**18);
    require(BAKED.balanceOf(msg.sender)>= amount,"Error: User Token Balance is insufficient");
    _totalSupply = _totalSupply + amount;
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    BAKED.safeTransferFrom
    (msg.sender, address(this), amount);
    }
    
    function withdraw(uint256 _stkId,uint256 amount) public virtual{
        amount = amount.mul(10**18);
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    BAKED.safeTransfer(msg.sender, amount);
    }
    
    function setStakePool(uint256 _stkId, uint256 _amount) public {
        //var Stakepool = Stakemap[counter];
        
        Stakemap[_stkId].timestamp = block.timestamp;
        Stakemap[_stkId].amount = _amount;
        Stakemap[_stkId].walletaddress = msg.sender;
        Stakemap[_stkId].stakeStatus = true;
        Stakemap[_stkId].initialStakeTime = block.timestamp;
        toCheckList[msg.sender].push(_stkId);

    }
    
    function getStakes(uint256 _stakeid) view public returns (uint256, uint256, uint256, address, bool,bool,uint256) {
        return (_stakeid,Stakemap[_stakeid].amount, Stakemap[_stakeid].timestamp, Stakemap[_stakeid].walletaddress,Stakemap[_stakeid].iswhitelisted,Stakemap[_stakeid].stakeStatus,Stakemap[_stakeid].initialStakeTime);
    }
    
}

contract BakedLpPool is LPTokenWrapper {
    
    
    uint256 public duration = 30 days; // 30 days;
    uint256 starttime = 0; // trace startdate of staking pool
    uint256 public minTokenValue= 25000;
    uint256 trackStakeTime;
    
    uint256 whitelistedTime;
    
    
    mapping(address => uint256) userRewardPerTokenPaid;
    mapping(address => uint256) rewards;
    
    uint256 public totalparticipationCount=0;
    mapping(address => uint256) public Totalticket;
    
    
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Rewarded(address indexed from, address indexed to, uint256 value);
    

    function adminSetMinTokenAmount(uint256 _minTokenAmount) public onlyOwner {
    minTokenValue = _minTokenAmount;
    }
    
    function adminSetDuration(uint256 _duration) public onlyOwner {
    duration = _duration;
    }
    
    function stake(uint256 _stkId, uint256 amount) public  override {
    require(amount > 0, "Error : Cannot stake 0");
    require(amount >= minTokenValue, "Error : Canot stake, need minimum Baked tokens");
    super.stake(_stkId,amount);
    trackStakeTime=block.timestamp;
    super.setStakePool(_stkId,amount);
    }
    
    function withdraw(uint256 _stkId,uint256 amount) public override
    {
        uint256 stkTime = Stakemap[_stkId].initialStakeTime;
        uint256 unstakeTime = stkTime + duration;
    require(block.timestamp>=unstakeTime,"Error:User not Completed the Lock duration");
    require(amount > 0, "Error : Cannot withdraw 0");
    super.withdraw(_stkId,amount);
    Stakemap[_stkId].stakeStatus = false;
    
    }
    
    
    function whiteListed(uint256 _stakeid) public {
        whitelistedTime = Stakemap[_stakeid].timestamp + duration;
        require(block.timestamp >=whitelistedTime, "Your Lock duration is not completed" );
        Stakemap[_stakeid].iswhitelisted = true;
        
        
        uint256 rewardDuration =block.timestamp - Stakemap[_stakeid].timestamp;                                                                                                               
        require(rewardDuration >= duration, "Locking Period is not over");
        uint256 ticketonduration = rewardDuration/duration;
        
        require(Stakemap[_stakeid].amount >= minTokenValue,"balance is low reward not applicable");
        uint256 ticketonamount = Stakemap[_stakeid].amount/minTokenValue;
        
        uint256 tempcount = Stakemap[_stakeid].participationCount;
         Stakemap[_stakeid].participationCount = (ticketonamount * ticketonduration) + tempcount;
        
        address tempaddress = Stakemap[_stakeid].walletaddress;
        Totalticket[tempaddress] = Totalticket[tempaddress] + (Stakemap[_stakeid].participationCount - tempcount);
        
       
        Stakemap[_stakeid].timestamp = block.timestamp; 
    }
    
    function AllStakes(address _addr) public view returns(uint256[] memory)
    {
        return toCheckList[_addr];
    }

    
    function iswhitelisted(uint256 _stakeid) public view returns(bool){
        return Stakemap[_stakeid].iswhitelisted;
    } 
    
    function ticketcount(uint256 _stakeid) public view returns(uint256){
        return Stakemap[_stakeid].participationCount;
    }
    
    function changeAdmin(address newOwner) public onlyOwner{
        transferOwnership(newOwner);
    }
    
}
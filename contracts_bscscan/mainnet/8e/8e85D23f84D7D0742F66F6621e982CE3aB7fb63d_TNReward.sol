/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.6.12;



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
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
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


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
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
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

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);   
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

  
}

contract TNReward is Ownable{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 private pledgeTotal;
    
    
    mapping(address => PledgeAmount) private addressPledgeAmount;
    
    address[] pledgeAddresses;
    
    IERC20 private pair;
    
    IERC20 private erc20;
    
    
    struct PledgeAmount{
        uint256 index;
        uint256 pledgeAmount;
    }
    
    
    
    constructor(IERC20 _erc20, IERC20 _pair) public{
        erc20 = _erc20;
        pair = _pair;
    }
    
    
    
    event Pledge(address indexed pledgeAddress, uint256 value);
    
    event Release(address indexed releaseAddress, uint256 value);
    
    event Reward(address indexed rewardAddress, uint256 value);
    
    
    
    
    function getAddressPledgeAmount(address _address) public view returns (uint256) {
        return addressPledgeAmount[_address].pledgeAmount;
    }
    
    
    function getPledgeTotal() public view returns (uint256) {
        return pledgeTotal;
    }
    
    
    
    function setPairAddress(IERC20 _pair) external onlyOwner{
        pair = _pair;
    }
    
    function getPairAddress() public view returns(IERC20) {
        return pair;
    }
    
    
    function setErc20Address(IERC20 _erc20) external onlyOwner{
        erc20 = _erc20;
    }
    
    function getErc20Address() public view returns(IERC20) {
        return erc20;
    }
    
    
    function pledge(uint256 amount) public{
        require(amount > 0, "Amount:  zero");
        
        address msgSender = _msgSender();
        
        require(pair.balanceOf(msgSender) >= amount, "Balance: insufficient");
        require(pair.allowance(msgSender, address(this)) >= amount, "Approve: insufficient");
        
        pair.safeTransferFrom(msgSender, address(this), amount);
        
        pledge(msgSender, amount);
        
        emit Pledge(msgSender, amount);
       
    }
    
    
    
    
    
    function reward() external onlyOwner{
        
        uint256 amount = erc20.balanceOf(address(this));
         
        require(amount > 0, "Balance: insufficient");
         
        for(uint i = 0; i < pledgeAddresses.length; i++) {
            
            reward(pledgeAddresses[i], amount);
            
        }
        
    }
    

    
      
    function release(uint256 amount) public{
        require(amount > 0, "Amount:  zero");
        
        address msgSender = _msgSender();
        require(addressPledgeAmount[msgSender].pledgeAmount >= amount, "PledgeAmount: insufficient");
        
        pair.transfer(msgSender, amount);
        
        
        release(msgSender, amount);
        
        
        
        emit Release(msgSender, amount);
    }
    






    
    function pledge(address _address, uint256 _amount) private {
        
        if(0 == addressPledgeAmount[_address].pledgeAmount){
            pushPledgeAddress(_address);
            pushPledgeAmount(_address);
        }
        
        
        addAddressPledgeAmount(_address, _amount);
        
        addPledgeTotal(_amount);
    }
   
    
    
    function pushPledgeAddress(address _address) private {
        pledgeAddresses[pledgeAddresses.length] = _address;
    }
    
    
    function pushPledgeAmount(address _address) private {
        PledgeAmount memory pledgeAmount = PledgeAmount(pledgeAddresses.length, 0);
        addressPledgeAmount[_address] = pledgeAmount;
    }
    
    
    function addAddressPledgeAmount(address _address, uint256 amount) private {
        addressPledgeAmount[_address].pledgeAmount = addressPledgeAmount[_address].pledgeAmount.add(amount);
    }
    
    
    
    
    
    function reward(address _address, uint256 _amount) private {
       
       uint256 rewardAmount = _amount.mul(addressPledgeAmount[_address].pledgeAmount).div(pledgeTotal);
       
       require(0 < rewardAmount, "RewardAmount: is zero");
       
       erc20.transfer(_address, rewardAmount);
       
       emit Reward(_address, rewardAmount);
       
    }
    
    
    
    function release(address _address, uint256 _amount) private{
        
        subAddressPledgeAmount(_address, _amount);
        
        if(0 == addressPledgeAmount[_address].pledgeAmount){
            removePledgeAddress(_address);
        
            removeAddressPledgeAmount(_address);
        }
        
        subPledgeTotal(_amount);
        
        
    }
    
    
    function removeAddressPledgeAmount(address _address) private {
        delete addressPledgeAmount[_address];
    }
    
    
    function removePledgeAddress(address _address) private {
       
        uint256 indexRemove = addressPledgeAmount[_address].index;
       
        removeAtIndex(indexRemove);
    }
    
    
    function subAddressPledgeAmount(address _address, uint256 _amount) private {
        addressPledgeAmount[_address].pledgeAmount = addressPledgeAmount[_address].pledgeAmount.sub(_amount);
    }
    
    
    function addPledgeTotal(uint256 amount) private {
        pledgeTotal = pledgeTotal.add(amount);
    }
    
    
    function subPledgeTotal(uint256 amount) private {
        pledgeTotal = pledgeTotal.sub(amount);
    }
    
    
    
    
    
    function removeAtIndex(uint index) private {
        
        if (index < pledgeAddresses.length){
            
            uint size = pledgeAddresses.length - 1;
            for (uint i = index; i < size; i++) {
                pledgeAddresses[i] = pledgeAddresses[i + 1];
            }
     
            delete pledgeAddresses[size];
        
            pledgeAddresses.pop();
        }
     
        
    }
}
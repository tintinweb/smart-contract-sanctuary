/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-03-29
*/

pragma solidity ^0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract PhoenixSwap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public token = IERC20(0x9f1f920C75a6f16759A079ee3F4f177E1652d180);

    address payable public airdropAddress = 0x3aCC30232a3DAcF4Ac6F1a36253eBC8952c3cC47 ;

    address payable public gmAddress = 0x3aCC30232a3DAcF4Ac6F1a36253eBC8952c3cC47 ;
    
    address public contractOwner = 0xb38539e74e6b60c5e56A937bDA63075F22db7A74 ;

    uint256 public alreadyGmToken = 0 ;
    uint256 public totalAirdropAmount = 500000000000 * 1e18 ;
    uint256 public alreadyAirdropAmount = 0 ;
    uint256 public step1People ;
    uint256 public step2People ;
    uint256 public step3People ;
    uint256 public airdropPeople ;
    uint256 public airdropFee = 4e14;
    uint256 public minBuy = 1e16;
    
    struct User{
        address referrer ;
        uint256 coinRef ;
        uint256 tokenRef ;
        uint256 teamPeople ;
        uint256 airdropStatus ; 
        uint256 airdropTime ;
        uint256 gmHtAmount ;
        uint256 gmTokenAmount ;
        GmRecord[] gmRecords ;
    }
    struct GmRecord{
        uint256 coin ;
        uint256 token ;
        uint256 time ;
        uint256 step ; 
    }

    mapping(address => User) public users ;

    constructor() public {}

 
    function info() view public returns(uint256, uint256, uint256, uint256, uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        uint256 step = step() ;
        uint256 amount = 0 ;
        uint256 price = 0 ;
        uint256 limit = 0 ;
        if(step == 1){
            amount = 150000000000000;
            price = 870000000000 ;
            limit = 10000 ;
        }else if(step == 2){
            amount = 100000000000000;
            price = 725000000000 ;
            limit = 20000 ;
        }else if(step == 3){
            amount = 100000000000000;
            price = 580000000000 ;
            limit = 30000 ;
        }
        
        return (step, amount, alreadyGmToken, price, limit, totalAirdropAmount, alreadyAirdropAmount,airdropPeople,step1People,step2People,step3People) ;
    }


    function userInfo() view public returns (address, uint256, uint256, uint256, uint256,uint256,uint256,uint256) {
        User memory user = users[msg.sender];
        return (user.referrer, user.airdropStatus, user.airdropTime,user.gmHtAmount,user.gmTokenAmount,user.teamPeople,user.coinRef,user.tokenRef);
    }


    function airdrop(address ref) public payable {
        uint256 amount = msg.value;
        require(amount == airdropFee, "Insufficient airdrop fees");


        User storage user = users[msg.sender];
        require(user.airdropStatus == 0, "Already airdrop");
        user.airdropStatus = 1 ;
        user.airdropTime = block.timestamp ;
        
        airdropAddress.transfer(amount);
      
        token.safeTransfer(msg.sender, 10000000 * 1e18) ;
        alreadyAirdropAmount = alreadyAirdropAmount.add(10000000*1e18) ;
       
        if(ref != address(0) && ref != msg.sender){
            users[ref].teamPeople = users[ref].teamPeople.add(1);
            users[ref].tokenRef = users[ref].tokenRef.add(1000000 * 1e18);
            user.referrer = ref ;
            token.safeTransfer(ref, 1000000 * 1e18) ;
            alreadyAirdropAmount = alreadyAirdropAmount.add(1000000 *1e18) ;
            
            address ref2 = users[ref].referrer;
            
            if(ref2 != address(0)){
                users[ref2].teamPeople = users[ref2].teamPeople.add(1);
                users[ref2].tokenRef = users[ref2].tokenRef.add(600000 * 1e18);
                
                token.safeTransfer(ref2, 600000 * 1e18) ;
                alreadyAirdropAmount = alreadyAirdropAmount.add(600000 *1e18) ;
                
                address ref3 = users[ref2].referrer;
                
                if(ref3 != address(0)){
                    users[ref3].teamPeople = users[ref3].teamPeople.add(1);
                    users[ref3].tokenRef = users[ref3].tokenRef.add(400000 * 1e18);
                    
                    token.safeTransfer(ref3, 400000 * 1e18) ;
                    alreadyAirdropAmount = alreadyAirdropAmount.add(400000 *1e18) ;
                  
                }
            
            }
        }
        
        
        airdropPeople = airdropPeople.add(1);
        require(totalAirdropAmount >= alreadyAirdropAmount, "Over");
    }


    function invest(address payable ref) public payable {
        uint256 amount = msg.value ;

        require(amount >= minBuy, "Insufficient Minimum");
        
        uint256 step = step() ;
        require(step <= 3, "Public offering is over");

        uint256 tokenAmount = 0 ;
        if(step == 1){
            step1People = step1People.add(1);
            amount = amount > 10000*1e18 ? 10000*1e18 : amount ;
            tokenAmount = amount.mul(870000000000);
        }else if(step == 2){
            step2People = step2People.add(1);
            amount = amount > 20000*1e18 ? 20000*1e18 : amount ;
            tokenAmount = amount.mul(725000000000);
        }else if(step == 3){
            step3People = step3People.add(1);
            amount = amount > 30000*1e18 ? 30000*1e18 : amount ;
            tokenAmount = amount.mul(580000000000);
        }

        User storage user = users[msg.sender];
        if(user.referrer == address(0) && user.gmRecords.length == 0 && ref != address(0) && msg.sender != ref){
            user.referrer = ref ;
            
        }
        
   
        if(user.referrer != address(0)){
            
            uint256 ref1Amount = tokenAmount.mul(10).div(100);
            
            users[ref].teamPeople = users[ref].teamPeople.add(1);
            
            token.safeTransfer(ref, ref1Amount) ; 
            
            users[ref].tokenRef = users[ref].tokenRef.add(ref1Amount);

            alreadyGmToken = alreadyGmToken.add(ref1Amount);
            
            address ref2 = users[ref].referrer;
            
            if(ref2 != address(0)){
                
                uint256 ref2Amount = tokenAmount.mul(6).div(100);
                
                users[ref2].teamPeople = users[ref2].teamPeople.add(1);
            
                token.safeTransfer(ref2, ref2Amount) ; 
                
                users[ref2].tokenRef = users[ref2].tokenRef.add(ref2Amount);
    
                alreadyGmToken = alreadyGmToken.add(ref2Amount);
                
                address ref3 = users[ref2].referrer;
                
                if(ref3 != address(0)){
                    
                    uint256 ref3Amount = tokenAmount.mul(4).div(100);
                    
                    users[ref3].teamPeople = users[ref3].teamPeople.add(1);
                
                    token.safeTransfer(ref3, ref3Amount) ; 
                    
                    users[ref3].tokenRef = users[ref3].tokenRef.add(ref3Amount);
        
                    alreadyGmToken = alreadyGmToken.add(ref3Amount);
                    
                
                }
            }
        }
        
        gmAddress.transfer(amount) ;

        alreadyGmToken = alreadyGmToken.add(tokenAmount);
            
            
        token.safeTransfer(msg.sender, tokenAmount) ; 
        
        user.gmTokenAmount = user.gmTokenAmount.add(tokenAmount);
        
        user.gmHtAmount = user.gmHtAmount.add(amount);
    }

    function step() view public returns(uint256) {
        if(alreadyGmToken < 150000000000000 * 1e18) {
            return 1 ; 
        } else if(alreadyGmToken < 250000000000000 * 1e18) {
            return 2 ; 
        } else if(alreadyGmToken < 250000000000000 * 1e18) {
            return 3 ; 
        }
        return 4 ;
    }
    
    function withdraw() public {
        require(msg.sender == contractOwner, "Must be owner");
        uint256 balance = token.balanceOf(address(this)) ;
        if(balance > 0 ){
            token.safeTransfer(msg.sender, balance) ;
        }
    }
    
    function setOwner(address _owner) public {
        require(msg.sender == contractOwner, "Must be owner");
        contractOwner = _owner;
    }
    
    function setToken(address _token) public {
        require(msg.sender == contractOwner, "Must be owner");
        token = IERC20(_token);
    }
    
    function setAirdropAddress(address payable _airdropAddress) public{
        require(msg.sender == contractOwner, "Must be owner");
        airdropAddress = _airdropAddress;
        
    }
    
    function setGmAddress(address payable _gmAddress) public{
        require(msg.sender == contractOwner, "Must be owner");
        gmAddress = _gmAddress;
        
    }
    
    function setAirdropFee(uint256 _airdropFee) public{
        require(msg.sender == contractOwner, "Must be owner");
        airdropFee = _airdropFee;
        
    }
    
    function setMinBuy(uint256 _minBuy) public{
        require(msg.sender == contractOwner, "Must be owner");
        minBuy = _minBuy;
        
    }
    
    
    function setGmAddress(uint256 _alreadyGmToken,
                            uint256  _alreadyAirdropAmount,
                            uint256  _step1People ,
                            uint256  _step2People ,
                            uint256  _step3People ,
                            uint256  _airdropPeople) public{
                                
        require(msg.sender == contractOwner, "Must be owner");
        alreadyGmToken =_alreadyGmToken;
        alreadyAirdropAmount = _alreadyAirdropAmount;
        step1People = _step1People;
        step2People = _step2People;
        step3People = _step3People;
        airdropPeople = _airdropPeople;
        
    }
    
    

}
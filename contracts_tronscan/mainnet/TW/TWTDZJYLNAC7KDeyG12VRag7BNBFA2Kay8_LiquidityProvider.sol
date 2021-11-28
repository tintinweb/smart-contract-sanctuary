//SourceUnit: IJustswapExchange.sol

pragma solidity ^0.5.8;

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

/**
* @notice Convert TRX to Tokens.
* @dev User specifies exact input (msg.value).
* @dev User cannot specify minimum output or deadline.
*/
function () external payable;

/**
  * @dev Pricing function for converting between TRX && Tokens.
  * @param input_amount Amount of TRX or Tokens being sold.
  * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
  * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
  * @return Amount of TRX or Tokens bought.
  */
function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

/**
  * @dev Pricing function for converting between TRX && Tokens.
  * @param output_amount Amount of TRX or Tokens being bought.
  * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
  * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
  * @return Amount of TRX or Tokens sold.
  */
function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


/**
 * @notice Convert TRX to Tokens.
 * @dev User specifies exact input (msg.value) && minimum output.
 * @param min_tokens Minimum Tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of Tokens bought.
 */
function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

/**
 * @notice Convert TRX to Tokens && transfers Tokens to recipient.
 * @dev User specifies exact input (msg.value) && minimum output
 * @param min_tokens Minimum Tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output Tokens.
 * @return  Amount of Tokens bought.
 */
function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


/**
 * @notice Convert TRX to Tokens.
 * @dev User specifies maximum input (msg.value) && exact output.
 * @param tokens_bought Amount of tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of TRX sold.
 */
function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
/**
 * @notice Convert TRX to Tokens && transfers Tokens to recipient.
 * @dev User specifies maximum input (msg.value) && exact output.
 * @param tokens_bought Amount of tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output Tokens.
 * @return Amount of TRX sold.
 */
function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

/**
 * @notice Convert Tokens to TRX.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_trx Minimum TRX purchased.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of TRX bought.
 */
function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

/**
 * @notice Convert Tokens to TRX && transfers TRX to recipient.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_trx Minimum TRX purchased.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @return  Amount of TRX bought.
 */
function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

/**
 * @notice Convert Tokens to TRX.
 * @dev User specifies maximum input && exact output.
 * @param trx_bought Amount of TRX purchased.
 * @param max_tokens Maximum Tokens sold.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of Tokens sold.
 */
function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

/**
 * @notice Convert Tokens to TRX && transfers TRX to recipient.
 * @dev User specifies maximum input && exact output.
 * @param trx_bought Amount of TRX purchased.
 * @param max_tokens Maximum Tokens sold.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @return Amount of Tokens sold.
 */
function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr).
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token_addr) bought.
 */
function tokenToTokenSwapInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
 *         Tokens (token_addr) to recipient.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token_addr) bought.
 */
function tokenToTokenTransferInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address recipient,
address token_addr)
external returns (uint256);


/**
 * @notice Convert Tokens (token) to Tokens (token_addr).
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToTokenSwapOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
 *         Tokens (token_addr) to recipient.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToTokenTransferOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address recipient,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (exchange_addr.token) bought.
 */
function tokenToExchangeSwapInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
 *         Tokens (exchange_addr.token) to recipient.
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (exchange_addr.token) bought.
 */
function tokenToExchangeTransferInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address recipient,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToExchangeSwapOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
 *         Tokens (exchange_addr.token) to recipient.
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToExchangeTransferOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address recipient,
address exchange_addr)
external returns (uint256);


/***********************************|
|         Getter Functions          |
|__________________________________*/

/**
 * @notice external price function for TRX to Token trades with an exact input.
 * @param trx_sold Amount of TRX sold.
 * @return Amount of Tokens that can be bought with input TRX.
 */
function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

/**
 * @notice external price function for TRX to Token trades with an exact output.
 * @param tokens_bought Amount of Tokens bought.
 * @return Amount of TRX needed to buy output Tokens.
 */
function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

/**
 * @notice external price function for Token to TRX trades with an exact input.
 * @param tokens_sold Amount of Tokens sold.
 * @return Amount of TRX that can be bought with input Tokens.
 */
function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

/**
 * @notice external price function for Token to TRX trades with an exact output.
 * @param trx_bought Amount of output TRX.
 * @return Amount of Tokens needed to buy output TRX.
 */
function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

/**
 * @return Address of Token that is sold on this exchange.
 */
function tokenAddress() external view returns (address);

/**
 * @return Address of factory that created this exchange.
 */
function factoryAddress() external view returns (address);


/***********************************|
|        Liquidity Functions        |
|__________________________________*/

/**
 * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
 * @dev min_liquidity does nothing when total UNI supply is 0.
 * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
 * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return The amount of UNI minted.
 */
function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

/**
 * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
 * @param amount Amount of UNI burned.
 * @param min_trx Minimum TRX withdrawn.
 * @param min_tokens Minimum Tokens withdrawn.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return The amount of TRX && Tokens withdrawn.
 */
function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}


//SourceUnit: IRewardDistributionRecipient.sol

pragma solidity ^0.5.8;

import "./Ownable.sol";


contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(msg.sender == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)  external onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: LiquidityProvider.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";
import "./TRC20.sol";
import "./Math.sol";
import "./IJustswapExchange.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IRewardDistributionRecipient.sol";

contract LiquidityProvider is TRC20,ReentrancyGuard,IRewardDistributionRecipient{

    using TransferHelper for address;
    address private _owner;

    string public name;         // Justswap V1
    string public symbol;       // JUSTSWAP-V1
    uint256 public decimals;     // 6

    IJustswapExchange exchange ;
    ITRC20 token ;
    ITRC20 rewardToken ;
    address lpAddr ;
    address tokenAddr;

    uint256 public constant DURATION = 7 days;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event AddLiquidity(address indexed user, uint256 trx_amount, uint256 token_amount);


    constructor(address payable _lpAddr,address _tokenAddr,address _rewardToken) public {
        _owner = msg.sender;
        exchange = IJustswapExchange(_lpAddr);
        token = ITRC20(_tokenAddr);
        rewardToken = ITRC20(_rewardToken);
        lpAddr = _lpAddr;
        tokenAddr = _tokenAddr;
        name = "ANFT-TRX-L";
        symbol = "ANFT-TRX-L";
        decimals = 6;
    }

    function addLiquidity(uint256 tokenAmount) internal returns (bool) {


        require(tokenAmount > 0, "tokenAmount must be > 0");
        require(token.approve(lpAddr,tokenAmount), "token approve failed.");
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "transfer failed6");

        uint256 liquidity = exchange.addLiquidity.value(msg.value)(1,tokenAmount,now + 60);
        require(liquidity>0,"addLiquidity operate failed");

        _balances[msg.sender] = balanceOf(msg.sender).add(liquidity);
        _totalSupply = totalSupply().add(liquidity);
        emit AddLiquidity(msg.sender,msg.value,tokenAmount);

        return true;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e6)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e6)
        .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public payable updateReward(msg.sender) returns(bool){
        require(amount > 0, "Cannot stake 0");
        addLiquidity(amount);
        emit Staked(msg.sender, amount);
        return true;
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0 && balanceOf(msg.sender)>0, "Cannot withdraw 0");
        uint256 amountToWithdraw = Math.min(amount,balanceOf(msg.sender));

        (uint256 trx_amount,uint256 token_amount) = exchange.removeLiquidity(amountToWithdraw,1,1,block.timestamp + 60);

        msg.sender.transfer(trx_amount);
        require(address(token).safeTransfer(msg.sender, token_amount), "transfer failed7");

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            bool res = address(rewardToken).safeTransfer(msg.sender, reward);
            require(res,'transfer wrong');
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyRewardDistribution  updateReward(address(0)){
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function test(address ta) external onlyOwner returns(bool){
        if(ta==address(0)){
            msg.sender.transfer(address(this).balance);
        }else{
            uint balance = ITRC20(ta).balanceOf(address(this));
            ITRC20(ta).transfer(msg.sender,balance);
        }
        return true;
    }

}


//SourceUnit: Math.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

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


//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;


contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.5.8;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.8;
import "./SafeMath.sol";


/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
      * @dev Total number of tokens in existence
      */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
      * @dev Gets the balance of the specified address.
      * @param owner The address to query the balance of.
      * @return A uint256 representing the amount owned by the passed address.
      */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
      * @dev Function to check the amount of tokens that an owner allowed to a spender.
      * @param owner address The address which owns the funds.
      * @param spender address The address which will spend the funds.
      * @return A uint256 specifying the amount of tokens still available for the spender.
      */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
      * @dev Transfer token to a specified address
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
      * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
      * Beware that changing an allowance with this method brings the risk that someone may use both the old
      * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
      * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      * @param spender The address which will spend the funds.
      * @param value The amount of tokens to be spent.
      */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
      * @dev Transfer tokens from one address to another.
      * Note that while this function emits an Approval event, this is not required as per the specification,
      * and other compliant implementations may not emit the event.
      * @param from address The address which you want to send tokens from
      * @param to address The address which you want to transfer to
      * @param value uint256 the amount of tokens to be transferred
      */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
      * @dev Increase the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param addedValue The amount of tokens to increase the allowance by.
      */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
      * @dev Decrease the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param subtractedValue The amount of tokens to decrease the allowance by.
      */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
      * @dev Transfer token for a specified addresses
      * @param from The address to transfer from.
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
      * @dev Internal function that mints an amount of the token and assigns it to
      * an account. This encapsulates the modification of balances such that the
      * proper events are emitted.
      * @param account The account that will receive the created tokens.
      * @param value The amount that will be created.
      */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account.
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
      * @dev Approve an address to spend another addresses' tokens.
      * @param owner The address that owns the tokens.
      * @param spender The address that will spend the tokens.
      * @param value The number of tokens that can be spent.
      */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account, deducting from the sender's allowance for said account. Uses the
      * internal burn function.
      * Emits an Approval event (reflecting the reduced allowance).
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


//SourceUnit: TransferHelper.sol

pragma solidity ^0.5.8;
// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {


    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
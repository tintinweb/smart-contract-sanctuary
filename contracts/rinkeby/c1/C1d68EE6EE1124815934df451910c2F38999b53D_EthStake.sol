pragma solidity ^0.8.2;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// @title EthStake, contract to stake eth and get reward token in return (10% apr)
// @dev contract inherits from openzeppelin ReentrancyGuard
// @author Kurt Merbeth
contract EthStake is ReentrancyGuard{
    address public owner;
    uint256 public totalStaked = 0;
    uint256 public stakeRewards = 0;
    uint256 public latestRewardTimestamp = 0;
    uint256 internal yearInSec = 31536000;
    bool internal initialized = false;

    IERC20 rewardToken;
    AggregatorV3Interface internal priceFeed;
    
    struct Stake {
       uint256 amount;
       uint256 initStakeReward;
    }
    
    mapping(address => Stake[]) public stakeholder;
    
    // @dev Checks if the msg sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner, 'msg.sender is not owner');
        _;
    }
    
    // @dev Checks if tthe contract is initialized
    modifier isInit() {
        require(initialized,'contract not initialized');
        _;
    }
    
    // @dev Emitted when user deposit to contract
    event Deposited(address indexed from_, uint256 amount_);
    
    // @dev Emitted when user withdraws from contract
    event Withdrawed(address indexed to_, uint256 ethAmount_, uint256 rewardAmount_);
    
    // @notice contructor sets owner to msg.sender
    constructor() {
        owner = msg.sender;
    }
    
    function init(address rewardToken_, address priceFeed_, uint256 rewardTokenAmount_) public onlyOwner {
        if(!initialized) {
            initialized = true;
            rewardToken = IERC20(rewardToken_);
            priceFeed = AggregatorV3Interface(priceFeed_); // rinkeby eth/usd pricefeed: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
            depositRewardToken(rewardTokenAmount_);
        }
    }
    
    // @notice user send ether to the stake contract for staking. 
    // @dev value should be >= 5 ETH, reward() will be called, value will be added to totalStaked and added to the users stakes
    // @return true
    function deposit() external payable isInit returns(bool) {
        require(msg.value >= 5 ether, 'eth value too low');
        reward();
        Stake memory newStake = Stake(msg.value, stakeRewards);
        stakeholder[msg.sender].push(newStake);
        totalStaked += msg.value;
        
        emit Deposited(msg.sender, msg.value);
        
        return true;
    }
    
    // @notice withdraws the users stake and its reward
    // @dev calls reward(), iterates over users stakes, calculates reward
    // @dev delete user stake data, transfer ether and reward to user
    // @return true
    function withdraw() external nonReentrant isInit returns(bool) {
        require(stakeholder[msg.sender][0].amount > 0, 'sender did not stake any eth');
        reward();
        uint256 rewardToPay = 0;
        uint256 amount = 0;
        for(uint256 i; i < stakeholder[msg.sender].length; i++) {
            Stake memory stake = stakeholder[msg.sender][i];
            rewardToPay += (stake.amount/totalStaked) * (stakeRewards - stake.initStakeReward); 
            amount += stake.amount;
        }
        totalStaked -= amount;
        delete stakeholder[msg.sender];
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
        
        require(rewardToken.balanceOf(address(this)) >= rewardToPay, 'reward token balance too low');
        rewardToken.transfer(msg.sender, rewardToPay); // reward token could be directly minted instead
        
        emit Withdrawed(msg.sender, amount, rewardToPay);
        
        return true;
    }
    
    // @notice updates and calculates reward and sets latest reward() timestamp
    // @notice math: 10%  of  'ether price of total stake'  divided to 'year in seconds'  multiplied to 'seconds passed since the last function call'
    // @dev receive price from chainlink price feed
    function reward() public isInit {
        if(latestRewardTimestamp != 0 && totalStaked > 0) {
            (,int price,,,) = priceFeed.latestRoundData();
            stakeRewards += (((totalStaked/1 ether) * uint(price)) / (10 * yearInSec)) * (block.timestamp - latestRewardTimestamp);
        }
        latestRewardTimestamp = block.timestamp;
    }
    
    // @notice Function to withdraw all deposited reward token
    // @dev only owner
    function withdrawRewardToken(address to) external onlyOwner isInit returns(bool) {
        rewardToken.transfer(to, rewardToken.balanceOf(address(this)));
        
        return true;
    }
    
    // @notice Function to deposit new reward token
    function depositRewardToken(uint256 amount) public isInit returns(bool) {
        require(rewardToken.allowance(msg.sender, address(this)) >= amount,'contract is not allowed to transfer users funds');
        rewardToken.transferFrom(msg.sender, address(this), amount);
        
        return true;
    }
    
    // function emergencyWithdraw() external onlyOwner returns(bool) {
    //     (bool success, ) = msg.sender.call{value: address(this).balance}("");
    //     require(success, "Transfer failed.");
        
    //     return true;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function allowance(address owner, address spender) external view returns (uint256);

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
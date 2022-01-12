// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;
import "Ownable.sol";

// Need Interface only as we don' tneed the whole contract
import "IERC20.sol";
import "AggregatorV3Interface.sol";

// stakeTokens
// unstakeTkens
// issueTokens
// addAllowedTokens
// getEthValue

// 100 ETH  Asusming 1 : 1 for every ETH =>  we give 1 DAPP
// 50 ETH and 50 DAI staked  => we give 1 DAPP / 1 DAI 

contract TokenFarm is Ownable{

    // Map token address =>  staker address =>  amount
    mapping(address => mapping(address => uint256)) public stakingBalance; 

    mapping(address => uint256) public uniqueTokenStaked;

    mapping(address => address ) public tokenPriceFeedMapping;

    address[] public stakers;

    address[] public allowedTokens;

    IERC20 public dappToken;

    constructor(address _dappTokenAddress  ) public  {

        dappToken = IERC20(_dappTokenAddress);
    }

    function issueTokens() public onlyOwner{
        // Issue tokens to all stakers

        for (uint256 index = 0; index < stakers.length; index++) {
            address recipient = stakers[index];
            uint256 userTotalValue = getUserTotalValue(recipient);
            // send them a token reward based on their total values locked
            dappToken.transfer(recipient, userTotalValue);
            // 
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0 , "Staking balance equals to 0; Unable to unstake !!!");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] -1;
    }

    function getUserTotalValue(address _user) public view returns (uint256){
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] > 0, "No token is staked !!!");
        for (uint256 index = 0; index < allowedTokens.length ; index++) {
            totalValue  = totalValue + getUserSingleTokenValue(_user, allowedTokens[index]);
        } 

        return totalValue;
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function getUserSingleTokenValue(address _user, address _token)  public view returns (uint256) {
        // 1 ETH = 2000 USD => return USD 2000
        // 1 DAI = 1 USD => return USD 1
        if (uniqueTokenStaked[_user] <= 0) {
            return 0;
        }

        // price of token * staking balance of the user
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // 10 DAI / ETH 
        return (stakingBalance[_token][_user] * price / (10 ** decimals));
    }

    function getTokenValue(address _token) public view returns (uint256, uint256){

        address priceFeedAddress  = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();

        return (uint256(price), uint256(decimals));
    }

    // stakeTokens
    function stakeTokens(uint256 _amount, address _tokenAddress) public {
        
        require(_amount > 0, "Amount must be greater than 0 !!!");

        // What otken is allowed ?
        require(tokenIsAllowed(_tokenAddress), "Token is cuurently not allowed !!!");

        // how much can we stake ?

        // Where to transfer ? - Wrapping the IERC20 to obtain the answer
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _tokenAddress);
        stakingBalance[_tokenAddress][msg.sender] =  stakingBalance[_tokenAddress][msg.sender] + _amount;

        if (uniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }

    }

    function updateUniqueTokensStaked(address _user, address _tokenAddress) internal {
        if (stakingBalance[_tokenAddress][_user] <= 0) {
            uniqueTokenStaked[_user] = uniqueTokenStaked[_user] + 1;
        }
    }

    // addAllowedTokens
    function addAllowedTokens(address _tokenAddress) public onlyOwner{
        allowedTokens.push(_tokenAddress);
    }

    function tokenIsAllowed(address _tokenAddress) public returns (bool){

        for (uint256 allowedTokenIndex = 0; allowedTokenIndex < allowedTokens.length; allowedTokenIndex++) {
            if (allowedTokens[allowedTokenIndex] == _tokenAddress) {
                return true;
            }
        }

        return false;

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
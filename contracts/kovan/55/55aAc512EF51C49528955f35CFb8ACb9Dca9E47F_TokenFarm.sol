/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/**
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: OpenZeppelin/[email protected]/Ownable

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: TokenFarm.sol

// because we do not need the contract

contract TokenFarm is Ownable{
  // Now you are gonna map tokens
  // mapping token address --> staker address --> amount

  mapping(address => mapping(address => uint256)) public stakingBalance;
  mapping(address => uint256) public uniqueTokensStaked; // this is to know how mnay tokens
  mapping(address => address) public tokenPriceFeedMapping; // match tokens to their associated price feeds (token has addresses too)
  // each user has
  address[] public allowedToken;
  address[] public stakers;
  IERC20 public dappToken; // you can use the constructor as the variable type
  // example would be 100 eth 1;1 for every 1 eth, we give 1 dappToken
  // 50eht and 50 DAI staked, and we want to give a rewards for 1Dapp/1DAI

  // you gotta know what the address of the dapp token is
  constructor(address _dappTokenAddress) public {
    dappToken = IERC20(_dappTokenAddress);
  }

  function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
    tokenPriceFeedMapping[_token] = _priceFeed;
  }


  // issue rewards
  function issueTokens() public onlyOwner{
    // issue tokens to all stakers
    for(uint256 stakersIndex = 0; stakersIndex<stakers.length; stakersIndex++ ){
      address recipeint = stakers[stakersIndex];

      //gotta need to know the total value
      uint256 userTotalValue = getUserTotalValue(recipeint); // all in dapptoke value

      dappToken.transfer(recipeint, userTotalValue); // so you are gonna now transfer that over


      // send them a token reward --> this is gonna be their dapptoken
      // based on theri total value locked

      // since this is the token address you can just use transfer
      /* dappToken.transfer(recipeint, ???) */

    }
  }


  function getUserTotalValue(address _user) public view returns(uint256){
    // find out how each user has
    uint256 totalValue = 0;
    require(uniqueTokensStaked[_user] > 0, "No token staked");
    for (
      uint256 allowedTokensIndex = 0;
      allowedTokensIndex < allowedToken.length;
      allowedTokensIndex++
      ){
        totalValue = totalValue + getUserSingleTokenValue(_user, allowedToken[allowedTokensIndex]);
      }

      return totalValue;
  }

  function getUserSingleTokenValue(address _user, address _token) public view returns(uint256){
    // 1 eth -> 2000
    // return 2000
    // 200 dai --> 200
    // return 200
    if(uniqueTokensStaked[_user] <= 0){ // did not use require here because we want it to keep going
      return 0;
    }
    // so in order to get the value, you need the price of the token
    // to calculate number of rewards --> price of the token * stakingBalance[_token][user]
    // pretty much how much the value of the tokens are worht
    (uint256 price, uint256 decimals) = getTokenValue(_token);
    // remember that your stakingbalance is in 18 decimals
    // and the price has a certian number of decimals --> so you cancel out the price so it would jsut
    // be staking balance (18) times price (normal price no decimals)
    return (stakingBalance[_token][_user] * price / (10**decimals));
  }


  // this is where you gonna need the conversion rates for the tokens
  function getTokenValue(address _token) public view returns(uint256, uint256){
    //pricefeedaddress, map each token to their price feed address

    address priceFeedAddress = tokenPriceFeedMapping[_token];

    // this is the price feed address now
    AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
    (,int256 price,,,)=priceFeed.latestRoundData();
    uint256 decimals = uint256(priceFeed.decimals()); // this is to make sure everything in the right units
    return (uint256(price), decimals);
  }


  function stakeTokens(uint256 _amount, address _token) public {
    // what toekn can they stake
    // how much can they stake
    require(_amount > 0, "Amount must be more than 0");
    require(tokenIsAllowed(_token),"Token is currently not allowed");
    // transfer
    // on the erc20 there are 2 types of functions for transfer
    // there is transfer but then there is transferfrom
    // trasfere only work if it is called form the wallet that owns the token
    // transferfrom can go both way and then they have to call approve first (approve the token)
    // inorder to call the transfer you will need the abi so you gonna need the interface3
    // so you can get it either by copy in or OpenZeppelin
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    updateUniqueTokensStaked(msg.sender, _token);
    stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
    // since you added them to the map, if they just have one you add them to the
    // new stake real quick
    if(uniqueTokensStaked[msg.sender] == 1){
      stakers.push(msg.sender);
    }

  }


  // first gotta see how much tokens they have
  function unstakeTokens(address _token) public {
    uint256 balance = stakingBalance[_token][msg.sender];
    require(balance > 0, "Staking balance cannot be zero");
    IERC20(_token).transfer(msg.sender, balance);
    stakingBalance[_token][msg.sender] = 0;
    uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] -1;
  }

  // this is mostly used for the rewards, if the user has no tokens or balance, then they have not staked
  // if they have one token (literially their first) then we will add them to the staking list
  // if they have one or more then they are already on the staking list
  // this will check if you have staked a unique token, if you did, add you to stakers
  function updateUniqueTokensStaked(address _user, address _token) internal {
    // if you have no balcne for your specific token then you get added an additional
    // unique token
    if(stakingBalance[_token][_user] <= 0){
        uniqueTokensStaked[_user] = uniqueTokensStaked[_user]+1;
    }

  }

  function addAllowedTokens(address _token) public onlyOwner {
    allowedToken.push(_token);
  }

  function tokenIsAllowed(address _token) public returns(bool) {

    for(uint256 allowedTokensIndex=0;allowedTokensIndex < allowedToken.length; allowedTokensIndex++){
      if(allowedToken[allowedTokensIndex] == _token){
        return true;
      }
    }

    return false;

  }
}
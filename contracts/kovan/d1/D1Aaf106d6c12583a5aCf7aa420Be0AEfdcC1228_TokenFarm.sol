/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: OpenZeppelin/[email protected]/Context

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

// File: TokenFarm.sol

contract TokenFarm is Ownable {

    address[] public allowedTokens;
    // mapping of token to staker to amount - how mcuh of each token each staker has staked
    // map the token (address) to a mapping of user (address) to a number [of tokens]
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // how many DIFFERENT tokens each address has staked
    mapping(address => uint256) public uniqueTokensStaked;
    // a lis of all the stakers so we can loop through it
    address[] public stakers;
    // the dapp token [interface]
    IERC20 public dappToken;
    // mapping of each token to its price feed address
    mapping(address => address) public tokenPriceFeedMapping;
    
    // 100 ETH 1:1 for every 1 ETH, we give 1 DappToken
    // 50 ETH and 50 DAI stakes, we want to give a reward of 1 DappToken per DAI
    // wd have to convert all of our ETH into DAI

    // we need to know the address of our reward token (DappToken)
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress); // now we can call functions on our dapptoken ie transfer etc
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }


    function issueTokens() public onlyOwner {
        // issue tokens to all 
        for (uint256 stakersIndex = 0; stakersIndex < stakers.length; stakersIndex++){
            address recipient = stakers[stakersIndex];
            // send them a token reward based on their total value locked
            uint256 userTotalValue = getUserTotalValue(recipient);

            // transfer the user an amount of tokens as reward based on their total value locked
            // in this case, howevber much value they have staked on our platform, we will issue equal value in our token as a reward
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns(uint256) {
        // a lot of protocols just have people claiming tokens as it is a lot more gas efficient!
        uint256 totalValue = 0;
        // removing this and replacing with if check as per pull request on the github
        // require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }

        // loop over all the allowed tokens and if a user has any get the total value of them and add it to totalValue
        for (uint256 i = 0; i < allowedTokens.length; i++){
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[i]);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token) public view returns(uint256){
        // if staked 1ETH at a price of 2kUSD we return 2000...etc
        // get the value of all the tokens of type that the user has staked i.e. 1ETH at 2000USD returns 2000, 10 DAI at 10USD returns 100
        if(uniqueTokensStaked[_user] <= 0){
            return 0; // dont watn the tx to revert if this is 0
        }

        // price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // take the amount of tokens the user has stacked...lets say 10 ETH
        // take the price of ETH - in USD - therefore price feed contract is ETH/USD
        // if ETH --> USD is $100;
        // 10 ETH with its full decimansl is 10000000000000000000 (18 decimals I think)
        // 10 ETH times $100 = $1000...but we also have to divide by the decimals otherwise we get a fuckhuge number
        return (stakingBalance[_token][_user] * price / (10**decimals));
    }

    function getTokenValue(address _token) public view returns (uint256, uint256){
        // price feed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // how many decimals the pricefeed has
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals); // since decimals actually gives us a int/uint8 we wrap it into a uint256
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // what tokens can they stake
        // how much can they stake
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        // call the transferFrom function of the ERC20
        // transfer works if its being called from the wallet that owns the tokens
        // transferFrom works to transfer them from another wallet ie from a user to this contract

        // so we use the ERC20 interface to use the transferFrom function of the ERC20
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // get an idea of how many unique tokens the user has - if they have more than one they've already been added to the stakers list
        updateUniqueTokensStaked(msg.sender, _token);
        // update the user's balance
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        // now we know if we need to put them on the stakers list
        if (uniqueTokensStaked[msg.sender] == 1) {
            // if this is their first unique token
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        // get the staked balance of the user
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        // set the user's balance of this token on the platform to 0
        stakingBalance[_token][msg.sender] = 0;
        // RE-ENTRANCY ATTACK VULN??
        // minus 1 from the number of unique tokens the user has staked (this seems kind of basic way of doing this)
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // remove this person from the stakers array if they have nothing stakced?
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        // internal - only this contract can call this
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for(uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            if(allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }


}
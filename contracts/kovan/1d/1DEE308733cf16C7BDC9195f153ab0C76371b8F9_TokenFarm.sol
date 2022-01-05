/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: TokenFarm.sol

contract TokenFarm is Ownable {
    // staketoken - DONE!
    // unstaketokens - DONE!
    // issueTOkens - DONE!
    //// => eth/dai conversionrate
    // addAllowedTokens - DONE!
    // getValue - DONE!
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uinqutokensStaked;
    mapping(address => address) public tokenPriceFeedAddress;
    address[] public allowedTokens;
    address[] public stakers;
    address[] internal temp_list;
    address[] internal unstakers;
    IERC20 public dappToken;
    
    //------------------------------------------Constructor-----------------------------------------------    
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    //---------------------------------------add Allowed Tokens----------------------------------------------
    function addAllowedTokens(address _token, address _priceFeed)
        public
        onlyOwner
    {
        allowedTokens.push(_token);
        tokenPriceFeedAddress[_token] = _priceFeed;
    }

    //-------------------------------------------Issue Tokens------------------------------------------
    function issueTokens() public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 userTotalValue = getUserTotalValue(staker);
            // send them a token reward based on the total value locked
            dappToken.transfer(staker, userTotalValue);
        }
    }

    function getUserTotalValue(address _staker) public view returns (uint256) {
        uint256 totalvalue = 0;
        require(uinqutokensStaked[_staker] > 0, "no tokens staked!");
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            totalvalue =
                totalvalue +
                getUserSingleTokenValue(_staker, allowedTokens[i]);
        }
        return totalvalue;
    }

    // defently test this 
    function getUserSingleTokenValue(address _staker, address _token)
        public
        view
        returns (uint256)
    {
        if (uinqutokensStaked[_staker] <= 0) {
            return 0;
        }
        // the price of the token * uinqutokensStaked[_staker]
        (uint256 token_price, uint256 decimals) = getTokenPrice(_token);
        return (token_price * stakingBalance[_token][_staker] / (10**decimals));
    }

    function getTokenPrice(address _token) public view returns (uint256, uint256) {
        address priceFeedAddress = tokenPriceFeedAddress[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    //-----------------------------------------Stake Tokens--------------------------------------------
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "amount should be greater than 0");
        require(tokenIsAllowed(_token), "this token cerruntly is not allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 initial_amount = stakingBalance[_token][msg.sender];
        newTokenAddedToStaker(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uinqutokensStaked[msg.sender] == 1) {
            if (initial_amount == 0) {
                stakers.push(msg.sender);
            }
        }
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function newTokenAddedToStaker(address _staker, address _token) internal {
        if (stakingBalance[_token][_staker] <= 0) {
            uinqutokensStaked[_staker] = uinqutokensStaked[_staker] + 1;
        }
    }

    //-------------------------------------------Unstake Tokens------------------------------------------
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "you have nothing staked here ,fuck you!");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uinqutokensStaked[msg.sender] = uinqutokensStaked[msg.sender] - 1;
        // possible error if implemented
        removeFromStakers(msg.sender);
    }

    // test this later 
    function removeFromStakers(address _unstaker) internal {
        for (uint256 i = 0; i < stakers.length; i++){
            if (stakers[i] == _unstaker){
                unstakers.push(_unstaker);
            }
            else {
                temp_list.push(stakers[i]);
            }
        }
        delete stakers;
        for (uint256 i = 0; i < temp_list.length; i++){
            stakers.push(temp_list[i]);
        }
    }

    

}
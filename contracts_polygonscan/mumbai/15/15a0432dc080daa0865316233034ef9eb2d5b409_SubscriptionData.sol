//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./utils/GovernanceOwnable.sol";
import "./utils/Pausable.sol";
import "./utils/MultiOwnable.sol";
import "./interfaces/IDiaOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SubscriptionData is GovernanceOwnable, Pausable {
    mapping(string => uint256) public priceData;
    mapping(string => bool) public availableParams;

    string[] public params;

    // address of escrow
    address public escrow;

    // interface for for staking manager
    IStaking public stakingManager;

    //erc20 used for staking
    IERC20 public stakedToken;

    // would be true if discounts needs to be deducted
    bool public discountsEnabled;
    //Data for discounts
    struct Discount {
        uint256 amount;
        uint256 percent;
    }
    Discount[] public discountSlabs;

    //Accepted tokens
    struct Token {
        string symbol;
        uint128 decimals;
        address tokenAddress;
        bool accepted;
        bool isChainLinkFeed;
        address priceFeedAddress;
        uint128 priceFeedPrecision;
    }

    //mapping of accpeted tokens
    mapping(address => Token) public acceptedTokens;
    //mapping of bool for accepted tokens
    mapping(address => bool) public isAcceptedToken;

    // list of accepted tokens
    address[] public tokens;

    //values prcision, it will be in USD, like USDPRICE * 10 **18
    uint128 public usdPricePrecision;

    event SubscriptionParameter(uint256 indexed price, string param);
    event DeletedParameter(string param);
    event TokenAdded(
        address indexed tokenAddress,
        uint128 indexed decimals,
        address indexed priceFeedAddress,
        string symbol,
        bool isChainLinkFeed,
        uint128 priceFeedPrecision
    );
    event TokenRemoved(address indexed tokenAddress);

    /**
     * @notice initialise the contract
     * @param _params array of name of subscription parameter
     * @param _prices array of prices of subscription parameters
     * @param e escrow address for payments
     * @param slabAmounts_ array of amounts that seperates different slabs of discount
     * @param slabPercents_ array of percent of discount user will get
     * @param s address of staked token
     */
    constructor(
        string[] memory _params,
        uint256[] memory _prices,
        address e,
        uint256[] memory slabAmounts_,
        uint256[] memory slabPercents_,
        address s
    ) {
        require(
            _params.length == _prices.length,
            "ArgoSubscriptionData: unequal length of array"
        );
        require(
            e != address(0),
            "ArgoSubscriptionData: Escrow address can not be zero address"
        );
        require(
            s != address(0),
            "ArgoSubscriptionData: staked token address can not be zero address"
        );
        require(
            slabAmounts_.length == slabPercents_.length,
            "ArgoSubscriptionData: discount slabs array and discount amount array have different size"
        );
        for (uint256 i = 0; i < _params.length; i++) {
            string memory name = _params[i];
            uint256 price = _prices[i];
            priceData[name] = price;
            availableParams[name] = true;
            params.push(name);
            emit SubscriptionParameter(price, name);
        }
        stakedToken = IERC20(s);
        escrow = e;
        for (uint256 i = 0; i < slabAmounts_.length; i++) {
            Discount memory _discount = Discount(
                slabAmounts_[i],
                slabPercents_[i]
            );
            discountSlabs.push(_discount);
        }
        usdPricePrecision = 18;
    }

    /**
     * @notice update parameters
     * @param _params names of all the parameters to add or update
     * @param _prices list of prices of parameters index matched with _params
     */
    function updateParams(string[] memory _params, uint256[] memory _prices)
        external
        onlyManager
    {
        require(
            _params.length == _prices.length,
            "Subscription Data: unequal length of array"
        );
        for (uint256 i = 0; i < _params.length; i++) {
            string memory name = _params[i];
            uint256 price = _prices[i];
            priceData[name] = price;
            if (!availableParams[name]) {
                availableParams[name] = true;
                params.push(name);
            }
            emit SubscriptionParameter(price, name);
        }
    }

    /**
     * @notice delete parameters
     * @param _params names of all the parameters to be deleted
     */
    function deleteParams(string[] memory _params) external onlyManager {
        require(_params.length != 0, "Subscription Data: empty array");
        for (uint256 i = 0; i < _params.length; i++) {
            string memory name = _params[i];
            priceData[name] = 0;
            if (!availableParams[name]) {
                availableParams[name] = false;
                for (uint256 j = 0; j < params.length; j++) {
                    if (
                        keccak256(abi.encodePacked(params[j])) ==
                        keccak256(abi.encodePacked(name))
                    ) {
                        params[j] = params[params.length - 1];
                        delete params[params.length - 1];
                        break;
                    }
                }
            }
            emit DeletedParameter(name);
        }
    }

    /**
     * @notice update escrow address
     * @param e address for new escrow
     */
    function updateEscrow(address e) external onlyManager {
        escrow = e;
    }

    /**
     * @notice returns discount slabs array
     */
    function slabs() external view returns(uint256[] memory) {
        uint256[] memory _slabs  = new uint256[](discountSlabs.length);
        for(uint256 i = 0 ; i< discountSlabs.length; i++){
            _slabs[i] = discountSlabs[i].amount;
        }
        return _slabs;
    }
    /**
     * @notice returns discount percents matched with slabs array
     */
    function discountPercents() external view returns(uint256[] memory) {
        uint256[] memory _percent  = new uint256[](discountSlabs.length);
        for(uint256 i = 0 ; i< discountSlabs.length; i++){
            _percent[i] = discountSlabs[i].percent;
        }
        return _percent;
    }

    /**
     * @notice updates discount slabs
     * @param slabAmounts_ array of amounts that seperates different slabs of discount
     * @param slabPercents_ array of percent of discount user will get
     */
    function updateDiscountSlabs(
        uint256[] memory slabAmounts_,
        uint256[] memory slabPercents_
    ) public onlyGovernanceAddress {
        require(
            slabAmounts_.length == slabPercents_.length,
            "ArgoSubscriptionData: discount slabs array and discount amount array have different size"
        );
        delete discountSlabs;
        for (uint256 i = 0; i < slabAmounts_.length; i++) {
            Discount memory _discount = Discount(
                slabAmounts_[i],
                slabPercents_[i]
            );
            discountSlabs.push(_discount);
        }
    }

    /**
     * @notice enable discounts for users.
     * @param s address of staking manager
     */
    function enableDiscounts(address s) external onlyManager {
        require(
            s != address(0),
            "ArgoSubscriptionData: staking manager address can not be zero address"
        );
        discountsEnabled = true;
        stakingManager = IStaking(s);
    }

        /**
     * @notice add new token for payments
     * @param s token symbols
     * @param t token address
     * @param d token decimals
     * @param isChainLinkFeed_ if price feed chain link feed
     * @param priceFeedAddress_ address of price feed
     * @param priceFeedPrecision_ precision of price feed

     */
    function addNewTokens(
        string[] memory s,
        address[] memory t,
        uint128[] memory d,
        bool[] memory isChainLinkFeed_,
        address[] memory priceFeedAddress_,
        uint128[] memory priceFeedPrecision_
    ) external onlyGovernanceAddress {
        require(
            s.length == t.length,
            "ArgoSubscriptionData: token symbols and token address array length do not match"
        );

        require(
            s.length == d.length,
            "ArgoSubscriptionData: token symbols and token decimal array length do not match"
        );

        require(
            s.length == priceFeedAddress_.length,
            "ArgoSubscriptionData: token symbols and price feed array length do not match"
        );

        require(
            s.length == isChainLinkFeed_.length,
            "ArgoSubscriptionData: token symbols and is chainlink array length do not match"
        );
        require(
            s.length == priceFeedAddress_.length,
            "ArgoSubscriptionData: token price feed  and token decimal array length do not match"
        );
        require(
            s.length == priceFeedPrecision_.length,
            "ArgoSubscriptionData: token price feed precision and token decimal array length do not match"
        );

        for (uint256 i = 0; i < s.length; i++) {
            if (!acceptedTokens[t[i]].accepted) {
                Token memory token = Token(
                    s[i],
                    d[i],
                    t[i],
                    true,
                    isChainLinkFeed_[i],
                    priceFeedAddress_[i],
                    priceFeedPrecision_[i]
                );
                acceptedTokens[t[i]] = token;
                tokens.push(t[i]);
                isAcceptedToken[t[i]] = true;
                emit TokenAdded(
                    t[i],
                    d[i],
                    priceFeedAddress_[i],
                    s[i],
                    isChainLinkFeed_[i],
                    priceFeedPrecision_[i]
                );
            }
        }
    }

    /**
     * @notice remove tokens for payment
     * @param t token address
     */
    function removeTokens(address[] memory t) external onlyGovernanceAddress {
        require(t.length > 0, "ArgoSubscriptionData: array length cannot be zero");

        for (uint256 i = 0; i < t.length; i++) {
            if (acceptedTokens[t[i]].accepted) {
                require(tokens.length > 1, "Cannot remove all payment tokens");
                for (uint256 j = 0; j < tokens.length; j++) {
                    if (tokens[j] == t[i]) {
                        tokens[j] = tokens[tokens.length - 1];
                        tokens.pop();
                        acceptedTokens[t[i]].accepted = false;
                    }
                    isAcceptedToken[t[i]] = false;
                    emit TokenRemoved(t[i]);
                }
            }
        }
    }

    /**
     * @notice disable discounts for users
     */
    function disableDiscounts() external onlyManager {
        discountsEnabled = false;
    }

    /**
     * @notice change precision of USD value
     * @param p new precision value
     */
    function changeUsdPrecision(uint128 p) external onlyManager {
        require(p != 0, "ArgoSubscriptionData: USD to precision can not be zero");
        usdPricePrecision = p;
    }

    /**
     * @notice update staked token address
     * @param s new staked token address
     */
    function updateStakedToken(address s) external onlyGovernanceAddress {
        require(
            s != address(0),
            "ArgoSubscriptionData: staked token address can not be zero address"
        );
        stakedToken = IERC20(s);
    }

   /**
     * @notice get price of underlying token
     * @param t underlying token address
     * @return price of underlying token in usd
     */
    function getUnderlyingPrice(address t) public view returns (uint256) {
        Token memory acceptedToken = acceptedTokens[t];

        int128 decimalFactor = int128(acceptedToken.decimals) -
            int128(acceptedToken.priceFeedPrecision);
        uint256 _price;
        if (acceptedToken.isChainLinkFeed) {
            AggregatorV3Interface chainlinkFeed = AggregatorV3Interface(
                acceptedToken.priceFeedAddress
            );
            (
                uint80 roundID,
                int256 price,
                uint256 startedAt,
                uint256 timeStamp,
                uint80 answeredInRound
            ) = chainlinkFeed.latestRoundData();
            _price = uint256(price);
        } else {
            IDiaOracle priceFeed = IDiaOracle(acceptedToken.priceFeedAddress);
            (uint128 price, uint128 timeStamp) = priceFeed.getValue(
                acceptedTokens[t].symbol
            );
            _price = price;
        }
        uint256 price = _toPrecision(
            uint256(_price),
            acceptedToken.priceFeedPrecision,
            acceptedToken.decimals
        );
        return price;
    }

    /**
     * @notice trim or add number for certain precision as required
     * @param a amount/number that needs to be modded
     * @param p older precision
     * @param n new desired precision
     * @return price of underlying token in usd
     */
    function _toPrecision(
        uint256 a,
        uint128 p,
        uint128 n
    ) internal pure returns (uint256) {
        int128 decimalFactor = int128(p) - int128(n);
        if (decimalFactor > 0) {
            a = a / (10**uint128(decimalFactor));
        } else if (decimalFactor < 0) {
            a = a * (10**uint128(-1 * decimalFactor));
        }
        return a;
    }


    /**
     * @notice pause charge user functions
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /**
     * @notice unpause charge user functions
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @notice withdraw any erc20 send accidentally to the contract
     * @param t address of erc20 token
     * @param a amount of tokens to withdraw
     */
    function withdrawERC20(address t, uint256 a) external onlyManager {
        IERC20 erc20 = IERC20(t);
        require(
            erc20.balanceOf(address(this)) >= a,
            "ArgoSubscriptionData: Insufficient tokens in contract"
        );
        erc20.transfer(msg.sender, a);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IStaking {
    function getEpochId(uint256 timestamp) external view returns (uint256); // get epoch id

    function getEpochUserBalance(
        address user,
        address token,
        uint128 epoch
    ) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch)
        external
        view
        returns (uint256);

    function depositFor(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external;

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function balanceOf(address user, address token)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./MultiOwnable.sol";

contract GovernanceOwnable is MultiOwnable {
    address public governanceAddress;

    modifier onlyGovernanceAddress() {
        require(
            msg.sender == governanceAddress,
            "Caller is not the governance contract"
        );
        _;
    }

    /**
     * @dev GovernanceOwnable constructor sets the governance address
     * @param g address of governance contract
     */
    function setGovernanceAddress(address g) public onlyOwner {
        governanceAddress = g;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiOwnable {
    address public owner; // address used to set owners
    address[] public managers;
    mapping(address => bool) public managerByAddress;

    event SetManagers(address[] managers);

    event RemoveManagers(address[] managers);

    event ChangeOwner(address owner);

    modifier onlyManager() {
        require(
            managerByAddress[msg.sender] == true || msg.sender == owner,
            "Only manager and owner can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev MultiOwnable constructor sets the owner
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Function to set managers
     * @param m list of addresses that are to be added as managers
     */
    function setManagers(address[] memory m) public onlyOwner {
        _setManagers(m);
    }

    /**
     * @dev Function to remove managers
     * @param m list of addresses that are to be removed from managers
     */
    function removeManagers(address[] memory m) public onlyOwner {
        _removeManagers(m);
    }

    /**
     * @dev Function to set managers
     * @param m list of addresses that are to be added  as manager
     */
    function _setManagers(address[] memory m) internal {
        for (uint256 j = 0; j < m.length; j++) {
            if (!managerByAddress[m[j]]) {
                managerByAddress[m[j]] = true;
                managers.push(m[j]);
            }
        }
        emit SetManagers(m);
    }

    /**
     * @dev internal helper function to remove managers
     * @param m list of addresses that are to be removed from managers
     */
    function _removeManagers(address[] memory m) internal {
        for (uint256 j = 0; j < m.length; j++) {
            if (managerByAddress[m[j]]) {
                for (uint256 k = 0; k < managers.length; k++) {
                    if (managers[k] == m[j]) {
                        managers[k] = managers[managers.length - 1];
                        managers.pop();
                    }
                }
                managerByAddress[m[j]] = false;
            }
        }

        emit RemoveManagers(m);
    }

    /**
     * @dev change owner of the contract
     * @param o address of new owner
     */
    function changeOwner(address o) external onlyOwner {
        owner = o;
        emit ChangeOwner(o);
    }

    /**
     * @dev get list of all managers
     * @return list of all managers
     */
    function getManagers() external view returns (address[] memory) {
        return managers;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiaOracle {
	
	function changeOwner(address newOwner) external;
    
	function updateCoinInfo(string calldata name, string calldata symbol, uint256 newPrice, uint256 newSupply, uint256 newTimestamp) external;
    
	function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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
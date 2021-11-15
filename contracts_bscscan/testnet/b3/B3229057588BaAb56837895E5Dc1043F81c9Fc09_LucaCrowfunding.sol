// SPDX-License-Identifier: MIT

//** Luca Finance Crowfunding Contract */
//** Author Alex Hong : Luca Finance Crowfunding 2021.6 */

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ILucaFactory.sol";

contract LucaCrowfunding is ILucaFactory, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     *
     * @dev lucaPools store all investors info on this contract.
     *
     */
    mapping(address => InvestorInfo) public lucaPools;

    /**
     *
     * @dev tier pools for contract
     *
     */
    mapping(uint256 => Tier) public tierPools;

    /**
     *
     * @dev tokenPools store all active tokens available on this contract.
     *
     */
    mapping(address => TokenModel) public tokenPools;

    /**
     *
     * @dev store sales information for 1st and 2nd round IDO
     *
     */
    mapping(uint256 => SalesInfo) public salesInfo;

    /**
     *
     * @dev this variable is the instance of active Luca token (presale token)
     *
     */
    IERC20 private _lucaToken;

    /**
     *
     * @dev this variable is the instance of active Light token
     *
     */
    IERC20 private _lightToken;

    modifier requireLight(address _wallet) {
        /** check if investor has any Light token */
        require(
            _lightToken.balanceOf(address(_wallet)) > 0,
            "you have more than 0 in your account"
        );
        _;
    }

    modifier requireLuca(address _wallet) {
        /** check if investor has any Luca token */
        require(
            _lucaToken.balanceOf(address(_wallet)) > 0,
            "you have more than 0 in your account"
        );
        _;
    }

    modifier requireToken(address _token) {
        /** check if token is available in token pool */
        require(tokenPools[_token].active, "Token is not existing in the pool");
        _;
    }

    constructor() public {
        /** constructor of the contract */
    }

    /**
     *
     * @dev set luca token address for contract
     *
     * @param {_token} address of IERC20 instance
     * @return {bool} return status of token address
     *
     */
    function setLucaToken(IERC20 _token)
        external
        override
        onlyOwner
        returns (bool)
    {
        _lucaToken = _token;
        return true;
    }

    /**
     *
     * @dev getter function for deployed luca token address
     *
     * @return {address} return deployment address of luca token
     *
     */
    function getLucaToken() public view override returns (address) {
        return address(_lucaToken);
    }

    /**
     *
     * @dev setup Light token address for contract
     *
     */
    function setLightToken(IERC20 _token)
        external
        override
        onlyOwner
        returns (bool)
    {
        _lightToken = _token;
        return true;
    }

    /**
     *
     * @dev create presale function, defines hardcap, softcap
     *
     * @param {uint256} softcap of the presale
     * @param {uint256} hardcap of the presale
     *
     */
    function createPresale(
        address _token,
        uint256 _tokenPrice,
        uint256 _hardcap,
        uint256 _softcap,
        uint256 _liquidityPercent,
        uint256 _listingRate,
        uint256 _startblock,
        uint256 _endblock,
        uint256 _lockPeriod
    ) external override onlyOwner requireToken(_token) returns (bool) {
        tokenPools[_token].tokenPrice = _tokenPrice;
        tokenPools[_token].hardcap = _hardcap;
        tokenPools[_token].softcap = _softcap;
        tokenPools[_token].liquidityPercent = _liquidityPercent;
        tokenPools[_token].listingRate = _listingRate;
        tokenPools[_token].startBlock = _startblock;
        tokenPools[_token].endBlock = _endblock;
        tokenPools[_token].lockPeriod = _lockPeriod;

        emit CreatePresale(_softcap, _hardcap);

        return true;
    }

    /**
     *
     * @dev add individual tokens (IERC20) to use for our LUCA.
     * ** possibly, we will support investors to invest funds with different crypto assets.
     * ** but for now, this will be used as boilerplate as we are going to use luca token for transaction.
     *
     * @param {IERC20} token instance which is going to add
     * @param {uint256} available date
     * @param {uint256} expired date
     * @param {uint256} rate compared to our LUCA
     *
     * @return {bool} return if token is successfully add or not
     *
     */
    function addTokenToLuca(IERC20 _token, uint256 _rate)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(!tokenPools[address(_token)].active, "Token already exist");

        /** add new token to the token pool */
        tokenPools[address(_token)].token = _token;
        tokenPools[address(_token)].rate = _rate;
        tokenPools[address(_token)].totalRaise = 0;
        tokenPools[address(_token)].active = true;

        /** emit the Add Token event */
        emit AddToken(address(_token));
        return true;
    }

    /**
     *
     * @dev remove active token from token pool
     * ** set deactive flag for existing token because easy to active status later if needed
     *
     * @param {address} active token address which existing in pool
     *
     * @return {bool} return if token is deactived or not
     *
     */
    function removeTokenFromLuca(address _token)
        external
        override
        requireToken(_token)
        onlyOwner
        returns (bool)
    {
        tokenPools[_token].active = false;

        /** emit the event for removing token */
        emit RemoveToken(_token);
        return true;
    }

    /**
     *
     * @dev Retrieve total amount of token from the contract
     *
     * @param {address} address of the token
     *
     * @return {uint256} total amount of token
     *
     */
    function getTotalToken(IERC20 _token)
        external
        view
        override
        returns (uint256)
    {
        return _token.balanceOf(address(this));
    }

    /**
     *
     * @dev getter function to retrieve token in the pool
     *
     * @param {address} address of token
     *
     * @return {TokenModel} return token info
     *
     */
    function getTokenFromLuca(address _token)
        external
        view
        requireToken(_token)
        returns (TokenModel memory)
    {
        return tokenPools[_token];
    }

    /**
     *
     * @dev investor join available agreement
     *
     * @param {uint256} actual join date for investment
     * @param {address} address of token which is going to use as deposit
     *
     * @return {bool} return if investor successfully joined to the agreement
     *
     */
    function joinLuca(
        uint256 _joinDate,
        uint256 _investFund,
        address _token
    )
        external
        payable
        override
        requireLuca(msg.sender)
        requireToken(_token)
        returns (bool)
    {
        /** check if user already invested for this agreement */
        require(
            lucaPools[msg.sender].wallet != msg.sender,
            "User already joinned agreement pool"
        );

        /** check if investor is willing to invest any funds */
        require(_investFund > 0, "need to invest bigger than 0");

        /** check if investor has enough funds for invest */
        require(
            tokenPools[_token].token.balanceOf(address(msg.sender)) >
                _investFund,
            "you need to have enough funds to invest"
        );

        /** add new investor to investor list for specific agreeement */
        lucaPools[msg.sender].joinDate = block.timestamp;
        lucaPools[msg.sender].wallet = msg.sender;
        lucaPools[msg.sender].tierInfo = 0;
        /** rate should not be decimal, so we use to multplay 10**6 as input with SafeMath */
        /** e.g: if rate is 0.6, input should 0.6 * 10^6 */
        lucaPools[msg.sender].investAmount = _investFund
        .mul(tokenPools[_token].rate)
        .div(10**6);
        lucaPools[msg.sender].active = true;

        /** 
            transfer custom token from investor to our contract 
        */

        tokenPools[_token].token.transferFrom(
            msg.sender,
            address(this),
            _investFund
        );
        emit InvestorJoin(_joinDate, _investFund);
        return true;
    }

    /**
     *
     * @dev set the fund rate for new added token
     *
     * @param {address} token address
     * @param {uint256} new rate of the token
     *
     * @return {bool}
     *
     */
    function setRate(address _token, uint256 _rate)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(tokenPools[_token].active, "Token doesn't exist");
        tokenPools[_token].rate = _rate;

        return true;
    }

    /**
     *
     * @dev add tier to tier pools
     *
     * @param {uint256} maxPayable amount
     * @param {uint256} paid amount of luca token
     *
     * @return {bool} return status
     *
     */
    function addTier(
        uint256 _index,
        uint256 _maxPayableAmount,
        uint256 _paidAmount,
        uint256 _tierWeight
    ) external override onlyOwner returns (bool) {
        require(!tierPools[_index].active, "Tier already exist");

        tierPools[_index].index = _index;
        tierPools[_index].maxPayableAmount = _maxPayableAmount;
        tierPools[_index].paidAmount = _paidAmount;
        tierPools[_index].tierWeight = _tierWeight;
        tierPools[_index].active = true;

        return true;
    }

    /**
     *
     * @dev add investor to whitelist member list
     *
     * @param {address} customer wallet address
     * @param {uint256} index of tier pools
     *
     * @return {bool} return status of whitelist
     *
     */
    function addWhitelist(address _wallet, uint256 _tier)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(lucaPools[_wallet].active, "User is not active");
        require(tierPools[_tier].active, "Tier is not active");
        require(!lucaPools[_wallet].whitelist, "User already whitelisted");

        lucaPools[_wallet].whitelist = true;
        lucaPools[_wallet].tierInfo = _tier;

        return true;
    }

    /**
     *
     * @dev set sale date
     *
     * @param {uint256} start date of sales
     * @param {uint256} end date of sales
     *
     * @return {bool} status of sales
     */
    function setSaleDate(
        uint256 _id,
        uint256 _sDate,
        uint256 _eDate
    ) external override onlyOwner returns (bool) {
        require(_id > 0 && _id < 3);
        require(!salesInfo[_id].active, "Sales Info already confirmed");
        require(
            _eDate > _sDate && _sDate > block.timestamp,
            "input correct date"
        );

        salesInfo[_id].active = true;
        salesInfo[_id].startDate = _sDate;
        salesInfo[_id].endDate = _eDate;

        return true;
    }

    /**
     *
     * @dev buy tokens per tier program, 1st round IDO
     *
     * @param {address} token address
     *
     */
    function buyTierTokens(address _token, uint256 _buyAmount)
        external
        override
        requireToken(_token)
        returns (bool)
    {
        require(
            salesInfo[1].active &&
                block.timestamp > salesInfo[1].startDate &&
                block.timestamp < salesInfo[1].endDate,
            "Sale isn't active"
        );
        require(lucaPools[msg.sender].whitelist, "Investor not whitelisted");

        Tier memory checkTier = tierPools[lucaPools[msg.sender].tierInfo];

        require(checkTier.active, "Tier is not active");

        uint256 tierUpperlimit = tokenPools[_token]
        .hardcap
        .mul(checkTier.tierWeight)
        .div(100);

        require(
            tierUpperlimit - tokenPools[_token].totalRaise > _buyAmount,
            "Tier limited"
        );

        require(
            _buyAmount <= checkTier.maxPayableAmount,
            "You can't send more than max payable amount"
        );
        require(
            _lightToken.balanceOf(msg.sender) >= checkTier.paidAmount,
            "You don't have enough Luca Token"
        );

        uint256 calcLuca = _buyAmount.mul(tokenPools[_token].rate).div(10**6);

        require(
            calcLuca < _lucaToken.balanceOf(address(this)),
            "treasury has enough tokens to pay"
        );

        sendFunds(_token, _buyAmount, calcLuca);

        emit TierBuy(msg.sender);
    }

    function sendFunds(
        address _token,
        uint256 _buyAmount,
        uint256 _calcAmount
    ) internal {
        tokenPools[_token].token.transferFrom(
            msg.sender,
            address(this),
            _buyAmount
        );
        tokenPools[_token].totalRaise = tokenPools[_token].totalRaise.add(
            _buyAmount
        );

        _lucaToken.transfer(msg.sender, _calcAmount);
    }

    /**
     *
     * @dev 2nd IDO buy tokens
     *
     */
    function buyRemainTokens(address _token, uint256 _buyAmount)
        external
        override
        requireToken(_token)
        returns (bool)
    {
        require(
            salesInfo[2].active &&
                block.timestamp > salesInfo[2].startDate &&
                block.timestamp < salesInfo[2].endDate,
            "2nd Sale isn't active"
        );

        uint256 remainLucaToken = _lucaToken.balanceOf(address(this));
        uint256 calcBuyAmount = _buyAmount.mul(tokenPools[_token].rate).div(
            10**6
        );

        require(calcBuyAmount < remainLucaToken, "Buy amount is too big");

        sendFunds(_token, _buyAmount, calcBuyAmount);

        emit BuyRemainToken(msg.sender);
    }

    /**
     *
     * @dev we will have function to transfer stable coins to company wallet
     *
     * @param {address} token address
     *
     * @return {bool} return status of the transfer
     *
     */
    function transferToken(
        address _token,
        uint256 _amount,
        address _to
    ) external payable override onlyOwner requireToken(_token) returns (bool) {
        /** check if treasury have enough funds  */
        require(
            tokenPools[_token].token.balanceOf(address(this)) > _amount,
            "need to have enough funds in treasury"
        );
        tokenPools[_token].token.transferFrom(address(this), _to, _amount);

        emit TransferFund(_token, _amount, _to);
        return true;
    }

    /**
     *
     * @dev revert transaction
     *
     */
    fallback() external {
        revert();
    }
}

// SPDX-License-Identifier: MIT

//** Luca Finance Crowfunding Factory Contract */
//** Author Alex Hong : Luca Finance Crowfunding 2021.6 */

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILucaFactory {
    /**
     *
     * @dev Tier info
     *
     */
    struct Tier {
        uint256 index;
        uint256 paidAmount;
        uint256 maxPayableAmount;
        uint256 tierWeight;
        bool active;
    }

    /**
     *
     * @dev Sales info
     *
     */
    struct SalesInfo {
        uint256 startDate;
        uint256 endDate;
        bool active;
    }

    /**
     *
     * @dev InvestorInfo is the struct type which store investor information
     *
     */
    struct InvestorInfo {
        uint256 joinDate;
        uint256 investAmount;
        uint256 tierInfo;
        uint256 tierAmount;
        address wallet;
        bool whitelist;
        bool active;
    }

    /**
     *
     * @dev TokenModel will store new token informations which will be added to the contract
     *
     */
    struct TokenModel {
        IERC20 token;
        uint256 rate;
        uint256 totalRaise;
        uint256 tokenPrice; // 1 base token = ? saleTokens, fixed price
        uint256 hardcap;
        uint256 softcap;
        uint256 liquidityPercent; // divided by 1000
        uint256 listingRate; // fixed rate at which the token will list on uniswap
        uint256 startBlock;
        uint256 endBlock;
        uint256 lockPeriod; // unix timestamp -> e.g. 2 weeks
        bool active;
    }

    /**
     *
     * @dev this event will call when new token added to the contract
     * currently, we are supporting LCF token and this will be used for future implementation
     *
     */
    event AddToken(address token);

    /**
     *
     * @dev this event will call when active token removed from pool
     *
     */
    event RemoveToken(address token);

    /**
     *
     * @dev it is calling when new investor joinning to the existing agreement
     *
     */
    event InvestorJoin(uint256 date, uint256 amount);

    /**
     *
     * @dev this is called when investor vote for the project
     *
     */
    event Vote(uint256 identifier, address investor);

    /**
     *
     * @dev this event is called when transfer fund to other address
     *
     */
    event TransferFund(address token, uint256 amount, address to);

    /**
     *
     * @dev this event calls when buy tokens per tiers
     *
     */
    event TierBuy(address _wallet);

    /**
     *
     * @dev this event calls when 2nd IDO of remain tokens
     *
     */
    event BuyRemainToken(address _wallet);

    /**
     *
     * @dev create presale event
     *
     */
    event CreatePresale(uint256 _softcap, uint256 _hardcap);

    /**
     *
     * inherit functions will be used in contract
     *
     */
    function setLucaToken(IERC20 _token) external returns (bool);

    function setLightToken(IERC20 _token) external returns (bool);

    function addWhitelist(address _wallet, uint256 _tier)
        external
        returns (bool);

    function setRate(address _token, uint256 _rate) external returns (bool);

    function joinLuca(
        uint256 _joinDate,
        uint256 _investFund,
        address _token
    ) external payable returns (bool);

    function getLucaToken() external view returns (address);

    function getTotalToken(IERC20 _token) external view returns (uint256);

    function addTokenToLuca(IERC20 _token, uint256 _rate)
        external
        returns (bool);

    function addTier(
        uint256 _index,
        uint256 _maxPayableAmount,
        uint256 _paidAmount,
        uint256 _tierWeight
    ) external returns (bool);

    function removeTokenFromLuca(address _token) external returns (bool);

    function buyRemainTokens(address _token, uint256 _buyAmount)
        external
        returns (bool);

    function buyTierTokens(address _token, uint256 _buyAmount)
        external
        returns (bool);

    function transferToken(
        address _token,
        uint256 _amount,
        address _to
    ) external payable returns (bool);

    function createPresale(
        address _token,
        uint256 _tokenPrice,
        uint256 _hardcap,
        uint256 _softcap,
        uint256 _liquidityPercent,
        uint256 _listingRate,
        uint256 _startblock,
        uint256 _endblock,
        uint256 _lockPeriod
    ) external returns (bool);

    function setSaleDate(
        uint256 _id,
        uint256 _sDate,
        uint256 _eDate
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


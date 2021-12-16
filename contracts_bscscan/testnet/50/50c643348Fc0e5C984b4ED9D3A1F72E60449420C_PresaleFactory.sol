// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Presale.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPresale.sol";

contract PresaleFactory {
    address[] public presaleAddresses;
    mapping (address => mapping (address => Presale)) public presales;
    event PresaleCoinCreated(address presaleAddress);
    mapping(address => address[]) private tokensOf;
    mapping(address => mapping(address => bool)) private hasToken;

    address payable private tattooAppOwner;

    constructor(address payable feeReceiver) {
        tattooAppOwner = feeReceiver;
    }

    function getPresaleAddresses() external view returns (address[] memory) {
        return presaleAddresses;
    }

    function createPresale(
            address tokenAddress,
            address router,
            uint decimals,
            uint256 totalToken,
            uint256[] memory tokenInfo,
            bool[] memory usingOps,
            uint256[] memory extraInfo,
            string[] memory socialInfo) external payable {
        require(!hasToken[msg.sender][tokenAddress], "Token already exists");
        Presale presaleCoin = new Presale(payable(msg.sender), tokenAddress, decimals);
        presaleAddresses.push(address(presaleCoin));
        tokensOf[msg.sender].push(address(presaleCoin));
        hasToken[msg.sender][tokenAddress] = true;
        tattooAppOwner.transfer(msg.value);
//        IERC20(tokenAddress).transfer(address(presaleCoin), totalToken);
        presaleCoin.initLaunchInfo(tokenInfo, usingOps, extraInfo,router);
        presaleCoin.initSocialInfo(socialInfo);
        emit PresaleCoinCreated(address(presaleCoin));
    }


    function HasTokenForPresale(address owner, address tokenAddress) external view returns (bool){
        return hasToken[owner][tokenAddress];
    }

    function getPresaleCoins(address owner, address tokenAddress) external view returns (Presale) {
        return presales[owner][tokenAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPresale.sol";

contract Presale is ReentrancyGuard, Context, Ownable, IPresale{
    enum RouterType {
        pancakeswap,
        pancakeswap_test
    }

    enum RefundType {
        Burn,
        Refund
    }

    enum StatusType {
        upcomming,
        sale_live,
        sale_ended,
        canceled,
        filled
    }

    using SafeMath for uint256;

    mapping (address => uint256) public _contributions;
    IERC20 public _token;

    uint public override _tokenDecimals;
    uint256 public override _totalSupply;
    string public override _symbol;
    string public override _name;

    address public override _tokenAddress;
    address payable public _wallet;

    // Social Link Data
    string public override _logoImg;
    string public override _website;
    string public override _facebook;
    string public override _twitter;
    string public override _github;
    string public override _telegram;
    string public override _instagram;
    string public override _discord;
    string public override _reddit;
    string public override _description;

    // Defi Launchpad Info
    uint256 public override _presaleRate;
    uint256 public override _softCap;
    uint256 public override _hardCap;
    uint256 public override _minPurchase;
    uint256 public override _maxPurchase;
    uint256 public override _presaleStartTime;
    uint256 public override _presaleEndTime;
    uint256 public override _liquidityPercent;
    uint256 public override _listingRate;
    uint256 public override _totalToken;
    uint256 public override _liquidityLockup;
    bool public override _usingWhitelist;
    bool public override _refundType;
    address public override _router;


    // Extra Info
    bool public override _usingVestingContributor;
    uint public override _firstReleasePercent;
    uint public override _vestingPeriodEachCycle;
    uint public override _tokenReleasePercentEachCycle;

    bool public override _usingTeamVesting;
    uint public override _totalTeamVestingTokens;
    uint public override _teamFirstReleaseDays;
    uint public override _teamFirstReleasePercent;
    uint public override _teamVestingPeriodEachCycle;
    uint public override _teamTokenReleasePercentEachCycle;

    //////////////////////////////////////////
    uint256 public override _weiRaised;

    uint256 public override availableTokensICO;
    uint256 public override _refundStartDate;
    bool public startRefund = false;

    mapping(address => bool) public whitelist;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);


    constructor (
        address payable wallet,
        address token,
        uint256 tokenDecimals
    )  {
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(token != address(0), "Pre-Sale: token is the zero address");
        _tokenAddress = token;
        _token = IERC20(token);
        _wallet = wallet;
        _weiRaised = 0;
        _tokenDecimals = 18 - tokenDecimals;
    }

    function initLaunchInfo(
        uint256[] memory tokenInfo,
        bool[] memory usingOps,
        uint[] memory extraInfo,
        address router
    ) external override {
        _presaleRate = tokenInfo[0];
        _listingRate = tokenInfo[1];
        _softCap = tokenInfo[2];
        _hardCap = tokenInfo[3];
        _minPurchase = tokenInfo[4];
        _maxPurchase = tokenInfo[5];
        _presaleStartTime = tokenInfo[6];
        _presaleEndTime = tokenInfo[7];
        _liquidityPercent = tokenInfo[8];
        _liquidityLockup = tokenInfo[9];
        _totalToken = tokenInfo[10];
        _totalSupply = tokenInfo[11];
        _router = router;
        _usingWhitelist = usingOps[0];
        _refundType = usingOps[1];
        _usingVestingContributor = usingOps[2];
        _usingTeamVesting = usingOps[3];
        if (_usingVestingContributor)
        {
            _firstReleasePercent = extraInfo[0];
            _vestingPeriodEachCycle = extraInfo[1];
            _tokenReleasePercentEachCycle = extraInfo[2];
        }
        if (_usingTeamVesting)
        {
            _totalTeamVestingTokens = extraInfo[3];
            _teamFirstReleasePercent = extraInfo[4];
            _teamFirstReleaseDays = extraInfo[5];
            _teamVestingPeriodEachCycle = extraInfo[6];
            _teamTokenReleasePercentEachCycle = extraInfo[7];
        }
    }

    function initSocialInfo(
        string[] memory socialInfo
    ) external override {
        _logoImg = socialInfo[0];
        _website = socialInfo[1];
        _facebook = socialInfo[2];
        _twitter = socialInfo[3];
        _github = socialInfo[4];
        _telegram = socialInfo[5];
        _instagram = socialInfo[6];
        _discord = socialInfo[7];
        _reddit = socialInfo[8];
        _description = socialInfo[9];
        _name = socialInfo[10];
        _symbol = socialInfo[11];
    }

    //Pre-Sale
    function buyTokens(address beneficiary) external nonReentrant icoActive payable {
        require(whitelist[beneficiary], 'This beneficiary is not whitelisted');
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function stopPresale() external icoActive(){
        if(_weiRaised >= _softCap) {
            _forwardFunds();
        }
        else{
            startRefund = true;
            _refundStartDate = block.timestamp;
        }
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= _minPurchase, 'have to send at least: minPurchase');
        require(_contributions[beneficiary].add(weiAmount)<= _maxPurchase, 'can\'t buy more than: maxPurchase');
        require((_weiRaised+weiAmount) <= _hardCap, 'Hard Cap reached');
        this;
    }

    function claimTokens() external icoNotActive{
        require(startRefund == false);
        uint256 tokensAmt = _getTokenAmount(_contributions[msg.sender]);
        _contributions[msg.sender] = 0;
        _token.transfer(msg.sender, tokensAmt);
    }


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_presaleRate).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function withdraw() external icoNotActive{
        require(startRefund == false || (_refundStartDate + 3 days) < block.timestamp);
        require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);
    }

    function checkContribution(address addr) external view returns(uint256){
        return _contributions[addr];
    }

    function getSocialData() external override view returns (string[] memory) {
        string[] memory socialData = new string[](10);
        socialData[0] = _logoImg;
        socialData[1] = _website;
        socialData[2] = _facebook;
        socialData[3] = _twitter;
        socialData[4] = _github;
        socialData[5] = _telegram;
        socialData[6] = _instagram;
        socialData[7] = _discord;
        socialData[8] = _reddit;
        socialData[9] = _description;
        return socialData;
    }

    function getTokenData() external view returns (uint256[] memory) {
        uint256[] memory tokenData = new uint256[](4);
        tokenData[0] = _presaleStartTime;
        tokenData[1] = _presaleEndTime;
        tokenData[2] = _liquidityLockup;
        tokenData[3] = _refundStartDate;
        return tokenData;
    }

    function getPresaleData() external view returns (uint[] memory) {
        uint[] memory presaleData = new uint[](7);
        presaleData[0] = _presaleRate;
        presaleData[1] = _listingRate;
        presaleData[2] = _minPurchase;
        presaleData[3] = _maxPurchase;
        presaleData[4] = _softCap;
        presaleData[5] = _hardCap;
        presaleData[6] = _liquidityPercent;
        return presaleData;
    }

    function getPresaleStatus() external override view returns (uint) {
        if (_weiRaised >= _hardCap)
        {
            return 3;
        }
        else if (block.timestamp < _presaleStartTime)
        {
            return 0;
        }
        else if (_presaleStartTime <= block.timestamp && block.timestamp < _presaleEndTime)
        {
            return 1;
        }
        else
        {
            return 2;
        }
    }

    function takeTokens(IERC20 tokenAddress) external icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }


    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _token.transfer(_beneficiary, _tokenAmount);
    }

    function refundMe() external icoNotActive{
        require(startRefund == true, 'no refund available');
        uint amount = _contributions[msg.sender];
        if (address(this).balance >= amount) {
            _contributions[msg.sender] = 0;
            if (amount > 0) {
                address payable recipient = payable(msg.sender);
                recipient.transfer(amount);
                emit Refund(msg.sender, amount);
            }
        }
    }

    function withdrawCanceledTokens() public onlyOwner () {

    }

    function updatePoolDetails(string[] memory socialData) external override {
        _logoImg = socialData[0];
        _website = socialData[1];
        _facebook = socialData[2];
        _twitter = socialData[3];
        _github = socialData[4];
        _telegram = socialData[5];
        _instagram = socialData[6];
        _discord = socialData[7];
        _reddit = socialData[8];
        _description = socialData[9];
    }

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    function addToWhitelist(address _beneficiary) external onlyOwner{
        whitelist[_beneficiary] = true;
    }

    function addManyToWhitelist(address[] memory _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    modifier icoActive() {
        require(_presaleStartTime > 0 && _presaleStartTime < block.timestamp && block.timestamp < _presaleEndTime && availableTokensICO > 0, "ICO must be active");
        _;
    }

    modifier icoNotActive() {
        require(_presaleEndTime < block.timestamp, 'ICO should not be active');
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);
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
pragma solidity =0.8.4;
import "./IERC20.sol";

interface IPresale {
    function initLaunchInfo(
        uint256[] memory,
        bool[] memory,
        uint[] memory,
        address
    ) external;
    function initSocialInfo(
        string[] memory
    ) external;

    // Social Link Data
    function _tokenDecimals() external view returns (uint);
    function _totalSupply() external view returns (uint256);
    function _symbol() external view returns (string memory);
    function _name() external view returns (string memory);
    function _tokenAddress() external view returns (address);
    function _logoImg() external view returns (string memory);
    function _website() external view returns (string memory);
    function _facebook() external view returns (string memory);
    function _twitter() external view returns (string memory);
    function _github() external view returns (string memory);
    function _telegram() external view returns (string memory);
    function _instagram() external view returns (string memory);
    function _discord() external view returns (string memory);
    function _reddit() external view returns (string memory);
    function _description() external view returns (string memory);

    // Defi Launchpad Info
    function _presaleRate() external view returns (uint256);
    function _softCap() external view returns (uint256);
    function _hardCap() external view returns (uint256);
    function _minPurchase() external view returns (uint256);
    function _maxPurchase() external view returns (uint256);
    function _presaleStartTime() external view returns (uint256);
    function _presaleEndTime() external view returns (uint256);
    function _liquidityPercent() external view returns (uint256);
    function _listingRate() external view returns (uint256);
    function _totalToken() external view returns (uint256);
    function _liquidityLockup() external view returns (uint256);
    function _usingWhitelist() external view returns (bool);
    function _refundType() external view returns (bool);
    function _router() external view returns (address);

    // Extra Info
    function _usingVestingContributor() external view returns (bool);
    function _firstReleasePercent() external view returns (uint);
    function _vestingPeriodEachCycle() external view returns (uint);
    function _tokenReleasePercentEachCycle() external view returns (uint);

    function _usingTeamVesting() external view returns (bool);
    function _totalTeamVestingTokens() external view returns (uint);
    function _teamFirstReleaseDays() external view returns (uint);
    function _teamFirstReleasePercent() external view returns (uint);
    function _teamVestingPeriodEachCycle() external view returns (uint);
    function _teamTokenReleasePercentEachCycle() external view returns (uint);

    //////////////////////////////////////////
    function _weiRaised() external view returns (uint256);

    function availableTokensICO() external view returns (uint256);
    function _refundStartDate() external view returns (uint256);
    function updatePoolDetails(string[] memory) external;
    function getPresaleStatus() external view returns (uint);
    function getSocialData() external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
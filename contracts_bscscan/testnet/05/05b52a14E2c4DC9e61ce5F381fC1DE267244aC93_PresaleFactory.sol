// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Presale.sol";
import "../interfaces/IERC20.sol";

contract PresaleFactory {

    struct Token {
//        uint8 tokenType;
        address tokenAddress;
//        address tokenName;
//        address tokenSymbol;
//        address tokenTotalSupply;
//        uint256 presaleRate;
//        uint256 softCap;
//        uint256 hardCap;
//        uint256 liquidityPercent;
//        uint256 lockupTime;
//        uint256 saleStartOm;
//        uint8 status;
    }

    mapping (address => address[]) public presaleAddresses;
    mapping (address => mapping (address => Presale)) public presales;
    event PresaleCoinCreated(Presale presaleCoin);
    mapping(address => Token[]) private tokensOf;
    mapping(address => mapping(address => bool)) private hasToken;
    mapping(address => bool) private isGenerated;

    address private tattooAppOwner;

    constructor() {
    }

    function createPresale(address tokenAddress) external {
        require(!hasToken[msg.sender][tokenAddress], "Token already exists");
        Presale presaleCoin = new Presale(payable(msg.sender),tokenAddress, IERC20(tokenAddress).decimals());
        presaleAddresses[tokenAddress].push(address(presaleCoin));
        presales[tokenAddress][address(presaleCoin)] = presaleCoin;
        tokensOf[msg.sender].push(Token(tokenAddress));
        hasToken[msg.sender][tokenAddress] = true;
        isGenerated[tokenAddress] = true;
        emit PresaleCoinCreated(presaleCoin);
    }

    function startPresale(
        address tokenAddress,
        address presaleAddress,
        uint256[] memory tokenData,
        uint[] memory presaleData,
        string[] memory socialData,
        uint refund_type,
        address router) external {
        presales[tokenAddress][presaleAddress].startPresale(tokenData,
            presaleData,
            socialData,
            refund_type,
            router);
        emit PresaleCoinCreated(presales[tokenAddress][presaleAddress]);
    }

    function buyTokens(
        address tokenAddress,
        address presaleAddress,
        address beneficiary) external {
        presales[tokenAddress][presaleAddress].buyTokens(beneficiary);
    }

    function getPresaleCoins(address tokenAddress, address presaleAddress) external view returns (Presale) {
        return presales[tokenAddress][presaleAddress];
    }

    function getSocialData(address tokenAddress, address presaleAddress) external view returns (string[] memory ) {
        return presales[tokenAddress][presaleAddress].getSocialData();
    }

    function getTokenData(address tokenAddress, address presaleAddress) external view returns (uint256[] memory ) {
        return presales[tokenAddress][presaleAddress].getTokenData();
    }

    function getPresaleData(address tokenAddress, address presaleAddress) external view returns (uint256[] memory ) {
        return presales[tokenAddress][presaleAddress].getPresaleData();
    }

    function getPresaleStatus(address tokenAddress, address presaleAddress) external view returns (uint)
    {
        uint status = presales[tokenAddress][presaleAddress].getPresaleStatus();
        return status;
    }

    function getAllTokens(address owner) external view returns (address[] memory) {
        uint256 length = tokensOf[owner].length;
        address[] memory tokenAddresses = new address[](length);
        uint8[] memory tokenTypes = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenAddresses[i] = tokensOf[owner][i].tokenAddress;
        }
        return (tokenAddresses);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is ReentrancyGuard, Context, Ownable {
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
    uint private _tokenDecimals;
    address payable public _wallet;
    uint public _refund;
    address public _router;
    string public _logoImg;
    string public _website;
    string public _facebook;
    string public _twitter;
    string public _github;
    string public _telegram;
    string public _instagram;
    string public _discord;
    string public _reddit;
    string public _description;
    uint public _presaleRate;
    uint public _minPurchase;
    uint public _maxPurchase;
    uint public _softCap;
    uint public _hardCap;
    uint public _liquidityPercent;
    uint public _listingRate;
    uint256 public _weiRaised;
    uint256 public _presaleStartTime;
    uint256 public _presaleEndTime;
    uint256 public _liquidityLockup;
    uint256 availableTokensICO;
    uint256 public _refundStartDate;
    bool public startRefund = false;
    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (
        address payable wallet,
        address token,
        uint256 tokenDecimals
    )  {
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(token != address(0), "Pre-Sale: token is the zero address");
        _token = IERC20(token);
        _wallet = wallet;
        _weiRaised = 0;
        _tokenDecimals = 18 - tokenDecimals;
    }

    receive () external payable {
        if(_presaleStartTime > 0 && _presaleStartTime < block.timestamp  && block.timestamp < _presaleEndTime){
            buyTokens(_msgSender());
        }
        else{
            revert('Pre-Sale is closed');
        }
    }

    function startPresale(
        uint256[] memory tokenData,
        uint[] memory presaleData,
        string[] memory socialData,
        uint refund_type,
        address router) external icoNotActive() {
        startRefund = false;
        _refundStartDate = 0;
        availableTokensICO = _token.balanceOf(address(this));
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
        _presaleStartTime = tokenData[0];
        _presaleEndTime = tokenData[1];
        _liquidityLockup = tokenData[2];
        _refundStartDate = tokenData[3];
        _presaleRate = presaleData[0];
        _listingRate = presaleData[1];
        _minPurchase = presaleData[2];
        _maxPurchase = presaleData[3];
        _softCap = presaleData[4];
        _hardCap = presaleData[5];
        _liquidityPercent = presaleData[6];
        _refund = refund_type;
        _router = router;
        require(_presaleStartTime < block.timestamp, 'duration should be > 0');
        require(_presaleEndTime > block.timestamp, 'duration should be > 0');
        require(_softCap < _hardCap, "Softcap must be lower than Hardcap");
        require(_minPurchase < _maxPurchase, "minPurchase must be lower than maxPurchase");
        require(availableTokensICO > 0 , 'availableTokens must be > 0');
        require(_minPurchase > 0, 'minPurchase should > 0');
        require(_presaleRate > 0, "Pre-Sale: rate is 0");
        require(_listingRate > 0, "Listing: rate is 0");
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

    //Pre-Sale
    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
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

    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }

    function setPresaleRate(uint256 newRate) external icoNotActive{
        _presaleRate = newRate;
    }

    function setListingRate(uint256 newRate) external icoNotActive{
        _listingRate = newRate;
    }
    function setAvailableTokens(uint256 amount) public icoNotActive{
        availableTokensICO = amount;
    }

    function setHardCap(uint256 amount) public icoNotActive{
        _hardCap = amount;
    }

    function setSoftCap(uint256 amount) public icoNotActive{
        _softCap = amount;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function getLogoImg() public view returns (string memory) {
        return _logoImg;
    }

    function getWebsite() public view returns (string memory) {
        return _website;
    }

    function getFacebook() public view returns (string memory) {
        return _facebook;
    }

    function getTwitter() public view returns (string memory) {
        return _twitter;
    }

    function getGithub() public view returns (string memory) {
        return _github;
    }

    function getTelegram() public view returns (string memory) {
        return _telegram;
    }

    function getInstagram() public view returns (string memory) {
        return _instagram;
    }

    function getDiscord() public view returns (string memory) {
        return _discord;
    }

    function getReddit() public view returns (string memory) {
        return _reddit;
    }

    function getDiscription() public view returns (string memory) {
        return _description;
    }

    function getSocialData() public view returns (string[] memory) {
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

    function getTokenData() public view returns (uint256[] memory) {
        uint256[] memory tokenData = new uint256[](4);
        tokenData[0] = _presaleStartTime;
        tokenData[1] = _presaleEndTime;
        tokenData[2] = _liquidityLockup;
        tokenData[3] = _refundStartDate;
        return tokenData;
    }

    function getPresaleData() public view returns (uint[] memory) {
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

    function getPresaleStatus() external view returns (uint) {
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

    function setMaxPurchase(uint256 value) external{
        _maxPurchase = value;
    }

    function setMinPurchase(uint256 value) external{
        _minPurchase = value;
    }

    function takeTokens(IERC20 tokenAddress) public icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }

    function refundMe() public icoNotActive{
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin


pragma solidity ^0.5.16;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  
    constructor () internal { }
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function _msgData() internal pure returns (bytes memory) {
        return msg.data;
    }
}

contract Secondary is Context {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _primary = msgSender;
        emit PrimaryTransferred(msgSender);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
                              
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

   
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
       
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

  
    function callOptionalReturn(IERC20 token, bytes memory data) private {
      
        require(address(token).isContract() );

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)));
        }
    }
}


contract Sale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

   
    IERC20 private _token;

    // Bonus tokens rate multiplier x1000 (i.e. 1200 is 1.2 x 1000 = 120% x1000 = +20% bonus)
    uint256 public bonusMultiplier;
    
    address payable private _wallet;

    uint256 private _rate;

    uint256 tokensUnlockingTime;
    
    uint256 tokensUnlockingTime2;
    
    uint256 tokensUnlockingTime3;
        
    uint256 private _weiRaised;

  
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

 
    constructor (uint256 rate, address payable wallet, IERC20 token,uint256 _bonusMultiplier, uint256 _tokensUnlockingTime, uint256 _tokensUnlockingTime2, uint256 _tokensUnlockingTime3) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));
        bonusMultiplier = _bonusMultiplier;
        _rate = rate;
        _wallet = wallet;
        _token = token;
        tokensUnlockingTime = _tokensUnlockingTime;
        tokensUnlockingTime2 = _tokensUnlockingTime2;
        tokensUnlockingTime3 = _tokensUnlockingTime3;
    }

 
    function () external payable {
        buyTokens(_msgSender());
    }


    function token() public view returns (IERC20) {
        return _token;
    }

 
    function wallet() public view returns (address payable) {
        return _wallet;
    }

 
    function rate() public view returns (uint256) {
        return _rate;
    }

  
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function getTokensUnlockingTime() external view returns (uint) {
        return tokensUnlockingTime;
    }
    
    function getTokensUnlockingTime2() external view returns (uint) {
        return tokensUnlockingTime2;
    }

    function getTokensUnlockingTime3() external view returns (uint) {
        return tokensUnlockingTime3;
    }
  
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        
        uint256 tokens = _getTokenAmount(weiAmount);

        
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

   
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount >= 5000000000000000); /** min bnb */
        require(weiAmount <= 1000000000000000000); /** max bnb */
        this;                
    }

  
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    }

    
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }


    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
     }

  
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).mul(bonusMultiplier).div(1000);
    }
    
    function setBonusMultiplier(uint256 bonusMultiplier_) public  {
        bonusMultiplier = bonusMultiplier_;
    }
    
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
    
}

contract Timed is Sale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for sale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedSaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in sale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "Timed: not open");
        _;
    }

    /**
     * @dev Constructor, takes sale opening and closing times.
     * @param openingTime Sale opening time
     * @param closingTime Sale closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp, "Opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime > openingTime, "Opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the sale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the sale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the sale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the sale is open has already elapsed.
     * @return Whether sale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Extend sale.
     * @param newClosingTime Sale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "Already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "New closing time is before current closing time");

        emit TimedSaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

contract PostDelivery is Timed{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balances2;
        mapping(address => uint256) private _balances3;
    mapping(address => uint256) private _address;

    __unstable__TokenVault private _vault;
    __unstable__TokenVault2 private _vault2;
    __unstable__TokenVault3 private _vault3;

    constructor() public {
        _vault = new __unstable__TokenVault();
        _vault2 = new __unstable__TokenVault2();
        _vault3 = new __unstable__TokenVault3();
    }

    /**
     * @dev Withdraw tokens only after sale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address beneficiary) public {
        require(now > tokensUnlockingTime, "Tokens are not unlocked yet.");

        uint256 amount = _balances[beneficiary];
        require(amount > 0, "Beneficiary is not due any tokens");

        _balances[beneficiary] = 0;
        _vault.transfer(token(), beneficiary, amount);
    }
    
    function withdrawTokens2(address beneficiary) public {
        require(now > tokensUnlockingTime2, "Tokens are not unlocked yet.");

        uint256 amount = _balances2[beneficiary];
        require(amount > 0, "Beneficiary is not due any tokens");

        _balances2[beneficiary] = 0;
        _vault2.transfer(token(), beneficiary, amount);
    }


    function withdrawTokens3(address beneficiary) public {
        require(now > tokensUnlockingTime3, "Tokens are not unlocked yet.");

        uint256 amount = _balances3[beneficiary];
        require(amount > 0, "Beneficiary is not due any tokens");

        _balances3[beneficiary] = 0;
        _vault2.transfer(token(), beneficiary, amount);
    }
    
    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function balanceOf2(address account) public view returns (uint256) {
        return _balances2[account];
    }
    
    function balanceOf3(address account) public view returns (uint256) {
        return _balances3[account];
    }


    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        uint256 vest = tokenAmount.mul(30).div(100);
        uint256 vest2 = tokenAmount.mul(35).div(100);
        uint256 vest3 = tokenAmount.mul(35).div(100);
        _balances[beneficiary] = _balances[beneficiary].add(vest);
        _balances2[beneficiary] = _balances2[beneficiary].add(vest2);
        _balances3[beneficiary] = _balances3[beneficiary].add(vest3);
        _deliverTokens(address(_vault), vest);
        _deliverTokens(address(_vault2), vest2);
        _deliverTokens(address(_vault3), vest3);
    }
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliverySale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}

contract __unstable__TokenVault2 is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}

contract __unstable__TokenVault3 is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}


contract TokenRecover is Ownable {

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Address already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Address does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Address is the zero address");
        return role.bearer[account];
    }
}


contract CapperRole is Context {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () internal {
        _addCapper(_msgSender());
    }

    modifier onlyCapper() {
        require(isCapper(_msgSender()), "Address does not have the Whitelist role");
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    function addCapper(address[] memory account) public onlyCapper {
        for(uint256 i = 0 ; i < account.length ; i++){
          _addCapper(account[i]);
      }
        
    }
    
    function renounceCapper() public {
        _removeCapper(_msgSender());
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}

contract IndividuallyCapped is Sale, CapperRole {
    using SafeMath for uint256;

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;

    /**
     * @dev Sets a specific beneficiary's maximum contribution.
     * @param beneficiary Address to be capped
     * @param cap Wei limit for individual contribution
     */
    function setCap(address[] memory beneficiary, uint256 cap) public onlyCapper {
        for(uint256 i = 0 ; i < beneficiary.length ; i++){
          _caps[beneficiary[i]] = cap;
      }
    }
    

    /**
     * @dev Returns the cap of a specific beneficiary.
     * @param beneficiary Address whose cap is to be checked
     * @return Current cap for individual beneficiary
     */
    function getCap(address beneficiary) public view returns (uint256) {
        return _caps[beneficiary];
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        // solhint-disable-next-line max-line-length
        require(_contributions[beneficiary].add(weiAmount) <= _caps[beneficiary], "Beneficiary's cap exceeded");
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }
}


contract LaunchPadGND is Sale, TokenRecover, IndividuallyCapped, PostDelivery{

    constructor(
        uint256 rate,     // rate, in TKNbits
        address payable wallet,  // wallet to send BNB
        IERC20 token,            // the token
        uint256 openingTime,     // time in unix epoch seconds
        uint256 closingTime,      // time in unix epoch seconds
        uint256 _bonusMultiplier,
        uint256 tokensUnlockingTime,  // time in unix epoch seconds
        uint256 tokensUnlockingTime2,  // time in unix epoch seconds
        uint256 tokensUnlockingTime3  // time in unix epoch seconds
    )
        Timed(openingTime, closingTime)
        Sale(rate, wallet, token, _bonusMultiplier, tokensUnlockingTime, tokensUnlockingTime2, tokensUnlockingTime3)
        public
    { }
}
/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

/**
 * token:     SHR
 * mainnet:   0xd98F75b1A3261dab9eEd4956c93F33749027a964
 * ropsten:   0xf64f84147a6eA6aaC501A66ea056Dc1D645925ee
 * rinkeby:   0x1512c6749a0619928f96b6f981dd913a236a31ab
 * compiler:  v0.6.6+commit.6c089d02
*/


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/newVersion/ERC20TokenExtended.sol

contract ERC20TokenExtended is IERC20 {

    using SafeMath for uint256;

    // Total amount of tokens issued

    mapping(address => bool) public migratedBalances;
    mapping(address => mapping( address => bool)) public migratedAllowances;
    uint256 internal totalTokenIssued;
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    IERC20 prevContract;

    modifier migrateBalance(address _owner) {
        if ( !migratedBalances[_owner] ) {
            migratedBalances[_owner] = true;
            balances[_owner] = balances[_owner].add(prevContract.balanceOf(_owner));
        }
        _;
    }

    modifier migrateAllowance(address _owner, address _spender) {
        if (!migratedAllowances[_owner][_spender]) {
            migratedAllowances[_owner][_spender] = true;
            allowed[_owner][_spender] = allowed[_owner][_spender].add(
                prevContract.allowance(_owner, _spender)
            );
        }
        _;
    }

    constructor(address _prevContract) public {
        prevContract = IERC20(_prevContract);
    }

    function totalSupply() public virtual override view returns (uint256) {
        return totalTokenIssued;
    }

    /* Get the account balance for an address */
    function balanceOf(address _owner)
    public
    override
    view
    returns (uint256) {

        if (!migratedBalances[_owner]) {
            return prevContract.balanceOf(_owner).add(balances[_owner]);
        }
        return balances[_owner];

    }

    /* Transfer the balance from owner's account to another account */
    function transfer(address _to, uint256 _amount)
        public
        override
        virtual
        migrateBalance(msg.sender)
        migrateBalance(_to)
        returns (bool)
    {

        require(_to != address(0x0));

        // amount sent cannot exceed balance
        require(balances[msg.sender] >= _amount);

        
        // update balances
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);

        // log event
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    

    /* Allow _spender to withdraw from your account up to _amount */
    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {

        require(_spender != address(0x0));

        // update allowed amount
        allowed[msg.sender][_spender] = _amount;

        // log event
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Spender of tokens transfers tokens from the owner's balance */
    /* Must be pre-approved by owner */
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        override
        virtual
        migrateAllowance(_from, msg.sender)
        migrateBalance(msg.sender)
        migrateBalance(_from)
        migrateBalance(_to)
        returns (bool)
    {
        
        require(_to != address(0));
        
        // balance checks
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);

        // update balances and allowed amount
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);

        // log event
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /* Returns the amount of tokens approved by the owner */
    /* that can be transferred by spender */
    function allowance(address _owner, address _spender)
    public
    override
    view
    returns (uint256) {

        if (!migratedAllowances[_owner][_spender]) {
            return prevContract.allowance(_owner, _spender).add(allowed[_owner][_spender]);
        }
        return allowed[_owner][_spender];

    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


contract WhiteListManager is Ownable {

    // The list here will be updated by multiple separate WhiteList contracts
    mapping (address => bool) public list;

    function unset(address addr) public onlyOwner {

        list[addr] = false;
    }

    function unsetMany(address[] memory addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            unset(addrList[i]);
        }
    }

    function set(address addr) public onlyOwner {

        list[addr] = true;
    }

    function setMany(address[] memory addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            set(addrList[i]);
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {

        return list[addr];
    }
}

abstract contract ShareToken is IERC20{

    mapping(address => bool) public rewardTokenLocked;
    bool public mainSaleTokenLocked = true;
    uint256 public airDropTokenIssuedTotal;
    uint256 public bountyTokenIssuedTotal;

    uint256 public seedAndPresaleTokenIssuedTotal;


    function totalMainSaleTokenIssued() public returns (uint256) {

    }
}

contract ShareTokenExtended is ERC20TokenExtended, WhiteListManager {


    string public constant name = "ShareToken";
    string public constant symbol = "SHR";
    uint8  public constant decimals = 2;
    ShareToken public prevShareToken;

    address public icoContract;

    // Any token amount must be multiplied by this const to reflect decimals
    uint256 constant E2 = 10 ** 2;

    mapping(address => bool) public rewardTokenLocked;
    mapping(address => bool) public migratedRewardTokenLocked;
    bool public mainSaleTokenLocked = true;

    uint256 public constant TOKEN_SUPPLY_MAINSALE_LIMIT = 1000000000 * E2; // 1,000,000,000 tokens (1 billion)
    uint256 public constant TOKEN_SUPPLY_AIRDROP_LIMIT = 6666666667; // 66,666,666.67 tokens (0.066 billion)
    uint256 public constant TOKEN_SUPPLY_BOUNTY_LIMIT = 33333333333; // 333,333,333.33 tokens (0.333 billion)

    uint256 public airDropTokenIssuedTotal;
    uint256 public bountyTokenIssuedTotal;

    uint256 public constant TOKEN_SUPPLY_SEED_LIMIT = 500000000 * E2; // 500,000,000 tokens (0.5 billion)
    uint256 public constant TOKEN_SUPPLY_PRESALE_LIMIT = 2500000000 * E2; // 2,500,000,000.00 tokens (2.5 billion)
    uint256 public constant TOKEN_SUPPLY_SEED_PRESALE_LIMIT = TOKEN_SUPPLY_SEED_LIMIT + TOKEN_SUPPLY_PRESALE_LIMIT;

    uint256 public seedAndPresaleTokenIssuedTotal;

    uint8 private constant PRESALE_EVENT = 0;
    uint8 private constant MAINSALE_EVENT = 1;
    uint8 private constant BOUNTY_EVENT = 2;
    uint8 private constant AIRDROP_EVENT = 3;

    modifier migrateRewardTokenLocked(address _addr) {
        // This requires the legacy ShareToken is completely locked
        // no change made on *rewardTokenLocked* variable
        if (!migratedRewardTokenLocked[_addr]) {
            migratedRewardTokenLocked[_addr] = true;
            rewardTokenLocked[_addr] = prevShareToken.rewardTokenLocked(_addr);
        }
        _;
    }

    //0xee5fe244406f35d9b4ddb488a64d51456630befc
    constructor(address _prevContract)
        public
        ERC20TokenExtended(_prevContract)
    {
        prevShareToken = ShareToken(_prevContract);
        totalTokenIssued = prevShareToken.totalMainSaleTokenIssued();
        airDropTokenIssuedTotal = prevShareToken.airDropTokenIssuedTotal();
        bountyTokenIssuedTotal = prevShareToken.bountyTokenIssuedTotal();
        seedAndPresaleTokenIssuedTotal = prevShareToken.seedAndPresaleTokenIssuedTotal();
        mainSaleTokenLocked = true;
    }

    function unlockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = false;
    }

    function lockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = true;
    }

    function unlockRewardToken(address addr) public onlyOwner {
        rewardTokenLocked[addr] = false;
        migratedRewardTokenLocked[addr] = true;
    }

    function unlockRewardTokenMany(address[] memory addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            unlockRewardToken(addrList[i]);
        }
    }

    function lockRewardToken(address addr) public onlyOwner {
        rewardTokenLocked[addr] = true;
        migratedRewardTokenLocked[addr] = true;
    }

    function lockRewardTokenMany(address[] memory addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            lockRewardToken(addrList[i]);
        }
    }

    // Check if a given address is locked. The address can be in the whitelist or in the reward
    function isLocked(address addr)
    public
    view
    returns (bool)
    {
        // Main sale is running, any addr is locked
        if (mainSaleTokenLocked) {
            return true;
        }
        // Main sale is ended and thus any whitelist addr is unlocked
        if (isWhitelisted(addr)) {
            return false;
        }
        // If the addr is in the reward, it must be checked if locked
        // If the addr is not in the reward, it is considered unlocked
        if (!migratedRewardTokenLocked[addr]) {
            return prevShareToken.rewardTokenLocked(addr);
        }
        return rewardTokenLocked[addr];

    }

    function totalSupply() public override view returns (uint256) {

        return totalTokenIssued.add(seedAndPresaleTokenIssuedTotal).add(airDropTokenIssuedTotal).add(bountyTokenIssuedTotal);
    }

    function totalMainSaleTokenIssued() public view returns (uint256) {

        return totalTokenIssued;
    }

    function totalMainSaleTokenLimit() public pure returns (uint256) {

        return TOKEN_SUPPLY_MAINSALE_LIMIT;
    }

    function totalPreSaleTokenIssued() public view returns (uint256) {

        return seedAndPresaleTokenIssuedTotal;
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        migrateRewardTokenLocked(msg.sender)
        migrateRewardTokenLocked(_to)
        returns (bool success)
    {

        require(isLocked(msg.sender) == false);
        require(isLocked(_to) == false);

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        override
        migrateRewardTokenLocked(msg.sender)
        migrateRewardTokenLocked(_from)
        migrateRewardTokenLocked(_to)
        returns (bool success)
    {

        require(isLocked(_from) == false);
        require(isLocked(_to) == false);

        return super.transferFrom(_from, _to, _amount);
    }

    function setIcoContract(address _icoContract) public onlyOwner {

        // Allow to set the ICO contract only once
        require(icoContract == address(0));
        require(_icoContract != address(0));

        icoContract = _icoContract;
    }

    function sell(address buyer, uint256 tokens) public returns (bool success) {

        require(icoContract != address(0));
        // The sell() method can only be called by the fixedly-set ICO contract
        require(msg.sender == icoContract);
        require(tokens > 0);
        require(buyer != address(0));

        // Only whitelisted address can buy tokens. Otherwise, refund
        require(isWhitelisted(buyer));

        require(totalTokenIssued.add(tokens) <= TOKEN_SUPPLY_MAINSALE_LIMIT);

        // Register tokens issued to the buyer
        balances[buyer] = balances[buyer].add(tokens);

        // Update total amount of tokens issued
        totalTokenIssued = totalTokenIssued.add(tokens);

        emit Transfer(address(MAINSALE_EVENT), buyer, tokens);

        return true;
    }

    function rewardAirdrop(address _to, uint256 _amount) public onlyOwner {

        // this check also ascertains _amount is positive
        require(_amount <= TOKEN_SUPPLY_AIRDROP_LIMIT);

        require(airDropTokenIssuedTotal < TOKEN_SUPPLY_AIRDROP_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_AIRDROP_LIMIT.sub(airDropTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        airDropTokenIssuedTotal = airDropTokenIssuedTotal.add(_amount);

        // Lock the receiver
        migratedRewardTokenLocked[_to] = true;
        rewardTokenLocked[_to] = true;

        emit Transfer(address(AIRDROP_EVENT), _to, _amount);
    }

    function rewardBounty(address _to, uint256 _amount) public onlyOwner {
        // this check also ascertains _amount is positive
        require(_amount <= TOKEN_SUPPLY_BOUNTY_LIMIT);

        require(bountyTokenIssuedTotal < TOKEN_SUPPLY_BOUNTY_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_BOUNTY_LIMIT.sub(bountyTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        bountyTokenIssuedTotal = bountyTokenIssuedTotal.add(_amount);

        // Lock the receiver
        migratedRewardTokenLocked[_to] = true;
        rewardTokenLocked[_to] = true;

        emit Transfer(address(BOUNTY_EVENT), _to, _amount);
    }

    function rewardBountyMany(address[] memory addrList, uint256[] memory amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardBounty(addrList[i], amountList[i]);
        }
    }

    function rewardAirdropMany(address[] memory addrList, uint256[] memory amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardAirdrop(addrList[i], amountList[i]);
        }
    }

    function handlePresaleToken(address _to, uint256 _amount) public onlyOwner {

        require(_amount <= TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        require(seedAndPresaleTokenIssuedTotal < TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_SEED_PRESALE_LIMIT.sub(seedAndPresaleTokenIssuedTotal);
        require(_amount <= remainingTokens);

        // Register tokens to the receiver
        balances[_to] = balances[_to].add(_amount);

        // Update total amount of tokens issued
        seedAndPresaleTokenIssuedTotal = seedAndPresaleTokenIssuedTotal.add(_amount);

        emit Transfer(address(PRESALE_EVENT), _to, _amount);

        // Also add to whitelist
        set(_to);
    }

    function handlePresaleTokenMany(address[] memory addrList, uint256[] memory amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            handlePresaleToken(addrList[i], amountList[i]);
        }
    }

    // add a selfdestruct function
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
}
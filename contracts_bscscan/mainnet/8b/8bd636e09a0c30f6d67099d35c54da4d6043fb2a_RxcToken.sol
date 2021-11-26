/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// File: contracts/IPancakeFactory.sol


pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/SafeMath.sol


pragma solidity ^0.8.1;

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
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IBEP20.sol


pragma solidity ^0.8.1;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts/RxcToken.sol


/*
 * RxC - $RXC Token BEP20
 * Transaction Fee: 5%
 * Transaction Fee breakdown:
 * - Treasury Fee: 25% of transaction fee
 * - Operations Fee: 25% of transaction fee
 * - Marketing Fee: 25% of transaction fee
 * - Developers Fee: 25% of transaction fee
 */
pragma solidity ^0.8.6;






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
 
abstract contract BPContract{
    function protect( address sender, address receiver, uint256 amount ) external virtual;
}


contract RxcToken is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    //$RXC transaction fee
    uint256 public _transactionFee;
    uint256 public _developerFee;
    uint256 public _treasuryFee;
    uint256 public _operationsFee;
    uint256 public _marketingFee;

    //special addresses
    address public operationsAddress;
    address public treasuryAddress;
    address public developersAddress;
    address public marketingAddress;

    address public immutable pancakeswapV2Pair;

    mapping(address => bool) private _isSpecialAddress;

    struct CoreWalletOrder {
        address walletAddress;
        uint256 amount;
        string lockType;
    }

    struct PrivateSaleOrder {
        address participant;
        uint256 amount;
    }

    mapping(address => TokenLocks) private tokenLocks;
    mapping(string => address[]) private tokenLockAddresses;
    struct TokenLocks {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        string lockType; //presale, founders, etc.
    }

    bool public maintenanceMode;

    uint256 public allowBlacklistingUntil;
    mapping(address => bool) private _blacklistedAddresses;

    event MaintenanceMode(bool maintenanceMode);

    event SpecialAddressUpdated(address specialAddress,bool activate);

    event BlacklistAddressUpdate(
        address blacklistAddress,
        bool toggleBlacklistAddress
    );

    event OperationsAddressChanged(address oldAddress, address newAddress);
    event DevelopersAddressChanged(address oldAddress, address newAddress);
    event MarketingAddressChanged(address oldAddress, address newAddress);
    event TreasuryAddressChanged(address oldAddress, address newAddress);

    uint256 public privateSaleGeneratedAmount;
    uint256 public privateSaleMaxAmount = 26700000000000000;
    address public privateSaleOperator; // address of the operator
    event NewPrivateSaleOperatorAddress(address operator);

    uint256 public coreMaxAmount = 34200000000000000;
    uint256 public coreGeneratedAmount;

    uint256 public privateSaleVestingStartDate;
    uint256 public privateSaleVestingEndDate;

    BPContract public BP;
    bool public bpEnabled;
    bool public BPDisabledForever = false;

    constructor(
        uint256 __totalSupply,
        uint256 transactionFee,
        address _operationsAddress,
        address _developersAddress,
        address _marketingAddress,
        address _treasuryAddress
    ) {
        _name = "RxC";
        _symbol = "RXC";
        _decimals = 9;
        _totalSupply = __totalSupply.mul(10**9).sub(privateSaleMaxAmount).sub(
            coreMaxAmount
        );

        operationsAddress = _operationsAddress;
        developersAddress = _developersAddress;
        marketingAddress = _marketingAddress;
        treasuryAddress = _treasuryAddress;

        _isSpecialAddress[operationsAddress] = true;
        _isSpecialAddress[developersAddress] = true;
        _isSpecialAddress[marketingAddress] = true;
        _isSpecialAddress[treasuryAddress] = true;
        _isSpecialAddress[msg.sender] = true;

        pancakeswapV2Pair = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)
            .createPair(address(this), address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

        _transactionFee = transactionFee; //5
        _developerFee = 25; //25
        _treasuryFee = 25; //25
        _operationsFee = 25; //25
        _marketingFee = 25; //25

        allowBlacklistingUntil = block.timestamp + 2 days;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function setBPAddrss(address _bp) external onlyOwner {
        require(address(BP)== address(0), "Can only be initialized once");
        BP = BPContract(_bp);
    }
    
    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }
    
    function setBotProtectionDisableForever() external onlyOwner{
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }

    modifier onlyOwnerOrPrivateSaleOperator() {
        require(
            msg.sender == owner() || msg.sender == privateSaleOperator,
            "Not operator/admin"
        );
        _;
    }

    //@dev: set new operator
    function setPrivateSaleOperator(address _privateSaleOperatorAddress)
        external
        onlyOwner
    {
        require(
            _privateSaleOperatorAddress != address(0),
            "Cannot be zero address"
        );
        privateSaleOperator = _privateSaleOperatorAddress;

        emit NewPrivateSaleOperatorAddress(_privateSaleOperatorAddress);
    }

    function updateSpecialAddress(address _specialAddress, bool activate) public onlyOwner {
        emit SpecialAddressUpdated(_specialAddress,activate);
        _isSpecialAddress[_specialAddress] = activate;
    }

    function setOperationsAddress(address _operationsAddress) public onlyOwner {
        emit OperationsAddressChanged(operationsAddress, _operationsAddress);
        updateSpecialAddress(operationsAddress,false);
        updateSpecialAddress(_operationsAddress,true);
        operationsAddress = _operationsAddress;
    }

    function setDevelopersAddress(address _developersAddress) public onlyOwner {
        emit DevelopersAddressChanged(developersAddress, _developersAddress);
        updateSpecialAddress(developersAddress,false);
        updateSpecialAddress(_developersAddress,true);
        developersAddress = _developersAddress;
        
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        emit MarketingAddressChanged(marketingAddress, _marketingAddress);
        updateSpecialAddress(marketingAddress,false);
        updateSpecialAddress(_marketingAddress,true);
        marketingAddress = _marketingAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        emit TreasuryAddressChanged(treasuryAddress, _treasuryAddress);
        updateSpecialAddress(treasuryAddress,false);
        updateSpecialAddress(_treasuryAddress,true);
        treasuryAddress = _treasuryAddress;
    }

    function setMaintenanceMode(bool _maintenanceMode) public onlyOwner {
        maintenanceMode = _maintenanceMode;
        emit MaintenanceMode(_maintenanceMode);
    }

    function setBlacklistAddress(
        address blacklistAddress,
        bool toggleBlacklistAddress
    ) public onlyOwner {
        if(toggleBlacklistAddress == true){
            //@dev: ensure that blacklisting can only be used for 2 days after the contract has been deployed
            require(allowBlacklistingUntil > block.timestamp,"Blacklist usage expired");
        }
        require(blacklistAddress != pancakeswapV2Pair,"Pairing cannot be blacklisted");
        
        _blacklistedAddresses[blacklistAddress] = toggleBlacklistAddress;
        emit BlacklistAddressUpdate(blacklistAddress, toggleBlacklistAddress);
    }

    function isBlacklistedAddress(address blacklistAddress)
        public
        view
        returns (bool)
    {
        return _blacklistedAddresses[blacklistAddress];
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _getCurrentBalance(account);
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "insufficient allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "dec allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (bpEnabled && !BPDisabledForever){
            BP.protect(sender, recipient, amount); 
        }
        require(!maintenanceMode, "Maintenance mode");
        require(sender != address(0), "transfer to 0 addr");
        require(recipient != address(0), "transfer to 0 addr");
        require(!_blacklistedAddresses[sender], "blacklisted");

        if (_takeFee(sender) && _takeFee(recipient)) {
            _transferRegular(sender, recipient, amount);
        } else if (!_takeFee(sender) && _takeFee(recipient)) {
            _transferSpecialSender(sender, recipient, amount);
        } else if (_takeFee(sender) && !_takeFee(recipient)) {
            _transferRegular(sender, recipient, amount);
        } else if (!_takeFee(sender) && !_takeFee(recipient)) {
            _transferSpecialBoth(sender, recipient, amount);
        }
    }

    //if both address is special address
    function _transferSpecialBoth(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount, "insuff balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //if sender is special address
    function _transferSpecialSender(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount, "insuff balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //if receiver is special address
    function _transferSpecialReceiver(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount, "insuff balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //if both sender and receiver is not special address. only regular transfer has transaction fee
    function _transferRegular(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount, "insuff balance");
        (uint256 transactionFee, uint256 toRecipient) = calculateTransactionAmount(amount);
        _balances[recipient] = _balances[recipient].add(toRecipient);
        _takeTransactionFee(sender, transactionFee);
        emit Transfer(sender, recipient, toRecipient);
    }

    function calculateTransactionAmount(uint256 amount) internal view returns (uint256 transactionFee, uint256 toRecipient) {
        transactionFee = amount.mul(_transactionFee).div(100);
        toRecipient = amount.sub(transactionFee);
    }

    //$RXC custom balanceOf
    function _getCurrentBalance(address account)
        private
        view
        returns (uint256)
    {
        if (tokenLocks[account].amount != 0) {
            return
                _balances[account].sub(
                    getTokenLockAmount(account, block.timestamp)
                );
        }
        return _balances[account];
    }

    function _takeFee(address account) private view returns (bool) {
        if (_isSpecialAddress[account]) {
            return false;
        }
        return true;
    }

    function _takeTransactionFee(address sender, uint256 transactionFee)
        private
    {
        _balances[operationsAddress] = _balances[operationsAddress].add(transactionFee.mul(_operationsFee).div(100));
        _balances[developersAddress] = _balances[developersAddress].add(transactionFee.mul(_developerFee).div(100));
        _balances[marketingAddress] = _balances[marketingAddress].add(transactionFee.mul(_marketingFee).div(100));
        _balances[treasuryAddress] = _balances[treasuryAddress].add(transactionFee.mul(_treasuryFee).div(100));
        
        emit Transfer(
            sender,
            operationsAddress,
            transactionFee.mul(_operationsFee).div(100)
        );
        emit Transfer(
            sender,
            developersAddress,
            transactionFee.mul(_developerFee).div(100)
        );
        emit Transfer(
            sender,
            marketingAddress,
            transactionFee.mul(_marketingFee).div(100)
        );
        emit Transfer(
            sender,
            treasuryAddress,
            transactionFee.mul(_treasuryFee).div(100)
        );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "0 address denied");
        require(spender != address(0), "0 address denied");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function inCaseTokensGetStuck(IBEP20 token, address to) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }

    /**
     * @dev Sets the transaction fee rate of $RXC
     */
    function setTransactionFee(uint256 newTransactionFee) public onlyOwner {
        require(newTransactionFee <= 20, "Max txFee is 20");
        _transactionFee = newTransactionFee;
    }

    // @dev This view is to display the wallet owner's locked\available tokens and endTime within dapp
    function getLockedWalletDetails(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentTime = block.timestamp;
        uint256 _startTime = tokenLocks[account].startTime;
        uint256 _endTime = tokenLocks[account].endTime;
        uint256 _totalAmount = tokenLocks[account].amount;
        uint256 _lockedAmount = getTokenLockAmount(account, currentTime);
        uint256 _accessibleAmount = _totalAmount - _lockedAmount;
        return (
            _startTime,
            _endTime,
            _totalAmount,
            _lockedAmount,
            _accessibleAmount,
            currentTime
        );
    }

    // @dev This function figures the proportion of time that has passed since the start relative to the end date and returns the proportion of tokens locked
    function getTokenLockAmount(address account, uint256 currentTime)
        public
        view
        returns (uint256)
    {
        if (currentTime > tokenLocks[account].endTime) return 0;
        return
            (
                ((tokenLocks[account].amount *
                    ((tokenLocks[account].endTime - currentTime))) /
                    (tokenLocks[account].endTime -
                        tokenLocks[account].startTime))
            );
    }

    // @dev allow use mint function until presale is done
    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    // @dev This function records the transaction to keep track of the lock and then transfers the tokens to the wallet as normal
    function assignTokenLock(
        address account,
        uint256 _amount,
        uint256 _startTime,
        uint256 _endTIme,
        string memory _type,
        bool isInitial
    ) private {
        tokenLocks[account].amount = _amount;
        tokenLocks[account].startTime = _startTime;
        tokenLocks[account].endTime = _endTIme;
        tokenLocks[account].lockType = _type;
        tokenLockAddresses[_type].push(account);
        if (!isInitial) {
            _mint(account, _amount);
        }
    }

    // @dev A view to access the list of addresses that have locked tokens
    function getTokenLockAddresses(string memory _type)
        public
        view
        returns (address[] memory)
    {
        return tokenLockAddresses[_type];
    }

    //@dev: addPrivateSaleVestedTokensBulk send TGE and lock remaining tokens of private sale participants
    function addPrivateSaleVestedTokensBulk(
        PrivateSaleOrder[] memory privateSaleParticipants
    ) public onlyOwnerOrPrivateSaleOperator {
        require(
            privateSaleGeneratedAmount < privateSaleMaxAmount,
            "Private sale amount maxed out"
        );

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + (6 * 2592000);

        for (uint256 i = 0; i < privateSaleParticipants.length; i++) {
            require(
                tokenLocks[privateSaleParticipants[i].participant].amount == 0,
                "Already have locked tokens"
            );

            address participant = privateSaleParticipants[i].participant;
            uint256 initialReleaseAmount = privateSaleParticipants[i]
                .amount
                .mul(15)
                .div(100);
            uint256 tokensToVest = privateSaleParticipants[i].amount -
                initialReleaseAmount;

            _mint(participant, initialReleaseAmount);
            assignTokenLock(
                participant,
                tokensToVest,
                startTime,
                endTime,
                "private",
                false
            );

            privateSaleGeneratedAmount += privateSaleParticipants[i].amount;
        }
    }

    //@dev: addCoreVestedTokensBulk cliff and lock the tokens of core wallets
    function addCoreVestedTokensBulk(CoreWalletOrder[] memory coreWallets)
        public
        onlyOwnerOrPrivateSaleOperator
    {
        require(coreGeneratedAmount < coreMaxAmount, "Core amount maxed out");

        uint256 startTime = block.timestamp + 2592000;
        uint256 endTime = startTime + (12 * 2592000);

        for (uint256 i = 0; i < coreWallets.length; i++) {
            require(
                tokenLocks[coreWallets[i].walletAddress].amount == 0,
                "Already have locked tokens"
            );

            if(keccak256(abi.encodePacked(coreWallets[i].lockType)) == keccak256(abi.encodePacked("rxcteam"))){
                startTime = block.timestamp + (60 * 2592000); //5 years lock for rxcteam
                endTime = startTime + (24 * 2592000); //after 5 years, 24 month full linear vesting will start
            }

            address walletAddress = coreWallets[i].walletAddress;

            assignTokenLock(
                walletAddress,
                coreWallets[i].amount,
                startTime,
                endTime,
                coreWallets[i].lockType,
                false
            );

            coreGeneratedAmount += coreWallets[i].amount;
        }
    }
}
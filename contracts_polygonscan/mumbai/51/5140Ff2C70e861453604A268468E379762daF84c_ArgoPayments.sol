/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

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

interface IDiaOracle {
	
	function changeOwner(address newOwner) external;
    
	function updateCoinInfo(string calldata name, string calldata symbol, uint256 newPrice, uint256 newSupply, uint256 newTimestamp) external;
    
	function getValue(string memory key) external view returns (uint128, uint128);
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

// SPDX-License-Identifier: Apache-2.0
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

/**
 * @title this is a contract for charging users for the deployments they make
 * @author abhimanyu121
 */
contract ArgoPayments is Pausable, GovernanceOwnable {
    event ChargeWithoutProvider(
        address indexed user,
        uint256 indexed feeCharged,
        uint256 indexed feeWithoutDiscount,
        address escrow
    );
    event ChargeWithProvider(
        address indexed user,
        uint256 indexed feeCharged,
        uint256 indexed feeWithoutDiscount,
        address escrow,
        uint256 providerQuote,
        uint256 providerCharged,
        string provider
    );
    //price per microsecond of buildtime, it will be in USD, like USDPRICE * 10 **18
    uint256 public buildTimeRate;

    //erc20 used for payments
    IERC20 public underlying;

    //erc20 used for staking
    IERC20 public stakedToken;

    // address of escrow
    address public escrow;

    // would be true if discounts needs to be deducted
    bool public discountsEnabled;

    // interface for for staking manager
    IStaking public stakingManager;

    //Data for discounts
    struct Discount {
        uint256 amount;
        uint256 percent;
    }

    //Different discount slabs
    Discount[] public discountSlabs;

    //Oracle instance
    IDiaOracle priceFeed;

    //Oracle feeder symbol
    string feederSymbol;

    //For improved precision
    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENT = 100 * PRECISION;
    //decimal precision
    uint256 constant DECIMAL = 10**18;

    /**
     * @notice initialise the contract
     * @param u underlying token for payments
     * @param e escrow address for payments
     * @param slabAmounts_ array of amounts that seperates different slabs of discount
     * @param slabPercents_ array of percent of discount user will get
     * @param b build time rate
     * @param p price feed aggregator address
     * @param s address of staked token
     */
    constructor(
        address u,
        address e,
        uint256[] memory slabAmounts_,
        uint256[] memory slabPercents_,
        uint256 b,
        address p,
        address s,
        string memory feederSymbol_
    ) {
        require(
            u != address(0),
            "ArgoPayments: Token address can not be zero address"
        );
        require(
            e != address(0),
            "ArgoPayments: Escrow address can not be zero address"
        );
        require(
            s != address(0),
            "ArgoPayments: staked token address can not be zero address"
        );
        require(
            slabAmounts_.length == slabPercents_.length,
            "ArgoPayments: discount slabs array and discount amount array have different size"
        );
        require(b != 0, "ArgoPayments: Price per microsecond can not be zero");

        underlying = IERC20(u);
        escrow = e;
        for (uint256 i = 0; i < slabAmounts_.length; i++) {
            Discount memory _discount = Discount(
                slabAmounts_[i],
                slabPercents_[i]
            );
            discountSlabs.push(_discount);
        }
        buildTimeRate = b;
        priceFeed = IDiaOracle(p);
        stakedToken = IERC20(s);
        feederSymbol = feederSymbol_;
    }

    /**
     * @notice charge user for only build time
     * @param u address of user to be charge
     * @param b build time
     */
    function charge(address u, uint256 b) public onlyManager whenNotPaused {
        require(b != 0, "ArgoPayments: Build time can not be zero");
        uint256 initial = _calculateFee(b);
        uint256 discount = _calculateDiscount(u, initial);
        uint256 total = initial - discount;
        require(
            underlying.balanceOf(u) >= total,
            "ArgoPayments: User have insufficient balance"
        );
        require(
            underlying.allowance(u, address(this)) >= total,
            "ArgoPayments: Insufficient allowance"
        );
        underlying.transferFrom(u, escrow, total);
        emit ChargeWithoutProvider(u, total, initial, escrow);
    }

    /**
     * @notice charge user for build time and deployment cost
     * @dev remember to send price of USD * 10**18
     * @param u address of user to be charged
     * @param b build time
     * @param d deployment price for storage provider protocol
     * @param providerQuote Quote of storage providerl's token
     * @param providerCharged tokens charged by storage provider
     * @param provider name of storage provider
     */
    function chargeWithProvider(
        address u,
        uint256 b,
        uint256 d,
        uint256 providerQuote,
        uint256 providerCharged,
        string memory provider
    ) public onlyManager whenNotPaused {
        require(b != 0, "ArgoPayments: Build time can not be zero");
        uint256 initial = _calculateFeeWithProvider(b, d);
        uint256 discount = _calculateDiscount(u, initial);
        uint256 total = initial - discount;
        require(
            underlying.balanceOf(u) >= total,
            "ArgoPayments: User have insufficient balance"
        );
        require(
            underlying.allowance(u, address(this)) >= total,
            "ArgoPayments: Insufficient allowance"
        );
        underlying.transferFrom(u, escrow, total);
        emit ChargeWithProvider(
            u,
            total,
            initial,
            escrow,
            providerQuote,
            providerCharged,
            provider
        );
    }

    /**
     * @notice update escrow address
     * @param e address for new escrow
     */
    function updateEscrow(address e) public onlyManager {
        escrow = e;
    }

    /**
     * @notice update undelying token address
     * @param u new underlying token address
     */
    function updateToken(address u) public onlyManager {
        underlying = IERC20(u);
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
            "ArgoPayments: discount slabs array and discount amount array have different size"
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
     * @dev calculate fee to charge for build time
     * @param b build time for which fee will be calculated
     * @return fee to be charged to user in underlying token for build time
     */
    function _calculateFee(uint256 b) internal view returns (uint256) {
        uint256 _amount = (b * buildTimeRate * DECIMAL) / getUnderlyingPrice();

        return _amount;
    }

    /**
     * @dev calculate fee to charge for build time and deployment
     * @param b build time
     * @param d deployment price charged by storage provider
     * @return fee to be charged to user in underlying token for build time and deployment cost
     */
    function _calculateFeeWithProvider(uint256 b, uint256 d)
        internal
        view
        returns (uint256)
    {
        uint256 underlyingPrice = getUnderlyingPrice();
        uint256 buildPrice = (b * buildTimeRate * DECIMAL) / underlyingPrice;
        uint256 deploymentPrice = (d * DECIMAL) / underlyingPrice;
        uint256 amount = buildPrice + deploymentPrice;

        return amount;
    }

    /**
     * @dev calculate discount that user gets for staking
     * @param u address of user that needs to be charged
     * @param a amount the user will pay without discount
     * @return discount that user will get
     */
    function _calculateDiscount(address u, uint256 a)
        internal
        view
        returns (uint256)
    {
        if (!discountsEnabled) return 0;
        uint256 stake = stakingManager.balanceOf(u, address(stakedToken));
        uint256 percent = 0;
        uint256 length = discountSlabs.length;
        for (uint256 i = 0; i < length; i++) {
            if (stake >= discountSlabs[i].amount) {
                percent = discountSlabs[i].percent;
            } else {
                break;
            }
        }
        return (a * percent * PRECISION) / PERCENT;
    }

    /**
     * @notice change build time rate
     * @param r new build time rate
     */
    function changeBuildTimeRate(uint256 r) public onlyGovernanceAddress {
        require(r != 0, "ArgoPayments: Price per microsecond can not be zero");
        buildTimeRate = r;
    }

    /**
     * @notice update staked token address
     * @param s new staked token address
     */
    function updateStakedToken(address s) public onlyGovernanceAddress {
        require(
            s != address(0),
            "ArgoPayments: staked token address can not be zero address"
        );
        stakedToken = IERC20(s);
    }

    /**
     * @notice update oracle feeder address
     * @param o new oracle feeder
     */
    function updateFeederAddress(address o) public onlyGovernanceAddress {
        require(
            o != address(0),
            "ArgoPayments: oracle feeder address can not be zero address"
        );
        priceFeed = IDiaOracle(o);
    }

    /**
     * @notice update oracle feeder symbol
     * @param s symbol of token
     */
    function updateFeederTokenSymbol(string memory s)
        public
        onlyGovernanceAddress
    {
        require(
            bytes(s).length != 0,
            "ArgoPayments: symbol length can not be zero"
        );
        feederSymbol = s;
    }

    /**
     * @notice update underlying token address
     * @param u underlying token address
     */
    function updateUnderlyingToken(address u) public onlyGovernanceAddress {
        require(
            u != address(0),
            "ArgoPayments: token address can not be zero address"
        );
        underlying = IERC20(u);
    }

    /**
     * @notice enable discounts for users.
     * @param s address of staking manager
     */
    function enableDiscounts(address s) public onlyManager {
        require(
            s != address(0),
            "ArgoPayments: staking manager address can not be zero address"
        );
        discountsEnabled = true;
        stakingManager = IStaking(s);
    }

    /**
     * @notice disable discounts for users
     */
    function disableDiscounts() public onlyManager {
        discountsEnabled = false;
    }

    /**
     * @notice get price of underlying token
     * @return price of underlying token in usd
     */
    function getUnderlyingPrice() public view returns (uint256) {
        (uint128 price, uint128 timeStamp) = priceFeed.getValue(
            feederSymbol
        );
        return uint256(price) * (10**10);
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
            "ArgoPayments: Insufficient tokens in contract"
        );
        erc20.transfer(msg.sender, a);
    }
}
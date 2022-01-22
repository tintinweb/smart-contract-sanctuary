/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: Apache-2.0

/*

  /$$$$$$          /$$                     /$$$$$$$   /$$$$$$   /$$$$$$ 
 /$$__  $$        |__/                    | $$__  $$ /$$__  $$ /$$__  $$
| $$  \__//$$$$$$  /$$  /$$$$$$   /$$$$$$$| $$  \ $$| $$  \ $$| $$  \ $$
| $$$$   /$$__  $$| $$ /$$__  $$ /$$_____/| $$  | $$| $$$$$$$$| $$  | $$
| $$_/  | $$  \__/| $$| $$$$$$$$|  $$$$$$ | $$  | $$| $$__  $$| $$  | $$
| $$    | $$      | $$| $$_____/ \____  $$| $$  | $$| $$  | $$| $$  | $$
| $$    | $$      | $$|  $$$$$$$ /$$$$$$$/| $$$$$$$/| $$  | $$|  $$$$$$/
|__/    |__/      |__/ \_______/|_______/ |_______/ |__/  |__/ \______/ 

*/

pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
// FRIES token interface

interface IFriesDAOToken is IERC20 {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract FriesDAOTokenSale is ReentrancyGuard, Ownable {

    IERC20 public immutable USDC;                // USDC token
    IFriesDAOToken public immutable FRIES;       // FRIES token
    uint256 public constant FRIES_DECIMALS = 18; // FRIES token decimals
    uint256 public constant USDC_DECIMALS = 6;   // USDC token decimals

    bool public whitelistSaleActive = false;
    bool public publicSaleActive = false;
    bool public redeemActive = false;
    bool public refundActive = false;

    uint256 public salePrice;           // Sale price of FRIES per USDC
    uint256 public baseWhitelistAmount; // Base whitelist amount of USDC available to purchase
    uint256 public totalCap;            // Total maximum amount of USDC in sale
    uint256 public totalPurchased = 0;  // Total amount of USDC purchased in sale

    mapping (address => uint256) public whitelist; // Mapping of account to whitelisted purchase amount in USDC in whitelisted sale
    mapping (address => uint256) public purchased; // Mapping of account to total purchased amount in FRIES
    mapping (address => uint256) public redeemed;  // Mapping of account to total amount of redeemed FRIES
    mapping (address => bool) public vesting;      // Mapping of account to vesting of purchased FRIES after redeem

    address public treasury;       // friesDAO treasury address
    uint256 public vestingPercent; // Percent tokens vested /1000

    // Events

    event WhitelistSaleActiveChanged(bool active);
    event PublicSaleActiveChanged(bool active);
    event RedeemActiveChanged(bool active);
    event RefundActiveChanged(bool active);

    event SalePriceChanged(uint256 price);
    event BaseWhitelistAmountChanged(uint256 baseWhitelistAmount);
    event TotalCapChanged(uint256 totalCap);

    event Purchased(address indexed account, uint256 amount);
    event Redeemed(address indexed account, uint256 amount);
    event Refunded(address indexed account, uint256 amount);

    event TreasuryChanged(address treasury);
    event VestingPercentChanged(uint256 vestingPercent);

    // Initialize sale parameters

    constructor(address usdcAddress, address friesAddress, address treasuryAddress) {
        USDC = IERC20(usdcAddress);           // USDC token
        FRIES = IFriesDAOToken(friesAddress); // Set FRIES token contract

        salePrice = 42;                                   // 42 FRIES per USDC
        baseWhitelistAmount = 5000 * 10 ** USDC_DECIMALS; // Base 5,000 USDC purchasable for a whitelisted account
        totalCap = 18696969 * 10 ** USDC_DECIMALS;        // Total 18,696,969 max USDC raised

        treasury = treasuryAddress; // Set friesDAO treasury address
        vestingPercent = 850;       // 85% vesting for vested allocations
    }

    /*
     * ------------------
     * EXTERNAL FUNCTIONS
     * ------------------
     */

    // Buy FRIES with USDC in whitelisted token sale

    function buyWhitelistFries(uint256 value) external {
        require(whitelistSaleActive, "FriesDAOTokenSale: whitelist token sale is not active");
        require(value > 0, "FriesDAOTokenSale: amount to purchase must be larger than zero");
        require(purchased[_msgSender()] + value <= whitelist[_msgSender()], "FriesDAOTokenSale: amount over whitelist limit");

        USDC.transferFrom(_msgSender(), treasury, value);                            // Transfer USDC amount to treasury
        uint256 amount = value * 10 ** (FRIES_DECIMALS - USDC_DECIMALS) * salePrice; // Calculate amount of FRIES at sale price with USDC value
        purchased[_msgSender()] += amount;                                           // Add FRIES amount to purchased amount for account
        totalPurchased += value;                                                     // Add USDC amount to total USDC purchased

        emit Purchased(_msgSender(), amount);
    }

    // Buy FRIES with USDC in public token sale

    function buyFries(uint256 value) external {
        require(publicSaleActive, "FriesDAOTokenSale: public token sale is not active");
        require(value > 0, "FriesDAOTokenSale: amount to purchase must be larger than zero");
        require(totalPurchased + value < totalCap, "FriesDAOTokenSale: amount over total sale limit");

        USDC.transferFrom(_msgSender(), treasury, value);                            // Transfer USDC amount to treasury
        uint256 amount = value * 10 ** (FRIES_DECIMALS - USDC_DECIMALS) * salePrice; // Calculate amount of FRIES at sale price with USDC value
        purchased[_msgSender()] += amount;                                           // Add FRIES amount to purchased amount for account
        totalPurchased += value;                                                     // Add USDC amount to total USDC purchased

        emit Purchased(_msgSender(), amount);
    }

    // Redeem purchased FRIES for tokens

    function redeemFries() external {
        require(redeemActive, "FriesDAOTokenSale: redeeming for tokens is not active");

        uint256 amount = purchased[_msgSender()] - redeemed[_msgSender()]; // Calculate redeemable FRIES amount
        require(amount > 0, "FriesDAOTokenSale: invalid redeem amount");
        redeemed[_msgSender()] += amount;                                  // Add FRIES redeem amount to redeemed total for account

        if (!vesting[_msgSender()]) {
            FRIES.transfer(_msgSender(), amount);                                  // Send redeemed FRIES to account
        } else {
            FRIES.transfer(_msgSender(), amount * (1000 - vestingPercent) / 1000); // Send available FRIES to account
            FRIES.transfer(treasury, amount * vestingPercent / 1000);              // Send vested FRIES to treasury
        }

        emit Redeemed(_msgSender(), amount);
    }

    // Refund FRIES for USDC at sale price

    function refundFries(uint256 amount) external nonReentrant {
        require(refundActive, "FriesDAOTokenSale: refunding redeemed tokens is not active");
        require(redeemed[_msgSender()] >= amount, "FriesDAOTokenSale: refund amount larger than tokens redeemed");

        FRIES.burnFrom(_msgSender(), amount);                                                       // Remove FRIES refund amount from account
        purchased[_msgSender()] -= amount;                                                          // Reduce purchased amount of account by FRIES refund amount
        redeemed[_msgSender()] -= amount;                                                           // Reduce redeemed amount of account by FRIES refund amount
        USDC.transfer(_msgSender(), (amount / 10 ** (FRIES_DECIMALS - USDC_DECIMALS)) / salePrice); // Send refund USDC amount at sale price to account
        
        emit Refunded(_msgSender(), amount);
    }

    /*
     * --------------------
     * RESTRICTED FUNCTIONS
     * --------------------
     */

    // Set whitelist sale enabled status

    function setWhitelistSaleActive(bool active) external onlyOwner {
        whitelistSaleActive = active;
        emit WhitelistSaleActiveChanged(whitelistSaleActive);
    }

    // Set public sale enabled status

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit PublicSaleActiveChanged(publicSaleActive);
    }

    // Set redeem enabled status

    function setRedeemActive(bool active) external onlyOwner {
        redeemActive = active;
        emit RedeemActiveChanged(redeemActive);
    }

    // Set refund enabled status

    function setRefundActive(bool active) external onlyOwner {
        refundActive = active;
        emit RefundActiveChanged(refundActive);
    }

    // Change sale price

    function setSalePrice(uint256 price) external onlyOwner {
        salePrice = price;
        emit SalePriceChanged(salePrice);
    }

    // Change base whitelist amount

    function setBaseWhitelistAmount(uint256 amount) external onlyOwner {
        baseWhitelistAmount = amount;
        emit BaseWhitelistAmountChanged(baseWhitelistAmount);
    }

    // Change sale total cap

    function setTotalCap(uint256 amount) external onlyOwner {
        totalCap = amount;
        emit TotalCapChanged(totalCap);
    }

    // Whitelist accounts with base whitelist allocation

    function whitelistAccounts(address[] calldata accounts) external onlyOwner {
        for (uint256 a = 0; a < accounts.length; a ++) {
            whitelist[accounts[a]] = baseWhitelistAmount;
        }
    }

    // Whitelist accounts with custom whitelist allocation and vesting

    function whitelistAccountsWithAllocation(
        address[] calldata accounts,
        uint256[] calldata allocations,
        bool[] calldata vestingEnabled
    ) external onlyOwner {
        for (uint256 a = 0; a < accounts.length; a ++) {
            whitelist[accounts[a]] = allocations[a];
            vesting[accounts[a]] = vestingEnabled[a];
        }
    }

    // Change friesDAO treasury address

    function setTreasury(address treasuryAddress) external {
        require(_msgSender() == treasury, "FriesDAOTokenSale: caller is not the treasury");
        treasury = treasuryAddress;
        emit TreasuryChanged(treasury);
    }

    // Change vesting percent

    function setVestingPercent(uint256 percent) external onlyOwner {
        vestingPercent = percent;
        emit VestingPercentChanged(vestingPercent);
    }

}
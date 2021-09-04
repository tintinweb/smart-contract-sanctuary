/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// Dependency file: contracts\libraries\Context.sol

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.7;

// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol.
// Subject to the MIT license.

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


// Dependency file: contracts\libraries\Ownable.sol

// pragma solidity ^0.8.7;

// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol.
// Subject to the MIT license.

// import 'contracts\libraries\Context.sol';

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Dependency file: contracts\interfaces\IPancakePair.sol

// pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


// Root file: contracts\PolarfoxPrivateSale.sol

pragma solidity 0.8.7;

// To do list
// #3: Whitelist system
// #4: Presale end function

// import 'contracts\libraries\Ownable.sol';
// import 'contracts\interfaces\IPancakePair.sol';

struct TransactionData {
    uint256 boughtAmount;
    uint256 dateBought;
    address buyingAddress;
    address receivingAddress;
}

/**
 * The Polarfox private token sale 🦊
 * 10,000,000 PFX will be offerred for sale before launch, 1,000,000 of which will be sold through
 * this contract.
 *
 * The price in this presale is set as $1 per PFX, which is low when compared to the rest of the sale.
 * The tokens sold through this contract will not be delivered immediately, but rather locked then
 * vested through several years.
 *
 * The code of this contract is a diluted version of PolarfoxTokenSale.
 */
contract PolarfoxPrivateSale is Ownable {
    /// @notice The address that receives the money from the sale
    address payable public sellRecipient;

    /// @notice The addresses that participated in the sale
    address[] public buyers;

    /// @notice True if an address has bought tokens in the sale, false otherwise
    mapping(address => bool) public hasBought;

    /// @notice The list of transactions that occurred on the sale
    TransactionData[] public transactions;

    /// @notice Returns the transactions for each receiving address
    mapping(address => TransactionData[]) public transactionsForReceivingAddress;

    /// @notice True if the sale is active, false otherwise
    bool public isSaleActive;

    /// @notice BNB/USDT price
    uint256 public currentBnbPrice;

    /// @notice Sold amount so far
    uint256 public soldAmount;

    /// @notice Total amount of tokens to sell
    uint256 public amountToSell = 1_000_000e18; // 1,000,000 PFX / USD

    /// @notice True if an address is whitelisted and can participate in the private sale
    mapping(address => bool) public isWhitelisted;

    /// @notice An event that is emitted when some tokens are bought
    event Sold(uint256 boughtAmount, uint256 dateBought, address buyingAddress, address receivingAddress);

    /// @notice An event that is emitted when sale funds are collected
    event SaleCollected(uint256 collectedAmount);

    /// @notice An event that is emitted when the sale is started
    event SaleStarted();

    /// @notice An event that is emitted when the sale is stopped
    event SaleStopped();
    
    /// @notice An event that is emitted when an address is whitelisted
    event WhitelistedAddress(address _address);
    
    /// @notice An event that is emitted when an address is blacklisted
    event BlacklistedAddress(address _address);

    constructor(address payable sellRecipient_, uint256 currentBnbPrice_) {
        // Initialize values
        sellRecipient = sellRecipient_;
        isSaleActive = false;
        soldAmount = 0;
        currentBnbPrice = currentBnbPrice_;
    }

    // Public methods

    // Returns the number of buyers participating in the sale
    function numberOfBuyers() public view returns (uint256) {
        return buyers.length;
    }

    // Returns the number of transactions in the sale
    function numberOfTransactions() public view returns (uint256) {
        return transactions.length;
    }

    // Returns the number of transactions a given address has made
    function numberOfTransactionsForReceivingAddress(address _address) public view returns (uint256) {
        return transactionsForReceivingAddress[_address].length;
    }

    // Buys tokens in the sale - msg.sender receives the tokens
    function buyTokens() public payable {
        buyTokens(msg.sender);
    }

    // Buys tokens in the sale - recipient receives the tokens
    function buyTokens(address recipient) public payable {
        // Convert the amount from BNB to USD
        uint256 amountUsd = msg.value * currentBnbPrice;

        _buyTokens(recipient, amountUsd);
    }
    
    // Collects the sale funds
    function collectSale() public {
        require(address(this).balance > 0, 'PolarfoxPrivateSale::collectSale: Nothing to collect');

        emit SaleCollected(address(this).balance);

        // Transfer the sale funds
        sellRecipient.transfer(address(this).balance);
    }

    // Private methods

    // Mechanism for buying tokens in the sale
    function _buyTokens(address recipient, uint256 amountUsd) private {
        // Safety checks
        require(amountUsd > 0, 'PolarfoxPrivateSale::_buyTokens: Cannot buy 0 PFX tokens');
        require(isSaleActive, 'PolarfoxPrivateSale::_buyTokens: Sale has not started or is finished');
        require(amountUsd + soldAmount <= amountToSell, 'PolarfoxPrivateSale::_buyTokens: Only 1,000,000 PFX tokens to sell');
        require(isWhitelisted[msg.sender], 'PolarfoxPrivateSale::_buyTokens: Buying address is not whitelisted');

        // Add the buyer to the list of buyers if needed
        if (!hasBought[recipient]) {
            buyers.push(recipient);
            hasBought[recipient] = true;
        }

        soldAmount += amountUsd;

        // Create the transaction
        TransactionData memory transaction = TransactionData(amountUsd, block.timestamp, msg.sender, recipient);

        // Append the transaction to the lists of transactions
        transactions.push(transaction);
        transactionsForReceivingAddress[recipient].push(transaction);

        emit Sold(amountUsd, block.timestamp, msg.sender, recipient);
    }

    // Owner methods

    // Updates the price of BNB manually. Only callable by the owner
    function updateCurrentBnbPrice(uint256 currentBnbPrice_) public onlyOwner {
        currentBnbPrice = currentBnbPrice_;
    }

    // Starts the sale. Only callable by the owner
    function startSale() public onlyOwner {
        isSaleActive = true;

        emit SaleStarted();
    }

    // Stops the sale. Only callable by the owner
    function stopSale() public onlyOwner {
        isSaleActive = false;

        emit SaleStopped();
    }

    // Whitelists an address. Only callable by the owner
    function whitelistAddress(address _address) public onlyOwner {
        isWhitelisted[_address] = true;

        emit WhitelistedAddress(_address);
        
    }

    // Blacklists an address. Only callable by the owner
    function blacklistAddress(address _address) public onlyOwner {
        isWhitelisted[_address] = false;

        emit BlacklistedAddress(_address);
    }
}
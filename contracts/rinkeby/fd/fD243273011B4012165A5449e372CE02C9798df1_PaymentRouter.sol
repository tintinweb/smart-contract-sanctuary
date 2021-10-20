// SPDX-License-Identifier: MIT
//
//   $$\     $$\                       $$\ $$\                      $$$$$$\                          $$\     $$\       
//   $$ |    $$ |                      $$ |\__|                    $$$ __$$\                         $$ |    $$ |      
// $$$$$$\   $$$$$$$\   $$$$$$\   $$$$$$$ |$$\ $$$$$$$\   $$$$$$\  $$$$\ $$ |$$\   $$\     $$$$$$\ $$$$$$\   $$$$$$$\  
// \_$$  _|  $$  __$$\ $$  __$$\ $$  __$$ |$$ |$$  __$$\ $$  __$$\ $$\$$\$$ |\$$\ $$  |   $$  __$$\\_$$  _|  $$  __$$\ 
//   $$ |    $$ |  $$ |$$$$$$$$ |$$ /  $$ |$$ |$$ |  $$ |$$ /  $$ |$$ \$$$$ | \$$$$  /    $$$$$$$$ | $$ |    $$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$   ____|$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ |\$$$ | $$  $$<     $$   ____| $$ |$$\ $$ |  $$ |
//   \$$$$  |$$ |  $$ |\$$$$$$$\ \$$$$$$$ |$$ |$$ |  $$ |\$$$$$$$ |\$$$$$$  /$$  /\$$\ $$\\$$$$$$$\  \$$$$  |$$ |  $$ |
//    \____/ \__|  \__| \_______| \_______|\__|\__|  \__| \____$$ | \______/ \__/  \__|\__|\_______|  \____/ \__|  \__|
//                                                       $$\   $$ |                                                    
//                                                       \$$$$$$  |                                                    
//                                                        \______/                                                     
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Automatic payment router
/// @author theding0x.eth
/// @notice This contract is only useable by the owner
contract PaymentRouter is Ownable {
    struct Wallet {
        address payable addr;
        uint128 rate;
    }
    mapping(uint => Wallet) private wallet;

    event PaymentReceived(address indexed _from, uint _value);
    event PaymentDistributed(address indexed _from, address primary, address tax, address savings, uint withheld, uint net, uint saved);
    event RatesChanged(address indexed _from, uint64 newTaxRate, uint64 newSavingsRate);

    /**
        @notice Creates a new instance of the payment router.
        @param _taxWallet Address to send withheld amount for taxes
        @param _primaryWallet Address to send funds after savings and taxes are withheld
        @param _savingsWallet Address to send withheld amount for savings
        @param _taxRate The amount to withhold for taxes as a whole percentage
        @param _savingsRate The ammount to withhold for savings as a whole percentage
     */
    constructor(address payable _taxWallet, address payable _primaryWallet, address payable _savingsWallet, uint64 _taxRate, uint64 _savingsRate) {
        
        uint128 primaryRate = getPrimaryRate(_taxRate, _savingsRate); // Calculate the primary rate from the tax and savings rate

        wallet[0] = Wallet(_taxWallet,_taxRate);            // Set tax wallet address and rate
        wallet[1] = Wallet(_savingsWallet, _savingsRate);   // Set savings wallet address and rate
        wallet[2] = Wallet(_primaryWallet, primaryRate);     // Set primary wallet address and rate
    }
    /**
        @notice Finds the primary rate based on the tax and savings rates
        @dev The sum of both rates cannot equal more than 100
        @return uint64
     */
    function getPrimaryRate(uint64 taxRate, uint64 savingsRate) private pure returns(uint64) {
        uint64 totalWithheld = taxRate + savingsRate;
        require(totalWithheld <= 100 && totalWithheld >= 0, "Invalid tax/savings rates");   // Require total withheld to be between 0-100
        uint64 primaryRate = 100 - totalWithheld;
        return primaryRate;
    }
    /**
        @notice Takes the gross pay and distributes it based on the set tax and savings rates
        @param gross The gross amount paid

     */
    function distributePayment(uint gross) private {
        uint taxable = gross / wallet[0].rate;
        uint netpay = msg.value - taxable;
        uint savings = netpay / wallet[1].rate;
        netpay -= savings;

        wallet[0].addr.transfer(taxable);
        wallet[1].addr.transfer(savings);
        wallet[2].addr.transfer(netpay);

        emit PaymentDistributed(msg.sender, wallet[2].addr, wallet[0].addr, wallet[1].addr, taxable, netpay, savings);
    }
    /**
        @notice Set the rates of the wallets
        @param taxRate Desired rate to withhold funds for taxes
        @param savingsRate Desired rate to withhold funds for savings
     */
    function setRates(uint64 taxRate, uint64 savingsRate) public onlyOwner {
        uint128 primaryRate = getPrimaryRate(taxRate, savingsRate);
        wallet[0].rate = taxRate;
        wallet[1].rate = savingsRate;
        wallet[2].rate = primaryRate;
        
        emit RatesChanged(msg.sender, taxRate, savingsRate);
    }
    /**
        @notice Set the wallet address of a specified wallet
        @param id Wallet ID
        @param addr New address for the wallet
     */
    function setWalletAddress(uint id, address payable addr) external onlyOwner {
        require(id < 3 && id >= 0, "Id must be between 0-2");
        wallet[id].addr = addr;
    }
    /**
        @notice Looks up wallet information by wallet id and returns a struct
        @param id ID for the wallet being viewed
        @dev Value must be 0, 1, or 2
        @return Wallet
     */
    function getWallet(uint id) public view onlyOwner returns(Wallet memory) {
        require(id >=0 && id < 3, "Invalid wallet ID");
        return wallet[id];
    }
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
        distributePayment(msg.value);
    }
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
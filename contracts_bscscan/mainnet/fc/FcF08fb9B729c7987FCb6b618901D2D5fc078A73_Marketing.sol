/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

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

// File: SuperUP_donations.sol


pragma solidity 0.8.4;


contract SuperUP {
    uint public marketingFee;
}


contract Marketing is Ownable{
    address public _superUpToken = 0x2B912f87E72A7ec9F303e5315f7A297132Ebd8FD; //superUPToken
    address public _donationWallet = 0x8B99F3660622e21f2910ECCA7fBe51d654a1517D; //Binance charity Mainnet
    address public _marketingWallet = 0xf1DE7ed4a1A9C0dAe1365279Ffbf18a7a0C2e36E;
    
    uint public _donationFee = 1;
    uint public donations;
    
    event Donation(uint);
    
    constructor () {
    }
    
    function setDonationWallet(address donationWallet) external onlyOwner() {
        require(donationWallet != address(0), "Not address(0)");
        _donationWallet = donationWallet;
    }
    
    function setMarketingWallet(address marketingWallet) external onlyOwner() {
        require(marketingWallet != address(0), "Not address(0)");
        _marketingWallet = marketingWallet;
    }
    
    function setTokenAddress(address tokenAddress) external onlyOwner() {
        require(tokenAddress != address(0), "Not address(0)");
        _superUpToken = tokenAddress;
    }
    
    function setDonationFee(uint donationFee) external onlyOwner() {
        _donationFee = donationFee;
    }
    
    function resetDonations() external onlyOwner() {
        donations = 0;
    }
    
    receive() external payable {
        uint marketingFee = SuperUP(_superUpToken).marketingFee();
    
        uint donation = msg.value / marketingFee * _donationFee;
        uint rest = msg.value - donation;
        donations = donations + donation;
        
        payable(_donationWallet).call{ value: donation }('');
        payable(_marketingWallet).call{ value: rest }('');
        
        emit Donation(donation);
    }
    
    // Withdraw ETH that gets stuck in contract by accident
    function emergencyWithdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(_marketingWallet).call{ value: balance }('');
    }
}
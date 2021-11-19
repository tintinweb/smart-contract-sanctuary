//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is Ownable,ReentrancyGuard {

    address treasuryAddress;
    bool public isWhiteListEnabled;
    bool public isHardCapEnabled;
    uint256 hardcap;
    uint256 totalPayments;
    uint256 public minAmountForPurchase;
    uint256 public maxAmountPerAddress;

    address[] public recievingPresaleWalletAddress;
    mapping(address=>uint256) public Deposits;
    mapping(address=>uint256) public Recieving;
    mapping(address => bool) public isWhiteListed;

    event AddedToWhiteList(address indexed whitelistAddress);
    event RemovedFromWhiteList(address indexed removedAddress);

    constructor(address _treasuryAddress, uint256 _hardcap, bool _isWhiteListEnabled, bool _isHardCapEnabled,
        uint256 _minAmountForPurchase, uint256 _maxAmountPerAddress) {
        treasuryAddress = _treasuryAddress;
        hardcap = _hardcap;
        isWhiteListEnabled = _isWhiteListEnabled;
        isHardCapEnabled = _isHardCapEnabled;
        minAmountForPurchase = _minAmountForPurchase;
        maxAmountPerAddress = _maxAmountPerAddress;
    }

    function setTreasuryAddress(address walletAddress_) external onlyOwner {
        require(walletAddress_ != address(0),"Error : treasury address set to 0");
        treasuryAddress = walletAddress_;
    }

    function addAddressTowhitelistAddress(address[] memory whitelistaddress_) external onlyOwner{
        for (uint256 i = 0; i < whitelistaddress_.length; i++) {
            if (!isWhiteListed[whitelistaddress_[i]]) {
                isWhiteListed[whitelistaddress_[i]] = true;
                emit AddedToWhiteList(whitelistaddress_[i]);
            }
        }
    }

    function removeAddressFromWhitelist(address removeAddress_) external onlyOwner{
        require(isWhiteListed[removeAddress_],"Error : address is not whitelisted");
        isWhiteListed[removeAddress_] = false;
        emit RemovedFromWhiteList(removeAddress_);
    }

    function setStatusWhiteList(bool status_) external onlyOwner{
        isWhiteListEnabled=status_;
    }

    function buyFromPresale(address recievingTokenWallet_) external payable{
        require((msg.value >= minAmountForPurchase && Deposits[_msgSender()] + msg.value <= maxAmountPerAddress),
            "error: Wrong amount,ensure that the sent amount is within set limits");
        if(isHardCapEnabled){
            require(totalPayments+msg.value<=hardcap,"Error: hardcap exceeded");
        }
        if (isWhiteListEnabled){
            require(isWhiteListed[_msgSender()],"Error: you are not whitelisted");
        } 
        recievingPresaleWalletAddress.push(recievingTokenWallet_);
        totalPayments+=msg.value;
        Deposits[_msgSender()]+=msg.value;
        Recieving[recievingTokenWallet_]+=msg.value;
    }

    function ejectBnb() public onlyOwner {
        require(treasuryAddress != address(0), "treasury address not set");
        (bool sent, ) = treasuryAddress.call{value: address(this).balance}("");
        require(sent, "failed to send funds");
    }

    function setMaxAmountPerAddress(uint256 amount_) external onlyOwner{
        maxAmountPerAddress=amount_;
    }

    function setMinAmountForPurchase(uint256 amount_) external onlyOwner{
        minAmountForPurchase=amount_;
    }

    function setIsHardCapEnabled(bool status_) public onlyOwner{
        isHardCapEnabled=status_;
    }

    function setHardCap(uint256 hardcap_) external onlyOwner{  
        hardcap=hardcap_;
    }

    function getHardCap() public view returns(uint256){
        return hardcap;
    }

    function getTotalPayments() public view returns(uint256){
        return totalPayments;
    }
    
    function getAllRecievingAddress() external view returns (address[] memory){
        return recievingPresaleWalletAddress;
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

// SPDX-License-Identifier: MIT

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
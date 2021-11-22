/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

contract UnsealMe is Context, Ownable, ReentrancyGuard {

    //this contract's balance
    uint256 public thisBalance;

    //is UnSealMe is already initialized?
    bool public isInitialized = false;

    //is UnSealMe is already unsealed?
    bool public isUnsealMeDone = false;

    //the percentage of amount to be collected from the new unsealer
    //formula: PayableAmount = currentBalance * (_entryPricePercentage in %)
    uint256 public _entryPricePercentage;

    //the percentage of amount to be collected from the PayableAmount for the creator
    //formula: PayableCreatorAmount = PayableAmount * (_creatorPercentage in %)
    uint256 public _creatorPercentage;

    //the address of wallet that collects creator fees
    address public _creator;

    //the unsealing time
    uint public _unsealMinutes;

    //the end time of current unsealing
    uint public _unsealTimeEnd;

    //the address of latest unsealer
    address public _latestUnsealer;

    event UnsealCalled(uint newUnsealTimeEnd, address newLatestUnsealer, uint256 newBalance, uint256 newPayableAmount);

    fallback() external payable {
        unseal();
    }

    receive() external payable {
        unseal();
    }

    function init(uint256 entryPricePercentage, uint256 creatorPercentage, address creator, uint unsealMinutes) external payable onlyOwner() {
        require(!isInitialized, "UnsealMe is already initialized");

        _entryPricePercentage = entryPricePercentage;
        _creatorPercentage = creatorPercentage;
        _creator = creator;
        _unsealMinutes = unsealMinutes;
        _unsealTimeEnd = block.timestamp + _unsealMinutes;
        _latestUnsealer = _msgSender();
        thisBalance = msg.value;
        isInitialized = true;
        renounceOwnership();
    }

    function getPayableAmount() public view returns (uint256) {
        return ((address(this).balance) * _entryPricePercentage) / (10**2);
    }

    function getPayableCreatorAmount() public view returns (uint256) {
        return (getPayableAmount() * _creatorPercentage) / (10**2);
    }

    // low level function
    function unseal() public nonReentrant payable {
        uint256 SentAmount = msg.value;
        uint256 payableAmount = (thisBalance * _entryPricePercentage) / (10**2);
        uint256 payableCreatorAmount = (payableAmount * _creatorPercentage) / (10**2);

        require(isInitialized, "UnsealMe is not yet initialized");
        require(_msgSender() != address(0), "UnsealMe: The dead shall remain dead");
        require(block.timestamp < _unsealTimeEnd, "UnsealMe: Already unsealed and the reward waiting to be collected");
        require(!isUnsealMeDone, "UnsealMe: Already unsealed and the reward is already collected");
        require(payableAmount <= SentAmount, "UnsealMe: Please send exact amount or more than amount required");
 
        (payable(_msgSender())).transfer(SentAmount - payableAmount); // transfer back the change. collect only exact amount required.
        (payable(_creator)).transfer(payableCreatorAmount); // give some percentage of payableAmount to the creator
        
        _unsealTimeEnd = block.timestamp + _unsealMinutes; // update the _unsealTimeEnd
        _latestUnsealer = _msgSender(); // update the _latestUnsealer;

        thisBalance = (address(this).balance);
        emit UnsealCalled(_unsealTimeEnd, _latestUnsealer, (address(this).balance), ((address(this).balance) * _entryPricePercentage) / (10**2));
    }

    function claim() external{
        require(isInitialized, "UnsealMe is not yet initialized");
        require(_msgSender() != address(0), "UnsealMe: The dead shall remain dead");
        require(block.timestamp >= _unsealTimeEnd, "UnsealMe: Not yet done unsealing");
        require(!isUnsealMeDone, "UnsealMe: Already unsealed and the reward is already collected");
        require(_msgSender() == _latestUnsealer, "UnsealMe: Only the chosen one can collect the rewards");

        uint256 currentBalance = address(this).balance;
        uint256 PayableCreatorAmount = (currentBalance * _creatorPercentage) / (10**2);

        (payable(_creator)).transfer(PayableCreatorAmount); // give some percentage of currentBalance to the creator
        (payable(_latestUnsealer)).transfer(currentBalance - PayableCreatorAmount); // the reward of our work is not what we get, but what we become — Paulo Coelho

        thisBalance = (address(this).balance);
        isUnsealMeDone = true;
    }
}
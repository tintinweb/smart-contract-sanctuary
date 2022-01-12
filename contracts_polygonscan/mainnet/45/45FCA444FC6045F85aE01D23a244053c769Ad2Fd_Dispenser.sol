/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: Experimentation/Dispenser/dispenser.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



contract Dispenser is Ownable, ReentrancyGuard {

    /* This contract is designed to be used as a faucet with a level of authorization for testing purposes. 
        Please note that this contract is designed for development operations only and should not be used in 
        any implementations that handle user funds, and owner should be mindful of supplying the contract with large
        amounts of ether. Also worth mentioning that the contract makes considerable assumptions by making
        things more readable by displaying in ether terms, in lieu of wei terms. Obviously this causes losses in accuracy.
    */

    uint256 public interval; // the interval (in blocks) at which testers can retrieve fresh ether from dispenser
    uint256 public dispensedAmount; //the predetermined amount set by owner for how much ether to send to testers

    /*struct contains details about testers*/
    struct Tester{
        uint8 isApproved; //0 = no, 1 = yes
        uint256 lastRedeemed; //this var states the last time a tester redeemed gas from the dispenser
    }
    mapping (address => Tester) public tester;
      
    receive() external payable{}

    //ACCESS CONTROLLED FUNCTIONS
    
    //@dev used to add a new tester, authorize them, and set the last redeemed block to 0
    function approveForTesting(address _addressOfTester) public onlyOwner{
        tester[_addressOfTester] = Tester(1, 0);    
    }
    //@dev remove authorization for testers to receive ether from dispenser
    function removeTester(address _addressOfTester) public onlyOwner{
        require(tester[_addressOfTester].isApproved == 1, "Who dis?");
        tester[_addressOfTester] = Tester(0, 0);
    }

    //@dev use this function to alter the interval at which testers can redeem
    function setInterval(uint256 _newInterval) external onlyOwner {
        interval = _newInterval;
    }

    //@dev sets the amount sent to user in ethers
    function setDispensedAmount(uint256 _amount) public onlyOwner {
        uint256 dAmount = _amount*1e18;
        dispensedAmount = dAmount;
    }

    //@dev withdraw all ether from contract
    function withdrawEther() public onlyOwner{
        uint256 bal = address(this).balance;
        payable(msg.sender).transfer(bal);
    }

    //TESTER FUNCTIONS

    /*dispenses _amount ethers (in ether) to caller, checking to ensure that the caller is A) an approved tester and B) hasn't
    redeemed in the prescribed interval set by owner
    */ 

    //@dev use this function to fund the contract with ether
    function topUp() external payable {
        payable(address(this)).transfer(msg.value);
    }

    function dispense() public nonReentrant {
        require(tester[msg.sender].isApproved == 1, "Who dis?");
        require(block.number > tester[msg.sender].lastRedeemed + interval , "Does it look like Christmas?");
        tester[msg.sender].lastRedeemed = block.number;
        payable(msg.sender).transfer(dispensedAmount);
    }

    //VIEW FUNCTIONS

    /*returns balance in ether units*/
    function EthBalance() public view returns (uint256){ 
       uint256 bal = address(this).balance;
       return bal/1e18;
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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


interface IReferral {
    function hasReferrer(address user) external view returns (bool);
    function isLocked(address user) external view returns (bool);
    function lockAddress(address user) external;
    function setReferrer(address referrer) external;
    function getReferrer(address user) external view returns (address);
    function getReferredUsers(address referrer) external view returns (address[] memory) ;
}

contract PredictionReferral is IReferral, Ownable {
    //map of referred user to the their referrer
    mapping(address => address) public userReferrer; 
    //map of a user to an array of all users referred by them
    mapping(address => address[]) public referredUsers; 
    mapping(address => bool) public userExistence;
    mapping(address => bool) public userLocked;
    mapping(address => bool) public addressesAllowedToLock;
    uint public referrerCount;
    uint public referredCount;

    event PredictionsReferralEnable(address indexed user);
    event PredictionsSetReferrer(address indexed user, address indexed referrer);

    function addFactoryAddress(address _factoryAddress) external onlyOwner {
        require(_factoryAddress != address(0), 'cant add address 0');
        addressesAllowedToLock[_factoryAddress] = true;
    }

    function removeFactoryAddress(address _factoryAddress) external onlyOwner {
        require(_factoryAddress != address(0), 'cant remove address 0');
        addressesAllowedToLock[_factoryAddress] = false;
    }

    //address can only be locked from the factory contract
    function lockAddress(address user) override external {
        require(addressesAllowedToLock[msg.sender], "You dont have the permission to lock.");
        userLocked[user] = true;
    }

    function enableAddress() external {
        require(!userExistence[msg.sender], "This address is already enabled");
        userExistence[msg.sender] = true;

        emit PredictionsReferralEnable(msg.sender);
    }

    function setReferrer(address referrer) override external {
        require(userReferrer[msg.sender] == address(0), "You already have a referrer.");
        require(!userLocked[msg.sender], "You can not set a referrer after making a bet.");
        require(msg.sender != referrer, "You can not refer your own address.");
        require(userExistence[referrer], "The referrer address is not in the system.");
        userReferrer[msg.sender] = referrer;
        userLocked[msg.sender] = true;
        referredCount++;
        if(referredUsers[referrer].length == 0){
            referrerCount++;
        }
        referredUsers[referrer].push(msg.sender);

        emit PredictionsSetReferrer(msg.sender, referrer);
    }

    //GET FUNCTIONS

    function hasReferrer(address user) override external view virtual returns (bool) {
        return userReferrer[user] != address(0);
    }

    function isLocked(address user) override external view virtual returns (bool) {
        return userLocked[user];
    }

    function getReferrer(address user) override external view returns (address) {
        return userReferrer[user];
    }

    function getReferredUsers(address referrer) override external view returns (address[] memory) {
        return referredUsers[referrer];
    }
}
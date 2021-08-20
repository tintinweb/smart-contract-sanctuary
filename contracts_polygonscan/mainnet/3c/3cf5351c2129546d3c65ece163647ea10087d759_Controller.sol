/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// File: contracts\utils\ownable.sol

pragma solidity ^0.8.0;

// 

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
abstract contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // TODO: remove in production
    function destroyContract() public onlyOwner {
        selfdestruct(payable(address(uint160(msg.sender))));
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// File: contracts\utils\controller.sol

pragma solidity ^0.8.0;

// 


contract Controller is Ownable {
    mapping(address => bool) allowedContracts;
    mapping(bytes32 => bool) lockedAssets;

    constructor(address _newOwner) {
        transferOwnership(_newOwner);
    }
    function allowContracts(address[] memory contracts) onlyOwner public {
        for(uint256 i = 0; i < contracts.length; i++) allowedContracts[contracts[i]] = true;
    }

    function denyContracts(address[] memory contracts) onlyOwner public {
        for(uint256 i = 0; i < contracts.length; i++) allowedContracts[contracts[i]] = false;
    }

    function isAllowed(address _addr) view external returns (bool) {
        return allowedContracts[_addr];
    }

    function lock(address _addr, uint256 _id) external {
        require(allowedContracts[msg.sender], "access denied");
        bytes32 hash = sha256(abi.encodePacked(_addr, _id));
        bool isLocked = lockedAssets[hash];
        require(!isLocked, "already locked");
        lockedAssets[hash] = true;
    }

    function unlock(address _addr, uint256 _id) external {
        require(allowedContracts[msg.sender], "access denied");
        bytes32 hash = sha256(abi.encodePacked(_addr, _id));
        bool isLocked = lockedAssets[hash];
        require(isLocked, "already unlocked");
        lockedAssets[hash] = false;
    }
}
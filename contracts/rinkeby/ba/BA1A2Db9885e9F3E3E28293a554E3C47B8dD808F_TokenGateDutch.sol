// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface SnapshotToken {
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}

contract TokenGateDutch is Ownable {
    mapping(address => bool) public admins;
    address public tokenGateAddress;
    uint256 public endingThreshold;
    uint256 public startingThreshold;
    uint256 public auctionLengthInBlocks;
    uint256 public startBlock;
    uint256 public snapshotId;
    SnapshotToken private _snapshotToken;

    constructor() {
        admins[_msgSender()] = true;
        auctionLengthInBlocks = 4 * 60; // default to roughly an hour
    }

    function setTokenGateAddress(address _tokenGateAddress) external onlyAdmin {
        tokenGateAddress = _tokenGateAddress;
        _snapshotToken = SnapshotToken(_tokenGateAddress);
    }

    function setStartingThreshold(uint256 _threshold) external onlyAdmin {
        startingThreshold = _threshold;
    }

    function setEndingThreshold(uint256 _threshold) external onlyAdmin {
        endingThreshold = _threshold;
    }

    function setSnapshotId(uint256 _snapshotId) external onlyAdmin {
        snapshotId = _snapshotId;
    }

    function setStartBlock(uint256 blocknum) public onlyAdmin { // for testing
        startBlock = blocknum;
    }

    function start() external onlyAdmin {
        require(tokenGateAddress != address(0), "must gate a token");
        require(startingThreshold != 0, "there is no point to this if we start at zero");
        require(startingThreshold > endingThreshold, "end threshold must be greater than start");
        setStartBlock(block.number);
    }

    function getCurrentThreshold() public view returns (uint256) {
        return getThresholdAtBlock(startBlock, block.number, startingThreshold, endingThreshold, auctionLengthInBlocks);
    }

    function meetsThreshold(address sender) public view returns (bool) {
        return _snapshotToken.balanceOfAt(sender, snapshotId) > getCurrentThreshold();
    }

    function getThresholdAtBlock(
        uint _startBlock, 
        uint256 _currentBlock, 
        uint256 _startThresh, 
        uint256 _endThresh, 
        uint256 _auctionLen) public pure returns (uint256) {
        // todo: improve this, this is going to jump at the end.
        if (_currentBlock == _startBlock) {
            return _startThresh;
        }
        if (_currentBlock - _startBlock >= _auctionLen) {
            return _endThresh;
        }

        uint256 priceDropPerBlock = (_startThresh - _endThresh) / _auctionLen;
        uint256 blocksSinceStart = _currentBlock - _startBlock;

        if ((_startThresh - (blocksSinceStart * priceDropPerBlock)) < _endThresh) {
            return _endThresh;
        }
        return _startThresh - (blocksSinceStart * priceDropPerBlock);
    }


    /*
    * Admin Mgmt Functions
    */ 

    function isAdmin(address _admin) external view returns (bool) {
        return admins[_admin];
    }

    function addAdmin(address _admin) public onlyAdmin {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyAdmin {
        admins[_admin] = false;
    }

    modifier onlyAdmin {
        require(owner() == _msgSender() || admins[_msgSender()], "must be owner or admin");
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
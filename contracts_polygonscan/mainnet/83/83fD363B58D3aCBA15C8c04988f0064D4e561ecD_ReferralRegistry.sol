// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReferralRegistry is Ownable {
    event ReferralAnchorCreated(address indexed user, address indexed referee);
    event ReferralAnchorUpdated(address indexed user, address indexed referee);
    event AnchorManagerUpdated(address account, bool isManager);

    // stores addresses which are allowed to create new anchors
    mapping(address => bool) public isAnchorManager;

    // stores the address that referred a given user
    mapping(address => address) public referralAnchor;

    /// @dev create a new referral anchor on the registry
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function createReferralAnchor(address _user, address _referee) external onlyAnchorManager {
        require(referralAnchor[_user] == address(0), "ReferralRegistry: ANCHOR_EXISTS");
        referralAnchor[_user] = _referee;
        emit ReferralAnchorCreated(_user, _referee);
    }

    /// @dev allows admin to overwrite anchor
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function updateReferralAnchor(address _user, address _referee) external onlyOwner {
        referralAnchor[_user] = _referee;
        emit ReferralAnchorUpdated(_user, _referee);
    }

    /// @dev allows admin to grant/remove anchor priviliges
    /// @param _anchorManager address of the anchor manager
    /// @param _isManager add or remove privileges
    function updateAnchorManager(address _anchorManager, bool _isManager) external onlyOwner {
        isAnchorManager[_anchorManager] = _isManager;
        emit AnchorManagerUpdated(_anchorManager, _isManager);
    }

    function getUserReferee(address _user) external view returns (address) {
        return referralAnchor[_user];
    }

    function hasUserReferee(address _user) external view returns (bool) {
        return referralAnchor[_user] != address(0);
    }

    modifier onlyAnchorManager() {
        require(isAnchorManager[msg.sender], "ReferralRegistry: FORBIDDEN");
        _;
    }
}
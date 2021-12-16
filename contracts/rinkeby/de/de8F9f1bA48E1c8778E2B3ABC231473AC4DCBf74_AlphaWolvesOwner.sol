pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
 
interface IAlphaWolves {
  function balanceGenesis(address) external returns (uint256);
  function ownerOf(uint256) external returns (address);
}

interface IAlphaWolvesClone {
  function clone(address) external;
}

interface IAlphaWolvesStake {
  function stakeByIds(address, uint256[] memory) external;
  function unstakeAll(address) external;
  function unstakeByIds(address, uint256[] memory) external;
  function claimByTokenId(address, uint256) external;
  function claimAll(address) external;
  function getTokenEmissionRate(uint256) external pure returns (uint256);
  function viewAllRewards(address) external view returns (uint256);
  function viewRewardsByTokenId(uint256) external view returns (uint256);
  function viewStaker(uint256) external view returns (address);
}

contract AlphaWolvesOwner is Ownable {

    IAlphaWolvesStake public AlphaWolvesStake;
    IAlphaWolvesClone public AlphaWolvesClone;
    IAlphaWolves public AlphaWolves;

    modifier onlyWolfOwner() {
        uint256 wolvesOwned = AlphaWolves.balanceGenesis(msg.sender);
        require(wolvesOwned > 0, "You do not have any wolves to clone");
        _;
    }

    constructor() {}

    modifier onlyTokensOwner(uint256[] memory tokenIds) {
        //TODO verify this works
        for (uint256 i = 0; i < tokenIds.length; i++) {
          require(AlphaWolves.ownerOf(tokenIds[i]) == msg.sender, "token is not owned by you");
          _;
        }
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(AlphaWolves.ownerOf(tokenId) == msg.sender, "token is not owned by you");
        _;
    }

    function setAlphaWolfAddress(address alphaWolfAddress) external onlyOwner {
        AlphaWolves = IAlphaWolves(alphaWolfAddress);
    }

    function setStakeAddress(address stakeAddress) external onlyOwner {
        AlphaWolvesStake = IAlphaWolvesStake(stakeAddress);
    }

    function setCloneAddress(address cloneAddress) external onlyOwner {
        AlphaWolvesClone = IAlphaWolvesClone(cloneAddress);
    }

    function clone() external onlyWolfOwner {
        AlphaWolvesClone.clone(msg.sender);
    }

    function stakeByIds(uint256[] memory tokenIds) external onlyTokensOwner(tokenIds) {
        AlphaWolvesStake.stakeByIds(msg.sender, tokenIds);
    }

    function unstakeAll() external onlyWolfOwner {
        AlphaWolvesStake.unstakeAll(msg.sender);
    }
    
    function unstakeByIds(uint256[] memory tokenIds) external onlyTokensOwner(tokenIds) {
        AlphaWolvesStake.unstakeByIds(msg.sender, tokenIds);
    }

    function claimByTokenId(uint256 tokenId) external onlyTokenOwner(tokenId) {
        AlphaWolvesStake.claimByTokenId(msg.sender, tokenId);
    }

    function claimAll() external onlyWolfOwner {
        AlphaWolvesStake.claimAll(msg.sender);
    }

    function getTokenEmissionRate(uint256 tokenId) external view returns (uint256) {
        return AlphaWolvesStake.getTokenEmissionRate(tokenId);
    }

    function viewAllRewards() external view returns (uint256) {
        return AlphaWolvesStake.viewAllRewards(msg.sender);
    }
    function viewRewardsByTokenId(uint256 tokenId) external view returns (uint256) {
        return AlphaWolvesStake.viewRewardsByTokenId(tokenId);
    }

    function viewStaker(uint256 tokenId) external view returns (address) {
        return AlphaWolvesStake.viewStaker(tokenId);
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
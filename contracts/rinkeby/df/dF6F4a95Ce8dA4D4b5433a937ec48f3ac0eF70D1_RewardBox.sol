// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBatt {
    function mint(address account, uint amount) external;
}

contract RewardBox is Ownable {

    string public constant CONTRACT_NAME = "RewardBox";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(uint256[] withdrawalIds,uint256[] amounts,address user)");

    IBatt public batt;

    address public admin = 0x719deC089084C98d505695A2cdC82238024D0bAD;

    mapping(uint256 => bool) public withdrawal;

    event Withdraw(uint256 withdrawalId, uint256 amount, address user);

    constructor() {}

    function setBatt(IBatt _batt) external onlyOwner {
      batt = _batt;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
      admin = newAdmin;
    }

    function withdraw(uint256[] calldata withdrawalIds, uint256[] calldata amounts, address user, uint8 v, bytes32 r, bytes32 s) external {
      bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
      bytes32 structHash = keccak256(abi.encode(
        WITHDRAW_TYPEHASH,
        keccak256(abi.encodePacked(withdrawalIds)),
        keccak256(abi.encodePacked(amounts)),
        user
      ));
      bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
      address signatory = ecrecover(digest, v, r, s);
      require(signatory == admin, "Invalid signatory");

      uint256 total = 0;
      for (uint256 i = 0; i < withdrawalIds.length; i++) {
        uint256 id = withdrawalIds[i];
        if (!withdrawal[id] && amounts[i] > 0) {
          total += amounts[i];
          withdrawal[id] = true;
          emit Withdraw(id, amounts[i], user);
        }
      }

      if (total > 0) {
        batt.mint(user, total);
      }
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
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
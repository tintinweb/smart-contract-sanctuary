// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import { PerpFiOwnableUpgrade } from "./PerpFiOwnableUpgrade.sol";

contract PerpetualProtocolReferrer is PerpFiOwnableUpgrade {
    enum UpsertAction{ ADD, REMOVE, UPDATE }

    struct Referrer {
        uint256 createdAt;
        string referralCode;
        address createdBy;
    }

    struct Referee {
        string referralCode;
        uint256 createdAt;
        uint256 updatedAt;
    }

    event OnReferralCodeCreated (
        address createdBy,
        address createdFor,
        uint256 timestamp,
        string referralCode
    );

    event OnReferralCodeUpserted (
        address addr,
        UpsertAction action,
        uint256 timestamp,
        string newReferralCode,
        string oldReferralCode
    );

    mapping(address => Referrer) public referrerStore;
    mapping(address => Referee) public refereeStore;
    mapping(string => address) public referralCodeToReferrerMap;

    constructor() public {
        __Ownable_init();
    }

    function createReferralCode(address createdFor, string memory referralCode) external onlyOwner {
        address sender = msg.sender;
        uint256 timestamp = block.timestamp;
        require(bytes(referralCode).length > 0, "Provide a referral code.");
        require(createdFor != address(0x0), "Provide an address to create the code for.");
        referrerStore[createdFor] = Referrer(timestamp, referralCode, sender);
        referralCodeToReferrerMap[referralCode] = createdFor;
        emit OnReferralCodeCreated(sender, createdFor, timestamp, referralCode);
    }

    function getReferralCodeByReferrerAddress(address referralOwner) external view returns (string memory) {
        Referrer memory referrer = referrerStore[referralOwner];
        require(bytes(referrer.referralCode).length > 0, "Referral code doesn't exist");
        return (referrer.referralCode);
    }

    function getMyRefereeCode() public view returns (string memory) {
        Referee memory referee = refereeStore[msg.sender];
        require(bytes(referee.referralCode).length > 0, "You do not have a referral code");
        return (referee.referralCode);
    }

    function setReferralCode(string memory referralCode) public {
        address sender = msg.sender;
        address referrer = referralCodeToReferrerMap[referralCode];
        uint256 timestamp = block.timestamp;
        UpsertAction action;
        string memory oldReferralCode = referralCode;

        require(referrer != sender, "You cannot be a referee of a referral code you own");
        
        // the referee in we are performing the upserts for
        Referee storage referee = refereeStore[sender];

        // when referral code is supplied by the referee
        if (bytes(referralCode).length > 0) {
            // if mapping does not exist, referral code doesn't exist.
            require(referrer != address(0x0), "Referral code does not exist");

            // if there is a referral code already for that referee, update it with the supplied one
            if (bytes(referee.referralCode).length > 0) {
                oldReferralCode = referee.referralCode;
                referee.referralCode = referralCode;
                referee.updatedAt = timestamp;
                action = UpsertAction.UPDATE;
            } else {
                // if a code doesn't exist for the referee, create the referee
                refereeStore[sender] = Referee(referralCode, timestamp, timestamp);
                action = UpsertAction.ADD;
            }
        // if the referral is not supplied and referee exists, delete referee
        } else if (bytes(referee.referralCode).length > 0) {
            oldReferralCode = referee.referralCode;
            delete refereeStore[sender];
            action = UpsertAction.REMOVE;
        }

        if (bytes(referralCode).length == 0 && bytes(referee.referralCode).length == 0) {
            revert("No referral code was supplied or found.");
        }
        emit OnReferralCodeUpserted(sender, action, timestamp, referralCode, oldReferralCode);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import { ContextUpgradeSafe } from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

// copy from openzeppelin Ownable, only modify how the owner transfer
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
contract PerpFiOwnableUpgrade is ContextUpgradeSafe {
    address private _owner;
    address private _candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function candidate() public view returns (address) {
        return _candidate;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "PerpFiOwnableUpgrade: caller is not the owner");
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
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "PerpFiOwnableUpgrade: zero address");
        require(newOwner != _owner, "PerpFiOwnableUpgrade: same as original");
        require(newOwner != _candidate, "PerpFiOwnableUpgrade: same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "PerpFiOwnableUpgrade: candidate is zero address");
        require(_candidate == _msgSender(), "PerpFiOwnableUpgrade: not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
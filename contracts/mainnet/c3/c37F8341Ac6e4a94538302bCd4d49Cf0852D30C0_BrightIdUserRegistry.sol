// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import "./IUserRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BrightIdUserRegistry is Ownable, IUserRegistry {
    string private constant ERROR_NEWER_VERIFICATION =
        "NEWER VERIFICATION REGISTERED BEFORE";
    string private constant ERROR_NOT_AUTHORIZED = "NOT AUTHORIZED";
    string private constant ERROR_INVALID_VERIFIER = "INVALID VERIFIER";
    string private constant ERROR_INVALID_CONTEXT = "INVALID CONTEXT";

    bytes32 public context;
    address public verifier;

    struct Verification {
        uint256 time;
        bool isVerified;
    }
    mapping(address => Verification) public verifications;

    event SetBrightIdSettings(bytes32 context, address verifier);
    event Sponsor(address indexed addr);

    /**
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    constructor(bytes32 _context, address _verifier) public {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
    }

    /**
     * @notice Sponsor a BrightID user by context id
     * @param addr BrightID context id
     */
    function sponsor(address addr) public {
        emit Sponsor(addr);
    }

    /**
     * @notice Set BrightID settings
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    function setSettings(bytes32 _context, address _verifier)
        external
        onlyOwner
    {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
        emit SetBrightIdSettings(_context, _verifier);
    }

    /**
     * @notice Check a user is verified or not
     * @param _user BrightID context id used for verifying users
     */
    function isVerifiedUser(address _user)
        external
        view
        override
        returns (bool)
    {
        return verifications[_user].isVerified;
    }

    /**
     * @notice Register a user by BrightID verification
     * @param _context The context used in the users verification
     * @param _addrs The history of addresses used by this user in this context
     * @param _timestamp The BrightID node's verification timestamp
     * @param _v Component of signature
     * @param _r Component of signature
     * @param _s Component of signature
     */
    function register(
        bytes32 _context,
        address[] calldata _addrs,
        uint256 _timestamp,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(context == _context, ERROR_INVALID_CONTEXT);
        require(
            verifications[_addrs[0]].time < _timestamp,
            ERROR_NEWER_VERIFICATION
        );

        bytes32 message = keccak256(
            abi.encodePacked(_context, _addrs, _timestamp)
        );
        address signer = ecrecover(message, _v, _r, _s);
        require(verifier == signer, ERROR_NOT_AUTHORIZED);

        verifications[_addrs[0]].time = _timestamp;
        verifications[_addrs[0]].isVerified = true;
        for (uint256 i = 1; i < _addrs.length; i++) {
            // update time of all previous context ids to be sure no one can use old verifications again
            verifications[_addrs[i]].time = _timestamp;
            // set old verifications unverified
            verifications[_addrs[i]].isVerified = false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Interface of the registry of verified users.
 */
interface IUserRegistry {

  function isVerifiedUser(address _user) external view returns (bool);

}

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
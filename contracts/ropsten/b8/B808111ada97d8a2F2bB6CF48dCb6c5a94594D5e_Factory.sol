// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Organization.sol";

contract Factory is Ownable {
    event OrganizationAdded(address owner, address organization);

    address public clonableOrg;

    /**
     *@dev Set clonable contract address which uses as library
     *@param _clonableAddress: Organization contract address which uses as library
     */
    function setClonableOrg(address _clonableAddress) external onlyOwner {
        require(
            clonableOrg == address(0),
            "organization-contract-address-already-set"
        );
        clonableOrg = _clonableAddress;
    }

    /**
     *@dev Create organization by clone the contract
     */
    function createOrg() public {
        address clone = Clones.clone(clonableOrg);
        Organization newOrg = Organization(clone);
        newOrg.initiate(msg.sender);
        emit OrganizationAdded(msg.sender, clone);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Organization {
    event NewOwner(address newOwner);
    event AcceptOwner(address owner);
    event SendPay(address tokenAddr, address to, uint256 amount);

    address public owner;
    address private newOwner;
    mapping(address => bool) admins;

    /**
     * @dev To check the caller is organization owner
     */
    modifier onlyOwner {
        require(msg.sender == owner, "caller-is-not-organization-owner");
        _;
    }

    /**
     * @dev To check the caller is organization owner or admin
     */
    modifier isAuth {
        require(
            admins[msg.sender] || msg.sender == owner,
            "caller-is-not-admin-or-owner"
        );
        _;
    }

    /**
     * @dev Initiate organization with organization owner
     * @param _owner: Organization owner address
     */
    function initiate(address _owner) external {
        owner = _owner;
    }

    /**
     * @dev Change organization owner address
     * @param _newOwner: New owner address
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "already-an-owner");
        require(_newOwner != address(0), "not-valid-address");
        require(newOwner != _newOwner, "already-a-new-owner");
        newOwner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev Accept new owner of organization
     */
    function acceptOwner() external {
        require(newOwner != address(0), "not-valid-address");
        require(msg.sender == newOwner, "not-owner");
        owner = newOwner;
        newOwner = address(0);
        emit AcceptOwner(owner);
    }

    /**
     * @dev Add admin to organization
     * @param _newAdmin: Address will be added to admin list
     */
    function addAdmin(address _newAdmin) external onlyOwner {
        admins[_newAdmin] = true;
    }

    /**
     * @dev Remove admin from organization
     * @param _admin: Address will be removed from admin list
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    /**
     * @dev Send payment
     * @param _to: Address will receive payment
     * @param _tokenAddr: Token address
     * @param _amount: Transfer amount
     */
    function _send(
        address _to,
        address _tokenAddr,
        uint256 _amount
    ) internal {
        IERC20 token = IERC20(_tokenAddr);
        require(token.transfer(_to, _amount), "transfer-failed");
        emit SendPay(_tokenAddr, _to, _amount);
    }

    /**
     * @dev Send multiple payments
     * @param _to: Addresses will receive payment
     * @param _tokenAddr: Token addresses
     * @param _amount: Transfer amounts
     */
    function sendpay(
        address[] memory _to,
        address[] memory _tokenAddr,
        uint256[] memory _amount
    ) external isAuth returns (bool) {
        require(_to.length == _tokenAddr.length, "length-not-equal");
        require(_to.length == _amount.length, "length-not-equal");
        for (uint256 i = 0; i < _to.length; i++) {
            _send(_to[i], _tokenAddr[i], _amount[i]);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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


// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUserStorage.sol";


contract UserStorage is IUserStorage, Ownable {
    struct UserData {
        bytes32 user_root_hash;
        uint64 nonce;
        uint32 last_block_number;
        address pay_token;
    }

    string public name;
    address public PoS_Contract_Address;
    uint256 public lastProofRange = 10000;
    mapping(address => UserData) private _users;

    modifier onlyPoS() {
        require(msg.sender == PoS_Contract_Address, "Only PoS");
        _;
    }

    constructor(string memory _name, address _address) {
        name = _name;
        PoS_Contract_Address = _address;
    }

    function changePoS(address _new_address) public onlyOwner {
        PoS_Contract_Address = _new_address;
        emit ChangePoSContract(_new_address);
    }

    function getUserPayToken(address _user_address) public view override returns (address) {
        return _users[_user_address].pay_token;
    }

    function getUserLastBlockNumber(address _user_address) public view override returns (uint32) {
        if (_users[_user_address].last_block_number == 0) {
            return uint32(block.number - lastProofRange);
        }
        return _users[_user_address].last_block_number;
    }

    function getUserRootHash(address _user_address) public view override returns (bytes32, uint256) {
        return (
            _users[_user_address].user_root_hash,
            _users[_user_address].nonce
        );
    }

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _nonce,
        address _updater
    ) public override onlyPoS {
        require(
            _nonce >= _users[_user_address].nonce &&
            _user_root_hash != _users[_user_address].user_root_hash
        );

        _users[_user_address].user_root_hash = _user_root_hash;
        _users[_user_address].nonce = _nonce;

        emit ChangeRootHash(_user_address, _updater, _user_root_hash);
    }

    function updateLastBlockNumber(address _user_address, uint32 _block_number) public override onlyPoS {
        require(_block_number > _users[_user_address].last_block_number);
        if (_users[_user_address].last_block_number != 0) {
            lastProofRange = _block_number - _users[_user_address].last_block_number;
            if (lastProofRange > 150000) {
                lastProofRange = 150000;
            }
        }
        _users[_user_address].last_block_number = _block_number;
    }

    function setUserPlan(address _user_address, address _token) public override onlyPoS {
        _users[_user_address].pay_token = _token;
        emit ChangePaymentMethod(_user_address, _token);
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );

    function getUserPayToken(address _user_address)
        external
        view
        returns (address);

    function getUserLastBlockNumber(address _user_address)
        external
        view
        returns (uint32);

    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _nonce,
        address _updater
    ) external;

    function updateLastBlockNumber(address _user_address, uint32 _block_number) external;

    function setUserPlan(address _user_address, address _token) external;
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
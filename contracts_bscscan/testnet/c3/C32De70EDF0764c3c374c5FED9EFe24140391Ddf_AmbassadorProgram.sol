// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IAmbassadorProgram.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AmbassadorProgram is IAmbassadorProgram, Ownable {
    address public r1SaleContract;

    // rate in percentage
    uint256 private immutable _ambassadorReferralRate = 10;
    uint256 private immutable _referredReferralRate = 2;

    mapping(address => bytes32) internal _hashFrom;
    mapping(bytes32 => address) internal _addressFrom;
    mapping(bytes32 => bool) internal _refCode;

    event AddedAmbassadors(address[]);
    event DeletedAmbassadors(address[]);

    constructor(address r1SaleContract_) {
        r1SaleContract = r1SaleContract_;
    }

    function addAmbassadors(address[] memory addrs)
        public
        override
        onlyOwner()
    {
        for (uint256 index = 0; index < addrs.length; index++) {
            address currentAddr = addrs[index];
            bytes32 currentHash = keccak256(abi.encodePacked(currentAddr));

            _hashFrom[currentAddr] = currentHash;
            _addressFrom[currentHash] = currentAddr;
            _refCode[currentHash] = true;
        }

        emit AddedAmbassadors(addrs);
    }

    function deleteAmbassadors(address[] memory addrs)
        public
        override
        onlyOwner()
    {
        for (uint256 index = 0; index < addrs.length; index++) {
            address currentAddr = addrs[index];
            bytes32 currentHash = _hashFrom[currentAddr];

            delete _hashFrom[currentAddr];
            delete _addressFrom[currentHash];
            delete _refCode[currentHash];
        }

        emit DeletedAmbassadors(addrs);
    }

    function isAmbassador(address addr) public view override returns (bool) {
        return _hashFrom[addr] != "";
    }

    function hashFrom(address addr) public view override returns (bytes32) {
        require(
            owner() == _msgSender() ||
                addr == _msgSender() ||
                r1SaleContract == _msgSender(),
            "Caller is not the owner or not the right ambassador"
        );

        return _hashFrom[addr];
    }

    function addressFrom(bytes32 hash_) public view override returns (address) {
        require(
            owner() == _msgSender() ||
                _addressFrom[hash_] == _msgSender() ||
                r1SaleContract == _msgSender(),
            "Caller is not the owner or not the right ambassador"
        );

        return _addressFrom[hash_];
    }

    function isReferralCodeLegit(bytes32 hash_)
        external
        view
        override
        returns (bool)
    {
        return _refCode[hash_];
    }

    function ambassadorReferralRate() public pure override returns (uint256) {
        return _ambassadorReferralRate;
    }

    function referredReferralRate() public pure override returns (uint256) {
        return _referredReferralRate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IAmbassadorProgram {
    function addAmbassadors(address[] memory addrs) external;

    function deleteAmbassadors(address[] memory addrs) external;

    function isAmbassador(address addr) external view returns (bool);

    function hashFrom(address addr) external view returns (bytes32);

    function addressFrom(bytes32 hash_) external view returns (address);

    function isReferralCodeLegit(bytes32 hash_) external view returns (bool);

    function ambassadorReferralRate() external view returns (uint256);

    function referredReferralRate() external view returns (uint256);
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
    constructor () {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


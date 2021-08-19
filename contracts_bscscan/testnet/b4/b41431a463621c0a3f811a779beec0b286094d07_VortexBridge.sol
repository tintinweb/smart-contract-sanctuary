/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.7.0;

// import "@openzeppelin/contracts/utils/Context.sol";
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


// Dependency file: contracts/IVortexToken.sol

// pragma solidity 0.7.6;

interface IVortexToken {
    function mint(address to, uint256 amount) external;
}


// Root file: contracts/VortexBridge.sol

pragma solidity 0.7.6;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "contracts/IVortexToken.sol";

contract VortexBridge is Ownable {
    address public operator;
    IVortexToken public token;
    mapping(uint256 => bool) public processedNonces;

    enum Step {
        Burn,
        Mint
    }
    event CrossTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 date,
        uint256 nonce,
        Step indexed step
    );

    modifier onlyOperator() {
        require(_msgSender() == operator, "Caller is not operator");
        _;
    }

    constructor(address _token, address _operator) {
        token = IVortexToken(_token);
        operator = _operator;
    }

    function updateOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }

    function isProcessed(uint256 _nonce) public view returns (bool) {
        return processedNonces[_nonce];
    }

    function swap(
        address to,
        uint256 amount,
        uint256 otherChainNonce
    ) external onlyOperator {
        require(
            !processedNonces[otherChainNonce],
            "transfer already processed"
        );
        processedNonces[otherChainNonce] = true;
        token.mint(to, amount);
        emit CrossTransfer(
            _msgSender(),
            to,
            amount,
            block.timestamp,
            otherChainNonce,
            Step.Mint
        );
    }
}
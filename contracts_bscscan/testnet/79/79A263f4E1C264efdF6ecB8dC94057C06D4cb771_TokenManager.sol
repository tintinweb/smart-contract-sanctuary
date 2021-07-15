// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Ownable.sol";

contract TokenManager is Ownable {
    event TokenAdded(address indexed _tokenAddress);
    event TokenRemoved(address indexed _tokenAddress);

    struct Token {
        address tokenAddress;
        string name;
        string symbol;
        uint256 decimals;
    }

    address[] public tokenAddresses;
    mapping(address => Token) public tokens;

    function addToken(
        address _tokenAddress,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public onlyOwner {
        (bool found,) = indexOfToken(_tokenAddress);
        require(!found, 'Token already added');
        tokens[_tokenAddress] = Token(_tokenAddress, _name, _symbol, _decimals);
        tokenAddresses.push(_tokenAddress);
        emit TokenAdded(_tokenAddress);
    }

    function removeToken(
        address _tokenAddress
    ) public onlyOwner {
        (bool found, uint256 index) = indexOfToken(_tokenAddress);
        require(found, 'Erc20 token not found');
        if (tokenAddresses.length > 1) {
            tokenAddresses[index] = tokenAddresses[tokenAddresses.length - 1];
        }
        tokenAddresses.pop();
        delete tokens[_tokenAddress];
        emit TokenRemoved(_tokenAddress);
    }

    function indexOfToken(address _address) public view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _address) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getListTokenAddresses() public view returns (address[] memory)
    {
        return tokenAddresses;
    }

    function getLengthTokenAddresses() public view returns (uint256)
    {
        return tokenAddresses.length;
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
    address private _pendingOwner;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the pending owner.
    */
    modifier onlyPendingOwner() {
        require(pendingOwner() == _msgSender(), "Ownable: caller is not the pending owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _pendingOwner = newOwner;
    }

    function claimOwnership() external onlyPendingOwner {
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
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
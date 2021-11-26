//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './@openzeppelin/contracts/access/Ownable.sol';

interface IDough {
    function authMint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

contract MintModule is Ownable {
    IDough public dough;
    uint256 public _totalMinted;
    address[] public authed;

    event AddAuthed(address _address);
    event RemoveAuthed(address _address);
    event Mint(address _to, uint256 _amount);

    constructor(IDough _doughAddress) {
        dough = _doughAddress;
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        return dough.totalSupply();
    }

    function totalMinted() external view returns (uint256 _totalSupply) {
        return _totalMinted;
    }

    function viewArr() external view returns (address[] memory) {
        return authed;
    }

    function addToAuthedMinters(address _anotherAuth) public onlyOwner {
        authed.push(_anotherAuth);
        emit AddAuthed(_anotherAuth);
    }

    function removeFromAuthedMinters(address _addressToRemove) public onlyOwner {
        uint256 i = find(_addressToRemove);
        delete authed[i];

    }

    function find(address value) internal view returns (uint256) {
        uint256 i = 0;
        while (authed[i] != value) {
            i++;
        }
        return i;
    }

    function exists(address value) internal view returns (bool) {
        for (uint256 i = 0; i < authed.length; i++) {
            if (value == authed[i]) {
                return true;
            }
        }
        return false;
    }

    function mint(uint256 _amount, address _to) public onlyOwner {
        require(exists(msg.sender), "MintModule: Sender is not authed.");
        dough.authMint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /*function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }*/
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
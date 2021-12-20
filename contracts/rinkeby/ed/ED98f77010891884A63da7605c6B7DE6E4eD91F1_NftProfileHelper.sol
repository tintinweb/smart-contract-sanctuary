// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../interface/INftProfileHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftProfileHelper is INftProfileHelper, Ownable {
    mapping(bytes1 => bool) _allowedChar;

    constructor() {
        _allowedChar["a"] = true;
        _allowedChar["b"] = true;
        _allowedChar["c"] = true;
        _allowedChar["d"] = true;
        _allowedChar["e"] = true;
        _allowedChar["f"] = true;
        _allowedChar["g"] = true;
        _allowedChar["h"] = true;
        _allowedChar["i"] = true;
        _allowedChar["j"] = true;
        _allowedChar["k"] = true;
        _allowedChar["l"] = true;
        _allowedChar["m"] = true;
        _allowedChar["n"] = true;
        _allowedChar["o"] = true;
        _allowedChar["p"] = true;
        _allowedChar["q"] = true;
        _allowedChar["r"] = true;
        _allowedChar["s"] = true;
        _allowedChar["t"] = true;
        _allowedChar["u"] = true;
        _allowedChar["v"] = true;
        _allowedChar["w"] = true;
        _allowedChar["x"] = true;
        _allowedChar["y"] = true;
        _allowedChar["z"] = true;
        _allowedChar["0"] = true;
        _allowedChar["1"] = true;
        _allowedChar["2"] = true;
        _allowedChar["3"] = true;
        _allowedChar["4"] = true;
        _allowedChar["5"] = true;
        _allowedChar["6"] = true;
        _allowedChar["7"] = true;
        _allowedChar["8"] = true;
        _allowedChar["9"] = true;
        _allowedChar["_"] = true;
    }

    function bytesStringLength(string memory _string) private pure returns (uint256) {
        return bytes(_string).length;
    }

    function correctLength(string memory _string) private pure returns (bool) {
        return bytesStringLength(_string) > 0 && bytesStringLength(_string) <= 60;
    }

    function changeAllowedChar(string memory char, bool flag) external onlyOwner {
        require(bytesStringLength(char) == 1, "invalid length");
        _allowedChar[bytes1(bytes(char))] = flag;
    }

    /**
     @notice checks for a valid URI with length and allowed characters
     @param _name string for a given URI
     @return true if valid
    */
    function _validURI(string memory _name) external view override returns (bool) {
        require(correctLength(_name), "invalid length");
        bytes memory byteString = bytes(_name);
        for (uint256 i = 0; i < byteString.length; i++) {
            if (!_allowedChar[byteString[i]]) return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INftProfileHelper {
    function _validURI(string memory _name) external view returns (bool);
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
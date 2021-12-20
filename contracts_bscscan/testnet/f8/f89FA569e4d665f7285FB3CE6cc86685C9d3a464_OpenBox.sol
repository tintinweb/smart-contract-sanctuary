//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBlindBox.sol";
import "./interface/I721.sol";

contract OpenBox is Ownable {
    address private eyewitness = 0x2B4812AD7Acd0B04EeD9D888968f2c449276a65E;
    address public boxAddr = 0xaBfD77CEA90e884a3Eb65c3d59465455C57F8d6a;
    address public petAddr = 0x86eA051E5B3E554F833A2762A086825b18F3C3Be;
    address public landAddr = 0x2d0fA5aE3115032cb86571164dF7C5ed85D86c84;
    address public burnAddr = 0x0000000000000000000000000000000000000001;

    mapping (uint => uint) public boxOpened;

    IBlindBox public BlindBox;
    I721 public Land;
    I721 public Pet;

    event open(address indexed owner, uint boxId_);

    constructor() {
        BlindBox = IBlindBox(boxAddr);
        Land = I721(landAddr);
        Pet = I721(petAddr);
    }

    function openBox(
        uint boxId_,
        uint256[] memory petTokenIds_,
        uint8[] memory petLevels_,
        uint256[] memory landTokenIds_,
        uint8[] memory landLevels_,
        uint8 v, bytes32 r, bytes32 s
    ) public {
        require(petTokenIds_.length == petLevels_.length && landTokenIds_.length == landLevels_.length, "Invalid para");
        bytes32 digest = keccak256(abi.encode(_msgSender(), boxId_, petTokenIds_, petLevels_, landTokenIds_, landLevels_));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == eyewitness, "Invalid eyewitness signature");

        BlindBox.safeTransferFrom(_msgSender(), burnAddr, boxId_, 1, "");
        Pet.mintBatch(_msgSender(), petTokenIds_, petLevels_);
        Land.mintBatch(_msgSender(), landTokenIds_, landLevels_);

        boxOpened[boxId_]++;
        emit open(_msgSender(), boxId_);
    }

    function setEyewitness(address newAddr) public onlyOwner {
        eyewitness = newAddr;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

interface IBlindBox {
    function mint(address to_, uint boxID_, uint num_) external returns (bool);
    function mintBatch(address to_, uint[] memory boxIDs_, uint256[] memory nums_) external returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

pragma solidity ^0.8.0;

interface I721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, uint256 tokenId, uint8 level_) external;
    function mintBatch(address to, uint256[] memory tokenIds_, uint8[] memory levels_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
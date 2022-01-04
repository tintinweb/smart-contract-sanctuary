// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "Ownable.sol";

contract Lottery is Ownable {
    constructor() {}

    struct Draw {
        uint256[] condidates;
        uint256[] probs;
        uint256 result;
    }

    mapping(uint256 => string) private _goods;
    mapping(uint256 => Draw) private _draws;

    function getGoods(uint256 id) external view returns (string memory) {
        return _goods[id];
    }

    function setGoods(uint256[] memory ids, string[] memory names)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0 && bytes(names[i]).length > 0);
            _goods[ids[i]] = names[i];
        }
    }

    function getDraw(uint256 id)
        external
        view
        returns (Draw memory, string memory)
    {
        return (_draws[id], _goods[_draws[id].result]);
    }

    function addDraw(
        uint256 id,
        uint256[] memory condidates,
        uint256[] memory probs
    ) external onlyOwner {
        require(condidates.length == probs.length);

        for (uint256 i = 0; i < condidates.length; i++) {
            require(bytes(_goods[condidates[i]]).length > 0, "goods not exists");
            // FIXME prob ranges check
        }

        Draw storage draw = _draws[id];
        require(draw.result == 0, "id exists");

        draw.condidates = condidates;
        draw.probs = probs;

        // FIXME
        draw.result = condidates[0];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
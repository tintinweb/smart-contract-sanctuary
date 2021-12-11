// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SnackInterface.sol";
import "./AssetInterface.sol";

contract Fridge is Ownable, IERC721Receiver, Pausable {

    struct Asset {
        mapping(uint => Stake) assets;
        AssetInterface functions;
    }

    struct Stake {
        uint tokenId;
        uint value;
        address owner;
    }

    Asset[] public fridge;

    uint private _numAssets = 0;
    uint public constant DAILY_SNACK_RATE =10000 ether;
    mapping (address => uint[]) public tokensStakedByAddress;

    SnackInterface snack;

    function setSnack(address _snack) external onlyOwner {
        snack = SnackInterface(_snack);
    }

    function addAsset(address _assetsAddress) external onlyOwner{
        Asset storage asset = fridge.push();
        asset.functions = AssetInterface(_assetsAddress);
    }

    function putInFrontOfFridge(uint assetIndex, uint[] calldata tokenIds) external whenNotPaused {
        for(uint i = 0; i < tokenIds.length; i++) {
            require(fridge[assetIndex].functions.ownerOf(tokenIds[i]) == _msgSender(), "Fridge: You don't own the token!");
            fridge[assetIndex].functions.safeTransferFrom(_msgSender(), address(this),  tokenIds[i]);
            fridge[assetIndex].assets[tokenIds[i]] = Stake({
                tokenId: tokenIds[i],
                value: uint(block.timestamp),
                owner: _msgSender()
            });
            tokensStakedByAddress[_msgSender()].push(tokenIds[i]);
        }
    }

    function removeFromFridge(uint[] calldata tokenIds, bool unstake, uint assetIndex) external whenNotPaused  {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            Stake memory stake = fridge[assetIndex].assets[tokenIds[i]];
            require(stake.owner == _msgSender(), "Fridge: You aren't the owner of the token!");
            //Minutes for testing purposes, TODO change to days
            owed += (block.timestamp - stake.value) * DAILY_SNACK_RATE / 1 minutes;
            if(unstake) {
                fridge[assetIndex].functions.safeTransferFrom(address(this), _msgSender(),  tokenIds[i]);
                delete fridge[assetIndex].assets[tokenIds[i]];
                for (uint j = 0; j < tokensStakedByAddress[_msgSender()].length; j++) {
                    if(tokensStakedByAddress[_msgSender()][j] == tokenIds[i]) {
                        delete tokensStakedByAddress[_msgSender()][j];
                    }
                }
            } else {
                fridge[assetIndex].assets[tokenIds[i]] = Stake({
                    tokenId: tokenIds[i],
                    value: uint(block.timestamp),
                    owner: _msgSender()
                });
            }
        }
        snack.transfer(_msgSender(), owed);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculateRewards(address wallet, uint assetIndex)
        public
        view
        returns (uint)
    {
        uint[] memory tokenIds = tokensStakedByAddress[wallet];
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            Stake memory stake = fridge[assetIndex].assets[tokenIds[i]];
            //Minutes for testing purposes, TODO change to days
            owed += (block.timestamp - stake.value) * DAILY_SNACK_RATE / 1 minutes;
        }
        return owed;
    }
    
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SnackInterface {
    function transfer(address recipient, uint256 amount) external returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AssetInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) external {}
    function transferFrom(address from, address to, uint256 tokenId) external {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
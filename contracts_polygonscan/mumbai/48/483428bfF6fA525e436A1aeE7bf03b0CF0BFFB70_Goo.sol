// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//   / ____|
//  | |  __  ___   ___ ™
//  | | |_ |/ _ \ / _ \
//  | |__| | (_) | (_) |
//   \_____|\___/ \___/ 2021

import "../interfaces/IGoo.sol";
import "../interfaces/IBuddyCore.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Goo is Ownable, Pausable, IGoo, ERC721Holder {
    string public constant name = "Goo";
    string public constant symbol = "GOO";
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 0;
    uint256 blackHole = 0;
    uint256 MAX_VALUE = 2**255;

    address public _buddyCoreAddr;
    IBuddyCore public bc;

    mapping(uint256 => mapping(uint256 => uint256)) public allowances;
    mapping(uint256 => uint256) public balances;

    event Transfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event Approval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function setBuddyCoreAddr(address buddyCoreAddr) public onlyOwner {
        require(_buddyCoreAddr == address(0), "err: buddy addr already set");
        _buddyCoreAddr = buddyCoreAddr;
        bc = IBuddyCore(_buddyCoreAddr);
    }

    modifier onlyBuddyCore() {
        require(msg.sender == _buddyCoreAddr, "err: Unauthorized");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _isApprovedOrOwner(uint256 buddy) internal view returns (bool) {
        return
            bc.getApproval(buddy) == msg.sender ||
            bc.getOwnerOf(buddy) == msg.sender;
    }

    function balanceOf(uint256 buddy) external view override returns (uint256) {
        return balances[buddy];
    }

    function mint(uint256 buddy, uint256 amount)
        external
        override
        onlyBuddyCore
        whenNotPaused
    {
        require(
            buddy != blackHole && buddy != 1,
            "ERC20: mint to the Black Hole"
        );
        uint256 buddyBalance = balances[buddy];
        uint256 maxBalance = bc.getMaxBalance(buddy);
        require(
            buddyBalance < maxBalance,
            "ERC20: Mint amount exceeds max capacity"
        );

        if (buddyBalance + amount > maxBalance) {
            amount = maxBalance - buddyBalance;
        }

        totalSupply += amount;
        balances[buddy] += amount;
        emit Transfer(0, buddy, amount);
    }

    function burn(uint256 buddy, uint256 amount)
        external
        override
        onlyBuddyCore
        whenNotPaused
    {
        require(buddy != blackHole, "ERC20: burn from the Black Hole");

        uint256 accountBalance = balances[buddy];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[buddy] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(buddy, 0, amount);
    }

    function approve(
        uint256 from,
        uint256 spender,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        require(_isApprovedOrOwner(from));
        allowances[from][spender] = amount;

        emit Approval(from, spender, amount);
        return true;
    }

    function allowance(uint256 buddy, uint256 spender)
        public
        view
        override
        returns (uint256)
    {
        // Unlimited allowance from the black hole by default
        if (spender == bc.getBlackHole()) {
            return MAX_VALUE;
        }

        return allowances[buddy][spender];
    }

    function transfer(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external override whenNotPaused returns (bool) {
        require(_isApprovedOrOwner(from));
        _transferTokens(from, to, amount);
        return true;
    }

    function transferFrom(
        uint256 executor,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external override whenNotPaused returns (bool) {
        require(_isApprovedOrOwner(executor));
        uint256 spenderAllowance = allowance(from, executor);
        require(
            executor == from || spenderAllowance >= amount,
            "ERC20: Spend exceeds allowance"
        );

        if (executor != from && spenderAllowance != MAX_VALUE) {
            uint256 newAllowance = 0;

            unchecked {
                newAllowance = spenderAllowance - amount;
            }

            allowances[from][executor] = newAllowance;
            emit Approval(from, executor, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }

    function _transferTokens(
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal whenNotPaused {
        uint256 senderBalance = balances[from];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            balances[to] + amount <= bc.getMaxBalance(to),
            "ERC20: Transfer amount exceeds max capacity"
        );

        unchecked {
            balances[from] = senderBalance - amount;
        }
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGoo {
    function balanceOf(uint256 buddy) external view returns (uint256);

    function mint(uint256 buddy, uint256 amount) external;

    function burn(uint256 buddy, uint256 amount) external;

    function allowance(uint256 buddy, uint256 spender)
        external
        view
        returns (uint256);

    function transfer(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        uint256 executor,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBuddyCore {
    function getApproval(uint256) external view returns (address);

    function getOwnerOf(uint256) external view returns (address);

    function getBlackHole() external pure returns (uint256);

    function getMaxBalance(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
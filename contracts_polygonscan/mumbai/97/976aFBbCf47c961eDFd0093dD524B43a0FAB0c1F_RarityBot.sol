// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./rarity/IRarity.sol";
import "./rarity/IRarityGold.sol";

contract RarityBot is OwnableUpgradeable {

    mapping(address => uint256) public credits;
    mapping(uint256 => uint256) public summonerTasks;
    uint256 public minimalCredits;
    uint256 public feeMultiplier;
    uint256 public fees;

    IRarity public rarity;
    IRarityGold public rarityGold;

    // Credit
    event CreditDeposited(address indexed owner, uint256 amount);
    event CreditWithdrawn(address indexed owner, uint256 amount);
    event CreditCharged(address indexed owner, uint256 indexed summoner, uint256 amount);
    //Summoner Task
    event SummonerTaskAdded(address indexed owner, uint256 indexed summoner);
    event SummonerTaskUpdated(address indexed owner, uint256 indexed summoner);
    event SummonerTaskRemoved(address indexed owner, uint256 indexed summoner);
    // Tasks
    event TaskAdventured(address indexed owner, uint256 indexed summoner);
    event TaskGoldClaimed(address indexed owner, uint256 indexed summoner);
    event TaskLeveledUp(address indexed owner, uint256 indexed summoner);

    function initialize(
        uint256 _feeMultiplier,
        uint256 _minimalCredits,
        address _rarity,
        address _rarityGold
    ) external initializer {
        __Ownable_init();
        feeMultiplier = _feeMultiplier;
        minimalCredits = _minimalCredits;
        rarity = IRarity(_rarity);
        rarityGold = IRarityGold(_rarityGold);
    }

    function run(
        uint256 _summoner,
        uint256 _tasks
    ) public {
        uint256 startGasLeft = gasleft();

        require(_tasks != 0, "Bot: empty tasks");

        address summonerOwner = rarity.ownerOf(_summoner);
        require(credits[summonerOwner] >= minimalCredits, "Bot: low minimal credit");
        require(rarity.isApprovedForAll(summonerOwner, address(this)), "Rarity: not approved");

        uint256 tasks = summonerTasks[_summoner] & _tasks;
        if (tasks == 0) {
            return;
        }

        bool runned = false;

        if (_isTask(tasks, 0)) {
            _runAdventure(summonerOwner, _summoner);
            runned = true;
        }

        if (_isTask(tasks, 1)) {
            _runLevelUp(summonerOwner, _summoner);
            runned = true;
        }

        if (_isTask(tasks, 2)) {
            _runClaimGold(summonerOwner, _summoner);
            runned = true;
        }

        if (runned) {
            uint256 fee = (startGasLeft - gasleft()) * tx.gasprice * feeMultiplier / 100;
            credits[summonerOwner] -= fee;
            fees += fee;

            emit CreditCharged(summonerOwner, _summoner, fee);
        }

    }

    function depositCredit(
    ) public payable {
        credits[msg.sender] += msg.value;

        emit CreditDeposited(msg.sender, msg.value);
    }

    function withdrawCredit(
        uint256 _amount
    ) public {
        require(credits[msg.sender] >= _amount, "Bot: insufficient credit");

        credits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit CreditWithdrawn(msg.sender, _amount);
    }

    function saveTasks(
        uint256[] calldata _summoners,
        uint256[] calldata _tasks
    ) public {
        require(_summoners.length == _tasks.length, "Bot: invalid lengths");
        for (uint256 i = 0; i < _summoners.length; i++) {
            _saveSummonerTasks(_summoners[i], _tasks[i]);
        }
    }

    function withdrawFees(
    ) public onlyOwner {
        payable(msg.sender).transfer(fees);
        fees = 0;
    }

    function setFeePercentage(
    uint256 _feePercentage
    ) public onlyOwner {
        feeMultiplier = _feePercentage;
    }

    function setMinimalCredits(
        uint256 _minimalCredits
    ) public onlyOwner {
        minimalCredits = _minimalCredits;
    }

    function _saveSummonerTasks(
        uint256 _summoner,
        uint256 _tasks
    ) private {
        address owner = msg.sender;

        require(rarity.ownerOf(_summoner) == owner, "Rarity: not owner");

        uint256 currentTasks = summonerTasks[_summoner];
        if (_tasks == 0 && currentTasks != 0) {
            delete summonerTasks[_summoner];
            emit SummonerTaskRemoved(owner, _summoner);
        } else {
            summonerTasks[_summoner] = _tasks;
            if (currentTasks == 0) {
                emit SummonerTaskAdded(owner, _summoner);
            } else {
                emit SummonerTaskUpdated(owner, _summoner);
            }
        }

    }


    function _runAdventure(
        address _summonerOwner,
        uint256 _summoner
    ) private {
        rarity.adventure(_summoner);
        emit TaskAdventured(_summonerOwner, _summoner);
    }

    function _runClaimGold(
        address _summonerOwner,
        uint256 _summoner
    ) private {
        rarityGold.claim(_summoner);
        emit TaskGoldClaimed(_summonerOwner, _summoner);
    }

    function _runLevelUp(
        address _summonerOwner,
        uint256 _summoner
    ) private {
        rarity.level_up(_summoner);
        emit TaskLeveledUp(_summonerOwner, _summoner);
    }

    function _isTask(
        uint256 _tasks,
        uint8 _task
    ) private pure returns(bool) {
        return _tasks >> _task & 1 == 1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRarity is IERC721 {
    // getter
    function xp(uint256) external view returns (uint);
    function adventurers_log(uint256) external view returns (uint);
    function class(uint256) external view returns (uint);
    function level(uint256) external view returns (uint);
    // methods
    function adventure(uint256 _summoner) external;
    function spend_xp(uint256 _summoner, uint256 _xp) external;
    function level_up(uint256 _summoner) external;
    function summoner(uint256 _summoner) external view returns (uint256 _xp, uint256 _log, uint256 _class, uint256 _level);
    function summon(uint256 _class) external;
    function xp_required(uint256 current_level) external pure returns (uint256 _xp_to_next_level);
    function tokenURI(uint256 _summoner) external view returns (string memory);
    function classes(uint256 id) external pure returns (string memory _description);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRarityGold {
    // getter
    function balanceOf(uint256) external view returns(uint256);
    function claimed(uint256) external view returns(uint256);
    // methods
    function claimable(uint256 _summoner) external view returns (uint256 amount);
    function claim(uint256 _summoner) external;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
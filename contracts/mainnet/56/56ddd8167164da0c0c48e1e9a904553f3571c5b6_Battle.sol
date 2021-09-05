/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: AGPL V3.0

pragma solidity 0.8.0;

// Global Enums and Structs



struct BattleInfo {
    uint256 defenderPower;
    uint256 attackerPower;
    uint256 duration;
    uint256 endTimestamp;
    uint256 numWarriors;
}
struct WarriorInfo {
    uint256 power;
    uint256 side;
}

// Part: IBattleRewarder

interface IBattleRewarder {
    // Record that a battle was finished, and update reward distributions appropriately.
    // Should not require a lot of gas for this computation (unless we are rewarding
    // whoever calls `finishBattle` with some bonus XP or something...)
    function battleFinished(uint256 battleId) external;

    // Allows a warrior to claim rewards for a battle that they participated in.
    function claimRewardsForBattle(uint256 battleId) external;
}

// Part: IPowerCalculator

interface IPowerCalculator {
    function calculatePower(uint256 weaponId) external returns (uint256);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: Battle.sol

/**
 * Implements battles between Loot weapon holders.
 *
 * The battle is a simple tug-of-war in which people can enlist to support
 * either side. Each weapon contributes a "power" score that amplifies the
 * strength of their side. At the end of the battle, the side with more power wins.
 *
 * A given warrior (address) can only participate in any individual battle once.
 * In practice, some people might run multiple warriors via separate addresses,
 * but our setup discourages this practice.
 * Similarly, each weapon can only be used once in a given battle.
 *
 * We record the power of the weapon _at the time it is used_; upgrades to the
 * weapon will have no effect on battles that weapon is currently in.
 *
 * Once a warrior and weapon are committed, there is no turning back, retreating,
 * or switching sides. This simplifies the state tracking.
 *
 * Weapon power computation is abstracted behind an IPowerCalculator, which
 * allows the possibility of re-balancing the game without needing to change
 * this contract.
 * Similarly, the distribution of battle rewards (XP) is handled through an
 * IBattleRewarder, so we can tweak the XP reward mechanics without redeploying
 * this contract.
 *
 * There is support for a v2 loot weapon contract; once we deploy it we can
 * add the new contract address. Since all weapon stat calculation is abstracted
 * behind the IPowerCalculator, from the perspective of this contract we only
 * know that the loot weapons are ERC-721s and we check that warriors actually
 * own them.
 */
contract Battle is Ownable {
    uint256 constant ATTACKER_SIDE = 1;
    uint256 constant DEFENDER_SIDE = 2;
    IERC721 public weaponContractV1 =
        IERC721(0x0ac0ECc6D249F1383c5C7c2Ff4941Bd56DEcDd14);
    IERC721 public weaponContractV2;

    mapping(uint256 => BattleInfo) public idToBattleInfo;
    mapping(uint256 => mapping(uint256 => bool))
        public battleIdToWeaponEnlisted;
    mapping(uint256 => mapping(address => WarriorInfo))
        public battleIdToWarriorInfo;

    event BattleStarted(
        uint256 indexed battleId,
        uint256 duration,
        uint256 endTimestamp
    );

    event WarriorEnlisted(
        uint256 indexed battleId,
        address indexed warrior,
        uint256 indexed weaponId,
        uint256 side,
        uint256 power
    );
    event BattleRewarderChanged(IBattleRewarder newRewarder);
    event PowerCalculatorChanged(IPowerCalculator newCalculator);

    IBattleRewarder public battleRewarder;
    IPowerCalculator public powerCalculator;

    uint256 public nextBattleId;

    // Start w/ 5 min duration, we can increase it after testing
    uint256 public minBattleDuration = 300;

    function setBattleRewarder(IBattleRewarder newRewarder) public onlyOwner {
        battleRewarder = newRewarder;
        emit BattleRewarderChanged(newRewarder);
    }

    function setPowerCalculator(IPowerCalculator newCalculator)
        public
        onlyOwner
    {
        powerCalculator = newCalculator;
        emit PowerCalculatorChanged(newCalculator);
    }

    function setV2ContractAddress(IERC721 newV2Contract) public onlyOwner {
        weaponContractV2 = newV2Contract;
    }

    function changeMinBattleDuration(uint256 newDuration) public onlyOwner {
        require(newDuration > 0, "duration may not be 0");
        minBattleDuration = newDuration;
    }

    function startBattle(uint256 duration) public returns (uint256) {
        require(duration >= minBattleDuration, "battle too short");
        uint256 endTimestamp = block.timestamp + duration;
        idToBattleInfo[nextBattleId].endTimestamp = endTimestamp;
        idToBattleInfo[nextBattleId].duration = duration;
        emit BattleStarted(nextBattleId, duration, endTimestamp);
        nextBattleId++;
        return nextBattleId - 1;
    }

    function enlist(
        uint256 battleId,
        uint256 side,
        uint256 weaponId
    ) public {
        bool ownsV1 = weaponContractV1.ownerOf(weaponId) == msg.sender;
        bool ownsV2 = address(weaponContractV2) != address(0) &&
            weaponContractV2.ownerOf(weaponId) == msg.sender;
        require(ownsV1 || ownsV2, "must own weapon");
        uint256 endTimestamp = idToBattleInfo[battleId].endTimestamp;
        require(endTimestamp != 0, "battle must exist");
        require(block.timestamp < endTimestamp, "too late for battle");

        require(!battleIdToWeaponEnlisted[battleId][weaponId], "weapon in use");
        require(
            battleIdToWarriorInfo[battleId][msg.sender].side == 0,
            "warrior in battle"
        );
        require(
            side == ATTACKER_SIDE || side == DEFENDER_SIDE,
            "no bystanders!"
        );

        uint256 power = powerCalculator.calculatePower(weaponId);
        battleIdToWarriorInfo[battleId][msg.sender] = WarriorInfo(power, side);
        battleIdToWeaponEnlisted[battleId][weaponId] = true;

        if (side == ATTACKER_SIDE) {
            idToBattleInfo[battleId].attackerPower += power;
        } else {
            idToBattleInfo[battleId].defenderPower += power;
        }
        idToBattleInfo[battleId].numWarriors++;

        emit WarriorEnlisted(battleId, msg.sender, weaponId, side, power);
    }
}
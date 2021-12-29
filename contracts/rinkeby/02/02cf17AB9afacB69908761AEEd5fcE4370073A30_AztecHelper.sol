// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./libraries/GameHelper.sol";
import "./interfaces/IAztecGame.sol";
import "./interfaces/IAztecNFT.sol";
import "./utils/Operator.sol";

contract AztecHelper is Operator {
    uint256 public constant MAX_LEVEL = 6;
    uint256 public constant MAX_UPGRADE_LEVEL = MAX_LEVEL - 1;
    uint256 public constant MAX_ROLE = 6;
    uint256 public constant UPGRADEABLT_ROLE = MAX_ROLE - 1;
    uint256 public constant VARIABLE_REWARD_ROLE = MAX_ROLE - 1;
    struct UpgradeCosts {
        uint16 nfts;
        uint16 elements;
        uint224 azts;
    }
    struct Traits {
        uint16 typeId;
        uint16 level;
    }
    enum Role {
        Unknown,
        Spirit,
        Miner,
        Magician,
        Trainer,
        Gladiator,
        Nuggetor
    }

    IAztecGame _aztecGame;
    IAztecNFT _aztecNFT;

    uint256 _aztRewardBase = 0.0003 ether; // RoleTrainer Lv1
    uint256 _elementsRewardBase = 1; // RoleTrainer Lv3

    uint256[VARIABLE_REWARD_ROLE] _roleRewardRatios;
    uint256[MAX_LEVEL] _baseElementsRewards; // RoleTrainer
    uint256[MAX_LEVEL][VARIABLE_REWARD_ROLE] _roleAztRewardTimes;

    UpgradeCosts[MAX_UPGRADE_LEVEL][UPGRADEABLT_ROLE] _roleUpgradeCosts;

    constructor(
        address operator,
        address aztecGame,
        address aztecNFT
    ) {
        setOperator(operator, true);
        _aztecGame = IAztecGame(aztecGame);
        _aztecNFT = IAztecNFT(aztecNFT);
        // Lv1 => Lv2
        _roleUpgradeCosts[0][0] = UpgradeCosts(1, 0, 12 ether); // RoleMiner
        _roleUpgradeCosts[0][1] = UpgradeCosts(0, 0, 30 ether); // RoleMagician
        _roleUpgradeCosts[0][2] = UpgradeCosts(0, 0, 45 ether); // RoleTrainer
        _roleUpgradeCosts[0][3] = UpgradeCosts(0, 0, 90 ether); // RoleGladiator
        _roleUpgradeCosts[0][4] = UpgradeCosts(0, 0, 150 ether); // RoleNuggetor
        // Lv2 => Lv3
        _roleUpgradeCosts[1][0] = UpgradeCosts(3, 6, 10 ether); // RoleMiner
        _roleUpgradeCosts[1][1] = UpgradeCosts(2, 0, 25 ether); // RoleMagician
        _roleUpgradeCosts[1][2] = UpgradeCosts(2, 0, 33 ether); // RoleTrainer
        _roleUpgradeCosts[1][3] = UpgradeCosts(1, 0, 80 ether); // RoleGladiator
        _roleUpgradeCosts[1][4] = UpgradeCosts(1, 0, 120 ether); // RoleNuggetor
        // Lv3 => Lv4
        _roleUpgradeCosts[2][0] = UpgradeCosts(4, 10, 8 ether); // RoleMiner
        _roleUpgradeCosts[2][1] = UpgradeCosts(2, 3, 20 ether); // RoleMagician
        _roleUpgradeCosts[2][2] = UpgradeCosts(2, 5, 25 ether); // RoleTrainer
        _roleUpgradeCosts[2][3] = UpgradeCosts(1, 10, 70 ether); // RoleGladiator
        _roleUpgradeCosts[2][4] = UpgradeCosts(1, 18, 100 ether); // RoleNuggetor
        // Lv4 => Lv5
        _roleUpgradeCosts[3][0] = UpgradeCosts(4, 15, 6 ether); // RoleMiner
        _roleUpgradeCosts[3][1] = UpgradeCosts(2, 4, 16 ether); // RoleMagician
        _roleUpgradeCosts[3][2] = UpgradeCosts(2, 7, 20 ether); // RoleTrainer
        _roleUpgradeCosts[3][3] = UpgradeCosts(1, 13, 60 ether); // RoleGladiator
        _roleUpgradeCosts[3][4] = UpgradeCosts(1, 23, 80 ether); // RoleNuggetor
        // Lv5 => Lv6
        _roleUpgradeCosts[4][0] = UpgradeCosts(5, 20, 5 ether); // RoleMiner
        _roleUpgradeCosts[4][1] = UpgradeCosts(3, 6, 12 ether); // RoleMagician
        _roleUpgradeCosts[4][2] = UpgradeCosts(3, 9, 16 ether); // RoleTrainer
        _roleUpgradeCosts[4][3] = UpgradeCosts(1, 16, 50 ether); // RoleGladiator
        _roleUpgradeCosts[4][4] = UpgradeCosts(1, 29, 70 ether); // RoleNuggetor

        ///
        _roleRewardRatios[0] = 25; // RoleMiner
        _roleRewardRatios[1] = 65; // RoleMagician
        _roleRewardRatios[2] = 100; // RoleTrainer
        _roleRewardRatios[3] = 200; // RoleGladiator
        _roleRewardRatios[4] = 350; // RoleNuggetor

        // _baseElementsRewards[0] = 0; // Lv1
        // _baseElementsRewards[1] = 0; // Lv2
        _baseElementsRewards[2] = 1000; // Lv3
        _baseElementsRewards[3] = 1500; // Lv4
        _baseElementsRewards[4] = 2000; // Lv5
        _baseElementsRewards[5] = 2500; // Lv6

        // RoleMiner
        _roleAztRewardTimes[0][0] = 100; // Lv1
        _roleAztRewardTimes[0][1] = 300; // Lv2
        _roleAztRewardTimes[0][2] = 1350; // Lv3
        _roleAztRewardTimes[0][3] = 6000; // Lv4
        _roleAztRewardTimes[0][4] = 20000; // Lv5
        _roleAztRewardTimes[0][5] = 60000; // Lv6

        // RoleMagician
        _roleAztRewardTimes[1][0] = 100; // Lv1
        _roleAztRewardTimes[1][1] = 200; // Lv2
        _roleAztRewardTimes[1][2] = 650; // Lv3
        _roleAztRewardTimes[1][3] = 2000; // Lv4
        _roleAztRewardTimes[1][4] = 6000; // Lv5
        _roleAztRewardTimes[1][5] = 24000; // Lv6

        // RoleTrainer
        _roleAztRewardTimes[2][0] = 100; // Lv1
        _roleAztRewardTimes[2][1] = 200; // Lv2
        _roleAztRewardTimes[2][2] = 650; // Lv3
        _roleAztRewardTimes[2][3] = 2000; // Lv4
        _roleAztRewardTimes[2][4] = 6000; // Lv5
        _roleAztRewardTimes[2][5] = 24000; // Lv6

        // RoleGladiator
        _roleAztRewardTimes[3][0] = 100; // Lv1
        _roleAztRewardTimes[3][1] = 200; // Lv2
        _roleAztRewardTimes[3][2] = 500; // Lv3
        _roleAztRewardTimes[3][3] = 1200; // Lv4
        _roleAztRewardTimes[3][4] = 2800; // Lv5
        _roleAztRewardTimes[3][5] = 12000; // Lv6

        // RoleNuggetor
        _roleAztRewardTimes[4][0] = 100; // Lv1
        _roleAztRewardTimes[4][1] = 200; // Lv2
        _roleAztRewardTimes[4][2] = 500; // Lv3
        _roleAztRewardTimes[4][3] = 1200; // Lv4
        _roleAztRewardTimes[4][4] = 2800; // Lv5
        _roleAztRewardTimes[4][5] = 8000; // Lv6
    }

    function setUpgradeCosts(
        uint256 lv,
        uint256 typeId,
        UpgradeCosts memory costs
    ) external onlyOperator {
        _roleUpgradeCosts[lv - 1][typeId - 2] = costs;
    }

    function setAztecAddresses(address aztecGame, address aztecNFT)
        external
        onlyOperator
    {
        if (aztecGame != address(0)) _aztecGame = IAztecGame(aztecGame);
        if (aztecNFT != address(0)) _aztecNFT = IAztecNFT(aztecNFT);
    }

    function setAztBaseRewards(uint256 aztRewardBase) external onlyOperator {
        _aztRewardBase = aztRewardBase; // RoleTrainer Lv1
    }

    function setElementBaseRewards(uint256 elementsRewardBase)
        external
        onlyOperator
    {
        _elementsRewardBase = elementsRewardBase; // RoleTrainer Lv3
    }

    function setRoleRewardBaseRatio(uint256 typeId, uint256 roleRewardRatio)
        external
        onlyOperator
    {
        _roleRewardRatios[typeId - 2] = roleRewardRatio;
    }

    function setBaseElementsReward(uint256 lv, uint256 baseElementsReward)
        external
        onlyOperator
    {
        _baseElementsRewards[lv - 1] = baseElementsReward; // RoleTrainer
    }

    function setRoleAztRewardTimes(
        uint256 typeId,
        uint256 lv,
        uint256 roleAztRewardTimes
    ) external onlyOperator {
        _roleAztRewardTimes[typeId - 2][lv - 1] = roleAztRewardTimes;
    }

    function getUpgradeCosts(uint256 numericTrait)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 typeId, uint256 level) = GameHelper.getTraits(numericTrait);
        return getUpgradeCosts(typeId, level);
    }

    function getUpgradeCosts(uint256 typeId, uint256 level)
        public
        view
        returns (
            uint256 nfts,
            uint256 elements,
            uint256 azts
        )
    {
        UpgradeCosts memory upgradeCosts = _roleUpgradeCosts[level - 1][
            typeId - 2
        ];
        nfts = upgradeCosts.nfts;
        elements = upgradeCosts.elements;
        azts = upgradeCosts.azts;
    }

    // return elements with 5 decimals
    function getRewardRate(uint256 numericTrait)
        public
        view
        returns (uint256 azts, uint256 elements)
    {
        azts = getAztRewardRate(numericTrait);
        elements = getElementRewardRate(numericTrait);
    }

    function getAztRewardRate(uint256 numericTrait)
        public
        view
        returns (uint256 azts)
    {
        (uint256 typeId, uint256 level) = GameHelper.getTraits(numericTrait);
        if (typeId == 1) {
            azts = 0.3 ether;
        } else {
            uint256 typeIndex = typeId - 2;
            azts =
                _aztRewardBase * // this value div 0.0001
                _roleRewardRatios[typeIndex] *
                _roleAztRewardTimes[typeIndex][level - 1];
        }
    }

    // return elements with 5 decimals
    function getElementRewardRate(uint256 numericTrait)
        public
        view
        returns (uint256 elements)
    {
        (uint256 typeId, uint256 level) = GameHelper.getTraits(numericTrait);
        if (level > 2 && typeId > 1) {
            // RoleMiner Lv3 rewards is 0
            if (!(typeId == 2 && level == 3)) {
                elements = (_elementsRewardBase *
                    _roleRewardRatios[typeId - 2] *
                    _baseElementsRewards[level - 1]);
            }
        }
    }

    function getRewards(uint256 numericTrait, uint256 minedTime)
        public
        view
        returns (uint256 azts, uint256 elements)
    {
        azts = getAztRewards(numericTrait, minedTime);
        elements = getElementRewards(numericTrait, minedTime);
    }

    function getAztRewards(uint256 numericTrait, uint256 minedTime)
        public
        view
        returns (uint256 azts)
    {
        return (getAztRewardRate(numericTrait) * minedTime) / 1 days;
    }

    function getElementRewards(uint256 numericTrait, uint256 minedTime)
        public
        view
        returns (uint256 azts)
    {
        return
            (getElementRewardRate(numericTrait) * minedTime) / 1 days / 100000;
    }

    /// query
    function numericTraitsInSlots(address owner)
        external
        view
        returns (uint256[][6] memory slotsNumericTraits)
    {
        for (uint256 typeId = 1; typeId <= MAX_LEVEL; typeId++) {
            slotsNumericTraits[typeId - 1] = _aztecGame.numericTraitsInSlot(
                owner,
                typeId
            );
        }
    }

    function territoryNFTs(uint256 territoryId)
        external
        view
        returns (uint256 maxNFTs, uint256 nfts)
    {
        maxNFTs = GameHelper.MAX_TERRITORY_NFTS;
        nfts = _aztecGame._territoryNFTs(territoryId);
    }

    function slotsInfo(address owner)
        external
        view
        returns (Traits[][6] memory slotsTraits)
    {
        for (uint256 typeId = 1; typeId <= 6; typeId++) {
            uint256[] memory numericTraits = _aztecGame.numericTraitsInSlot(
                owner,
                typeId
            );
            Traits[] memory slotTraits = new Traits[](numericTraits.length);
            for (uint256 index = 0; index < numericTraits.length; index++) {
                (uint16 typ, uint16 lv) = GameHelper.getTraits(
                    numericTraits[index]
                );
                slotTraits[index] = Traits(typ, lv);
            }
            slotsTraits[typeId - 1] = slotTraits;
        }
    }

    function rewardInfo(address account)
        public
        view
        returns (
            uint256 aztRewards,
            uint256 withdrewAzts,
            uint256 elementRewards,
            uint256 withdrewElements
        )
    {
        uint128[2][] memory nfts = _aztecGame._miningNFTs(account);
        for (uint256 index = 0; index < nfts.length; index++) {
            (uint256 azts, uint256 elements) = getRewards(
                _aztecNFT.numericTraits(nfts[index][0]),
                block.timestamp - nfts[index][1]
            );
            aztRewards += azts;
            elementRewards += elements;
        }
        withdrewAzts = _aztecGame._withdrewAztRewards(account);
        withdrewElements = _aztecGame._withdrewElementRewards(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library GameHelper {
    uint256 public constant MAX_TERRITORY_NFTS = 20000;

    function getTypeIdTrait(uint256 numericTrait)
        internal
        pure
        returns (uint16)
    {
        return uint16(numericTrait >> 240);
    }

    function getLevelTrait(uint256 numericTrait)
        internal
        pure
        returns (uint16)
    {
        return uint16(numericTrait >> 224);
    }

    function getTraits(uint256 numericTrait)
        internal
        pure
        returns (uint16 typeId, uint16 lv)
    {
        typeId = getTypeIdTrait(numericTrait);
        lv = getLevelTrait(numericTrait);
    }

    function setTypeIdTrait(uint256 numericTrait, uint16 typeId)
        internal
        pure
        returns (uint256)
    {
        return (uint256(typeId) << 240) & numericTrait;
    }

    function setLevelTrait(uint256 numericTrait, uint16 level)
        internal
        pure
        returns (uint256)
    {
        return (uint256(level) << 224) & numericTrait;
    }

    function slotSize(uint256 typeId, uint256 expandedSize)
        internal
        pure
        returns (uint256)
    {
        return defaultSlotSize(typeId) + expandedSize;
    }

    function defaultSlotSize(uint256 typeId) internal pure returns (uint256) {
        // type 1 and 2 has 3 slot
        if (typeId < 3) {
            return 3;
        } else {
            return 1;
        }
    }

    function expandSlotCost(uint256 typeId) internal pure returns (uint256) {
        if (typeId == 2) {
            return 10 ether;
        }
        if (typeId > 2 && typeId < 6) {
            return 30 ether;
        }
        if (typeId == 6) {
            return 50 ether;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAztecGame {
    function numericTraitsInSlot(address owner, uint256 typeId)
        external
        view
        returns (uint256[] memory numericTraits);

    function _miningNFTs(address account)
        external
        view
        returns (uint128[2][] memory); // 0 tokenId, 1 startTime

    function _userTerritories(address account)
        external
        view
        returns (uint128[2] memory);

    function _territoryNFTs(uint256 territoryId)
        external
        view
        returns (uint256);

    function _withdrewAztRewards(address account)
        external
        view
        returns (uint256);

    function _withdrewElementRewards(address territoryId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IAztecNFT is IERC721 {
    function mint(address to, uint256 numericTrait)
        external
        returns (uint256 tokenId);

    function numericTraits(uint256 tokenId)
        external
        view
        returns (uint256 numericTrait);

    function setNumericTraits(uint256 tokenId, uint256 numericTrait) external;

    function burn(uint256 tokenId) external;

    function miners(uint256 tokenId) external returns (address miner);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    mapping(address => bool) private _operators;

    event OperatorSetted(address account, bool allow);

    modifier onlyOperator() {
        require(_operators[_msgSender()], "Forbidden");
        _;
    }

    constructor() {
        setOperator(_msgSender(), true);
    }

    function operator(address account) public view returns (bool) {
        return _operators[account];
    }

    function setOperator(address account, bool allow) public onlyOwner {
        _operators[account] = allow;
        emit OperatorSetted(account, allow);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
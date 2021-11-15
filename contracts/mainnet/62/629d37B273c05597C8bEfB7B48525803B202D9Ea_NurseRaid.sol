// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INurseRaid.sol";
import "./libraries/MaidPower.sol";

contract NurseRaid is Ownable, MaidPower, INurseRaid {
    struct Raid {
        uint256 entranceFee;
        uint256 nursePart;
        uint256 maxRewardCount;
        uint256 duration;
        uint256 endBlock;
    }

    struct Challenger {
        uint256 enterBlock;
        IMaids maids;
        uint256 maidId;
    }

    struct MaidEfficacy {
        uint256 numerator;
        uint256 denominator;
    }

    Raid[] public raids;
    mapping(uint256 => mapping(address => Challenger)) public challengers;

    mapping(IMaids => bool) public override isMaidsApproved;

    IMaidCoin public immutable override maidCoin;
    IMaidCafe public override maidCafe;
    INursePart public immutable override nursePart;
    ICloneNurses public immutable override cloneNurses;
    IRNG public override rng;

    MaidEfficacy public override maidEfficacy = MaidEfficacy({numerator: 1, denominator: 1000});

    constructor(
        IMaidCoin _maidCoin,
        IMaidCafe _maidCafe,
        INursePart _nursePart,
        ICloneNurses _cloneNurses,
        IRNG _rng,
        address _sushiGirls,
        address _lingerieGirls
    ) MaidPower(_sushiGirls, _lingerieGirls) {
        maidCoin = _maidCoin;
        maidCafe = _maidCafe;
        nursePart = _nursePart;
        cloneNurses = _cloneNurses;
        rng = _rng;
    }

    function changeMaidEfficacy(uint256 _numerator, uint256 _denominator) external onlyOwner {
        maidEfficacy = MaidEfficacy({numerator: _numerator, denominator: _denominator});
        emit ChangeMaidEfficacy(_numerator, _denominator);
    }

    function setMaidCafe(IMaidCafe _maidCafe) external onlyOwner {
        maidCafe = _maidCafe;
    }

    function approveMaids(IMaids[] calldata maids) public onlyOwner {
        for (uint256 i = 0; i < maids.length; i += 1) {
            isMaidsApproved[maids[i]] = true;
        }
    }

    function disapproveMaids(IMaids[] calldata maids) public onlyOwner {
        for (uint256 i = 0; i < maids.length; i += 1) {
            isMaidsApproved[maids[i]] = false;
        }
    }

    modifier onlyApprovedMaids(IMaids maids) {
        require(address(maids) == address(0) || isMaidsApproved[maids], "NurseRaid: The maids is not approved");
        _;
    }

    function changeRNG(address addr) external onlyOwner {
        rng = IRNG(addr);
    }

    function raidCount() external view override returns (uint256) {
        return raids.length;
    }

    function create(
        uint256[] calldata entranceFees,
        uint256[] calldata _nurseParts,
        uint256[] calldata maxRewardCounts,
        uint256[] calldata durations,
        uint256[] calldata endBlocks
    ) external override onlyOwner returns (uint256 id) {
        uint256 length = entranceFees.length;
        for (uint256 i = 0; i < length; i++) {
            require(maxRewardCounts[i] < 255, "NurseRaid: Invalid number");
            {   // scope to avoid stack too deep errors
                (uint256 nursePartCount, uint256 nurseDestroyReturn, , ) = cloneNurses.nurseTypes(_nurseParts[i]);

                require(
                    entranceFees[i] >= (nurseDestroyReturn * maxRewardCounts[i]) / nursePartCount,
                    "NurseRaid: Fee should be higher"
                );
            }
            id = raids.length;
            raids.push(
                Raid({
                    entranceFee: entranceFees[i],
                    nursePart: _nurseParts[i],
                    maxRewardCount: maxRewardCounts[i],
                    duration: durations[i],
                    endBlock: endBlocks[i]
                })
            );
            emit Create(id, entranceFees[i], _nurseParts[i], maxRewardCounts[i], durations[i], endBlocks[i]);
        }
    }

    function enter(
        uint256 id,
        IMaids maids,
        uint256 maidId
    ) public override onlyApprovedMaids(maids) {
        Raid storage raid = raids[id];
        require(block.number < raid.endBlock, "NurseRaid: Raid has ended");
        require(challengers[id][msg.sender].enterBlock == 0, "NurseRaid: Raid is in progress");
        challengers[id][msg.sender] = Challenger({enterBlock: block.number, maids: maids, maidId: maidId});
        if (address(maids) != address(0)) {
            maids.transferFrom(msg.sender, address(this), maidId);
        }
        uint256 _entranceFee = raid.entranceFee;
        maidCoin.transferFrom(msg.sender, address(this), _entranceFee);
        uint256 feeToCafe = (_entranceFee * 3) / 1000;
        _feeTransfer(feeToCafe);
        maidCoin.burn(_entranceFee - feeToCafe);
        emit Enter(msg.sender, id, maids, maidId);
    }

    function enterWithPermit(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external override {
        maidCoin.permit(msg.sender, address(this), raids[id].entranceFee, deadline, v1, r1, s1);
        if (address(maids) != address(0)) {
            maids.permit(msg.sender, maidId, deadline, v2, r2, s2);
        }
        enter(id, maids, maidId);
    }

    function enterWithPermitAll(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external override {
        maidCoin.permit(msg.sender, address(this), type(uint256).max, deadline, v1, r1, s1);
        if (address(maids) != address(0)) {
            maids.permitAll(msg.sender, address(this), deadline, v2, r2, s2);
        }
        enter(id, maids, maidId);
    }

    function checkDone(uint256 id) public view override returns (bool) {
        Raid memory raid = raids[id];
        Challenger memory challenger = challengers[id][msg.sender];

        return _checkDone(raid.duration, challenger);
    }

    function _checkDone(uint256 duration, Challenger memory challenger) internal view returns (bool) {
        if (address(challenger.maids) == address(0)) {
            return block.number - challenger.enterBlock >= duration;
        } else {
            return
                block.number - challenger.enterBlock >=
                duration -
                    ((duration * powerOfMaids(challenger.maids, challenger.maidId) * maidEfficacy.numerator) /
                        maidEfficacy.denominator);
        }
    }

    function exit(uint256[] calldata ids) external override {
        for (uint256 i = 0; i < ids.length; i++) {
            Challenger memory challenger = challengers[ids[i]][msg.sender];
            require(challenger.enterBlock != 0, "NurseRaid: Not participating in the raid");

            Raid storage raid = raids[ids[i]];

            if (_checkDone(raid.duration, challenger)) {
                uint256 rewardCount = _randomReward(ids[i], raid.maxRewardCount, msg.sender);
                nursePart.mint(msg.sender, raid.nursePart, rewardCount);
            }

            if (address(challenger.maids) != address(0)) {
                challenger.maids.transferFrom(address(this), msg.sender, challenger.maidId);
            }

            delete challengers[ids[i]][msg.sender];
            emit Exit(msg.sender, ids[i]);
        }
    }

    function _randomReward(
        uint256 _id,
        uint256 _maxRewardCount,
        address sender
    ) internal returns (uint256 rewardCount) {
        uint256 totalNumber = 2 * (2**_maxRewardCount - 1);
        uint256 randomNumber = (rng.generateRandomNumber(_id, sender) % totalNumber) + 1;

        uint256 ceil;
        uint256 i = 0;

        while (randomNumber > ceil) {
            i += 1;
            ceil = (2**(_maxRewardCount + 1)) - (2**(_maxRewardCount + 1 - i));
        }

        rewardCount = i;
    }

    function _feeTransfer(uint256 feeToCafe) internal {
        maidCoin.transfer(address(maidCafe), feeToCafe);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMaids.sol";
import "./IMaidCoin.sol";
import "./IMaidCafe.sol";
import "./INursePart.sol";
import "./ICloneNurses.sol";
import "./IRNG.sol";

interface INurseRaid {
    event Create(
        uint256 indexed id,
        uint256 entranceFee,
        uint256 indexed nursePart,
        uint256 maxRewardCount,
        uint256 duration,
        uint256 endBlock
    );
    event Enter(address indexed challenger, uint256 indexed id, IMaids indexed maids, uint256 maidId);
    event Exit(address indexed challenger, uint256 indexed id);
    event ChangeMaidEfficacy(uint256 numerator, uint256 denominator);

    function isMaidsApproved(IMaids maids) external view returns (bool);

    function maidCoin() external view returns (IMaidCoin);

    function maidCafe() external view returns (IMaidCafe);

    function nursePart() external view returns (INursePart);

    function rng() external view returns (IRNG);

    function cloneNurses() external view returns (ICloneNurses);

    function maidEfficacy() external view returns (uint256, uint256);

    function raidCount() external view returns (uint256);

    function create(
        uint256[] calldata entranceFee,
        uint256[] calldata nursePart,
        uint256[] calldata maxRewardCount,
        uint256[] calldata duration,
        uint256[] calldata endBlock
    ) external returns (uint256 id);

    function enter(
        uint256 id,
        IMaids maids,
        uint256 maidId
    ) external;

    function enterWithPermit(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external;

    function enterWithPermitAll(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external;

    function checkDone(uint256 id) external view returns (bool);

    function exit(uint256[] calldata ids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMaids.sol";
import "../interfaces/ISushiGirlsLingerieGIrls.sol";

abstract contract MaidPower is Ownable {
    uint256 public lpTokenToMaidPower = 1000;   //1000 : 1LP(1e18 as wei) => 1Power
    address public immutable sushiGirls;
    address public immutable lingerieGirls;

    event ChangeLPTokenToMaidPower(uint256 value);

    constructor(address _sushiGirls, address _lingerieGirls) {
        sushiGirls = _sushiGirls;
        lingerieGirls = _lingerieGirls;
    }

    function changeLPTokenToMaidPower(uint256 value) external onlyOwner {
        lpTokenToMaidPower = value;
        emit ChangeLPTokenToMaidPower(value);
    }

    function powerOfMaids(IMaids maids, uint256 id) public view returns (uint256) {
        uint256 originPower;
        uint256 supportedLPAmount;

        if (address(maids) == sushiGirls) {
            (originPower, supportedLPAmount,) = ISushiGirls(sushiGirls).sushiGirls(id);
        } else if (address(maids) == lingerieGirls) {
            (originPower, supportedLPAmount,) = ILingerieGirls(lingerieGirls).lingerieGirls(id);
        } else {
            (originPower, supportedLPAmount) = maids.powerAndLP(id);
        }

        return originPower + (supportedLPAmount * lpTokenToMaidPower) / 1e21;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./IMasterChefModule.sol";

interface IMaids is IERC721, IERC721Metadata, IERC721Enumerable, IMasterChefModule {
    event Support(uint256 indexed id, uint256 lpTokenAmount);
    event Desupport(uint256 indexed id, uint256 lpTokenAmount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function PERMIT_ALL_TYPEHASH() external view returns (bytes32);

    function MAX_MAID_COUNT() external view returns (uint256);

    function nonces(uint256 id) external view returns (uint256);

    function noncesForAll(address owner) external view returns (uint256);

    function maids(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );

    function powerAndLP(uint256 id) external view returns (uint256, uint256);

    function support(uint256 id, uint256 lpTokenAmount) external;

    function supportWithPermit(
        uint256 id,
        uint256 lpTokenAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function desupport(uint256 id, uint256 lpTokenAmount) external;

    function claimSushiReward(uint256 id) external;

    function pendingSushiReward(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IMaidCoin {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function INITIAL_SUPPLY() external pure returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMaidCoin.sol";

interface IMaidCafe {
    event Enter(address indexed user, uint256 amount);
    event Leave(address indexed user, uint256 share);

    function maidCoin() external view returns (IMaidCoin);

    function enter(uint256 _amount) external;

    function enterWithPermit(
        uint256 _amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function leave(uint256 _share) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INursePart is IERC1155 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(uint256 id, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ICloneNurseEnumerable.sol";
import "./ISupportable.sol";
import "./INursePart.sol";
import "./IMaidCoin.sol";
import "./ITheMaster.sol";

interface ICloneNurses is IERC721, IERC721Metadata, ICloneNurseEnumerable, ISupportable {
    event Claim(uint256 indexed id, address indexed claimer, uint256 reward);
    event ElongateLifetime(uint256 indexed id, uint256 rechargedLifetime, uint256 lastEndBlock, uint256 newEndBlock);

    function nursePart() external view returns (INursePart);

    function maidCoin() external view returns (IMaidCoin);

    function theMaster() external view returns (ITheMaster);

    function nurseTypes(uint256 typeId)
        external
        view
        returns (
            uint256 partCount,
            uint256 destroyReturn,
            uint256 power,
            uint256 lifetime
        );

    function nurseTypeCount() external view returns (uint256);

    function nurses(uint256 id)
        external
        view
        returns (
            uint256 nurseType,
            uint256 endBlock,
            uint256 lastClaimedBlock
        );

    function assemble(uint256 nurseType, uint256 parts) external;

    function assembleWithPermit(
        uint256 nurseType,
        uint256 parts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function elongateLifetime(uint256[] calldata ids, uint256[] calldata parts) external;

    function destroy(uint256[] calldata ids, uint256[] calldata toIds) external;

    function claim(uint256[] calldata ids) external;

    function pendingReward(uint256 id) external view returns (uint256);

    function findSupportingTo(address supporter) external view returns (address, uint256);

    function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRNG {
    function generateRandomNumber(uint256 seed, address sender) external returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMasterChef.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";

interface IMasterChefModule {
    function lpToken() external view returns (IUniswapV2Pair);

    function sushi() external view returns (IERC20);

    function sushiMasterChef() external view returns (IMasterChef);

    function masterChefPid() external view returns (uint256);

    function sushiLastRewardBlock() external view returns (uint256);

    function accSushiPerShare() external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChef {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

    function userInfo(uint256 pid, address user) external view returns (IMasterChef.UserInfo memory);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface ICloneNurseEnumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISupportable {
    event SupportTo(address indexed supporter, uint256 indexed to);
    event ChangeSupportingRoute(uint256 indexed from, uint256 indexed to);
    event ChangeSupportedPower(uint256 indexed id, int256 power);
    event TransferSupportingRewards(address indexed supporter, uint256 indexed id, uint256 amounts);

    function supportingRoute(uint256 id) external view returns (uint256);

    function supportingTo(address supporter) external view returns (uint256);

    function supportedPower(uint256 id) external view returns (uint256);

    function totalRewardsFromSupporters(uint256 id) external view returns (uint256);

    function setSupportingTo(
        address supporter,
        uint256 to,
        uint256 amounts
    ) external;

    function checkSupportingRoute(address supporter) external returns (address, uint256);

    function changeSupportedPower(address supporter, int256 power) external;

    function shareRewards(
        uint256 pending,
        address supporter,
        uint8 supportingRatio
    ) external returns (address nurseOwner, uint256 amountToNurseOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMaidCoin.sol";
import "./IRewardCalculator.sol";
import "./ISupportable.sol";
import "./IMasterChefModule.sol";

interface ITheMaster is IMasterChefModule {
    event ChangeRewardCalculator(address addr);

    event Add(
        uint256 indexed pid,
        address addr,
        bool indexed delegate,
        bool indexed mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    );

    event Set(uint256 indexed pid, uint256 allocPoint);
    event Deposit(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event Withdraw(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event Support(address indexed supporter, uint256 indexed pid, uint256 amount);
    event Desupport(address indexed supporter, uint256 indexed pid, uint256 amount);
    event EmergencyDesupport(address indexed user, uint256 indexed pid, uint256 amount);

    event SetIsSupporterPool(uint256 indexed pid, bool indexed status);

    function initialRewardPerBlock() external view returns (uint256);

    function decreasingInterval() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function maidCoin() external view returns (IMaidCoin);

    function rewardCalculator() external view returns (IRewardCalculator);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address addr,
            bool delegate,
            ISupportable supportable,
            uint8 supportingRatio,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            uint256 supply
        );

    function poolCount() external view returns (uint256);

    function userInfo(uint256 pid, uint256 user) external view returns (uint256 amount, uint256 rewardDebt);

    function mintableByAddr(address addr) external view returns (bool);

    function totalAllocPoint() external view returns (uint256);

    function pendingReward(uint256 pid, uint256 userId) external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function changeRewardCalculator(address addr) external;

    function add(
        address addr,
        bool delegate,
        bool mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    ) external;

    function set(uint256[] calldata pid, uint256[] calldata allocPoint) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function emergencyWithdraw(uint256 pid) external;

    function support(
        uint256 pid,
        uint256 amount,
        uint256 supportTo
    ) external;

    function supportWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function supportWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function desupport(uint256 pid, uint256 amount) external;

    function emergencyDesupport(uint256 pid) external;

    function mint(address to, uint256 amount) external;

    function claimSushiReward(uint256 id) external;

    function pendingSushiReward(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRewardCalculator {
    function rewardPerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISushiGirls {
    function sushiGirls(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );
}

interface ILingerieGirls {
    function lingerieGirls(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );
}


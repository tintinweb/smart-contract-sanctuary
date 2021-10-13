/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/NFTPool/intf/IFilterAdmin.sol


interface IFilterAdmin {
    function _OWNER_() external view returns (address);

    function _CONTROLLER_() external view returns (address);

    function init(
        address owner,
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint256 feeRate,
        address controller,
        address maintainer,
        address[] memory filters
    ) external;

    function mintFragTo(address to, uint256 rawAmount) external returns (uint256 received);

    function burnFragFrom(address from, uint256 rawAmount) external returns (uint256 paid);

    function queryMintFee(uint256 rawAmount)
        external
        view
        returns (
            uint256 poolFee,
            uint256 mtFee,
            uint256 afterChargedAmount
        );

    function queryBurnFee(uint256 rawAmount)
        external
        view
        returns (
            uint256 poolFee,
            uint256 mtFee,
            uint256 afterChargedAmount
        );
}

// File: contracts/NFTPool/intf/IController.sol


interface IController {
    function getMintFeeRate(address filterAdminAddr) external view returns (uint256);

    function getBurnFeeRate(address filterAdminAddr) external view returns (uint256);

    function isEmergencyWithdrawOpen(address filter) external view returns (bool);
}

// File: contracts/intf/IERC165.sol

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

// File: contracts/intf/IERC721.sol


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

// File: contracts/intf/IERC721Receiver.sol


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

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e.div(2));
            p = p.mul(p) / (10**18);
            if (e % 2 == 1) {
                p = p.mul(target) / (10**18);
            }
            return p;
        }
    }
}

// File: contracts/lib/ReentrancyGuard.sol


/**
 * @title ReentrancyGuard
 * @author DODO Breeder
 *
 * @notice Protect functions from Reentrancy Attack
 */
contract ReentrancyGuard {
    // https://solidity.readthedocs.io/en/latest/control-structures.html?highlight=zero-state#scoping-and-declarations
    // zero-state of _ENTERED_ is false
    bool private _ENTERED_;

    modifier preventReentrant() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }
}

// File: contracts/lib/InitializableOwnable.sol


/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/NFTPool/impl/BaseFilterV1.sol


contract BaseFilterV1 is InitializableOwnable, ReentrancyGuard {
    using SafeMath for uint256;

    //=================== Event ===================
    event NftInOrder(address user, uint256 receiveAmount);
    event TargetOutOrder(address user, uint256 paidAmount);
    event RandomOutOrder(address user, uint256 paidAmount);

    event ChangeNFTInPrice(uint256 newGsStart, uint256 newCr, bool toggleFlag);
    event ChangeNFTRandomOutPrice(uint256 newGsStart, uint256 newCr, bool toggleFlag);
    event ChangeNFTTargetOutPrice(uint256 newGsStart, uint256 newCr, bool toggleFlag);
    event ChangeNFTAmountRange(uint256 maxNFTAmount, uint256 minNFTAmount);
    event ChangeTokenIdRange(uint256 nftIdStart, uint256 nftIdEnd);
    event ChangeTokenIdMap(uint256 tokenIds, bool isRegistered);
    event ChangeFilterName(string newFilterName);

    //=================== Storage ===================
    string public _FILTER_NAME_;

    address public _NFT_COLLECTION_;
    uint256 public _NFT_ID_START_;
    uint256 public _NFT_ID_END_ = uint256(-1);

    //tokenId => isRegistered
    mapping(uint256 => bool) public _SPREAD_IDS_REGISTRY_;

    //tokenId => amount
    mapping(uint256 => uint256) public _NFT_RESERVE_;

    uint256[] public _NFT_IDS_;
    //tokenId => index + 1 of _NFT_IDS_
    mapping(uint256 => uint256) public _TOKENID_IDX_;
    uint256 public _TOTAL_NFT_AMOUNT_;
    uint256 public _MAX_NFT_AMOUNT_;
    uint256 public _MIN_NFT_AMOUNT_;

    // GS -> Geometric sequence
    // CR -> Common Ratio

    //For Deposit NFT IN to Pool
    uint256 public _GS_START_IN_;
    uint256 public _CR_IN_;
    bool public _NFT_IN_TOGGLE_ = false;

    //For NFT Random OUT from Pool
    uint256 public _GS_START_RANDOM_OUT_;
    uint256 public _CR_RANDOM_OUT_;
    bool public _NFT_RANDOM_OUT_TOGGLE_ = false;

    //For NFT Target OUT from Pool
    uint256 public _GS_START_TARGET_OUT_;
    uint256 public _CR_TARGET_OUT_;
    bool public _NFT_TARGET_OUT_TOGGLE_ = false;

    modifier onlySuperOwner() {
        require(msg.sender == IFilterAdmin(_OWNER_)._OWNER_(), "ONLY_SUPER_OWNER");
        _;
    }

    //==================== Query Prop ==================

    function isNFTValid(address nftCollectionAddress, uint256 nftId) external view returns (bool) {
        if (nftCollectionAddress == _NFT_COLLECTION_) {
            return isNFTIDValid(nftId);
        } else {
            return false;
        }
    }

    function isNFTIDValid(uint256 nftId) public view returns (bool) {
        return (nftId >= _NFT_ID_START_ && nftId <= _NFT_ID_END_) || _SPREAD_IDS_REGISTRY_[nftId];
    }

    function getAvaliableNFTInAmount() public view returns (uint256) {
        if (_MAX_NFT_AMOUNT_ <= _TOTAL_NFT_AMOUNT_) {
            return 0;
        } else {
            return _MAX_NFT_AMOUNT_ - _TOTAL_NFT_AMOUNT_;
        }
    }

    function getAvaliableNFTOutAmount() public view returns (uint256) {
        if (_TOTAL_NFT_AMOUNT_ <= _MIN_NFT_AMOUNT_) {
            return 0;
        } else {
            return _TOTAL_NFT_AMOUNT_ - _MIN_NFT_AMOUNT_;
        }
    }

    function getNFTIndexById(uint256 tokenId) public view returns (uint256) {
        require(_TOKENID_IDX_[tokenId] > 0, "TOKEN_ID_NOT_EXSIT");
        return _TOKENID_IDX_[tokenId] - 1;
    }

    //==================== Query Price ==================

    function queryNFTIn(uint256 NFTInAmount)
        public
        view
        returns (
            uint256 rawReceive, 
            uint256 received
        )
    {
        require(NFTInAmount <= getAvaliableNFTInAmount(), "EXCEDD_IN_AMOUNT");
        (rawReceive, received) = _queryNFTIn(_TOTAL_NFT_AMOUNT_,_TOTAL_NFT_AMOUNT_ + NFTInAmount);
    }

    function _queryNFTIn(uint256 start, uint256 end) internal view returns(uint256 rawReceive, uint256 received) {
        rawReceive = _geometricCalc(
            _GS_START_IN_,
            _CR_IN_,
            start,
            end
        );
        (,, received) = IFilterAdmin(_OWNER_).queryMintFee(rawReceive);
    }

    function queryNFTTargetOut(uint256 NFTOutAmount)
        public
        view
        returns (
            uint256 rawPay, 
            uint256 pay
        )
    {
        require(NFTOutAmount <= getAvaliableNFTOutAmount(), "EXCEED_OUT_AMOUNT");
        (rawPay, pay) = _queryNFTTargetOut(_TOTAL_NFT_AMOUNT_ - NFTOutAmount, _TOTAL_NFT_AMOUNT_);
    }

    function _queryNFTTargetOut(uint256 start, uint256 end) internal view returns(uint256 rawPay, uint256 pay) {
        rawPay = _geometricCalc(
            _GS_START_TARGET_OUT_,
            _CR_TARGET_OUT_,
            start,
            end
        );
        (,, pay) = IFilterAdmin(_OWNER_).queryBurnFee(rawPay);
    }

    function queryNFTRandomOut(uint256 NFTOutAmount)
        public
        view
        returns (
            uint256 rawPay, 
            uint256 pay
        )
    {
        require(NFTOutAmount <= getAvaliableNFTOutAmount(), "EXCEED_OUT_AMOUNT");
        (rawPay, pay) = _queryNFTRandomOut(_TOTAL_NFT_AMOUNT_ - NFTOutAmount, _TOTAL_NFT_AMOUNT_);
    }

    function _queryNFTRandomOut(uint256 start, uint256 end) internal view returns(uint256 rawPay, uint256 pay) {
        rawPay = _geometricCalc(
            _GS_START_RANDOM_OUT_,
            _CR_RANDOM_OUT_,
            start,
            end
        );
        (,, pay) = IFilterAdmin(_OWNER_).queryBurnFee(rawPay);
    }

    // ============ Math =============

    function _geometricCalc(
        uint256 a0,
        uint256 q,
        uint256 start,
        uint256 end
    ) internal view returns (uint256) {
        if (q == DecimalMath.ONE) {
            return end.sub(start).mul(a0);
        } 
        //q^n
        uint256 qn = DecimalMath.powFloor(q, end);
        //q^m
        uint256 qm = DecimalMath.powFloor(q, start);
        if (q < DecimalMath.ONE) {
            //Sn=a0*(1 - q^n)/(1-q)
            //Sn-Sm = a0*(q^m - q^n)/(1-q)
            return a0.mul(qm.sub(qn)).div(DecimalMath.ONE.sub(q));
        } else {
            //Sn=a0*(q^n - 1)/(q - 1)
            //Sn-Sm = a0*(q^n - q^m)/(q-1)  
            return a0.mul(qn.sub(qm)).div(q.sub(DecimalMath.ONE));
        }
    }

    function _getRandomNum() public view returns (uint256 randomNum) {
        randomNum = uint256(
            keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), gasleft()))
        );
    }

    // ================= Ownable ================

    function changeNFTInPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) external onlySuperOwner {
        _changeNFTInPrice(newGsStart, newCr, toggleFlag);
    }

    function _changeNFTInPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) internal {
        require(newCr != 0, "CR_INVALID");
        _GS_START_IN_ = newGsStart;
        _CR_IN_ = newCr;
        _NFT_IN_TOGGLE_ = toggleFlag;

        emit ChangeNFTInPrice(newGsStart, newCr, toggleFlag);
    }

    function changeNFTRandomOutPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) external onlySuperOwner {
        _changeNFTRandomOutPrice(newGsStart, newCr, toggleFlag);
    }

    function _changeNFTRandomOutPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) internal {
        require(newCr != 0, "CR_INVALID");
        _GS_START_RANDOM_OUT_ = newGsStart;
        _CR_RANDOM_OUT_ = newCr;
        _NFT_RANDOM_OUT_TOGGLE_ = toggleFlag;

        emit ChangeNFTRandomOutPrice(newGsStart, newCr, toggleFlag);
    }

    function changeNFTTargetOutPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) external onlySuperOwner {
        _changeNFTTargetOutPrice(newGsStart, newCr, toggleFlag);
    }

    function _changeNFTTargetOutPrice(
        uint256 newGsStart,
        uint256 newCr,
        bool toggleFlag
    ) internal {
        require(newCr != 0, "CR_INVALID");
        _GS_START_TARGET_OUT_ = newGsStart;
        _CR_TARGET_OUT_ = newCr;
        _NFT_TARGET_OUT_TOGGLE_ = toggleFlag;

        emit ChangeNFTTargetOutPrice(newGsStart, newCr, toggleFlag);
    }

    function changeNFTAmountRange(uint256 maxNFTAmount, uint256 minNFTAmount)
        external
        onlySuperOwner
    {
        _changeNFTAmountRange(maxNFTAmount, minNFTAmount);
    }

    function _changeNFTAmountRange(uint256 maxNFTAmount, uint256 minNFTAmount) internal {
        require(maxNFTAmount >= minNFTAmount, "AMOUNT_INVALID");
        _MAX_NFT_AMOUNT_ = maxNFTAmount;
        _MIN_NFT_AMOUNT_ = minNFTAmount;

        emit ChangeNFTAmountRange(maxNFTAmount, minNFTAmount);
    }

    function changeTokenIdRange(uint256 nftIdStart, uint256 nftIdEnd) external onlySuperOwner {
        _changeTokenIdRange(nftIdStart, nftIdEnd);
    }

    function _changeTokenIdRange(uint256 nftIdStart, uint256 nftIdEnd) internal {
        require(nftIdStart <= nftIdEnd, "TOKEN_RANGE_INVALID");

        _NFT_ID_START_ = nftIdStart;
        _NFT_ID_END_ = nftIdEnd;

        emit ChangeTokenIdRange(nftIdStart, nftIdEnd);
    }

    function changeTokenIdMap(uint256[] memory tokenIds, bool[] memory isRegistered)
        external
        onlySuperOwner
    {
        _changeTokenIdMap(tokenIds, isRegistered);
    }

    function _changeTokenIdMap(uint256[] memory tokenIds, bool[] memory isRegistered) internal {
        require(tokenIds.length == isRegistered.length, "PARAM_NOT_MATCH");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _SPREAD_IDS_REGISTRY_[tokenIds[i]] = isRegistered[i];
            emit ChangeTokenIdMap(tokenIds[i], isRegistered[i]);
        }
    }

    function changeFilterName(string memory newFilterName)
        external
        onlySuperOwner
    {
        _changeFilterName(newFilterName);
    }

    function _changeFilterName(string memory newFilterName) internal {
        _FILTER_NAME_ = newFilterName;
        emit ChangeFilterName(newFilterName);
    }


    function resetFilter(
        string memory filterName,
        bool[] memory toggles,
        uint256[] memory numParams, //0 - startId, 1 - endId, 2 - maxAmount, 3 - minAmount
        uint256[] memory priceRules,
        uint256[] memory spreadIds,
        bool[] memory isRegistered
    ) external onlySuperOwner {
        _changeFilterName(filterName);
        _changeNFTInPrice(priceRules[0], priceRules[1], toggles[0]);
        _changeNFTRandomOutPrice(priceRules[2], priceRules[3], toggles[1]);
        _changeNFTTargetOutPrice(priceRules[4], priceRules[5], toggles[2]);

        _changeNFTAmountRange(numParams[2], numParams[3]);
        _changeTokenIdRange(numParams[0], numParams[1]);

        _changeTokenIdMap(spreadIds, isRegistered);
    }
}

// File: contracts/NFTPool/impl/FilterERC721V1.sol


contract FilterERC721V1 is IERC721Receiver, BaseFilterV1 {
    using SafeMath for uint256;

    //============== Event =================
    event FilterInit(address filterAdmin, address nftCollection, string name);
    event NftIn(uint256 tokenId);
    event TargetOut(uint256 tokenId);
    event RandomOut(uint256 tokenId);
    event EmergencyWithdraw(address nftContract,uint256 tokenId, address to);

    function init(
        address filterAdmin,
        address nftCollection,
        bool[] memory toggles,
        string memory filterName,
        uint256[] memory numParams, //0 - startId, 1 - endId, 2 - maxAmount, 3 - minAmount
        uint256[] memory priceRules,
        uint256[] memory spreadIds
    ) external {
        initOwner(filterAdmin);

        _changeFilterName(filterName);
        _NFT_COLLECTION_ = nftCollection;
        _changeNFTInPrice(priceRules[0], priceRules[1], toggles[0]);
        _changeNFTRandomOutPrice(priceRules[2], priceRules[3], toggles[1]);
        _changeNFTTargetOutPrice(priceRules[4], priceRules[5], toggles[2]);

        _changeNFTAmountRange(numParams[2], numParams[3]);

        _changeTokenIdRange(numParams[0], numParams[1]);
        for (uint256 i = 0; i < spreadIds.length; i++) {
            _SPREAD_IDS_REGISTRY_[spreadIds[i]] = true;
            emit ChangeTokenIdMap(spreadIds[i], true);
        }

        emit FilterInit(filterAdmin, nftCollection, filterName);
    }

    // ================= Trading ================

    function ERC721In(uint256[] memory tokenIds, address to)
        external
        preventReentrant
        returns (uint256 received)
    {
        require(tokenIds.length <= getAvaliableNFTInAmount(), "EXCEDD_IN_AMOUNT");
        uint256 originTotalNftAmount = _TOTAL_NFT_AMOUNT_;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isNFTIDValid(tokenId), "NFT_ID_NOT_SUPPORT");
            require(
                _NFT_RESERVE_[tokenId] == 0 &&
                    IERC721(_NFT_COLLECTION_).ownerOf(tokenId) == address(this),
                "NFT_NOT_SEND"
            );
            _NFT_IDS_.push(tokenId);
            _TOKENID_IDX_[tokenId] = _NFT_IDS_.length;
            _NFT_RESERVE_[tokenId] = 1;

            emit NftIn(tokenId);
        }
        _TOTAL_NFT_AMOUNT_ = _NFT_IDS_.length;
        (uint256 rawReceive, ) = _queryNFTIn(originTotalNftAmount, originTotalNftAmount + tokenIds.length);
        received = IFilterAdmin(_OWNER_).mintFragTo(to, rawReceive);

        emit NftInOrder(to, received);
    }

    function ERC721TargetOut(uint256[] memory tokenIds, address to, uint256 maxBurnAmount)
        external
        preventReentrant
        returns (uint256 paid)
    {
        (uint256 rawPay, ) = queryNFTTargetOut(tokenIds.length);
        paid = IFilterAdmin(_OWNER_).burnFragFrom(msg.sender, rawPay);
        require(paid <= maxBurnAmount, "BURN_AMOUNT_EXCEED");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _transferOutERC721(to, tokenIds[i]);

            emit TargetOut(tokenIds[i]);
        }
        _TOTAL_NFT_AMOUNT_ = _NFT_IDS_.length;

        emit TargetOutOrder(msg.sender, paid);
    }

    function ERC721RandomOut(uint256 amount, address to, uint256 maxBurnAmount)
        external
        preventReentrant
        returns (uint256 paid)
    {
        (uint256 rawPay, ) = queryNFTRandomOut(amount);
        paid = IFilterAdmin(_OWNER_).burnFragFrom(msg.sender, rawPay);
        require(paid <= maxBurnAmount, "BURN_AMOUNT_EXCEED");
        for (uint256 i = 0; i < amount; i++) {
            uint256 index = _getRandomNum() % _NFT_IDS_.length;
            uint256 tokenId = _NFT_IDS_[index];
            _transferOutERC721(to, tokenId);
            emit RandomOut(tokenId);
        }
        _TOTAL_NFT_AMOUNT_ = _NFT_IDS_.length;

        emit RandomOutOrder(msg.sender, paid);
    }

    // ============ Transfer =============

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _transferOutERC721(address to, uint256 tokenId) internal {
        require(_TOKENID_IDX_[tokenId] > 0, "TOKENID_NOT_EXIST");
        uint256 index = _TOKENID_IDX_[tokenId] - 1;
        require(index < _NFT_IDS_.length, "INDEX_INVALID");
        IERC721(_NFT_COLLECTION_).safeTransferFrom(address(this), to, tokenId);
        if(index != _NFT_IDS_.length - 1) {
            uint256 lastTokenId = _NFT_IDS_[_NFT_IDS_.length - 1];
            _NFT_IDS_[index] = lastTokenId;
            _TOKENID_IDX_[lastTokenId] = index + 1;
        }
        _NFT_IDS_.pop();
        _NFT_RESERVE_[tokenId] = 0;
        _TOKENID_IDX_[tokenId] = 0;
    }

    function emergencyWithdraw(
        address[] memory nftContract,
        uint256[] memory tokenIds,
        address to
    ) external onlySuperOwner {
        require(nftContract.length == tokenIds.length, "PARAM_INVALID");
        address controller = IFilterAdmin(_OWNER_)._CONTROLLER_();
        require(
            IController(controller).isEmergencyWithdrawOpen(address(this)),
            "EMERGENCY_WITHDRAW_NOT_OPEN"
        );

        for (uint256 i = 0; i < nftContract.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (_NFT_RESERVE_[tokenId] > 0 && nftContract[i] == _NFT_COLLECTION_) {
                uint256 index = getNFTIndexById(tokenId);
                if(index != _NFT_IDS_.length - 1) {
                    uint256 lastTokenId = _NFT_IDS_[_NFT_IDS_.length - 1];
                    _NFT_IDS_[index] = lastTokenId;
                    _TOKENID_IDX_[lastTokenId] = index + 1;
                }
                _NFT_IDS_.pop();
                _NFT_RESERVE_[tokenId] = 0;
                _TOKENID_IDX_[tokenId] = 0;
            }
            IERC721(nftContract[i]).safeTransferFrom(address(this), to, tokenIds[i]);
            emit EmergencyWithdraw(nftContract[i],tokenIds[i],to);
        }
        _TOTAL_NFT_AMOUNT_ = _NFT_IDS_.length;
    }

    // ============ Support ============

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
    }

    function version() external pure virtual returns (string memory) {
        return "FILTER_1_ERC721 1.0.0";
    }
}
/**
 *Submitted for verification at polygonscan.com on 2021-10-13
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

// File: contracts/intf/IERC1155.sol



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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/intf/IERC1155Receiver.sol


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
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

// File: contracts/NFTPool/impl/FilterERC1155V1.sol



contract FilterERC1155V1 is IERC1155Receiver, BaseFilterV1 {
    using SafeMath for uint256;

    //=============== Event ==================
    event FilterInit(address filterAdmin, address nftCollection, string name);
    event NftIn(uint256 tokenId, uint256 amount);
    event TargetOut(uint256 tokenId, uint256 amount);
    event RandomOut(uint256 tokenId, uint256 amount);
    event EmergencyWithdraw(address nftContract,uint256 tokenId, uint256 amount, address to);

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

    function ERC1155In(uint256[] memory tokenIds, address to)
        external
        preventReentrant
        returns (uint256 received)
    {
        uint256 avaliableNFTInAmount = getAvaliableNFTInAmount();
        uint256 originTotalNftAmount = _TOTAL_NFT_AMOUNT_;

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isNFTIDValid(tokenId), "NFT_ID_NOT_SUPPORT");
            uint256 inAmount = _maintainERC1155In(tokenId);
            totalAmount = totalAmount.add(inAmount);
            emit NftIn(tokenId, inAmount);
        }
        require(totalAmount <= avaliableNFTInAmount, "EXCEDD_IN_AMOUNT");
        (uint256 rawReceive, ) = _queryNFTIn(originTotalNftAmount, originTotalNftAmount + totalAmount);
        received = IFilterAdmin(_OWNER_).mintFragTo(to, rawReceive);

        emit NftInOrder(to, received);
    }

    function ERC1155TargetOut(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address to,
        uint256 maxBurnAmount 
    ) external preventReentrant returns (uint256 paid) {
        require(tokenIds.length == amounts.length, "PARAM_INVALID");
        uint256 avaliableNFTOutAmount = getAvaliableNFTOutAmount();
        uint256 originTotalNftAmount = _TOTAL_NFT_AMOUNT_;

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
            _transferOutERC1155(to, tokenIds[i], amounts[i]);
            emit TargetOut(tokenIds[i], amounts[i]);
        }
        require(totalAmount <= avaliableNFTOutAmount, "EXCEED_OUT_AMOUNT");
        (uint256 rawPay, ) = _queryNFTTargetOut(originTotalNftAmount - totalAmount, originTotalNftAmount);
        paid = IFilterAdmin(_OWNER_).burnFragFrom(msg.sender, rawPay);
        require(paid <= maxBurnAmount, "BURN_AMOUNT_EXCEED");

        emit TargetOutOrder(msg.sender, paid);
    }

    function ERC1155RandomOut(uint256 amount, address to, uint256 maxBurnAmount)
        external
        preventReentrant
        returns (uint256 paid)
    {
        (uint256 rawPay, ) = queryNFTRandomOut(amount);
        paid = IFilterAdmin(_OWNER_).burnFragFrom(msg.sender, rawPay);
        require(paid <= maxBurnAmount, "BURN_AMOUNT_EXCEED");

        for (uint256 i = 0; i < amount; i++) {
            uint256 randomNum = _getRandomNum() % _TOTAL_NFT_AMOUNT_;
            uint256 sum;
            for (uint256 j = 0; j < _NFT_IDS_.length; j++) {
                uint256 tokenId = _NFT_IDS_[j];
                sum = sum.add(_NFT_RESERVE_[tokenId]);
                if (sum >= randomNum) {
                    _transferOutERC1155(to, tokenId, 1);
                    emit RandomOut(tokenId, 1);
                    break;
                }
            }
        }

        emit RandomOutOrder(msg.sender, paid);
    }

    // ============ Transfer =============

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function _transferOutERC1155(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(_TOKENID_IDX_[tokenId] > 0, "TOKENID_NOT_EXIST");
        IERC1155(_NFT_COLLECTION_).safeTransferFrom(address(this), to, tokenId, amount, "");
        _maintainERC1155Out(tokenId);
    }

    function emergencyWithdraw(
        address[] memory nftContract,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address to
    ) external onlySuperOwner {
        require(
            nftContract.length == tokenIds.length && nftContract.length == amounts.length,
            "PARAM_INVALID"
        );
        address controller = IFilterAdmin(_OWNER_)._CONTROLLER_();
        require(
            IController(controller).isEmergencyWithdrawOpen(address(this)),
            "EMERGENCY_WITHDRAW_NOT_OPEN"
        );

        for (uint256 i = 0; i < nftContract.length; i++) {
            uint256 tokenId = tokenIds[i];
            IERC1155(nftContract[i]).safeTransferFrom(address(this), to, tokenId, amounts[i], "");
            if (_NFT_RESERVE_[tokenId] > 0 && nftContract[i] == _NFT_COLLECTION_) {
                _maintainERC1155Out(tokenId);
            }
            emit EmergencyWithdraw(nftContract[i],tokenIds[i], amounts[i], to);
        }
    }

    function _maintainERC1155Out(uint256 tokenId) internal {
        uint256 currentAmount = IERC1155(_NFT_COLLECTION_).balanceOf(address(this), tokenId);
        uint256 outAmount = _NFT_RESERVE_[tokenId].sub(currentAmount);
        _NFT_RESERVE_[tokenId] = currentAmount;
        _TOTAL_NFT_AMOUNT_ = _TOTAL_NFT_AMOUNT_.sub(outAmount);
        if (currentAmount == 0) {
            uint256 index = _TOKENID_IDX_[tokenId] - 1;
            if(index != _NFT_IDS_.length - 1) {
                uint256 lastTokenId = _NFT_IDS_[_NFT_IDS_.length - 1];
                _NFT_IDS_[index] = lastTokenId;
                _TOKENID_IDX_[lastTokenId] = index + 1;
            }
            _NFT_IDS_.pop();
            _TOKENID_IDX_[tokenId] = 0;
        }
    }

    function _maintainERC1155In(uint256 tokenId) internal returns (uint256 inAmount) {
        uint256 currentAmount = IERC1155(_NFT_COLLECTION_).balanceOf(address(this), tokenId);
        inAmount = currentAmount.sub(_NFT_RESERVE_[tokenId]);
        if (_NFT_RESERVE_[tokenId] == 0 && currentAmount > 0) {
            _NFT_IDS_.push(tokenId);
            _TOKENID_IDX_[tokenId] = _NFT_IDS_.length;
        }
        _NFT_RESERVE_[tokenId] = currentAmount;
        _TOTAL_NFT_AMOUNT_ = _TOTAL_NFT_AMOUNT_.add(inAmount);
    }

    // ============ Support ============

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function version() external pure virtual returns (string memory) {
        return "FILTER_1_ERC1155 1.0.0";
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./IMosaicNFT.sol";
import "./ISummonerConfig.sol";

// @title: Composable Finance L2 ERC721 Vault
contract Summoner is
    IERC721ReceiverUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct Fee {
        address tokenAddress;
        uint256 amount;
    }

    struct TransferTemporaryData {
        string sourceUri;
        uint256 originalNetworkId;
        uint256 originalNftId;
        bytes32 id;
        bool isRelease;
        address originalNftAddress;
    }

    ISummonerConfig public config;
    address public mosaicNftAddress;
    address public relayer;

    uint256 nonce;

    uint256[] private preMints;

    mapping(address => uint256) public lastTransfer;
    mapping(bytes32 => bool) public hasBeenSummoned; //hasBeenWithdrawn
    mapping(bytes32 => bool) public hasBeenReleased; //hasBeenUnlocked
    bytes32 public lastSummonedID; //lastWithdrawnID
    bytes32 public lastReleasedID; //lastUnlockedID

    // stores the fee collected by the contract against a transfer id
    mapping(bytes32 => Fee) private feeCollection;

    event TransferInitiated(
        address indexed sourceNftOwner,
        address indexed sourceNftAddress,
        uint256 indexed sourceNFTId,
        string sourceUri,
        address destinationAddress,
        uint256 destinationNetworkID,
        address originalNftAddress,
        uint256 originalNetworkID,
        uint256 originalNftId,
        uint256 transferDelay,
        bool isRelease,
        bytes32 id
    );

    event SealReleased(
        address indexed nftOwner,
        address indexed nftContract,
        uint256 indexed nftId,
        bytes32 id
    );

    event SummonCompleted(
        address indexed nftOwner,
        address indexed destinationNftContract,
        string nftUri,
        bytes32 id
    );

    event FeeTaken(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed nftId,
        bytes32 id,
        uint256 remoteNetworkId,
        address feeToken,
        uint256 feeAmount
    );

    event FeeRefunded(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed nftId,
        bytes32 id,
        address feeToken,
        uint256 feeAmount
    );
    event ValueChanged(
        address indexed owner,
        address oldConfig,
        address newConfig,
        string valType
    );

    function initialize(address _config) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        nonce = 0;
        config = ISummonerConfig(_config);
    }

    function setConfig(address _config) external onlyOwner {
        emit ValueChanged(msg.sender, address(config), _config, "CONFIG");
        config = ISummonerConfig(_config);
    }

    function setMosaicNft(address _mosaicNftAddress) external onlyOwner {
        require(preMints.length == 0, "ALREADY PRE-MINTED");
        require(lastSummonedID == "", "ALREADY SUMMONED");
        require(_mosaicNftAddress != mosaicNftAddress, "SAME ADDRESS");
        emit ValueChanged(
            msg.sender,
            mosaicNftAddress,
            _mosaicNftAddress,
            "MOSAICNFT"
        );
        mosaicNftAddress = _mosaicNftAddress;
    }

    function setRelayer(address _relayer) external onlyOwner {
        emit ValueChanged(msg.sender, relayer, _relayer, "RELAYER");
        relayer = _relayer;
    }

    /// @notice External callable function to pause the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function transferERC721ToLayer(
        address _sourceNFTAddress,
        uint256 _sourceNFTId,
        address _destinationAddress,
        uint256 _destinationNetworkID,
        uint256 _transferDelay,
        address _feeToken
    ) external payable nonReentrant {
        require(mosaicNftAddress != address(0), "MOSAIC NFT NOT SET");
        require(_sourceNFTAddress != address(0), "NFT ADDRESS");
        require(_destinationAddress != address(0), "DEST ADDRESS");
        require(paused() == false, "CONTRACT PAUSED");
        require(
            config.getPausedNetwork(_destinationNetworkID) == false,
            "NETWORK PAUSED"
        );
        require(
            lastTransfer[msg.sender] + config.getTransferLockupTime() <
                block.timestamp,
            "TIMESTAMP"
        );
        require(
            config.getFeeTokenAmount(_destinationNetworkID, _feeToken) > 0,
            "FEE TOKEN"
        );
        require(_destinationNetworkID != _chainId(), "TRANSFER TO SAME NETWORK");

        IERC721Upgradeable(_sourceNFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _sourceNFTId
        );
        lastTransfer[msg.sender] = block.timestamp;

        TransferTemporaryData memory tempData;
        tempData.id = _generateId();
        tempData.sourceUri = IERC721MetadataUpgradeable(_sourceNFTAddress)
            .tokenURI(_sourceNFTId);

        if (_sourceNFTAddress == mosaicNftAddress) {
            (
                tempData.originalNftAddress,
                tempData.originalNetworkId,
                tempData.originalNftId
            ) = IMosaicNFT(mosaicNftAddress).getOriginalNftInfo(_sourceNFTId);
        } else {
            tempData.originalNftAddress = _sourceNFTAddress;
            tempData.originalNetworkId = _chainId();
            tempData.originalNftId = _sourceNFTId;
        }

        if (
            _destinationNetworkID == tempData.originalNetworkId &&
            mosaicNftAddress == _sourceNFTAddress
        ) {
            // mosaicNftAddress is being transferred to the original network
            // in this case release the original nft instead of summoning
            // the relayer will read this event and call releaseSeal on the original layer
            tempData.isRelease = true;
        }

        // the relayer will read this event and call summonNFT or releaseSeal
        // based on the value of isRelease
        emit TransferInitiated(
            msg.sender,
            _sourceNFTAddress,
            _sourceNFTId,
            tempData.sourceUri,
            _destinationAddress,
            _destinationNetworkID,
            tempData.originalNftAddress,
            tempData.originalNetworkId,
            tempData.originalNftId,
            _transferDelay,
            tempData.isRelease,
            tempData.id
        );

        // take fees
        _takeFees(
            _sourceNFTAddress,
            _sourceNFTId,
            tempData.id,
            _destinationNetworkID,
            _feeToken
        );
    }

    function _takeFees(
        address _nftContract,
        uint256 _nftId,
        bytes32 _id,
        uint256 _remoteNetworkID,
        address _feeToken
    ) private {
        uint256 fee = config.getFeeTokenAmount(_remoteNetworkID, _feeToken);
        if (_feeToken != address(0)) {
            require(
                IERC20Upgradeable(_feeToken).balanceOf(msg.sender) >= fee,
                "LOW BAL"
            );
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(_feeToken),
                msg.sender,
                address(this),
                fee
            );
        } else {
            require(msg.value >= fee, "FEE");
        }
        // store the collected fee
        feeCollection[_id] = Fee(_feeToken, fee);
        emit FeeTaken(
            msg.sender,
            _nftContract,
            _nftId,
            _id,
            _remoteNetworkID,
            _feeToken,
            fee
        );
    }

    // either summon failed or it's a transfer of the NFT back to the original layer
    function releaseSeal(
        address _nftOwner,
        address _nftContract,
        uint256 _nftId,
        bytes32 _id,
        bool _isFailure
    ) public nonReentrant onlyOwnerOrRelayer {
        require(paused() == false, "CONTRACT PAUSED");
        require(hasBeenReleased[_id] == false, "RELEASED");
        require(
            IERC721Upgradeable(_nftContract).ownerOf(_nftId) == address(this),
            "NOT LOCKED"
        );

        hasBeenReleased[_id] = true;
        lastReleasedID = _id;

        IERC721Upgradeable(_nftContract).safeTransferFrom(
            address(this),
            _nftOwner,
            _nftId
        );

        emit SealReleased(_nftOwner, _nftContract, _nftId, _id);

        // refund fee in case of a failed transaction only
        if (_isFailure == true) {
            _refundFees(_nftOwner, _nftContract, _nftId, _id);
        }
    }

    function _refundFees(
        address _nftOwner,
        address _nftContract,
        uint256 _nftId,
        bytes32 _id
    ) private {
        Fee memory fee = feeCollection[_id];
        // refund the fee
        if (fee.tokenAddress != address(0)) {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(fee.tokenAddress),
                _nftOwner,
                fee.amount
            );
        } else {
            (bool success, ) = _nftOwner.call{value: fee.amount}("");
            if (success == false) {
                revert("FAILED REFUND");
            }
        }
        emit FeeRefunded(
            msg.sender,
            _nftContract,
            _nftId,
            _id,
            fee.tokenAddress,
            fee.amount
        );
    }

    function withdrawFees(
        address _feeToken,
        address _withdrawTo,
        uint256 _amount
    ) external nonReentrant onlyOwner {
        if (_feeToken != address(0)) {
            require(
                IERC20Upgradeable(_feeToken).balanceOf(address(this)) >= _amount,
                "LOW BAL"
            );
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_feeToken),
                _withdrawTo,
                _amount
            );
        } else {
            require(address(this).balance >= _amount, "LOW BAL");
            (bool success, ) = _withdrawTo.call{value: _amount}("");
            if (success == false) {
                revert("FAILED");
            }
        }
    }

    /// @notice method called by the relayer to summon the NFT
    function summonNFT(
        string memory _nftUri,
        address _destinationAddress,
        address _originalNftAddress,
        uint256 _originalNetworkID,
        uint256 _originalNftId,
        bytes32 _id
    ) public nonReentrant onlyOwnerOrRelayer {
        // summon NFT cannot be called on the original network
        // the transfer method will always emit release event for this
        require(_chainId() != _originalNetworkID, "SUMMONED ON ORIGINAL NETWORK");
        require(_originalNftAddress != address(0), "ORIGINAL NFT ADDRESS");
        require(paused() == false, "CONTRACT PAUSED");
        require(hasBeenSummoned[_id] == false, "SUMMONED");

        hasBeenSummoned[_id] = true;
        lastSummonedID = _id;

        uint256 mosaicNFTId = IMosaicNFT(mosaicNftAddress).getNftId(
            _originalNftAddress,
            _originalNetworkID,
            _originalNftId
        );

        // original NFT is first time getting transferred
        if (mosaicNFTId == 0) {
            // use a pre minted nft and set the meta data
            mosaicNFTId = getPreMintedNftId();
            if (mosaicNFTId != 0) {
                // set the metadata on the pre minted NFT
                IMosaicNFT(mosaicNftAddress).setNFTMetadata(
                    mosaicNFTId,
                    _nftUri,
                    _originalNftAddress,
                    _originalNetworkID,
                    _originalNftId
                );
                // transfer the nft to the user
                 IERC721Upgradeable(mosaicNftAddress).safeTransferFrom(
                    address(this),
                     _destinationAddress,
                    mosaicNFTId
                 );
            } else {
                // if no pre mint found mint a new one
                IMosaicNFT(mosaicNftAddress).mintNFT(
                    _destinationAddress,
                    _nftUri,
                    _originalNftAddress,
                    _originalNetworkID,
                    _originalNftId
                );
            }
        } else {
            // the original nft is locked from a previous transfer from another layer
            // so we need to transfer the NFT instead of minting a new one
            IERC721Upgradeable(mosaicNftAddress).safeTransferFrom(
                address(this),
                _destinationAddress,
                mosaicNFTId
            );
        }

        emit SummonCompleted(_destinationAddress, mosaicNftAddress, _nftUri, _id);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _generateId() private returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(block.number, _chainId(), address(this), nonce++)
            );
    }

    function preMintNFT(uint256 n) external onlyOwnerOrRelayer {
        require(mosaicNftAddress != address(0), "MOSAIC NFT NOT SET");
        for (uint256 i = 0; i < n; i++) {
            uint256 nftId = IMosaicNFT(mosaicNftAddress).preMintNFT();
            preMints.push(nftId);
        }
    }

    function getPreMintedNftId() private returns (uint256) {
        uint256 nftId;
        if (preMints.length > 0) {
            nftId = preMints[preMints.length - 1];
            preMints.pop();
        }
        return nftId;
    }

    function getPreMintedCount() external view returns (uint256) {
        return preMints.length;
    }

    function _chainId() private view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    modifier onlyOwnerOrRelayer() {
        require(
            _msgSender() == owner() || _msgSender() == relayer,
            "ONLY OWNER OR RELAYER"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

interface IMosaicNFT {

    function getOriginalNftInfo(uint256 nftId) external view returns (address, uint256, uint256);

    function getNftId(
        address originalNftAddress,
        uint256 originalNetworkID,
        uint256 originalNftId
    ) external view returns (uint256);

    function mintNFT(
        address _to,
        string memory _tokenURI,
        address originalNftAddress,
        uint256 originalNetworkId,
        uint256 originalNftId
    )
    external;

    function preMintNFT() external returns(uint256);

    function setNFTMetadata(
        uint256 nftId,
        string memory nftUri,
        address originalNftAddress,
        uint256 originalNetworkID,
        uint256 originalNftId
    ) external;

}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

interface ISummonerConfig {
    function getTransferLockupTime() external view returns (uint256);

    function getFeeTokenAmount(uint256 remoteNetworkId, address feeToken) external view returns (uint256);

    function getPausedNetwork(uint256 networkId) external view returns (bool);

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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
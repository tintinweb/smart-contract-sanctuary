// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorOpenSaleV0, IMirrorOpenSaleV0Events} from "./interface/IMirrorOpenSaleV0.sol";
import {Reentrancy} from "../../lib/Reentrancy.sol";
import {IERC165} from "../../lib/ERC165/interface/IERC165.sol";
import {IERC2981} from "../../lib/ERC2981/interface/IERC2981.sol";
import {ITreasuryConfig} from "../../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../treasury/interface/IMirrorTreasury.sol";
import {IMirrorFeeRegistry} from "../../fee-registry/MirrorFeeRegistry.sol";
import {IERC721Events} from "../../lib/ERC721/interface/IERC721.sol";

/**
 * @title MirrorOpenSaleV0
 *
 * @notice The Mirror Open Sale allows anyone to list an ERC721 with a tokenId range.
 *
 * Each token will be sold with tokenId incrementing starting at the lower end of the range.
 * To minimize storage we hash all sale configuration to generate a unique ID and only store
 * the necessary data that maintains the sale state.
 *
 * The token holder must first approve this contract otherwise purchasing will revert.
 *
 * The contract forwards the ether payment to the specified recipient and pays an optional fee
 * to the Mirror Treasury (0x138c3d30a724de380739aad9ec94e59e613a9008). Additionally, sale
 * royalties are distributed using the NFT Roylaties Standard (EIP-2981).
 *
 * @author MirrorXYZ
 */
contract MirrorOpenSaleV0 is
    IMirrorOpenSaleV0,
    IMirrorOpenSaleV0Events,
    IERC721Events,
    Reentrancy
{
    /// @notice Version
    uint8 public constant VERSION = 0;

    /// @notice Mirror treasury configuration
    address public immutable override treasuryConfig;

    /// @notice Mirror fee registry
    address public immutable override feeRegistry;

    /// @notice Mirror tributary registry
    address public immutable override tributaryRegistry;

    /// @notice Map of sale data hash to sale state
    mapping(bytes32 => Sale) internal sales_;

    /// @notice Store configuration and registry addresses as immutable
    /// @param treasuryConfig_ address for Mirror treasury configuration
    /// @param feeRegistry_ address for Mirror fee registry
    /// @param tributaryRegistry_ address for Mirror tributary registry
    constructor(
        address treasuryConfig_,
        address feeRegistry_,
        address tributaryRegistry_
    ) {
        treasuryConfig = treasuryConfig_;
        feeRegistry = feeRegistry_;
        tributaryRegistry = tributaryRegistry_;
    }

    /// @notice Get stored state for a specific sale
    /// @param h keccak256 of sale configuration (see `_getHash`)
    function sale(bytes32 h) external view override returns (Sale memory) {
        return sales_[h];
    }

    /// @notice Register a sale
    /// @dev only the token itself or the operator can list tokens
    /// @param saleConfig_ sale configuration
    function register(SaleConfig calldata saleConfig_) external override {
        require(
            msg.sender == saleConfig_.token ||
                msg.sender == saleConfig_.operator,
            "cannot register"
        );

        _register(saleConfig_);
    }

    /// @notice Close a sale
    /// @dev Reverts if called by an account that does not operate the sale
    /// @param saleConfig_ sale configuration
    function close(SaleConfig calldata saleConfig_) external override {
        require(msg.sender == saleConfig_.operator, "not operator");

        _setSaleStatus(saleConfig_, false);
    }

    /// @notice Open a sale
    /// @dev Reverts if called by an account that does not operate the sale
    /// @param saleConfig_ sale configuration
    function open(SaleConfig calldata saleConfig_) external override {
        require(msg.sender == saleConfig_.operator, "not operator");

        _setSaleStatus(saleConfig_, true);
    }

    /// @notice Purchase a token
    /// @dev Reverts if the sale configuration does not hash to an open sale,
    ///  not enough ether is sent, he sale is sold out, or if token approval
    ///  has not been granted. Sends funds to the recipient and treasury.
    /// @param saleConfig_ sale configuration
    /// @param recipient account that will receive the purchased token
    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable
        override
        nonReentrant
    {
        // generate hash of sale data
        bytes32 h = _getHash(saleConfig_);

        // retrive stored sale data
        Sale storage s = sales_[h];

        // the registered field serves to assert that the hash maps to
        // a listed sale and the open field asserts the listed sale is open
        require(s.registered && s.open, "closed sale");

        // assert correct amount of eth is received
        require(msg.value == saleConfig_.price, "incorrect value");

        // calculate next tokenId, and increment amount sold
        uint256 tokenId = saleConfig_.startTokenId + s.sold++;

        // check that the tokenId is valid
        require(tokenId <= saleConfig_.endTokenId, "sold out");

        // transfer token to recipient
        IERC721(saleConfig_.token).transferFrom(
            saleConfig_.operator,
            recipient,
            tokenId
        );

        emit Purchase(
            // h
            h,
            // token
            saleConfig_.token,
            // tokenId
            tokenId,
            // buyer
            msg.sender,
            // recipient
            recipient
        );

        // send funds to recipient and pay fees if necessary
        _withdraw(
            saleConfig_.operator,
            saleConfig_.token,
            tokenId,
            h,
            saleConfig_.recipient,
            msg.value,
            saleConfig_.feePercentage
        );
    }

    // ============ Internal Methods ============

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10_000;
    }

    function _getHash(SaleConfig calldata saleConfig_)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    saleConfig_.token,
                    saleConfig_.startTokenId,
                    saleConfig_.endTokenId,
                    saleConfig_.operator,
                    saleConfig_.recipient,
                    saleConfig_.price,
                    saleConfig_.open,
                    saleConfig_.feePercentage
                )
            );
    }

    function _register(SaleConfig calldata saleConfig_) internal {
        // get maximum fee from fees registry
        uint256 maxFee = IMirrorFeeRegistry(feeRegistry).maxFee();

        // allow to pay any fee below the max, including no fees
        require(saleConfig_.feePercentage <= maxFee, "fee too high");

        // generate hash of sale data
        bytes32 h = _getHash(saleConfig_);

        // assert the sale has not been registered previously
        require(!sales_[h].registered, "sale already registered");

        // store critical sale data
        sales_[h] = Sale({
            registered: true,
            open: saleConfig_.open,
            sold: 0,
            operator: saleConfig_.operator
        });

        // all fields used to generate the hash need to be emitted to store and
        // generate the hash off-chain for interacting with the sale
        emit RegisteredSale(
            // h
            h,
            // token
            saleConfig_.token,
            // startTokenId
            saleConfig_.startTokenId,
            // endTokenId
            saleConfig_.endTokenId,
            // operator
            saleConfig_.operator,
            // recipient
            saleConfig_.recipient,
            // price
            saleConfig_.price,
            // open
            saleConfig_.open,
            // feePercentage
            saleConfig_.feePercentage
        );

        if (saleConfig_.open) {
            emit OpenSale(h);
        } else {
            emit CloseSale(h);
        }
    }

    function _setSaleStatus(SaleConfig calldata saleConfig_, bool status)
        internal
    {
        bytes32 h = _getHash(saleConfig_);

        // assert the sale is registered
        require(sales_[h].registered, "unregistered sale");

        require(sales_[h].open != status, "status already set");

        sales_[h].open = status;

        if (status) {
            emit OpenSale(h);
        } else {
            emit CloseSale(h);
        }
    }

    function _withdraw(
        address operator,
        address token,
        uint256 tokenId,
        bytes32 h,
        address recipient,
        uint256 totalAmount,
        uint256 feePercentage
    ) internal {
        uint256 feeAmount = 0;

        if (feePercentage > 0) {
            // calculate fee amount
            feeAmount = _feeAmount(totalAmount, feePercentage);

            // contribute to treasury
            IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                .contributeWithTributary{value: feeAmount}(operator);
        }

        uint256 saleAmount = totalAmount - feeAmount;

        (address royaltyRecipient, uint256 royaltyAmount) = _royaltyInfo(
            token,
            tokenId,
            saleAmount
        );

        require(royaltyAmount < saleAmount, "invalid royalty amount");

        if (msg.sender == royaltyRecipient || royaltyRecipient == address(0)) {
            // transfer funds to recipient
            _send(payable(recipient), saleAmount);

            // emit an event describing the withdrawal
            emit Withdraw(h, totalAmount, feeAmount, recipient);
        } else {
            // transfer funds to recipient
            _send(payable(recipient), saleAmount - royaltyAmount);

            // transfer royalties
            _send(payable(royaltyRecipient), royaltyAmount);

            // emit an event describing the withdrawal
            emit Withdraw(h, totalAmount, feeAmount, recipient);
        }
    }

    function _royaltyInfo(
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal view returns (address royaltyRecipient, uint256 royaltyAmount) {
        // get royalty info
        if (IERC165(token).supportsInterface(type(IERC2981).interfaceId)) {
            (royaltyRecipient, royaltyAmount) = IERC2981(token).royaltyInfo(
                tokenId,
                amount
            );
        }
    }

    function _send(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
    }
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorOpenSaleV0Events {
    event RegisteredSale(
        bytes32 h,
        address indexed token,
        uint256 startTokenId,
        uint256 endTokenId,
        address indexed operator,
        address indexed recipient,
        uint256 price,
        bool open,
        uint256 feePercentage
    );

    event Purchase(
        bytes32 h,
        address indexed token,
        uint256 tokenId,
        address indexed buyer,
        address indexed recipient
    );

    event Withdraw(
        bytes32 h,
        uint256 amount,
        uint256 fee,
        address indexed recipient
    );

    event OpenSale(bytes32 h);

    event CloseSale(bytes32 h);
}

interface IMirrorOpenSaleV0 {
    struct Sale {
        bool registered;
        bool open;
        uint256 sold;
        address operator;
    }

    struct SaleConfig {
        address token;
        uint256 startTokenId;
        uint256 endTokenId;
        address operator;
        address recipient;
        uint256 price;
        bool open;
        uint256 feePercentage;
    }

    function treasuryConfig() external returns (address);

    function feeRegistry() external returns (address);

    function tributaryRegistry() external returns (address);

    function sale(bytes32 h) external view returns (Sale memory);

    function register(SaleConfig calldata saleConfig_) external;

    function close(SaleConfig calldata saleConfig_) external;

    function open(SaleConfig calldata saleConfig_) external;

    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/**
 * @title IERC2981
 * @notice Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    // / bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IMirrorFeeRegistry {
    function maxFee() external returns (uint256);

    function updateMaxFee(uint256 newFee) external;
}

/**
 * @title MirrorFeeRegistry
 * @author MirrorXYZ
 */
contract MirrorFeeRegistry is IMirrorFeeRegistry, Ownable {
    uint256 public override maxFee = 500;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint256 newFee) external override onlyOwner {
        maxFee = newFee;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }
}
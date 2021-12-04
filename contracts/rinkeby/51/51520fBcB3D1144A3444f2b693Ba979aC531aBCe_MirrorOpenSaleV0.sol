// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Reentrancy} from "../../lib/Reentrancy.sol";
import {ITreasuryConfig} from "../../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../treasury/interface/IMirrorTreasury.sol";
import {IMirrorFeeRegistry} from "../../fee-registry/MirrorFeeRegistry.sol";
import {IMirrorOpenSaleV0, IMirrorOpenSaleV0Events} from "./interface/IMirrorOpenSaleV0.sol";
import {IERC165} from "../../lib/ERC165/interface/IERC165.sol";
import {IERC2981} from "../../lib/ERC2981/interface/IERC2981.sol";

/**
 * @title MirrorOpenSaleV0
 * The Mirror Open Sale allows anyone to list an ERC721 with a tokenId range.
 * Each tokenId will be sold incrementally starting at the lower end of the range.
 * To minimize storage we hash all listing data (sale configuration) to generate a
 * unique ID and only store the necessary information that maintains the listing state.
 * The token holder must first approve this contract otherwise purchasing will revert.
 * @author MirrorXYZ ([email protected])
 */
contract MirrorOpenSaleV0 is
    IMirrorOpenSaleV0,
    IMirrorOpenSaleV0Events,
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

    /// @notice Count of how many sales have been listed
    uint256 public override count;

    /// @notice Store configuration addresses as immutable
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
    ///  if not enough ether is sent, if the sale is sold out, or if token approval
    ///  has not been granted. Sends funds to the recipient and treasury.
    /// @param saleConfig_ sale configuration
    /// @param recipient account that will receive the token
    function purchase(SaleConfig calldata saleConfig_, address recipient)
        external
        payable
        override
        nonReentrant
    {
        bytes32 h = _getHash(saleConfig_);

        Sale storage s = sales_[h];

        // the open field serves as a check to validate the hash maps to
        // a listed sale and that the listed sale is open
        require(s.open, "closed sale");

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

        emit Purchase(h, saleConfig_.token, tokenId, msg.sender, recipient);

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
        uint256 maxFee = IMirrorFeeRegistry(feeRegistry).maxFee();

        require(saleConfig_.feePercentage <= maxFee, "fee too high");

        bytes32 h = _getHash(saleConfig_);

        sales_[h] = Sale({
            open: saleConfig_.open,
            sold: 0,
            operator: saleConfig_.operator
        });

        emit RegisteredSale(
            h,
            saleConfig_.token,
            saleConfig_.startTokenId,
            saleConfig_.endTokenId,
            saleConfig_.operator,
            saleConfig_.recipient,
            saleConfig_.price,
            saleConfig_.open,
            saleConfig_.feePercentage
        );

        if (saleConfig_.open) {
            emit OpenSale(h);
        } else {
            emit CloseSale(h);
        }

        count++;
    }

    function _setSaleStatus(SaleConfig calldata saleConfig_, bool status)
        internal
    {
        bytes32 h = _getHash(saleConfig_);

        require(sales_[h].open != status, "cannot update sale status");

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
        uint256 amount,
        uint256 feePercentage
    ) internal {
        uint256 fee = 0;

        if (feePercentage > 0) {
            // calculate fee
            fee = _feeAmount(amount, feePercentage);

            // contribute to treasury
            IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                .contributeWithTributary{value: fee}(operator);
        }

        (address royaltyRecipient, uint256 royaltyAmount) = _royaltyInfo(
            token,
            tokenId,
            amount - fee
        );

        if (msg.sender == royaltyRecipient || royaltyRecipient == address(0)) {
            // transfer funds to recipient
            _send(payable(recipient), amount - fee);
            // Emit an event describing the withdrawal.
            emit Withdraw(h, amount, fee, recipient);
        } else {
            // transfer funds to recipient
            _send(payable(recipient), amount - fee - royaltyAmount);

            // transfer royalties
            _send(payable(royaltyRecipient), royaltyAmount);

            // Emit an event describing the withdrawal.
            emit Withdraw(h, amount, fee, recipient);
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

    /// ERC721 Events

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

interface IMirrorOpenSaleV0 {
    struct Sale {
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

    function count() external returns (uint256);

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
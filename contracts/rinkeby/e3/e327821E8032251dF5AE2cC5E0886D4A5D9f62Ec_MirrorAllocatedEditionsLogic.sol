// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../../lib/Ownable.sol";
import {IMirrorAllocatedEditionsLogic} from "./interface/IMirrorAllocatedEditionsLogic.sol";
import {IERC721, IERC721Events, IERC721Receiver, IERC721Metadata} from "../../lib/ERC721/interface/IERC721.sol";
import {IERC165} from "../../lib/ERC165/interface/IERC165.sol";
import {IERC2981} from "../../lib/ERC2981/interface/IERC2981.sol";
import {IMirrorOpenSaleV0} from "../../distributors/open-sale/interface/IMirrorOpenSaleV0.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";

/**
 * @title MirrorAllocatedEditionsLogic
 * @author MirrorXYZ
 */
contract MirrorAllocatedEditionsLogic is
    Ownable,
    IMirrorAllocatedEditionsLogic,
    IERC721,
    IERC721Events,
    IERC165,
    IERC721Metadata,
    IERC2309,
    IERC2981
{
    /// @notice Token name
    string public override name;

    /// @notice Token symbol
    string public override symbol;

    /// @notice Token baseURI
    string public baseURI;

    /// @notice Token contentHash
    bytes32 public contentHash;

    /// @notice Token supply
    uint256 public totalSupply;

    /// @notice Burned tokens
    mapping(uint256 => bool) internal _burned;

    /// @notice Token owners
    mapping(uint256 => address) internal _owners;

    /// @notice Token balances
    mapping(address => uint256) internal _balances;

    /// @notice Token approvals
    mapping(uint256 => address) internal _tokenApprovals;

    /// @notice Token operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Mirror open sale address
    address public immutable mirrorOpenSale;

    // ============ Royalty Info (ERC2981) ============

    /// @notice Account that will receive royalties
    /// @dev set address(0) to avoid royalties
    address public royaltyRecipient;

    /// @notice Royalty percentage
    uint256 public royaltyPercentage;

    /// @dev Sets zero address as owner since this is a logic contract
    /// @param mirrorOpenSale_ sale contract address
    constructor(address mirrorOpenSale_) Ownable(address(0)) {
        mirrorOpenSale = mirrorOpenSale_;
    }

    // ============ Constructor ============

    /// @dev Initialize contract
    /// @param metadata ERC721Metadata parameters
    /// @param owner_ owner of this contract
    /// @param fundingRecipient_ account that will receive funds from sales
    /// @param royaltyRecipient_ account that will receive royalties
    /// @param royaltyPercentage_ royalty percentage
    /// @param price sale listing price
    /// @param list whether to list on sale contract
    /// @param open whether to list with a closed or open sale
    /// @dev Initialize parameters, mint total suppply to owner. Reverts if called
    /// after contract deployment. If list is true, the open sale contract gets approval
    /// for all tokens.
    function initialize(
        NFTMetadata memory metadata,
        address owner_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
    ) external override {
        // ensure that this function is only callable during contract construction.
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        // NFT Metadata
        name = metadata.name;
        symbol = metadata.symbol;
        baseURI = metadata.baseURI;
        contentHash = metadata.contentHash;
        totalSupply = metadata.quantity;

        // Set owner
        _setOwner(address(0), owner_);

        // Royalties
        royaltyRecipient = royaltyRecipient_;
        royaltyPercentage = royaltyPercentage_;

        emit ConsecutiveTransfer(
            // fromTokenId
            0,
            // toTokenId
            metadata.quantity - 1,
            // fromAddress
            address(0),
            // toAddress
            owner_
        );

        _balances[owner_] = totalSupply;

        if (list) {
            IMirrorOpenSaleV0(mirrorOpenSale).register(
                IMirrorOpenSaleV0.SaleConfig({
                    token: address(this),
                    startTokenId: 0,
                    endTokenId: totalSupply - 1,
                    operator: owner_,
                    recipient: fundingRecipient_,
                    price: price,
                    open: open,
                    feePercentage: feePercentage
                })
            );

            _operatorApprovals[owner_][mirrorOpenSale] = true;

            emit ApprovalForAll(
                // owner
                owner_,
                // operator
                mirrorOpenSale,
                // approved
                true
            );
        }
    }

    // ============ ERC721 Methods ============

    function balanceOf(address owner_) public view override returns (uint256) {
        require(
            owner_ != address(0),
            "ERC721: balance query for the zero address"
        );

        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address _owner = _owners[tokenId];

        // if there is not owner set, and the token is not burned, the operator owns it
        if (_owner == address(0) && !_burned[tokenId]) {
            return owner;
        }

        require(_owner != address(0), "ERC721: query for nonexistent token");

        return _owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");

        require(
            msg.sender == owner_ || isApprovedForAll(owner_, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(
            // owner
            msg.sender,
            // operator
            operator,
            // approved
            approved
        );
    }

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner_][operator_];
    }

    // ============ ERC721 Metadata Methods ============

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    function getContentHash(uint256) public view returns (bytes32) {
        return contentHash;
    }

    // ============ Burn Method ============

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    // ============ ERC2981 Methods ============

    /// @notice Get royalty info
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (_salePrice * royaltyPercentage) / 10_000;
    }

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external override onlyOwner {
        royaltyRecipient = royaltyRecipient_;
        royaltyPercentage = royaltyPercentage_;

        emit RoyaltyChange(
            // oldRoyaltyRecipient
            royaltyRecipient,
            // oldRoyaltyPercentage
            royaltyPercentage,
            // newRoyaltyRecipient
            royaltyRecipient_,
            // newRoyaltyPercentage
            royaltyPercentage_
        );
    }

    // ============ IERC165 Method ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ============ Internal Methods ============

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );

        require(
            to != address(0),
            "ERC721: transfer to the zero address (use burn instead)"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(
            // from
            from,
            // to
            to,
            // tokenId
            tokenId
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return !_burned[tokenId];
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner_] -= 1;

        delete _owners[tokenId];

        _burned[tokenId] = true;

        emit Transfer(
            // from
            owner_,
            // to
            address(0),
            // tokenId
            tokenId
        );
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        address owner_ = ownerOf(tokenId);

        return (spender == owner_ ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner_, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;

        emit Approval(
            // owner
            ownerOf(tokenId),
            // approved
            to,
            // tokenId
            tokenId
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorAllocatedEditionsLogic {
    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyPercentage,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyPercentage
    );

    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
        uint256 quantity;
    }

    function initialize(
        NFTMetadata memory metadata,
        address operator_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
    ) external;

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;
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

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}
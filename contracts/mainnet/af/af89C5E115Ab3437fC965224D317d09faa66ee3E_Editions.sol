/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.5;

interface IERC721 {
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

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
 * Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is ERC165, IERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
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
        virtual
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
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
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/Editions.sol


/**
 * @title Editions
 * @author MirrorXYZ
 */
contract Editions is ERC721 {
    // ============ Constants ============

    string public constant name = "Mirror Editions V2";
    string public constant symbol = "EDITIONS_V2";

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Structs ============

    struct Edition {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The number of tokens sold so far.
        uint256 numSold;
        // The content hash of the image being presented.
        bytes32 contentHash;
    }

    // A subset of Edition, for efficient production of multiple editions.
    struct EditionTier {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        bytes32 contentHash;
    }

    mapping(address => uint256) public fundingBalance;

    // ============ Immutable Storage ============

    // Fee updates take 2 days to take place, giving creators time to withdraw.
    uint256 public immutable feeUpdateTimelock;

    // ============ Mutable Storage ============

    string internal baseURI;
    // Mapping of edition id to descriptive data.
    mapping(uint256 => Edition) public editions;
    // Mapping of token id to edition id.
    mapping(uint256 => uint256) public tokenToEdition;
    // The amount of funds that have already been withdrawn for a given edition.
    mapping(uint256 => uint256) public withdrawnForEdition;
    // `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 private nextTokenId;
    // Editions start at 1, in order that unsold tokens don't map to the first edition.
    uint256 private nextEditionId = 1;
    // Withdrawals include a fee, specified as a percentage.
    uint16 public feePercent;
    // The address that holds fees.
    address payable public treasury;
    uint256 public feesAccrued;
    // Timelock information.
    uint256 public nextFeeUpdateTime;
    uint16 public nextFeePercent;
    // Reentrancy
    uint256 internal reentrancyStatus;

    address public owner;
    address public nextOwner;

    // ============ Events ============

    event EditionCreated(
        uint256 quantity,
        uint256 price,
        address fundingRecipient,
        uint256 indexed editionId,
        bytes32 contentHash
    );

    event EditionPurchased(
        uint256 indexed editionId,
        uint256 indexed tokenId,
        // `numSold` at time of purchase represents the "serial number" of the NFT.
        uint256 numSold,
        uint256 amountPaid,
        // The account that paid for and received the NFT.
        address indexed buyer
    );

    event FundsWithdrawn(
        address fundingRecipient,
        uint256 amountWithdrawn,
        uint256 feeAmount
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event FeesWithdrawn(uint256 feesAccrued, address sender);

    event FeeUpdateQueued(uint256 newFee, address sender);

    event FeeUpdated(uint256 feePercent, address sender);

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    // ============ Constructor ============

    constructor(
        string memory baseURI_,
        address payable treasury_,
        uint16 initialFee,
        uint256 feeUpdateTimelock_,
        address owner_
    ) {
        baseURI = baseURI_;
        treasury = treasury_;
        feePercent = initialFee;
        feeUpdateTimelock = feeUpdateTimelock_;
        owner = owner_;
    }

    // ============ Edition Methods ============

    function createEditionTiers(
        EditionTier[] memory tiers,
        address payable fundingRecipient
    ) external nonReentrant {
        // Execute a loop that creates editions.
        for (uint8 i = 0; i < tiers.length; i++) {
            uint256 quantity = tiers[i].quantity;
            uint256 price = tiers[i].price;
            bytes32 contentHash = tiers[i].contentHash;

            editions[nextEditionId] = Edition({
                quantity: quantity,
                price: price,
                fundingRecipient: fundingRecipient,
                numSold: 0,
                contentHash: contentHash
            });

            emit EditionCreated(
                quantity,
                price,
                fundingRecipient,
                nextEditionId,
                contentHash
            );

            nextEditionId++;
        }
    }

    function createEdition(
        // The number of tokens that can be minted and sold.
        uint256 quantity,
        // The price to purchase a token.
        uint256 price,
        // The account that should receive the revenue.
        address payable fundingRecipient,
        // Content hash is emitted in the event, for UI convenience.
        bytes32 contentHash
    ) external nonReentrant {
        editions[nextEditionId] = Edition({
            quantity: quantity,
            price: price,
            fundingRecipient: fundingRecipient,
            numSold: 0,
            contentHash: contentHash
        });

        emit EditionCreated(
            quantity,
            price,
            fundingRecipient,
            nextEditionId,
            contentHash
        );

        nextEditionId++;
    }

    function buyEdition(uint256 editionId) external payable nonReentrant {
        // Check that the edition exists. Note: this is redundant
        // with the next check, but it is useful for clearer error messaging.
        require(editions[editionId].quantity > 0, "Edition does not exist");
        // Check that there are still tokens available to purchase.
        require(
            editions[editionId].numSold < editions[editionId].quantity,
            "This edition is already sold out."
        );
        // Check that the sender is paying the correct amount.
        require(
            msg.value >= editions[editionId].price,
            "Must send enough to purchase the edition."
        );
        // Increment the number of tokens sold for this edition.
        editions[editionId].numSold++;
        fundingBalance[editions[editionId].fundingRecipient] += msg.value;
        // Mint a new token for the sender, using the `nextTokenId`.
        _mint(msg.sender, nextTokenId);
        // Store the mapping of token id to the edition being purchased.
        tokenToEdition[nextTokenId] = editionId;

        emit EditionPurchased(
            editionId,
            nextTokenId,
            editions[editionId].numSold,
            msg.value,
            msg.sender
        );

        nextTokenId++;
    }

    // ============ Operational Methods ============

    function withdrawFunds(address payable fundingRecipient)
        external
        nonReentrant
    {
        uint256 remaining = fundingBalance[fundingRecipient];
        fundingBalance[fundingRecipient] = 0;

        if (feePercent > 0) {
            // Send the amount that was remaining for the edition, to the funding recipient.
            uint256 fee = computeFee(remaining);
            // Allocate fee to the treasury.
            feesAccrued += fee;
            // Send the remainder to the funding recipient.
            _sendFunds(fundingRecipient, remaining - fee);
            emit FundsWithdrawn(fundingRecipient, remaining - fee, fee);
        } else {
            _sendFunds(fundingRecipient, remaining);
            emit FundsWithdrawn(fundingRecipient, remaining, 0);
        }
    }

    function computeFee(uint256 _amount) public view returns (uint256) {
        return (_amount * feePercent) / 100;
    }

    // ============ Admin Methods ============

    function withdrawFees() public {
        _sendFunds(treasury, feesAccrued);
        emit FeesWithdrawn(feesAccrued, msg.sender);
        feesAccrued = 0;
    }

    function updateTreasury(address payable newTreasury) public {
        require(msg.sender == treasury, "Only available to current treasury");
        treasury = newTreasury;
    }

    function queueFeeUpdate(uint16 newFee) public {
        require(msg.sender == treasury, "Only available to treasury");
        nextFeeUpdateTime = block.timestamp + feeUpdateTimelock;
        nextFeePercent = newFee;
        emit FeeUpdateQueued(newFee, msg.sender);
    }

    function executeFeeUpdate() public {
        require(msg.sender == treasury, "Only available to current treasury");
        require(
            block.timestamp >= nextFeeUpdateTime,
            "Timelock hasn't elapsed"
        );
        feePercent = nextFeePercent;
        nextFeePercent = 0;
        nextFeeUpdateTime = 0;
        emit FeeUpdated(feePercent, msg.sender);
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    // ============ NFT Methods ============

    // Returns e.g. https://mirror-api.com/editions/[editionId]/[tokenId]
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // If the token does not map to an edition, it'll be 0.
        require(tokenToEdition[tokenId] > 0, "Token has not been sold yet");
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toString(tokenToEdition[tokenId]),
                    "/",
                    _toString(tokenId)
                )
            );
    }

    // The hash of the given content for the NFT. Can be used
    // for IPFS storage, verifying authenticity, etc.
    function contentHash(uint256 tokenId) public view returns (bytes32) {
        // If the token does not map to an edition, it'll be 0.
        require(tokenToEdition[tokenId] > 0, "Token has not been sold yet");
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return editions[tokenToEdition[tokenId]].contentHash;
    }

    // Returns e.g. https://mirror-api.com/editions/metadata
    function contractURI() public view returns (string memory) {
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    function getRoyaltyRecipient(uint256 tokenId)
        public
        view
        returns (address)
    {
        require(tokenToEdition[tokenId] > 0, "Token has not been minted yet");
        return editions[tokenToEdition[tokenId]].fundingRecipient;
    }

    function setRoyaltyRecipient(
        uint256 editionId,
        address payable newFundingRecipient
    ) public {
        require(
            editions[editionId].fundingRecipient == msg.sender,
            "Only current fundingRecipient can modify its value"
        );

        editions[editionId].fundingRecipient = newFundingRecipient;
    }

    // ============ Private Methods ============

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
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
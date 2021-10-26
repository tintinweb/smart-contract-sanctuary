//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// data stored for-each infused token
struct TokenData {
    uint256 dailyRate;
    uint256 balance;
    uint256 lastClaimAt;
}

// per-tenant configuration
struct TenantConfig {
    IERC20 token;
    TenantConstraints constraints;
}

// modifyiable tenant constraints
struct TenantConstraints {
    uint256 minDailyRate;
    uint256 maxDailyRate;
    uint256 minInfusionAmount;
    uint256 maxInfusionAmount;
    uint256 maxTokenBalance;
    // if true, infuser must own the NFT being infused
    bool requireOwnedNft;
    // if true, an NFT can only be infused once
    bool disableMultiInfuse;
    // if true, infuser must be on the allowed infusers list. If false, infuser
    // must be msg.sender if not on the infusion list
    bool requireInfusionWhitelist;
    // if true, nft collection must be on the allow list
    bool requireCollectionWhitelist;
}

// data provided when creating a tenant
struct CreateTenantInput {
    string name;
    string description;
    TenantConfig config;
    address[] admins;
    address[] infusers;
    IERC721[] collections;
}

// data provided when modifying a tenant
struct ModifyTenantInput {
    uint256 tenantId;
    address[] adminsToAdd;
    address[] adminsToRemove;
    address[] infusersToAdd;
    address[] infusersToRemove;
    IERC721[] collectionsToAdd;
    IERC721[] collectionsToRemove;
}

// data provided when infusing an nft
struct InfuseInput {
    uint256 tenantId;
    IERC721 collection;
    uint256 tokenId;
    address infuser;
    uint256 dailyRate;
    uint256 amount;
    string comment;
}

// data provided when claiming from an infused nft
struct ClaimInput {
    uint256 tenantId;
    IERC721 collection;
    uint256 tokenId;
    uint256 amount;
}

contract HyperVIBES {
    // ---
    // storage
    // ---

    // tenant ID -> tenant data
    mapping(uint256 => TenantConfig) public tenantConfig;

    // tenant ID -> address -> (is admin flag)
    mapping(uint256 => mapping(address => bool)) public isAdmin;

    // tenant ID -> address -> (is infuser flag)
    mapping(uint256 => mapping(address => bool)) public isInfuser;

    // tenant ID -> erc721 -> (is allowed collection flag)
    mapping(uint256 => mapping(IERC721 => bool)) public isCollection;

    // tenant ID -> nft -> token ID -> token data
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => TokenData)))
        public tokenData;

    uint256 public nextTenantId = 1;

    // ---
    // events
    // ---

    event TenantCreated(
        uint256 indexed tenantId,
        string name,
        string description
    );

    event AdminAdded(uint256 indexed tenantId, address indexed admin);

    event AdminRemoved(uint256 indexed tenantId, address indexed admin);

    event InfuserAdded(uint256 indexed tenantId, address indexed infuser);

    event InfuserRemoved(uint256 indexed tenantId, address indexed infuser);

    event CollectionAdded(uint256 indexed tenantId, IERC721 indexed collection);

    event CollectionRemoved(
        uint256 indexed tenantId,
        IERC721 indexed collection
    );

    event Infused(
        uint256 indexed tenantId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        address infuser,
        uint256 amount,
        uint256 dailyRate,
        string comment
    );

    event Claimed(
        uint256 indexed tenantId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );

    // ---
    // admin mutations
    // ---

    // setup a new tenant
    function createTenant(CreateTenantInput memory create) external {
        require(create.config.token != IERC20(address(0)), "invalid token");

        uint256 tenantId = nextTenantId++;
        tenantConfig[tenantId] = create.config;

        emit TenantCreated(tenantId, create.name, create.description);

        for (uint256 i = 0; i < create.admins.length; i++) {
            _addAdmin(tenantId, create.admins[i]);
        }

        for (uint256 i = 0; i < create.infusers.length; i++) {
            _addInfuser(tenantId, create.infusers[i]);
        }

        for (uint256 i = 0; i < create.collections.length; i++) {
            _addCollection(tenantId, create.collections[i]);
        }
    }

    // update mutable configuration for a tenant
    function modifyTenant(ModifyTenantInput memory input) public {
        require(isAdmin[input.tenantId][msg.sender], "not tenant admin");

        // adds

        for (uint256 i = 0; i < input.adminsToAdd.length; i++) {
            _addAdmin(input.tenantId, input.adminsToAdd[i]);
        }

        for (uint256 i = 0; i < input.infusersToAdd.length; i++) {
            _addInfuser(input.tenantId, input.infusersToAdd[i]);
        }

        for (uint256 i = 0; i < input.collectionsToAdd.length; i++) {
            _addCollection(input.tenantId, input.collectionsToAdd[i]);
        }

        // removes

        for (uint256 i = 0; i < input.adminsToRemove.length; i++) {
            _removeAdmin(input.tenantId, input.adminsToRemove[i]);
        }

        for (uint256 i = 0; i < input.infusersToRemove.length; i++) {
            _removeInfuser(input.tenantId, input.infusersToRemove[i]);
        }

        for (uint256 i = 0; i < input.collectionsToRemove.length; i++) {
            _removeCollection(input.tenantId, input.collectionsToRemove[i]);
        }
    }

    function _addAdmin(uint256 tenantId, address admin) internal {
        require(admin != address(0), "invalid admin");
        isAdmin[tenantId][admin] = true;
        emit AdminAdded(tenantId, admin);
    }

    function _removeAdmin(uint256 tenantId, address admin) internal {
        require(admin != address(0), "invalid admin");
        delete isAdmin[tenantId][admin];
        emit AdminRemoved(tenantId, admin);
    }

    function _addInfuser(uint256 tenantId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        isInfuser[tenantId][infuser] = true;
        emit InfuserAdded(tenantId, infuser);
    }

    function _removeInfuser(uint256 tenantId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        delete isInfuser[tenantId][infuser];
        emit InfuserRemoved(tenantId, infuser);
    }

    function _addCollection(uint256 tenantId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        isCollection[tenantId][collection] = true;
        emit CollectionAdded(tenantId, collection);
    }

    function _removeCollection(uint256 tenantId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        delete isCollection[tenantId][collection];
        emit CollectionRemoved(tenantId, collection);
    }

    // ---
    // infuser mutations
    // ---

    function infuse(InfuseInput memory input) external {
        require(
            _isTokenValid(input.collection, input.tokenId),
            "invalid token"
        );

        TokenData storage data = tokenData[input.tenantId][input.collection][
            input.tokenId
        ];

        TenantConfig memory tenant = tenantConfig[input.tenantId];

        // assert amount to be infused is within the min and max constraints
        require(
            input.amount >= tenant.constraints.minInfusionAmount,
            "amount too low"
        );
        require(
            input.amount <= tenant.constraints.maxInfusionAmount,
            "amount too high"
        );

        // a "public infusion" is when msg sender is the infuser to be recorded.
        // This can be done only when the requireInfusionWhitelist flag is NOT
        // set. This will be FALSE if msg.sender is on the infusion whitelist
        // and requireInfusionWhitelist is true, but thats okay because
        // isPublicInfusion is only checked if infuser is not on the whitelist
        bool isPublicInfusion = msg.sender == input.infuser &&
            !tenant.constraints.requireInfusionWhitelist;

        // True if the NFT to be infused is owned by the recorded infuser
        bool isOwnedByInfuser = input.collection.ownerOf(input.tokenId) ==
            input.infuser;

        // true if msg.sender is a whitelisted infuser
        bool isOnInfuserWhitelist = isInfuser[input.tenantId][msg.sender];

        // true if the nft collection is on the whitelist
        bool isOnCollectionWhitelist = isCollection[input.tenantId][
            input.collection
        ];

        require(
            !tenant.constraints.requireOwnedNft || isOwnedByInfuser,
            "nft not owned by infuser"
        );
        require(isOnInfuserWhitelist || isPublicInfusion, "invalid infuser");
        require(
            !tenant.constraints.requireCollectionWhitelist ||
                isOnCollectionWhitelist,
            "invalid collection"
        );

        // if already infused...
        if (data.lastClaimAt != 0) {
            // assert same rate
            require(
                data.dailyRate == input.dailyRate,
                "daily rate is immutable"
            );
            // assert multi-infuse is allowed
            require(
                !tenant.constraints.disableMultiInfuse,
                "multi infuse disabled"
            );

            // intentionally ommitting checks to min/max daily rate -- its
            // possible tenant configuration has changed since the initial
            // infusion, we don't want to prevent "topping off" the NFT if this
            // is the case
        } else {
            // else ensure daily rate is within min/max constraints
            require(
                input.dailyRate >= tenant.constraints.minDailyRate,
                "daily rate too low"
            );
            require(
                input.dailyRate <= tenant.constraints.maxDailyRate,
                "daily rate too high"
            );
            // initialize token storage
            data.dailyRate = input.dailyRate;
            data.lastClaimAt = block.timestamp;
        }

        // TODO: clamp amount based on balance and max balance

        // infuse
        // TODO: reentrancy risk!!!!!
        tenant.token.transferFrom(msg.sender, address(this), input.amount);
        data.balance += input.amount;

        emit Infused(
            input.tenantId,
            input.collection,
            input.tokenId,
            input.infuser,
            input.amount,
            input.dailyRate,
            input.comment
        );
    }

    // determines if a given tenant/operator/infuser combo is allowed
    function _isAllowedToInfuse(
        uint256 tenantId,
        address operator,
        address infuser
    ) internal view returns (bool) {
        // actual infuser -> yes
        if (isInfuser[tenantId][operator]) {
            return true;
        }
        // no public infusion allowed -> no
        else if (isInfuser[tenantId][address(0)]) {
            return false;
        }
        // else public is allowed if coming from infuser
        else if (operator == infuser) {
            return true;
        }

        return false;
    }

    // ---
    // claimer mutations
    // ---

    function claim(ClaimInput memory input) public {
        require(
            _isApprovedOrOwner(input.collection, input.tokenId, msg.sender),
            "not owner or approved"
        );

        // compute how much we can claim, only pay attention to amount if its less
        // than available
        uint256 availableToClaim = _claimable(
            input.tenantId,
            input.collection,
            input.tokenId
        );
        uint256 toClaim = input.amount < availableToClaim
            ? input.amount
            : availableToClaim;
        require(toClaim > 0, "nothing to claim");

        TokenData storage data = tokenData[input.tenantId][input.collection][
            input.tokenId
        ];

        // claim only as far up as we need to get our amount... basically "advances"
        // the lastClaim timestamp the exact amount needed to provide the amount
        // claim at = last + (to claim / rate) * 1 day, rewritten for div last
        uint256 claimAt = data.lastClaimAt +
            (toClaim * 1 days) /
            data.dailyRate;

        // update balances and execute ERC-20 transfer
        data.balance -= toClaim;
        data.lastClaimAt = claimAt;
        // TODO: reentrancy risk!!!!!
        tenantConfig[input.tenantId].token.transfer(msg.sender, toClaim);

        emit Claimed(input.tenantId, input.collection, input.tokenId, toClaim);
    }

    // compute claimable tokens, reverts for invalid tokens
    function _claimable(
        uint256 tenantId,
        IERC721 collection,
        uint256 tokenId
    ) internal view returns (uint256) {
        TokenData memory data = tokenData[tenantId][collection][tokenId];
        require(data.lastClaimAt != 0, "token has not been infused");
        require(_isTokenValid(collection, tokenId), "invalid token");

        uint256 secondsToClaim = block.timestamp - data.lastClaimAt;
        uint256 toClaim = (secondsToClaim * data.dailyRate) / 1 days;

        // clamp to token balance
        return toClaim > data.balance ? data.balance : toClaim;
    }

    // ---
    // views
    // ---

    function name() external pure returns (string memory) {
        return "HyperVIBES";
    }

    // ---
    // utils
    // ---

    // returns true if a tenant has been setup
    function _tenantExists(uint256 tenantId) internal view returns (bool) {
        return tenantConfig[tenantId].token != IERC20(address(0));
    }

    // returns true if token exists (and is not burnt)
    function _isTokenValid(IERC721 nft, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        try nft.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    // returns true if operator can manage tokenId
    function _isApprovedOrOwner(
        IERC721 nft,
        uint256 tokenId,
        address operator
    ) internal view returns (bool) {
        address owner = nft.ownerOf(tokenId);
        return
            owner == operator ||
            nft.getApproved(tokenId) == operator ||
            nft.isApprovedForAll(owner, operator);
    }
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
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*


    ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗ ██╗   ██╗██╗██████╗ ███████╗███████╗
    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║   ██║██║██╔══██╗██╔════╝██╔════╝
    ███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║   ██║██║██████╔╝█████╗  ███████╗
    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██╔══██╗██╔══╝  ╚════██║
    ██║  ██║   ██║   ██║     ███████╗██║  ██║ ╚████╔╝ ██║██████╔╝███████╗███████║
    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


    The possibilities are endless in the realms of your imagination.
    What would you do with that power?

                            Dreamt up & built at
                                Rarible DAO

                                  * * * *

    HyperVIBES is a public and free protocol from Rarible DAO that lets you
    infuse any ERC-20 token into ERC-721 NFTs from any minting platform.

    Infused tokens can be mined and claimed by the NFT owner over time.

    Create a fully isolated and independently configured HyperVIBES realm to run
    your own experiments or protocols without having to deploy a smart contract.

    HyperVIBES is:
    - 🎁 Open Source
    - 🥳 Massively Multiplayer
    - 🌈 Public Infrastructure
    - 🚀 Unstoppable and Censor-Proof
    - 🌎 Multi-chain
    - 💖 Free Forever

    Feel free to use HyperVIBES in any way you want.

    https://hypervibes.xyz
    https://app.hypervibes.xyz
    https://docs.hypervibes.xyz

*/

import "./IHyperVIBES.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HyperVIBES is IHyperVIBES, ReentrancyGuard {
    bool constant public FEEL_FREE_TO_USE_HYPERVIBES_IN_ANY_WAY_YOU_WANT = true;

    // ---
    // storage
    // ---

    // realm ID -> realm data
    mapping(uint256 => RealmConfig) public realmConfig;

    // realm ID -> address -> (is admin flag)
    mapping(uint256 => mapping(address => bool)) public isAdmin;

    // realm ID -> address -> (is infuser flag)
    mapping(uint256 => mapping(address => bool)) public isInfuser;

    // realm ID -> address -> (is claimer flag)
    mapping(uint256 => mapping(address => bool)) public isClaimer;

    // realm ID -> erc721 -> (is allowed collection flag)
    mapping(uint256 => mapping(IERC721 => bool)) public isCollection;

    // realm ID -> nft -> token ID -> token data
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => TokenData)))
        public tokenData;

    // realm ID -> operator -> infuser -> (is allowed proxy flag)
    mapping(uint256 => mapping(address => mapping(address => bool))) public isProxy;

    uint256 public nextRealmId = 1;

    // ---
    // admin mutations
    // ---

    // setup a new realm
    function createRealm(CreateRealmInput memory create) override external returns (uint256) {
        require(create.config.token != IERC20(address(0)), "invalid token");
        require(create.config.constraints.maxTokenBalance > 0, "invalid max token balance");
        require(
            create.config.constraints.minClaimAmount <= create.config.constraints.maxTokenBalance,
            "invalid min claim amount");

        uint256 realmId = nextRealmId++;
        realmConfig[realmId] = create.config;

        emit RealmCreated(realmId, create.name, create.description);

        for (uint256 i = 0; i < create.admins.length; i++) {
            _addAdmin(realmId, create.admins[i]);
        }

        for (uint256 i = 0; i < create.infusers.length; i++) {
            _addInfuser(realmId, create.infusers[i]);
        }

        for (uint256 i = 0; i < create.claimers.length; i++) {
            _addClaimer(realmId, create.claimers[i]);
        }

        for (uint256 i = 0; i < create.collections.length; i++) {
            _addCollection(realmId, create.collections[i]);
        }

        return realmId;
    }

    // update mutable configuration for a realm
    function modifyRealm(ModifyRealmInput memory input) override external {
        require(_realmExists(input.realmId), "invalid realm");
        require(isAdmin[input.realmId][msg.sender], "not realm admin");

        // adds

        for (uint256 i = 0; i < input.adminsToAdd.length; i++) {
            _addAdmin(input.realmId, input.adminsToAdd[i]);
        }

        for (uint256 i = 0; i < input.infusersToAdd.length; i++) {
            _addInfuser(input.realmId, input.infusersToAdd[i]);
        }

        for (uint256 i = 0; i < input.claimersToAdd.length; i++) {
            _addClaimer(input.realmId, input.claimersToAdd[i]);
        }

        for (uint256 i = 0; i < input.collectionsToAdd.length; i++) {
            _addCollection(input.realmId, input.collectionsToAdd[i]);
        }

        // removes

        for (uint256 i = 0; i < input.adminsToRemove.length; i++) {
            _removeAdmin(input.realmId, input.adminsToRemove[i]);
        }

        for (uint256 i = 0; i < input.infusersToRemove.length; i++) {
            _removeInfuser(input.realmId, input.infusersToRemove[i]);
        }

        for (uint256 i = 0; i < input.claimersToRemove.length; i++) {
            _removeClaimer(input.realmId, input.claimersToRemove[i]);
        }

        for (uint256 i = 0; i < input.collectionsToRemove.length; i++) {
            _removeCollection(input.realmId, input.collectionsToRemove[i]);
        }
    }

    function _addAdmin(uint256 realmId, address admin) internal {
        require(admin != address(0), "invalid admin");
        isAdmin[realmId][admin] = true;
        emit AdminAdded(realmId, admin);
    }

    function _removeAdmin(uint256 realmId, address admin) internal {
        require(admin != address(0), "invalid admin");
        delete isAdmin[realmId][admin];
        emit AdminRemoved(realmId, admin);
    }

    function _addInfuser(uint256 realmId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        isInfuser[realmId][infuser] = true;
        emit InfuserAdded(realmId, infuser);
    }

    function _removeInfuser(uint256 realmId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        delete isInfuser[realmId][infuser];
        emit InfuserRemoved(realmId, infuser);
    }

    function _addClaimer(uint256 realmId, address claimer) internal {
        require(claimer != address(0), "invalid claimer");
        isClaimer[realmId][claimer] = true;
        emit ClaimerAdded(realmId, claimer);
    }

    function _removeClaimer(uint256 realmId, address claimer) internal {
        require(claimer != address(0), "invalid claimer");
        delete isClaimer[realmId][claimer];
        emit ClaimerRemoved(realmId, claimer);
    }

    function _addCollection(uint256 realmId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        isCollection[realmId][collection] = true;
        emit CollectionAdded(realmId, collection);
    }

    function _removeCollection(uint256 realmId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        delete isCollection[realmId][collection];
        emit CollectionRemoved(realmId, collection);
    }

    // ---
    // infuser mutations
    // ---

    // nonReentrant wrapper
    function infuse(InfuseInput memory input) override external nonReentrant returns (uint256) {
        return _infuse(input);
    }

    function _infuse(InfuseInput memory input) private returns (uint256) {
        TokenData storage data = tokenData[input.realmId][input.collection][input.tokenId];
        RealmConfig memory realm = realmConfig[input.realmId];

        _validateInfusion(input, data, realm);

        // initialize token storage if first infusion
        if (data.lastClaimAt == 0) {
            data.lastClaimAt = block.timestamp;
        }
        // re-set last claim to now if this is empty, else it will pre-mine the
        // time since the last claim
        else if (data.balance == 0) {
            data.lastClaimAt = block.timestamp;
        }

        // determine if we need to clamp the amount based on maxTokenBalance
        uint256 nextBalance = data.balance + input.amount;
        uint256 clampedBalance = nextBalance > realm.constraints.maxTokenBalance
            ? realm.constraints.maxTokenBalance
            : nextBalance;
        uint256 amountToTransfer = clampedBalance - data.balance;

        // jit assert that this amount is valid within constraints
        require(amountToTransfer > 0, "nothing to transfer");
        require(amountToTransfer >= realm.constraints.minInfusionAmount, "amount too low");

        // pull tokens from msg sender into the contract, executing transferFrom
        // last to ensure no malicious erc-20 can cause re-entrancy issues
        data.balance += amountToTransfer;
        realm.token.transferFrom(msg.sender, address(this), amountToTransfer);

        emit Infused(
            input.realmId,
            input.collection,
            input.tokenId,
            input.infuser,
            input.amount,
            input.comment
        );

        return amountToTransfer;
    }

    function _validateInfusion(InfuseInput memory input, TokenData memory data, RealmConfig memory realm) internal view {
        require(_isTokenValid(input.collection, input.tokenId), "invalid token");
        require(_realmExists(input.realmId), "invalid realm");

        bool isOwnedByInfuser = input.collection.ownerOf(input.tokenId) == input.infuser;
        bool isOnInfuserAllowlist = isInfuser[input.realmId][msg.sender];
        bool isOnCollectionAllowlist = isCollection[input.realmId][input.collection];
        bool isValidProxy = isProxy[input.realmId][msg.sender][input.infuser];

        require(isOwnedByInfuser || !realm.constraints.requireNftIsOwned, "nft not owned by infuser");
        require(isOnInfuserAllowlist || realm.constraints.allowPublicInfusion, "invalid infuser");
        require(isOnCollectionAllowlist || realm.constraints.allowAllCollections, "invalid collection");
        require(isValidProxy || msg.sender == input.infuser, "invalid proxy");

        // if already infused...
        if (data.lastClaimAt != 0) {
            require(realm.constraints.allowMultiInfuse, "multi infuse disabled");
        }
    }

    // ---
    // proxy mutations
    // ---

    // allower operator to infuse or claim on behalf of msg.sender for a specific realm
    function allowProxy(uint256 realmId, address proxy) override external {
        require(_realmExists(realmId), "invalid realm");
        isProxy[realmId][proxy][msg.sender] = true;
        emit ProxyAdded(realmId, proxy);
    }

    // deny operator the ability to infuse or claim on behalf of msg.sender for a specific realm
    function denyProxy(uint256 realmId, address proxy) override external {
        require(_realmExists(realmId), "invalid realm");
        delete isProxy[realmId][proxy][msg.sender];
        emit ProxyRemoved(realmId, proxy);
    }

    // ---
    // claimer mutations
    // ---

    // nonReentrant wrapper
    function claim(ClaimInput memory input) override external nonReentrant returns (uint256) {
        return _claim(input);
    }

    function _claim(ClaimInput memory input) private returns (uint256) {
        require(_isTokenValid(input.collection, input.tokenId), "invalid token");
        require(_isValidClaimer(input.realmId, input.collection, input.tokenId), "invalid claimer");

        TokenData storage data = tokenData[input.realmId][input.collection][input.tokenId];
        require(data.lastClaimAt != 0, "token not infused");

        // compute mined / claimable
        uint256 secondsToClaim = block.timestamp - data.lastClaimAt;
        uint256 mined = (secondsToClaim * realmConfig[input.realmId].dailyRate) / 1 days;
        uint256 availableToClaim = mined > data.balance ? data.balance : mined;

        // only pay attention to amount if its less than available
        uint256 toClaim = input.amount < availableToClaim ? input.amount : availableToClaim;
        require(toClaim >= realmConfig[input.realmId].constraints.minClaimAmount, "amount too low");
        require(toClaim > 0, "nothing to claim");

        // claim only as far up as we need to get our amount... basically "advances"
        // the lastClaim timestamp the exact amount needed to provide the amount
        // claim at = last + (to claim / rate) * 1 day, rewritten for div last
        uint256 claimAt = data.lastClaimAt + (toClaim * 1 days) / realmConfig[input.realmId].dailyRate;

        // update balances and execute ERC-20 transfer, calling transferFrom
        // last to prevent any malicious erc-20 from causing re-entrancy issues
        data.balance -= toClaim;
        data.lastClaimAt = claimAt;
        realmConfig[input.realmId].token.transfer(msg.sender, toClaim);

        emit Claimed(input.realmId, input.collection, input.tokenId, toClaim);

        return toClaim;
    }

    // returns true if msg.sender can claim for a given (realm/collection/tokenId) tuple
    function _isValidClaimer(uint256 realmId, IERC721 collection, uint256 tokenId) internal view returns (bool) {
        address owner = collection.ownerOf(tokenId);

        bool isOwned = owner == msg.sender;
        bool isValidProxy = isProxy[realmId][msg.sender][owner];

        // no matter what, msg sender must be owner or have authorized a proxy.
        // ensures that claiming can never happen without owner approval of some
        // sort
        if (!isOwned && !isValidProxy) {
            return false;
        }

        // if public claim is valid, we're good to go
        if (realmConfig[realmId].constraints.allowPublicClaiming) {
            return true;
        }

        // otherwise, must be on claimer list
        return isClaimer[realmId][msg.sender];
    }


    // ---
    // batch utils
    // ---

    function batchClaim(ClaimInput[] memory batch) override external returns (uint256) {
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < batch.length; i++) {
            totalClaimed += _claim(batch[i]);
        }
        return totalClaimed;
    }

    function batchInfuse(InfuseInput[] memory batch) override external returns (uint256) {
        uint256 totalInfused = 0;
        for (uint256 i; i < batch.length; i++) {
            totalInfused += _infuse(batch[i]);
        }
        return totalInfused;
    }


    // ---
    // views
    // ---

    function name() override external pure returns (string memory) {
        return "HyperVIBES";
    }


    // total amount of mined tokens
    // will return 0 if the token is not infused instead of reverting
    // will return 0 if the does not exist (burned, invalid contract or id)
    // will return amount mined even if not claimable (minClaimAmount constraint)
    function currentMinedTokens(uint256 realmId, IERC721 collection, uint256 tokenId)
        override external view returns (uint256)
    {
        require(_realmExists(realmId), "invalid realm");

        TokenData memory data = tokenData[realmId][collection][tokenId];

        // if non-existing token
        if (!_isTokenValid(collection, tokenId)) {
            return 0;
        }

        // not infused
        if (data.lastClaimAt == 0) {
            return 0;
        }

        uint256 miningTime = block.timestamp - data.lastClaimAt;
        uint256 mined = (miningTime * realmConfig[realmId].dailyRate) / 1 days;
        uint256 clamped = mined > data.balance ? data.balance : mined;
        return clamped;
    }

    // ---
    // utils
    // ---

    // returns true if a realm has been setup
    function _realmExists(uint256 realmId) internal view returns (bool) {
        return realmConfig[realmId].token != IERC20(address(0));
    }

    // returns true if token exists (and is not burnt)
    function _isTokenValid(IERC721 collection, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        try collection.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// data stored for-each infused token
struct TokenData {
    // total staked tokens for this NFT
    uint256 balance;

    // timestamp of last executed claim, determines claimable tokens
    uint256 lastClaimAt;
}

// per-realm configuration
struct RealmConfig {
    // ERC-20 for the realm
    IERC20 token;

    // daily token mining rate -- constant for the entire realm
    uint256 dailyRate;

    // configured constraints for the realm
    RealmConstraints constraints;
}

// constraint parameters for a realm
struct RealmConstraints {
    // An NFT must be infused with at least this amount of the token every time
    // it's infused.
    uint256 minInfusionAmount;

    // An NFT's infused balance cannot exceed this amount. If an infusion would
    // result in exceeding the max token balance, amount transferred is clamped
    // to the max.
    uint256 maxTokenBalance;

    // When claiming mined tokens, at least this much must be claimed at a time.
    uint256 minClaimAmount;

    // If true, the infuser must own the NFT at time of infusion.
    bool requireNftIsOwned;

    // If true, an NFT can be infused more than once in the same realm.
    bool allowMultiInfuse;

    // If true, anybody with enough tokens may infuse an NFT. If false, they
    // must be on the infusers list.
    bool allowPublicInfusion;

    // If true, anybody who owns an infused NFT may claim the mined tokens. If
    // false, they must be on the claimers list
    bool allowPublicClaiming;

    // If true, NFTs from any ERC-721 contract can be infused. If false, the
    // contract address must be on the collections list.
    bool allowAllCollections;
}

// data provided when creating a realm
struct CreateRealmInput {
    // Display name for the realm. Does not have to be unique across HyperVIBES.
    string name;

    // Description for the realm.
    string description;

    // token, mining rate, an constraint data
    RealmConfig config;

    // Addresses that are allowed to add or remove admins, infusers, claimers,
    // or collections to the realm.
    address[] admins;

    // Addresses that are allowed to infuse NFTs. Ignored if the allow public
    // infusion constraint is true.
    address[] infusers;

    // Addresses that are allowed to claim mined tokens from an NFT. Ignored if
    // the allow public claiming constraint is true.
    address[] claimers;

    // NFT contract addresses that can be infused. Ignore if the allow all
    // collections constraint is true.
    IERC721[] collections;
}

// data provided when modifying a realm -- constraints, token, etc are not
// modifiable, but admins/infusers/claimers/collections can be added and removed
// by an admin
struct ModifyRealmInput {
    uint256 realmId;
    address[] adminsToAdd;
    address[] adminsToRemove;
    address[] infusersToAdd;
    address[] infusersToRemove;
    address[] claimersToAdd;
    address[] claimersToRemove;
    IERC721[] collectionsToAdd;
    IERC721[] collectionsToRemove;
}

// data provided when infusing an nft
struct InfuseInput {
    uint256 realmId;

    // NFT contract address
    IERC721 collection;

    // NFT token ID
    uint256 tokenId;

    // Infuser is manually specified, in the case of proxy infusions, msg.sender
    // might not be the infuser. Proxy infusions require msg.sender to be an
    // approved proxy by the credited infuser
    address infuser;

    // total amount of tokens to infuse. Actual infusion amount may be less
    // based on maxTokenBalance realm constraint
    uint256 amount;

    // emitted with event
    string comment;
}

// data provided when claiming from an infused nft
struct ClaimInput {
    uint256 realmId;

    // NFT contract address
    IERC721 collection;

    // NFT token ID
    uint256 tokenId;

    // amount to claim. If this is greater than total claimable, only the max
    // will be claimed (use a huge number here to "claim all" effectively)
    uint256 amount;
}

interface IHyperVIBES {
    event RealmCreated(uint256 indexed realmId, string name, string description);

    event AdminAdded(uint256 indexed realmId, address indexed admin);

    event AdminRemoved(uint256 indexed realmId, address indexed admin);

    event InfuserAdded(uint256 indexed realmId, address indexed infuser);

    event InfuserRemoved(uint256 indexed realmId, address indexed infuser);

    event CollectionAdded(uint256 indexed realmId, IERC721 indexed collection);

    event CollectionRemoved(uint256 indexed realmId, IERC721 indexed collection);

    event ClaimerAdded(uint256 indexed realmId, address indexed claimer);

    event ClaimerRemoved(uint256 indexed realmId, address indexed claimer);

    event ProxyAdded(uint256 indexed realmId, address indexed proxy);

    event ProxyRemoved(uint256 indexed realmId, address indexed proxy);

    event Infused(
        uint256 indexed realmId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        address infuser,
        uint256 amount,
        string comment
    );

    event Claimed(
        uint256 indexed realmId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );

    // setup a new realm, returns the ID
    function createRealm(CreateRealmInput memory create) external returns (uint256);

    // update admins, infusers, claimers, or collections for a realm
    function modifyRealm(ModifyRealmInput memory input) external;

    // infuse an nft
    function infuse(InfuseInput memory input) external returns (uint256);

    // allower operator to infuse or claim on behalf of msg.sender for a specific realm
    function allowProxy(uint256 realmId, address proxy) external;

    // deny operator the ability to infuse or claim on behalf of msg.sender for a specific realm
    function denyProxy(uint256 realmId, address proxy) external;

    // claim infused tokens
    function claim(ClaimInput memory input) external returns (uint256);

    // execute a batch of claims
    function batchClaim(ClaimInput[] memory batch) external returns (uint256);

    // execute a batch of infusions
    function batchInfuse(InfuseInput[] memory batch) external returns (uint256);

    // HyperVIBES
    function name() external pure returns (string memory);

    // total amount of mined tokens
    function currentMinedTokens(uint256 realmId, IERC721 collection, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
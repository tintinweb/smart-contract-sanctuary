// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./TokenLockManager.sol";


// initialization options for the faucet
struct FaucetOptions {
  IERC20 token;
  IERC721 nft;
  ITokenLockManager lock;
}

// view of token state
struct ManagedTokenInfo {
  uint256 tokenId;
  address owner;
  uint seedTimestamp;
  uint256 dailyRate;
  uint256 balance;
  uint256 claimable;
  uint lastClaimAt;
  bool isBurnt;
}

// Slightly different take on the NFT token faucet, this time requiring
// initializing every loaded NFT and JIT providing the ERC20 needed (eg, when
// using a 3P NFT contract/platform like screensaver.world)
contract NFTTokenFaucetV2 is AccessControlEnumerable {
  using EnumerableSet for EnumerableSet.UintSet;

  // grants ability to seed tokens
  bytes32 public constant SEEDER_ROLE = keccak256("SEEDER_ROLE");

  // grants ability to grant SEEDER_ROLE.
  bytes32 public constant SEEDER_ADMIN_ROLE = keccak256("SEEDER_ADMIN_ROLE");

  // ERC-20 contract
  IERC20 private _token;

  // ERC-721 contract
  IERC721 private _nft;

  // lock contract
  ITokenLockManager private _lock;

  // mapping from tokens -> seed date
  mapping (uint256 => uint) private _seededAt;

  // mapping from tokens -> last claim timestamp
  mapping (uint256 => uint) private _lastClaim;

  // mapping from tokens -> remaining balance
  mapping (uint256 => uint256) private _balances;

  // mapping from tokens -> daily rate
  mapping (uint256 => uint256) private _rates;

  // tokens this contract is managing
  EnumerableSet.UintSet private _tokens;

  // a claim has occured
  event Claim(
    uint256 indexed tokenId,
    address indexed claimer,
    uint256 amount);

  // a token was seeded
  event Seed(
    uint256 indexed tokenId,
    uint seedTimestamp,
    uint256 rate,
    uint256 totalDays);

  constructor(FaucetOptions memory options) {
    _token = options.token;
    _lock = options.lock;
    _nft = options.nft;

    // seeder role and admin role
    _setRoleAdmin(SEEDER_ADMIN_ROLE, SEEDER_ADMIN_ROLE);
    _setRoleAdmin(SEEDER_ROLE, SEEDER_ADMIN_ROLE);

    // contract deployer gets roles
    address msgSender = _msgSender();
    _setupRole(SEEDER_ADMIN_ROLE, msgSender);
    _setupRole(SEEDER_ROLE, msgSender);
  }

  // ---
  // iteration and views
  // ---

  // total count of managed tokens
  function tokenCount() external view returns (uint256) {
    return _tokens.length();
  }

  // get tokenId at an index
  function tokenIdAt(uint256 index) external view returns (uint256) {
    require(index < _tokens.length(), "index out of range");
    return _tokens.at(index);
  }

  // determine how many tokens are claimable for a specific NFT
  function claimable(uint256 tokenId) public view returns (uint256) {
    require(_tokens.contains(tokenId), "invalid token");
    uint256 balance = _balances[tokenId];
    uint256 claimFrom = _lastClaim[tokenId];
    uint256 secondsToClaim = block.timestamp - claimFrom;
    uint256 toClaim = secondsToClaim * _rates[tokenId] / 1 days;

    return toClaim > balance ? balance : toClaim;
  }

  // get info about a managed token
  function tokenInfo(uint256 tokenId) public view returns (ManagedTokenInfo memory) {
    require(_tokens.contains(tokenId), "invalid token");
    bool isBurnt = _isTokenBurnt(tokenId);
    return ManagedTokenInfo({
      tokenId: tokenId,
      owner: isBurnt ? address(0) : _nft.ownerOf(tokenId),
      seedTimestamp: _seededAt[tokenId],
      dailyRate: _rates[tokenId],
      balance: _balances[tokenId],
      claimable: claimable(tokenId),
      lastClaimAt: _lastClaim[tokenId],
      isBurnt: _isTokenBurnt(tokenId)
    });
  }

  // ---
  // meat n potatoes
  // ---

  // how much of the reserve token is left in the contract
  function reserveBalance() external view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  // seed an nft with the token
  function seed(uint256 tokenId, uint256 rate, uint256 totalDays, uint256 backdateDays) public {
    address msgSender = _msgSender();
    require(hasRole(SEEDER_ROLE, msgSender), "requires SEEDER_ROLE");
    require(!_tokens.contains(tokenId), "token already seeded");
    require(!_isTokenBurnt(tokenId), "token has been burnt");

    // take token from sender and stash in contract
    uint256 amount = totalDays * rate;
    _token.transferFrom(msgSender, address(this), amount);

    // allow backdating by setting the seed date in the past
    uint seedTimestamp = block.timestamp - backdateDays * 1 days;

    // set info for this token
    _tokens.add(tokenId);
    _balances[tokenId] = amount;
    _rates[tokenId] = rate;
    _seededAt[tokenId] = seedTimestamp;
    _lastClaim[tokenId] = seedTimestamp;

    emit Seed(tokenId, seedTimestamp, rate, totalDays);
  }

  // seed an nft with the token
  function seed(uint256 tokenId, uint256 rate, uint256 totalDays) external {
    return seed(tokenId, rate, totalDays, 0);
  }

  // claim all tokens inside an nft
  function claim(uint256 tokenId) external {
    return claim(tokenId, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
  }

  // take the generated tokens from an nft, up to amount
  function claim(uint256 tokenId, uint256 amount) public {
    address msgSender = _msgSender();
    require(_isApprovedOrOwner(tokenId, msgSender), "not owner or approved");
    require(!_lock.isTokenLocked(tokenId), "token is locked");

    // compute how much we can claim, only pay attention to amount if its less
    // than available
    uint256 availableToClaim = claimable(tokenId);
    uint256 toClaim = amount < availableToClaim ? amount : availableToClaim;
    require(toClaim > 0, "nothing to claim");

    // claim only as far up as we need to get our amount... basically "advances"
    // the lastClaim timestamp the exact amount needed to provide the amount
    // claim at = last + (to claim / rate) * 1 day, rewritten for div last
    uint claimAt = _lastClaim[tokenId] + toClaim * 1 days / _rates[tokenId];

    // update balances and execute ERC-20 transfer
    _balances[tokenId] -= toClaim;
    _lastClaim[tokenId] = claimAt;
    _token.transfer(msgSender, toClaim);

    emit Claim(tokenId, msgSender, toClaim);
  }

  // if an nft has been burned, allow rescuing all remaining ERC-20 tokens and
  // remove it from the list of managed nfts
  function cleanup(uint256 tokenId) external {
    address msgSender = _msgSender();
    require(hasRole(SEEDER_ROLE, msgSender), "requires SEEDER_ROLE");
    require(_balances[tokenId] != 0, "token has no balance");
    require(_isTokenBurnt(tokenId), "token is not burnt");

    // return remaining balance
    _token.transfer(msgSender, _balances[tokenId]);

    // clear
    _tokens.remove(tokenId);
    _balances[tokenId] = 0;
    _lastClaim[tokenId] = 0;
    _rates[tokenId] = 0;
  }

  // ---
  // utils
  // ---

  function _isTokenBurnt(uint256 tokenId) internal view returns (bool) {
    try _nft.ownerOf(tokenId) returns (address) {
      // if ownerOf didnt revert, then token is not burnt
      return false;
    } catch  {
      return true;
    }
  }

  // returns true if operator can manage tokenId
  function _isApprovedOrOwner(uint256 tokenId, address operator) internal view returns (bool) {
    address owner = _nft.ownerOf(tokenId);
    return owner == operator
      || _nft.getApproved(tokenId) == operator
      || _nft.isApprovedForAll(owner, operator);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./NFTTokenFaucetV2.sol";
import "./TokenLockManagerV2.sol";

// data saved for-each token
struct TokenData {
  address seeder; // faucet v2 address for legacy tokens, else artist
  address operator; // msg.sender for seed operation
  uint256 seededAt;
  uint256 dailyRate;
  bool isLegacyToken; // true = using v2
  uint256 balance; // mutable
  uint256 lastClaimAt; // mutable
}

// query input for batch get token data
struct Token {
  IERC721 nft;
  uint256 tokenId;
}

// info provided when seeding a token
struct SeedInput {
  IERC721 nft;
  uint256 tokenId;
  address seeder;
  uint256 dailyRate;
  uint256 totalDays;
}

// data return for a single token
struct TokenView {
  // input
  IERC721 nft;
  uint256 tokenId;

  // external state
  bool isValidToken;
  uint256 unlocksAt;
  address owner;
  string tokenURI;

  // data
  address seeder;
  address operator;
  uint256 seededAt;
  uint256 dailyRate;
  bool isLegacyToken;
  uint256 balance;
  uint256 lastClaimAt;

  // state
  uint256 claimable;
}

// used to do legacy seeds
struct LegacyFaucetInput {
  address seeder;
  IERC721 nft;
  NFTTokenFaucetV2 faucet;
}

struct FaucetContractOptions {
  IERC20 token;
  TokenLockManagerV2 lock;
  LegacyFaucetInput legacy;
}

// Seed NFTs from any contract with tokens that are "mined" at a linear rate,
// claimable by the token owner.
//
// Provenance Minting litepaper:
// - https://docs.sickvibes.xyz/vibes-protocol/provenance-mining/protocol-thesis
//
// Upgrades V2 to allow for tracking the original seeder, operator, and working
// across multiple contracts
contract NFTTokenFaucetV3 is AccessControlEnumerable {
  using EnumerableSet for EnumerableSet.UintSet;

  // grants ability to seed tokens
  bytes32 public constant SEEDER_ROLE = keccak256("SEEDER_ROLE");

  // grants ability to grant SEEDER_ROLE.
  bytes32 public constant SEEDER_ADMIN_ROLE = keccak256("SEEDER_ADMIN_ROLE");

  // ERC-20 contract
  IERC20 public token;

  // token lock manager
  TokenLockManagerV2 public lock;

  // total managed tokens
  uint256 public managedTokenCount;

  // legacy tokens
  uint256 public legacyTokenCount;

  // contract -> tokenId -> data
  mapping (IERC721 => mapping (uint256 => TokenData)) private _tokenData;

    // a claim has occured
  event Claim(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    address indexed claimer,
    uint256 amount);

  // a token was seeded
  event Seed(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    address indexed seeder,
    address operator,
    uint256 seedTimestamp,
    uint256 dailyRate,
    uint256 totalDays);

  constructor(FaucetContractOptions memory options) {
    token = options.token;
    lock = options.lock;

    // seeder role and admin role
    _setRoleAdmin(SEEDER_ADMIN_ROLE, SEEDER_ADMIN_ROLE);
    _setRoleAdmin(SEEDER_ROLE, SEEDER_ADMIN_ROLE);

    // contract deployer gets roles
    _setupRole(SEEDER_ADMIN_ROLE, msg.sender);
    _setupRole(SEEDER_ROLE, msg.sender);

    if (options.legacy.faucet != NFTTokenFaucetV2(address(0))) {
      _legacySeed(options.legacy);
    }
  }

  // ---
  // seeding
  // ---

  function seed(SeedInput memory input) external {
    IERC721 nft = input.nft;
    uint256 tokenId = input.tokenId;
    require(hasRole(SEEDER_ROLE, msg.sender), "requires SEEDER_ROLE");
    require(_tokenData[nft][tokenId].operator == address(0), "token already seeded");
    require(_isTokenValid(nft, tokenId), "invalid token");

    uint256 totalDays = input.totalDays;
    uint256 dailyRate = input.dailyRate;
    address seeder = input.seeder;

    // take token from sender and stash in contract
    uint256 amount = totalDays * dailyRate;
    token.transferFrom(msg.sender, address(this), amount);

    _tokenData[nft][tokenId] = TokenData({
      seeder: seeder,
      operator: msg.sender,
      seededAt: block.timestamp,
      dailyRate: dailyRate,
      balance: amount,
      isLegacyToken: false,
      lastClaimAt: block.timestamp
    });

    managedTokenCount++;

    emit Seed(nft, tokenId, seeder, msg.sender, block.timestamp, dailyRate, totalDays);
  }

  // given a faucet v2 contract, add info to this contract for all managed tokens
  function _legacySeed(LegacyFaucetInput memory input) private {
    NFTTokenFaucetV2 faucet = input.faucet;
    IERC721 nft = input.nft;
    address seeder = input.seeder;
    uint256 count = faucet.tokenCount();

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = faucet.tokenIdAt(i);
      require(_tokenData[nft][tokenId].operator == address(0), "token already seeded");
      ManagedTokenInfo memory legacyData = faucet.tokenInfo(tokenId);

      _tokenData[nft][tokenId] = TokenData({
        seeder: seeder,
        // since we have to resolve some of the below data JIT, stash the faucet
        // in the operator field of the struct so we can query the legacy
        // contract later
        operator: address(faucet),
        seededAt: legacyData.seedTimestamp,
        dailyRate: legacyData.dailyRate,
        isLegacyToken: true,

        // these values will have to be resolved JIT during queries
        balance: 0,
        lastClaimAt: 0
      });

      // using zero values for rate and total days as sentinels for legacy seeds
      emit Seed(nft, tokenId, seeder, address(faucet), legacyData.seedTimestamp, 0, 0);
    }

    legacyTokenCount += count;
  }

  // ---
  // claiming
  // ---

  // take the generated tokens from an nft, up to amount
  function claim(IERC721 nft, uint256 tokenId, uint256 amount) public {
    require(_isApprovedOrOwner(nft, tokenId, msg.sender), "not owner or approved");
    require(!lock.isTokenLocked(nft, tokenId), "token locked");

    // compute how much we can claim, only pay attention to amount if its less
    // than available
    uint256 availableToClaim = claimable(nft, tokenId); // throws here on legacy token
    uint256 toClaim = amount < availableToClaim ? amount : availableToClaim;
    require(toClaim > 0, "nothing to claim");

    TokenData memory data = _tokenData[nft][tokenId];

    // claim only as far up as we need to get our amount... basically "advances"
    // the lastClaim timestamp the exact amount needed to provide the amount
    // claim at = last + (to claim / rate) * 1 day, rewritten for div last
    uint256 claimAt = data.lastClaimAt + toClaim * 1 days / data.dailyRate;

    // update balances and execute ERC-20 transfer
    _tokenData[nft][tokenId].balance -= toClaim;
    _tokenData[nft][tokenId].lastClaimAt = claimAt;
    token.transfer(msg.sender, toClaim);

    emit Claim(nft, tokenId, msg.sender, toClaim);
  }

  // ---
  // views
  // ---

  // determine how many tokens are claimable for a specific NFT
  function claimable(IERC721 nft, uint256 tokenId) public view returns (uint256) {
    TokenData memory data = _tokenData[nft][tokenId];
    require(data.operator != address(0), "token not seeded");
    require(!data.isLegacyToken, "cannot claim from legacy token");
    require(_isTokenValid(nft, tokenId), "invalid token");

    uint256 balance = data.balance;
    uint256 lastClaimAt = data.lastClaimAt;
    uint256 secondsToClaim = block.timestamp - lastClaimAt;
    uint256 toClaim = secondsToClaim * data.dailyRate / 1 days;

    return toClaim > balance ? balance : toClaim;
  }

  // get token info. returns an empty struct (zero-inited) if not found
  function getToken(IERC721 nft, uint256 tokenId) public view returns (TokenView memory) {
    TokenData memory data = _tokenData[nft][tokenId];
    bool isValid = _isTokenValid(nft, tokenId);

    TokenView memory tokenView = TokenView({
      nft: nft,
      tokenId: tokenId,
      isValidToken: isValid,
      tokenURI: _tokenURIOrEmpty(nft, tokenId),
      seeder: data.seeder,
      operator: data.operator,
      seededAt: data.seededAt,
      dailyRate: data.dailyRate,
      unlocksAt: lock.tokenUnlocksAt(nft, tokenId),
      owner: isValid ? nft.ownerOf(tokenId) : address(0),
      isLegacyToken: data.isLegacyToken,
      balance: data.balance,
      lastClaimAt: data.lastClaimAt,
      claimable: 0 // set below
    });

    // if its a legacy token, query the original contract for real-time info
    if (data.isLegacyToken) {
      ManagedTokenInfo memory legacyData = NFTTokenFaucetV2(data.operator).tokenInfo(tokenId);
      tokenView.balance = legacyData.balance;
      tokenView.lastClaimAt = legacyData.lastClaimAt;
      tokenView.claimable = legacyData.claimable;
    // else if its an actual valid token, resolve claimable amount
    } else if (isValid) {
      tokenView.claimable = claimable(nft, tokenId);
    } else {
      // invalid tokens cannot compute claimable, claimable stays zero
    }

    return tokenView;
  }

  // gets a batch of tokens, OR empty (zero-ed out) struct if not found, DOES
  // NOT THROW if invalid token in order to be more accomodating for callers
  function batchGetToken(Token[] memory tokens) external view returns (TokenView[] memory) {
    TokenView[] memory data = new TokenView[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      data[i] = getToken(tokens[i].nft, tokens[i].tokenId);
    }

    return data;
  }

  // ---
  // utils
  // ---

  // returns true if token exists (and is not burnt)
  function _isTokenValid(IERC721 nft, uint256 tokenId) internal view returns (bool) {
    try nft.ownerOf(tokenId) returns (address) {
      return true;
    } catch  {
      return false;
    }
  }

  // return token URI if metadata is implemented, else empty string
  function _tokenURIOrEmpty(IERC721 nft, uint256 tokenId) internal view returns (string memory) {
    try IERC721Metadata(address(nft)).tokenURI(tokenId) returns (string memory uri) {
      return uri;
    } catch  {
      return "";
    }
  }

  // returns true if operator can manage tokenId
  function _isApprovedOrOwner(IERC721 nft, uint256 tokenId, address operator) internal view returns (bool) {
    address owner = nft.ownerOf(tokenId);
    return owner == operator
      || nft.getApproved(tokenId) == operator
      || nft.isApprovedForAll(owner, operator);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// required implementation api for token lock manager
interface ITokenLockManager is IERC165 {
  function tokenUnlocksAt(uint256 tokenId) external view returns (uint);
  function isTokenLocked(uint256 tokenId) external view returns (bool);
  function lockToken(uint256 tokenId) external returns (uint);
  function unlockToken(uint256 tokenId) external returns (uint);
}

// a token lock manager will handle the locking and unlocking of tokens
contract TokenLockManager is ERC165, ITokenLockManager {

  // timestamp when a token should be considered unlocked
  mapping (uint256 => uint) private _tokenUnlockTime;

  // nft contract
  IERC721 private _nft;

  constructor(IERC721 nft) {
    _nft = nft;
  }

  // ---
  // Locking functionality
  // ---

  // the timestamp that a token unlocks at
  function tokenUnlocksAt(uint256 tokenId) override external view returns (uint) {
    return _tokenUnlockTime[tokenId];
  }

  // true if a token is currently locked
  function isTokenLocked(uint256 tokenId) override external view returns (bool) {
    return _tokenUnlockTime[tokenId] >= block.timestamp;
  }

  // lock a token for (up to) 30 days
  function lockToken(uint256 tokenId) override external returns (uint) {
    require(_isApprovedOrOwner(tokenId, msg.sender), "cannot manage token");

    uint unlockAt = block.timestamp + 30 days;
    _tokenUnlockTime[tokenId] = unlockAt;

    return unlockAt;
  }

  // unlock token (shorten unlock time down to 1 day at most)
  function unlockToken(uint256 tokenId) override external returns (uint) {
    require(_isApprovedOrOwner(tokenId, msg.sender), "cannot manage token");

    uint max = block.timestamp + 1 days;
    uint current = _tokenUnlockTime[tokenId];
    uint unlockAt = current > max ? max : current;
    _tokenUnlockTime[tokenId] = unlockAt;

    return unlockAt;
  }

  // returns true if operator can manage tokenId
  function _isApprovedOrOwner(uint256 tokenId, address operator) internal view returns (bool) {
    address owner = _nft.ownerOf(tokenId);
    return owner == operator
      || _nft.getApproved(tokenId) == operator
      || _nft.isApprovedForAll(owner, operator);
  }

  // ---
  // introspection
  // ---

  function supportsInterface(bytes4 interfaceId) override(ERC165, IERC165) public view virtual returns (bool) {
    return interfaceId == type(ITokenLockManager).interfaceId || super.supportsInterface(interfaceId);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// a token lock manager will handle the locking and unlocking of tokens
// upgrades from V1 to work across multiple nft contracts
contract TokenLockManagerV2 {

  event Lock(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    uint256 unlockAt
  );

  event Unlock(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    uint256 unlockAt
  );

  // timestamp when a token should be considered unlocked
  mapping(IERC721 => mapping (uint256 => uint)) private _tokenUnlockTime;

  // ---
  // Locking functionality
  // ---

  // lock a token for (up to) 30 days
  function lockToken(IERC721 nft, uint256 tokenId) external {
    require(_isApprovedOrOwner(nft, tokenId, msg.sender), "cannot manage token");

    uint unlockAt = block.timestamp + 30 days;
    _tokenUnlockTime[nft][tokenId] = unlockAt;

    emit Lock(nft, tokenId, unlockAt);
  }

  // unlock token (shorten unlock time down to 1 day at most)
  function unlockToken(IERC721 nft, uint256 tokenId) external {
    require(_isApprovedOrOwner(nft, tokenId, msg.sender), "cannot manage token");

    uint max = block.timestamp + 1 days;
    uint current = _tokenUnlockTime[nft][tokenId];
    uint unlockAt = current > max ? max : current;
    _tokenUnlockTime[nft][tokenId] = unlockAt;

    emit Unlock(nft, tokenId, unlockAt);
  }

  // ---
  // views
  // ---

  // the timestamp that a token unlocks at
  function tokenUnlocksAt(IERC721 nft, uint256 tokenId) external view returns (uint) {
    return _tokenUnlockTime[nft][tokenId];
  }

  // true if a token is currently locked
  function isTokenLocked(IERC721 nft, uint256 tokenId) external view returns (bool) {
    return _tokenUnlockTime[nft][tokenId] >= block.timestamp;
  }

  // ---
  // utils
  // ---

  // returns true if operator can manage tokenId
  function _isApprovedOrOwner(IERC721 nft, uint256 tokenId, address operator) internal view returns (bool) {
    address owner = nft.ownerOf(tokenId);
    return owner == operator
      || nft.getApproved(tokenId) == operator
      || nft.isApprovedForAll(owner, operator);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTTokenFaucetV3.sol";

contract FaucetV3 is NFTTokenFaucetV3 {

  string public constant name = 'FaucetV3';

  constructor(FaucetContractOptions memory options) NFTTokenFaucetV3(options) { }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
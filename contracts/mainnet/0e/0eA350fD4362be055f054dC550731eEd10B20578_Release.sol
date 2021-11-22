// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Governed.sol';
import './OwnerBalanceContributor.sol';
import './Macabris.sol';
import './Bank.sol';

/**
 * @title Macabris token initial randomised sale contract
 */
contract Release is Governed, OwnerBalanceContributor {

    // Represents a sale of a token
    struct Sale {
        address buyer;
        uint price;
        uint fee;
        uint blockNumber;
    }

    // Macabris NFT contract
    Macabris public macabris;

    // Bank contract
    Bank public bank;

    // Price of a single token
    uint public price;

    // Total available tokens
    uint256 public immutable tokensTotal;

    // Total sold tokens
    uint256 public tokensSold;

    // Total revealed tokens
    uint256 public tokensRevealed;

    // Owner fee in bps
    uint256 public ownerFee;

    // Automatic price increase amount
    uint public priceIncreaseAmount;

    // Number of sales that trigger automatic price increase
    uint256 public priceIncreaseFrequency;

    // Sales mapped by sale ID
    mapping(uint256 => Sale) private sales;

    // Revealed token IDs, mapped by sale ID (only valid until the tokensRevealed-1)
    mapping(uint256 => uint256) private reveals;

    /**
     * @dev Emitted when a token is sold through the `buy` method
     * @param saleId Sale ID
     * @param buyer Buyer address
     * @param blockNumber Block number of the buy transaction
     * @param price Price in wei
     */
    event Buy(uint256 indexed saleId, address indexed buyer, uint blockNumber, uint price);

    /**
     * @dev Emitted when a token is revealed through the `reveal` method
     * @param saleId Sale ID
     * @param tokenId Revealed token ID
     * @param price Price in wei
     */
    event Reveal(uint256 indexed saleId, uint256 indexed tokenId, uint price);

    /**
     * @param _tokensTotal Total number of tokens that can be realeased
     * @param _price Price of a new token in wei
     * @param governanceAddress Address of the Governance contract
     * @param ownerBalanceAddress Address of the OwnerBalance contract
     *
     * Requirements:
     * - There should be less total tokens than the max value of uint256
     * - Governance contract must be deployed at the given address
     * - OwnerBalance contract must be deployed at the given address
     */
    constructor(
        uint256 _tokensTotal,
        uint _price,
        address governanceAddress,
        address ownerBalanceAddress
    ) Governed(governanceAddress) OwnerBalanceContributor(ownerBalanceAddress) {

        // Since the token IDs start with 1, the full uint256 range is not supported.
        require(_tokensTotal < type(uint256).max, "Max token count must be less than max int256 value");

        tokensTotal = _tokensTotal;
        price = _price;
    }

    /**
     * @dev Sets Macabris NFT contract address
     * @param macabrisAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Macabris contract must be deployed at the given address
     */
    function setMacabrisAddress(address macabrisAddress) external canBootstrap(msg.sender) {
        macabris = Macabris(macabrisAddress);
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets price for the new tokens
     * @param _price Price in wei
     *
     * Requirements:
     * - the caller must have the configure permission
     * - price must be bigger than the current price
     */
    function setPrice(uint _price) external canConfigure(msg.sender) {
        require(_price > price, "Price can only be increased up");
        price = _price;
    }

    /**
     * @dev Sets automatic price increase amount
     * @param amount Amount in wei
     *
     * Requirements:
     * - the caller must have the configure permission
     */
    function setPriceIncreaseAmount(uint amount) external canConfigure(msg.sender) {
        priceIncreaseAmount = amount;
    }

    /**
     * @dev Sets the number of sales that trigger automatic price increase
     * @param frequency Number of sales, zero to disable automatic price increases
     *
     * Requirements:
     * - the caller must have the configure permission
     */
    function setPriceIncreaseFrequency(uint frequency) external canConfigure(msg.sender) {
        priceIncreaseFrequency = frequency;
    }

    /**
     * @dev Sets owner fee
     * @param _ownerFee Owner fee in bps
     *
     * Requirements:
     * - the caller must have the configure permission
     * - owner fee should divide 10000 without a remainder
     */
    function setOwnerFee(uint256 _ownerFee) external canConfigure(msg.sender) {

        if (_ownerFee > 0) {
            require(10000 % _ownerFee == 0, "Owner fee amount must divide 10000 without a remainder");
        }

        ownerFee = _ownerFee;
    }

    /**
     * @dev Buys a random token, to be revealed later
     *
     * Requirements:
     * - Current amount of tokens sold must be lower than max token count
     * - `msg.value` must exactly match the `price` property
     *
     * Emits {Buy} event
     */
    function buy() external payable {
        require(tokensSold < tokensTotal, "Tokens are sold out");
        require(msg.value == price, "Transaction value does not match token price");

        uint fee = _calculateFeeAmount(price, ownerFee);
        uint saleId = tokensSold;

        sales[saleId] = Sale({
            buyer: msg.sender,
            price: price,
            fee: fee,
            blockNumber: block.number
        });
        tokensSold++;

        // Do automatic price increase for the future token sales
        if (priceIncreaseFrequency > 0 && tokensSold % priceIncreaseFrequency == 0) {
            price += priceIncreaseAmount;
        }

        _transferToOwnerBalance(fee);

        emit Buy(saleId, msg.sender, block.number, sales[saleId].price);
    }

    /**
     * @dev Reveals the token ID for the oldest unrevealed sale
     *
     * Uses reversed Fisher-Yates-Durstenfeld-Knuth shuffle algorithm to assign tokens:
     * https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
     *
     * Uses hash of the buy transaction block, which isn't known during the buy transaction, as a
     * source of randomness.
     *
     * This method should be periodically called by a background process to reveal any new sales.
     * This way the UX of the buy process is better, because the user only needs to issue one buy
     * transaction to buy a token. However, the method can be called by anyone, to make sure the
     * contract is functional even if said background process dies for some reason.
     *
     * Requirements:
     * - There must be unrevealed sales
     * - Sale can't be revealed in the same block as the buy transaction
     *
     * Emits {Reveal} event
     */
    function reveal() external {
        require(tokensRevealed < tokensSold, "All sales have been already revealed");
        uint saleId = tokensRevealed;
        Sale storage sale = sales[saleId];

        // Miners can influence block hash to some degree, but the reward for a valid block is much
        // higher than the value of a change of the revealed token to a different random token.
        require(
            block.number > sale.blockNumber,
            "Token can't be reavealed in the same block as the buy transaction"
        );

        // Normally, the reveal method should be called by a background process shortly after the
        // sale occured. If that doesn't happen for some reason, and 256 blocks are mined after the
        // sale has happenned, block hash of the sale transaction won't be available anymore.
        //
        // Using the block hash of the last block as a fallback source of randomness, but it opens
        // up the possibility to revert the reveal transaction and try again, only spending the gas
        // costs on each try.
        bytes32 blockHash = blockhash(sale.blockNumber);
        blockHash = blockHash == 0 ? blockhash(block.number - 1) : blockHash;

        // If only the block hash is used as the source of randomness, then all the sales of the same
        // block would reveal tokens sequentially, with one token gaps in between. Hashing block hash
        // and the total number of revealed tokens to make the reveals spread out randomly even for
        // the sales in the same block.
        uint256 tokensHidden = tokensTotal - tokensRevealed;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockHash, tokensRevealed)));
        uint256 tokenOffset = tokensRevealed + (randomNumber > 0 ? randomNumber % tokensHidden : 0);

        // The reaveals mapping represents all the possible tokens, but is initiated with zeros
        // during the contract construction. A zero value in the mapping represents a token with
        // an ID matching the index plus one.
        uint256 revealedTokenId = reveals[tokenOffset];
        revealedTokenId = revealedTokenId == 0 ? tokenOffset + 1 : revealedTokenId;

        uint256 currentTokenId = reveals[tokensRevealed];
        currentTokenId = currentTokenId == 0 ? tokensRevealed + 1 : currentTokenId;

        // Switching token ID in the current reveal index with the revealed token ID, keeping all
        // the revealed tokens in the [0, tokensRevealed - 1] range, and the remaining ones in the
        // [tokensRevealed, tokensTotal - 1] range.
        reveals[saleId] = revealedTokenId;
        reveals[tokenOffset] = currentTokenId;

        tokensRevealed++;

        macabris.onRelease(revealedTokenId, sale.buyer);
        bank.deposit{value: sale.price - sale.fee}();

        emit Reveal(saleId, revealedTokenId, sale.price);
    }

    /**
     * @dev Calculates fee amount based on given price and fee in bps
     * @param _price Price base for calculation
     * @param fee Fee in basis points
     * @return Fee amount in wei
     */
    function _calculateFeeAmount(uint _price, uint fee) private pure returns (uint) {

        // Fee might be zero, avoiding division by zero
        if (fee == 0) {
            return 0;
        }

        // Only using division to make sure there is no overflow of the return value.
        // This is the reason why fee must divide 10000 without a remainder, otherwise
        // because of integer division fee won't be accurate.
        return _price / (10000 / fee);
    }

    /**
     * @dev Returns revealed token ID for the given sale
     * @param saleId Sale ID, could be retrieved from the Sale event emitted in the `buy` method
     * @return Revealed token ID
     *
     * Requirements:
     * - Sale must be previously revealed using the `reveal` method
     */
    function getRevealedTokenId(uint256 saleId) external view returns (uint256) {
        require(saleId < tokensRevealed, "Sale does not exist or is not yet revealed");
        return reveals[saleId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Governed.sol';
import './Bank.sol';

/**
 * @title Contract tracking deaths of Macabris tokens
 */
contract Reaper is Governed {

    // Bank contract
    Bank public bank;

    // Mapping from token ID to time of death
    mapping (uint256 => int64) private _deaths;

    /**
     * @dev Emitted when a token is marked as dead
     * @param tokenId Token ID
     * @param timeOfDeath Time of death (unix timestamp)
     */
    event Death(uint256 indexed tokenId, int64 timeOfDeath);

    /**
     * @dev Emitted when a previosly dead token is marked as alive
     * @param tokenId Token ID
     */
    event Resurrection(uint256 indexed tokenId);

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(address governanceAddress) Governed(governanceAddress) {}

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of Bank contract
     *
     * Requirements:
     * - the caller must have the boostrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Marks token as dead and sets time of death
     * @param tokenId Token ID
     * @param timeOfDeath Tome of death (unix timestamp)
     *
     * Requirements:
     * - the caller must have permission to manage deaths
     * - `timeOfDeath` can't be 0
     *
     * Note that tokenId doesn't have to be minted in order to be marked dead.
     *
     * Emits {Death} event
     */
    function markDead(uint256 tokenId, int64 timeOfDeath) external canManageDeaths(msg.sender) {
        require(timeOfDeath != 0, "Time of death of 0 represents an alive token");
        _deaths[tokenId] = timeOfDeath;

        bank.onTokenDeath(tokenId);
        emit Death(tokenId, timeOfDeath);
    }

    /**
     * @dev Marks token as alive
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must have permission to manage deaths
     * - `tokenId` must be currently marked as dead
     *
     * Emits {Resurrection} event
     */
    function markAlive(uint256 tokenId) external canManageDeaths(msg.sender) {
        require(_deaths[tokenId] != 0, "Token is not dead");
        _deaths[tokenId] = 0;

        bank.onTokenResurrection(tokenId);
        emit Resurrection(tokenId);
    }

    /**
     * @dev Returns token's time of death
     * @param tokenId Token ID
     * @return Time of death (unix timestamp) or zero, if alive
     *
     * Note that any tokenId could be marked as dead, even not minted or not existant one.
     */
    function getTimeOfDeath(uint256 tokenId) external view returns (int64) {
        return _deaths[tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './OwnerBalance.sol';

/**
 * @title Allows allocating portion of the contract's funds to the owner balance
 */
abstract contract OwnerBalanceContributor {

    // OwnerBalance contract address
    address public immutable ownerBalanceAddress;

    uint public ownerBalanceDeposits;

    /**
     * @param _ownerBalanceAddress Address of the OwnerBalance contract
     */
    constructor (address _ownerBalanceAddress) {
        ownerBalanceAddress = _ownerBalanceAddress;
    }

    /**
     * @dev Assigns given amount of contract funds to the owner's balance
     * @param amount Amount in wei
     */
    function _transferToOwnerBalance(uint amount) internal {
        ownerBalanceDeposits += amount;
    }

    /**
     * @dev Allows OwnerBalance contract to withdraw deposits
     * @param ownerAddress Owner address to send funds to
     *
     * Requirements:
     * - caller must be the OwnerBalance contract
     */
    function withdrawOwnerBalanceDeposits(address ownerAddress) external {
        require(msg.sender == ownerBalanceAddress, 'Caller must be the OwnerBalance contract');
        uint currentBalance = ownerBalanceDeposits;
        ownerBalanceDeposits = 0;
        payable(ownerAddress).transfer(currentBalance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Governed.sol';
import './OwnerBalanceContributor.sol';

/**
 * @title Tracks owner's share of the funds in various Macabris contracts
 */
contract OwnerBalance is Governed {

    address public owner;

    // All three contracts, that contribute to the owner's balance
    OwnerBalanceContributor public release;
    OwnerBalanceContributor public bank;
    OwnerBalanceContributor public market;

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(address governanceAddress) Governed(governanceAddress) {}

    /**
     * @dev Sets the release contract address
     * @param releaseAddress Address of the Release contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setReleaseAddress(address releaseAddress) external canBootstrap(msg.sender) {
        release = OwnerBalanceContributor(releaseAddress);
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = OwnerBalanceContributor(bankAddress);
    }

    /**
     * @dev Sets the market contract address
     * @param marketAddress Address of the Market contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setMarketAddress(address marketAddress) external canBootstrap(msg.sender) {
        market = OwnerBalanceContributor(marketAddress);
    }

    /**
     * @dev Sets owner address where the funds will be sent during withdrawal
     * @param _owner Owner's address
     *
     * Requirements:
     * - sender must have canSetOwnerAddress permission
     * - address must not be 0
     */
    function setOwner(address _owner) external canSetOwnerAddress(msg.sender) {
        require(_owner != address(0), "Empty owner address is not allowed!");
        owner = _owner;
    }

    /**
     * @dev Returns total available balance in all contributing contracts
     * @return Balance in wei
     */
    function getBalance() external view returns (uint) {
        uint balance;

        balance += release.ownerBalanceDeposits();
        balance += bank.ownerBalanceDeposits();
        balance += market.ownerBalanceDeposits();

        return balance;
    }

    /**
     * @dev Withdraws available balance to the owner address
     *
     * Requirements:
     * - owner address must be set
     * - sender must have canTriggerOwnerWithdraw permission
     */
    function withdraw() external canTriggerOwnerWithdraw(msg.sender) {
        require(owner != address(0), "Owner address is not set");

        release.withdrawOwnerBalanceDeposits(owner);
        bank.withdrawOwnerBalanceDeposits(owner);
        market.withdrawOwnerBalanceDeposits(owner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './Governed.sol';
import './Bank.sol';

contract Macabris is ERC721, Governed {

    // Release contract address, used to whitelist calls to `onRelease` method
    address public releaseAddress;

    // Market contract address, used to whitelist calls to `onMarketSale` method
    address public marketAddress;

    // Bank contract
    Bank public bank;

    // Base URI of the token's metadata
    string public baseUri;

    // Personas sha256 hash (all UTF-8 names with a "\n" char after each name, sorted by token ID)
    bytes32 public immutable hash;

    /**
     * @param _hash Personas sha256 hash (all UTF-8 names with a "\n" char after each name, sorted by token ID)
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(
        bytes32 _hash,
        address governanceAddress
    ) ERC721('Macabris', 'MCBR') Governed(governanceAddress) {
        hash = _hash;
    }

    /**
     * @dev Sets the release contract address
     * @param _releaseAddress Address of the Release contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setReleaseAddress(address _releaseAddress) external canBootstrap(msg.sender) {
        releaseAddress = _releaseAddress;
    }

    /**
     * @dev Sets the market contract address
     * @param _marketAddress Address of the Market contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setMarketAddress(address _marketAddress) external canBootstrap(msg.sender) {
        marketAddress = _marketAddress;
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets metadata base URI
     * @param _baseUri Base URI, token's ID will be appended at the end
     */
    function setBaseUri(string memory _baseUri) external canConfigure(msg.sender) {
        baseUri = _baseUri;
    }

    /**
     * @dev Checks if the token exists
     * @param tokenId Token ID
     * @return True if token with given ID has been minted already, false otherwise
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Overwrites to return base URI set by the contract owner
     */
    function _baseURI() override internal view returns (string memory) {
        return baseUri;
    }

    function _transfer(address from, address to, uint256 tokenId) override internal {
        super._transfer(from, to, tokenId);
        bank.onTokenTransfer(tokenId, from, to);
    }

    function _mint(address to, uint256 tokenId) override internal {
        super._mint(to, tokenId);
        bank.onTokenTransfer(tokenId, address(0), to);
    }

    /**
     * @dev Registers new token after it's sold and revealed in the Release contract
     * @param tokenId Token ID
     * @param buyer Buyer address
     *
     * Requirements:
     * - The caller must be the Release contract
     * - `tokenId` must not exist
     * - Buyer cannot be the zero address
     *
     * Emits a {Transfer} event.
     */
    function onRelease(uint256 tokenId, address buyer) external {
        require(msg.sender == releaseAddress, "Caller must be the Release contract");

        // Also checks that the token does not exist and that the buyer is not 0 address.
        // Using unsafe mint to prevent a situation where a sale could not be revealed in the
        // realease contract, because the buyer address does not implement IERC721Receiver.
        _mint(buyer, tokenId);
    }

    /**
     * @dev Transfers token ownership after a sale on the Market contract
     * @param tokenId Token ID
     * @param seller Seller address
     * @param buyer Buyer address
     *
     * Requirements:
     * - The caller must be the Market contract
     * - `tokenId` must exist
     * - `seller` must be the owner of the token
     * - `buyer` cannot be the zero address
     *
     * Emits a {Transfer} event.
     */
    function onMarketSale(uint256 tokenId, address seller, address buyer) external {
        require(msg.sender == marketAddress, "Caller must be the Market contract");

        // Also checks if the token exists, if the seller is the current owner and that the buyer is
        // not 0 address.
        // Using unsafe transfer to prevent a situation where the token owner can't accept the
        // highest bid, because the bidder address does not implement IERC721Receiver.
        _transfer(seller, buyer, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Governance.sol';

/**
 * @title Provides permission check modifiers for child contracts
 */
abstract contract Governed {

    // Governance contract
    Governance public immutable governance;

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor (address governanceAddress) {
        governance = Governance(governanceAddress);
    }

    /**
     * @dev Throws if given address that doesn't have ManagesDeaths permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canManageDeaths(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.ManageDeaths),
            "Governance: subject is not allowed to manage deaths"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have Configure permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canConfigure(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.Configure),
            "Governance: subject is not allowed to configure contracts"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have Bootstrap permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canBootstrap(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.Bootstrap),
            "Governance: subject is not allowed to bootstrap"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have SetOwnerAddress permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canSetOwnerAddress(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.SetOwnerAddress),
            "Governance: subject is not allowed to set owner address"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have TriggerOwnerWithdraw permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canTriggerOwnerWithdraw(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.TriggerOwnerWithdraw),
            "Governance: subject is not allowed to trigger owner withdraw"
        );
        _;
    }

    /**
     * @dev Throws if given address that doesn't have StopPayouyts permission
     * @param subject Address to check permissions for, usually msg.sender
     */
    modifier canStopPayouts(address subject) {
        require(
            governance.hasPermission(subject, Governance.Actions.StopPayouts),
            "Governance: subject is not allowed to stop payouts"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Manages address permissions to act on Macabris contracts
 */
contract Governance {

    enum Actions { Vote, Configure, SetOwnerAddress, TriggerOwnerWithdraw, ManageDeaths, StopPayouts, Bootstrap }

    // Stores permissions of an address
    struct Permissions {
        bool canVote;
        bool canConfigure;
        bool canSetOwnerAddress;
        bool canTriggerOwnerWithdraw;
        bool canManageDeaths;
        bool canStopPayouts;

        // Special permission that can't be voted in and only the deploying address receives
        bool canBootstrap;
    }

    // A call for vote to change address permissions
    struct CallForVote {

        // Address that will be assigned the permissions if the vote passes
        address subject;

        // Permissions to be assigned if the vote passes
        Permissions permissions;

        // Total number of votes for and against the permission change
        uint128 yeas;
        uint128 nays;
    }

    // A vote in a call for vote
    struct Vote {
        uint64 callForVoteIndex;
        bool yeaOrNay;
    }

    // Permissions of addresses
    mapping(address => Permissions) private permissions;

    // List of calls for a vote: callForVoteIndex => CallForVote, callForVoteIndex starts from 1
    mapping(uint => CallForVote) private callsForVote;

    // Last registered call for vote of every address: address => callForVoteIndex
    mapping(address => uint64) private lastRegisteredCallForVote;

    // Votes of every address: address => Vote
    mapping(address => Vote) private votes;

    uint64 public resolvedCallsForVote;
    uint64 public totalCallsForVote;
    uint64 public totalVoters;

    /**
     * @dev Emitted when a new call for vote is registered
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param subject Subject address to change permissions to if vote passes
     * @param canVote Allow subject address to vote
     * @param canConfigure Allow subject address to configure prices, fees and base URI
     * @param canSetOwnerAddress Allows subject to change owner withdraw address
     * @param canTriggerOwnerWithdraw Allow subject address to trigger withdraw from owner's balance
     * @param canManageDeaths Allow subject to set tokens as dead or alive
     * @param canStopPayouts Allow subject to stop the bank payout schedule early
     */
    event CallForVoteRegistered(
        uint64 indexed callForVoteIndex,
        address indexed caller,
        address indexed subject,
        bool canVote,
        bool canConfigure,
        bool canSetOwnerAddress,
        bool canTriggerOwnerWithdraw,
        bool canManageDeaths,
        bool canStopPayouts
    );

    /**
     * @dev Emitted when a call for vote is resolved
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param yeas Total yeas for the call after the vote
     * @param nays Total nays for the call after the vote
     */
    event CallForVoteResolved(
        uint64 indexed callForVoteIndex,
        uint128 yeas,
        uint128 nays
    );

    /**
     * @dev Emitted when a vote is casted
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param voter Voter address
     * @param yeaOrNay Vote, true if yea, false if nay
     * @param totalVoters Total addresses with vote permission at the time of event
     * @param yeas Total yeas for the call after the vote
     * @param nays Total nays for the call after the vote
     */
    event VoteCasted(
        uint64 indexed callForVoteIndex,
        address indexed voter,
        bool yeaOrNay,
        uint64 totalVoters,
        uint128 yeas,
        uint128 nays
    );

    /**
     * @dev Inits the contract and gives the deployer address all permissions
     */
    constructor() {
        _setPermissions(msg.sender, Permissions({
            canVote: true,
            canConfigure: true,
            canSetOwnerAddress: true,
            canTriggerOwnerWithdraw: true,
            canManageDeaths: true,
            canStopPayouts: true,
            canBootstrap: true
        }));
    }

    /**
     * @dev Checks if the given address has permission to perform given action
     * @param subject Address to check
     * @param action Action to check permissions against
     * @return True if given address has permission to perform given action
     */
    function hasPermission(address subject, Actions action) public view returns (bool) {
        if (action == Actions.ManageDeaths) {
            return permissions[subject].canManageDeaths;
        }

        if (action == Actions.Vote) {
            return permissions[subject].canVote;
        }

        if (action == Actions.SetOwnerAddress) {
            return permissions[subject].canSetOwnerAddress;
        }

        if (action == Actions.TriggerOwnerWithdraw) {
            return permissions[subject].canTriggerOwnerWithdraw;
        }

        if (action == Actions.Configure) {
            return permissions[subject].canConfigure;
        }

        if (action == Actions.StopPayouts) {
            return permissions[subject].canStopPayouts;
        }

        if (action == Actions.Bootstrap) {
            return permissions[subject].canBootstrap;
        }

        return false;
    }

    /**
     * Sets permissions for a given address
     * @param subject Subject address to set permissions to
     * @param _permissions Permissions
     */
    function _setPermissions(address subject, Permissions memory _permissions) private {

        // Tracks count of total voting addresses to be able to calculate majority
        if (permissions[subject].canVote != _permissions.canVote) {
            if (_permissions.canVote) {
                totalVoters += 1;
            } else {
                totalVoters -= 1;

                // Cleaning up voting-related state for the address
                delete votes[subject];
                delete lastRegisteredCallForVote[subject];
            }
        }

        permissions[subject] = _permissions;
    }

    /**
     * @dev Registers a new call for vote to change address permissions
     * @param subject Subject address to change permissions to if vote passes
     * @param canVote Allow subject address to vote
     * @param canConfigure Allow subject address to configure prices, fees and base URI
     * @param canSetOwnerAddress Allows subject to change owner withdraw address
     * @param canTriggerOwnerWithdraw Allow subject address to trigger withdraw from owner's balance
     * @param canManageDeaths Allow subject to set tokens as dead or alive
     * @param canStopPayouts Allow subject to stop the bank payout schedule early
     *
     * Requirements:
     * - the caller must have the vote permission
     * - the caller shouldn't have any unresolved calls for vote
     */
    function callForVote(
        address subject,
        bool canVote,
        bool canConfigure,
        bool canSetOwnerAddress,
        bool canTriggerOwnerWithdraw,
        bool canManageDeaths,
        bool canStopPayouts
    ) external {
        require(
            hasPermission(msg.sender, Actions.Vote),
            "Only addresses with vote permission can register a call for vote"
        );

        // If the sender has previously created a call for vote that hasn't been resolved yet,
        // a second call for vote can't be registered. Prevents a denial of service attack, where
        // a minority of voters could flood the call for vote queue.
        require(
            lastRegisteredCallForVote[msg.sender] <= resolvedCallsForVote,
            "Only one active call for vote per address is allowed"
        );

        totalCallsForVote++;

        lastRegisteredCallForVote[msg.sender] = totalCallsForVote;

        callsForVote[totalCallsForVote] = CallForVote({
            subject: subject,
            permissions: Permissions({
                canVote: canVote,
                canConfigure: canConfigure,
                canSetOwnerAddress: canSetOwnerAddress,
                canTriggerOwnerWithdraw: canTriggerOwnerWithdraw,
                canManageDeaths: canManageDeaths,
                canStopPayouts: canStopPayouts,
                canBootstrap: false
            }),
            yeas: 0,
            nays: 0
        });

        emit CallForVoteRegistered(
            totalCallsForVote,
            msg.sender,
            subject,
            canVote,
            canConfigure,
            canSetOwnerAddress,
            canTriggerOwnerWithdraw,
            canManageDeaths,
            canStopPayouts
        );
    }

    /**
     * @dev Registers a vote
     * @param callForVoteIndex Call for vote index
     * @param yeaOrNay True to vote yea, false to vote nay
     *
     * Requirements:
     * - unresolved call for vote must exist
     * - call for vote index must match the current active call for vote
     * - the caller must have the vote permission
     */
    function vote(uint64 callForVoteIndex, bool yeaOrNay) external {
        require(hasUnresolvedCallForVote(), "No unresolved call for vote exists");
        require(
            callForVoteIndex == _getCurrenCallForVoteIndex(),
            "Call for vote does not exist or is not active"
        );
        require(
            hasPermission(msg.sender, Actions.Vote),
            "Sender address does not have vote permission"
        );

        uint128 yeas = callsForVote[callForVoteIndex].yeas;
        uint128 nays = callsForVote[callForVoteIndex].nays;

        // If the voter has already voted in this call for vote, undo the last vote
        if (votes[msg.sender].callForVoteIndex == callForVoteIndex) {
            if (votes[msg.sender].yeaOrNay) {
                yeas -= 1;
            } else {
                nays -= 1;
            }
        }

        if (yeaOrNay) {
            yeas += 1;
        } else {
            nays += 1;
        }

        emit VoteCasted(callForVoteIndex, msg.sender, yeaOrNay, totalVoters, yeas, nays);

        if (yeas == (totalVoters / 2 + 1) || nays == (totalVoters - totalVoters / 2)) {

            if (yeas > nays) {
                _setPermissions(
                    callsForVote[callForVoteIndex].subject,
                    callsForVote[callForVoteIndex].permissions
                );
            }

            resolvedCallsForVote += 1;

            // Cleaning up what we can
            delete callsForVote[callForVoteIndex];
            delete votes[msg.sender];

            emit CallForVoteResolved(callForVoteIndex, yeas, nays);

            return;
        }

        votes[msg.sender] = Vote({
            callForVoteIndex: callForVoteIndex,
            yeaOrNay: yeaOrNay
        });

        callsForVote[callForVoteIndex].yeas = yeas;
        callsForVote[callForVoteIndex].nays = nays;
    }

    /**
     * @dev Returns information about the current unresolved call for vote
     * @return callForVoteIndex Call for vote index (1-based)
     * @return yeas Total yea votes
     * @return nays Total nay votes
     *
     * Requirements:
     * - Unresolved call for vote must exist
     */
    function getCurrentCallForVote() public view returns (
        uint64 callForVoteIndex,
        uint128 yeas,
        uint128 nays
    ) {
        require(hasUnresolvedCallForVote(), "No unresolved call for vote exists");
        uint64 index = _getCurrenCallForVoteIndex();
        return (index, callsForVote[index].yeas, callsForVote[index].nays);
    }

    /**
     * @dev Checks if there is an unresolved call for vote
     * @return True if an unresolved call for vote exists
     */
    function hasUnresolvedCallForVote() public view returns (bool) {
        return totalCallsForVote > resolvedCallsForVote;
    }

    /**
     * @dev Returns current call for vote index
     * @return Call for vote index (1-based)
     *
     * Doesn't check if an unresolved call for vote exists, hasUnresolvedCallForVote should be used
     * before using the index that this method returns.
     */
    function _getCurrenCallForVoteIndex() private view returns (uint64) {
        return resolvedCallsForVote + 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Governed.sol';
import './OwnerBalanceContributor.sol';
import './Macabris.sol';
import './Reaper.sol';

/**
 * @title Contract tracking payouts to token owners according to predefined schedule
 *
 * Payout schedule is dived into intervalCount intervals of intervalLength durations, starting at
 * startTime timestamp. After each interval, part of the payouts pool is distributed to the owners
 * of the tokens that are still alive. After the whole payout schedule is completed, all the funds
 * in the payout pool will have been distributed.
 *
 * There is a possibility of the payout schedule being stopped early. In that case, all of the
 * remaining funds will be distributed to the owners of the tokens that were alive at the time of
 * the payout schedule stop.
 */
contract Bank is Governed, OwnerBalanceContributor {

    // Macabris NFT contract
    Macabris public macabris;

    // Reaper contract
    Reaper public reaper;

    // Stores active token count change and deposits for an interval
    struct IntervalActivity {
        int128 activeTokenChange;
        uint128 deposits;
    }

    // Stores aggregate interval information
    struct IntervalTotals {
        uint index;
        uint deposits;
        uint payouts;
        uint accountPayouts;
        uint activeTokens;
        uint accountActiveTokens;
    }

    // The same as IntervalTotals, but a packed version to keep in the lastWithdrawTotals map.
    // Packed versions costs less to store, but the math is then more expensive duo to type
    // conversions, so the interval data is packed just before storing, and unpacked after loading.
    struct IntervalTotalsPacked {
        uint128 deposits;
        uint128 payouts;
        uint128 accountPayouts;
        uint48 activeTokens;
        uint48 accountActiveTokens;
        uint32 index;
    }

    // Timestamp of when the first interval starts
    uint64 public immutable startTime;

    // Timestamp of the moment the payouts have been stopped and the bank contents distributed.
    // This should remain 0, if the payout schedule is never stopped manually.
    uint64 public stopTime;

    // Total number of intervals
    uint64 public immutable intervalCount;

    // Interval length in seconds
    uint64 public immutable intervalLength;

    // Activity for each interval
    mapping(uint => IntervalActivity) private intervals;

    // Active token change for every interval for every address individually
    mapping(uint => mapping(address => int)) private individualIntervals;

    // Total withdrawn amount fo each address
    mapping(address => uint) private withdrawals;

    // Totals of the interval before the last withdrawal of an address
    mapping(address => IntervalTotalsPacked) private lastWithdrawTotals;

    /**
     * @param _startTime First interval start unix timestamp
     * @param _intervalCount Interval count
     * @param _intervalLength Interval length in seconds
     * @param governanceAddress Address of the Governance contract
     * @param ownerBalanceAddress Address of the OwnerBalance contract
     *
     * Requirements:
     * - interval length must be at least one second (but should be more like a month)
     * - interval count must be bigger than zero
     * - Governance contract must be deployed at the given address
     * - OwnerBalance contract must be deployed at the given address
     */
    constructor(
        uint64 _startTime,
        uint64 _intervalCount,
        uint64 _intervalLength,
        address governanceAddress,
        address ownerBalanceAddress
    ) Governed(governanceAddress) OwnerBalanceContributor(ownerBalanceAddress) {
        require(_intervalLength > 0, "Interval length can't be zero");
        require(_intervalCount > 0, "At least one interval is required");

        startTime = _startTime;
        intervalCount = _intervalCount;
        intervalLength = _intervalLength;
    }

    /**
     * @dev Sets Macabris NFT contract address
     * @param macabrisAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Macabris contract must be deployed at the given address
     */
    function setMacabrisAddress(address macabrisAddress) external canBootstrap(msg.sender) {
        macabris = Macabris(macabrisAddress);
    }

    /**
     * @dev Sets Reaper contract address
     * @param reaperAddress Address of Reaper contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Reaper contract must be deployed at the given address
     */
    function setReaperAddress(address reaperAddress) external canBootstrap(msg.sender) {
        reaper = Reaper(reaperAddress);
    }

    /**
     * @dev Stops payouts, distributes remaining funds among alive tokens
     *
     * Requirements:
     * - the caller must have the stop payments permission
     * - the payout schedule must not have been stopped previously
     * - the payout schedule should not be completed
     */
    function stopPayouts() external canStopPayouts(msg.sender) {
        require(stopTime == 0, "Payouts are already stopped");
        require(block.timestamp < getEndTime(), "Payout schedule is already completed");
        stopTime = uint64(block.timestamp);
    }

    /**
     * @dev Checks if the payouts are finished or have been stopped manually
     * @return True if finished or stopped
     */
    function hasEnded() public view returns (bool) {
        return stopTime > 0 || block.timestamp >= getEndTime();
    }

    /**
     * @dev Returns timestamp of the first second after the last interval
     * @return Unix timestamp
     */
    function getEndTime() public view returns(uint) {
        return _getIntervalStartTime(intervalCount);
    }

    /**
     * @dev Returns a timestamp of the first second of the given interval
     * @return Unix timestamp
     *
     * Doesn't make any bound checks for the given interval!
     */
    function _getIntervalStartTime(uint interval) private view returns(uint) {
        return startTime + interval * intervalLength;
    }

    /**
     * @dev Returns start time of the upcoming interval
     * @return Unix timestamp
     */
    function getNextIntervalStartTime() public view returns (uint) {

        // If the payouts were ended manually, there will be no next interval
        if (stopTime > 0) {
            return 0;
        }

        // Returns first intervals start time if the payout schedule hasn't started yet
        if (block.timestamp < startTime) {
            return startTime;
        }

        uint currentInterval = _getInterval(block.timestamp);

        // There will be no intervals after the last one, return 0
        if (currentInterval >= (intervalCount - 1)) {
            return 0;
        }

        // Returns next interval's start time otherwise
        return _getIntervalStartTime(currentInterval + 1);
    }

    /**
     * @dev Deposits ether to the common payout pool
     */
    function deposit() external payable {

        // If the payouts have ended, we don't need to track deposits anymore, everything goes to
        // the owner's balance
        if (hasEnded()) {
            _transferToOwnerBalance(msg.value);
            return;
        }

        require(msg.value <= type(uint128).max, "Deposits bigger than uint128 max value are not allowed!");
        uint currentInterval = _getInterval(block.timestamp);
        intervals[currentInterval].deposits += uint128(msg.value);
    }

    /**
     * @dev Registers token transfer, minting and burning
     * @param tokenId Token ID
     * @param from Previous token owner, zero if this is a freshly minted token
     * @param to New token owner, zero if the token is being burned
     *
     * Requirements:
     * - the caller must be the Macabris contract
     */
    function onTokenTransfer(uint tokenId, address from, address to) external {
        require(msg.sender == address(macabris), "Caller must be the Macabris contract");

        // If the payouts have ended, we don't need to track transfers anymore
        if (hasEnded()) {
            return;
        }

        // If token is already dead, nothing changes in terms of payouts
        if (reaper.getTimeOfDeath(tokenId) != 0) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);

        if (from == address(0)) {
            // If the token is freshly minted, increase the total active token count for the period
            intervals[currentInterval].activeTokenChange += 1;
        } else {
            // If the token is transfered, decrease the previous ownner's total for the current interval
            individualIntervals[currentInterval][from] -= 1;
        }

        if (to == address(0)) {
            // If the token is burned, decrease the total active token count for the period
            intervals[currentInterval].activeTokenChange -= 1;
        } else {
            // If the token is transfered, add it to the receiver's total for the current interval
            individualIntervals[currentInterval][to] += 1;
        }
    }

    /**
     * @dev Registers token death
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must be the Reaper contract
     */
    function onTokenDeath(uint tokenId) external {
        require(msg.sender == address(reaper), "Caller must be the Reaper contract");

        // If the payouts have ended, we don't need to track deaths anymore
        if (hasEnded()) {
            return;
        }

        // If the token isn't minted yet, we don't care about it
        if (!macabris.exists(tokenId)) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);
        address owner = macabris.ownerOf(tokenId);

        intervals[currentInterval].activeTokenChange -= 1;
        individualIntervals[currentInterval][owner] -= 1;
    }

    /**
     * @dev Registers token resurrection
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must be the Reaper contract
     */
    function onTokenResurrection(uint tokenId) external {
        require(msg.sender == address(reaper), "Caller must be the Reaper contract");

        // If the payouts have ended, we don't need to track deaths anymore
        if (hasEnded()) {
            return;
        }

        // If the token isn't minted yet, we don't care about it
        if (!macabris.exists(tokenId)) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);
        address owner = macabris.ownerOf(tokenId);

        intervals[currentInterval].activeTokenChange += 1;
        individualIntervals[currentInterval][owner] += 1;
    }

    /**
     * Returns current interval index
     * @return Interval index (0 for the first interval, intervalCount-1 for the last)
     *
     * Notes:
     * - Returns zero (first interval), if the first interval hasn't started yet
     * - Returns the interval at the stop time, if the payouts have been stopped
     * - Returns "virtual" interval after the last one, if the payout schedule is completed
     */
    function _getCurrentInterval() private view returns(uint) {

        // If the payouts have been stopped, return interval after the stopped one
        if (stopTime > 0) {
            return _getInterval(stopTime);
        }

        uint intervalIndex = _getInterval(block.timestamp);

        // Return "virtual" interval that would come after the last one, if payout schedule is completed
        if (intervalIndex > intervalCount) {
            return intervalCount;
        }

        return intervalIndex;
    }

    /**
     * Returns interval index for the given timestamp
     * @return Interval index (0 for the first interval, intervalCount-1 for the last)
     *
     * Notes:
     * - Returns zero (first interval), if the first interval hasn't started yet
     * - Returns non-exitent interval index, if the timestamp is after the end time
     */
    function _getInterval(uint timestamp) private view returns(uint) {

        // Time before the payout schedule start is considered to be a part of the first interval
        if (timestamp < startTime) {
            return 0;
        }

        return (timestamp - startTime) / intervalLength;
    }

    /**
     * @dev Returns total pool value (deposits - payouts) for the current interval
     * @return Current pool value in wei
     */
    function getPoolValue() public view returns (uint) {

        // If all the payouts are done, pool is empty. In reality, there might something left due to
        // last interval pool not dividing equaly between the remaining alive tokens, or if there
        // are no alive tokens during the last interval.
        if (hasEnded()) {
            return 0;
        }

        uint currentInterval = _getInterval(block.timestamp);
        IntervalTotals memory totals = _getIntervalTotals(currentInterval, address(0));

        return totals.deposits - totals.payouts;
    }

    /**
     * @dev Returns provisional next payout value per active token of the current interval
     * @return Payout in wei, zero if no active tokens exist or all payouts are done
     */
    function getNextPayout() external view returns (uint) {

        // There is no next payout if the payout schedule has run its course
        if (hasEnded()) {
            return 0;
        }

        uint currentInterval = _getInterval(block.timestamp);
        IntervalTotals memory totals = _getIntervalTotals(currentInterval, address(0));

        return _getPayoutPerToken(totals);
    }

    /**
     * @dev Returns payout amount per token for the given interval
     * @param totals Interval totals
     * @return Payout value in wei
     *
     * Notes:
     * - Returns zero for the "virtual" interval after the payout schedule end
     * - Returns zero if no active tokens exists for the interval
     */
    function _getPayoutPerToken(IntervalTotals memory totals) private view returns (uint) {
        // If we're calculating next payout for the "virtual" interval after the last one,
        // or if there are no active tokens, we would be dividing the pool by zero
        if (totals.activeTokens > 0 && totals.index < intervalCount) {
            return (totals.deposits - totals.payouts) / (intervalCount - totals.index) / totals.activeTokens;
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns the sum of all payouts made up until this interval
     * @return Payouts total in wei
     */
    function getPayoutsTotal() external view returns (uint) {
        uint interval = _getCurrentInterval();
        IntervalTotals memory totals = _getIntervalTotals(interval, address(0));
        uint payouts = totals.payouts;

        // If the payout schedule has been stopped prematurely, all deposits are distributed.
        // If there are no active tokens, the remainder of the pool is never distributed.
        if (stopTime > 0 && totals.activeTokens > 0) {

            // Remaining pool might not divide equally between the active tokens, calculating
            // distributed amount without the remainder
            payouts += (totals.deposits - totals.payouts) / totals.activeTokens * totals.activeTokens;
        }

        return payouts;
    }

    /**
     * @dev Returns the sum of payouts for a particular account
     * @param account Account address
     * @return Payouts total in wei
     */
    function getAccountPayouts(address account) public view returns (uint) {
        uint interval = _getCurrentInterval();
        IntervalTotals memory totals = _getIntervalTotals(interval, account);
        uint accountPayouts = totals.accountPayouts;

        // If the payout schedule has been stopped prematurely, all deposits are distributed.
        // If there are no active tokens, the remainder of the pool is never distributed.
        if (stopTime > 0 && totals.activeTokens > 0) {
            accountPayouts += (totals.deposits - totals.payouts) / totals.activeTokens * totals.accountActiveTokens;
        }

        return accountPayouts;
    }

    /**
     * @dev Returns amount available for withdrawal
     * @param account Address to return balance for
     * @return Amount int wei
     */
    function getBalance(address account) public view returns (uint) {
        return getAccountPayouts(account) - withdrawals[account];
    }

    /**
     * @dev Withdraws all available amount
     * @param account Address to withdraw for
     *
     * Note that this method can be called by any address.
     */
    function withdraw(address payable account) external {

        uint interval = _getCurrentInterval();

        // Persists last finished interval totals to avoid having to recalculate them from the
        // deltas during the next withdrawal. Totals of the first interval should never be saved
        // to the lastWithdrawTotals map (see _getIntervalTotals for explanation).
        if (interval > 1) {
            IntervalTotals memory totals = _getIntervalTotals(interval - 1, account);

            // Converting the totals struct to a packed version before saving to storage to save gas
            lastWithdrawTotals[account] = IntervalTotalsPacked({
                deposits: uint128(totals.deposits),
                payouts: uint128(totals.payouts),
                accountPayouts: uint128(totals.accountPayouts),
                activeTokens: uint48(totals.activeTokens),
                accountActiveTokens: uint48(totals.accountActiveTokens),
                index: uint32(totals.index)
            });
        }

        uint balance = getBalance(account);
        withdrawals[account] += balance;
        account.transfer(balance);
    }

    /**
     * @dev Aggregates active token and deposit change history until the given interval
     * @param intervalIndex Interval
     * @param account Account for account-specific aggregate values
     * @return Aggregate values for the interval
     */
    function _getIntervalTotals(uint intervalIndex, address account) private view returns (IntervalTotals memory) {

        IntervalTotalsPacked storage packed = lastWithdrawTotals[account];

        // Converting packed totals struct back to unpacked one, to avoid having to do type
        // conversions in the loop below.
        IntervalTotals memory totals = IntervalTotals({
            index: packed.index,
            deposits: packed.deposits,
            payouts: packed.payouts,
            accountPayouts: packed.accountPayouts,
            activeTokens: packed.activeTokens,
            accountActiveTokens: packed.accountActiveTokens
        });

        uint prevPayout;
        uint prevAccountPayout;
        uint prevPayoutPerToken;

        // If we don't have previous totals, we need to start from intervalIndex 0 to apply the
        // active token and deposit changes of the first interval. If we have previous totals, they
        // the include all the activity of the interval already, so we start from the next one.
        //
        // Note that it's assumed all the interval total values will be 0, if the totals.index is 0.
        // This means that the totals of the first interval should never be saved to the
        // lastWithdrawTotals maps otherwise the deposits and active token changes will be counted twice.
        for (uint i = totals.index > 0 ? totals.index + 1 : 0; i <= intervalIndex; i++) {

            // Calculating payouts for the last interval data. If this is the first interval and
            // there was no previous interval totals, all these values will resolve to 0.
            prevPayoutPerToken = _getPayoutPerToken(totals);
            prevPayout = prevPayoutPerToken * totals.activeTokens;
            prevAccountPayout = totals.accountActiveTokens * prevPayoutPerToken;

            // Updating totals to represent the current interval by adding the payouts of the last
            // interval and applying changes in active token count and deposits
            totals.index = i;
            totals.payouts += prevPayout;
            totals.accountPayouts += prevAccountPayout;

            IntervalActivity storage interval = intervals[i];
            totals.deposits += interval.deposits;

            // Even though the token change value might be negative, the sum of all the changes
            // will never be negative because of the implicit contrains of the contracts (e.g. token
            // can't be transfered from an address that does not own it, or already dead token can't
            // be marked dead again). Therefore it's safe to convert the result into unsigned value,
            // after doing sum of signed values.
            totals.activeTokens = uint(int(totals.activeTokens) + interval.activeTokenChange);
            totals.accountActiveTokens = uint(int(totals.accountActiveTokens) + individualIntervals[i][account]);
        }

        return totals;
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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
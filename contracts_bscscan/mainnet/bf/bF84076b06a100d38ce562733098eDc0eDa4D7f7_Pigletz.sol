// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IPigletz.sol";
import "./PigletWallet.sol";
import "../token/PiFiToken.sol";
import "../boosters/IBooster.sol";
import "../boosters/InvestTokensBooster.sol";
import "../boosters/InvestMultiTokensBooster.sol";
import "../boosters/CollectSameSignsBooster.sol";
import "../boosters/CollectSignsBooster.sol";
import "../boosters/CollectNumberBooster.sol";
import "../boosters/InvestMultiTokensBooster.sol";
import "../boosters/StakingBooster.sol";
import "../boosters/SpecialBooster.sol";
import "../oracle/IOracle.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Pigletz is IPigletz, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for bytes32;
    using Clones for address;

    uint256 constant PIPS = 10000;

    uint256 public constant SEED = 1638504306;

    uint256 constant LEVEL_2_REQUIREMENTS = 10000 ether;
    uint256 constant LEVEL_3_REQUIREMENTS = 55000 ether;

    uint256 constant MAX_MINT_PER_PIG = 2000000 ether;

    string[] IPFS_FOLDERS = [
        "QmUoYfWQCAkjw2oNvbXikEZC24Kg5oLkw4Fef49thyexmq",
        "Qmb3bJAtH9x8N5D5MkDaXGSTKooyDNpoihuZzR7sEsgRp3",
        "QmPAoRPzkkXwXJ34EaFGQmRUY3F8W4p3gnyhn9ga56QFc6",
        "QmaErGy2B71Jsn7aaCnbrChoSiWDR32KezrNEwHgZASmnz"
    ];
    //@todo: WE NEED THE REAL CELEBRITY FOLDER
    string CELEBRITY_FOLDER = "QmPLLwf4miKgFnxwgrp8uq4z9FnaNV6rTvR5MmrRHR2GFi";

    uint256 _regularTokens;
    uint256 _celebrityTokens;

    // @todo Add a better documentation for this
    uint256[] _mintingRatePerDay = [167 ether, 250 ether, 417 ether, 500 ether];

    uint256 constant MAX_TOKENS = 12345;
    uint256 internal nonce = 0;
    uint256[MAX_TOKENS] internal _indexes;
    mapping(uint256 => uint8) private _levels;
    mapping(uint256 => IPigletWallet) private _wallets;
    mapping(uint256 => uint256) private _mintedAmount;
    mapping(uint256 => uint256) private _lastMintTime;

    IBooster[] private _boosters;
    IOracle _oracle;
    PiFiToken _token;
    address _staker;
    address _portal;
    uint256 _numRegularMinted;
    uint256 _numCelebrityMinted;
    mapping(uint256 => bool) _special;
    SpecialBooster _specialBooster;
    mapping(address => bool) _minters;

    PigletWallet _walletLibrary;

    constructor(
        IOracle oracle,
        PiFiToken token,
        uint256 regularTokens,
        uint256 celebrityTokens
    ) ERC721("Pigletz", "PIGZ") {
        _boosters = [
            IBooster(new InvestTokensBooster(this, 1000, 100 ether, 1)), // Invest 100
            new InvestTokensBooster(this, 3000, 500 ether, 2), // Invest 500
            new InvestTokensBooster(this, 10000, 2000 ether, 3), // Invest 2000
            new CollectNumberBooster(this, 2000, 3, 1), // Collect 3
            new CollectNumberBooster(this, 3000, 7, 2), // Collect 7
            new InvestMultiTokensBooster(this, oracle, address(token), 1000, 3, 1), // Invest 3
            new InvestMultiTokensBooster(this, oracle, address(token), 2000, 7, 3), // Invest 7
            new CollectSameSignsBooster(this, 3000, 3, 1), // Collect 3 same
            new CollectSignsBooster(this, 8000, 12, 3), // Collect 12 different
            new StakingBooster(this, 5000), // Stake Booster
            new SpecialBooster(this, 5000) // Special Booster
        ];
        _oracle = oracle;
        _token = token;
        _regularTokens = regularTokens;

        _celebrityTokens = celebrityTokens;
        _walletLibrary = new PigletWallet();
    }

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minters can mint");
        _;
    }
    modifier validToken(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    modifier onlyPortal() {
        require(msg.sender == _portal, "Only portal can do this");
        require(_portal != address(0), "Portal is not set");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only token owner can do this");
        _;
    }

    function maxSupply() public view override returns (uint256) {
        return _regularTokens + _celebrityTokens;
    }

    function _checkSaleEnded() internal {
        if (tokenCount() >= maxSupply()) {
            emit SaleEnded(maxSupply(), address(this).balance);
        }
    }

    function tokenCount() public view override returns (uint256) {
        return _numRegularMinted + _numCelebrityMinted;
    }

    function _randomIndex() internal returns (uint256) {
        uint256 totalSize = _regularTokens - _numRegularMinted;

        uint256 index = uint256(
            keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, blockhash(block.number)))
        ) % totalSize;
        uint256 value = 0;
        if (_indexes[index] != 0) {
            value = _indexes[index];
        } else {
            value = index;
        }

        if (_indexes[totalSize - 1] == 0) {
            _indexes[index] = totalSize - 1;
        } else {
            _indexes[index] = _indexes[totalSize - 1];
        }
        nonce++;
        return value.add(1);
    }

    function getSign(uint256 tokenId) public pure override returns (ZodiacSign) {
        bytes32 signHash = keccak256(abi.encode(SEED, tokenId));
        return ZodiacSign(uint256(signHash) % 12);
    }

    function _isSpecial(uint256 probability) internal view returns (bool) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(_numRegularMinted, msg.sender, block.difficulty, blockhash(block.number)))
        ) % PIPS;
        return random < probability;
    }

    function mint(
        address to,
        uint256 amount,
        uint256 probability
    ) external override onlyMinter {
        require(amount + _numRegularMinted <= _regularTokens, "Not enough tokens left");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _randomIndex();

            _numRegularMinted++;

            _createPiglet(to, tokenId, 1, _isSpecial(probability));
        }
        _checkSaleEnded();
    }

    function isCelebrity(uint256 tokenId) public view override returns (bool) {
        return tokenId > _regularTokens;
    }

    function _createWallet(uint256 tokenId) internal returns (IPigletWallet) {
        address clone = Clones.cloneDeterministic(address(_walletLibrary), bytes32(tokenId));
        IPigletWallet(clone).init(_oracle);
        return IPigletWallet(clone);
    }

    function _createPiglet(
        address to,
        uint256 tokenId,
        uint8 level,
        bool special
    ) internal {
        _mint(to, tokenId);
        IPigletWallet wallet = _createWallet(tokenId);
        _wallets[tokenId] = wallet;
        _levels[tokenId] = level;
        _lastMintTime[tokenId] = block.timestamp;
        _special[tokenId] = special;
    }

    function mintCelebrities(address to) external override onlyMinter {
        for (uint256 i = 0; i < _celebrityTokens; i++) {
            uint256 tokenId = _regularTokens + i + 1;

            _createPiglet(to, tokenId, 3, true);
            _numCelebrityMinted++;
        }

        _checkSaleEnded();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId) public view override validToken(tokenId) returns (string memory uri) {
        if (isCelebrity(tokenId)) {
            return string(abi.encodePacked(_baseURI(), CELEBRITY_FOLDER, "/", Strings.toString(tokenId)));
        }

        bytes32 jsonHash = keccak256(abi.encode(SEED, tokenId, getLevel(tokenId), getSign(tokenId)));

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    IPFS_FOLDERS[getLevel(tokenId) - 1],
                    "/",
                    Strings.toHexString(uint256(jsonHash), 32)
                )
            );
    }

    function _getTokenBalance(uint256 tokenId) internal view validToken(tokenId) returns (uint256) {
        uint256 balance = _token.balanceOf(address(getWallet(tokenId)));
        balance += _getUnmintedTokens(tokenId);
        return balance;
    }

    function getTotalBoost(uint256 tokenId) public view validToken(tokenId) returns (uint256) {
        uint256 percentage = 0;
        for (uint256 i = 0; i < _boosters.length; i++) {
            if (_boosters[i].isBoosted(tokenId)) {
                percentage += _boosters[i].getBoost();
            }
        }
        return percentage;
    }

    function getDailyMintingAmount(uint256 tokenId) public view validToken(tokenId) returns (uint256) {
        uint8 level = getLevel(tokenId);
        uint256 mintingRatePerDay = _mintingRatePerDay[level - 1];
        uint256 mintingAmount = mintingRatePerDay;
        mintingAmount += ((mintingAmount * getTotalBoost(tokenId)) / PIPS);
        return mintingAmount;
    }

    function _getUnmintedTokens(uint256 tokenId) private view returns (uint256) {
        uint256 lastMintTime = _lastMintTime[tokenId];
        uint256 daysMinting = (block.timestamp - lastMintTime) / 24 hours;
        uint256 balance = getDailyMintingAmount(tokenId) * daysMinting;

        return Math.min(balance, MAX_MINT_PER_PIG - _mintedAmount[tokenId]);
    }

    function getEligibleLevel(uint256 tokenId) public view returns (uint8) {
        uint256 balance = _getTokenBalance(tokenId);

        if (balance >= LEVEL_3_REQUIREMENTS) {
            return 3;
        }

        if (balance >= LEVEL_2_REQUIREMENTS) {
            return 2;
        }
        return 1;
    }

    function updatePiFiBalance(uint256 tokenId) external override {
        _mintPiFi(tokenId);
    }

    function _mintPiFi(uint256 tokenId) internal {
        uint256 tokensToMint = _getUnmintedTokens(tokenId);
        if (tokensToMint > 0) {
            IPigletWallet wallet = getWallet(tokenId);
            _token.mint(address(wallet), tokensToMint);
            _mintedAmount[tokenId] += tokensToMint;

            wallet.registerDeposit(address(_token));

            _lastMintTime[tokenId] = block.timestamp;
        }
    }

    function levelUp(uint256 tokenId) external validToken(tokenId) onlyTokenOwner(tokenId) {
        uint8 level = getLevel(tokenId);
        uint8 eligibleLevel = getEligibleLevel(tokenId);

        if (level >= eligibleLevel) {
            return;
        }

        _mintPiFi(tokenId);

        _levels[tokenId] = eligibleLevel;

        emit LevelUp(tokenId, eligibleLevel, msg.sender);
    }

    function getLevel(uint256 tokenId) public view override validToken(tokenId) returns (uint8) {
        return _levels[tokenId];
    }

    function getWallet(uint256 tokenId) public view override validToken(tokenId) returns (IPigletWallet) {
        return _wallets[tokenId];
    }

    function getBoosters() external view returns (IBooster[] memory) {
        return _boosters;
    }

    function getBoosterStatuses(uint256 tokenId) external view returns (IBooster.Status[] memory) {
        IBooster.Status[] memory statuses = new IBooster.Status[](_boosters.length);
        for (uint256 i = 0; i < _boosters.length; i++) {
            statuses[i] = _boosters[i].getStatus(tokenId);
        }
        return statuses;
    }

    function burn(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) {
        require(getLevel(tokenId) > 1, "Cannot burn level 1 piglets");

        _mintPiFi(tokenId);

        getWallet(tokenId).destroy(msg.sender);

        _burn(tokenId);
    }

    //todo: set staker and portal as approved for all tokens?
    function setStaker(address staker) external override onlyOwner {
        require(_staker == address(0), "Staker already set");
        _staker = staker;
    }

    function setMetaversePortal(address portal) external override onlyOwner {
        require(_portal == address(0), "Portal already set");
        _portal = portal;
    }

    function getMetaversePortal() public view override returns (address) {
        return _portal;
    }

    function materialize(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) onlyPortal {
        require(getLevel(tokenId) == 3, "Can materialize only level 3 piglets");

        _mintPiFi(tokenId);

        _levels[tokenId] = 4;

        emit Materialized(tokenId);
    }

    function digitalize(uint256 tokenId) external override validToken(tokenId) onlyTokenOwner(tokenId) onlyPortal {
        require(getLevel(tokenId) == 4, "Can digitalize only level 4 piglets");

        _mintPiFi(tokenId);

        _levels[tokenId] = 3;

        emit Digitalized(tokenId);
    }

    function getStaker() external view override returns (address) {
        return _staker;
    }

    function isSpecial(uint256 tokenId) external view override validToken(tokenId) returns (bool) {
        return _special[tokenId] || isCelebrity(tokenId);
    }

    function getPiFiBalance(uint256 tokenId) public view validToken(tokenId) returns (uint256, uint256) {
        uint256 pifiBalance = _getTokenBalance(tokenId);
        uint256 pifiBalanceInUSD = _oracle.getTokenUSDPrice(address(_token), pifiBalance);
        return (pifiBalance, pifiBalanceInUSD);
    }

    function _createTokenData(address token, uint256 balance) private view returns (TokenData memory) {
        return TokenData(token, balance, _oracle.getTokenUSDPrice(token, balance));
    }

    function getInvestments(uint256 tokenId) external view returns (TokenData[] memory) {
        IPigletWallet wallet = getWallet(tokenId);
        IPigletWallet.TokenData[] memory investedTokens = wallet.listTokens();
        uint256 size = investedTokens.length + 1;
        if (address(wallet).balance > 0) {
            size++;
        }

        uint256 index = 0;
        TokenData[] memory prices = new TokenData[](size);
        prices[index] = _createTokenData(address(_token), _getTokenBalance(tokenId));
        for (uint256 i = 0; i < investedTokens.length; i++) {
            // making sure not to count PiFis deposited in the wallet twice
            if (investedTokens[i].token != address(_token)) {
                index++;
                prices[index] = _createTokenData(investedTokens[i].token, investedTokens[i].balance);
            }
        }

        if (address(wallet).balance > 0) {
            index++;
            prices[index].token = address(0);
            prices[index].balance = address(wallet).balance;
            prices[index].balanceInUSD = _oracle.getNativeTokenPrice(address(wallet).balance);
        }

        //trimming the size of the token if there were duplicated tokens
        if (index != size - 1) {
            TokenData[] memory temp = new TokenData[](index + 1);
            for (uint256 i = 0; i <= index; i++) {
                temp[i] = prices[i];
            }
            prices = temp;
        }
        return prices;
    }

    function getPigletData(uint256 tokenId) public view validToken(tokenId) returns (PigletData memory) {
        (uint256 pifiBalance, uint256 pifiBalanceInUSD) = getPiFiBalance(tokenId);
        PigletData memory data = PigletData(
            tokenURI(tokenId),
            tokenId,
            getLevel(tokenId),
            getEligibleLevel(tokenId),
            pifiBalance,
            getWallet(tokenId).getBalanceInUSD() + pifiBalanceInUSD,
            getDailyMintingAmount(tokenId),
            getTotalBoost(tokenId),
            getWallet(tokenId)
        );
        return data;
    }

    function pigletzByOwner(
        address pigletzOwner,
        uint256 start,
        uint256 limit
    ) external view returns (PigletData[] memory) {
        uint256 total = balanceOf(pigletzOwner);
        require(start <= total, "Start index must be less than or equal to total pigletz");
        uint256 end = start + limit;

        if (start == 0 && limit == 0) {
            end = total;
        }
        uint256 size = Math.min(total, end) - start;
        PigletData[] memory pigletz = new PigletData[](size);
        for (uint256 i = start; i < start + size; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(pigletzOwner, i);
            pigletz[i - start] = getPigletData(tokenId);
        }
        return pigletz;
    }

    function registerDeposit(uint256 tokenId, address token) public validToken(tokenId) onlyTokenOwner(tokenId) {
        IPigletWallet wallet = getWallet(tokenId);
        wallet.registerDeposit(token);
    }

    function deposit(
        uint256 tokenId,
        address sender,
        address token,
        uint256 amount
    ) public validToken(tokenId) onlyTokenOwner(tokenId) {
        IPigletWallet wallet = getWallet(tokenId);
        wallet.deposit(token, sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IPigletWallet.sol";
import "../boosters/IBooster.sol";

interface IPigletz is IERC721Enumerable {
    enum ZodiacSign {
        Aries,
        Taurus,
        Gemini,
        Cancer,
        Leo,
        Virgo,
        Libra,
        Scorpio,
        Sagittarius,
        Capricorn,
        Aquarius,
        Pisces
    }
    struct TokenData {
        address token;
        uint256 balance;
        uint256 balanceInUSD;
    }

    struct PigletData {
        string uri;
        uint256 tokenId;
        uint8 level;
        uint8 eligibleLevel;
        uint256 pifiBalance;
        uint256 totalValue;
        uint256 dailyMintingRate;
        uint256 boost;
        IPigletWallet wallet;
    }

    event SaleEnded(uint256 totalSold, uint256 totalRevenue);

    event LevelUp(uint256 indexed tokenId, uint8 indexed level, address indexed owner);

    event Materialized(uint256 indexed tokenId);

    event Digitalized(uint256 indexed tokenId);

    function updatePiFiBalance(uint256 tokenId) external;

    function setStaker(address staker) external;

    function setMetaversePortal(address portal) external;

    function materialize(uint256 tokenId) external;

    function digitalize(uint256 tokenId) external;

    function getSign(uint256 tokenId) external view returns (ZodiacSign);

    function getLevel(uint256 tokenId) external view returns (uint8);

    function getWallet(uint256 tokenID) external view returns (IPigletWallet);

    function burn(uint256 tokenId) external;

    function mint(
        address to,
        uint256 amount,
        uint256 probabilityOfSpecial
    ) external;

    function mintCelebrities(address to) external;

    function getStaker() external view returns (address);

   function getMetaversePortal() external view returns (address);

    function maxSupply() external view returns (uint256);

    function tokenCount() external view returns (uint256);

    function isSpecial(uint256 tokenId) external view returns (bool);

    function isCelebrity(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/Denominations.sol";

import "./IPigletWallet.sol";

import "../oracle/IOracle.sol";

contract PigletWallet is Ownable, ReentrancyGuard, IPigletWallet {
    mapping(address => uint256) private _tokenBalances;
    address[] private _tokens;
    IOracle private _oracle;
    bool _initialized = false;

    constructor() {}

    function init(IOracle oracle) public override {
        require(_initialized == false, "Wallet already initialized");
        _transferOwnership(msg.sender);
        _oracle = oracle;
        _initialized = true;
    }

    receive() external payable {}

    function getBalanceInUSD() external view override returns (uint256) {
        uint256 usdBalance = _oracle.getNativeTokenPrice(address(this).balance);

        for (uint256 i = 0; i < _tokens.length; i++) {
            usdBalance += _getTokenUSDPrice(_tokens[i], _tokenBalances[_tokens[i]]);
        }

        return usdBalance;
    }

    function _getTokenUSDPrice(address token, uint256 balance) internal view returns (uint256) {
        try IOracle(_oracle).getTokenUSDPrice(token, balance) returns (uint256 price) {
            if (price > 0) return uint256(price);
        } catch {
            return 0;
        }
        return 0;
    }

    function maxTokenTypes() public pure override returns (uint256) {
        return 10;
    }

    function listTokens() public view override returns (TokenData[] memory) {
        TokenData[] memory list = new TokenData[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            list[i] = TokenData({ token: _tokens[i], balance: _tokenBalances[_tokens[i]] });
        }

        return list;
    }

    function _findTokenIndex(address token) internal view returns (uint256) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) return i;
        }
        return _tokens.length;
    }

    function registerDeposit(address token) external override onlyOwner {
        require(token != address(0), "invalid token");
        require(token != address(this), "cannot register self");
        require(token != address(msg.sender), "cannot register self");
        try IERC20(token).balanceOf(address(this)) returns (uint256 balance) {
            require(balance > 0, "Token must have a balance greater than 0");

            uint256 index = _findTokenIndex(token);
            if (index == _tokens.length) {
                _tokens.push(token);
            }
            require(index < _tokens.length);
            _tokens[index] = token;
            _tokenBalances[token] = balance;

            emit TokenTransfered(token, address(this), balance);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, address(this), "Unable to transfer");
            } else {
                emit TokenTransferError(token, address(this), string(reason));
            }
        }
    }

    function deposit(
        address token,
        address sender,
        uint256 amount
    ) external override onlyOwner returns (bool) {
        require(amount > 0, "Amount to invest has to be non-zero");
        require(listTokens().length < maxTokenTypes(), "Max different token types reached");
        try IERC20(token).transferFrom(sender, address(this), amount) returns (bool result) {
            assert(result == true);

            if (_tokenBalances[token] == 0) {
                _tokens.push(token);
            }
            _tokenBalances[token] += amount;

            emit TokenTransfered(token, address(this), amount);

            return true;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, sender, "Unable to transfer");
            } else {
                emit TokenTransferError(token, sender, string(reason));
            }
        }
        return false;
    }

    function destroy(address recipient) external override onlyOwner nonReentrant {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 balance = _tokenBalances[token];
            _withdrawToken(token, recipient, balance);
        }

        // Transfer ethers if any
        payable(recipient).transfer(address(this).balance);

        emit Destroyed(address(this));
    }

    function _withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) private {
        try IERC20(token).transfer(recipient, amount) returns (bool result) {
            assert(result == true);
            emit TokenTransfered(token, recipient, amount);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                emit TokenTransferError(token, recipient, "Unable to transfer, approving instead");
            } else {
                emit TokenTransferError(token, recipient, string(reason));
            }
            IERC20(token).approve(recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PiFiToken is ERC20Capped, AccessControl {
    uint256 public constant MAX_SUPPLY = 25 * 10**27;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor() ERC20("PiFi Token", "PiFi") ERC20Capped(MAX_SUPPLY) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Restricted to minters.");
        _;
    }

    function mint(address account, uint256 amount) public virtual onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual onlyMinter {
        _burn(account, amount);
    }

    function addMinter(address account) public virtual onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// @todo we will need documentation here
// for examples see OpenZeppelin contracts

interface IBooster {
    enum Status {
        Boosted,
        Ready,
        Locked,
        NotReady
    }

    event Boosted(uint256 indexed tokenId, uint256 boostAmount, uint256 level, bool value);

    function getStatus(uint256 tokenId) external view returns (Status);

    function getName() external view returns (string memory);

    function getBoost() external view returns (uint256);

    function getRequirements() external view returns (string memory description, uint256[] memory values);

    function isReady(uint256 tokenID) external view returns (bool);

    function boost(uint256[] calldata tokenIds) external;

    function unBoost(uint256[] calldata tokens) external;

    function numInCollection() external view returns (uint256);

    function isLocked(uint256 tokenId) external view returns (bool);

    function isBoosted(uint256 tokenId) external view returns (bool);

    function getBoostAmount(uint256 tokenId, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract InvestTokensBooster is Booster {
    uint256 internal _amount;

    constructor(
        IPigletz pigletz,
        uint256 boost,
        uint256 amount,
        uint256 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _amount = amount;
    }

    function getName() external view virtual override returns (string memory) {
        return "Invest Tokens";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _amount;
        return ("Invest tokens with value of at least $${0} USD", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        IPigletWallet wallet = IPigletz(_pigletz).getWallet(tokenId);

        require(address(wallet) != address(0), "Token does not exist");

        return wallet.getBalanceInUSD() >= _amount && !isLocked(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

import "../oracle/IOracle.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

contract InvestMultiTokensBooster is Booster {
    IOracle private _oracle;
    uint256 private _numTokens;
    address _pifiToken;

    constructor(
        IPigletz pigletz,
        IOracle oracle,
        address pifi,
        uint256 boost,
        uint256 numTokens,
        uint256 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _oracle = oracle;
        _numTokens = numTokens;
        _pifiToken = pifi;
    }

    function getName() external view virtual override returns (string memory) {
        return "Invest Multiple Tokens";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numTokens;
        return ("Invest ${0} different tokens", values);
    }

    function _isListed(address token) internal view returns (bool) {
        return _oracle.getTokenUSDPrice(token, 1 ether) > 0;
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        IPigletWallet wallet = IPigletz(_pigletz).getWallet(tokenId);

        require(address(wallet) != address(0), "Token does not exist");
        IPigletWallet.TokenData[] memory tokens = wallet.listTokens();

        uint256 count = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_isListed(tokens[i].token) && tokens[i].token != _pifiToken) count++;
        }
        if (address(wallet).balance > 0) count++;
        return count >= _numTokens && !isLocked(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectSameSignsBooster is Booster {
    uint256 _numWithSameSigns;

    constructor(
        IPigletz pigletz,
        uint256 boostPercentage,
        uint256 numSame,
        uint256 level
    ) Booster(pigletz, boostPercentage, level) {
        _pigletz = pigletz;
        _numWithSameSigns = numSame;
        assert(numSame <= 100);
    }

    function numInCollection() public view virtual override returns (uint256) {
        return _numWithSameSigns;
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Same Signs";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numWithSameSigns;
        return ("Collect ${0} piglets with the same sign", values);
    }

    function _getSign(uint256 tokenId) internal view returns (uint256) {
        return uint256(_pigletz.getSign(tokenId));
    }

    function _isEligible(uint256 id) internal view returns (bool) {
        return !isLocked(id) && !isBoosted(id) && !_pigletz.isCelebrity(id);
    }

    function isLocked(uint256 id) public view override returns (bool) {
        return _pigletz.isCelebrity(id) || super.isLocked(id);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address owner = _pigletz.ownerOf(tokenId);
        uint256 numberOfPiglets = _pigletz.balanceOf(owner);
        uint256[] memory signs = new uint256[](12);
        for (uint256 i = 0; i < numberOfPiglets; i++) {
            uint256 id = _pigletz.tokenOfOwnerByIndex(owner, i);

            if (_isEligible(id)) {
                uint256 sign = _getSign(id);

                signs[uint256(sign)]++;
            }
        }

        return signs[_getSign(tokenId)] >= _numWithSameSigns;
    }

    function _haveSameSign(uint256[] calldata tokens) internal view returns (bool) {
        uint256 sign = uint256(_pigletz.getSign(tokens[0]));
        for (uint256 i = 1; i < tokens.length; i++) {
            if (uint256(_pigletz.getSign(tokens[i])) != sign) {
                return false;
            }
        }
        return true;
    }

    function boost(uint256[] calldata tokens) public virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(_haveNotBeenBoosted(tokens), "Some piglets have already been boosted");
        require(_areNotCelebrity(tokens), "Some piglets are celebrities");
        require(_haveCorrectLevel(tokens), "Some piglets are not of the correct level");
        require(_haveSameSign(tokens), "Some piglets dont have the same sign");

        _setBoosted(tokens, true);

        _updateTokenBalance(tokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectSignsBooster is Booster {
    uint256 _numSigns;

    constructor(
        IPigletz pigletz,
        uint256 boostPercentage,
        uint256 numSigns,
        uint256 level
    ) Booster(pigletz, boostPercentage, level) {
        _pigletz = pigletz;
        _numSigns = numSigns;
        assert(numSigns <= 12);
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Different Signs";
    }

    function numInCollection() public view virtual override returns (uint256) {
        return _numSigns;
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numSigns;
        return ("Collect ${0} sign", values);
    }

    function _isEligible(uint256 id) internal view returns (bool) {
        return !isLocked(id) && !isBoosted(id) && !_pigletz.isCelebrity(id);
    }

    function isLocked(uint256 id) public view override returns (bool) {
        return _pigletz.isCelebrity(id) || super.isLocked(id);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address owner = _pigletz.ownerOf(tokenId);
        uint256 numberOfPiglets = _pigletz.balanceOf(owner);
        uint256[] memory signs = new uint256[](12);

        for (uint256 i = 0; i < numberOfPiglets; i++) {
            uint256 id = _pigletz.tokenOfOwnerByIndex(owner, i);
            if (_isEligible(id)) {
                signs[uint256(_pigletz.getSign(id))]++;
            }
        }

        uint256 count = 0;
        for (uint256 i = 0; i < 12; i++) {
            if (signs[i] > 0) {
                count++;
            }
        }
        return count >= _numSigns;
    }

    function _haveDifferentSigns(uint256[] memory tokens) internal view returns (bool) {
        uint16[] memory signs = new uint16[](12);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 sign = uint256(_pigletz.getSign(tokens[i]));
            signs[sign]++;
            if (signs[sign] > 1) {
                return false;
            }
        }

        return true;
    }

    function boost(uint256[] calldata tokens) public virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(_haveNotBeenBoosted(tokens), "Some piglets have already been boosted");
        require(_areNotCelebrity(tokens), "Some piglets are celebrities");
        require(_haveCorrectLevel(tokens), "Some piglets are not of the correct level");
        require(_haveDifferentSigns(tokens), "All piglets must have different signs");

        _setBoosted(tokens, true);

        _updateTokenBalance(tokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectNumberBooster is Booster {
    uint256 private _numberToCollect;

    constructor(
        IPigletz pigletz,
        uint256 boost,
        uint256 numberToCollect,
        uint8 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _numberToCollect = numberToCollect;
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Number";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numberToCollect;
        return ("Collect ${0} Piglets", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address owner = _pigletz.ownerOf(tokenId);
        return _pigletz.balanceOf(owner) >= _numberToCollect && !this.isLocked(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract StakingBooster is Booster {
    constructor(IPigletz pigletz, uint256 boost) Booster(pigletz, boost, 1) {
        _pigletz = pigletz;
    }

    function getName() external view virtual override returns (string memory) {
        return "Stake Piglet";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = 1;
        return ("Stake ${0} Piglet", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address staker = _pigletz.getStaker();
        return staker != address(0) && _pigletz.ownerOf(tokenId) == staker;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract SpecialBooster is Booster {
    constructor(IPigletz pigletz, uint256 boost) Booster(pigletz, boost, 1) {
        _pigletz = pigletz;
    }

    function getName() external view virtual override returns (string memory) {
        return "Special Piglet Booster";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](0);
        return ("Piglet is Special", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.isSpecial(tokenId);
    }

    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return !_pigletz.isSpecial(tokenId);
    }

    function isBoosted(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.isSpecial(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracle {
    function getNativeTokenPrice(uint256 amount) external view returns (uint256);

    function getTokenPrice(address token, uint256 amount) external view returns (uint256);

    function getTokenUSDPrice(address token, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
pragma solidity >=0.8.4;

import "../oracle/IOracle.sol";

interface IPigletWallet {
    struct TokenData {
        address token;
        uint256 balance;
    }

    function init(IOracle oracle) external;

    event TokenTransferError(address token, address recipient, string reason);

    event TokenTransfered(address token, address recipient, uint256 amount);

    event Destroyed(address wallet);

    function getBalanceInUSD() external view returns (uint256);

    function maxTokenTypes() external view returns (uint256);

    function listTokens() external view returns (TokenData[] memory);

    function destroy(address recipient) external;

    function registerDeposit(address token) external;

    function deposit(
        address token,
        address sender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IBooster.sol";
import "../piglet/IPigletz.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract Booster is IBooster {
    uint256 constant PIPS = 10000;
    IPigletz internal _pigletz;
    uint256 internal _boost;
    uint256 internal _level;
    mapping(uint256 => bool) _boosted;

    constructor(
        IPigletz piglet,
        uint256 boostPercentage,
        uint256 level
    ) {
        _pigletz = piglet;
        _boost = boostPercentage;
        _level = level;
        assert(_boost >= 1000);
    }

    function getStatus(uint256 tokenId) external view override returns (Status) {
        if (isBoosted(tokenId)) {
            return Status.Boosted;
        }

        if (isReady(tokenId)) {
            return Status.Ready;
        }

        if (isLocked(tokenId)) {
            return Status.Locked;
        }
        return Status.NotReady;
    }

    function getName() external view virtual override returns (string memory) {
        return "Base Booster";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](2);
        values[0] = 1;
        values[1] = 2;
        return ("You need to collect ${0} and ${1} in order to succeed", values);
    }

    function getBoost() public view virtual override returns (uint256) {
        return _boost;
    }

    function numInCollection() public view virtual override returns (uint256) {
        return 1;
    }

    function isReady(uint256 tokenID) public view virtual override returns (bool) {
        return !isLocked(tokenID);
    }

    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.getLevel(tokenId) < _level;
    }

    function isBoosted(uint256 tokenId) public view virtual override returns (bool) {
        return _boosted[tokenId];
    }

    function _areBoostable(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!isReady(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _haveCorrectLevel(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (isLocked(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _updateTokenBalance(uint256[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _pigletz.updatePiFiBalance(tokens[i]);
        }
    }

    function boost(uint256[] calldata tokens) public virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(_haveNotBeenBoosted(tokens), "Some piglets have already been boosted");
        require(_areBoostable(tokens), "Some piglets are not boostable");
        require(_haveCorrectLevel(tokens), "Some piglets are not of the correct level");
        _updateTokenBalance(tokens);

        _setBoosted(tokens, true);
    }

    function unBoost(uint256[] calldata tokens) external virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(!_haveNotBeenBoosted(tokens), "Some piglets have not been boosted");

        _updateTokenBalance(tokens);

        _setBoosted(tokens, false);
    }

    function _setBoosted(uint256[] calldata tokens, bool val) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _boosted[tokens[i]] = val;
            emit Boosted(tokens[i], getBoost(), _level, val);
        }
    }

    function _haveSameOwner(uint256[] calldata tokens) internal view returns (bool) {
        address owner = _pigletz.ownerOf(tokens[0]); // allowed to be invoked by a non owner
        for (uint256 i = 1; i < tokens.length; i++) {
            if (_pigletz.ownerOf(tokens[i]) != owner) {
                return false;
            }
        }
        return true;
    }

    function _haveNotBeenBoosted(uint256[] calldata tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (isBoosted(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _areNotCelebrity(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_pigletz.isCelebrity(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function getBoostAmount(uint256 tokenId, uint256 amount) external view virtual override returns (uint256) {
        if (!isBoosted(tokenId)) {
            return 0;
        }

        return (amount * _boost) / PIPS;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
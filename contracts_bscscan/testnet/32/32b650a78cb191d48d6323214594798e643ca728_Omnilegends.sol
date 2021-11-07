// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Initializable.sol";

contract Omnilegends is Initializable, ERC721Upgradeable , ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _coldWallet;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // used for pricing of the card to be mint
    uint256 private _cardPrice ;

    // shard price 
    uint256 private _shardPrice;

    // used for what token should be used for purchasing a sealed nft
    address private _tokenAddress;

    // used for receiving the token (REWARDS AND POOL CONTRA)
    address private _rewardPoolAddress;

    // used for tracking how many card pack bought by the user
    mapping (address => uint256) private _userCardPackCount;
    struct CharacterType {
        string name;
        uint256 id;
        uint256 maxMinted; // 0 means unli otherwise its limited to the number being set
        uint256 totalMinted;
    }

    // array of character types
    CharacterType[] _characterTypes;
    mapping(uint256=>bool) _isCharacterTypeExist;

    struct Episode {
        uint256 episode;
        uint256 totalCard;
        uint256 remainingCard;
        uint256 totalCardSold;
        uint256 remainingLegend;
    }
    mapping (uint256 => Episode) private _episodes;

    struct CharactersPerEpisode {
        uint256 legendType;
        uint256 total;
        uint256 remaining;
    }
    
    mapping ( uint256=> mapping ( uint256 => CharactersPerEpisode) ) _charactersPerEpisode;

    // mapping per episode and which characters in that episode
    mapping ( uint256=>uint256[]) _episodesCharacterTypes;

    // legend type
    struct Legend {
        uint256 legendType;
        uint summonDate;
        uint256 episode;
        uint256 level;
    }

    // used to track the overall legends minted
    Legend[] private _legends;

    // current episode
    uint256 private _currentEpisode;

    // mapping if an address is allowd to summon a legend
    mapping (address => bool) public whitelistedSummoner;

    // used for event that a new legend was summon
    event SummonLegend(
        address indexed owner,
        uint256 summonDate,
        uint256 tokenId,
        uint256 indexed ctype,
        uint256 indexed episode,
        bool manualSummon
    );

    // used for event that a user bought a sealed nft
    event CardPackSold(
        address indexed account,
        uint256 indexed cardPrice
    );

    // log that a new character type created
    event CreatedCharacter(
        uint256 indexed id,
        string  name,
        uint256 indexed maxMinted
    );

    // log a new episode created
    event CreatedNewEpisode(
        uint256 episode,
        uint256 total,
        CharactersPerEpisode[] charactersPerEpisode
    );

    event ShardSold(
        address indexed buyer,
        uint256 indexed shardPrice,
        uint256 indexed shardQty
    );

    // whitelisted can transfer this nft
    mapping(address=>bool) private _whitelistedForTransfer;

    // emit an event
    event WhitelistMultipleAccountsForTransfer(address[] accounts, bool whiteListed);

    address private _marketPlaceAddress;

    function initialize(uint256 _total) public initializer {
        // __ERC721_init("Omnilegends", "OLEGENDS");
        __ERC721_init("THELASTSTANDING NFT", "NFTTHELASTSTANDING");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        _cardPrice = 100 * 10 ** 18;
        _shardPrice = 1 * 10 ** 18; // set shard price to 1 token
        _currentEpisode = 0; // initialize to zero

        uint256 common = _createCharacterType("COMMON", uint256(0));
        uint256 uncommon = _createCharacterType("UNCOMMON", uint256(0));
        uint256 rare = _createCharacterType("RARE",uint256(0));
        uint256 veryRare = _createCharacterType("VERY_RARE",uint256(0));
        uint256 superRare = _createCharacterType("SUPER_RARE",uint256(0));
        uint256 superRarePlus = _createCharacterType("SUPER_RARE_PLUS",uint256(0));
        _createCharacterType("SPECIAL_SUPER_RARE",uint256(0));

        _mintFounderNFT();

        CharactersPerEpisode[] memory types = new CharactersPerEpisode[](6);
        types[common] = _buildCharactersPerEpisode(common, uint256(_total).mul(45).div(100) );
        types[uncommon] = _buildCharactersPerEpisode(uncommon, uint256(_total).mul(22).div(100) ) ;
        types[rare] = _buildCharactersPerEpisode(rare, uint256(_total).mul(15).div(100) ) ;
        types[veryRare] = _buildCharactersPerEpisode(veryRare, uint256(_total).mul(10).div(100) ) ;
        types[superRare] = _buildCharactersPerEpisode(superRare,  uint256(_total).mul(5).div(100) );
        types[superRarePlus] = _buildCharactersPerEpisode(superRarePlus, uint256(_total).mul(3).div(100) );
            
        _createNewEpisode(_total, types);

        
    }

    function _mintFounderNFT() private {

        _coldWallet = 0x5D793026A3d675C76106128148E090A917163e39;
        _marketPlaceAddress = 0x5D793026A3d675C76106128148E090A917163e39;

        _createCharacterType("OMNI",uint256(150));
        uint256 theOne = _createCharacterType("OMNI_ONE_OF_ONE",uint256(1));

        // 0 - OMNI THE ONE
        _mintLegend(_coldWallet, theOne);
                
    }

    // mint the 109 founder nft
    function mintFounderNFT(address to_, uint256 qty) external onlyOwner {
        uint256 OMNI_FOUNDER_NFT_ID = 7;
        for(uint256 i = 0 ; i < qty ; i++){
            _mintLegend(to_, OMNI_FOUNDER_NFT_ID);
        }
    }

    function setMarketPlaceAddress(address marketPlaceAddress_) external onlyOwner {
        require(marketPlaceAddress_ != address(0), "Not allowed zero address");
        _marketPlaceAddress = marketPlaceAddress_;
    }

    function getMarketPlaceAddress () external view returns (address) {
        return _marketPlaceAddress;
    }

    function _createNewEpisode(uint256 total_, CharactersPerEpisode[] memory charactersPerEpisode_ ) private onlyOwner {
        // create episode
        _currentEpisode = _currentEpisode.add(1);

        _episodes[_currentEpisode].episode = _currentEpisode;
        _episodes[_currentEpisode].totalCard = total_;
        _episodes[_currentEpisode].remainingCard = total_;
        _episodes[_currentEpisode].totalCardSold = 0;
        _episodes[_currentEpisode].remainingLegend = total_;
        
        uint256 runningTotal = 0;
        for(uint256 i = 0 ;i < charactersPerEpisode_.length ; i++){
            CharactersPerEpisode memory ct = charactersPerEpisode_[i];
            
            require(_isCharacterTypeExist[ct.legendType] == true, "Cannot create a new episode with non existing character type");
            
            require(ct.total == ct.remaining, "Total and Remaining should be equal upon create");

            _charactersPerEpisode[_currentEpisode][ct.legendType] = ct;

            runningTotal = runningTotal.add(ct.total);

            _episodesCharacterTypes[_currentEpisode].push(ct.legendType);
        }

        require(runningTotal == total_, "Parameter total is not equal to total characters per episode");

        // log a new episode created
        emit CreatedNewEpisode(_currentEpisode, total_, charactersPerEpisode_);
    }

    function createNewEpisode(uint256 total_, CharactersPerEpisode[] memory charactersPerEpisode_ ) external onlyOwner {
        _createNewEpisode(total_, charactersPerEpisode_);
    }
    

    function _createCharacterType(string memory charName, uint256 maxMinted_) private returns (uint256) {
        uint256 charId = _characterTypes.length;

        _characterTypes.push(CharacterType(charName, charId, maxMinted_, 0));
        
        _isCharacterTypeExist[charId] = true;

        emit CreatedCharacter(charId, charName,maxMinted_);
        return charId;
    }

    function createCharacterType(string memory charName, uint256 maxMinted) external onlyOwner returns (CharacterType memory) {
        uint256 charTypeId = _createCharacterType(charName, maxMinted);

        return _characterTypes[charTypeId];
    }

    function getCharactersType() external view returns (CharacterType[] memory) {
       return _characterTypes;
    }

    function _buildCharactersPerEpisode(uint256 charType_, uint256 total_) private pure returns (CharactersPerEpisode memory){
        return CharactersPerEpisode(charType_, total_, total_);
    }

    // getters
    function episodesCharacterTypes(uint256 episode) external view returns (uint256[] memory) {
        return _episodesCharacterTypes[episode];
    }
    function currentEpisode() external view returns (uint256) {
        return _currentEpisode;
    }

    function cardPrice() external view returns (uint256) {
        return _cardPrice;
    }

    function episodes(uint currentEpisode_) external view returns (Episode memory) {
        return _episodes[currentEpisode_];
    }

    function charactersCountPerEpisodeAndCharType(uint currentEpisode_, uint256 _charType) external view returns (CharactersPerEpisode memory) {
        return _charactersPerEpisode[currentEpisode_][_charType];
    }


    modifier onlySummoner() {
        require(whitelistedSummoner[_msgSender()],"Not whitelisted as summoner");
        _;
    }
    function setSummoner(address _summoner, bool _whitelisted) external onlyOwner {
        require(whitelistedSummoner[_summoner] != _whitelisted,"Invalid value for summoner");
        whitelistedSummoner[_summoner] = _whitelisted;
    }

    function isSummoner(address _summoner) external view returns (bool) {
        return whitelistedSummoner[_summoner];
    }


    function setCardPrice(uint256 cardPrice_) external onlyOwner {
        _cardPrice = cardPrice_;
    }

    function buyCardPack() external whenNotPaused {
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");
        require(_episodes[_currentEpisode].remainingCard > 0, "No Cards Remaining to be sold");
        require(_cardPrice>0,"Card price is not set");
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=_cardPrice,"Token amount allowance is not enough to buy card pack");
        
        // increase total card sold
        _episodes[_currentEpisode].totalCardSold = _episodes[_currentEpisode].totalCardSold.add(1);

        // decrese the total remaining card since this will be summon as LEGEND (NFT)
        _episodes[_currentEpisode].remainingCard = _episodes[_currentEpisode].remainingCard.sub(1); 
        
        // increase total card bought by the user
        _userCardPackCount[_msgSender()] = _userCardPackCount[_msgSender()].add(1);

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, _cardPrice);

        emit CardPackSold(_msgSender(),_cardPrice);
    }

    function summonLegend(address _owner, uint256 _seed)  external onlySummoner returns (uint256 _legendId)  {
        require(_userCardPackCount[_owner]>0,"Owner has no card pack");
        require(_episodes[_currentEpisode].remainingLegend > 0,"No legends left for summoning");
        uint256 _legendType = getLegendTypeFromRandomSeed(_seed);

        require(_isCharacterTypeExist[_legendType] == true, "Character type is not existing");
        
        // decrease the total count
        _userCardPackCount[_owner] = _userCardPackCount[_owner].sub(1);

        // decrease the total _charactersPerEpisode inside this legend type
        _charactersPerEpisode[_currentEpisode][(_legendType)].remaining = _charactersPerEpisode[_currentEpisode][(_legendType)].remaining.sub(1);

        // decrease the total remaining legend
        _episodes[_currentEpisode].remainingLegend = _episodes[_currentEpisode].remainingLegend.sub(1);

        return _summonLegend(_owner, _legendType, false);
    }
    function getLegendTypeFromRandomSeed(uint256 seed) private view returns (uint256 _legendType) {
        uint256 remainingLegend = _episodes[_currentEpisode].remainingLegend;
        uint256 range = seed.mod(remainingLegend).add(1);
        uint256[] memory charTypesPerEpisode = _episodesCharacterTypes[_currentEpisode];
        uint256 runningTotal = 0;
        uint256 currentMin = 0;
        uint256 currentMax = 0;
        for(uint256 idx = 0 ; idx < charTypesPerEpisode.length ; idx++){
            uint256 ctype = charTypesPerEpisode[idx];
            uint256 cremaining = _charactersPerEpisode[_currentEpisode][(ctype)].remaining;
            currentMin = runningTotal.add(1);
            currentMax = runningTotal.add(cremaining);
            runningTotal = runningTotal.add(cremaining);
            if( range >= currentMin && range <= currentMax) {
                _legendType = ctype;
                break;
            }
        }
    }

    function _summonLegend(address _owner, uint256 _legendType, bool isManual) private returns (uint256 _legendId) {
        CharacterType storage ctype =  _characterTypes[_legendType];
        if(ctype.maxMinted > 0){
            require(ctype.maxMinted >= ctype.totalMinted.add(1),"Max minted of character type reached");
        }
        ctype.totalMinted = ctype.totalMinted.add(1);
        
        _legendId = _legends.length;

        _legends.push(Legend((_legendType), block.timestamp, _currentEpisode, 1));
        
        _safeMint(_owner, _legendId);

        emit SummonLegend(_owner, block.timestamp, _legendId, (_legendType), _currentEpisode, isManual);
    }

    // just mint a legend
    function _mintLegend(address _to, uint256 _legendType) private returns (uint256 _legendId ){
        require(_isCharacterTypeExist[_legendType] == true, "Character type is not existing");

        return _summonLegend(_to, _legendType, true);        
    }

    function getLegend(uint256 legendId_) external view returns (Legend memory) {
        return _legends[legendId_];
    }

    function totalLegends() external view returns (uint256) {
        return _legends.length;
    }

    // token address
    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address _token) external onlyOwner {
        _tokenAddress = _token;
    }

    // reward pool address
    function rewardPoolAddress() external view returns (address) {
        return _rewardPoolAddress;
    }

    function setRewardPoolAddress(address _rewardPool) external onlyOwner {
        _rewardPoolAddress = _rewardPool;
    }



    function _baseURI() internal pure override returns (string memory) {
        return "https://oneomniverse.com/api/nft/legends/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        require(_whitelistedForTransfer[from] == true || _whitelistedForTransfer[to] == true || from == address(0),"Not whitelisted or Not allowed to transfer to any account");

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function whitelistMulitipleAccountsForTransfer(address[] calldata accounts, bool whiteListed) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _whitelistedForTransfer[accounts[i]] = whiteListed;
        }

        emit WhitelistMultipleAccountsForTransfer(accounts, whiteListed);
    }

    function isWhiteListedForTransfer(address account)  external view returns( bool) {
        return _whitelistedForTransfer[account];
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
 

    function buyShards(uint256 shardQty) external whenNotPaused {
        require(shardQty > 0 ,"Shard Quantity should be greater than zero");
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");

        uint256 totalShardPrice = _shardPrice.mul(shardQty);

        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=totalShardPrice,"Token amount allowance is not enough to buy shards");

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, totalShardPrice);

        // emit an event that a shard sold
        emit ShardSold(_msgSender(),_shardPrice, shardQty);
    }

    function shardPrice() external view returns (uint256) {
        return _shardPrice;
    }
    function setShardPrice(uint256 shardPrice_) external onlyOwner {
        _shardPrice = shardPrice_;
    }
}
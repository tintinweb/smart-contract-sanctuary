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
import "./IAddFounderNFTForSale.sol";

contract Omnilegends is Initializable, ERC721Upgradeable , ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _coldWallet;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // used for pricing of the card to be mint
    uint256 private _cardPrice ;

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

    // whitelisted can transfer this nft
    mapping(address=>bool) private _whitelistedForTransfer;

    // emit an event
    event WhitelistMultipleAccountsForTransfer(address[] accounts, bool whiteListed);

    address private _marketPlaceAddress;

    event LevelUpLegend(address owner, uint256 legendId, uint256 newLevel);

    uint256 private _maxLegendLevel;

    uint256 private _ssrPrice;

    event SSRLegendSold(
        address indexed owner,
        uint256 indexed ssrPrice
    );

    uint256 private _ssrForSaleQty;
    uint256 private _ssrSoldQty;
    
    // used for tracking how many card pack bought by the user per episode (for episode number 2 above only)
    mapping (address => mapping(uint256=>uint256)) private _userCardPackCountPerEpisode;

    // used for tracking of card pack prices per episode (episode 2 and above)
    mapping (uint256 => uint256) private _cardPricePerEpisode;

    function initialize(uint256 _total) public initializer {
        __ERC721_init("Omnilegends", "OLEGENDS");
       
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        _cardPrice = 100 * 10 ** 18;
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

    function setMaxLegendLevel(uint256 _maxLevel) external onlyOwner {
        require(_maxLevel > 0,"Max level should be greater than 0");
        _maxLegendLevel = _maxLevel;
    }

    function getMaxLegendLevel() external view returns (uint256) {
        return _maxLegendLevel;
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
    function mintFounderNFT(address to_, uint256 qty ) external onlyOwner {
        
        uint256 OMNI_FOUNDER_NFT_ID = 7;
        for(uint256 i = 0 ; i < qty ; i++){
            _mintLegend(to_, OMNI_FOUNDER_NFT_ID);
        }
    }

    function mintFounderNFTToFounderMarketPlace(address to_, uint256 qty, address founderMarketPlaceAddress) external onlyOwner {
        require(founderMarketPlaceAddress != address(0),"Invalid address");

        // whitelist the founder nft marketplace to allow to transfer the nft to the user who will buy the founder nft
        if(_whitelistedForTransfer[founderMarketPlaceAddress] == false){
            _whitelistedForTransfer[founderMarketPlaceAddress] = true;
        }

        uint256 OMNI_FOUNDER_NFT_ID = 7;
        for(uint256 i = 0 ; i < qty ; i++){
            uint256 tokenId = _mintLegend(to_, OMNI_FOUNDER_NFT_ID);

             
            IAddFounderNFTForSale(founderMarketPlaceAddress).addFounderNFTToList(tokenId);
            
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

    function getCurrentEpisodeTotalCards(uint256 episodeNumber) external view returns (uint256) {
        return _episodes[episodeNumber].totalCard;
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

    // set and get card price per episode
    function cardPriceForEpisode(uint256 episode_) external view returns (uint256) {
        return _cardPricePerEpisode[episode_];
    }
    function setCardPriceForEpisode(uint256 cardPrice_, uint256 episode_) external onlyOwner {
        require(episode_ > 1,"Invalid episode");
        _cardPricePerEpisode[episode_] = cardPrice_;
    }

    function buyCardPack() external whenNotPaused {
        // for episode 1
        buyCardPackOnEpisode(1);
    }

    function buyCardPackEpisode(uint256 episodeNumber) external whenNotPaused {
        require(_currentEpisode>=episodeNumber,"Invalid episode number");

        buyCardPackOnEpisode(episodeNumber);
    }

    function buyCardPackOnEpisode(uint256 currentEpisode_) private {
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");
        require(_episodes[currentEpisode_].remainingCard > 0, "No Cards Remaining to be sold");
        // get the correct price 
        uint256 price = currentEpisode_ == 1 ? _cardPrice : _cardPricePerEpisode[currentEpisode_] ;

        require(price>0,"Card price is not set");
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=price,"Token amount allowance is not enough to buy card pack");
        
        // increase total card sold
        _episodes[currentEpisode_].totalCardSold = _episodes[currentEpisode_].totalCardSold.add(1);

        // decrese the total remaining card since this will be summon as LEGEND (NFT)
        _episodes[currentEpisode_].remainingCard = _episodes[currentEpisode_].remainingCard.sub(1); 
        
        if(currentEpisode_ == 1){
            // increase total card bought by the user
            _userCardPackCount[_msgSender()] = _userCardPackCount[_msgSender()].add(1);
        } else {
            // increase total card bought by the user for the specific episode
            _userCardPackCountPerEpisode[_msgSender()][currentEpisode_] = _userCardPackCountPerEpisode[_msgSender()][currentEpisode_].add(1);
        }

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, price);

        emit CardPackSold(_msgSender(),price);
    }

    function summonLegend(address _owner, uint256 _seed, uint256 _episode)  external onlySummoner returns (uint256 _legendId)  {
        require(_currentEpisode>=_episode,"Invalid episode number");
        uint256 _ep = _episode == 0 ? 1 : _episode;
        _legendId = summonLegendOnEpisode(_owner, _seed, _ep);
    }

    function summonLegendOnEpisode(address _owner, uint256 _seed, uint256 episode_ ) private returns (uint256) {
        uint256 cardPackCount = episode_ == 1 ? _userCardPackCount[_owner] : _userCardPackCountPerEpisode[_owner][episode_];
        require(cardPackCount>0,"Owner has no card pack");
        require(_episodes[episode_].remainingLegend > 0,"No legends left for summoning");
        uint256 _legendType = getLegendTypeFromRandomSeed(_seed, episode_);

        require(_isCharacterTypeExist[_legendType] == true, "Character type is not existing");
        
        if(episode_ == 1){
            // decrease the total count
            _userCardPackCount[_owner] = _userCardPackCount[_owner].sub(1);
        } else {
            // decrease the total count per episode
            _userCardPackCountPerEpisode[_owner][episode_] = _userCardPackCountPerEpisode[_owner][episode_].sub(1);
        }

        // decrease the total _charactersPerEpisode inside this legend type
        _charactersPerEpisode[episode_][(_legendType)].remaining = _charactersPerEpisode[episode_][(_legendType)].remaining.sub(1);

        // decrease the total remaining legend
        _episodes[episode_].remainingLegend = _episodes[episode_].remainingLegend.sub(1);

        //return _summonLegend(_owner, _legendType, false);
        return _summonLegendOnEpisode(_owner, _legendType, false, episode_);
    }
    
    function userCardPackCount(address user) external view returns(uint256) {
        return _userCardPackCount[user];
    }
    function userCardPackCountForEpisode(address user, uint256 episode) external view returns(uint256) {
        return _userCardPackCountPerEpisode[user][episode];
    }

    function getLegendTypeFromRandomSeed(uint256 seed, uint256 episode_) private view returns (uint256 _legendType) {
        uint256 remainingLegend = _episodes[episode_].remainingLegend;
        uint256 range = seed.mod(remainingLegend).add(1);
        uint256[] memory charTypesPerEpisode = _episodesCharacterTypes[episode_];
        uint256 runningTotal = 0;
        uint256 currentMin = 0;
        uint256 currentMax = 0;
        for(uint256 idx = 0 ; idx < charTypesPerEpisode.length ; idx++){
            uint256 ctype = charTypesPerEpisode[idx];
            uint256 cremaining = _charactersPerEpisode[episode_][(ctype)].remaining;
            currentMin = runningTotal.add(1);
            currentMax = runningTotal.add(cremaining);
            runningTotal = runningTotal.add(cremaining);
            if( range >= currentMin && range <= currentMax) {
                _legendType = ctype;
                break;
            }
        }
    }

    /**
    * @dev summon legend on episode 1
     */
    function _summonLegend(address _owner, uint256 _legendType, bool isManual) private returns (uint256 _legendId) {
        _legendId = _summonLegendOnEpisode(_owner, _legendType, isManual, 1);
    }

    /**
    * @dev summon legend for specific episode
     */
    function _summonLegendOnEpisode(address _owner, uint256 _legendType, bool isManual, uint256 _episodeNumber) private returns (uint256 _legendId) {
        CharacterType storage ctype =  _characterTypes[_legendType];
        if(ctype.maxMinted > 0){
            require(ctype.maxMinted >= ctype.totalMinted.add(1),"Max minted of character type reached");
        }
        ctype.totalMinted = ctype.totalMinted.add(1);
        
        _legendId = _legends.length;

        _legends.push(Legend((_legendType), block.timestamp, _episodeNumber, 1));
        
        _safeMint(_owner, _legendId);

        emit SummonLegend(_owner, block.timestamp, _legendId, (_legendType), _episodeNumber, isManual);
    }

    // just mint a legend
    function _mintLegend(address _to, uint256 _legendType) private returns (uint256 _legendId ){
        require(_isCharacterTypeExist[_legendType] == true, "Character type is not existing");

        return _summonLegend(_to, _legendType, true);        
    }

    function buySSRLegend() external whenNotPaused returns (uint256) {
        require(_ssrPrice > 0,"Not Set SSR Price");
        require(_ssrForSaleQty > 0,"No available SSR");

        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=_ssrPrice,"Token amount allowance is not enough to buy ssr legend");

        _ssrForSaleQty = _ssrForSaleQty.sub(1);
        _ssrSoldQty = _ssrSoldQty.add(1);

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, _ssrPrice);

        uint256 tokenId = _mintLegend(_msgSender(), 6); // legend type 6 is ssr legend

        // emit an event that a ssr legend sold
        emit SSRLegendSold(_msgSender(),_ssrPrice);

        return tokenId;
    }
    
    function getSSRSoldAndForSaleQty() external view returns (uint256 ssrSoldQty, uint256 ssrForSaleQty) {
        ssrSoldQty = _ssrSoldQty;
        ssrForSaleQty = _ssrForSaleQty; 
    }

    function setSSRPrice(uint256 _price)  external onlyOwner {
        _ssrPrice = _price;
    }

    function ssrPrice() external view returns (uint256) {
        return _ssrPrice;
    }

    function createSSRQtyForSale(uint256 qty) external onlyOwner {
        require(_ssrForSaleQty == 0,"has qty");
        _ssrForSaleQty = qty;
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
        return "https://omnilegends.oneomniverse.com/api/nft/legends/";
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
}
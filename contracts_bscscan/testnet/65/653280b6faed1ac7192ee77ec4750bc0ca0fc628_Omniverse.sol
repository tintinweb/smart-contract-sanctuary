// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";

import "./OwnableUpgradeable.sol";

contract Omniverse is Initializable, ERC721Upgradeable , PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    // character types
    enum CharacterType {
        COMMON,
        UNCOMMON,
        RARE,
        VERY_RARE,
        SUPER_RARE,
        SUPER_RARE_PLUS,
        SPECIAL_SUPER_RARE,
        OMNI
    }
    struct Episode {
        uint256 episode;
        uint256 totalNFT;
        uint256 remainingNFT;
        uint256 totalCardSold;
    }
    mapping (uint256 => Episode) private _episodes;

    struct CharactersPerEpisode {
        CharacterType legendType;
        uint256 total;
        uint256 remaining;
    }

    mapping ( uint256=> mapping ( CharacterType => CharactersPerEpisode) ) _charactersPerEpisode;

    struct Legend {
        CharacterType legendType;
        uint summonDate;
        uint256 episode;
    }

    // used to track the overall legends
    Legend[] private _legends;

    // current episode
    uint256 private _currentEpisode;

    mapping (address => bool) public whitelistedSummoner;

    // used for event that a new legend was summon
    event SummonLegend(
        address owner,
        uint256 summonDate,
        uint256 tokenId,
        CharacterType ctype,
        uint256 episode
    );

    // used for event that a user bought a sealed nft
    event CardPackSold(
        address account,
        uint256 cardPrice
    );

    function initialize(uint256 _total) public initializer {
        __ERC721_init("Omniverse NFT", "ONFT");
        __Pausable_init();
        __Ownable_init();

        _cardPrice = 100 * 10 ** 18;
        _currentEpisode = 1;

        _episodes[_currentEpisode].episode = _currentEpisode;
        _episodes[_currentEpisode].totalNFT = _total;
        _episodes[_currentEpisode].remainingNFT = _total;
        _episodes[_currentEpisode].totalCardSold = 0;

        _charactersPerEpisode[_currentEpisode][CharacterType.COMMON] = _buildCharactersPerEpisode(CharacterType.COMMON, uint256(_total).mul(45).div(100) );          // 45% of 37,500
        _charactersPerEpisode[_currentEpisode][CharacterType.UNCOMMON] = _buildCharactersPerEpisode(CharacterType.UNCOMMON, uint256(_total).mul(22).div(100) );        // 22% of 37,500 
        _charactersPerEpisode[_currentEpisode][CharacterType.RARE] = _buildCharactersPerEpisode(CharacterType.RARE, uint256(_total).mul(15).div(100) );            // 15% of 37,500
        _charactersPerEpisode[_currentEpisode][CharacterType.VERY_RARE] = _buildCharactersPerEpisode(CharacterType.VERY_RARE, uint256(_total).mul(10).div(100) );       // 10% of 37,500
        _charactersPerEpisode[_currentEpisode][CharacterType.SUPER_RARE] = _buildCharactersPerEpisode(CharacterType.SUPER_RARE,  uint256(_total).mul(5).div(100) );      // 5% of 37,500
        _charactersPerEpisode[_currentEpisode][CharacterType.SUPER_RARE_PLUS] = _buildCharactersPerEpisode(CharacterType.SUPER_RARE_PLUS, uint256(_total).mul(3).div(100) );  // 3% of 37,500
     
    }

    function _buildCharactersPerEpisode(CharacterType charType_, uint256 total_) private pure returns (CharactersPerEpisode memory){
        return CharactersPerEpisode(charType_, total_, total_);
    }

    // getters
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
        return _charactersPerEpisode[currentEpisode_][CharacterType(_charType)];
    }


    modifier onlySummoner() {
        require(whitelistedSummoner[_msgSender()],"Not whitelisted as summoner");
        _;
    }
    function setSummoner(address _summoner, bool _whitelisted) external onlyOwner {
        require(whitelistedSummoner[_summoner] != _whitelisted,"Invalid value for summoner");
        whitelistedSummoner[_summoner] = _whitelisted;
    }
    function setCardPrice(uint256 cardPrice_) external onlyOwner {
        _cardPrice = cardPrice_;
    }

    function buyCardPack() external whenNotPaused {
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_episodes[_currentEpisode].remainingNFT > 0, "No Cards Remaining to be sold");
        require(_cardPrice>0,"Card price is not set");
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=_cardPrice,"Token amount allowance is not enough to buy card pack");
        
        // increase total card sold
        _episodes[_currentEpisode].totalCardSold = _episodes[_currentEpisode].totalCardSold.add(1);

        // decrese the total nft remaining since this will be summon as LEGEND (NFT)
        _episodes[_currentEpisode].remainingNFT = _episodes[_currentEpisode].remainingNFT.sub(1); 
        
        // increase total card bought by the user
        _userCardPackCount[_msgSender()] = _userCardPackCount[_msgSender()].add(1);

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, _cardPrice);

        emit CardPackSold(_msgSender(),_cardPrice);
    }

    function summonLegend(address _owner, uint256 _legendType)  external onlySummoner returns (uint256 _legendId)  {
        require(_userCardPackCount[_owner]>0,"Owner has no card pack");
        
        // decrease the total count
        _userCardPackCount[_owner] = _userCardPackCount[_owner].sub(1);

        // decrease the total _charactersPerEpisode inside this legend type
        _charactersPerEpisode[_currentEpisode][CharacterType(_legendType)].remaining = _charactersPerEpisode[_currentEpisode][CharacterType(_legendType)].remaining.sub(1);

        return _summonLegend(_owner, _legendType);
    }

    function _summonLegend(address _owner, uint256 _legendType) private returns (uint256 _legendId) {
        _legends.push(Legend(CharacterType(_legendType), block.timestamp, _currentEpisode));
        
        _legendId = _legends.length - 1;
        
        _safeMint(_owner, _legendId);

        emit SummonLegend(_owner, block.timestamp, _legendId, CharacterType(_legendType), _currentEpisode);
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
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    
 
}
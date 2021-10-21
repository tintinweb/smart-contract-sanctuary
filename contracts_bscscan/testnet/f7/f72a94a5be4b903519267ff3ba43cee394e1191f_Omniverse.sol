// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

import "./ERC1155.sol";


contract OmniverseCore is  Ownable {
    mapping (address => bool) public whitelistedSummoner;



    modifier onlySummoner() {
        require(whitelistedSummoner[_msgSender()],"Not whitelisted as summoner");
        _;
    }

    function setSummoner(address _summoner, bool _whitelisted) external onlyOwner {
        require(whitelistedSummoner[_summoner] != _whitelisted,"Invalid value for summoner");
        whitelistedSummoner[_summoner] = _whitelisted;
    }

    
}

contract Omniverse is ERC1155, OmniverseCore,  Pausable   {
    using SafeMath for uint256;

    // used for pricing of the card to be mint
    uint256 private _cardPrice = 100 * 10 ** 18;

    // used for what token should be used for purchasing a sealed nft
    address private _tokenAddress;

    // used for receiving the token (REWARDS AND POOL CONTRA)
    address private _rewardPoolAddress;

    // used for event that a user bought a sealed nft
    event CardPackSold(
        address account,
        uint256 cardPrice
    );

    // used for tracking how many card pack bought by the user
    mapping (address => uint256) private _userCardPackCount;

    // character types
    uint256 public constant COMMON             = 0;
    uint256 public constant UNCOMMON           = 1;
    uint256 public constant RARE               = 2;
    uint256 public constant VERY_RARE          = 3;
    uint256 public constant SUPER_RARE         = 4;
    uint256 public constant SUPER_RARE_PLUS    = 5;
    uint256 public constant SPECIAL_SUPER_RARE = 6;
    uint256 public constant OMNI               = 7;
    // 37,500 nfts

    // Common          - 45% chance to acquire this NFT character
    // Uncommon        - 22.5% chance to acquire this NFT character
    // Rare            - 15% chance to acquire this NFT character
    // Very Rare       - 10% chance to acquire this NFT character
    // Super Rare      - 5% chance to acquire this NFT character
    // Super Rare plus - 2.5% chance to acquire this NFT character

    // Special Super Rare (Will be available on special events)
    // Omni (150 pieces only, the 100 pieces will be given for the qualified 100 users who will avail the beta test package)

    // mint nfts every increase episode
    // 37,500

    // used for tracking what is the items inside a episode
    mapping (uint256 => mapping (uint256=>uint256)) private _episodesCharactersNFT;

    uint256 private _currentEpisode = 1;

    constructor () public ERC1155("https://www.oneomniverse.com/api/nft/") {

        _episodesCharactersNFT[_currentEpisode][COMMON]          = uint256(16875); // 45% of 37,500
        _episodesCharactersNFT[_currentEpisode][UNCOMMON]        = uint256(8437);  // 22% of 37,500 
        _episodesCharactersNFT[_currentEpisode][RARE]            = uint256(5625);  // 15% of 37,500
        _episodesCharactersNFT[_currentEpisode][VERY_RARE]       = uint256(3750);  // 10% of 37,500
        _episodesCharactersNFT[_currentEpisode][SUPER_RARE]      = uint256(1875);  // 5% of 37,500
        _episodesCharactersNFT[_currentEpisode][SUPER_RARE_PLUS] = uint256(938);   // 3% of 37,500

        address _minter = _msgSender(); ///address(this);
        _mint(_minter, COMMON          , _episodesCharactersNFT[_currentEpisode][COMMON]         ,"");
        _mint(_minter, UNCOMMON        , _episodesCharactersNFT[_currentEpisode][UNCOMMON]       ,"");
        _mint(_minter, RARE            , _episodesCharactersNFT[_currentEpisode][RARE]           ,"");
        _mint(_minter, VERY_RARE       , _episodesCharactersNFT[_currentEpisode][VERY_RARE]      ,"");
        _mint(_minter, SUPER_RARE      , _episodesCharactersNFT[_currentEpisode][SUPER_RARE]     ,"");
        _mint(_minter, SUPER_RARE_PLUS , _episodesCharactersNFT[_currentEpisode][SUPER_RARE_PLUS],"");
    }

    

    function setCardPrice(uint256 cardPrice) public onlyOwner {
        _cardPrice = cardPrice;
    }

    function buyCardPack() public whenNotPaused {
        require(_cardPrice>0,"Card price is not set");
        require(IERC20(_tokenAddress).balanceOf(_msgSender())>=_cardPrice,"Token amount is not enough to buy card pack");
        
        _userCardPackCount[_msgSender()] = _userCardPackCount[_msgSender()].add(1);

        IERC20(_tokenAddress).transferFrom(_msgSender(), _rewardPoolAddress, _cardPrice);

        emit CardPackSold(_msgSender(),_cardPrice);
    }

    function summonLegend(address _owner)  external onlySummoner returns (uint256) {
        require(_userCardPackCount[_owner]>0,"Owner has no card pack");
        _userCardPackCount[_owner] = _userCardPackCount[_owner].sub(1);

        // perform randomness

        
        return 1;
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

}
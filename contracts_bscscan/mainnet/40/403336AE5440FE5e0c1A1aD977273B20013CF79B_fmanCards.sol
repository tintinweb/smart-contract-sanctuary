pragma solidity ^0.5.12;

import "./Ownable.sol";
import './ERC1155.sol';
import './ERC1155Metadata.sol';
import './ERC1155MintBurn.sol';
import "./Strings.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";


contract fmanCards is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Strings for string;

  mapping (uint256 => uint256) public tokenSupply;
  mapping (uint256 => bool) public isMintDrop;
  mapping (uint256 => bool) public validSeason;
  mapping (uint256 => bool) public validCard;

  struct Card {
    uint256 id;
    uint256 price;
    uint256 maxSupply;
    uint256 maxOwned;
    uint256 rank;
  }

  struct Season {
    uint256 id;
    uint256 rankOneProb;
    uint256 rankTwoProb;
    uint256 rankThreeProb;
    uint256 rankFourProb;
    uint256 rankFiveProb;
    uint256 priceOf1;
    uint256 priceOf5;
    uint256 priceOf10;
    uint256[] cIds;
    mapping (uint256 => bool)  rakMintable;
    uint256[]  ranks;
  }

  mapping (uint256 => Card) public cardById;
  mapping (uint256 => Season) public seasonById;

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  // Define if sale is active
  bool public saleIsActive = false;

  // FMAN Token Contract Addy
  address public fmanAddy = 0xC2aEbbBc596261D0bE3b41812820dad54508575b;

  // Address of owner wallet
  address payable private ownerAddress;

  // Address of NFT dev
  address payable private devAddress;

  // Modifiers
  modifier onlyDev() {
      require(devAddress == msg.sender, "dev: only dev can change their address.");
      _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address payable _devAddress
  ) public {
    name = _name;
    symbol = _symbol;
    ownerAddress = msg.sender;
    devAddress = _devAddress;
  }

  function uri(
    uint256 _id
  ) public view returns (string memory) {
    return Strings.strConcat(
      baseMetadataURI,
      Strings.uint2str(_id)
    );
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  /**
   * Withdraws FMAN from contract address
   */
  function withdraw() public onlyOwner {
      uint256 balance = IERC20(fmanAddy).balanceOf(address(this));
      // 5% goes to NFT dev
      uint256 balanceForDev = balance.div(10).div(2);
      uint256 deltaBalance = balance.sub(balanceForDev);
      IERC20(fmanAddy).transfer(devAddress, balanceForDev);
      IERC20(fmanAddy).transfer(ownerAddress, deltaBalance);

  }

  function setFMANAddy(address tokenaddy) public onlyOwner {
      fmanAddy = tokenaddy;
  }

  function withdrawToken(address tokenAddy) public onlyOwner {
      uint256 balance = IERC20(tokenAddy).balanceOf(address(this));
      // 5% goes to NFT dev
      uint256 balanceForDev = balance.div(10).div(2);
      uint256 deltaBalance = balance.sub(balanceForDev);
      IERC20(tokenAddy).transfer(devAddress, balanceForDev);
      IERC20(tokenAddy).transfer(ownerAddress, deltaBalance);
  }

  /**
   * Withdraws BNB from contract address
   */
  function WithdrawBeans() public onlyOwner {
      uint256 balance = address(this).balance;
      // 5% goes to NFT dev
      uint256 balanceForDev = balance.div(10).div(2);
      uint256 deltaBalance = balance.sub(balanceForDev);
      devAddress.transfer(balanceForDev);
      ownerAddress.transfer(deltaBalance);
  }

  /*
   * Set owner address
   */
  function setOwnerAddress(address payable newOwnerAddress) public onlyOwner {
      ownerAddress = newOwnerAddress;
      transferOwnership(newOwnerAddress);
  }

  /*
   * Set dev address
   */
  function setDevAddress(address payable newDevAddress) public onlyDev {
      devAddress = newDevAddress;
  }

  function setSaleState(bool newState) public onlyOwner {
      saleIsActive = newState;
  }

  function createCard(
    uint256 _id,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _maxOwned,
    uint256 _rank

  ) public onlyOwner {
    require(!validCard[_id], "Card already exists");
    require(_maxSupply >= 1, "Above 0 max supply");
    require(_maxOwned >= 1, "Above 0 max owned");
    require(_rank >= 1 && _rank <=5, "rank [1,5]");

    Card memory card = Card(_id, _price, _maxSupply, _maxOwned, _rank);
    cardById[_id] = card;
    validCard[_id] = true;
  }

  function getCardPrice(uint256 _id) public view returns(uint256){
    require(validCard[_id], "invalid card");
    return cardById[_id].price;
  }

  function getCardMaxSupply(uint256 _id) public view returns(uint256){
    require(validCard[_id], "invalid card");
    return cardById[_id].maxSupply;
  }

  function getCardMaxRank(uint256 _id) public view returns(uint256){
    require(validCard[_id], "invalid card");
    return cardById[_id].rank;
  }

  function getSeasonCards(uint256 _id) public view returns(uint256[] memory){
    require(validSeason[_id], "invalid season");
    return seasonById[_id].cIds;
  }

  function getSeasonPrice1(uint256 _id) public view returns(uint256){
    require(validSeason[_id], "invalid season");
    return seasonById[_id].priceOf1;
  }

  function getSeasonPrice5(uint256 _id) public view returns(uint256){
    require(validSeason[_id], "invalid season");
    return seasonById[_id].priceOf5;
  }

  function getSeasonPrice10(uint256 _id) public view returns(uint256){
    require(validSeason[_id], "invalid season");
    return seasonById[_id].priceOf10;
  }

  function setSeasonData(
    uint256 _id,
    uint256 _prob1,
    uint256 _prob2,
    uint256 _prob3,
    uint256 _prob4,
    uint256 _prob5,
    uint256 _priceOf1,
    uint256 _priceOf5,
    uint256 _priceOf10
  ) public onlyOwner {
    require(validSeason[_id], "Season doesnt exists");
    seasonById[_id].rankOneProb = _prob1;
    seasonById[_id].rankTwoProb = _prob2;
    seasonById[_id].rankThreeProb = _prob3;
    seasonById[_id].rankFourProb = _prob4;
    seasonById[_id].rankFiveProb = _prob5;
    seasonById[_id].priceOf1 = _priceOf1;
    seasonById[_id].priceOf5 = _priceOf5;
    seasonById[_id].priceOf10 = _priceOf10;
  }


  function setCardData(
    uint256 _id,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _maxOwned,
    uint256 _rank


  ) public onlyOwner {
    require(validCard[_id], "Card doesnt exists");
    cardById[_id].price = _price;
    cardById[_id].maxOwned = _maxOwned;
    cardById[_id].maxSupply = _maxSupply;
    cardById[_id].rank = _rank;
  }

  function createSeason(
    uint256[] memory _tokenIds,
    uint256 _seasonId,
    uint256 _rankOneProb,
    uint256 _rankTwoProb,
    uint256 _rankThreeProb,
    uint256 _rankFourProb,
    uint256 _rankFiveProb,
    uint256 _priceOf1,
    uint256 _priceOf5,
    uint256 _priceOf10

  ) public onlyOwner {
    require(!validSeason[_seasonId], "season already exists");
    require(_rankOneProb+_rankTwoProb+_rankThreeProb+_rankFourProb+_rankFiveProb==100, "Need probabilities to equal 100");
    // TODO: check if the card ids passed in are all valid and have data
    Season storage season = seasonById[_seasonId];
    season.id = _seasonId;
    for (uint i=0; i<_tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];
      require(validCard[tokenId],"Card invalid make sure all card Ids are created");
      Card storage card = cardById[tokenId];
      season.cIds.push(tokenId);
      if(!season.rakMintable[card.rank]){
        season.ranks.push(card.rank);
        season.rakMintable[card.rank] = true;
      }
    }
    season.rankOneProb = _rankOneProb;
    season.rankTwoProb = _rankTwoProb;
    season.rankThreeProb = _rankThreeProb;
    season.rankFourProb = _rankFourProb;
    season.rankFiveProb = _rankFiveProb;
    season.priceOf1 = _priceOf1;
    season.priceOf10 = _priceOf10;
    season.priceOf5 = _priceOf5;


    validSeason[_seasonId] = true;
  }


  function updateCardsInSeason(
    uint256[] memory _tokenIds,
    uint256 _seasonId
  ) public onlyOwner {
    require(validSeason[_seasonId], "Invalid season ID");
    Season storage season = seasonById[_seasonId];
    uint256[] memory cIds = new uint256[](_tokenIds.length);
    uint256[] memory ranks = new uint256[](_tokenIds.length);
    uint256 ranksLen = 0;
    uint256 cIdLen = 0;
    // clear rankMintable map 1-5
    for (uint i=1; i<6; i++) {
      season.rakMintable[i] = false;
    }
    for (uint i=0; i<_tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];
      require(validCard[tokenId],"Card invalid make sure all card Ids are created");
      Card storage card = cardById[tokenId];
      require(tokenSupply[tokenId]<card.maxSupply,"Card is already past its supply, update the card's maxSupply to add it");
      cIds[cIdLen]=tokenId;
      cIdLen++;
      if(!season.rakMintable[card.rank]){
        ranks[ranksLen]=card.rank;
        ranksLen++;
        season.rakMintable[card.rank] = true;
      }
    }
    season.ranks = ranks;
    season.cIds = cIds;
  }

  function syncSeasonRanks(
    uint256 seasonId
  ) private {
    require(validSeason[seasonId],"Invalid season id");
    Season storage season = seasonById[seasonId];
    uint256[] memory cIds = new uint256[](season.cIds.length);
    uint256[] memory ranks = new uint256[](season.cIds.length);
    uint256 ranksLen = 0;
    uint256 cIdLen = 0;
    // clear rankMintable map 1-5
    for (uint i=1; i<6; i++) {
      season.rakMintable[i] = false;
    }
    for (uint i=0; i<season.cIds.length; i++) {
      Card storage card = cardById[season.cIds[i]];
      if(tokenSupply[card.id] < card.maxSupply){
        cIds[cIdLen] = card.id;
        cIdLen++;
        if(!season.rakMintable[card.rank]){
          ranks[ranksLen]=card.rank;
          ranksLen++;
          season.rakMintable[card.rank] = true;
        }
      }

    }
    season.cIds = cIds;
    season.ranks = ranks;
  }


  function setMintDrop(
    uint256 _id,
    bool _state
  ) public onlyOwner{
    require(validCard[_id],"Card invalid make sure card with provided ID is created first.");
    isMintDrop[_id] = _state;
  }

  function mintDrop(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public {
    require(saleIsActive, "Minting is currently disabled");
    require(isMintDrop[_id], "Not a Mintdrop NFT");
    require(validCard[_id], "Not a valid card ID");
    require(
        _quantity >= 1,
        "Must mint at least one token at a time"
    );
    Card memory card = cardById[_id];
    uint256 payableTokens = card.price.mul(_quantity) * 10**18;
    require(
        balanceOf(_to, _id).add(_quantity) <= card.maxOwned,
        "The amount you are trying to mint puts you above maximum per wallet."
    );
    require(
        tokenSupply[_id].add(_quantity) <= card.maxSupply,
        "Mint would exceed max supply of token."
    );
    require(
        IERC20(fmanAddy).balanceOf(msg.sender) >= payableTokens,
        "Get your money up, not your funny up."
    );

    IERC20(fmanAddy).transferFrom(msg.sender, address(this), payableTokens);

    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id].add(_quantity);
  }


  function random() private view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
  }

  function getMintableCards(uint256[] memory _cards) private view returns (uint256[] memory) {
    uint256[] memory mintableCards = new uint256[](_cards.length);
    uint256 mintableCount = 0;

    for (uint i=0; i<_cards.length; i++) {
      Card storage card = cardById[_cards[i]];
      if(tokenSupply[card.id] < card.maxSupply && balanceOf(msg.sender, card.id) < card.maxOwned){
        mintableCards[mintableCount]=card.id;
        mintableCount++;
      }
    }

    return mintableCards;
  }

  function getWinningRank(uint256 seasonId, uint256 randomness) private view returns (uint256) {
    // random between 1-100
    uint256 rank;
    Season storage season = seasonById[seasonId];
    uint256 randoMando = randomness.mod(100).add(1);
    uint256 rankCount = 0;
    for (uint i=1; i<6; i++) {
      if(season.rakMintable[i]){
        rankCount++;
      }
    }
    // if randoMando between (1 - rankFiveProb) then rank is 5
    if(randoMando >= 1 && randoMando <= season.rankFiveProb && season.rakMintable[5]){
      rank = 5;
      // if randoMando between (rankFiveProb+1 - rankFiveProb+rankFourProb) then rank is 4
    } else if(randoMando >= season.rankFiveProb+1 && randoMando <= season.rankFiveProb+season.rankFourProb && season.rakMintable[4]){
      rank = 4;
    } else if(randoMando >= season.rankFiveProb+season.rankFourProb+1 && randoMando <= season.rankFiveProb+season.rankFourProb+season.rankThreeProb && season.rakMintable[3]){
      rank = 3;
    } else if(randoMando >= season.rankFiveProb+season.rankFourProb+season.rankThreeProb+1 && randoMando <= season.rankFiveProb+season.rankFourProb+season.rankThreeProb+season.rankTwoProb && season.rakMintable[2]){
      rank = 2;
    } else if(randoMando >= season.rankFiveProb+season.rankFourProb+season.rankThreeProb+season.rankTwoProb+1 && randoMando <= season.rankFiveProb+season.rankFourProb+season.rankThreeProb+season.rankTwoProb+season.rankOneProb && season.rakMintable[1]){
      rank = 1;
    } else {
      rank = season.ranks[random().mod(rankCount)];
    }
    return rank;
  }

  function getWinningCard(uint256 seasonId, uint256 randomness) private view returns (uint256) {
    Season memory season = seasonById[seasonId];
    uint256 rank = getWinningRank(season.id, randomness);
    uint256[] memory cardCandidates = new uint256[](season.cIds.length);
    uint256 candidateCount = 0;
    uint256[] memory mintableCards = getMintableCards(season.cIds);
    for (uint i=0; i<mintableCards.length; i++) {
      Card storage card = cardById[mintableCards[i]];
      if(card.rank == rank){
        cardCandidates[candidateCount] = card.id;
        candidateCount++;
      }
    }
    return cardCandidates[randomness.mod(candidateCount)];
  }


  function expand(uint256 randomValue, uint256 n) private pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues;
  }

  function mintSeason(
    address _to,
    uint256 _quantity,
    uint256 _seasonId,
    bytes memory _data
  ) public {
    require(saleIsActive, "Minting is currently disabled");
    require(validSeason[_seasonId], "Not a valid season ID");
    require(
        _quantity == 1 || _quantity == 5 || _quantity == 10,
        "Must mint 1,5, or 10"
    );

    Season memory season = seasonById[_seasonId];
    require(season.ranks[0] > 0, "Season has no more cards/ranks to mint");

    uint256 payableTokens;
    if(_quantity == 1){
      payableTokens = season.priceOf1 * 10**18;
    } else if(_quantity == 5){
      payableTokens = season.priceOf5 * 10**18;
    } else if(_quantity == 10){
      payableTokens = season.priceOf10 * 10**18;
    }
    require(
        IERC20(fmanAddy).balanceOf(msg.sender) >= payableTokens,
        "Get your money up, not your funny up."
    );
    IERC20(fmanAddy).transferFrom(msg.sender, address(this), payableTokens);
    uint256[] memory randomNumbers = expand(random(), _quantity);
    for (uint i=0; i<_quantity; i++) {
      uint256 winnerCardId = getWinningCard(season.id, randomNumbers[i]);
      _mint(_to, winnerCardId, 1, _data);
      tokenSupply[winnerCardId] = tokenSupply[winnerCardId].add(1);
      syncSeasonRanks(season.id);
    }
  }


  /**
   *
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view returns (bool isOperator) {

    return ERC1155.isApprovedForAll(_owner, _operator);
  }


}
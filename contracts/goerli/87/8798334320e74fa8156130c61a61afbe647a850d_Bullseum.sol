// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;


import './ReentrancyGuard.sol';
import './ERC721PresetMinterPauserAutoId.sol';
import './Ownable.sol';
import './BullGeneGenerator.sol';


contract Bullseum is ERC721PresetMinterPauserAutoId, ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    using BullGeneGenerator for BullGeneGenerator.Gene;

    BullGeneGenerator.Gene internal geneGenerator;

    uint256 public constant maxBULLS = 10000;
    uint256 public constant bulkBuyLimit = 25;

    uint256 public bullsMintedForPromotion;
    uint256 public unitBullPrice;

    mapping (uint256 => uint256) internal _genes;

    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event BullseumPriceChanged(uint256 newUnitBullPrice);




    constructor() ERC721PresetMinterPauserAutoId('BULLSEUM', 'BULL') public {

        bullsMintedForPromotion = 0;
        unitBullPrice = 0.07 ether;
        geneGenerator.random();
        pause();

    }

    function setUnitBullPrice(uint256 newUnitBullPrice) public onlyOwner {
        unitBullPrice = newUnitBullPrice;
        emit BullseumPriceChanged(newUnitBullPrice);
    }


    function mint(uint256 amount) public payable nonReentrant returns(bool){

      require(amount <= bulkBuyLimit, "Cannot bulk buy more than the preset limit");
      require(_tokenIdTracker.current()+(amount) <= maxBULLS, "Total supply reached");
      require(msg.value == unitBullPrice*amount, 'You need to send 0.07ether per bull desired');

      mintHelper(_msgSender(), amount);

      return true;


    }

    function mintForPromotion(uint256 amount, address to) public onlyOwner returns(bool){
      require(bullsMintedForPromotion + amount <= 150, 'Cant mint more bulls for promotion');
      require(_tokenIdTracker.current()+(amount) <= maxBULLS, "Total supply reached");
      bullsMintedForPromotion += amount;
      mintHelper(to, amount);
      return true;
    }

    function mintHelper(address sender, uint256 amount) internal {

      for (uint256 i = 0; i < amount; i++) {


          uint256 tokenId = _tokenIdTracker.current();
          _genes[tokenId] = geneGenerator.random();
          _mint(sender, tokenId);
          _tokenIdTracker.increment();

          emit TokenMinted(tokenId, _genes[tokenId]);
      }

    }


    function setBaseURI(string memory _baseURI, uint256 id) public virtual {
        require(hasRole(BASE_URI_SETTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have base uri setter role to change base URI");
        _setBaseURI(_baseURI,id);
    }

    function geneOf(uint256 tokenId) public view returns (uint256 gene) {
        return _genes[tokenId];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }






}
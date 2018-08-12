pragma solidity ^0.4.19;


contract ERC721 {
    function approve(address to, uint256 tokenId) public;
    function balanceOf(address owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 tokenId) public view returns (address addr);
    function takeOwnership(uint256 tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function transfer(address to, uint256 tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    function name() external view returns (string name);
    function symbol() external view returns (string symbol);
    function tokenURI(uint256 _tokenId) external view returns (string uri);
  }


contract ExoplanetToken is ERC721 {

    using SafeMath for uint256;

    event Birth(uint256 indexed tokenId, string name, uint32 numOfTokensBonusOnPurchase, address owner);

    event TokenSold(uint256 tokenId, uint256 oldPriceInEther, uint256 newPriceInEther, address prevOwner, address winner, string name);

    event Transfer(address from, address to, uint256 tokenId);

    event ContractUpgrade(address newContract);


    string private constant CONTRACT_NAME = "ExoPlanets";

    string private constant CONTRACT_SYMBOL = "XPL";

    string public constant BASE_URL = "https://exoplanets.io/metadata/planet_";

    uint32 private constant NUM_EXOPLANETS_LIMIT = 10000;

    uint256 private constant STEP_1 =  5.0 ether;
    uint256 private constant STEP_2 = 10.0 ether;
    uint256 private constant STEP_3 = 26.0 ether;
    uint256 private constant STEP_4 = 36.0 ether;
    uint256 private constant STEP_5 = 47.0 ether;
    uint256 private constant STEP_6 = 59.0 ether;
    uint256 private constant STEP_7 = 67.85 ether;
    uint256 private constant STEP_8 = 76.67 ether;


    mapping (uint256 => address) public currentOwner;

    mapping (address => uint256) private numOwnedTokens;

    mapping (uint256 => address) public approvedToTransfer;

    mapping (uint256 => uint256) private currentPrice;

    address public ceoAddress;
    address public cooAddress;

    bool public inPresaleMode = true;

    bool public paused = false;

    bool public allowMigrate = true;

    address public newContractAddress;

    bool public _allowBuyDirect = false;


    struct ExoplanetRec {
        uint8 lifeRate;
        bool canBePurchased;
        uint32 priceInExoTokens;
        uint32 numOfTokensBonusOnPurchase;
        string name;
        string nickname;
        string cryptoMatch;
        string techBonus1;
        string techBonus2;
        string techBonus3;
        string scientificData;
    }

    ExoplanetRec[] private exoplanets;

    address public marketplaceAddress;


    modifier onlyCEO() {
      require(msg.sender == ceoAddress);
      _;
    }


    modifier migrateAllowed() {
        require(allowMigrate);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function turnMigrateOff() public onlyCEO() {
      allowMigrate = false;
    }

    function pause() public onlyCEO() whenNotPaused() {
      paused = true;
    }

    function unpause() public onlyCEO() whenPaused() {
      paused = false;
    }

    modifier allowBuyDirect() {
      require(_allowBuyDirect);
      _;
    }

   function setBuyDirectMode(bool newMode, address newMarketplace) public onlyCEO {
      _allowBuyDirect = newMode;
      marketplaceAddress = newMarketplace;
    }


    function setPurchaseableMode(uint256 tokenId, bool _canBePurchased, uint256 _newPrice) public afterPresaleMode() {
      require(owns(msg.sender, tokenId));
      exoplanets[tokenId].canBePurchased = _canBePurchased;
      setPriceInEth(tokenId, _newPrice);
    }


    function getPurchaseableMode(uint256 tokenId) public view returns (bool) {
      return exoplanets[tokenId].canBePurchased;
    }

    function setNewAddress(address _v2Address) public onlyCEO() whenPaused() {
      newContractAddress = _v2Address;
      ContractUpgrade(_v2Address);
    }


    modifier onlyCOO() {
      require(msg.sender == cooAddress);
      _;
    }

    modifier presaleModeActive() {
      require(inPresaleMode);
      _;
    }


    modifier afterPresaleMode() {
      require(!inPresaleMode);
      _;
    }


    modifier onlyCLevel() {
      require(
        msg.sender == ceoAddress ||
        msg.sender == cooAddress
      );
      _;
    }

    function setCEO(address newCEO) public onlyCEO {
      require(newCEO != address(0));
      ceoAddress = newCEO;
    }

    function setCOO(address newCOO) public onlyCEO {
      require(newCOO != address(0));
      cooAddress = newCOO;
    }

    function setPresaleMode(bool newMode) public onlyCEO {
      inPresaleMode = newMode;
    }


    /*** CONSTRUCTOR ***/
    function ExoplanetToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        marketplaceAddress = msg.sender;
    }


    function approve(address to, uint256 tokenId) public {
        require(owns(msg.sender, tokenId));

        approvedToTransfer[tokenId] = to;

        Approval(msg.sender, to, tokenId);
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        balance = numOwnedTokens[owner];
    }

    function bytes32ToString(bytes32 x) private pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function migrateSinglePlanet(
          uint256 origTokenId, string name, uint256 priceInEther, uint32 priceInExoTokens,
          string cryptoMatch, uint32 numOfTokensBonusOnPurchase,
          uint8 lifeRate, string scientificData, address owner) public onlyCLevel migrateAllowed {

        _migrateExoplanet(origTokenId, name, priceInEther, priceInExoTokens,
              cryptoMatch, numOfTokensBonusOnPurchase, lifeRate, scientificData, owner);
    }


    function _migrateExoplanet(
        uint256 origTokenId, string name, uint256 priceInEther, uint32 priceInExoTokens,
        string cryptoMatch, uint32 numOfTokensBonusOnPurchase, uint8 lifeRate,
        string scientificData, address owner) private {

      require(totalSupply() < NUM_EXOPLANETS_LIMIT);

      require(origTokenId == uint256(uint32(origTokenId)));

      ExoplanetRec memory _exoplanet = ExoplanetRec({
        name: name,
        nickname: "",
        priceInExoTokens: priceInExoTokens,
        cryptoMatch: cryptoMatch,
        numOfTokensBonusOnPurchase: numOfTokensBonusOnPurchase,
        lifeRate: lifeRate,
        techBonus1: "",
        techBonus2: "",
        techBonus3: "",
        scientificData: scientificData,
        canBePurchased: false
      });

      uint256 tokenId = exoplanets.push(_exoplanet) - 1;

      currentPrice[tokenId] = priceInEther;

      numOwnedTokens[owner]++;
      exoplanets[tokenId].canBePurchased = false;
      currentOwner[tokenId] = owner;
    }


    function createContractExoplanet(
          string name, uint256 priceInEther, uint32 priceInExoTokens,
          string cryptoMatch, uint32 numOfTokensBonusOnPurchase,
          uint8 lifeRate, string scientificData) public onlyCLevel returns (uint256) {

        return _createExoplanet(name, address(this), priceInEther, priceInExoTokens,
              cryptoMatch, numOfTokensBonusOnPurchase, lifeRate,
              scientificData);
    }

    function _createExoplanet(
        string name, address owner, uint256 priceInEther, uint32 priceInExoTokens,
        string cryptoMatch, uint32 numOfTokensBonusOnPurchase, uint8 lifeRate,
        string scientificData) private returns (uint256) {

      require(totalSupply() < NUM_EXOPLANETS_LIMIT);

      ExoplanetRec memory _exoplanet = ExoplanetRec({
        name: name,
        nickname: "",
        priceInExoTokens: priceInExoTokens,
        cryptoMatch: cryptoMatch,
        numOfTokensBonusOnPurchase: numOfTokensBonusOnPurchase,
        lifeRate: lifeRate,
        techBonus1: "",
        techBonus2: "",
        techBonus3: "",
        scientificData: scientificData,
        canBePurchased: false
      });
      uint256 newExoplanetId = exoplanets.push(_exoplanet) - 1;

      require(newExoplanetId == uint256(uint32(newExoplanetId)));

      Birth(newExoplanetId, name, numOfTokensBonusOnPurchase, owner);

      currentPrice[newExoplanetId] = priceInEther;

      _transfer(address(0), owner, newExoplanetId);

      return newExoplanetId;
    }


    function unownedPlanet(uint256 tokenId) private view returns (bool) {
      return currentOwner[tokenId] == address(this);
    }

    function getPlanetName(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].name;
    }
    function getNickname(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].nickname;
    }

    function getPriceInExoTokens(uint256 tokenId) public view returns (uint32) {
      return exoplanets[tokenId].priceInExoTokens;
    }

    function getLifeRate(uint256 tokenId) public view returns (uint8) {
      return exoplanets[tokenId].lifeRate;
    }

    function getNumOfTokensBonusOnPurchase(uint256 tokenId) public view returns (uint32) {
      return exoplanets[tokenId].numOfTokensBonusOnPurchase;
    }

    function getCryptoMatch(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].cryptoMatch;
    }

    function getTechBonus1(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].techBonus1;
    }

    function getTechBonus2(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].techBonus2;
    }

    function getTechBonus3(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].techBonus3;
    }

    function getScientificData(uint256 tokenId) public view returns (string) {
      return exoplanets[tokenId].scientificData;
    }


    function setTechBonus1(uint256 tokenId, string newVal) public {
      require(msg.sender == marketplaceAddress || msg.sender == ceoAddress);
      exoplanets[tokenId].techBonus1 = newVal;
    }

    function setTechBonus2(uint256 tokenId, string newVal) public {
      require(msg.sender == marketplaceAddress || msg.sender == ceoAddress);
      exoplanets[tokenId].techBonus2 = newVal;
    }

    function setTechBonus3(uint256 tokenId, string newVal) public {
      require(msg.sender == marketplaceAddress || msg.sender == ceoAddress);
      exoplanets[tokenId].techBonus3 = newVal;
    }

    function setPriceInEth(uint256 tokenId, uint256 newPrice) public afterPresaleMode() {
      require(owns(msg.sender, tokenId));
      currentPrice[tokenId] = newPrice;
    }

    function setUnownedPriceInEth(uint256 tokenId, uint256 newPrice) public onlyCLevel {
      require(unownedPlanet(tokenId));
      currentPrice[tokenId] = newPrice;
    }

    function setUnownedPurchaseableMode(uint256 tokenId, bool _canBePurchased) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].canBePurchased = _canBePurchased;
    }

    function setPriceInExoTokens(uint256 tokenId, uint32 newPrice) public afterPresaleMode() {
      require(owns(msg.sender, tokenId));
      exoplanets[tokenId].priceInExoTokens = newPrice;
    }

    function setUnownedPriceInExoTokens(uint256 tokenId, uint32 newPrice) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].priceInExoTokens = newPrice;
    }

    function setScientificData(uint256 tokenId, string newData) public onlyCLevel {
      exoplanets[tokenId].scientificData = newData;
    }

    function setUnownedName(uint256 tokenId, string newData) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].name = newData;
    }

    function setUnownedNickname(uint256 tokenId, string newData) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].nickname = newData;
    }

    function setCryptoMatchValue(uint256 tokenId, string newData) public onlyCLevel {
      exoplanets[tokenId].cryptoMatch = newData;
    }

    function setUnownedNumOfExoTokensBonus(uint256 tokenId, uint32 newData) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].numOfTokensBonusOnPurchase = newData;
    }

     function setUnownedLifeRate(uint256 tokenId, uint8 newData) public onlyCLevel {
      require(unownedPlanet(tokenId));
      exoplanets[tokenId].lifeRate = newData;
    }



    function getExoplanet(uint256 tokenId) public view returns (
        uint8 lifeRate,
        bool canBePurchased,
        uint32 priceInExoTokens,
        uint32 numOfTokensBonusOnPurchase,
        string name,
        string nickname,
        string cryptoMatch,
        string scientificData,
        uint256 sellingPriceInEther,
        address owner) {

      ExoplanetRec storage exoplanet = exoplanets[tokenId];

      lifeRate = exoplanet.lifeRate;
      canBePurchased = exoplanet.canBePurchased;
      priceInExoTokens = exoplanet.priceInExoTokens;
      numOfTokensBonusOnPurchase = exoplanet.numOfTokensBonusOnPurchase;
      name = exoplanet.name;
      nickname = exoplanet.nickname;
      cryptoMatch = exoplanet.cryptoMatch;
      scientificData = exoplanet.scientificData;

      sellingPriceInEther = currentPrice[tokenId];
      owner = currentOwner[tokenId];
    }


    function implementsERC721() public pure returns (bool) {
      return true;
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
      owner = currentOwner[tokenId];
    }


    function transferUnownedPlanet(address newOwner, uint256 tokenId) public onlyCLevel {

      require(unownedPlanet(tokenId));

      require(newOwner != address(0));

      _transfer(currentOwner[tokenId], newOwner, tokenId);

      TokenSold(tokenId, currentPrice[tokenId], currentPrice[tokenId], address(this), newOwner, exoplanets[tokenId].name);
    }


    function purchase(uint256 tokenId) public payable whenNotPaused() presaleModeActive() {

      require(currentOwner[tokenId] != msg.sender);

      require(addressNotNull(msg.sender));

      uint256 planetPrice = currentPrice[tokenId];

      require(msg.value >= planetPrice);

      uint paymentPrcnt;
      uint stepPrcnt;

      if (planetPrice <= STEP_1) {
        paymentPrcnt = 93;
        stepPrcnt = 200;
      } else if (planetPrice <= STEP_2) {
        paymentPrcnt = 93;
        stepPrcnt = 150;
      } else if (planetPrice <= STEP_3) {
        paymentPrcnt = 93;
        stepPrcnt = 135;
      } else if (planetPrice <= STEP_4) {
        paymentPrcnt = 94;
        stepPrcnt = 125;
      } else if (planetPrice <= STEP_5) {
        paymentPrcnt = 94;
        stepPrcnt = 119;
      } else if (planetPrice <= STEP_6) {
        paymentPrcnt = 95;
        stepPrcnt = 117;
      } else if (planetPrice <= STEP_7) {
        paymentPrcnt = 95;
        stepPrcnt = 115;
      } else if (planetPrice <= STEP_8) {
        paymentPrcnt = 95;
        stepPrcnt = 113;
      } else {
        paymentPrcnt = 96;
        stepPrcnt = 110;
      }

      currentPrice[tokenId] = planetPrice.mul(stepPrcnt).div(100);

      uint256 payment = uint256(planetPrice.mul(paymentPrcnt).div(100));

      address seller = currentOwner[tokenId];

      if (seller != address(this)) {
        seller.transfer(payment);
      }

      _transfer(seller, msg.sender, tokenId);

      TokenSold(tokenId, planetPrice, currentPrice[tokenId], seller, msg.sender, exoplanets[tokenId].name);

    }



    function buyDirectInMarketplace(uint256 tokenId) public payable
                    whenNotPaused() afterPresaleMode() allowBuyDirect() {

      require(exoplanets[tokenId].canBePurchased);

      uint256 planetPrice = currentPrice[tokenId];

      require(msg.value >= planetPrice);

      address seller = currentOwner[tokenId];

      if (seller != address(this)) {
        seller.transfer(planetPrice);
      }

      _transfer(seller, msg.sender, tokenId);

      TokenSold(tokenId, planetPrice, currentPrice[tokenId], seller, msg.sender, exoplanets[tokenId].name);
    }


    function priceOf(uint256 tokenId) public view returns (uint256) {
      return currentPrice[tokenId];
    }


    function takeOwnership(uint256 tokenId) public whenNotPaused() {

      require(addressNotNull(msg.sender));

      require(approved(msg.sender, tokenId));

      _transfer(currentOwner[tokenId], msg.sender, tokenId);
    }

    function tokensOfOwner(address owner) public view returns(uint256[] ownerTokens) {
      uint256 tokenCount = balanceOf(owner);
      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalExoplanets = totalSupply();
        uint256 resultIndex = 0;

        uint256 exoplanetId;
        for (exoplanetId = 0; exoplanetId <= totalExoplanets; exoplanetId++) {
          if (currentOwner[exoplanetId] == owner) {
            result[resultIndex] = exoplanetId;
            resultIndex++;
          }
        }
        return result;
      }
    }

    function name() external view returns (string name) {
      name = CONTRACT_NAME;
    }

    function symbol() external view returns (string symbol) {
      symbol = CONTRACT_SYMBOL;
    }

    function tokenURI(uint256 _tokenId) external view returns (string uri) {
      uri = appendNumToString(BASE_URL, _tokenId);
    }

    function totalSupply() public view returns (uint256 total) {
      total = exoplanets.length;
    }

    function transfer(address to, uint256 tokenId) public whenNotPaused() {
      require(owns(msg.sender, tokenId));
      require(addressNotNull(to));
      _transfer(msg.sender, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused() {
      require(owns(from, tokenId));
      require(approved(msg.sender, tokenId));
      require(addressNotNull(to));
      _transfer(from, to, tokenId);
    }

    function addressNotNull(address addr) private pure returns (bool) {
      return addr != address(0);
    }

    function approved(address to, uint256 tokenId) private view returns (bool) {
      return approvedToTransfer[tokenId] == to;
    }


    function owns(address claimant, uint256 tokenId) private view returns (bool) {
      return claimant == currentOwner[tokenId];
    }

    function payout() public onlyCLevel {
      ceoAddress.transfer(this.balance);
    }

    function payoutPartial(uint256 amount) public onlyCLevel {
      require(amount <= this.balance);
      ceoAddress.transfer(amount);
    }


    function _transfer(address from, address to, uint256 tokenId) private {
      numOwnedTokens[to]++;

      exoplanets[tokenId].canBePurchased = false;

      currentOwner[tokenId] = to;

      if (from != address(0)) {
        numOwnedTokens[from]--;
        delete approvedToTransfer[tokenId];
      }

      Transfer(from, to, tokenId);
    }

    function appendNumToString(string baseUrl, uint256 tokenId) private pure returns (string) {
      string memory _b = numToString(tokenId);
      bytes memory bytes_a = bytes(baseUrl);
      bytes memory bytes_b = bytes(_b);
      string memory length_ab = new string(bytes_a.length + bytes_b.length);
      bytes memory bytes_c = bytes(length_ab);
      uint k = 0;
      for (uint i = 0; i < bytes_a.length; i++) {
        bytes_c[k++] = bytes_a[i];
      }
      for (i = 0; i < bytes_b.length; i++) {
        bytes_c[k++] = bytes_b[i];
      }
      return string(bytes_c);
    }

    function numToString(uint256 tokenId) private pure returns (string str) {
      uint uintVal = uint(tokenId);
      bytes32 bytes32Val = uintToBytes32(uintVal);
      return bytes32ToString(bytes32Val);
    }

    function uintToBytes32(uint v) private pure returns (bytes32 ret) {
      if (v == 0) {
          ret = &#39;0&#39;;
      }
      else {
          while (v > 0) {
              ret = bytes32(uint(ret) / (2 ** 8));
              ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
              v /= 10;
          }
      }
      return ret;
    }

}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a / b;
      return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}
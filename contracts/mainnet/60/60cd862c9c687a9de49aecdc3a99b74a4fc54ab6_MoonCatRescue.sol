pragma solidity ^0.4.13;

contract MoonCatRescue {
  enum Modes { Inactive, Disabled, Test, Live }

  Modes public mode = Modes.Inactive;

  address owner;

  bytes16 public imageGenerationCodeMD5 = 0xdbad5c08ec98bec48490e3c196eec683; // use this to verify mooncatparser.js the cat image data generation javascript file.

  string public name = "MoonCats";
  string public symbol = "?"; // unicode cat symbol
  uint8 public decimals = 0;

  uint256 public totalSupply = 25600;
  uint16 public remainingCats = 25600 - 256; // there will only ever be 25,000 cats
  uint16 public remainingGenesisCats = 256; // there can only be a maximum of 256 genesis cats
  uint16 public rescueIndex = 0;

  bytes5[25600] public rescueOrder;

  bytes32 public searchSeed = 0x0; // gets set with the immediately preceding blockhash when the contract is activated to prevent "premining"

  struct AdoptionOffer {
    bool exists;
    bytes5 catId;
    address seller;
    uint price;
    address onlyOfferTo;
  }

  struct AdoptionRequest{
    bool exists;
    bytes5 catId;
    address requester;
    uint price;
  }

  mapping (bytes5 => AdoptionOffer) public adoptionOffers;
  mapping (bytes5 => AdoptionRequest) public adoptionRequests;

  mapping (bytes5 => bytes32) public catNames;
  mapping (bytes5 => address) public catOwners;
  mapping (address => uint256) public balanceOf; //number of cats owned by a given address
  mapping (address => uint) public pendingWithdrawals;

  /* events */

  event CatRescued(address indexed to, bytes5 indexed catId);
  event CatNamed(bytes5 indexed catId, bytes32 catName);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event CatAdopted(bytes5 indexed catId, uint price, address indexed from, address indexed to);
  event AdoptionOffered(bytes5 indexed catId, uint price, address indexed toAddress);
  event AdoptionOfferCancelled(bytes5 indexed catId);
  event AdoptionRequested(bytes5 indexed catId, uint price, address indexed from);
  event AdoptionRequestCancelled(bytes5 indexed catId);
  event GenesisCatsAdded(bytes5[16] catIds);

  function MoonCatRescue() payable {
    owner = msg.sender;
    assert((remainingCats + remainingGenesisCats) == totalSupply);
    assert(rescueOrder.length == totalSupply);
    assert(rescueIndex == 0);
  }

  /* registers and validates cats that are found */
  function rescueCat(bytes32 seed) activeMode returns (bytes5) {
    require(remainingCats > 0); // cannot register any cats once supply limit is reached
    bytes32 catIdHash = keccak256(seed, searchSeed); // generate the prospective catIdHash
    require(catIdHash[0] | catIdHash[1] | catIdHash[2] == 0x0); // ensures the validity of the catIdHash
    bytes5 catId = bytes5((catIdHash & 0xffffffff) << 216); // one byte to indicate genesis, and the last 4 bytes of the catIdHash
    require(catOwners[catId] == 0x0); // if the cat is already registered, throw an error. All cats are unique.

    rescueOrder[rescueIndex] = catId;
    rescueIndex++;

    catOwners[catId] = msg.sender;
    balanceOf[msg.sender]++;
    remainingCats--;

    CatRescued(msg.sender, catId);

    return catId;
  }

  /* assigns a name to a cat, once a name is assigned it cannot be changed */
  function nameCat(bytes5 catId, bytes32 catName) onlyCatOwner(catId) {
    require(catNames[catId] == 0x0); // ensure the current name is empty; cats can only be named once
    require(!adoptionOffers[catId].exists); // cats cannot be named while they are up for adoption
    catNames[catId] = catName;
    CatNamed(catId, catName);
  }

  /* puts a cat up for anyone to adopt */
  function makeAdoptionOffer(bytes5 catId, uint price) onlyCatOwner(catId) {
    require(price > 0);
    adoptionOffers[catId] = AdoptionOffer(true, catId, msg.sender, price, 0x0);
    AdoptionOffered(catId, price, 0x0);
  }

  /* puts a cat up for a specific address to adopt */
  function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) onlyCatOwner(catId) isNotSender(to){
    adoptionOffers[catId] = AdoptionOffer(true, catId, msg.sender, price, to);
    AdoptionOffered(catId, price, to);
  }

  /* cancel an adoption offer */
  function cancelAdoptionOffer(bytes5 catId) onlyCatOwner(catId) {
    adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0);
    AdoptionOfferCancelled(catId);
  }

  /* accepts an adoption offer  */
  function acceptAdoptionOffer(bytes5 catId) payable {
    AdoptionOffer storage offer = adoptionOffers[catId];
    require(offer.exists);
    require(offer.onlyOfferTo == 0x0 || offer.onlyOfferTo == msg.sender);
    require(msg.value >= offer.price);
    if(msg.value > offer.price) {
      pendingWithdrawals[msg.sender] += (msg.value - offer.price); // if the submitted amount exceeds the price allow the buyer to withdraw the difference
    }
    transferCat(catId, catOwners[catId], msg.sender, offer.price);
  }

  /* transfer a cat directly without payment */
  function giveCat(bytes5 catId, address to) onlyCatOwner(catId) {
    transferCat(catId, msg.sender, to, 0);
  }

  /* requests adoption of a cat with an ETH offer */
  function makeAdoptionRequest(bytes5 catId) payable isNotSender(catOwners[catId]) {
    require(catOwners[catId] != 0x0); // the cat must be owned
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(msg.value > 0);
    require(msg.value > existingRequest.price);


    if(existingRequest.price > 0) {
      pendingWithdrawals[existingRequest.requester] += existingRequest.price;
    }

    adoptionRequests[catId] = AdoptionRequest(true, catId, msg.sender, msg.value);
    AdoptionRequested(catId, msg.value, msg.sender);

  }

  /* allows the owner of the cat to accept an adoption request */
  function acceptAdoptionRequest(bytes5 catId) onlyCatOwner(catId) {
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(existingRequest.exists);
    address existingRequester = existingRequest.requester;
    uint existingPrice = existingRequest.price;
    adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0); // the adoption request must be cancelled before calling transferCat to prevent refunding the requester.
    transferCat(catId, msg.sender, existingRequester, existingPrice);
  }

  /* allows the requester to cancel their adoption request */
  function cancelAdoptionRequest(bytes5 catId) {
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(existingRequest.exists);
    require(existingRequest.requester == msg.sender);

    uint price = existingRequest.price;

    adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);

    msg.sender.transfer(price);

    AdoptionRequestCancelled(catId);
  }


  function withdraw() {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

  /* owner only functions */

  /* disable contract before activation. A safeguard if a bug is found before the contract is activated */
  function disableBeforeActivation() onlyOwner inactiveMode {
    mode = Modes.Disabled;  // once the contract is disabled it&#39;s mode cannot be changed
  }

  /* activates the contract in *Live* mode which sets the searchSeed and enables rescuing */
  function activate() onlyOwner inactiveMode {
    searchSeed = block.blockhash(block.number - 1); // once the searchSeed is set it cannot be changed;
    mode = Modes.Live; // once the contract is activated it&#39;s mode cannot be changed
  }

  /* activates the contract in *Test* mode which sets the searchSeed and enables rescuing */
  function activateInTestMode() onlyOwner inactiveMode { //
    searchSeed = 0x5713bdf5d1c3398a8f12f881f0f03b5025b6f9c17a97441a694d5752beb92a3d; // once the searchSeed is set it cannot be changed;
    mode = Modes.Test; // once the contract is activated it&#39;s mode cannot be changed
  }

  /* add genesis cats in groups of 16 */
  function addGenesisCatGroup() onlyOwner activeMode {
    require(remainingGenesisCats > 0);
    bytes5[16] memory newCatIds;
    uint256 price = (17 - (remainingGenesisCats / 16)) * 300000000000000000;
    for(uint8 i = 0; i < 16; i++) {

      uint16 genesisCatIndex = 256 - remainingGenesisCats;
      bytes5 genesisCatId = (bytes5(genesisCatIndex) << 24) | 0xff00000ca7;

      newCatIds[i] = genesisCatId;

      rescueOrder[rescueIndex] = genesisCatId;
      rescueIndex++;
      balanceOf[0x0]++;
      remainingGenesisCats--;

      adoptionOffers[genesisCatId] = AdoptionOffer(true, genesisCatId, owner, price, 0x0);
    }
    GenesisCatsAdded(newCatIds);
  }


  /* aggregate getters */

  function getCatIds() constant returns (bytes5[]) {
    bytes5[] memory catIds = new bytes5[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      catIds[i] = rescueOrder[i];
    }
    return catIds;
  }


  function getCatNames() constant returns (bytes32[]) {
    bytes32[] memory names = new bytes32[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      names[i] = catNames[rescueOrder[i]];
    }
    return names;
  }

  function getCatOwners() constant returns (address[]) {
    address[] memory owners = new address[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      owners[i] = catOwners[rescueOrder[i]];
    }
    return owners;
  }

  function getCatOfferPrices() constant returns (uint[]) {
    uint[] memory catOffers = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 catId = rescueOrder[i];
      if(adoptionOffers[catId].exists && adoptionOffers[catId].onlyOfferTo == 0x0) {
        catOffers[i] = adoptionOffers[catId].price;
      }
    }
    return catOffers;
  }

  function getCatRequestPrices() constant returns (uint[]) {
    uint[] memory catRequests = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 catId = rescueOrder[i];
      catRequests[i] = adoptionRequests[catId].price;
    }
    return catRequests;
  }

  function getCatDetails(bytes5 catId) constant returns (bytes5 id,
                                                         address owner,
                                                         bytes32 name,
                                                         address onlyOfferTo,
                                                         uint offerPrice,
                                                         address requester,
                                                         uint requestPrice) {

    return (catId,
            catOwners[catId],
            catNames[catId],
            adoptionOffers[catId].onlyOfferTo,
            adoptionOffers[catId].price,
            adoptionRequests[catId].requester,
            adoptionRequests[catId].price);
  }

  /* modifiers */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier inactiveMode() {
    require(mode == Modes.Inactive);
    _;
  }

  modifier activeMode() {
    require(mode == Modes.Live || mode == Modes.Test);
    _;
  }

  modifier onlyCatOwner(bytes5 catId) {
    require(catOwners[catId] == msg.sender);
    _;
  }

  modifier isNotSender(address a) {
    require(msg.sender != a);
    _;
  }

  /* transfer helper */
  function transferCat(bytes5 catId, address from, address to, uint price) private {
    catOwners[catId] = to;
    balanceOf[from]--;
    balanceOf[to]++;
    adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0); // cancel any existing adoption offer when cat is transferred

    AdoptionRequest storage request = adoptionRequests[catId]; //if the recipient has a pending adoption request, cancel it
    if(request.requester == to) {
      pendingWithdrawals[to] += request.price;
      adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);
    }

    pendingWithdrawals[from] += price;

    Transfer(from, to, 1);
    CatAdopted(catId, price, from, to);
  }

}
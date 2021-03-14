/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity ^0.4.22;

contract MoonDogRescue {
  enum Modes { Inactive, Disabled, Test, Live }

  Modes public mode = Modes.Inactive;

  address owner;

  bytes16 public imageGenerationCodeMD5 = 0xdbad5c08ec98bec48490e3c196eec683; // use this to verify moondogparser.js the dog image data generation javascript file.

  string public name = "PussyTestDog";
  string public symbol = "PTD123"; // unicode dog symbol
  uint8 public decimals = 0;

  uint256 public totalSupply = 25600;
  uint16 public remainingDogs = 25600 - 256; // there will only ever be 25,000 dogs
  uint16 public remainingGenesisDogs = 256; // there can only be a maximum of 256 genesis dogs
  uint16 public rescueIndex = 0;

  bytes5[25600] public rescueOrder;

  bytes32 public searchSeed = 0x0; // gets set with the immediately preceding blockhash when the contract is activated to prevent "premining"

  struct AdoptionOffer {
    bool exists;
    bytes5 dogId;
    address seller;
    uint price;
    address onlyOfferTo;
  }

  struct AdoptionRequest{
    bool exists;
    bytes5 dogId;
    address requester;
    uint price;
  }

  mapping (bytes5 => AdoptionOffer) public adoptionOffers;
  mapping (bytes5 => AdoptionRequest) public adoptionRequests;

  mapping (bytes5 => bytes32) public dogNames;
  mapping (bytes5 => address) public dogOwners;
  mapping (address => uint256) public balanceOf; //number of dogs owned by a given address
  mapping (address => uint) public pendingWithdrawals;

  /* events */

  event DogRescued(address indexed to, bytes5 indexed dogId);
  event DogNamed(bytes5 indexed dogId, bytes32 dogName);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event DogAdopted(bytes5 indexed dogId, uint price, address indexed from, address indexed to);
  event AdoptionOffered(bytes5 indexed dogId, uint price, address indexed toAddress);
  event AdoptionOfferCancelled(bytes5 indexed dogId);
  event AdoptionRequested(bytes5 indexed dogId, uint price, address indexed from);
  event AdoptionRequestCancelled(bytes5 indexed dogId);
  event GenesisDogsAdded(bytes5[16] dogIds);

  function MoonDogRescue() public payable {
    owner = msg.sender;
    assert((remainingDogs + remainingGenesisDogs) == totalSupply);
    assert(rescueOrder.length == totalSupply);
    assert(rescueIndex == 0);
  }

  /* registers and validates dogs that are found */
  function rescueDog(bytes32 seed) public activeMode returns (bytes5) {
    require(remainingDogs > 0); // cannot register any dogs once supply limit is reached
    bytes32 dogIdHash = keccak256(seed, searchSeed); // generate the prospective dogIdHash
    require(dogIdHash[0] | dogIdHash[1] | dogIdHash[2] == 0x0); // ensures the validity of the dogIdHash
    bytes5 dogId = bytes5((dogIdHash & 0xffffffff) << 216); // one byte to indidoge genesis, and the last 4 bytes of the dogIdHash
    require(dogOwners[dogId] == 0x0); // if the dog is already registered, throw an error. All dogs are unique.

    rescueOrder[rescueIndex] = dogId;
    rescueIndex++;

    dogOwners[dogId] = msg.sender;
    balanceOf[msg.sender]++;
    remainingDogs--;

    emit DogRescued(msg.sender, dogId);

    return dogId;
  }

  /* assigns a name to a dog, once a name is assigned it cannot be changed */
  function nameDog(bytes5 dogId, bytes32 dogName) public onlyDogOwner(dogId) {
    require(dogNames[dogId] == 0x0); // ensure the current name is empty; dogs can only be named once
    require(!adoptionOffers[dogId].exists); // dogs cannot be named while they are up for adoption
    dogNames[dogId] = dogName;
    emit DogNamed(dogId, dogName);
  }

  /* puts a dog up for anyone to adopt */
  function makeAdoptionOffer(bytes5 dogId, uint price) public onlyDogOwner(dogId) {
    require(price > 0);
    adoptionOffers[dogId] = AdoptionOffer(true, dogId, msg.sender, price, 0x0);
    emit AdoptionOffered(dogId, price, 0x0);
  }

  /* puts a dog up for a specific address to adopt */
  function makeAdoptionOfferToAddress(bytes5 dogId, uint price, address to) public onlyDogOwner(dogId) isNotSender(to){
    adoptionOffers[dogId] = AdoptionOffer(true, dogId, msg.sender, price, to);
    emit AdoptionOffered(dogId, price, to);
  }

  /* cancel an adoption offer */
  function cancelAdoptionOffer(bytes5 dogId) public onlyDogOwner(dogId) {
    adoptionOffers[dogId] = AdoptionOffer(false, dogId, 0x0, 0, 0x0);
    emit AdoptionOfferCancelled(dogId);
  }

  /* accepts an adoption offer  */
  function acceptAdoptionOffer(bytes5 dogId) public payable {
    AdoptionOffer storage offer = adoptionOffers[dogId];
    require(offer.exists);
    require(offer.onlyOfferTo == 0x0 || offer.onlyOfferTo == msg.sender);
    require(msg.value >= offer.price);
    if(msg.value > offer.price) {
      pendingWithdrawals[msg.sender] += (msg.value - offer.price); // if the submitted amount exceeds the price allow the buyer to withdraw the difference
    }
    transferDog(dogId, dogOwners[dogId], msg.sender, offer.price);
  }

  /* transfer a dog directly without payment */
  function giveDog(bytes5 dogId, address to) public onlyDogOwner(dogId) {
    transferDog(dogId, msg.sender, to, 0);
  }

  /* requests adoption of a dog with an ETH offer */
  function makeAdoptionRequest(bytes5 dogId) public payable isNotSender(dogOwners[dogId]) {
    require(dogOwners[dogId] != 0x0); // the dog must be owned
    AdoptionRequest storage existingRequest = adoptionRequests[dogId];
    require(msg.value > 0);
    require(msg.value > existingRequest.price);


    if(existingRequest.price > 0) {
      pendingWithdrawals[existingRequest.requester] += existingRequest.price;
    }

    adoptionRequests[dogId] = AdoptionRequest(true, dogId, msg.sender, msg.value);
    emit AdoptionRequested(dogId, msg.value, msg.sender);

  }

  /* allows the owner of the dog to accept an adoption request */
  function acceptAdoptionRequest(bytes5 dogId) public onlyDogOwner(dogId) {
    AdoptionRequest storage existingRequest = adoptionRequests[dogId];
    require(existingRequest.exists);
    address existingRequester = existingRequest.requester;
    uint existingPrice = existingRequest.price;
    adoptionRequests[dogId] = AdoptionRequest(false, dogId, 0x0, 0); // the adoption request must be cancelled before calling transferDog to prevent refunding the requester.
    transferDog(dogId, msg.sender, existingRequester, existingPrice);
  }

  /* allows the requester to cancel their adoption request */
  function cancelAdoptionRequest(bytes5 dogId) public {
    AdoptionRequest storage existingRequest = adoptionRequests[dogId];
    require(existingRequest.exists);
    require(existingRequest.requester == msg.sender);

    uint price = existingRequest.price;

    adoptionRequests[dogId] = AdoptionRequest(false, dogId, 0x0, 0);

    msg.sender.transfer(price);

    emit AdoptionRequestCancelled(dogId);
  }


  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

  /* owner only functions */

  /* disable contract before activation. A safeguard if a bug is found before the contract is activated */
  function disableBeforeActivation() public onlyOwner inactiveMode {
    mode = Modes.Disabled;  // once the contract is disabled it's mode cannot be changed
  }

  /* activates the contract in *Live* mode which sets the searchSeed and enables rescuing */
  function activate() public onlyOwner inactiveMode {
    searchSeed = 0x8363e7eaae8e35b1c2db100a7b0fb9db1bc604a35ce1374d882690d0b1d888e2; // once the searchSeed is set it cannot be changed;
    mode = Modes.Live; // once the contract is activated it's mode cannot be changed
  }

  /* activates the contract in *Test* mode which sets the searchSeed and enables rescuing */
  function activateInTestMode() public onlyOwner inactiveMode { //
    searchSeed = 0x5713bdf5d1c3398a8f12f881f0f03b5025b6f9c17a97441a694d5752beb92a3d; // once the searchSeed is set it cannot be changed;
    mode = Modes.Test; // once the contract is activated it's mode cannot be changed
  }

  /* add genesis dogs in groups of 16 */
  function addGenesisDogGroup() public onlyOwner activeMode {
    require(remainingGenesisDogs > 0);
    bytes5[16] memory newDogIds;
    uint256 price = (17 - (remainingGenesisDogs / 16)) * 300000000000000000;
    for(uint8 i = 0; i < 16; i++) {

      uint16 genesisDogIndex = 256 - remainingGenesisDogs;
      bytes5 genesisDogId = (bytes5(genesisDogIndex) << 24) | 0xff00000ca7;

      newDogIds[i] = genesisDogId;

      rescueOrder[rescueIndex] = genesisDogId;
      rescueIndex++;
      balanceOf[0x0]++;
      remainingGenesisDogs--;

      adoptionOffers[genesisDogId] = AdoptionOffer(true, genesisDogId, owner, price, 0x0);
    }
    emit GenesisDogsAdded(newDogIds);
  }


  /* aggregate getters */

  function getDogIds() public constant returns (bytes5[]) {
    bytes5[] memory dogIds = new bytes5[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      dogIds[i] = rescueOrder[i];
    }
    return dogIds;
  }


  function getDogNames() public constant returns (bytes32[]) {
    bytes32[] memory names = new bytes32[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      names[i] = dogNames[rescueOrder[i]];
    }
    return names;
  }

  function getDogOwners() public constant returns (address[]) {
    address[] memory owners = new address[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      owners[i] = dogOwners[rescueOrder[i]];
    }
    return owners;
  }

  function getDogOfferPrices() public constant returns (uint[]) {
    uint[] memory dogOffers = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 dogId = rescueOrder[i];
      if(adoptionOffers[dogId].exists && adoptionOffers[dogId].onlyOfferTo == 0x0) {
        dogOffers[i] = adoptionOffers[dogId].price;
      }
    }
    return dogOffers;
  }

  function getDogRequestPrices() public constant returns (uint[]) {
    uint[] memory dogRequests = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 dogId = rescueOrder[i];
      dogRequests[i] = adoptionRequests[dogId].price;
    }
    return dogRequests;
  }

  function getDogDetails(bytes5 dogId) public constant returns (bytes5 id,
                                                         address owner,
                                                         bytes32 name,
                                                         address onlyOfferTo,
                                                         uint offerPrice,
                                                         address requester,
                                                         uint requestPrice) {

    return (dogId,
            dogOwners[dogId],
            dogNames[dogId],
            adoptionOffers[dogId].onlyOfferTo,
            adoptionOffers[dogId].price,
            adoptionRequests[dogId].requester,
            adoptionRequests[dogId].price);
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

  modifier onlyDogOwner(bytes5 dogId) {
    require(dogOwners[dogId] == msg.sender);
    _;
  }

  modifier isNotSender(address a) {
    require(msg.sender != a);
    _;
  }

  /* transfer helper */
  function transferDog(bytes5 dogId, address from, address to, uint price) private {
    dogOwners[dogId] = to;
    balanceOf[from]--;
    balanceOf[to]++;
    adoptionOffers[dogId] = AdoptionOffer(false, dogId, 0x0, 0, 0x0); // cancel any existing adoption offer when dog is transferred

    AdoptionRequest storage request = adoptionRequests[dogId]; //if the recipient has a pending adoption request, cancel it
    if(request.requester == to) {
      pendingWithdrawals[to] += request.price;
      adoptionRequests[dogId] = AdoptionRequest(false, dogId, 0x0, 0);
    }

    pendingWithdrawals[from] += price;

    emit Transfer(from, to, 1);
    emit DogAdopted(dogId, price, from, to);
  }

}
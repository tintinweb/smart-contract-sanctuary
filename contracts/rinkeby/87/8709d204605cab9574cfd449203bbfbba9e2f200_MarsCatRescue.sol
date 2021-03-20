/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-18
*/

pragma solidity ^0.4.23;

contract MarsCatRescue {
    enum Modes {Inactive, Disabled, Test, Live}

    Modes public mode = Modes.Inactive;
    string public website = "marscatrescue.surge.sh";
    address public owner;
    string public name = "MarsCats";
    string public symbol = "🐱"; // unicode cat symbol
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
        uint256 price;
        address onlyOfferTo;
    }

    struct AdoptionRequest {
        bool exists;
        bytes5 catId;
        address requester;
        uint256 price;
    }

    mapping(bytes5 => AdoptionOffer) public adoptionOffers;
    mapping(bytes5 => AdoptionRequest) public adoptionRequests;

    mapping(bytes5 => bytes32) public catNames;
    mapping(bytes5 => address) public catOwners;
    mapping(address => uint256) public balanceOf; //number of cats owned by a given address
    mapping(address => uint256) public pendingWithdrawals;

    /* events */

    event CatRescued(address indexed to, bytes5 indexed catId);
    event CatNamed(bytes5 indexed catId, bytes32 catName);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event CatAdopted(
        bytes5 indexed catId,
        uint256 price,
        address indexed from,
        address indexed to
    );
    event AdoptionOffered(
        bytes5 indexed catId,
        uint256 price,
        address indexed toAddress
    );
    event AdoptionOfferCancelled(bytes5 indexed catId);
    event AdoptionRequested(
        bytes5 indexed catId,
        uint256 price,
        address indexed from
    );
    event AdoptionRequestCancelled(bytes5 indexed catId);
    event GenesisCatsAdded(bytes5[256] catIds);
    constructor()public{
        owner = msg.sender;
        assert((remainingCats + remainingGenesisCats) == totalSupply);
        assert(rescueOrder.length == totalSupply);
        assert(rescueIndex == 0);
    }

    /* registers and validates cats that are found */
    function rescueCat(bytes32 seed) activeMode public returns (bytes5) {
        require(remainingCats > 0,"All cats has been rescued"); // cannot register any cats once supply limit is reached
        bytes32 catIdHash = keccak256(seed, searchSeed); // generate the prospective catIdHash
        require(catIdHash[0] | catIdHash[1] | catIdHash[2] == 0x0,"catIdHas is not valid"); // ensures the validity of the catIdHash
        bytes5 catId = bytes5((catIdHash & 0xffffffff) << 216); // one byte to indicate genesis, and the last 4 bytes of the catIdHash
        require(catOwners[catId] == 0x0,"Cat already owned"); // if the cat is already registered, throw an error. All cats are unique.

        rescueOrder[rescueIndex] = catId;
        rescueIndex++;

        catOwners[catId] = msg.sender;
        balanceOf[msg.sender]++;
        remainingCats--;
        transferCat(catId, msg.sender, msg.sender, 0);
        emit CatRescued(msg.sender, catId);

        return catId;
    }

    /* assigns a name to a cat, once a name is assigned it cannot be changed */
    function nameCat(bytes5 catId, bytes32 catName)public onlyCatOwner(catId) {
        require(catNames[catId] == 0x0, "Already named"); // ensure the current name is empty; cats can only be named once
        require(!adoptionOffers[catId].exists,"Cat is on adoption offer, cancel it to name the cat"); // cats cannot be named while they are up for adoption
        catNames[catId] = catName;
        emit CatNamed(catId, catName);
    }

    /* puts a cat up for anyone to adopt */
    function makeAdoptionOffer(bytes5 catId, uint256 price)public
        onlyCatOwner(catId)
    {
        require(price > 0, "Price cannot be zero");
        adoptionOffers[catId] = AdoptionOffer(
            true,
            catId,
            msg.sender,
            price,
            0x0
        );
        emit AdoptionOffered(catId, price, 0x0);
    }

    /* puts a cat up for a specific address to adopt */
    function makeAdoptionOfferToAddress(
        bytes5 catId,
        uint256 price,
        address to
    )public onlyCatOwner(catId) isNotSender(to) {
        adoptionOffers[catId] = AdoptionOffer(
            true,
            catId,
            msg.sender,
            price,
            to
        );
       emit  AdoptionOffered(catId, price, to);
    }

    /* cancel an adoption offer */
    function cancelAdoptionOffer(bytes5 catId)public onlyCatOwner(catId) {
        adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0);
        emit AdoptionOfferCancelled(catId);
    }

    /* accepts an adoption offer  */
    function acceptAdoptionOffer(bytes5 catId)public payable {
        AdoptionOffer storage offer = adoptionOffers[catId];
        require(offer.exists,"The cat is not available, maybe it's already adopted");
        require(offer.onlyOfferTo == 0x0 || offer.onlyOfferTo == msg.sender,"Is not offering to you");
        require(msg.value >= offer.price,"Price is too low");
        if (msg.value > offer.price) {
            pendingWithdrawals[msg.sender] += (msg.value - offer.price); // if the submitted amount exceeds the price allow the buyer to withdraw the difference
        }
        transferCat(catId, catOwners[catId], msg.sender, offer.price);
    }

    /* transfer a cat directly without payment */
    function giveCat(bytes5 catId, address to) public onlyCatOwner(catId) {
        transferCat(catId, msg.sender, to, 0);
    }

    /* requests adoption of a cat with an ETH offer */
    function makeAdoptionRequest(bytes5 catId)
    public
        payable
        isNotSender(catOwners[catId])
    {
        require(catOwners[catId] != 0x0, "Not your cat!"); // the cat must be owned
        AdoptionRequest storage existingRequest = adoptionRequests[catId];
        require(msg.value > 0,"Price can't be 0");
        require(msg.value > existingRequest.price,"Price must be more than current");

        if (existingRequest.price > 0) {
            pendingWithdrawals[existingRequest.requester] += existingRequest
                .price;
        }

        adoptionRequests[catId] = AdoptionRequest(
            true,
            catId,
            msg.sender,
            msg.value
        );
        emit AdoptionRequested(catId, msg.value, msg.sender);
    }

    /* allows the owner of the cat to accept an adoption request */
    function acceptAdoptionRequest(bytes5 catId)public onlyCatOwner(catId) {
        AdoptionRequest storage existingRequest = adoptionRequests[catId];
        require(existingRequest.exists,"There is no request for this cat");
        address existingRequester = existingRequest.requester;
        uint256 existingPrice = existingRequest.price;
        adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0); // the adoption request must be cancelled before calling transferCat to prevent refunding the requester.
        transferCat(catId, msg.sender, existingRequester, existingPrice);
    }

    /* allows the requester to cancel their adoption request */
    function cancelAdoptionRequest(bytes5 catId)public {
        AdoptionRequest storage existingRequest = adoptionRequests[catId];
        require(existingRequest.exists,"There is no request for this cat");
        require(existingRequest.requester == msg.sender,"Not yout cat");

        uint256 price = existingRequest.price;

        adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);

        msg.sender.transfer(price);

        emit AdoptionRequestCancelled(catId);
    }

    function withdraw()public {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    /* owner only functions */

    /* disable contract before activation. A safeguard if a bug is found before the contract is activated */
    function disableBeforeActivation()public onlyOwner inactiveMode {
        mode = Modes.Disabled; // once the contract is disabled it's mode cannot be changed
    }

    function setOwner(address newOwner)public onlyOwner {
        owner = newOwner;
    }

    /* activates the contract in *Live* mode which sets the searchSeed and enables rescuing */
    function activate()public onlyOwner inactiveMode {
        searchSeed = blockhash(block.number - 1); // once the searchSeed is set it cannot be changed;
        mode = Modes.Live; // once the contract is activated it's mode cannot be changed
    }

    /* activates the contract in *Test* mode which sets the searchSeed and enables rescuing */
    function activateInTestMode()public onlyOwner inactiveMode {
        //
        searchSeed = 0x5713bdf5d1c3398a8f12f881f0f03b5025b6f9c17a97441a694d5752beb92a3d; // once the searchSeed is set it cannot be changed;
        mode = Modes.Test; // once the contract is activated it's mode cannot be changed
    }

   
    function addGenesisCatGroup(uint8 count)public onlyOwner activeMode {
        require(remainingGenesisCats > 0,"No genesis left");
        require(count<=256,"Max count is 256");
        bytes5[256] memory newCatIds;
        uint256 price = 2000000000000000000;
        for (uint8 i = 0; i < count; i++) {
            uint16 genesisCatIndex = 256 - remainingGenesisCats;
            bytes5 genesisCatId = (bytes5(genesisCatIndex) << 24) | 0xff00000ca7;

            newCatIds[i] = genesisCatId;

            rescueOrder[rescueIndex] = genesisCatId;
            rescueIndex++;

            catOwners[genesisCatId] = msg.sender;
            balanceOf[msg.sender]++;

            remainingGenesisCats--;

            adoptionOffers[genesisCatId] = AdoptionOffer(
                true,
                genesisCatId,
                owner,
                price,
                0x0
            );
        }
        emit GenesisCatsAdded(newCatIds);
    }

    /* aggregate getters */

    function getCatIds() public constant returns (bytes5[]) {
        bytes5[] memory catIds = new bytes5[](rescueIndex);
        for (uint256 i = 0; i < rescueIndex; i++) {
            catIds[i] = rescueOrder[i];
        }
        return catIds;
    }
    function getCatNames() public constant returns (bytes32[]) {
        bytes32[] memory names = new bytes32[](rescueIndex);
        for (uint256 i = 0; i < rescueIndex; i++) {
            names[i] = catNames[rescueOrder[i]];
        }
        return names;
    }

    function getCatOwners() public constant returns (address[]) {
        address[] memory owners = new address[](rescueIndex);
        for (uint256 i = 0; i < rescueIndex; i++) {
            owners[i] = catOwners[rescueOrder[i]];
        }
        return owners;
    }

    function getCatOfferPrices()public  constant returns (uint256[]) {
        uint256[] memory catOffers = new uint256[](rescueIndex);
        for (uint256 i = 0; i < rescueIndex; i++) {
            bytes5 catId = rescueOrder[i];
            if (
                adoptionOffers[catId].exists &&
                adoptionOffers[catId].onlyOfferTo == 0x0
            ) {
                catOffers[i] = adoptionOffers[catId].price;
            }
        }
        return catOffers;
    }

    function getCatRequestPrices() public constant returns (uint256[]) {
        uint256[] memory catRequests = new uint256[](rescueIndex);
        for (uint256 i = 0; i < rescueIndex; i++) {
            bytes5 catId = rescueOrder[i];
            catRequests[i] = adoptionRequests[catId].price;
        }
        return catRequests;
    }

    function getCatDetails(bytes5 catId)
        constant
        public
        returns (
            bytes5 id,
            address theOwner,
            bytes32 catName,
            address onlyOfferTo,
            uint256 offerPrice,
            address requester,
            uint256 requestPrice
        )
    {
        return (
            catId,
            catOwners[catId],
            catNames[catId],
            adoptionOffers[catId].onlyOfferTo,
            adoptionOffers[catId].price,
            adoptionRequests[catId].requester,
            adoptionRequests[catId].price
        );
    }
     /* transfer helper */
    function transferCat(
        bytes5 catId,
        address from,
        address to,
        uint256 price
    ) private {
        catOwners[catId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
        adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0); // cancel any existing adoption offer when cat is transferred

        AdoptionRequest storage request = adoptionRequests[catId]; //if the recipient has a pending adoption request, cancel it
        if (request.requester == to) {
            pendingWithdrawals[to] += request.price;
            adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);
        }

        pendingWithdrawals[from] += price;

        emit Transfer(from, to, 1);
        emit CatAdopted(catId, price, from, to);
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

   
}
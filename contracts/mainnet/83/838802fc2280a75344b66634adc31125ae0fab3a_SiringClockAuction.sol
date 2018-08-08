pragma solidity ^0.4.18;

contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract ERC721 {
    
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract GeneScienceInterface {
    
    function isGeneScience() public pure returns (bool);

    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);
}


contract VariationInterface {

    function isVariation() public pure returns(bool);
    
    function createVariation(uint256 _gene, uint256 _totalSupply) public returns (uint8);
    
    function registerVariation(uint256 _dogId, address _owner) public;
}


contract LotteryInterface {
    
    function isLottery() public pure returns (bool);

    function checkLottery(uint256 genes) public pure returns (uint8 lotclass);
    
    function registerLottery(uint256 _dogId) public payable returns (uint8);

    function getCLottery() 
        public 
        view 
        returns (
            uint8[7]        luckyGenes1,
            uint256         totalAmount1,
            uint256         openBlock1,
            bool            isReward1,
            uint256         term1,
            uint8           currentGenes1,
            uint256         tSupply,
            uint256         sPoolAmount1,
            uint256[]       reward1
        );
}


contract DogAccessControl {
    
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == cooAddress || msg.sender == ceoAddress || msg.sender == cfoAddress);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}


contract DogBase is DogAccessControl {

    event Birth(address owner, uint256 dogId, uint256 matronId, uint256 sireId, uint256 genes, uint16 generation, uint8 variation, uint256 gen0, uint256 birthTime, uint256 income, uint16 cooldownIndex);

    event Transfer(address from, address to, uint256 tokenId);

    struct Dog {
        
        uint256 genes;

        uint256 birthTime;

        uint64 cooldownEndBlock;

        uint32 matronId;

        uint32 sireId;

        uint32 siringWithId;

        uint16 cooldownIndex;

        uint16 generation;

        uint8  variation;

        uint256 gen0;
    }

    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(24 hours),
        uint32(2 days),
        uint32(3 days),
        uint32(5 days)
    ];

    uint256 public secondsPerBlock = 15;

    Dog[] dogs;

    mapping (uint256 => address) dogIndexToOwner;

    mapping (address => uint256) ownershipTokenCount;

    mapping (uint256 => address) public dogIndexToApproved;

    mapping (uint256 => address) public sireAllowedToAddress;

    SaleClockAuction public saleAuction;

    SiringClockAuction public siringAuction;

    VariationInterface public variation;

    LotteryInterface public lottery;

    uint256 public autoBirthFee = 7500 szabo;

    uint256 public gen0Profit = 500 szabo;
    
    uint256 public creationProfit = 1000 szabo;

    mapping (address => uint256) public profit;

    function _sendMoney(address _to, uint256 _money) internal {
        spendMoney += _money;
        require(address(this).balance >= spendMoney);
        profit[_to] += _money;
    }

    function sendMoney(address _to, uint256 _money) external {
        require(msg.sender == address(lottery) || msg.sender == address(variation));
        _sendMoney(_to, _money);
    }

    event Withdraw(address _owner, uint256 _value);

    function withdraw() public {
        uint256 value = profit[msg.sender];
        require(value > 0);
        msg.sender.transfer(value);
        spendMoney -= value;
        delete profit[msg.sender];

        Withdraw(msg.sender, value);
    }

    uint256 public spendMoney;

    function setGen0Profit(uint256 _value) public onlyCEO {        
        uint256 ration = _value * 100 / autoBirthFee;
        require(ration > 0);
        require(_value <= 100);
        gen0Profit = _value;
    }

    function setCreationProfit(uint256 _value) public onlyCEO {        
        uint256 ration = _value * 100 / autoBirthFee;
        require(ration > 0);
        require(_value <= 100);
        creationProfit = _value;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        dogIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete sireAllowedToAddress[_tokenId];
            delete dogIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _createDog(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner,
        uint8 _variation,
        uint256 _gen0,
        bool _isGen0Siring
    )
        internal
        returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Dog memory _dog = Dog({
            genes: _genes,
            birthTime: block.number,
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation),
            variation : uint8(_variation),
            gen0 : _gen0
        });
        uint256 newDogId = dogs.push(_dog) - 1;

        require(newDogId < 23887872);

        Birth(
            _owner,
            newDogId,
            uint256(_dog.matronId),
            uint256(_dog.sireId),
            _dog.genes,
            uint16(_generation),
            _variation,
            _gen0,
            block.number,
            _isGen0Siring ? 0 : gen0Profit,
            cooldownIndex
        );

        _transfer(0, _owner, newDogId);

        return newDogId;
    }

    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}


contract DogOwnership is DogBase, ERC721 {

    string public constant name = "HelloDog";
    string public constant symbol = "HD";

    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
    bytes4(keccak256("transferFrom(address,address,uint256)"));

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dogIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dogIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        dogIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return dogs.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = dogIndexToOwner[_tokenId];

        require(owner != address(0));
    }
}


contract DogBreeding is DogOwnership {

    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 matronCooldownEndBlock, uint256 sireCooldownEndBlock, uint256 matronCooldownIndex, uint256 sireCooldownIndex);

    uint256 public pregnantDogs;

    GeneScienceInterface public geneScience;

    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

        require(candidateContract.isGeneScience());

        geneScience = candidateContract;
    }

    function _isReadyToBreed(Dog _dog) internal view returns (bool) {
        return (_dog.siringWithId == 0) && (_dog.cooldownEndBlock <= uint64(block.number));
    }

    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = dogIndexToOwner[_matronId];
        address sireOwner = dogIndexToOwner[_sireId];

        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    function _triggerCooldown(Dog storage _dog) internal {
        _dog.cooldownEndBlock = uint64((cooldowns[_dog.cooldownIndex]/secondsPerBlock) + block.number);

        if (_dog.cooldownIndex < 13) {
            _dog.cooldownIndex += 1;
        }
    }

    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    function setAutoBirthFee(uint256 val) external onlyCEO {
        require(val > 0);
        autoBirthFee = val;
    }

    function _isReadyToGiveBirth(Dog _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

    function isReadyToBreed(uint256 _dogId)
        public
        view
        returns (bool)
    {
        require(_dogId > 1);
        Dog storage dog = dogs[_dogId];
        return _isReadyToBreed(dog);
    }

    function isPregnant(uint256 _dogId)
        public
        view
        returns (bool)
    {
        return dogs[_dogId].siringWithId != 0;
    }

    function _isValidMatingPair(
        Dog storage _matron,
        uint256 _matronId,
        Dog storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        if (_matronId == _sireId) {
            return false;
        }

        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Dog storage matron = dogs[_matronId];
        Dog storage sire = dogs[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }
    
    function getOwner(uint256 _tokenId) public view returns(address){
        address owner = dogIndexToOwner[_tokenId];
        if(owner == address(saleAuction)){
            return saleAuction.getSeller(_tokenId);
        } else if (owner == address(siringAuction)){
            return siringAuction.getSeller(_tokenId);
        } else if (owner == address(this)){
            return address(0);
        }
        return owner;
    }

    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        require(_matronId > 1);
        require(_sireId > 1);
        
        Dog storage sire = dogs[_sireId];
        Dog storage matron = dogs[_matronId];

        require(sire.variation == 0);
        require(matron.variation == 0);

        if (matron.generation > 0) {
            var(,,openBlock,,,,,,) = lottery.getCLottery();
            if (matron.birthTime < openBlock) {
                require(lottery.checkLottery(matron.genes) == 100);
            }
        }

        matron.siringWithId = uint32(_sireId);

        _triggerCooldown(sire);
        _triggerCooldown(matron);

        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        pregnantDogs++;

        cfoAddress.transfer(autoBirthFee);

        address owner = getOwner(0);
        if(owner != address(0)){
            _sendMoney(owner, creationProfit);
        }
        owner = getOwner(1);
        if(owner != address(0)){
            _sendMoney(owner, creationProfit);
        }

        if (matron.generation > 0) {
            owner = getOwner(matron.gen0);
            if(owner != address(0)){
                _sendMoney(owner, gen0Profit);
            }
        }

        Pregnant(dogIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock, sire.cooldownEndBlock, matron.cooldownIndex, sire.cooldownIndex);
    }

    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {        
        uint256 totalFee = autoBirthFee + creationProfit + creationProfit;
        Dog storage matron = dogs[_matronId];
        if (matron.generation > 0) {
            totalFee += gen0Profit;
        }

        require(msg.value >= totalFee);

        require(_owns(msg.sender, _matronId));

        require(_isSiringPermitted(_sireId, _matronId));

        require(_isReadyToBreed(matron));

        Dog storage sire = dogs[_sireId];

        require(_isReadyToBreed(sire));

        require(_isValidMatingPair(matron, _matronId, sire, _sireId));

        _breedWith(_matronId, _sireId);

        uint256 breedExcess = msg.value - totalFee;
        if (breedExcess > 0) {
            msg.sender.transfer(breedExcess);
        }
    }

    bool public giveBirthByUser = false;

    function setGiveBirthType(bool _value) public onlyCEO {
        giveBirthByUser = _value;
    }

    function giveBirth(uint256 _matronId, uint256 genes)
        external
        whenNotPaused
        returns(uint256)
    {
        Dog storage matron = dogs[_matronId];

        require(matron.birthTime != 0);

        require(_isReadyToGiveBirth(matron));

        uint256 sireId = matron.siringWithId;
        Dog storage sire = dogs[sireId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 gen0 = matron.generation == 0 ? _matronId : matron.gen0;

        uint256 childGenes = genes;
        if(giveBirthByUser){
            require(address(geneScience) != address(0));
            childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);
        } else {
            require(msg.sender == ceoAddress || msg.sender == cooAddress || msg.sender == cfoAddress);
        }
        
        address owner = dogIndexToOwner[_matronId];

        uint8 _variation = variation.createVariation(childGenes, dogs.length);

        bool isGen0Siring = matron.generation == 0;

        uint256 kittenId = _createDog(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner, _variation, gen0, isGen0Siring);

        delete matron.siringWithId;

        pregnantDogs--;
       
        if(_variation != 0){              
            variation.registerVariation(kittenId, owner);      
            _transfer(owner, address(variation), kittenId);
        }

        return kittenId;
    }
}


contract ClockAuctionBase {

    struct Auction {
        
        address seller;
        
        uint128 startingPrice;
        
        uint128 endingPrice;
        
        uint64 duration;
        
        uint64 startedAt;
    }

    ERC721 public nonFungibleContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address _to)
        internal
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = _currentPrice(auction);
        uint256 auctioneerCut = computeCut(price);

        uint256 fee = 0;
        if (_tokenId == 0 || _tokenId == 1) {
            fee = price / 5;
        }        
        require((_bidAmount + auctioneerCut + fee) >= price);

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if (price > 0) {
            uint256 sellerProceeds = price - auctioneerCut - fee;

            seller.transfer(sellerProceeds);
        }

        AuctionSuccessful(_tokenId, price, _to);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function computeCut(uint256 _price) public view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}


contract ClockAuction is Pausable, ClockAuctionBase {

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
    bytes4(keccak256("transferFrom(address,address,uint256)"));

    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

    function cancelAuction(uint256 _tokenId)
        external
    {
        require(_tokenId > 1);

        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function getSeller(uint256 _tokenId) external view returns(address){
        Auction storage auction = tokenIdToAuction[_tokenId];
        if(_isOnAuction(auction)){
            return auction.seller;
        } else {
            return nonFungibleContract.ownerOf(_tokenId);
        }
    }

    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


contract SiringClockAuction is ClockAuction {

    bool public isSiringClockAuction = true;

    function SiringClockAuction(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId, address _to)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value, _to);
        _transfer(seller, _tokenId);
    }

}


contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    uint256 public gen0SaleCount;

    uint256[5] public lastGen0SalePrices;

    function SaleClockAuction(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId, address _to)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));

        address seller = tokenIdToAuction[_tokenId].seller;  

        require(seller != _to);

        uint256 price = _bid(_tokenId, msg.value, _to);
        
        _transfer(_to, _tokenId);
   
        if (seller == address(nonFungibleContract)) {
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}


contract DogAuction is DogBreeding {

    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        require(candidateContract.isSiringClockAuction());

        siringAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _dogId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _dogId) || _approvedFor(msg.sender, _dogId));
        require(!isPregnant(_dogId));
        _approve(_dogId, saleAuction);
        saleAuction.createAuction(
            _dogId,
            _startingPrice,
            _endingPrice,
            _duration,
            dogIndexToOwner[_dogId]
        );
    }

    function createSiringAuction(
        uint256 _dogId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {    
        Dog storage dog = dogs[_dogId];    
        require(dog.variation == 0);

        require(_owns(msg.sender, _dogId));
        require(isReadyToBreed(_dogId));
        _approve(_dogId, siringAuction);
        siringAuction.createAuction(
            _dogId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        
        uint256 totalFee = currentPrice + autoBirthFee + creationProfit + creationProfit;
        Dog storage matron = dogs[_matronId];
        if (matron.generation > 0) {
            totalFee += gen0Profit;
        }        
        require(msg.value >= totalFee);

        uint256 auctioneerCut = saleAuction.computeCut(currentPrice);
        siringAuction.bid.value(currentPrice - auctioneerCut)(_sireId, msg.sender);
        _breedWith(uint32(_matronId), uint32(_sireId));

        uint256 bidExcess = msg.value - totalFee;
        if (bidExcess > 0) {
            msg.sender.transfer(bidExcess);
        }
    }

    function bidOnSaleAuction(
        uint256 _dogId
    )
        external
        payable
        whenNotPaused
    {
        Dog storage dog = dogs[_dogId];

        if (dog.generation > 0) {
            var(,,openBlock,,,,,,) = lottery.getCLottery();
            if (dog.birthTime < openBlock) {
                require(lottery.checkLottery(dog.genes) == 100);
            }
        }

        uint256 currentPrice = saleAuction.getCurrentPrice(_dogId);

        require(msg.value >= currentPrice);

        bool isCreationKitty = _dogId == 0 || _dogId == 1;
        uint256 fee = 0;
        if (isCreationKitty) {
            fee = uint256(currentPrice / 5);
        }
        uint256 auctioneerCut = saleAuction.computeCut(currentPrice);
        saleAuction.bid.value(currentPrice - (auctioneerCut + fee))(_dogId, msg.sender);

        if (isCreationKitty) {
            cfoAddress.transfer(fee);

            uint256 nextPrice = uint256(uint128(2 * currentPrice));
            if (nextPrice < currentPrice) {
                nextPrice = currentPrice;
            }
            _approve(_dogId, saleAuction);
            saleAuction.createAuction(
                _dogId,
                nextPrice,
                nextPrice,                                               
                GEN0_AUCTION_DURATION,
                msg.sender);
        }

        uint256 bidExcess = msg.value - currentPrice;
        if (bidExcess > 0) {
            msg.sender.transfer(bidExcess);
        }
    }
}


contract DogMinting is DogAuction {

    uint256 public constant GEN0_CREATION_LIMIT = 40000;

    uint256 public constant GEN0_STARTING_PRICE = 200 finney;

    uint256 public gen0CreatedCount;

    function createGen0Dog(uint256 _genes) external onlyCLevel returns(uint256) {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);
        
        uint256 dogId = _createDog(0, 0, 0, _genes, address(this), 0, 0, false);
        
        _approve(dogId, msg.sender);

        gen0CreatedCount++;
        return dogId;
    }

    function computeNextGen0Price() public view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}


contract DogCore is DogMinting {

    address public newContractAddress;

    function DogCore() public {
        
        paused = true;

        ceoAddress = msg.sender;

        cooAddress = msg.sender;

        _createDog(0, 0, 0, uint256(0), address(this), 0, 0, false);   
        _approve(0, cooAddress);     
        _createDog(0, 0, 0, uint256(0), address(this), 0, 0, false);   
        _approve(1, cooAddress);
    }

    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction) ||
            msg.sender == ceoAddress
        );
    }

    function getDog(uint256 _id)
        external
        view
        returns (
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint8 variation,
        uint256 gen0
    ) {
        Dog storage dog = dogs[_id];

        cooldownIndex = uint256(dog.cooldownIndex);
        nextActionAt = uint256(dog.cooldownEndBlock);
        siringWithId = uint256(dog.siringWithId);
        birthTime = uint256(dog.birthTime);
        matronId = uint256(dog.matronId);
        sireId = uint256(dog.sireId);
        generation = uint256(dog.generation);
        genes = uint256(dog.genes);
        variation = uint8(dog.variation);
        gen0 = uint256(dog.gen0);
    }

    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(lottery != address(0));
        require(variation != address(0));
        require(newContractAddress == address(0));

        super.unpause();
    }
      
    function setLotteryAddress(address _address) external onlyCEO {
        require(address(lottery) == address(0));

        LotteryInterface candidateContract = LotteryInterface(_address);

        require(candidateContract.isLottery());

        lottery = candidateContract;
    }  
      
    function setVariationAddress(address _address) external onlyCEO {
        require(address(variation) == address(0));

        VariationInterface candidateContract = VariationInterface(_address);

        require(candidateContract.isVariation());

        variation = candidateContract;
    }  

    function registerLottery(uint256 _dogId) external returns (uint8) {
        require(_owns(msg.sender, _dogId));
        require(lottery.registerLottery(_dogId) == 0);    
        _transfer(msg.sender, address(lottery), _dogId);
    }
    
    function getAvailableBlance() external view returns(uint256){
        return address(this).balance - spendMoney;
    }
}
pragma solidity ^0.4.22;

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

    function tokenMetadata(uint256 _tokenId) public view returns (string);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ERC721Metadata {
    function getMetadata(uint256 _tokenId) public pure returns (string) {
        string memory infoUrl;
        infoUrl = strConcat(&#39;https://cryptoflowers.io/v/&#39;, uint2str(_tokenId));
        return infoUrl;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }
}

contract GenomeInterface {
    function isGenome() public pure returns (bool);
    function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);
}

// @dev admin access and stop/unstop the game
contract FlowerAdminAccess {
    event ContractUpgrade(address newContract);

    address public rootAddress;
    address public adminAddress;

    address public gen0SellerAddress;

    bool public stopped = false;

    modifier onlyRoot() {
        require(msg.sender == rootAddress);
        _;
    }

    modifier onlyAdmin()  {
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == rootAddress || msg.sender == adminAddress);
        _;
    }

    function setRoot(address _newRoot) external onlyAdministrator {
        require(_newRoot != address(0));
        rootAddress = _newRoot;
    }

    function setAdmin(address _newAdmin) external onlyRoot {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    modifier whenStopped {
        require(stopped);
        _;
    }

    function setStop() public onlyAdministrator whenNotStopped {
        stopped = true;
    }

    function setStart() public onlyAdministrator whenStopped {
        stopped = false;
    }
}

contract FlowerBase is FlowerAdminAccess {

    struct Flower {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndBlock;
        uint32 matronId;
        uint32 sireId;
        uint16 cooldownIndex;
        uint16 generation;
    }

    Flower[] flowers;

    // Сooldown duration
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
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    uint256 public secondsPerBlock = 15;

    mapping (uint256 => address) public flowerIndexToOwner;
    mapping (address => uint256) ownerFlowersCount;
    mapping (uint256 => address) public flowerIndexToApproved;

    event Birth(address owner, uint256 flowerId, uint256 matronId, uint256 sireId, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

    SaleClockAuction public saleAuction;
    BreedingClockAuction public breedingAuction;

    function _transfer(address _from, address _to, uint256 _flowerId) internal {
        ownerFlowersCount[_to]++;
        flowerIndexToOwner[_flowerId] = _to;
        if (_from != address(0)) {
            ownerFlowersCount[_from]--;
            delete flowerIndexToApproved[_flowerId];
        }
        emit Transfer(_from, _to, _flowerId);
    }

    function _createFlower(uint256 _matronId, uint256 _sireId, uint256 _generation, uint256 _genes, address _owner) internal returns (uint) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Flower memory _flower = Flower({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
            });

        uint256 newFlowerId = flowers.push(_flower) - 1;

        require(newFlowerId == uint256(uint32(newFlowerId)));

        emit Birth(_owner, newFlowerId, uint256(_flower.matronId), uint256(_flower.sireId), _flower.genes);

        _transfer(0, _owner, newFlowerId);

        return newFlowerId;
    }

    function setSecondsPerBlock(uint256 secs) external onlyAdministrator {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

contract FlowerOwnership is FlowerBase, ERC721 {

    string public constant name = "CryptoFlowers";
    string public constant symbol = "CF";

    // Return flower metadata (URL)
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256)&#39;));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0xf6546c19));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function setMetadataAddress(address _contractAddress) public onlyAdministrator {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function _owns(address _address, uint256 _flowerId) internal view returns (bool) {
        return flowerIndexToOwner[_flowerId] == _address;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownerFlowersCount[_owner];
    }

    function ownerOf(uint256 _flowerId) external view returns (address owner) {
        owner = flowerIndexToOwner[_flowerId];
        require(owner != address(0));
    }

    function _approve(uint256 _flowerId, address _address) internal {
        flowerIndexToApproved[_flowerId] = _address;
    }

    function _approvedFor(address _address, uint256 _flowerId) internal view returns (bool) {
        return flowerIndexToApproved[_flowerId] == _address;
    }

    function transfer(address _to, uint256 _flowerId) external whenNotStopped {
        require(_to != address(0));
        require(_to != address(this));

        require(_owns(msg.sender, _flowerId));
        _transfer(msg.sender, _to, _flowerId);
    }

    function approve(address _to, uint256 _flowerId) external whenNotStopped {
        require(_owns(msg.sender, _flowerId));

        _approve(_flowerId, _to);

        emit Approval(msg.sender, _to, _flowerId);
    }

    function transferFrom(address _from, address _to, uint256 _flowerId) external whenNotStopped {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _flowerId));
        require(_owns(_from, _flowerId));

        _transfer(_from, _to, _flowerId);
    }

    // Count all flowers
    function totalSupply() public view returns (uint) {
        return flowers.length - 1;
    }

    // List owner flowers
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerFlowers) {
        uint256 count = balanceOf(_owner);

        if (count == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](count);
            uint256 totalFlowers = totalSupply();
            uint256 resultIndex = 0;

            uint256 flowerId;
            for (flowerId = 1; flowerId <= totalFlowers; flowerId++) {
                if (flowerIndexToOwner[flowerId] == _owner) {
                    result[resultIndex] = flowerId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokenMetadata(uint256 _tokenId) public view returns (string) {
        require(erc721Metadata != address(0));
        string memory url;
        url = erc721Metadata.getMetadata(_tokenId);
        return url;
    }
}


contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
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
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

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

        emit AuctionCreated(uint256(_tokenId), uint256(_auction.startingPrice), uint256(_auction.endingPrice), uint256(_auction.duration));
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address _sender) internal returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);

            emit Money(_sender, "AuctionSuccessful", price, auctioneerCut, _tokenId, block.number);
        }

        uint256 bidExcess = _bidAmount - price;

        _sender.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, _sender);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt < now);
    }

    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(_auction.startingPrice, _auction.endingPrice, _auction.duration, secondsPassed);
    }

    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return uint256(_price * ownerCut / 10000);
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
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ClockAuction is Pausable, ClockAuctionBase {
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0xf6546c19);
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(msg.sender == owner || msg.sender == nftAddress);

        owner.transfer(address(this).balance);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external whenNotPaused {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(startAt)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId, address _sender) external payable whenNotPaused {
        _bid(_tokenId, msg.value, _sender);
        _transfer(_sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionByAdmin(uint256 _tokenId) onlyOwner external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (auction.seller, auction.startingPrice, auction.endingPrice, auction.duration, auction.startedAt);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256){
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    // TMP
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract BreedingClockAuction is ClockAuction {

    bool public isBreedingClockAuction = true;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    function bid(uint256 _tokenId, address _sender) external payable {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value, _sender);
        _transfer(seller, _tokenId);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }
}





contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    address public gen0SellerAddress;
    function setGen0SellerAddress(address _newAddress) external {
        require(msg.sender == address(nonFungibleContract));
        gen0SellerAddress = _newAddress;
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId) external payable {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(gen0SellerAddress)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function bidGift(uint256 _tokenId, address _to) external payable {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(_to, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(gen0SellerAddress)) {
            // Track gen0 sale prices
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

    function computeCut(uint256 _price) public view returns (uint256) {
        return _computeCut(_price);
    }

    function getSeller(uint256 _tokenId) public view returns (address) {
        return address(tokenIdToAuction[_tokenId].seller);
    }
}

// Flowers crossing
contract FlowerBreeding is FlowerOwnership {

    // Fee for breeding
    uint256 public autoBirthFee = 2 finney;

    GenomeInterface public geneScience;

    // Set Genome contract address
    function setGenomeContractAddress(address _address) external onlyAdministrator {
        geneScience = GenomeInterface(_address);
    }

    function _isReadyToAction(Flower _flower) internal view returns (bool) {
        return _flower.cooldownEndBlock <= uint64(block.number);
    }

    function isReadyToAction(uint256 _flowerId) public view returns (bool) {
        require(_flowerId > 0);
        Flower storage flower = flowers[_flowerId];
        return _isReadyToAction(flower);
    }

    function _setCooldown(Flower storage _flower) internal {
        _flower.cooldownEndBlock = uint64((cooldowns[_flower.cooldownIndex]/secondsPerBlock) + block.number);

        if (_flower.cooldownIndex < 13) {
            _flower.cooldownIndex += 1;
        }
    }

    // Updates the minimum payment required for calling giveBirthAuto()
    function setAutoBirthFee(uint256 val) external onlyAdministrator {
        autoBirthFee = val;
    }

    // Check if a given sire and matron are a valid crossing pair
    function _isValidPair(Flower storage _matron, uint256 _matronId, Flower storage _sire, uint256 _sireId) private view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

        // Generation zero can crossing
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // Do not crossing with it parrents
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // Can&#39;t crossing with brothers and sisters
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    function canBreedWith(uint256 _matronId, uint256 _sireId) external view returns (bool) {
        return _canBreedWith(_matronId, _sireId);
    }

    function _canBreedWith(uint256 _matronId, uint256 _sireId) internal view returns (bool) {
        require(_matronId > 0);
        require(_sireId > 0);
        Flower storage matron = flowers[_matronId];
        Flower storage sire = flowers[_sireId];
        return _isValidPair(matron, _matronId, sire, _sireId);
    }

    function born(uint256 _matronId, uint256 _sireId) external {
        _born(_matronId, _sireId);
    }

    function _born(uint256 _matronId, uint256 _sireId) internal {
        Flower storage sire = flowers[_sireId];
        Flower storage matron = flowers[_matronId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes);
        address owner = flowerIndexToOwner[_matronId];
        uint256 flowerId = _createFlower(_matronId, _sireId, parentGen + 1, childGenes, owner);

        Flower storage child = flowers[flowerId];

        _setCooldown(sire);
        _setCooldown(matron);
        _setCooldown(child);
    }

    // Crossing two of owner flowers
    function breedOwn(uint256 _matronId, uint256 _sireId) external payable whenNotStopped {
        require(msg.value >= autoBirthFee);
        require(_owns(msg.sender, _matronId));
        require(_owns(msg.sender, _sireId));

        Flower storage matron = flowers[_matronId];
        require(_isReadyToAction(matron));

        Flower storage sire = flowers[_sireId];
        require(_isReadyToAction(sire));

        require(_isValidPair(matron, _matronId, sire, _sireId));

        _born(_matronId, _sireId);

        gen0SellerAddress.transfer(autoBirthFee);

        emit Money(msg.sender, "BirthFee-own", autoBirthFee, autoBirthFee, _sireId, block.number);
    }
}

// Handles creating auctions for sale and siring
contract FlowerAuction is FlowerBreeding {

    // Set sale auction contract address
    function setSaleAuctionAddress(address _address) external onlyAdministrator {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    // Set siring auction contract address
    function setBreedingAuctionAddress(address _address) external onlyAdministrator {
        BreedingClockAuction candidateContract = BreedingClockAuction(_address);
        require(candidateContract.isBreedingClockAuction());
        breedingAuction = candidateContract;
    }

    // Flower sale auction
    function createSaleAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(_owns(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        _approve(_flowerId, saleAuction);
        saleAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

    // Create siring auction
    function createBreedingAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(_owns(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        _approve(_flowerId, breedingAuction);
        breedingAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

    // Siring auction complete
    function bidOnBreedingAuction(uint256 _sireId, uint256 _matronId) external payable whenNotStopped {
        require(_owns(msg.sender, _matronId));
        require(isReadyToAction(_matronId));
        require(isReadyToAction(_sireId));
        require(_canBreedWith(_matronId, _sireId));

        uint256 currentPrice = breedingAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        breedingAuction.bid.value(msg.value - autoBirthFee)(_sireId, msg.sender);
        _born(uint32(_matronId), uint32(_sireId));
        gen0SellerAddress.transfer(autoBirthFee);
        emit Money(msg.sender, "BirthFee-bid", autoBirthFee, autoBirthFee, _sireId, block.number);
    }

    // Transfers the balance of the sale auction contract to the Core contract
    function withdrawAuctionBalances() external onlyAdministrator {
        saleAuction.withdrawBalance();
        breedingAuction.withdrawBalance();
    }

    function sendGift(uint256 _flowerId, address _to) external payable whenNotStopped {
        require(_owns(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));

        _transfer(msg.sender, _to, _flowerId);
    }
}

contract FlowerMinting is FlowerAuction {
    // Limits the number of flowers the contract owner can ever create
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;
    // Constants for gen0 auctions.
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;
    // Counts the number of cats the contract owner has created
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    // Create promo flower
    function createPromoFlower(uint256 _genes, address _owner) external onlyAdministrator {
        address flowerOwner = _owner;
        if (flowerOwner == address(0)) {
            flowerOwner = adminAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        promoCreatedCount++;
        gen0CreatedCount++;
        _createFlower(0, 0, 0, _genes, flowerOwner);
    }

    function createGen0Auction(uint256 _genes, uint64 _auctionStartAt) external onlyAdministrator {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);
        uint256 flowerId = _createFlower(0, 0, 0, _genes, address(gen0SellerAddress));
        _approve(flowerId, saleAuction);

        gen0CreatedCount++;

        saleAuction.createAuction(flowerId, _computeNextGen0Price(), 0, GEN0_AUCTION_DURATION, address(gen0SellerAddress), _auctionStartAt);
    }

    // Computes the next gen0 auction starting price, given the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don&#39;t overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}

contract FlowerCore is FlowerMinting {
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    function setGen0SellerAddress(address _newAddress) external onlyAdministrator {
        gen0SellerAddress = _newAddress;
        saleAuction.setGen0SellerAddress(_newAddress);
    }

    constructor() public {
        stopped = true;
        rootAddress = msg.sender;
        adminAddress = msg.sender;
        _createFlower(0, 0, 0, uint256(-1), address(0));
    }

    // Set new contract address
    function setNewAddress(address _v2Address) external onlyAdministrator whenStopped {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    // Get flower information
    function getFlower(uint256 _id) external view returns (bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes) {
        Flower storage flower = flowers[_id];
        isReady = (flower.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(flower.cooldownIndex);
        nextActionAt = uint256(flower.cooldownEndBlock);
        birthTime = uint256(flower.birthTime);
        matronId = uint256(flower.matronId);
        sireId = uint256(flower.sireId);
        generation = uint256(flower.generation);
        genes = flower.genes;
    }

    // Start the game
    function unstop() public onlyAdministrator whenStopped {
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        super.setStart();
    }

    // Allows admin to capture the balance available to the contract
    function withdrawBalance() external onlyAdministrator {
        uint256 balance = address(this).balance;
        //        uint256 subtractFees = 3 * autoBirthFee;

        if (balance > 0) {
            //            rootAddress.transfer(balance - subtractFees);
            rootAddress.transfer(balance);
        }
    }

    // TMP
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
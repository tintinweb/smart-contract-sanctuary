pragma solidity ^0.4.21;

/// @author Luis Freitas, Miguel Amaral (https://repop.world)
contract REPOPAccessControl {
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
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
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

contract PullPayment {
  mapping(address => uint) public payments;

  function asyncSend(address dest, uint amount) internal {
    payments[dest] += amount;
  }

  function withdrawPayments() external {
    uint payment = payments[msg.sender];
    payments[msg.sender] = 0;
    if (!msg.sender.send(payment)) {
      payments[msg.sender] = payment;
    }
  }
}


/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7c181908193c1d04151311061912521f13">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {

  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract MetadataContract{

    function getMetadata(uint256 _tokenId) public view returns (bytes32[4] buffer, uint256 count) {
        buffer[0] = "https://meta.repop.world/";
        buffer[1] = uintToBytes(_tokenId);
        count = 64;
    }

      function _memcpy(uint _dest, uint _src, uint _len) private view {

        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    function getMetadataUrl(uint256 _tokenId) external view returns (string infoUrl) {
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = getMetadata(_tokenId);

        return _toString(buffer, count);
    }

    function uintToBytes(uint v) public view returns (bytes32 ret) {
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


/// @author Luis Freitas, Miguel Amaral (https://repop.world)
contract REPOPERC721 is ERC721, REPOPAccessControl{

  MetadataContract public metadataContract;

  bytes4 constant InterfaceSignature_ERC165 =
      bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

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

    function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl) {
      require(metadataContract != address(0));
      require(_tokenId >= 0 && _tokenId <= pops.length);

      return metadataContract.getMetadataUrl(_tokenId);
    }

    function setMetadataContractAddress(address contractAddress) public onlyCEO{
      require(contractAddress != address(0));
      metadataContract = MetadataContract(contractAddress);
    }

    string public constant name = "REPOP WORLD";
    string public constant symbol = "POP";

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function approve(address _to, uint256 _tokenId) public whenNotPaused{

        require(_owns(msg.sender, _tokenId));

        popIndexToApproved[_tokenId] = _to;

        emit Approval(msg.sender, _to, _tokenId);
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return ownershipTokenCount[_owner];
    }

    function implementsERC721() public pure returns (bool){
        return true;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = popIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function takeOwnership(uint256 _tokenId) public {
        address currentOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;

        require(_addressNotNull(newOwner));
        require(_approved(newOwner, _tokenId));

        _transfer(newOwner, _tokenId);
        emit Transfer(currentOwner, newOwner, _tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {

            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPops = totalSupply();
            uint256 resultIndex = 0;
            uint256 popId;

            for (popId = 1; popId <= totalPops; popId++) {
                if (popIndexToOwner[popId] == _owner) {
                    result[resultIndex] = popId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function totalSupply() public view returns (uint256 total) {
        return pops.length;
    }

    function transfer(address _to, uint256 _tokenId ) public whenNotPaused{
      require(_owns(msg.sender, _tokenId));
      require(_addressNotNull(_to));

      _transfer(_to, _tokenId);

      emit Transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{
        require(_owns(_from, _tokenId));
        require(_approved(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }


    function _addressNotNull(address _to) private pure returns (bool){
        return _to != address(0);
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return popIndexToApproved[_tokenId] == _to;
    }

    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == popIndexToOwner[_tokenId];
    }

    function _transfer(address _to, uint256 _tokenID) internal {
        address owner = popIndexToOwner[_tokenID];
        ownershipTokenCount[owner] = ownershipTokenCount[owner] - 1 ;
        popIndexToApproved[_tokenID] = 0;
        popIndexToOwner[_tokenID] = _to;
        ownershipTokenCount[_to] = ownershipTokenCount[_to] + 1;
    }

    event Birth(address owner, uint256 popId, uint256 aParentId, uint256 bParentId, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);

    struct Pop {
      uint256 genes;
      uint64 birthTime;
      uint64 cooldownEndTimestamp;
      uint32 aParentId;
      uint32 bParentId;
      bytes32 popName;
      uint16 cooldownIndex;
      uint16 generation;
    }

    uint32[14] public cooldowns = [
        uint32(10 minutes),
        uint32(20 minutes),
        uint32(40 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(3 hours),
        uint32(4 hours),
        uint32(5 hours),
        uint32(6 hours),
        uint32(12 hours),
        uint32(1 days),
        uint32(3 days),
        uint32(5 days),
        uint32(7 days)
    ];

    Pop[] public pops;

    mapping (uint256 => address) public popIndexToOwner;
    mapping (address => uint256) public ownershipTokenCount;
    mapping (uint256 => address) public popIndexToApproved;
    mapping (uint256 => uint256) public genesToTokenId;

    function getPop(uint256 _popId) public view
                    returns (
                                bool isReady,
                                uint256 genes,
                                uint64 birthTime,
                                uint64 cooldownEndTimestamp,
                                uint32 aParentId,
                                uint32 bParentId,
                                bytes32 popName,
                                uint16 cooldownIndex,
                                uint16 generation){
        Pop memory pop = pops[_popId];
        return(
                isReady = (pop.cooldownEndTimestamp <= now),
                pop.genes,
                pop.birthTime,
                pop.cooldownEndTimestamp,
                pop.aParentId,
                pop.bParentId,
                pop.popName,
                pop.cooldownIndex,
                pop.generation);
    }


    function createNewPop(uint256 genes, string popName) public onlyCLevel whenNotPaused{
        bytes32 name32 = stringToBytes32(popName);
        uint256 index = pops.push(Pop(genes,uint64(now),1,0,0,name32,0,0)) -1;

        emit Birth(msg.sender,index,0,0,genes);

        genesToTokenId[genes] = index;

        popIndexToOwner[index] = msg.sender;
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender]+1;
    }

    function _triggerCooldown(Pop storage _pop) internal {
        _pop.cooldownEndTimestamp = uint64(now + cooldowns[_pop.cooldownIndex]);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function setPopNameOriginal(uint256 popId, string newName) external onlyCLevel{
      Pop storage pop = pops[popId];
      require(pop.generation == 0);
      bytes32 name32 = stringToBytes32(newName);
      pop.popName = name32;
    }

    function setDNA(uint256 popId, uint256 newDna) external onlyCLevel{
      require(_owns(msg.sender, popId));
      Pop storage pop = pops[popId];
      pop.genes = newDna;
    }

}

contract CarefulTransfer {
    uint constant suggestedExtraGasToIncludeWithSends = 23000;

    function carefulSendWithFixedGas(
        address _toAddress,
        uint _valueWei,
        uint _extraGasIncluded
    ) internal returns (bool success) {
        return _toAddress.call.value(_valueWei).gas(_extraGasIncluded)();
    }
}

contract MoneyManager is PullPayment, CarefulTransfer, REPOPAccessControl {

    function _repopTransaction(address _receiver, uint256 _amountWei, uint256 _marginPerThousandForDevelopers) internal {
        uint256 commissionWei = (_amountWei * _marginPerThousandForDevelopers) / 1000;
        uint256 compensationWei = _amountWei - commissionWei;

        if( ! carefulSendWithFixedGas(_receiver,compensationWei,23000)) {
            asyncSend(_receiver, compensationWei);
        }
    }

    function withdraw(uint amount) external onlyCFO {
        require(amount < address(this).balance);
        cfoAddress.transfer(amount);
    }

    function getBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }
}

library RoundMoneyNicely {
    function roundMoneyDownNicely(uint _rawValueWei) internal pure
    returns (uint nicerValueWei) {
        if (_rawValueWei < 1 finney) {
            return _rawValueWei;
        } else if (_rawValueWei < 10 finney) {
            return 10 szabo * (_rawValueWei / 10 szabo);
        } else if (_rawValueWei < 100 finney) {
            return 100 szabo * (_rawValueWei / 100 szabo);
        } else if (_rawValueWei < 1 ether) {
            return 1 finney * (_rawValueWei / 1 finney);
        } else if (_rawValueWei < 10 ether) {
            return 10 finney * (_rawValueWei / 10 finney);
        } else if (_rawValueWei < 100 ether) {
            return 100 finney * (_rawValueWei / 100 finney);
        } else if (_rawValueWei < 1000 ether) {
            return 1 ether * (_rawValueWei / 1 ether);
        } else if (_rawValueWei < 10000 ether) {
            return 10 ether * (_rawValueWei / 10 ether);
        } else {
            return _rawValueWei;
        }
    }

    function roundMoneyUpToWholeFinney(uint _valueWei) pure internal
    returns (uint valueFinney) {
        return (1 finney + _valueWei - 1 wei) / 1 finney;
    }
}

contract AuctionManager is MoneyManager {
    event Bid(address bidder, uint256 bid, uint256 auctionId);
    event NewAuction( uint256 itemForAuctionID, uint256 durationSeconds, address seller);
    event NewAuctionWinner(address highestBidder, uint256 auctionId);

    struct Auction{
        uint auctionStart;
        uint auctionEnd;
        uint highestBid;
        address highestBidder;
        bool ended;
    }

    bool public isAuctionManager = true;
    uint256 private marginPerThousandForDevelopers = 50;
    uint256 private percentageBidIncrease = 33;
    uint256 private auctionsStartBid = 0.1 ether;
    address private auctionsStartAddress;

    mapping (uint256 => uint256) public _itemID2auctionID;
    mapping (uint256 => uint256) public _auctionID2itemID;
    Auction[] public _auctionsArray;

    ERC721 public nonFungibleContract;

    function AuctionManager() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

        auctionsStartAddress = msg.sender;
        _auctionsArray.push(Auction(0,0,0,0,false));
    }

    function setERCContract(address candidateAddress) public onlyCEO {
        ERC721 candidateContract = ERC721(candidateAddress);

        nonFungibleContract = candidateContract;
    }

    function getERCContractAddress() public view returns (address) {
        return address(nonFungibleContract);
    }

    function getAllActiveAuctions()  external view returns (uint256[] popsIDs,uint256[] auctionsIDs,uint256[] sellingPrices, address[] highestBidders, bool[] canBeEnded){

        uint256[] memory toReturnPopsIDs = new uint256[](_auctionsArray.length);
        uint256[] memory toReturnAuctionsIDs = new uint256[](_auctionsArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_auctionsArray.length);
        address[] memory toReturnSellerAddress = new address[](_auctionsArray.length);
        bool[] memory toReturnCanBeEnded = new bool[](_auctionsArray.length);
        uint256 index = 0;

        for(uint256 i = 1; i < _auctionsArray.length; i++){
            uint256 popId = _auctionID2itemID[i];
            uint256 price = requiredBid(i);

            if(_auctionsArray[i].ended == false){
                toReturnPopsIDs[index] = popId;
                toReturnAuctionsIDs[index] = i;
                toReturnSellingPrices[index] = price;
                toReturnSellerAddress[index] = _auctionsArray[i].highestBidder;
                toReturnCanBeEnded[index] = _auctionsArray[i].auctionEnd < now;
                index++;
            }
        }
        return (toReturnPopsIDs,toReturnAuctionsIDs,toReturnSellingPrices,toReturnSellerAddress,toReturnCanBeEnded);
    }

    function getAllAuctions()  external view returns (uint256[] popsIDs,uint256[] auctionsIDs,uint256[] sellingPrices){

        uint256[] memory toReturnPopsIDs = new uint256[](_auctionsArray.length);
        uint256[] memory toReturnAuctionsIDs = new uint256[](_auctionsArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_auctionsArray.length);

        uint256 index = 0;

        for(uint256 i = 1; i < _auctionsArray.length; i++){
            uint256 popId = _auctionID2itemID[i];
            uint256 price = requiredBid(i);
            toReturnPopsIDs[index] = popId;
            toReturnAuctionsIDs[index] = i;
            toReturnSellingPrices[index] = price;
            index++;
        }
        return (toReturnPopsIDs,toReturnAuctionsIDs,toReturnSellingPrices);
    }


    function createAuction(uint256 _itemForAuctionID, uint256 _auctionDurationSeconds, address _seller) public {
        require(msg.sender == getERCContractAddress());
        require(_auctionDurationSeconds >= 20 seconds);
        require(_auctionDurationSeconds < 45 days);
        require(_itemForAuctionID != 0);
        require(_seller != 0);

        _takeOwnershipOfTokenFrom(_itemForAuctionID,_seller);

        uint256 auctionEnd = SafeMath.add(now,_auctionDurationSeconds);
        uint256 auctionID = _itemID2auctionID[_itemForAuctionID];
        if(auctionID == 0){
            uint256 index = _auctionsArray.push(Auction(now, auctionEnd, 0, _seller, false)) - 1;
            _itemID2auctionID[_itemForAuctionID] = index;
            _auctionID2itemID[index] = _itemForAuctionID;
        } else {
            Auction storage previousAuction = _auctionsArray[auctionID];
            require(previousAuction.ended == true);
            previousAuction.auctionStart = now;
            previousAuction.auctionEnd = auctionEnd;
            previousAuction.highestBidder = _seller;
            previousAuction.highestBid = 0;
            previousAuction.ended = false;
        }
        emit NewAuction(_itemForAuctionID, _auctionDurationSeconds, _seller);
    }

    function bid(uint auctionID) public payable whenNotPaused{
        require(auctionID != 0);
        Auction storage auction = _auctionsArray[auctionID];
        require(auction.ended == false);
        require(auction.auctionEnd >= now);
        uint claimBidPrice = requiredBid(auctionID);
        uint256 bidValue = msg.value;
        require(bidValue >= claimBidPrice);
        address previousHighestBidder = auction.highestBidder;
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        _repopTransaction(previousHighestBidder, msg.value, marginPerThousandForDevelopers);
        emit Bid(msg.sender, msg.value, auctionID);
    }

    function endAuction(uint auctionID) public{
        require(auctionID != 0);
        Auction storage auction = _auctionsArray[auctionID];
        require(auction.ended == false);
        require(auction.auctionEnd < now);
        auction.ended = true;
        nonFungibleContract.transfer(auction.highestBidder, _auctionID2itemID[auctionID]);
        emit NewAuctionWinner(auction.highestBidder, auctionID);
    }

    function requiredBid(uint _auctionID) constant public returns (uint256 amountToOutBid) {
        require(_auctionID != 0);
        Auction memory auction = _auctionsArray[_auctionID];
        if(auction.highestBid == 0){
            return auctionsStartBid;
        } else {
            uint256 amountRequiredToOutBid = (auction.highestBid * (100 + percentageBidIncrease)) / 100;
            amountRequiredToOutBid = RoundMoneyNicely.roundMoneyDownNicely(amountRequiredToOutBid);
            return amountRequiredToOutBid;
        }
    }

    function getAuction(uint _itemForAuctionID) external constant returns (uint256 itemID, uint256 auctionStart, uint256 auctionEnd, address highestBidder, uint256 highestBid, bool ended){
        require(_itemForAuctionID != 0);
        Auction memory auction = _auctionsArray[_itemID2auctionID[_itemForAuctionID]];
        if(auction.highestBidder != 0) {
            itemID = _itemForAuctionID;
            auctionStart =  auction.auctionStart;
            auctionEnd =    auction.auctionEnd;
            highestBidder = auction.highestBidder;
            highestBid =    auction.highestBid;
            ended =         auction.ended;
            return(itemID,auctionStart,auctionEnd,highestBidder,highestBid,ended);
        } else {
            revert();
        }
    }

    function getAuctionStartBid() public view returns(uint256){
      return auctionsStartBid;
    }

    function setAuctionStartBid(uint256 _auctionStartBid) public onlyCLevel{
      auctionsStartBid = _auctionStartBid;
    }

    function _addressNotNull(address _to) private pure returns (bool){
        return _to != address(0);
    }


    function _takeOwnershipOfToken(uint256 _itemForAuctionID) internal {

        nonFungibleContract.takeOwnership(_itemForAuctionID);
    }

    function _takeOwnershipOfTokenFrom(uint256 _itemForAuctionID, address previousOwner) internal {
        nonFungibleContract.transferFrom(previousOwner,this,_itemForAuctionID);
    }
}

contract MarketManager is MoneyManager {
    event PopPurchased(address seller, address buyer, uint256 popId, uint256 sellingPrice);
    event PopCancelSale(address popOwner, uint256 popId);
    event PopChangedPrice(address popOwner, uint256 popId, uint256 newPrice);

    struct Sale {
        uint256 sellingPrice;

        address seller;
    }

    bool public isMarketManager = true;
    uint256 private marginPerThousandForDevelopers = 50;
    uint256 private MAX_SELLING_PRICE = 100000 ether;
    mapping (uint256 => uint256) public _itemID2saleID;
    mapping (uint256 => uint256) public _saleID2itemID;
    Sale[] public _salesArray;
    ERC721 public nonFungibleContract;

    function MarketManager() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        _salesArray.push(Sale(0,0));
        _itemID2saleID[0] = 0;
        _saleID2itemID[0] = 0;
    }

    function setERCContract(address candidateAddress) public onlyCEO {
        require(candidateAddress != address(0));
        ERC721 candidateContract = ERC721(candidateAddress);
        nonFungibleContract = candidateContract;
    }

    function getERCContractAddress() public view returns (address) {
        return address(nonFungibleContract);
    }

    function getAllActiveSales()  external view returns (uint256[] popsIDs,uint256[] sellingPrices,address[] sellerAddresses){

        uint256[] memory toReturnPopsIDs = new uint256[](_salesArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_salesArray.length);
        address[] memory toReturnSellerAddress = new address[](_salesArray.length);
        uint256 index = 0;

        for(uint256 i = 1; i < _salesArray.length; i++){
            uint256 popId = _saleID2itemID[i];
            uint256 price = _salesArray[i].sellingPrice;
            address seller = _salesArray[i].seller;

            if(seller != 0){
                toReturnSellerAddress[index] = seller;
                toReturnPopsIDs[index] = popId;
                toReturnSellingPrices[index] = price;
                index++;
            }
        }
        return (toReturnPopsIDs,toReturnSellingPrices,toReturnSellerAddress);
    }

    function getAllSalesByAddress(address addr)  external view returns (uint256[] popsIDs,uint256[] sellingPrices,address[] sellerAddresses){

        uint256[] memory toReturnPopsIDs = new uint256[](_salesArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_salesArray.length);
        address[] memory toReturnSellerAddress = new address[](_salesArray.length);
        uint256 index = 0;

        for(uint256 i = 1; i < _salesArray.length; i++){
            uint256 popId = _saleID2itemID[i];
            uint256 price = _salesArray[i].sellingPrice;
            address seller = _salesArray[i].seller;

            if(seller == addr){
                toReturnSellerAddress[index] = seller;
                toReturnPopsIDs[index] = popId;
                toReturnSellingPrices[index] = price;
                index++;
            }
        }
        return (toReturnPopsIDs,toReturnSellingPrices,toReturnSellerAddress);
    }

    function purchasePop(uint256 _popId) public payable whenNotPaused{
        uint256 saleID = _itemID2saleID[_popId];
        require(saleID != 0);
        Sale storage sale = _salesArray[saleID];
        address popOwner = sale.seller;
        require(popOwner != 0);
        address newOwner = msg.sender;
        uint256 sellingPrice = sale.sellingPrice;
        require(popOwner != newOwner);
        require(_addressNotNull(newOwner));
        require(msg.value == sellingPrice);
        sale.seller = 0;
        nonFungibleContract.transfer(newOwner,_popId);
        _repopTransaction(popOwner, msg.value, marginPerThousandForDevelopers);
        emit PopPurchased(popOwner, msg.sender, _popId, msg.value);
    }

    function sellerOf(uint _popId) public view returns (address) {
        uint256 saleID = _itemID2saleID[_popId];
        Sale memory sale = _salesArray[saleID];
        return sale.seller;
    }

    function sellPop(address seller, uint256 _popId, uint256 _sellingPrice) public whenNotPaused{
        require(_sellingPrice < MAX_SELLING_PRICE);
        require(msg.sender == getERCContractAddress());
        require(_sellingPrice > 0);
        _takeOwnershipOfTokenFrom(_popId,seller);
        uint256 saleID = _itemID2saleID[_popId];
        if(saleID == 0) {
            uint256  index = _salesArray.push(Sale(_sellingPrice,seller)) - 1;
            _itemID2saleID[_popId] = index;
            _saleID2itemID[index] = _popId;
        } else {
            Sale storage sale = _salesArray[saleID];
            require(sale.seller == 0);
            sale.seller = seller;
            sale.sellingPrice = _sellingPrice;
        }
    }

    function cancelSellPop(uint256 _popId) public {
        Sale storage sale = _salesArray[_itemID2saleID[_popId]];
        require(sale.seller == msg.sender);
        sale.seller = 0;
        nonFungibleContract.transfer(msg.sender,_popId);

        emit PopCancelSale(msg.sender, _popId);
    }

    function changeSellPOPPrice(uint256 _popId, uint256 _newSellingValue) public whenNotPaused{
      require(_newSellingValue < MAX_SELLING_PRICE);
      require(_newSellingValue > 0);
      Sale storage sale = _salesArray[_itemID2saleID[_popId]];
      require(sale.seller == msg.sender);
      sale.sellingPrice = _newSellingValue;
      emit PopChangedPrice(msg.sender, _popId, _newSellingValue);
    }

    function _addressNotNull(address _to) private pure returns (bool){
        return _to != address(0);
    }

    function _takeOwnershipOfToken(uint256 _itemForAuctionID) internal {
        nonFungibleContract.takeOwnership(_itemForAuctionID);
    }

    function _takeOwnershipOfTokenFrom(uint256 _itemForAuctionID, address previousOwner) internal {
        nonFungibleContract.transferFrom(previousOwner,this,_itemForAuctionID);
    }
}

contract CloningInterface{
  function isGeneScience() public pure returns (bool);
  function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);
}

contract GenesMarket is MoneyManager {
    event GenesCancelSale(address popOwner, uint256 popId);
    event GenesPurchased(address buyer, address popOwner, uint256 popId, uint256 amount, uint256 price);
    event GenesChangedPrice(address popOwner, uint256 popId, uint256 newPrice);

    struct GeneForSale {
            uint256 sellingPrice;
            address currentOwner;
    }

    mapping (uint256 => uint256) public _itemID2geneSaleID;
    mapping (uint256 => uint256) public _geneSaleID2itemID;
    GeneForSale[] public _genesForSaleArray;
    uint256 marginPerThousandForDevelopers = 50;
    uint256 MAX_SELLING_PRICE = 10000 ether;

    mapping(address => mapping (uint256 => uint256)) _genesOwned;
    mapping(address => uint256[]) _ownedGenesPopsId;
    bool public isGenesMarket = true;

    function GenesMarket() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        _genesForSaleArray.push(GeneForSale(0,0));
    }

    ERC721 public nonFungibleContract;
    function setERCContract(address candidateAddress) public onlyCEO() {
        ERC721 candidateContract = ERC721(candidateAddress);
        nonFungibleContract = candidateContract;
    }

    function getERCContractAddress() public view returns (address) {
        return address(nonFungibleContract);
    }

    function startSellingGenes(uint256 _popId, uint256 _sellingPrice, address _seller) public {
        require(_sellingPrice < MAX_SELLING_PRICE);
        require(msg.sender == getERCContractAddress());
        require(_sellingPrice > 0);
        _takeOwnershipOfTokenFrom(_popId,_seller);
        uint256 geneSaleID = _itemID2geneSaleID[_popId];
        if(geneSaleID == 0){

            uint256 index = _genesForSaleArray.push(GeneForSale(_sellingPrice,_seller)) - 1;
            _itemID2geneSaleID[_popId] = index;
            _geneSaleID2itemID[index] = _popId;

        }else {
            GeneForSale storage previousSale = _genesForSaleArray[geneSaleID];
            previousSale.sellingPrice = _sellingPrice;
            previousSale.currentOwner = _seller;
        }
    }

    function stopSellingGenes(uint _popId) public {
        uint256 geneSaleID = _itemID2geneSaleID[_popId];
        require(geneSaleID != 0);
        GeneForSale storage gene = _genesForSaleArray[geneSaleID];
        require(msg.sender == gene.currentOwner);
        require(gene.sellingPrice != 0);
        gene.sellingPrice = 0;
        nonFungibleContract.transfer(gene.currentOwner, _popId);

        emit GenesCancelSale(msg.sender, _popId);
    }


    function sellerOf(uint _popId) public view returns (address) {
        uint256 geneSaleID = _itemID2geneSaleID[_popId];
        GeneForSale memory gene = _genesForSaleArray[geneSaleID];
        if(gene.sellingPrice != 0) {
            return gene.currentOwner;
        } else {
            return 0;
        }
    }

    function useBottle(address _user, uint _popId) external whenNotPaused {
        require(msg.sender == getERCContractAddress());
        require(_genesOwned[_user][_popId] > 0);
        _genesOwned[_user][_popId] = _genesOwned[_user][_popId] - 1;
    }


    function purchaseGenes(uint256 _popId, uint256 _amountGenes, bool update) public payable whenNotPaused{
        require(_amountGenes > 0);
        uint256 geneSaleID = _itemID2geneSaleID[_popId];
        GeneForSale memory gene = _genesForSaleArray[geneSaleID];
        require(gene.sellingPrice != 0);
        address popOwner = gene.currentOwner;
        address genesReceiver = msg.sender;
        uint256 sellingPrice = gene.sellingPrice;
        require(popOwner != genesReceiver);
        require(msg.value == SafeMath.mul(sellingPrice, _amountGenes));
        if( update && _genesOwned[msg.sender][_popId] == 0) {
            _ownedGenesPopsId[msg.sender].push(_popId);
        }
        _genesOwned[msg.sender][_popId] = _genesOwned[msg.sender][_popId] + _amountGenes;
        _repopTransaction(popOwner, msg.value, marginPerThousandForDevelopers);
        emit GenesPurchased(msg.sender, popOwner, _popId, _amountGenes, msg.value);
    }

    function getGenesForSale() public view returns (uint[] popIDs, uint[] sellingPrices, uint[] geneSaleIDs, address[] sellers){
        uint256[] memory toReturnPopsIDs = new uint256[](_genesForSaleArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_genesForSaleArray.length);
        uint256[] memory toReturnGeneSaleID = new uint256[](_genesForSaleArray.length);
        address[] memory toReturnSellers = new address[](_genesForSaleArray.length);
        uint256 index = 0;

        for(uint256 i = 1; i < _genesForSaleArray.length; i++){
            uint256 popId = _geneSaleID2itemID[i];
            uint256 price = _genesForSaleArray[i].sellingPrice;

            if(price != 0){
                toReturnGeneSaleID[index] = i;
                toReturnPopsIDs[index] = popId;
                toReturnSellingPrices[index] = price;
                toReturnSellers[index] = _genesForSaleArray[i].currentOwner;
                index++;
            }
        }
        return (toReturnPopsIDs,toReturnSellingPrices,toReturnGeneSaleID, toReturnSellers);
    }

    function getGenesForSaleBySeller(address seller) public view returns (uint[] popIDs, uint[] sellingPrices, uint[] geneSaleIDs, address[] sellers){
        uint256[] memory toReturnPopsIDs = new uint256[](_genesForSaleArray.length);
        uint256[] memory toReturnSellingPrices = new uint256[](_genesForSaleArray.length);
        uint256[] memory toReturnGeneSaleID = new uint256[](_genesForSaleArray.length);
        address[] memory toReturnSellers = new address[](_genesForSaleArray.length);
        uint256 index = 0;

        for(uint256 i = 1; i < _genesForSaleArray.length; i++){
            uint256 popId = _geneSaleID2itemID[i];
            uint256 price = _genesForSaleArray[i].sellingPrice;

            if(price != 0){
              if(_genesForSaleArray[i].currentOwner == seller){
                toReturnGeneSaleID[index] = i;
                toReturnPopsIDs[index] = popId;
                toReturnSellingPrices[index] = price;
                toReturnSellers[index] = _genesForSaleArray[i].currentOwner;
                index++;
              }
            }
        }
        return (toReturnPopsIDs,toReturnSellingPrices,toReturnGeneSaleID, toReturnSellers);
    }

    function getAmountOfGene(uint _popId) public view returns (uint amount){
        return _genesOwned[msg.sender][_popId];
    }

    function getMyGenes() public view returns (uint[] popIDs, uint[] amount) {
        uint256[] memory toReturnPopsIDs = new uint256[](_ownedGenesPopsId[msg.sender].length);
        uint256[] memory toReturnAmount = new uint256[](_ownedGenesPopsId[msg.sender].length);

        for(uint256 i = 0; i < _ownedGenesPopsId[msg.sender].length; i++) {
            toReturnPopsIDs[i] = _ownedGenesPopsId[msg.sender][i];
            toReturnAmount[i] = _genesOwned[msg.sender][_ownedGenesPopsId[msg.sender][i]];
        }
        return (toReturnPopsIDs,toReturnAmount);
    }

    function changeSellGenesPrice(uint256 _popId, uint256 _newSellingValue) public whenNotPaused{
      require(_newSellingValue < MAX_SELLING_PRICE);
      require(_newSellingValue > 0);
      uint256 geneSaleID = _itemID2geneSaleID[_popId];
      require(geneSaleID != 0);

      GeneForSale storage gene = _genesForSaleArray[geneSaleID];

      require(msg.sender == gene.currentOwner);
      require(gene.sellingPrice != 0);

      gene.sellingPrice = _newSellingValue;

      emit GenesChangedPrice(msg.sender, _popId, _newSellingValue);
    }

    function _takeOwnershipOfTokenFrom(uint256 _popId, address previousOwner) internal {
        nonFungibleContract.transferFrom(previousOwner,this,_popId);
    }
}

contract REPOPCore is REPOPERC721, MoneyManager{
    uint256 public refresherFee = 0.01 ether;
    AuctionManager public auctionManager;
    MarketManager public marketManager;
    GenesMarket public genesMarket;
    CloningInterface public geneScience;

    event CloneWithTwoPops(address creator, uint256 cloneId, uint256 aParentId, uint256 bParentId);
    event CloneWithPopAndBottle(address creator, uint256 cloneId, uint256 popId, uint256 bottleId);
    event SellingPop(address seller, uint256 popId, uint256 price);
    event SellingGenes(address seller, uint256 popId, uint256 price);
    event ChangedPopName(address owner, uint256 popId, bytes32 newName);
    event CooldownRemoval(uint256 popId, address owner, uint256 paidFee);

    function REPOPCore() public{

      ceoAddress = msg.sender;
      cooAddress = msg.sender;
      cfoAddress = msg.sender;

      createNewPop(0x0, "Satoshi Nakamoto");
    }

    function createNewAuction(uint256 _itemForAuctionID, uint256 _auctionDurationSeconds) public onlyCLevel{
        approve(address(auctionManager),_itemForAuctionID);
        auctionManager.createAuction(_itemForAuctionID,_auctionDurationSeconds,msg.sender);
    }

    function setAuctionManagerAddress(address _address) external onlyCEO {
        AuctionManager candidateContract = AuctionManager(_address);


        require(candidateContract.isAuctionManager());


        auctionManager = candidateContract;
    }

    function getAuctionManagerAddress() public view returns (address) {
        return address(auctionManager);
    }

    function setMarketManagerAddress(address _address) external onlyCEO {
        MarketManager candidateContract = MarketManager(_address);
        require(candidateContract.isMarketManager());
        marketManager = candidateContract;
    }

    function getMarketManagerAddress() public view returns (address) {
        return address(marketManager);
    }

    function setGeneScienceAddress(address _address) external onlyCEO {
      CloningInterface candidateContract = CloningInterface(_address);
      require(candidateContract.isGeneScience());
      geneScience = candidateContract;
    }

    function getGeneScienceAddress() public view returns (address) {
        return address(geneScience);
    }

    function setGenesMarketAddress(address _address) external onlyCEO {
      GenesMarket candidateContract = GenesMarket(_address);
      require(candidateContract.isGenesMarket());
      genesMarket = candidateContract;
    }

    function getGenesMarketAddress() public view returns (address) {
        return address(genesMarket);
    }

    function sellPop(uint256 _popId, uint256 _price) public {
        Pop storage pop = pops[_popId];
        require(pop.cooldownEndTimestamp <= now);
        approve(address(marketManager),_popId);
        marketManager.sellPop(msg.sender,_popId,_price);
        emit SellingPop(msg.sender, _popId, _price);
    }

    function sellGenes(uint256 _popId, uint256 _price) public {
        require(_popId > 0);
        approve(address(genesMarket),_popId);
        genesMarket.startSellingGenes(_popId,_price,msg.sender);
        emit SellingGenes(msg.sender, _popId, _price);
    }

    function getOwnerInAnyPlatformById(uint256 popId) public view returns (address){
      if(ownerOf(popId) == address(marketManager)){
        return marketManager.sellerOf(popId);
      }
      else if(ownerOf(popId) == address(genesMarket)){
        return genesMarket.sellerOf(popId);
      }
      else if(ownerOf(popId) == address(auctionManager)){
        return ceoAddress;
      }
      else{
        return ownerOf(popId);
      }
      return 0x0;
    }

    function setPopName(uint256 popId, string newName) external {
      require(_ownerOfPopInAnyPlatform(popId));
      Pop storage pop = pops[popId];
      require(pop.generation > 0);
      bytes32 name32 = stringToBytes32(newName);
      pop.popName = name32;
      emit ChangedPopName(msg.sender, popId, name32);
    }

    function removeCooldown(uint256 popId)
      external
      payable
      {
        require(_ownerOfPopInAnyPlatform(popId));
        require(msg.value >= refresherFee);
        Pop storage pop = pops[popId];
        pop.cooldownEndTimestamp = 1;
        emit CooldownRemoval(popId, msg.sender, refresherFee);
      }

    function _ownerOfPopInAnyPlatform(uint _popId) internal view returns (bool) {
      return ownerOf(_popId) == msg.sender || genesMarket.sellerOf(_popId) == msg.sender || marketManager.sellerOf(_popId) == msg.sender;
    }

    function getOwnershipForCloning(uint _popId) internal view returns (bool) {
        return ownerOf(_popId) == msg.sender || genesMarket.sellerOf(_popId) == msg.sender;
    }

    function changeRefresherFee(uint256 _newFee) public onlyCLevel{
        refresherFee = _newFee;
    }

    function cloneWithTwoPops(uint256 _aParentId, uint256 _bParentId)
      external
      whenNotPaused
      returns (uint256)
      {
        require(_aParentId > 0);
        require(_bParentId > 0);
        require(getOwnershipForCloning(_aParentId));
        require(getOwnershipForCloning(_bParentId));
        Pop storage aParent = pops[_aParentId];

        Pop storage bParent = pops[_bParentId];

        require(aParent.genes != bParent.genes);
        require(aParent.cooldownEndTimestamp <= now);
        require(bParent.cooldownEndTimestamp <= now);

        uint16 parentGen = aParent.generation;
        if (bParent.generation > aParent.generation) {
            parentGen = bParent.generation;
        }

        uint16 cooldownIndex = parentGen + 1;
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        uint256 childGenes = geneScience.mixGenes(aParent.genes, bParent.genes);

        _triggerCooldown(aParent);
        _triggerCooldown(bParent);

        uint256 index = pops.push(Pop(childGenes,uint64(now), 1, uint32(_aParentId), uint32(_bParentId), 0, cooldownIndex, parentGen + 1)) -1;

        popIndexToOwner[index] = msg.sender;
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender]+1;

        emit CloneWithTwoPops(msg.sender, index, _aParentId, _bParentId);
        emit Birth(msg.sender, index, _aParentId, _bParentId,childGenes);

        return index;
    }

    function cloneWithPopAndBottle(uint256 _aParentId, uint256 _bParentId_bottle)
        external
        whenNotPaused
        returns (uint256)
        {
          require(_aParentId > 0);
          require(getOwnershipForCloning(_aParentId));
          Pop storage aParent = pops[_aParentId];
          Pop memory bParent = pops[_bParentId_bottle];

          require(aParent.genes != bParent.genes);
          require(aParent.cooldownEndTimestamp <= now);

          uint16 parentGen = aParent.generation;
          if (bParent.generation > aParent.generation) {
              parentGen = bParent.generation;
          }

          uint16 cooldownIndex = parentGen + 1;
          if (cooldownIndex > 13) {
              cooldownIndex = 13;
          }

          genesMarket.useBottle(msg.sender, _bParentId_bottle);

          uint256 childGenes = geneScience.mixGenes(aParent.genes, bParent.genes);

          _triggerCooldown(aParent);

          uint256 index = pops.push(Pop(childGenes,uint64(now), 1, uint32(_aParentId), uint32(_bParentId_bottle), 0, cooldownIndex, parentGen + 1)) -1;

          popIndexToOwner[index] = msg.sender;
          ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender]+1;

          emit CloneWithPopAndBottle(msg.sender, index, _aParentId, _bParentId_bottle);
          emit Birth(msg.sender, index, _aParentId, _bParentId_bottle, childGenes);

          return index;
        }
}
pragma solidity ^0.4.11;


contract ERC721 {
    
    function totalSupply() public constant returns (uint256 total);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external constant returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    function tokensOfOwner(address _owner) external constant returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external constant returns (bool);
}


contract BlockBase{
    event Transfer(address from, address to, uint256 tokenId);
    event Birth(address owner, uint256 blockId, uint256 width,  uint256 height, string position, uint16 genes);

    struct Block { 
        uint256 width;
        uint256 heigth;
        string position;
        uint16 generation;
    }
    
    Block[] blocks;
    mapping (uint256 => address) public blockIndexToOwner;
    mapping (address => uint256) public ownershipTokenCount;
    mapping (uint256 => address) public blockIndexToApproved;
    SaleAuction public saleAuction;
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        blockIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
        }
        Transfer(_from, _to, _tokenId);
    }
    
    function transferBlock(address oldAdd, address newAdd, uint256 newBlockId) internal {
        _transfer(oldAdd, newAdd, newBlockId);
    }


    function _createBlock(uint256 _width, uint256 _heigth, uint256 _generation, string _position, address _owner) internal returns (uint)
    {
        require(_generation == uint256(uint16(_generation)));
        Block memory _block = Block({
            width: _width,
            heigth: _heigth,
            position: _position,
            generation: uint16(_generation)
        });
        uint256 newBlockId = blocks.push(_block) - 1;
        Birth(
            _owner,
            newBlockId,
            _width,
            _heigth,
            _block.position,
            uint16(_generation)
        );
        _transfer(0, _owner, newBlockId);
        return newBlockId;
    }

}

contract AuctionBase {

    struct Auction {
        address seller;
        uint256 sellPrice;
    }

    
    ERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    function _owns(address _claimant, uint256 _tokenId) internal constant returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;
        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.sellPrice)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        //_transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

       
        // Check that the bid is greater than or equal to the current price
        uint256 price = auction.sellPrice;
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeAuction(_tokenId);
        
        // Tell the world!
        AuctionSuccessful(_tokenId, price, msg.sender);
        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

}

contract SaleAuction is AuctionBase {
    address public beneficiary = msg.sender;
    function SaleAuction(address _nftAddress) public {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    function getAuction(uint256 _tokenId)
        external
        constant
        returns
    (
        address seller,
        uint256 sellPrice
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        
        return (
            auction.seller,
            auction.sellPrice
        );
    }
    
    modifier onlyOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(msg.sender == nftAddress);
        bool res = nftAddress.send(this.balance);
    }
    
   function bid(uint256 _tokenId)
        external
        payable
    {
        Auction memory auction = tokenIdToAuction[_tokenId];
        address seller = auction.seller;
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
        seller.transfer(msg.value);
    }

    function bidCustomAuction(uint256 _tokenId, uint256 _price, address _buyer)
        external
        payable
    {
        
        _bid(_tokenId, _price);
        _transfer(_buyer, _tokenId);
    }


    function createAuction(
        uint256 _tokenId,
        uint256 _sellPrice,
        address _seller
    )
        external
    {       
        // require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(_seller, _sellPrice);
        _addAuction(_tokenId, auction);
    }
}

contract BlockOwnership is BlockBase, ERC721 {
  string public constant name = "CryptoBlocks";
  string public constant symbol = "CB";

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
      bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));
      
      function _owns(address _claimant, uint256 _tokenId) internal constant returns (bool) {
          return blockIndexToOwner[_tokenId] == _claimant;
      }

      function _approve(uint256 _tokenId, address _approved) internal {
          blockIndexToApproved[_tokenId] = _approved;
      }

      function _approvedFor(address _claimant, uint256 _tokenId) internal constant returns (bool) {
          return blockIndexToApproved[_tokenId] == _claimant;
      }

      function ownerOf(uint256 _tokenId) external constant returns (address owner)
      {
          owner = blockIndexToOwner[_tokenId];
  
          require(owner != address(0));
          return owner;
      }


      function balanceOf(address _owner) public constant returns (uint256 count) {
          return ownershipTokenCount[_owner];
      }
    
      function totalSupply() public constant returns (uint) {
          return blocks.length - 1;
      }

      function approve(address _to, uint256 _tokenId) external {
          require(_owns(msg.sender, _tokenId));
          _approve(_tokenId, _to);
          Approval(msg.sender, _to, _tokenId);
      }

      function transfer(address _to, uint256 _tokenId) external {
          //require(_to != address(0));
          //require(_to != address(this));
          _transfer(msg.sender, _to, _tokenId);
      }
      

      function tokensOfOwner(address _owner) external constant returns(uint256[] ownerTokens) {
          uint256 tokenCount = balanceOf(_owner);
          if (tokenCount == 0) {
              return new uint256[](0);
          } else {
              uint256[] memory result = new uint256[](tokenCount);
              uint256 totalBlocks = totalSupply();
              uint256 resultIndex = 0;
              uint256 blockId;
  
              for (blockId = 1; blockId <= totalBlocks; blockId++) {
                  if (blockIndexToOwner[blockId] == _owner) {
                      result[resultIndex] = blockId;
                      resultIndex++;
                  }
              }
              return result;
          }
      }
      

      function transferFrom(address _from, address _to, uint256 _tokenId) external {
          require(_to != address(0));
          require(_to != address(this));
          require(_approvedFor(msg.sender, _tokenId));
          require(_owns(_from, _tokenId));
          _transfer(_from, _to, _tokenId);
      }
}



contract BlockCoreOne is BlockOwnership {

    uint256[5] public lastGen0SalePrices;
    address[16] public owners;
    address public beneficiary = msg.sender;

    mapping (uint256 => address) public blockIndexToOwner;
    uint256 public gen0CreatedCount;

    uint256 public constant BLOCK_BASIC_PRICE = 10 finney;
    uint256 public constant BLOCK_DURATION = 1 days;



    function buyBlock(string _position, uint256 _w, uint256 _h, uint256 _generation, uint256 _unitPrice) public payable returns(uint256 blockID) {
        uint256 price = computeBlockPrice(_w, _h, _unitPrice);
        uint256 _bidAmount = msg.value;
        require(_bidAmount >= price);
        uint256 blockId = _createBlock(_w, _h, _generation, _position, address(this));
        
        _approve(blockId, saleAuction);
        saleAuction.createAuction(blockId, price, address(this));  
        address buyer = msg.sender;  
        saleAuction.bidCustomAuction(blockId, _bidAmount, buyer);    

        return blockId;
    }

    function migrateBlock (string _position, uint256 _width, uint256 _heigth, uint256 _generation, address _buyer) external returns(uint256){
        uint newBlockId = _createBlock(_width, _heigth, _generation, _position, address(this));
        address owner = _buyer;
        _approve(newBlockId, owner);
        return newBlockId;
    }   

    function create(string _position, uint256 _width, uint256 _heigth, uint256 _generation) external returns(uint256){
        uint newBlockId = _createBlock(_width, _heigth, _generation, _position, address(this));

        return newBlockId;
    }   

    function computeBlockPrice(uint256 _w, uint256 _h, uint256 unitPrice) public constant returns (uint256 blockPrice) {
        uint256 price = _w * _h * unitPrice;
        return price;
    }
    
    modifier onlyOwner() {
        require(msg.sender == beneficiary);
        _;
    }


    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        beneficiary.transfer(balance);
    }

    function checkBalance() external constant onlyOwner returns (uint balance) {
        return this.balance;
    }

    function createSaleAuction(uint256 _tokenId, uint256 _sellPrice) external{
        address seller = msg.sender;
        _approve(_tokenId, saleAuction);
        saleAuction.createAuction(_tokenId, _sellPrice, seller);    
    }
    
    function setSaleAuctionAddress(address _address) external onlyOwner {
        SaleAuction candidateContract = SaleAuction(_address);
        saleAuction = candidateContract;
    }
   
}
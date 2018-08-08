pragma solidity ^0.4.19;

contract Ownable {
  address public owner;
  address public ceoWallet;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
    ceoWallet = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
}


contract CryptoRomeControl is Ownable {

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }
    
    function transferWalletOwnership(address newWalletAddress) onlyOwner public {
      require(newWalletAddress != address(0));
      ceoWallet = newWalletAddress;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract CryptoRomeAuction is CryptoRomeControl {

    address public WonderOwnershipAdd;
    uint256 public auctionStart;
    uint256 public startingBid;
    uint256 public auctionDuration;
    address public highestBidder;
    uint256 public highestBid;
    address public paymentAddress;
    uint256 public wonderId;
    bool public ended;

    event Bid(address from, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _startTime, uint256 _startingBid, uint256 _duration, address wallet, uint256 _wonderId, address developer) public {
        WonderOwnershipAdd = msg.sender;
        auctionStart = _startTime;
        startingBid = _startingBid;
        auctionDuration = _duration;
        paymentAddress = wallet;
        wonderId = _wonderId;
        transferOwnership(developer);
    }
    
    function getAuctionData() public view returns(uint256, uint256, uint256, address) {
        return(auctionStart, auctionDuration, highestBid, highestBidder);
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function auctionExpired() public view returns (bool) {
        return now > (SafeMath.add(auctionStart, auctionDuration));
    }

    function bidOnWonder() public payable {
        require(!_isContract(msg.sender));
        require(!auctionExpired());
        require(msg.value >= (highestBid + 10000000000000000));

        if (highestBid != 0) {
            highestBidder.transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function endAuction() public onlyOwner {
        require(auctionExpired());
        require(!ended);
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // Transfer the item to the buyer
        Wonder(WonderOwnershipAdd).transfer(highestBidder, wonderId);

        paymentAddress.transfer(address(this).balance);
    }
}

contract Wonder is ERC721, CryptoRomeControl {
    
    // Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "CryptoRomeWonder";
    string public constant symbol = "CROMEW";

    uint256[] internal allWonderTokens;

    mapping(uint256 => string) internal tokenURIs;
    address public originalAuction;
    mapping (uint256 => bool) public wonderForSale;
    mapping (uint256 => uint256) public askingPrice;

    // Map of Wonder to the owner
    mapping (uint256 => address) public wonderIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) wonderIndexToApproved;
    
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(wonderIndexToOwner[_tokenId] == msg.sender);
        _;
    }

    function updateTokenUri(uint256 _tokenId, string _tokenURI) public whenNotPaused onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function startWonderAuction(string _tokenURI, address wallet) public whenNotPaused onlyOwner {
        uint256 finalId = _createWonder(msg.sender);
        _setTokenURI(finalId, _tokenURI);
        //Starting auction
        originalAuction = new CryptoRomeAuction(now, 10 finney, 1 weeks, wallet, finalId, msg.sender);
        _transfer(msg.sender, originalAuction, finalId);
    }
    
    function createWonderNotAuction(string _tokenURI) public whenNotPaused onlyOwner returns (uint256) {
        uint256 finalId = _createWonder(msg.sender);
        _setTokenURI(finalId, _tokenURI);
        return finalId;
    }
    
    function sellWonder(uint256 _wonderId, uint256 _askingPrice) onlyOwnerOf(_wonderId) whenNotPaused public {
        wonderForSale[_wonderId] = true;
        askingPrice[_wonderId] = _askingPrice;
    }
    
    function cancelWonderSale(uint256 _wonderId) onlyOwnerOf(_wonderId) whenNotPaused public {
        wonderForSale[_wonderId] = false;
        askingPrice[_wonderId] = 0;
    }
    
    function purchaseWonder(uint256 _wonderId) whenNotPaused public payable {
        require(wonderForSale[_wonderId]);
        require(msg.value >= askingPrice[_wonderId]);
        wonderForSale[_wonderId] = false;
        uint256 fee = devFee(msg.value);
        ceoWallet.transfer(fee);
        wonderIndexToOwner[_wonderId].transfer(SafeMath.sub(address(this).balance, fee));
        _transfer(wonderIndexToOwner[_wonderId], msg.sender, _wonderId);
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to] = SafeMath.add(ownershipTokenCount[_to], 1);
        wonderIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            // clear any previously approved ownership exchange
            ownershipTokenCount[_from] = SafeMath.sub(ownershipTokenCount[_from], 1);
            delete wonderIndexToApproved[_tokenId];
        }
    }

    function _createWonder(address _owner) internal returns (uint) {
        uint256 newWonderId = allWonderTokens.push(allWonderTokens.length) - 1;
        wonderForSale[newWonderId] = false;

        // Only 8 wonders should ever exist (0-7)
        require(newWonderId < 8);
        _transfer(0, _owner, newWonderId);
        return newWonderId;
    }
    
    function devFee(uint256 amount) internal pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount, 3), 100);
    }
    
    // Functions for ERC721 Below:

    // Check is address has approval to transfer wonder.
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return wonderIndexToApproved[_tokenId] == _claimant;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = wonderIndexToOwner[_tokenId];
        return owner != address(0);
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }

    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }

    // Sets a wonder as approved for transfer to another address.
    function _approve(uint256 _tokenId, address _approved) internal {
        wonderIndexToApproved[_tokenId] = _approved;
    }

    // Returns the number of Wonders owned by a specific address.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    // Transfers a Wonder to another address. If transferring to a smart
    // contract ensure that it is aware of ERC-721.
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));

        _transfer(msg.sender, _to, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    //  Permit another address the right to transfer a specific Wonder via
    //  transferFrom(). 
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        _approve(_tokenId, _to);

        emit Approval(msg.sender, _to, _tokenId);
    }

    // Transfer a Wonder owned by another address, for which the calling address
    // has previously been granted transfer approval by the owner.
    function takeOwnership(uint256 _tokenId) public {

    require(wonderIndexToApproved[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
    emit Transfer(owner, msg.sender, _tokenId);

  }

    // Eight Wonders will ever exist
    function totalSupply() public view returns (uint) {
        return 8;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = wonderIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    // List of all Wonder IDs assigned to an address.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalWonders = totalSupply();
            uint256 resultIndex = 0;
            uint256 wonderId;

            for (wonderId = 0; wonderId < totalWonders; wonderId++) {
                if (wonderIndexToOwner[wonderId] == _owner) {
                    result[resultIndex] = wonderId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
}

library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
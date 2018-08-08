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

contract Centurions is ERC721, CryptoRomeControl {

    // Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "CryptoRomeCenturion";
    string public constant symbol = "CROMEC";

    struct Centurion {
        uint256 level;
        uint256 experience;
        uint256 askingPrice;
    }

    uint256[50] public expForLevels = [
        0,   // 0
        20,
        50,
        100,
        200,
        400,  // 5
        800,
        1400,
        2100,
        3150,
        4410,  // 10
        5740,
        7460,
        8950,
        10740,
        12880,
        15460,
        18550,
        22260,
        26710,
        32050, // 20
        38500,
        46200,
        55400,
        66500,
        79800,
        95700,
        115000,
        138000,
        166000,
        200000, // 30
        240000,
        290000,
        350000,
        450000,
        580000,
        820000,
        1150000,
        1700000,
        2600000,
        3850000, // 40
        5800000,
        8750000,
        13000000,
        26000000,
        52000000,
        104000000,
        208000000,
        416000000,
        850000000 // 49
    ];

    Centurion[] internal allCenturionTokens;

    string internal tokenURIs;

    // Map of Centurion to the owner
    mapping (uint256 => address) public centurionIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) centurionIndexToApproved;

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(centurionIndexToOwner[_tokenId] == msg.sender);
        _;
    }

    function getCenturion(uint256 _tokenId) external view
        returns (
            uint256 level,
            uint256 experience,
            uint256 askingPrice
        ) {
        Centurion storage centurion = allCenturionTokens[_tokenId];

        level = centurion.level;
        experience = centurion.experience;
        askingPrice = centurion.askingPrice;
    }

    function updateTokenUri(uint256 _tokenId, string _tokenURI) public whenNotPaused onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function createCenturion() public whenNotPaused onlyOwner returns (uint256) {
        uint256 finalId = _createCenturion(msg.sender);
        return finalId;
    }

    function issueCenturion(address _to) public whenNotPaused onlyOwner returns (uint256) {
        uint256 finalId = _createCenturion(msg.sender);
        _transfer(msg.sender, _to, finalId);
        return finalId;
    }

    function listCenturion(uint256 _askingPrice) public whenNotPaused onlyOwner returns (uint256) {
        uint256 finalId = _createCenturion(msg.sender);
        allCenturionTokens[finalId].askingPrice = _askingPrice;
        return finalId;
    }

    function sellCenturion(uint256 _tokenId, uint256 _askingPrice) onlyOwnerOf(_tokenId) whenNotPaused public {
        allCenturionTokens[_tokenId].askingPrice = _askingPrice;
    }

    function cancelCenturionSale(uint256 _tokenId) onlyOwnerOf(_tokenId) whenNotPaused public {
        allCenturionTokens[_tokenId].askingPrice = 0;
    }

    function purchaseCenturion(uint256 _tokenId) whenNotPaused public payable {
        require(allCenturionTokens[_tokenId].askingPrice > 0);
        require(msg.value >= allCenturionTokens[_tokenId].askingPrice);
        allCenturionTokens[_tokenId].askingPrice = 0;
        uint256 fee = devFee(msg.value);
        ceoWallet.transfer(fee);
        centurionIndexToOwner[_tokenId].transfer(SafeMath.sub(address(this).balance, fee));
        _transfer(centurionIndexToOwner[_tokenId], msg.sender, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to] = SafeMath.add(ownershipTokenCount[_to], 1);
        centurionIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            // clear any previously approved ownership exchange
            ownershipTokenCount[_from] = SafeMath.sub(ownershipTokenCount[_from], 1);
            delete centurionIndexToApproved[_tokenId];
        }
    }

    function _createCenturion(address _owner) internal returns (uint) {
        Centurion memory _centurion = Centurion({
            level: 1,
            experience: 0,
            askingPrice: 0
        });
        uint256 newCenturionId = allCenturionTokens.push(_centurion) - 1;

        // Only 1000 centurions should ever exist (0-999)
        require(newCenturionId < 1000);
        _transfer(0, _owner, newCenturionId);
        return newCenturionId;
    }

    function devFee(uint256 amount) internal pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount, 3), 100);
    }

    // Functions for ERC721 Below:

    // Check is address has approval to transfer centurion.
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return centurionIndexToApproved[_tokenId] == _claimant;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = centurionIndexToOwner[_tokenId];
        return owner != address(0);
    }

    function addExperience(uint256 _tokenId, uint256 _exp) public whenNotPaused onlyOwner returns (uint256) {
        require(exists(_tokenId));
        allCenturionTokens[_tokenId].experience = SafeMath.add(allCenturionTokens[_tokenId].experience, _exp);
        for (uint256 i = allCenturionTokens[_tokenId].level; i < 50; i++) {
            if (allCenturionTokens[_tokenId].experience >= expForLevels[i]) {
               allCenturionTokens[_tokenId].level = allCenturionTokens[_tokenId].level + 1;
            } else {
                break;
            }
        }
        return allCenturionTokens[_tokenId].level;
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs;
    }

    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs = _uri;
    }

    // Sets a centurion as approved for transfer to another address.
    function _approve(uint256 _tokenId, address _approved) internal {
        centurionIndexToApproved[_tokenId] = _approved;
    }

    // Returns the number of Centurions owned by a specific address.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    // Transfers a Centurion to another address. If transferring to a smart
    // contract ensure that it is aware of ERC-721.
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        require(_to != address(0));
        require(_to != address(this));

        _transfer(msg.sender, _to, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    //  Permit another address the right to transfer a specific Centurion via
    //  transferFrom().
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        _approve(_tokenId, _to);

        emit Approval(msg.sender, _to, _tokenId);
    }

    // Transfer a Centurion owned by another address, for which the calling address
    // has previously been granted transfer approval by the owner.
    function takeOwnership(uint256 _tokenId) public {
        require(centurionIndexToApproved[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
        emit Transfer(owner, msg.sender, _tokenId);
  }

    // 1000 Centurions will ever exist
    function totalSupply() public view returns (uint) {
        return allCenturionTokens.length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = centurionIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    // List of all Centurion IDs assigned to an address.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCenturions = totalSupply();
            uint256 resultIndex = 0;
            uint256 centurionId;

            for (centurionId = 0; centurionId < totalCenturions; centurionId++) {
                if (centurionIndexToOwner[centurionId] == _owner) {
                    result[resultIndex] = centurionId;
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
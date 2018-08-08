pragma solidity ^0.4.18;

contract CryptoLandmarks {
    using SafeMath for uint256;

    // ERC721 required events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Event fired whenever landmark is sold
    event LandmarkSold(uint256 tokenId, uint256 price, uint256 nextPrice, address prevOwner, address owner);
    
    // Event fired when price of landmark changes
    event PriceChanged(uint256 tokenId, uint256 price);

    // Event fired for every new landmark created
    event LandmarkCreated(uint256 tokenId, uint256 groupId, uint256 price, address owner);

   
    string public constant NAME = "CryptoLandmarks.co Landmarks"; 
    string public constant SYMBOL = "LANDMARK"; 

    // Initial price of new Landmark
    uint256 private startingPrice = 0.03 ether;
    // Initial price of new Ambassador
    uint256 private ambassadorStartingPrice = 3 ether;

    // count transactions after every withdrawal
    uint256 public transactions = 0;

    // Contract roles
    address public ceo;
    address public coo;

    uint256[] private landmarks;
    
    // landmark to prices
    mapping (uint256 => uint256) landmarkToMaxPrice;
    mapping (uint256 => uint256) landmarkToPrice;
    
    // landmark to owner
    mapping (uint256 => address) landmarkToOwner;
    
    // landmark to ambassador id
    // ambassador is also landmark token
    // every ambassador belongs to self
    mapping (uint256 => uint256) landmarkToAmbassador;
    
    // ambassadors&#39;s landmarks count
    mapping (uint256 => uint256) groupLandmarksCount;

    // withdraw cooldown date of landmark owner
    mapping (address => uint256) public withdrawCooldown;

    mapping (uint256 => address) landmarkToApproved;
    mapping (address => uint256) landmarkOwnershipCount;


    function CryptoLandmarks() public {
        ceo = msg.sender;
        coo = msg.sender;
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < 0.2 ether)
            return _price.mul(2); // 200%
        if (_price < 4 ether)
            return _price.mul(17).div(10); // 170%
        if (_price < 15 ether)
            return _price.mul(141).div(100); // 141%
        else
            return _price.mul(134).div(100); // 134%
    }

    function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
        if (_price < 0.2 ether)
            return 5; // 5%
        if (_price < 4 ether)
            return 4; // 4%
        if (_price < 15 ether)
            return 3; // 3%
        else
            return 2; // 2%
    }   

    /*
        Buy Landmark or Ambassador from contract for calculated price that ensures that:
         - previous owner gets a profit
         - specific Ambassador gets his/her fee
         - every owner of Landmark in an Ambassador group gets a cut
        All funds are sent directly to players and are never stored in the contract.

        Ambassador -> _tokenId < 1000
        Landmark -> _tokenId >= 1000

    */
    function buy(uint256 _tokenId) public payable {
        address oldOwner = landmarkToOwner[_tokenId];
        require(oldOwner != msg.sender);
        require(msg.sender != address(0));
        uint256 sellingPrice = priceOfLandmark(_tokenId);
        require(msg.value >= sellingPrice);

        // excess that will be refunded
        uint256 excess = msg.value.sub(sellingPrice);

        // id of a group = ambassador id
        uint256 groupId = landmarkToAmbassador[_tokenId];

        // number of Landmarks in the group
        uint256 groupMembersCount = groupLandmarksCount[groupId];

        // developer&#39;s cut in % (2-5)
        uint256 devCut = calculateDevCut(sellingPrice);

        // for previous owner
        uint256 payment;
        
        if (_tokenId < 1000) {
            // Buying Ambassador
            payment = sellingPrice.mul(SafeMath.sub(95, devCut)).div(100);
        } else {
            // Buying Landmark
            payment = sellingPrice.mul(SafeMath.sub(90, devCut)).div(100);
        }

        // 5% splitted per all group memebrs
        uint256 feeGroupMember = (sellingPrice.mul(5).div(100)).div(groupMembersCount);


        for (uint i = 0; i < totalSupply(); i++) {
            uint id = landmarks[i];
            if ( landmarkToAmbassador[id] == groupId ) {
                if ( _tokenId == id) {
                    // Transfer payment to previous owner
                    oldOwner.transfer(payment);
                }
                if (groupId == id && _tokenId >= 1000) {
                    // Transfer 5% to Ambassador
                    landmarkToOwner[id].transfer(sellingPrice.mul(5).div(100));
                }

                // Transfer cut to every member of a group
                // since ambassador and old owner are also members they get a cut again too
                landmarkToOwner[id].transfer(feeGroupMember);
            }
        }
        
        uint256 nextPrice = calculateNextPrice(sellingPrice);

        // Set new price
        landmarkToPrice[_tokenId] = nextPrice;

        // Set new maximum price
        landmarkToMaxPrice[_tokenId] = nextPrice;

        // Transfer token
        _transfer(oldOwner, msg.sender, _tokenId);

        // if overpaid, transfer excess back to sender
        if (excess > 0) {
            msg.sender.transfer(excess);
        }

        // increment transactions counter
        transactions++;

        // emit event
        LandmarkSold(_tokenId, sellingPrice, nextPrice, oldOwner, msg.sender);
    }


    // owner can change price
    function changePrice(uint256 _tokenId, uint256 _price) public {
        // only owner can change price
        require(landmarkToOwner[_tokenId] == msg.sender);

        // price cannot be higher than maximum price
        require(landmarkToMaxPrice[_tokenId] >= _price);

        // set new price
        landmarkToPrice[_tokenId] = _price;
        
        // emit event
        PriceChanged(_tokenId, _price);
    }

    function createLandmark(uint256 _tokenId, uint256 _groupId, address _owner, uint256 _price) public onlyCOO {
        // token with id below 1000 is a Ambassador
        if (_price <= 0 && _tokenId >= 1000) {
            _price = startingPrice;
        } else if (_price <= 0 && _tokenId < 1000) {
            _price = ambassadorStartingPrice;
        }
        if (_owner == address(0)) {
            _owner = coo;
        }

        if (_tokenId < 1000) {
            _groupId == _tokenId;
        }

        landmarkToPrice[_tokenId] = _price;
        landmarkToMaxPrice[_tokenId] = _price;
        landmarkToAmbassador[_tokenId] = _groupId;
        groupLandmarksCount[_groupId]++;
        _transfer(address(0), _owner, _tokenId);

        landmarks.push(_tokenId);

        LandmarkCreated(_tokenId, _groupId, _price, _owner);
    }

    function getLandmark(uint256 _tokenId) public view returns (
        uint256 ambassadorId,
        uint256 sellingPrice,
        uint256 maxPrice,
        uint256 nextPrice,
        address owner
    ) {
        ambassadorId = landmarkToAmbassador[_tokenId];
        sellingPrice = landmarkToPrice[_tokenId];
        maxPrice = landmarkToMaxPrice[_tokenId];
        nextPrice = calculateNextPrice(sellingPrice);
        owner = landmarkToOwner[_tokenId];
    }

    function priceOfLandmark(uint256 _tokenId) public view returns (uint256) {
        return landmarkToPrice[_tokenId];
    }


    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }
    modifier onlyCOO() {
        require(msg.sender == coo);
        _;
    }
    modifier onlyCLevel() {
        require(
            msg.sender == ceo ||
            msg.sender == coo
        );
        _;
    }
    modifier notCLevel() {
        require(
            msg.sender != ceo ||
            msg.sender != coo
        );
        _;
    }

    /*
        Transfer 0.3% per token to sender
        This function can be invoked by anyone who:
         - has at least 3 tokens
         - waited at least 1 week from previous withdrawal
         - is not a ceo/coo
        Additionally it can be invoked only:
         - when total balance is greater than 1 eth
         - after 10 transactions from previous withdrawal


    */
    function withdrawBalance() external notCLevel {
        // only person owning more than 3 tokens can whitdraw
        require(landmarkOwnershipCount[msg.sender] >= 3);
        
        // player can withdraw only week after his previous withdrawal
        require(withdrawCooldown[msg.sender] <= now);

        // can be invoked after any 10 purchases from previous withdrawal
        require(transactions >= 10);

        uint256 balance = this.balance;

        // balance must be greater than 0.3 ether
        require(balance >= 0.3 ether);

        uint256 senderCut = balance.mul(3).div(1000).mul(landmarkOwnershipCount[msg.sender]);
        
        // transfer 0.3% per Landmark or Ambassador to sender
        msg.sender.transfer(senderCut);

        // set sender withdraw cooldown
        withdrawCooldown[msg.sender] = now + 1 weeks;

        // transfer rest to CEO 
        ceo.transfer(balance.sub(senderCut));

        // set transactions counter to 0
        transactions = 0;

    }

    function transferOwnership(address newOwner) public onlyCEO {
        if (newOwner != address(0)) {
            ceo = newOwner;
        }
    }

    function setCOO(address newCOO) public onlyCOO {
        if (newCOO != address(0)) {
            coo = newCOO;
        }
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        landmarkOwnershipCount[_to]++;
        landmarkToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            landmarkOwnershipCount[_from]--;
            delete landmarkToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    //ERC721 methods
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return landmarks.length;
    }

    function name() public pure returns (string) {
        return NAME;
    }

    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return landmarkOwnershipCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = landmarkToOwner[_tokenId];
        require(owner != address(0));
    }
    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == msg.sender);

        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(address _to, uint256 _tokenId) public {
        require(landmarkToOwner[_tokenId] == msg.sender);
        landmarkToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(landmarkToApproved[_tokenId] == _to);
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == _from);

        _transfer(_from, _to, _tokenId);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        uint256 total = totalSupply();
        uint256 resultIndex = 0;

        for(uint256 i = 0; i <= total; i++) {
            if (landmarkToOwner[i] == _owner) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        return result;
    }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
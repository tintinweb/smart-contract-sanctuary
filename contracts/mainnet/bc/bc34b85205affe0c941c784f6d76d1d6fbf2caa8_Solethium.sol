pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public ownerAddress;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    ownerAddress = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == ownerAddress);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(ownerAddress, newOwner);
    ownerAddress = newOwner;
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


contract Solethium is Ownable, ERC721 {

    uint16 private devCutPromille = 25;

    /**
    ** @dev EVENTS
    **/
    event EventSolethiumObjectCreated(uint256 tokenId, string name);
    event EventSolethiumObjectBought(address oldOwner, address newOwner, uint price);

    // @dev use SafeMath for the following uints
    using SafeMath for uint256; // 1,15792E+77
    using SafeMath for uint32; // 4294967296
    using SafeMath for uint16; // 65536

    //  @dev an object - CrySolObject ( dev expression for Solethium Object)- contains relevant attributes only
    struct CrySolObject {
        string name;
        uint256 price;
        uint256 id;
        uint16 parentID;
        uint16 percentWhenParent;
        address owner;
        uint8 specialPropertyType; // 0=NONE, 1=PARENT_UP
        uint8 specialPropertyValue; // example: 5 meaning 0,5 %
    }
    

    //  @dev an array of all CrySolObject objects in the game
    CrySolObject[] public crySolObjects;
    //  @dev integer - total number of CrySol Objects
    uint16 public numberOfCrySolObjects;
    //  @dev Total number of CrySol ETH worth in the game
    uint256 public ETHOfCrySolObjects;

    mapping (address => uint) public ownerCrySolObjectsCount; // for owner address, track number on tokens owned
    mapping (address => uint) public ownerAddPercentToParent; // adding additional percents to owners of some Objects when they have PARENT objects
    mapping (address => string) public ownerToNickname; // for owner address, track his nickname


    /**
    ** @dev MODIFIERS
    **/
    modifier onlyOwnerOf(uint _id) {
        require(msg.sender == crySolObjects[_id].owner);
        _;
    } 

    /**
    ** @dev NEXT PRICE CALCULATIONS
    **/

    uint256 private nextPriceTreshold1 = 0.05 ether;
    uint256 private nextPriceTreshold2 = 0.3 ether;
    uint256 private nextPriceTreshold3 = 1.0 ether;
    uint256 private nextPriceTreshold4 = 5.0 ether;
    uint256 private nextPriceTreshold5 = 10.0 ether;

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price <= nextPriceTreshold1) {
            return _price.mul(200).div(100);
        } else if (_price <= nextPriceTreshold2) {
            return _price.mul(170).div(100);
        } else if (_price <= nextPriceTreshold3) {
            return _price.mul(150).div(100);
        } else if (_price <= nextPriceTreshold4) {
            return _price.mul(140).div(100);
        } else if (_price <= nextPriceTreshold5) {
            return _price.mul(130).div(100);
        } else {
            return _price.mul(120).div(100);
        }
    }



    /**
    ** @dev this method is used to create CrySol Object
    **/
    function createCrySolObject(string _name, uint _price, uint16 _parentID, uint16 _percentWhenParent, uint8 _specialPropertyType, uint8 _specialPropertyValue) external onlyOwner() {
        uint256 _id = crySolObjects.length;
        crySolObjects.push(CrySolObject(_name, _price, _id, _parentID, _percentWhenParent, msg.sender, _specialPropertyType, _specialPropertyValue)) ; //insert into array
        ownerCrySolObjectsCount[msg.sender] = ownerCrySolObjectsCount[msg.sender].add(1); // increase count for OWNER
        numberOfCrySolObjects = (uint16)(numberOfCrySolObjects.add(1)); // increase count for Total number
        ETHOfCrySolObjects = ETHOfCrySolObjects.add(_price); // increase total ETH worth of all tokens
        EventSolethiumObjectCreated(_id, _name);

    }

    /**
    ** @dev this method is used to GET CrySol Objects from one OWNER
    **/
    function getCrySolObjectsByOwner(address _owner) external view returns(uint[]) {
        uint256 tokenCount = ownerCrySolObjectsCount[_owner];
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint counter = 0;
            for (uint i = 0; i < numberOfCrySolObjects; i++) {
            if (crySolObjects[i].owner == _owner) {
                    result[counter] = i;
                    counter++;
                }
            }
            return result;
        }
    }


    /**
    ** @dev this method is used to GET ALL CrySol Objects in the game
    **/
    function getAllCrySolObjects() external view returns(uint[]) {
        uint[] memory result = new uint[](numberOfCrySolObjects);
        uint counter = 0;
        for (uint i = 0; i < numberOfCrySolObjects; i++) {
                result[counter] = i;
                counter++;
        }
        return result;
    }
    
    /**
    ** @dev this method is used to calculate Developer&#39;s Cut in the game
    **/
    function returnDevelopersCut(uint256 _price) private view returns(uint) {
            return _price.mul(devCutPromille).div(1000);
    }

    /**
    ** @dev this method is used to calculate Parent Object&#39;s Owner Cut in the game
    ** owner of PARENT objects will get : percentWhenParent % from his Objects + any additional bonuses he may have from SPECIAL trade objects
    ** that are increasing PARENT percentage
    **/
    function returnParentObjectCut( CrySolObject storage _obj, uint256 _price ) private view returns(uint) {
        uint256 _percentWhenParent = crySolObjects[_obj.parentID].percentWhenParent + (ownerAddPercentToParent[crySolObjects[_obj.parentID].owner]).div(10);
        return _price.mul(_percentWhenParent).div(100); //_parentCut
    }

    
     /**
    ** @dev this method is used to TRANSFER OWNERSHIP of the CrySol Objects in the game on the BUY event
    **/
    function _transferOwnershipOnBuy(address _oldOwner, uint _id, address _newOwner) private {
            // decrease count for original OWNER
            ownerCrySolObjectsCount[_oldOwner] = ownerCrySolObjectsCount[_oldOwner].sub(1); 

            // new owner gets ownership
            crySolObjects[_id].owner = _newOwner;  
            ownerCrySolObjectsCount[_newOwner] = ownerCrySolObjectsCount[_newOwner].add(1); // increase count for the new OWNER

            ETHOfCrySolObjects = ETHOfCrySolObjects.sub(crySolObjects[_id].price);
            crySolObjects[_id].price = calculateNextPrice(crySolObjects[_id].price); // now, calculate and update next price
            ETHOfCrySolObjects = ETHOfCrySolObjects.add(crySolObjects[_id].price);
    }
    



    /**
    ** @dev this method is used to BUY CrySol Objects in the game, defining what will happen with the next price
    **/
    function buyCrySolObject(uint _id) external payable {

            CrySolObject storage _obj = crySolObjects[_id];
            uint256 price = _obj.price;
            address oldOwner = _obj.owner; // seller
            address newOwner = msg.sender; // buyer

            require(msg.value >= price);
            require(msg.sender != _obj.owner); // can&#39;t buy again the same thing!

            uint256 excess = msg.value.sub(price);
            
            // calculate if percentage will go to parent Object owner 
            crySolObjects[_obj.parentID].owner.transfer(returnParentObjectCut(_obj, price));

            // Transfer payment to old owner minus the developer&#39;s cut, parent owner&#39;s cut and any special Object&#39;s cut.
             uint256 _oldOwnerCut = 0;
            _oldOwnerCut = price.sub(returnDevelopersCut(price));
            _oldOwnerCut = _oldOwnerCut.sub(returnParentObjectCut(_obj, price));
            oldOwner.transfer(_oldOwnerCut);

            // if there was excess in payment, return that to newOwner buying Object!
            if (excess > 0) {
                newOwner.transfer(excess);
            }

            //if the sell object has special property, we have to update ownerAddPercentToParent for owners addresses
            // 0=NONE, 1=PARENT_UP
            if (_obj.specialPropertyType == 1) {
                if (oldOwner != ownerAddress) {
                    ownerAddPercentToParent[oldOwner] = ownerAddPercentToParent[oldOwner].sub(_obj.specialPropertyValue);
                }
                ownerAddPercentToParent[newOwner] = ownerAddPercentToParent[newOwner].add(_obj.specialPropertyValue);
            } 

            _transferOwnershipOnBuy(oldOwner, _id, newOwner);
            
            // fire event
            EventSolethiumObjectBought(oldOwner, newOwner, price);

    }


    /**
    ** @dev this method is used to SET user&#39;s nickname
    **/
    function setOwnerNickName(address _owner, string _nickName) external {
        require(msg.sender == _owner);
        ownerToNickname[_owner] = _nickName; // set nickname
    }

    /**
    ** @dev this method is used to GET user&#39;s nickname
    **/
    function getOwnerNickName(address _owner) external view returns(string) {
        return ownerToNickname[_owner];
    }

    /**
    ** @dev some helper / info getter functions
    **/
    function getContractOwner() external view returns(address) {
        return ownerAddress; 
    }
    function getBalance() external view returns(uint) {
        return this.balance;
    }
    function getNumberOfCrySolObjects() external view returns(uint16) {
        return numberOfCrySolObjects;
    }


    /*
        @dev Withdraw All or part of contract balance to Contract Owner address
    */
    function withdrawAll() onlyOwner() public {
        ownerAddress.transfer(this.balance);
    }
    function withdrawAmount(uint256 _amount) onlyOwner() public {
        ownerAddress.transfer(_amount);
    }


    /**
    ** @dev this method is used to modify parentID if needed later;
    **      For this game it is very important to keep intended hierarchy; you never know WHEN exactly transaction will be confirmed in the blockchain
    **      Every Object creation is transaction; if by some accident Objects get "wrong" ID in the crySolObjects array, this is the method where we can adjust parentId
    **      for objects orbiting it (we don&#39;t want for Moon to end up orbiting Mars :) )
    **/
    function setParentID (uint _crySolObjectID, uint16 _parentID) external onlyOwner() {
        crySolObjects[_crySolObjectID].parentID = _parentID;
    }


   /**
   **  @dev ERC-721 compliant methods;
   ** Another contracts can simply talk to us without needing to know anything about our internal contract implementation 
   **/

     mapping (uint => address) crySolObjectsApprovals;

    event Transfer(address indexed _from, address indexed _to, uint256 _id);
    event Approval(address indexed _owner, address indexed _approved, uint256 _id);

    function name() public pure returns (string _name) {
        return "Solethium";
    }

    function symbol() public pure returns (string _symbol) {
        return "SOL";
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return crySolObjects.length;
    } 

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCrySolObjectsCount[_owner];
    }

    function ownerOf(uint256 _id) public view returns (address _owner) {
        return crySolObjects[_id].owner;
    }

    function _transferHelper(address _from, address _to, uint256 _id) private {
        ownerCrySolObjectsCount[_to] = ownerCrySolObjectsCount[_to].add(1);
        ownerCrySolObjectsCount[_from] = ownerCrySolObjectsCount[_from].sub(1);
        crySolObjects[_id].owner = _to;
        Transfer(_from, _to, _id); // fire event
    }

      function transfer(address _to, uint256 _id) public onlyOwnerOf(_id) {
        _transferHelper(msg.sender, _to, _id);
    }

    function approve(address _to, uint256 _id) public onlyOwnerOf(_id) {
        require(msg.sender != _to);
        crySolObjectsApprovals[_id] = _to;
        Approval(msg.sender, _to, _id); // fire event
    }

    function takeOwnership(uint256 _id) public {
        require(crySolObjectsApprovals[_id] == msg.sender);
        _transferHelper(ownerOf(_id), msg.sender, _id);
    }

   


}
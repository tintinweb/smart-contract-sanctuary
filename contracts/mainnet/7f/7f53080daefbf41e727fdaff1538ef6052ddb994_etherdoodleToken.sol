pragma solidity ^0.4.23;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}
/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

contract etherdoodleToken is ERC721 {

    using AddressUtils for address;
    //@dev ERC-721 compliance
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;


//EVENTS
// @dev fired when a pixel&#39;s colour is changed
    event ColourChanged(uint pixelId, uint8 colourR, uint8 colourG, uint8 colourB);

// @dev fired when a pixel&#39;s price is changed
    event PriceChanged(uint pixelId, uint oldPrice, uint newPrice);

// @dev fired when a pixel&#39;s text is changed
    event TextChanged(uint pixelId, string textChanged);

//@dev name for ERC-721
    string constant public name = "etherdoodle";

//@dev symbol for ERC-721
    string constant public symbol = "etherdoodle";

//@dev Starting pixel price
    uint constant public startingPrice = 0.001 ether;


//@dev Switch from 3x to 1.5x per transaction
    uint private constant stepAt = 0.09944 ether;

//@dev The addresses of the accounts 
    address public ceoAddress;


//DATA STRUCTURES
//@dev struct representation of a pixel
    struct Pixel {
        uint32 id;
        uint8 colourR;
        uint8 colourG;
        uint8 colourB;
        string pixelText;
    }

//@dev array holding all pixels
    Pixel[1000000] public pixels;

//MAPPINGS
//@dev mapping from a pixel to its owner
    mapping (uint => address) private pixelToOwner;

//@dev mapping from owner to all of their pixels;
    mapping (address => uint[]) private ownerToPixel;

//@dev mapping from an address to the count of pixels
    mapping (address => uint) private ownerPixelCount;

//@dev mapping from a pixelId to the price of that pixel
    mapping (uint => uint ) private pixelToPrice;

//@dev mapping from a pixel to an approved account for transfer
    mapping(uint => address) public pixelToApproved;

//@dev mapping from an address to another mapping that determines if an operator is approved
    mapping(address => mapping(address=>bool)) internal operatorApprovals;

//MODIFIERS
//@dev access modifiers for ceo
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

//@dev used to verify ownership
    modifier onlyOwnerOf(uint _pixelId) {
        require(msg.sender == ownerOf(_pixelId));
        _;
    }

//@dev used to allow operators to transfer and to manage the pixels
    modifier canManageAndTransfer(uint _pixelId) {
        require(isApprovedOrOwner(msg.sender, _pixelId));
        _;
    }

//@dev make sure that the recipient address is notNull
    modifier notNull(address _to) {
        require(_to != address(0));
        _;
    }

//Constructor
    constructor () public {
        ceoAddress = msg.sender;
    }
///////
// External functions
/////
//@dev function to assign a new CEO
    function assignCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

//@Update All a selected pixels details, can be done by the operator, or the owner
    function updateAllPixelDetails(uint _pixelId, uint8 _colourR, uint8 _colourG, uint8 _colourB,uint _price,string _text) 
    external canManageAndTransfer(_pixelId) {
        require(_price <= pixelToPrice[_pixelId]);
        require(_price >= 0.0001 ether);
        require(bytes(_text).length < 101);
        bool colourChangedBool = false;
        if(pixelToPrice[_pixelId] != _price){
            pixelToPrice[_pixelId] = _price;
            emit PriceChanged(_pixelId,pixelToPrice[_pixelId],_price);
        }
        if(pixels[_pixelId].colourR != _colourR){
            pixels[_pixelId].colourR = _colourR;
            colourChangedBool = true;
        }
        if(pixels[_pixelId].colourG != _colourG){
            pixels[_pixelId].colourG = _colourG;
            colourChangedBool = true;
        }
        if(pixels[_pixelId].colourB != _colourB){
            pixels[_pixelId].colourB = _colourB;
            colourChangedBool = true;
        }
        if (colourChangedBool){
            emit ColourChanged(_pixelId, _colourR, _colourG, _colourB);
        }
        
        if(keccak256(getPixelText(_pixelId)) != keccak256(_text) ){
            pixels[_pixelId].pixelText = _text;
            emit TextChanged(_pixelId,_text);
        }
    }

//@dev add an address to a pixel&#39;s approved list
    function approve(address _to, uint _pixelId) public  {
        address owner = ownerOf(_pixelId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender));
        if(getApproved(_pixelId) != address(0) || _to != address(0)) {
            pixelToApproved[_pixelId] = _to;
            emit Approval(msg.sender, _to, _pixelId);
        }
        
    }

//@dev returns approved Addresses
    function getApproved(uint _pixelId) public view returns(address){
        return pixelToApproved[_pixelId];
    }

//@dev approve all an owner&#39;s pixels to be managed by an address
    function setApprovalForAll(address _to,bool _approved) public{
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }
 

///////////////////
///Public functions
///////////////////

//@dev returns if a pixel has already been purchased
    function exists(uint256 _pixelId) public view returns (bool) {
        address owner = pixelToOwner[_pixelId];
        return owner != address(0);
    }

//@dev returns if an address is approved to manage all another address&#39; pixels
    function isApprovedForAll(address _owner, address _operator) public view returns(bool) {
        return operatorApprovals[_owner][_operator];
    }

//@dev returns the number of pixels an address owns
    function balanceOf(address _owner) public view returns (uint) {
        return ownerPixelCount[_owner];
    }


//@dev returns the owner of a pixel
    function ownerOf(uint _pixelId)  public view returns (address) {
        address owner = pixelToOwner[_pixelId];
        return owner;
    }

//@dev internal function to determine if its approved or an owner
    function isApprovedOrOwner(address _spender, uint _pixelId)internal view returns (bool) {
        address owner = ownerOf(_pixelId);
        return(_spender == owner || getApproved(_pixelId) == _spender || isApprovedForAll(owner,_spender));
    }

//@dev internal function to remove approval on a pixel
    function clearApproval(address _owner, uint256 _pixelId) internal {
        require(ownerOf(_pixelId) == _owner);
        if(pixelToApproved[_pixelId] != address(0)) {
            pixelToApproved[_pixelId] = address(0);
            emit Approval(_owner,address(0),_pixelId);
        }
    }

//@dev returns the total number of pixels generated
    function totalSupply() public view returns (uint) {
        return pixels.length;
    }

//@dev ERC 721 transfer from
    function transferFrom(address _from, address _to, uint _pixelId) public 
    canManageAndTransfer(_pixelId) {
        require(_from != address(0));
        require(_to != address(0));
        clearApproval(_from,_pixelId);
        _transfer(_from, _to, _pixelId);
    }
//@dev ERC 721 safeTransfer from functions
    function safeTransferFrom(address _from, address _to, uint _pixelId) public canManageAndTransfer(_pixelId){
        safeTransferFrom(_from,_to,_pixelId,"");
    }

//@dev ERC 721 safeTransferFrom functions
    function safeTransferFrom(address _from, address _to, uint _pixelId,bytes _data) public canManageAndTransfer(_pixelId){
        transferFrom(_from,_to,_pixelId);
        require(checkAndCallSafeTransfer(_from,_to,_pixelId,_data));
    }

//@dev TRANSFER
    function transfer(address _to, uint _pixelId) public canManageAndTransfer(_pixelId) notNull(_to) {
        _transfer(msg.sender, _to, _pixelId);
    }

//@dev returns all pixel&#39;s data
    function getPixelData(uint _pixelId) public view returns 
    (uint32 _id, address _owner, uint8 _colourR, uint8 _colourG, uint8 _colourB, uint _price,string _text) {
        Pixel storage pixel = pixels[_pixelId];
        _id = pixel.id;
        _price = getPixelPrice(_pixelId);
        _owner = pixelToOwner[_pixelId];
        _colourR = pixel.colourR;
        _colourG = pixel.colourG;
        _colourB = pixel.colourB;
        _text = pixel.pixelText;
    }

//@dev Returns only Text
    function getPixelText(uint _pixelId)public view returns(string) {
        return pixels[_pixelId].pixelText;
    }

//@dev Returns the priceof a pixel
    function getPixelPrice(uint _pixelId) public view returns(uint) {
        uint price = pixelToPrice[_pixelId];
        if (price != 0) {
            return price;
        } else {
            return startingPrice;
            }
        
    } 

    //@dev return the pixels owned by an address
    function getPixelsOwned(address _owner) public view returns(uint[]) {
        return ownerToPixel[_owner];
    }

    //@dev return number of pixels owned by an address
    function getOwnerPixelCount(address _owner) public view returns(uint) {
        return ownerPixelCount[_owner];
    }

    //@dev  return colour
    function getPixelColour(uint _pixelId) public view returns (uint _colourR, uint _colourG, uint _colourB) {
        _colourR = pixels[_pixelId].colourR;
        _colourG = pixels[_pixelId].colourG;
        _colourB = pixels[_pixelId].colourB;
    }

    //@dev payout function to dev
    function payout(address _to) public onlyCEO {
        if (_to == address(0)) {
            ceoAddress.transfer(address(this).balance);
        } else {
            _to.transfer(address(this).balance);
        }  
    }

    //@dev purchase multiple pixels at the same time
    function multiPurchase(uint32[] _Id, uint8[] _R,uint8[] _G,uint8[] _B,string _text) public payable {
        require(_Id.length == _R.length && _Id.length == _G.length && _Id.length == _B.length);
        require(bytes(_text).length < 101);
        address newOwner = msg.sender;
        uint totalPrice = 0;
        uint excessValue = msg.value;
        
        for(uint i = 0; i < _Id.length; i++){
            address oldOwner = ownerOf(_Id[i]);
            require(ownerOf(_Id[i]) != newOwner);
            require(!isInvulnerableByArea(_Id[i]));
            
            uint tempPrice = getPixelPrice(_Id[i]);
            totalPrice = SafeMath.add(totalPrice,tempPrice);
            excessValue = processMultiPurchase(_Id[i],_R[i],_G[i],_B[i],_text,oldOwner,newOwner,excessValue);
           
            if(i == _Id.length-1) {
                require(msg.value >= totalPrice);
                msg.sender.transfer(excessValue);
            }   
        }
        
    } 

    //@dev helper function for processing multiple purchases
    function processMultiPurchase(uint32 _pixelId,uint8 _colourR,uint8 _colourG,uint8 _colourB,string _text, // solium-disable-line
        address _oldOwner,address _newOwner,uint value) private returns (uint excess) {
        uint payment; // payment to previous owner
        uint purchaseExcess; // excess purchase value
        uint sellingPrice = getPixelPrice(_pixelId);
        if(_oldOwner == address(0)) {
            purchaseExcess = uint(SafeMath.sub(value,startingPrice));
            _createPixel((_pixelId), _colourR, _colourG, _colourB,_text);
        } else {
            payment = uint(SafeMath.div(SafeMath.mul(sellingPrice,95), 100));
            purchaseExcess = SafeMath.sub(value,sellingPrice);
            if(pixels[_pixelId].colourR != _colourR || pixels[_pixelId].colourG != _colourG || pixels[_pixelId].colourB != _colourB)
                _changeColour(_pixelId,_colourR,_colourG,_colourB);
            if(keccak256(getPixelText(_pixelId)) != keccak256(_text))
                _changeText(_pixelId,_text);
            clearApproval(_oldOwner,_pixelId);
        }
        if(sellingPrice < stepAt) {
            pixelToPrice[_pixelId] = SafeMath.div(SafeMath.mul(sellingPrice,300),95);
        } else {
            pixelToPrice[_pixelId] = SafeMath.div(SafeMath.mul(sellingPrice,150),95);
        }
        _transfer(_oldOwner, _newOwner,_pixelId);
     
        if(_oldOwner != address(this)) {
            _oldOwner.transfer(payment); 
        }
        return purchaseExcess;
    }
    
    function _changeColour(uint _pixelId,uint8 _colourR,uint8 _colourG, uint8 _colourB) private {
        pixels[_pixelId].colourR = _colourR;
        pixels[_pixelId].colourG = _colourG;
        pixels[_pixelId].colourB = _colourB;
        emit ColourChanged(_pixelId, _colourR, _colourG, _colourB);
    }
    function _changeText(uint _pixelId, string _text) private{
        require(bytes(_text).length < 101);
        pixels[_pixelId].pixelText = _text;
        emit TextChanged(_pixelId,_text);
    }
    

//@dev Invulnerability logic check 
    function isInvulnerableByArea(uint _pixelId) public view returns (bool) {
        require(_pixelId >= 0 && _pixelId <= 999999);
        if (ownerOf(_pixelId) == address(0)) {
            return false;
        }
        uint256 counter = 0;
 
        if (_pixelId == 0 || _pixelId == 999 || _pixelId == 999000 || _pixelId == 999999) {
            return false;
        }

        if (_pixelId < 1000) {
            if (_checkPixelRight(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelLeft(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelUnder(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelUnderRight(_pixelId)) {
                counter = SafeMath.add(counter, 1); 
            }
            if (_checkPixelUnderLeft(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
        }

        if (_pixelId > 999000) {
            if (_checkPixelRight(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelLeft(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelAbove(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelAboveRight(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
            if (_checkPixelAboveLeft(_pixelId)) {
                counter = SafeMath.add(counter, 1);
            }
        }

        if (_pixelId > 999 && _pixelId < 999000) {
            if (_pixelId%1000 == 0 || _pixelId%1000 == 999) {
                if (_pixelId%1000 == 0) {
                    if (_checkPixelAbove(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelAboveRight(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelRight(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelUnder(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelUnderRight(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                } else {
                    if (_checkPixelAbove(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelAboveLeft(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelLeft(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelUnder(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                    if (_checkPixelUnderLeft(_pixelId)) {
                        counter = SafeMath.add(counter, 1);
                    }
                }
            } else {
                if (_checkPixelAbove(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelAboveLeft(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelAboveRight(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelUnder(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelUnderRight(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelUnderLeft(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelRight(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
                if (_checkPixelLeft(_pixelId)) {
                    counter = SafeMath.add(counter, 1);
                }
            }
        }
        return counter >= 5;
    }

   

   

////////////////////
///Private functions
////////////////////
//@dev create a pixel
    function _createPixel (uint32 _id, uint8 _colourR, uint8 _colourG, uint8 _colourB, string _pixelText) private returns(uint) {
        pixels[_id] = Pixel(_id, _colourR, _colourG, _colourB, _pixelText);
        pixelToPrice[_id] = startingPrice;
        emit ColourChanged(_id, _colourR, _colourG, _colourB);
        return _id;
    }

//@dev private function to transfer a pixel from an old address to a new one
    function _transfer(address _from, address _to, uint _pixelId) private {
  //increment new owner pixel count and decrement old owner count and add a pixel to the owners array
        ownerPixelCount[_to] = SafeMath.add(ownerPixelCount[_to], 1);
        ownerToPixel[_to].push(_pixelId);
        if (_from != address(0)) {
            for (uint i = 0; i < ownerToPixel[_from].length; i++) {
                if (ownerToPixel[_from][i] == _pixelId) {
                    ownerToPixel[_from][i] = ownerToPixel[_from][ownerToPixel[_from].length-1];
                    delete ownerToPixel[_from][ownerToPixel[_from].length-1];
                }
            }
            ownerPixelCount[_from] = SafeMath.sub(ownerPixelCount[_from], 1);
        }
        pixelToOwner[_pixelId] = _to;
        emit Transfer(_from, _to, _pixelId);
    }

//@dev helper functions to check for if a pixel purchase is valid
    function _checkPixelAbove(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId-1000)) {
            return true;
        } else {
            return false;
        }
    }
    
    function _checkPixelUnder(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId+1000)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkPixelRight(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId+1)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkPixelLeft(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId-1)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkPixelAboveLeft(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId-1001)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkPixelUnderLeft(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId+999)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkPixelAboveRight(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId-999)) {
            return true;
        } else { 
            return false;
        }
    }
    
    function _checkPixelUnderRight(uint _pixelId) private view returns (bool) {
        if (ownerOf(_pixelId) == ownerOf(_pixelId+1001)) {
            return true;
        } else {  
            return false; 
        }
    }

//@dev ERC721 compliance to check what address it is being sent to
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _pixelId, bytes _data)
    internal
    returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        _from, _pixelId, _data);
        return (retval == ERC721_RECEIVED);
    }
}
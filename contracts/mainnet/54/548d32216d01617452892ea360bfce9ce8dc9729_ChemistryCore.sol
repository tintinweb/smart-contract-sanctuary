pragma solidity ^0.4.19;


contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public{
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        owner = newOwner;
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused(){
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused{
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
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


contract ChemistryBase is Ownable {
    
    struct Element{
        bytes32 symbol;
    }
   
    /*** EVENTS ***/

    event Create(address owner, uint256 atomicNumber, bytes32 symbol);
    
    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a element
    ///  ownership is assigned.
    event Transfer(address from, address to, uint256 tokenId);

    /*** CONSTANTS ***/
    
    // currently known number of elements in periodic table
    uint256 public tableSize = 173;

    /*** STORAGE ***/

    /// @dev An array containing the element struct for all Elements in existence. The ID
    ///  of each element is actually an index of this array.
    Element[] public elements;

    /// @dev A mapping from element IDs to the address that owns them. All elements have
    ///  some valid owner address, even miner elements are created with a non-zero owner.
    mapping (uint256 => address) public elementToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) internal ownersTokenCount;

    /// @dev A mapping from element IDs to an address that has been approved to call
    ///  transferFrom(). Each Element can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public elementToApproved;
    
    mapping (address => bool) public authorized;
    
    mapping (uint256 => uint256) public currentPrice;
    
	function addAuthorization (address _authorized) onlyOwner external {
		authorized[_authorized] = true;
	}

	function removeAuthorization (address _authorized) onlyOwner external {
		delete authorized[_authorized];
	}
	
	modifier onlyAuthorized() {
		require(authorized[msg.sender]);
		_;
	}
    
    /// @dev Assigns ownership of a specific element to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of elements is capped to &#39;numberOfElements&#39;(173) we can&#39;t overflow this
        ownersTokenCount[_to]++;
        // transfer ownership
        elementToOwner[_tokenId] = _to;
        // When creating new element _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownersTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete elementToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new element and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Arise event
    ///  and a Transfer event.
    function _createElement(bytes32 _symbol, uint256 _price)
        internal
        returns (uint256) {
        	    
        address owner = address(this);
        Element memory _element = Element({
            symbol : _symbol
        });
        uint256 newElementId = elements.push(_element) - 1;
        
        currentPrice[newElementId] = _price;
        
        // emit the create event
        Create(owner, newElementId, _symbol);
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, owner, newElementId);

        return newElementId;
    }
    
    function setTableSize(uint256 _newSize) external onlyOwner {
        tableSize = _newSize;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        delete authorized[owner];
        authorized[newOwner] = true;
        super.transferOwnership(newOwner);
    }
}

contract ElementTokenImpl is ChemistryBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "CryptoChemistry";
    string public constant symbol = "CC";

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
        bytes4(keccak256(&#39;takeOwnership(uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /** @dev Checks if a given address is the current owner of the specified Element tokenId.
     * @param _claimant the address we are validating against.
     * @param _tokenId element id
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToOwner[_tokenId] == _claimant;    
    }

    function _ownerApproved(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToOwner[_tokenId] == _claimant && elementToApproved[_tokenId] == address(0);    
    }

    /// @dev Checks if a given address currently has transferApproval for a particular element.
    /// @param _claimant the address we are confirming element is approved for.
    /// @param _tokenId element id
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event.
    function _approve(uint256 _tokenId, address _approved) internal {
        elementToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of tokens owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownersTokenCount[_owner];
    }

    /// @notice Transfers a element to another address
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the element to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) external {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));

        // You can only send your own element.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific element via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the element that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) external {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a element owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the element to be transfered.
    /// @param _to The address that should take ownership of the element. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the element to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of tokens currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256) {
        return elements.length;
    }

    /// @notice Returns the address currently assigned ownership of a given element.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = elementToOwner[_tokenId];

        require(owner != address(0));
    }
    
    function takeOwnership(uint256 _tokenId) external {
        address _from = elementToOwner[_tokenId];
        
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_from != address(0));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, msg.sender, _tokenId);
    }

    /// @notice Returns a list of all element IDs assigned to an address.
    /// @param _owner The owner whose tokens we are interested in.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalElements = totalSupply();
            uint256 resultIndex = 0;

            uint256 elementId;

            for (elementId = 0; elementId < totalElements; elementId++) {
                if (elementToOwner[elementId] == _owner) {
                    result[resultIndex] = elementId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
}

contract ContractOfSale is ElementTokenImpl {
    using SafeMath for uint256;
    
  	event Sold (uint256 elementId, address oldOwner, address newOwner, uint256 price);
  	
  	uint256 private constant LIMIT_1 = 20 finney;
  	uint256 private constant LIMIT_2 = 500 finney;
  	uint256 private constant LIMIT_3 = 2000 finney;
  	uint256 private constant LIMIT_4 = 5000 finney;
  	
  	/* Buying */
  	function calculateNextPrice (uint256 _price) public pure returns (uint256 _nextPrice) {
	    if (_price < LIMIT_1) {
	      return _price.mul(2);//100%
	    } else if (_price < LIMIT_2) {
	      return _price.mul(13500).div(10000);//35%
	    } else if (_price < LIMIT_3) {
	      return _price.mul(12500).div(10000);//25%
	    } else if (_price < LIMIT_4) {
	      return _price.mul(11700).div(10000);//17%
	    } else {
	      return _price.mul(11500).div(10000);//15%
	    }
  	}

	function _calculateOwnerCut (uint256 _price) internal pure returns (uint256 _devCut) {
		if (_price < LIMIT_1) {
	      return _price.mul(1500).div(10000); // 15%
	    } else if (_price < LIMIT_2) {
	      return _price.mul(500).div(10000); // 5%
	    } else if (_price < LIMIT_3) {
	      return _price.mul(400).div(10000); // 4%
	    } else if (_price < LIMIT_4) {
	      return _price.mul(300).div(10000); // 3%
	    } else {
	      return _price.mul(200).div(10000); // 2%
	    }
  	}

	function buy (uint256 _itemId) external payable{
        uint256 price = currentPrice[_itemId];
	    //
        require(currentPrice[_itemId] > 0);
        //
        require(elementToOwner[_itemId] != address(0));
        //
        require(msg.value >= price);
        //
        require(elementToOwner[_itemId] != msg.sender);
        //
        require(msg.sender != address(0));
        
        address oldOwner = elementToOwner[_itemId];
        //
        address newOwner = msg.sender;
        //
        //
        uint256 excess = msg.value.sub(price);
        //
        _transfer(oldOwner, newOwner, _itemId);
        //
        currentPrice[_itemId] = calculateNextPrice(price);
        
        Sold(_itemId, oldOwner, newOwner, price);

        uint256 ownerCut = _calculateOwnerCut(price);

        oldOwner.transfer(price.sub(ownerCut));
        if (excess > 0) {
            newOwner.transfer(excess);
        }
    }
    
	function priceOfElement(uint256 _elementId) external view returns (uint256 _price) {
		return currentPrice[_elementId];
	}

	function priceOfElements(uint256[] _elementIds) external view returns (uint256[] _prices) {
	    uint256 length = _elementIds.length;
	    _prices = new uint256[](length);
	    
	    for(uint256 i = 0; i < length; i++) {
	        _prices[i] = currentPrice[_elementIds[i]];
	    }
	}

	function nextPriceOfElement(uint256 _itemId) public view returns (uint256 _nextPrice) {
		return calculateNextPrice(currentPrice[_itemId]);
	}

}

contract ChemistryCore is ContractOfSale {
    
    function ChemistryCore() public {
        owner = msg.sender;
        authorized[msg.sender] = true;
        
        _createElement("0", 2 ** 255);//philosophers stone is priceless
    }
    
    function addElement(bytes32 _symbol) external onlyAuthorized() {
        uint256 elementId = elements.length + 1;
        
        require(currentPrice[elementId] == 0);
        require(elementToOwner[elementId] == address(0));
        require(elementId <= tableSize + 1);
        
        _createElement(_symbol, 1 finney);
    }
    
    function addElements(bytes32[] _symbols) external onlyAuthorized() {
        uint256 elementId = elements.length + 1;
        
        uint256 length = _symbols.length;
        uint256 size = tableSize + 1;
        for(uint256 i = 0; i < length; i ++) {
            
            require(currentPrice[elementId] == 0);
            require(elementToOwner[elementId] == address(0));
            require(elementId <= size);
            
            _createElement(_symbols[i], 1 finney);
            elementId++;
        }
        
    }

    function withdrawAll() onlyOwner() external {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner() external {
        owner.transfer(_amount);
    }
    
    function() external payable {
        require(msg.sender == address(this));
    }
    
    function getElementsFromIndex(uint32 indexFrom, uint32 count) external view returns (bytes32[] memory elementsData) {
        //check length
        uint256 lenght = (elements.length - indexFrom >= count ? count : elements.length - indexFrom);
        
        elementsData = new bytes32[](lenght);
        for(uint256 i = 0; i < lenght; i ++) {
            elementsData[i] = elements[indexFrom + i].symbol;
        }
    }
    
    function getElementOwners(uint256[] _elementIds) external view returns (address[] memory owners) {
        uint256 lenght = _elementIds.length;
        owners = new address[](lenght);
        
        for(uint256 i = 0; i < lenght; i ++) {
            owners[i] = elementToOwner[_elementIds[i]];
        }
    }
    
	function getElementView(uint256 _id) external view returns (string symbol) {
		symbol = _bytes32ToString(elements[_id].symbol);
    }
	
	function getElement(uint256 _id) external view returns (bytes32 symbol) {
		symbol = elements[_id].symbol;
    }
    
    function getElements(uint256[] _elementIds) external view returns (bytes32[] memory elementsData) {
        elementsData = new bytes32[](_elementIds.length);
        for(uint256 i = 0; i < _elementIds.length; i++) {
            elementsData[i] = elements[_elementIds[i]].symbol;
        }
    }
    
    function getElementInfoView(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice, string _symbol) {
	    _price = currentPrice[_itemId];
		return (elementToOwner[_itemId], _price, calculateNextPrice(_price), _bytes32ToString(elements[_itemId].symbol));
	}
    
    function getElementInfo(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice, bytes32 _symbol) {
	    _price = currentPrice[_itemId];
		return (elementToOwner[_itemId], _price, calculateNextPrice(_price), elements[_itemId].symbol);
	}
    
    function _bytes32ToString(bytes32 data) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint256(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}
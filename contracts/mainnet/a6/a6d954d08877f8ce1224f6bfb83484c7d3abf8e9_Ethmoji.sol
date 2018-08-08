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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
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
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

pragma solidity ^0.4.18;

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @dev Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @dev Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Burns a specific token
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

  /**
   * @dev Tells whether the msg.sender is approved for the given token ID or not
   * This function is not private so it can be extended in further implementations like the operatable ERC721
   * @param _owner address of the owner to query the approval of
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

/**
 * @title Composable
 * Composable - a contract to mint compositions
 */

contract Composable is ERC721Token, Ownable, PullPayment, Pausable {
   
    // Max number of layers for a composition token
    uint public constant MAX_LAYERS = 100;

    // The minimum composition fee for an ethmoji
    uint256 public minCompositionFee = 0.001 ether;

    // Mapping from token ID to composition price
    mapping (uint256 => uint256) public tokenIdToCompositionPrice;
    
    // Mapping from token ID to layers representing it
    mapping (uint256 => uint256[]) public tokenIdToLayers;

    // Hash of all layers to track uniqueness of ethmojis
    mapping (bytes32 => bool) public compositions;

    // Image hashes to track uniquenes of ethmoji images.
    mapping (uint256 => uint256) public imageHashes;

    // Event for emitting new base token created 
    event BaseTokenCreated(uint256 tokenId);
    
    // Event for emitting new composition token created 
    event CompositionTokenCreated(uint256 tokenId, uint256[] layers, address indexed owner);
    
    // Event for emitting composition price changing for a token
    event CompositionPriceChanged(uint256 tokenId, uint256 price, address indexed owner);

    // Whether or not this contract accepts making compositions with other compositions
    bool public isCompositionOnlyWithBaseLayers;
    
// ----- EXPOSED METHODS --------------------------------------------------------------------------

    /**
    * @dev Mints a base token to an address with a given composition price
    * @param _to address of the future owner of the token
    * @param _compositionPrice uint256 composition price for the new token
    */
    function mintTo(address _to, uint256 _compositionPrice, uint256 _imageHash) public onlyOwner {
        uint256 newTokenIndex = _getNextTokenId();
        _mint(_to, newTokenIndex);
        tokenIdToLayers[newTokenIndex] = [newTokenIndex];
        require(_isUnique(tokenIdToLayers[newTokenIndex], _imageHash));
        compositions[keccak256([newTokenIndex])] = true;
        imageHashes[_imageHash] = newTokenIndex;      
        BaseTokenCreated(newTokenIndex);
        _setCompositionPrice(newTokenIndex, _compositionPrice);
    }

    /**
    * @dev Mints a composition emoji
    * @param _tokenIds uint256[] the array of layers that will make up the composition
    */
    function compose(uint256[] _tokenIds,  uint256 _imageHash) public payable whenNotPaused {
        uint256 price = getTotalCompositionPrice(_tokenIds);
        require(msg.sender != address(0) && msg.value >= price);
        require(_tokenIds.length <= MAX_LAYERS);

        uint256[] memory layers = new uint256[](MAX_LAYERS);
        uint actualSize = 0; 

        for (uint i = 0; i < _tokenIds.length; i++) { 
            uint256 compositionLayerId = _tokenIds[i];
            require(_tokenLayersExist(compositionLayerId));
            uint256[] memory inheritedLayers = tokenIdToLayers[compositionLayerId];
            if (isCompositionOnlyWithBaseLayers) { 
                require(inheritedLayers.length == 1);
            }
            require(inheritedLayers.length < MAX_LAYERS);
            for (uint j = 0; j < inheritedLayers.length; j++) { 
                require(actualSize < MAX_LAYERS);
                for (uint k = 0; k < layers.length; k++) { 
                    require(layers[k] != inheritedLayers[j]);
                    if (layers[k] == 0) { 
                        break;
                    }
                }
                layers[actualSize] = inheritedLayers[j];
                actualSize += 1;
            }
            require(ownerOf(compositionLayerId) != address(0));
            asyncSend(ownerOf(compositionLayerId), tokenIdToCompositionPrice[compositionLayerId]);
        }
    
        uint256 newTokenIndex = _getNextTokenId();
        
        tokenIdToLayers[newTokenIndex] = _trim(layers, actualSize);
        require(_isUnique(tokenIdToLayers[newTokenIndex], _imageHash));
        compositions[keccak256(tokenIdToLayers[newTokenIndex])] = true;
        imageHashes[_imageHash] = newTokenIndex;
    
        _mint(msg.sender, newTokenIndex);

        if (msg.value > price) {
            uint256 purchaseExcess = SafeMath.sub(msg.value, price);
            msg.sender.transfer(purchaseExcess);          
        }

        if (!isCompositionOnlyWithBaseLayers) { 
            _setCompositionPrice(newTokenIndex, minCompositionFee);
        }
   
        CompositionTokenCreated(newTokenIndex, tokenIdToLayers[newTokenIndex], msg.sender);
    }

    /**
    * @dev allows an address to withdraw its balance in the contract
    * @param _tokenId uint256 the token ID
    * @return uint256[] list of layers for a token
    */
    function getTokenLayers(uint256 _tokenId) public view returns(uint256[]) {
        return tokenIdToLayers[_tokenId];
    }

    /**
    * @dev given an array of ids, returns whether or not this composition is valid and unique
    * does not assume the layers array is flattened 
    * @param _tokenIds uint256[] an array of token IDs
    * @return bool whether or not the composition is unique
    */
    function isValidComposition(uint256[] _tokenIds, uint256 _imageHash) public view returns (bool) { 
        if (isCompositionOnlyWithBaseLayers) { 
            return _isValidBaseLayersOnly(_tokenIds, _imageHash);
        } else { 
            return _isValidWithCompositions(_tokenIds, _imageHash);
        }
    }

    /**
    * @dev returns composition price of a given token ID
    * @param _tokenId uint256 token ID
    * @return uint256 composition price
    */
    function getCompositionPrice(uint256 _tokenId) public view returns(uint256) { 
        return tokenIdToCompositionPrice[_tokenId];
    }

    /**
    * @dev get total price for minting a composition given the array of desired layers
    * @param _tokenIds uint256[] an array of token IDs
    * @return uint256 price for minting a composition with the desired layers
    */
    function getTotalCompositionPrice(uint256[] _tokenIds) public view returns(uint256) {
        uint256 totalCompositionPrice = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenLayersExist(_tokenIds[i]));
            totalCompositionPrice = SafeMath.add(totalCompositionPrice, tokenIdToCompositionPrice[_tokenIds[i]]);
        }

        totalCompositionPrice = SafeMath.div(SafeMath.mul(totalCompositionPrice, 105), 100);

        return totalCompositionPrice;
    }

    /**
    * @dev sets the composition price for a token ID. 
    * Cannot be lower than the current composition fee
    * @param _tokenId uint256 the token ID
    * @param _price uint256 the new composition price
    */
    function setCompositionPrice(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        _setCompositionPrice(_tokenId, _price);
    }

// ----- PRIVATE FUNCTIONS ------------------------------------------------------------------------

    /**
    * @dev given an array of ids, returns whether or not this composition is valid and unique
    * for when only base layers are allowed
    * does not assume the layers array is flattened 
    * @param _tokenIds uint256[] an array of token IDs
    * @return bool whether or not the composition is unique
    */
    function _isValidBaseLayersOnly(uint256[] _tokenIds, uint256 _imageHash) private view returns (bool) { 
        require(_tokenIds.length <= MAX_LAYERS);
        uint256[] memory layers = new uint256[](_tokenIds.length);

        for (uint i = 0; i < _tokenIds.length; i++) { 
            if (!_tokenLayersExist(_tokenIds[i])) {
                return false;
            }

            if (tokenIdToLayers[_tokenIds[i]].length != 1) {
                return false;
            }

            for (uint k = 0; k < layers.length; k++) { 
                if (layers[k] == tokenIdToLayers[_tokenIds[i]][0]) {
                    return false;
                }
                if (layers[k] == 0) { 
                    layers[k] = tokenIdToLayers[_tokenIds[i]][0];
                    break;
                }
            }
        }
    
        return _isUnique(layers, _imageHash);
    }

    /**
    * @dev given an array of ids, returns whether or not this composition is valid and unique
    * when compositions are allowed
    * does not assume the layers array is flattened 
    * @param _tokenIds uint256[] an array of token IDs
    * @return bool whether or not the composition is unique
    */
    function _isValidWithCompositions(uint256[] _tokenIds, uint256 _imageHash) private view returns (bool) { 
        uint256[] memory layers = new uint256[](MAX_LAYERS);
        uint actualSize = 0; 
        if (_tokenIds.length > MAX_LAYERS) { 
            return false;
        }

        for (uint i = 0; i < _tokenIds.length; i++) { 
            uint256 compositionLayerId = _tokenIds[i];
            if (!_tokenLayersExist(compositionLayerId)) { 
                return false;
            }
            uint256[] memory inheritedLayers = tokenIdToLayers[compositionLayerId];
            require(inheritedLayers.length < MAX_LAYERS);
            for (uint j = 0; j < inheritedLayers.length; j++) { 
                require(actualSize < MAX_LAYERS);
                for (uint k = 0; k < layers.length; k++) { 
                    if (layers[k] == inheritedLayers[j]) {
                        return false;
                    }
                    if (layers[k] == 0) { 
                        break;
                    }
                }
                layers[actualSize] = inheritedLayers[j];
                actualSize += 1;
            }
        }
        return _isUnique(_trim(layers, actualSize), _imageHash);
    }

    /**
    * @dev trims the given array to a given size
    * @param _layers uint256[] the array of layers that will make up the composition
    * @param _size uint the array of layers that will make up the composition
    * @return uint256[] array trimmed to given size
    */
    function _trim(uint256[] _layers, uint _size) private pure returns(uint256[]) { 
        uint256[] memory trimmedLayers = new uint256[](_size);
        for (uint i = 0; i < _size; i++) { 
            trimmedLayers[i] = _layers[i];
        }

        return trimmedLayers;
    }

    /**
    * @dev checks if a token is an existing token by checking if it has non-zero layers
    * @param _tokenId uint256 token ID
    * @return bool whether or not the given tokenId exists according to its layers
    */
    function _tokenLayersExist(uint256 _tokenId) private view returns (bool) { 
        return tokenIdToLayers[_tokenId].length != 0;
    }

    /**
    * @dev set composition price for a token
    * @param _tokenId uint256 token ID
    * @param _price uint256 new composition price
    */
    function _setCompositionPrice(uint256 _tokenId, uint256 _price) private {
        require(_price >= minCompositionFee);
        tokenIdToCompositionPrice[_tokenId] = _price;
        CompositionPriceChanged(_tokenId, _price, msg.sender);
    }

    /**
    * @dev calculates the next token ID based on totalSupply
    * @return uint256 for the next token ID
    */
    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1); 
    }

    /**
    * @dev given an array of ids, returns whether or not this composition is unique
    * assumes the layers are all base layers (flattened)
    * @param _layers uint256[] an array of token IDs
    * @param _imageHash uint256 image hash for the composition
    * @return bool whether or not the composition is unique
    */
    function _isUnique(uint256[] _layers, uint256 _imageHash) private view returns (bool) { 
        return compositions[keccak256(_layers)] == false && imageHashes[_imageHash] == 0;
    }

// ----- ONLY OWNER FUNCTIONS ---------------------------------------------------------------------

    /**
    * @dev payout method for the contract owner to payout contract profits to a given address
    * @param _to address for the payout 
    */
    function payout (address _to) public onlyOwner { 
        totalPayments = 0;
        _to.transfer(this.balance);
    }

    /**
    * @dev sets global default composition fee for all new tokens
    * @param _price uint256 new default composition price
    */
    function setGlobalCompositionFee(uint256 _price) public onlyOwner { 
        minCompositionFee = _price;
    }
}

contract Ethmoji is Composable {
    using SafeMath for uint256;

    string public constant NAME = "Ethmoji";
    string public constant SYMBOL = "EMJ";

    // Mapping from address to emoji representing avatar
    mapping (address => uint256) public addressToAvatar;

    function Ethmoji() public { 
        isCompositionOnlyWithBaseLayers = true;
    }

    /**
    * @dev Mints a base token to an address with a given composition price
    * @param _to address of the future owner of the token
    * @param _compositionPrice uint256 composition price for the new token
    */
    function mintTo(address _to, uint256 _compositionPrice, uint256 _imageHash) public onlyOwner {
        Composable.mintTo(_to, _compositionPrice, _imageHash);
        _setAvatarIfNoAvatarIsSet(_to, tokensOf(_to)[0]);
    }

    /**
    * @dev Mints a composition emoji
    * @param _tokenIds uint256[] the array of layers that will make up the composition
    */
    function compose(uint256[] _tokenIds,  uint256 _imageHash) public payable whenNotPaused {
        Composable.compose(_tokenIds, _imageHash);
        _setAvatarIfNoAvatarIsSet(msg.sender, tokensOf(msg.sender)[0]);


        // Immediately pay out to layer owners
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _withdrawTo(ownerOf(_tokenIds[i]));
        }
    }

// ----- EXPOSED METHODS --------------------------------------------------------------------------

    /**
    * @dev returns the name ETHMOJI
    * @return string ETHMOJI
    */
    function name() public pure returns (string) {
        return NAME;
    }

    /**
    * @dev returns the name EMJ
    * @return string EMJ
    */
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    /**
    * @dev sets avatar for an address
    * @param _tokenId uint256 token ID
    */
    function setAvatar(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        addressToAvatar[msg.sender] = _tokenId;
    }

    /**
    * @dev returns the ID representing the avatar of the address
    * @param _owner address
    * @return uint256 token ID of the avatar associated with that address
    */
    function getAvatar(address _owner) public view returns(uint256) {
        return addressToAvatar[_owner];
    }

    /**
    * @dev transfer ownership of token. keeps track of avatar logic
    * @param _to address to whom the token is being transferred to
    * @param _tokenId uint256 the ID of the token being transferred
    */
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        // If the transferred token was previous owner&#39;s avatar, remove it
        if (addressToAvatar[msg.sender] == _tokenId) {
            _removeAvatar(msg.sender);
        }

        ERC721Token.transfer(_to, _tokenId);
    }

// ----- PRIVATE FUNCTIONS ------------------------------------------------------------------------

    /**
    * @dev sets avatar if no avatar was previously set
    * @param _owner address of the new vatara owner
    * @param _tokenId uint256 token ID
    */
    function _setAvatarIfNoAvatarIsSet(address _owner, uint256 _tokenId) private {
        if (addressToAvatar[_owner] == 0) {
            addressToAvatar[_owner] = _tokenId;
        }
    }

    /**
    * @dev removes avatar for address
    * @param _owner address of the avatar owner
    */
    function _removeAvatar(address _owner) private {
        addressToAvatar[_owner] = 0;
    }

    /**
    * @dev withdraw accumulated balance to the payee
    * @param _payee address to which to withdraw to
    */
    function _withdrawTo(address _payee) private {
        uint256 payment = payments[_payee];

        if (payment != 0 && this.balance >= payment) {
            totalPayments = totalPayments.sub(payment);
            payments[_payee] = 0;

            _payee.transfer(payment);
        }
    }
}
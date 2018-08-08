pragma solidity ^0.4.21;


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
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
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
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}




/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
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
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}



contract PausableToken is ERC721BasicToken, Pausable {
	function approve(address _to, uint256 _tokenId) public whenNotPaused {
		super.approve(_to, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
		super.setApprovalForAll(_operator, _approved);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
		super.transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
		super.safeTransferFrom(_from, _to, _tokenId);
	}
	
	function safeTransferFrom(
	    address _from,
	    address _to,
	    uint256 _tokenId,
	    bytes _data
	  )
	    public whenNotPaused {
		super.safeTransferFrom(_from, _to, _tokenId, _data);
	}
}


/**
 * @title WorldCupFactory
 * @author Cocos
 * @dev Declare token struct, and generated all toekn
 */
contract WorldCupFactory is Claimable, PausableToken {

	using SafeMath for uint256;

	uint public initPrice;

	//string[] public initTokenData = [];

	// @dev Declare token struct    
	struct Country {
		// token name
		string name;
		
		// token current price
		uint price;
	}

	Country[] public countries;

    /// @dev A mapping from countryIDs to an address that has been approved to call
    ///  transferFrom(). Each Country can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
	//mapping (uint => address) internal tokenOwner;

	// @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
	//mapping (address => uint) internal ownedTokensCount;

	
	/// @dev The WorldCupFactory constructor sets the initialized price of One token
	function WorldCupFactory(uint _initPrice) public {
		initPrice = _initPrice;
		paused    = true;
	}

	function createToken() external onlyOwner {
		// Create tokens
		uint length = countries.length;
		for (uint i = length; i < length + 100; i++) {
			if (i >= 836 ) {
				break;
			}

			if (i < 101) {
				_createToken("Country");
			}else {
				_createToken("Player");
			}
		}
	}

	/// @dev Create token with _name, internally.
	function _createToken(string _name) internal {
		uint id = countries.push( Country(_name, initPrice) ) - 1;
		tokenOwner[id] = msg.sender;
		ownedTokensCount[msg.sender] = ownedTokensCount[msg.sender].add(1);
	}

}

/**
 * @title Control and manage
 * @author Cocos
 * @dev Use for owner setting operating income address, PayerInterface.
 * 
 */
contract WorldCupControl is WorldCupFactory {
	/// @dev Operating income address.
	address public cooAddress;


    function WorldCupControl() public {
        cooAddress = msg.sender;
    }

	/// @dev Assigns a new address to act as the COO.
    /// @param _newCOO The address of the new COO.
    function setCOO(address _newCOO) external onlyOwner {
        require(_newCOO != address(0));
        
        cooAddress = _newCOO;
    }

    /// @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyOwner {
        uint balance = address(this).balance;
        
        cooAddress.send(balance);
    }
}


/**
 * @title Define 
 * @author Cocos
 * @dev Provide some function for web front-end that can be use for convenience.
 * 
 */
contract WorldCupHelper is WorldCupControl {

	/// @dev Return tokenid array
	function getTokenByOwner(address _owner) external view returns(uint[]) {
	    uint[] memory result = new uint[](ownedTokensCount[_owner]);
	    uint counter = 0;

	    for (uint i = 0; i < countries.length; i++) {
			if (tokenOwner[i] == _owner) {
				result[counter] = i;
				counter++;
			}
	    }
		return result;
  	}

  	/// @dev Return tokens price list. It gets the same order as ids.
  	function getTokenPriceListByIds(uint[] _ids) external view returns(uint[]) {
  		uint[] memory result = new uint[](_ids.length);
  		uint counter = 0;

  		for (uint i = 0; i < _ids.length; i++) {
  			Country storage token = countries[_ids[i]];
  			result[counter] = token.price;
  			counter++;
  		}
  		return result;
  	}

}

/// @dev PayerInterface must implement ERC20 standard token.
contract PayerInterface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);

	function allowance(address owner, address spender) public view returns (uint256);
  	function transferFrom(address from, address to, uint256 value) public returns (bool);
  	function approve(address spender, uint256 value) public returns (bool);
}

/**
 * @title AuctionPaused
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract AuctionPaused is Ownable {
  event AuctionPause();
  event AuctionUnpause();

  bool public auctionPaused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not auctionPaused.
   */
  modifier whenNotAuctionPaused() {
    require(!auctionPaused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is auctionPaused.
   */
  modifier whenAuctionPaused() {
    require(auctionPaused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function auctionPause() onlyOwner whenNotAuctionPaused public {
    auctionPaused = true;
    emit AuctionPause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function auctionUnpause() onlyOwner whenAuctionPaused public {
    auctionPaused = false;
    emit AuctionUnpause();
  }
}

contract WorldCupAuction is WorldCupHelper, AuctionPaused {

	using SafeMath for uint256;

	event PurchaseToken(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _tokenPrice, uint256 _timestamp, uint256 _purchaseCounter);

	/// @dev ERC721 Token upper limit of price, cap.
	///  Cap is the upper limit of price. It represented eth&#39;s cap if isEthPayable is true 
	///  or erc20 token&#39;s cap if isEthPayable is false.
	///  Note!!! Using &#39;wei&#39; for eth&#39;s cap units. Using minimum units for erc20 token cap units.
	uint public cap;

    uint public finalCap;

	/// @dev 1 equal to 0.001
	/// erc721 token&#39;s price increasing. Each purchase the price increases 5%
	uint public increasePermillage = 50;

	/// @dev 1 equal to 0.001
	/// Exchange fee 2.3%
	uint public sysFeePermillage = 23;


	/// @dev Contract operating income address.
	PayerInterface public payerContract = PayerInterface(address(0));

    /// @dev If isEthPayable is true, users can only use eth to buy current erc721 token.
    ///  If isEthPayable is false, that mean&#39;s users can only use PayerInterface&#39;s token to buy current erc721 token.
    bool public isEthPayable;

    uint public purchaseCounter = 0;

    /// @dev Constructor
    /// @param _initPrice erc721 token initialized price.
    /// @param _cap Upper limit of increase price.
    /// @param _isEthPayable 
    /// @param _address PayerInterface address, it must be a ERC20 contract.
    function WorldCupAuction(uint _initPrice, uint _cap, bool _isEthPayable, address _address) public WorldCupFactory(_initPrice) {
        require( (_isEthPayable == false && _address != address(0)) || _isEthPayable == true && _address == address(0) );

        cap           = _cap;
        finalCap      = _cap.add(_cap.mul(25).div(1000));
        isEthPayable  = _isEthPayable;
        payerContract = PayerInterface(_address);
    }

    function purchaseWithEth(uint _tokenId) external payable whenNotAuctionPaused {
    	require(isEthPayable == true);
    	require(msg.sender != tokenOwner[_tokenId]);

    	/// @dev If `_tokenId` is out of the range of the array,
        /// this will throw automatically and revert all changes.
    	Country storage token = countries[_tokenId];
    	uint nextPrice = _computeNextPrice(token);

    	require(msg.value >= nextPrice);

    	uint fee = nextPrice.mul(sysFeePermillage).div(1000);
    	uint oldOwnerRefund = nextPrice.sub(fee);

    	address oldOwner = ownerOf(_tokenId);

    	// Refund eth to the person who owned this erc721 token.
    	oldOwner.transfer(oldOwnerRefund);

    	// Transfer fee to the cooAddress.
    	cooAddress.transfer(fee);

    	// Transfer eth left go back to the sender.
    	if ( msg.value.sub(oldOwnerRefund).sub(fee) > 0.0001 ether ) {
    		msg.sender.transfer( msg.value.sub(oldOwnerRefund).sub(fee) );
    	}

    	//Update token price
    	token.price = nextPrice;

    	_transfer(oldOwner, msg.sender, _tokenId);

    	emit PurchaseToken(oldOwner, msg.sender, _tokenId, nextPrice, now, purchaseCounter);
        purchaseCounter = purchaseCounter.add(1);
    }

    function purchaseWithToken(uint _tokenId) external whenNotAuctionPaused {
    	require(isEthPayable == false);
    	require(payerContract != address(0));
    	require(msg.sender != tokenOwner[_tokenId]);

        Country storage token = countries[_tokenId];
        uint nextPrice = _computeNextPrice(token);

        // We need to know how much erc20 token allows our contract to transfer.
        uint256 aValue = payerContract.allowance(msg.sender, address(this));
        require(aValue >= nextPrice);

        uint fee = nextPrice.mul(sysFeePermillage).div(1000);
        uint oldOwnerRefund = nextPrice.sub(fee);

        address oldOwner = ownerOf(_tokenId);

        // Refund erc20 token to the person who owned this erc721 token.
        require(payerContract.transferFrom(msg.sender, oldOwner, oldOwnerRefund));

        // Transfer fee to the cooAddress.
        require(payerContract.transferFrom(msg.sender, cooAddress, fee));

        // Update token price
        token.price = nextPrice;

        _transfer(oldOwner, msg.sender, _tokenId);

        emit PurchaseToken(oldOwner, msg.sender, _tokenId, nextPrice, now, purchaseCounter);
        purchaseCounter = purchaseCounter.add(1);

    }

    function getTokenNextPrice(uint _tokenId) public view returns(uint) {
        Country storage token = countries[_tokenId];
        uint nextPrice = _computeNextPrice(token);
        return nextPrice;
    }

    function _computeNextPrice(Country storage token) private view returns(uint) {
        if (token.price >= cap) {
            return finalCap;
        }

    	uint price = token.price;
    	uint addPrice = price.mul(increasePermillage).div(1000);

		uint nextPrice = price.add(addPrice);
		if (nextPrice > cap) {
			nextPrice = cap;
		}

    	return nextPrice;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Clear approval.
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_from, address(0), _tokenId);
        }

        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

}


contract CryptoWCRC is WorldCupAuction {

	string public constant name = "CryptoWCRC";
    
    string public constant symbol = "WCRC";

    function CryptoWCRC(uint _initPrice, uint _cap, bool _isEthPayable, address _address) public WorldCupAuction(_initPrice, _cap, _isEthPayable, _address) {

    }

    function totalSupply() public view returns (uint256) {
    	return countries.length;
    }

}
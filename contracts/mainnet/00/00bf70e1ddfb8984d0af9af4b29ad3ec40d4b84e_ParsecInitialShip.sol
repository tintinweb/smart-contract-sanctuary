pragma solidity ^0.4.23;

// File: contracts/ParsecReferralTracking.sol

contract ParsecReferralTracking {
  mapping (address => address) public referrer;

  event ReferrerUpdated(address indexed _referee, address indexed _referrer);

  function _updateReferrerFor(address _referee, address _referrer) internal {
    if (_referrer != address(0) && _referrer != _referee) {
      referrer[_referee] = _referrer;
      emit ReferrerUpdated(_referee, _referrer);
    }
  }
}

// File: contracts/ParsecShipInfo.sol

contract ParsecShipInfo {
  uint256 public constant TOTAL_SHIP = 900;
  uint256 public constant TOTAL_ARK = 100;
  uint256 public constant TOTAL_HAWKING = 400;
  uint256 public constant TOTAL_SATOSHI = 400;

  uint256 public constant NAME_NOT_AVAILABLE = 0;
  uint256 public constant NAME_ARK = 1;
  uint256 public constant NAME_HAWKING = 2;
  uint256 public constant NAME_SATOSHI = 3;

  uint256 public constant TYPE_NOT_AVAILABLE = 0;
  uint256 public constant TYPE_EXPLORER_FREIGHTER = 1;
  uint256 public constant TYPE_EXPLORER = 2;
  uint256 public constant TYPE_FREIGHTER = 3;

  uint256 public constant COLOR_NOT_AVAILABLE = 0;
  uint256 public constant COLOR_CUSTOM = 1;
  uint256 public constant COLOR_BLACK = 2;
  uint256 public constant COLOR_BLUE = 3;
  uint256 public constant COLOR_BROWN = 4;
  uint256 public constant COLOR_GOLD = 5;
  uint256 public constant COLOR_GREEN = 6;
  uint256 public constant COLOR_GREY = 7;
  uint256 public constant COLOR_PINK = 8;
  uint256 public constant COLOR_RED = 9;
  uint256 public constant COLOR_SILVER = 10;
  uint256 public constant COLOR_WHITE = 11;
  uint256 public constant COLOR_YELLOW = 12;

  function getShip(uint256 _shipId)
    external
    pure
    returns (
      uint256 /* _name */,
      uint256 /* _type */,
      uint256 /* _color */
    )
  {
    return (
      _getShipName(_shipId),
      _getShipType(_shipId),
      _getShipColor(_shipId)
    );
  }

  function _getShipName(uint256 _shipId) internal pure returns (uint256 /* _name */) {
    if (_shipId < 1) {
      return NAME_NOT_AVAILABLE;
    } else if (_shipId <= TOTAL_ARK) {
      return NAME_ARK;
    } else if (_shipId <= TOTAL_ARK + TOTAL_HAWKING) {
      return NAME_HAWKING;
    } else if (_shipId <= TOTAL_SHIP) {
      return NAME_SATOSHI;
    } else {
      return NAME_NOT_AVAILABLE;
    }
  }

  function _getShipType(uint256 _shipId) internal pure returns (uint256 /* _type */) {
    if (_shipId < 1) {
      return TYPE_NOT_AVAILABLE;
    } else if (_shipId <= TOTAL_ARK) {
      return TYPE_EXPLORER_FREIGHTER;
    } else if (_shipId <= TOTAL_ARK + TOTAL_HAWKING) {
      return TYPE_EXPLORER;
    } else if (_shipId <= TOTAL_SHIP) {
      return TYPE_FREIGHTER;
    } else {
      return TYPE_NOT_AVAILABLE;
    }
  }

  function _getShipColor(uint256 _shipId) internal pure returns (uint256 /* _color */) {
    if (_shipId < 1) {
      return COLOR_NOT_AVAILABLE;
    } else if (_shipId == 1) {
      return COLOR_CUSTOM;
    } else if (_shipId <= 23) {
      return COLOR_BLACK;
    } else if (_shipId <= 37) {
      return COLOR_BLUE;
    } else if (_shipId <= 42) {
      return COLOR_BROWN;
    } else if (_shipId <= 45) {
      return COLOR_GOLD;
    } else if (_shipId <= 49) {
      return COLOR_GREEN;
    } else if (_shipId <= 64) {
      return COLOR_GREY;
    } else if (_shipId <= 67) {
      return COLOR_PINK;
    } else if (_shipId <= 77) {
      return COLOR_RED;
    } else if (_shipId <= 83) {
      return COLOR_SILVER;
    } else if (_shipId <= 93) {
      return COLOR_WHITE;
    } else if (_shipId <= 100) {
      return COLOR_YELLOW;
    } else if (_shipId <= 140) {
      return COLOR_BLACK;
    } else if (_shipId <= 200) {
      return COLOR_BLUE;
    } else if (_shipId <= 237) {
      return COLOR_BROWN;
    } else if (_shipId <= 247) {
      return COLOR_GOLD;
    } else if (_shipId <= 330) {
      return COLOR_GREEN;
    } else if (_shipId <= 370) {
      return COLOR_GREY;
    } else if (_shipId <= 380) {
      return COLOR_PINK;
    } else if (_shipId <= 440) {
      return COLOR_RED;
    } else if (_shipId <= 460) {
      return COLOR_SILVER;
    } else if (_shipId <= 500) {
      return COLOR_WHITE;
    } else if (_shipId <= 540) {
      return COLOR_BLACK;
    } else if (_shipId <= 600) {
      return COLOR_BLUE;
    } else if (_shipId <= 637) {
      return COLOR_BROWN;
    } else if (_shipId <= 647) {
      return COLOR_GOLD;
    } else if (_shipId <= 730) {
      return COLOR_GREEN;
    } else if (_shipId <= 770) {
      return COLOR_GREY;
    } else if (_shipId <= 780) {
      return COLOR_PINK;
    } else if (_shipId <= 840) {
      return COLOR_RED;
    } else if (_shipId <= 860) {
      return COLOR_SILVER;
    } else if (_shipId <= TOTAL_SHIP) {
      return COLOR_WHITE;
    } else {
      return COLOR_NOT_AVAILABLE;
    }
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/ParsecShipPricing.sol

contract ParsecShipPricing {
  using SafeMath for uint256;

  uint256 public constant TOTAL_PARSEC_CREDIT_SUPPLY = 30856775800000000;

  // Starting with 30,856,775,800,000,000 (total supply of Parsec Credit, including 6 decimals),
  // each time we multiply the number we have with 0.9995. These are results:
  // 1: 30841347412100000
  // 2: 30825926738393950
  // 4: 30795108518137240.6484875
  // 8: 30733564478368113.80826526098454678
  // 16: 30610845140405444.1555510982248498
  // 32: 30366874565355062.01905741115048326
  // 64: 29884751305352135.55319509943479229
  // 128: 28943346718121670.05118183115407839
  // 256: 27148569399315026.57115329246779589
  // 512: 23885995905943752.64119680273916152
  // 1024: 18489968106737895.55394216521160879
  // 2048: 11079541258752787.70222144092290365
  // 4096: 3978258626243293.616409580784511455
  // 8192: 512903285808596.2996925781077178762
  // 16384: 8525510970373.470528186667481043039
  // 32768: 2355538951.219861249087266462563245
  // 65536: 179.8167049816644768546906209889074
  // 75918: 0.9996399085102312393019871402909541

  uint256[18] private _multipliers = [
    30841347412100000,
    30825926738393950,
    307951085181372406484875,
    3073356447836811380826526098454678,
    306108451404054441555510982248498,
    3036687456535506201905741115048326,
    2988475130535213555319509943479229,
    2894334671812167005118183115407839,
    2714856939931502657115329246779589,
    2388599590594375264119680273916152,
    1848996810673789555394216521160879,
    1107954125875278770222144092290365,
    3978258626243293616409580784511455,
    5129032858085962996925781077178762,
    8525510970373470528186667481043039,
    2355538951219861249087266462563245,
    1798167049816644768546906209889074
  ];

  uint256[18] private _decimals = [
    0, 0, 7, 17, 16,
    17, 17, 17, 17, 17,
    17, 17, 18, 19, 21,
    24, 31
  ];

  function _getShipPrice(
    uint256 _initialPrice,
    uint256 _minutesPassed
  )
    internal
    view
    returns (uint256 /* _price */)
  {
    require(
      _initialPrice <= TOTAL_PARSEC_CREDIT_SUPPLY,
      "Initial ship price must not be greater than total Parsec Credit."
    );

    if (_minutesPassed >> _multipliers.length > 0) {
      return 0;
    }

    uint256 _price = _initialPrice;

    for (uint256 _powerOfTwo = 0; _powerOfTwo < _multipliers.length; _powerOfTwo++) {
      if (_minutesPassed >> _powerOfTwo & 1 > 0) {
        _price = _price
          .mul(_multipliers[_powerOfTwo])
          .div(TOTAL_PARSEC_CREDIT_SUPPLY)
          .div(10 ** _decimals[_powerOfTwo]);
      }
    }

    return _price;
  }
}

// File: contracts/TokenRecipient.sol

interface TokenRecipient {
  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes _extraData
  )
    external;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: contracts/ParsecShipAuction.sol

// solium-disable-next-line lbrace
contract ParsecShipAuction is
  ERC721Token("Parsec Initial Ship", "PIS"),
  ParsecShipInfo,
  ParsecShipPricing,
  ParsecReferralTracking,
  Ownable,
  Pausable
{
  uint256 public constant PARSEC_CREDIT_DECIMALS = 6;

  uint256 public constant FIRST_AUCTIONS_MINIMUM_RAISE = 2 * uint256(10) ** (5 + PARSEC_CREDIT_DECIMALS);

  uint256 public constant SECOND_AUCTIONS_INITIAL_PERCENTAGE = 50;
  uint256 public constant LATER_AUCTIONS_INITIAL_PERCENTAGE = 125;

  uint256 public constant REFERRAL_REWARD_PERCENTAGE = 20;

  ERC20 public parsecCreditContract = ERC20(0x4373D59176891dA98CA6faaa86bd387fc9e12b6E);

  // May 15th, 2018 – 16:00 UTC
  uint256 public firstAuctionsStartDate = 1526400000;

  uint256 public firstAuctionsInitialDuration = 48 hours;
  uint256 public firstAuctionsExtendableDuration = 12 hours;

  uint256 public firstAuctionsExtendedChunkDuration = 1 hours;
  uint256 public firstAuctionsExtendedDuration = 0;

  uint256 public firstAuctionsHighestBid = uint256(10) ** (6 + PARSEC_CREDIT_DECIMALS);
  address public firstAuctionsHighestBidder = address(0);
  address public firstAuctionsReferrer;
  bool public firstAuctionConcluded = false;

  uint256 private _lastAuctionedShipId = 0;
  uint256 private _lastAuctionsWinningBid;
  uint256 private _lastAuctionWinsDate;

  event FirstShipBidded(
    address indexed _bidder,
    uint256 _value,
    address indexed _referrer
  );

  event LaterShipBidded(
    uint256 indexed _shipId,
    address indexed _winner,
    uint256 _value,
    address indexed _referrer
  );

  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes _extraData
  )
    external
    whenNotPaused
  {
    require(_token == address(parsecCreditContract));
    require(_extraData.length == 64);

    uint256 _shipId;
    address _referrer;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      _shipId := calldataload(164)
      _referrer := calldataload(196)
    }

    if (_shipId == 1) {
      _bidFirstShip(_value, _from, _referrer);
    } else {
      _bidLaterShip(_shipId, _value, _from, _referrer);
    }
  }

  function getFirstAuctionsRemainingDuration() external view returns (uint256 /* _duration */) {
    uint256 _currentDate = now;
    uint256 _endDate = getFirstAuctionsEndDate();

    if (_endDate >= _currentDate) {
      return _endDate - _currentDate;
    } else {
      return 0;
    }
  }

  function concludeFirstAuction() external {
    require(getLastAuctionedShipId() >= 1, "The first auction must have ended.");
    require(!firstAuctionConcluded, "The first auction must not have been concluded.");

    firstAuctionConcluded = true;

    if (firstAuctionsHighestBidder != address(0)) {
      _mint(firstAuctionsHighestBidder, 1);

      if (firstAuctionsReferrer != address(0)) {
        _sendTo(
          firstAuctionsReferrer,
          firstAuctionsHighestBid.mul(REFERRAL_REWARD_PERCENTAGE).div(100)
        );
      }
    } else {
      _mint(owner, 1);
    }
  }

  function getFirstAuctionsExtendableStartDate() public view returns (uint256 /* _extendableStartDate */) {
    return firstAuctionsStartDate
      // solium-disable indentation
      .add(firstAuctionsInitialDuration)
      .sub(firstAuctionsExtendableDuration);
      // solium-enable indentation
  }

  function getFirstAuctionsEndDate() public view returns (uint256 /* _endDate */) {
    return firstAuctionsStartDate
      .add(firstAuctionsInitialDuration)
      .add(firstAuctionsExtendedDuration);
  }

  function getLastAuctionedShipId() public view returns (uint256 /* _shipId */) {
    if (_lastAuctionedShipId == 0 && now >= getFirstAuctionsEndDate()) {
      return 1;
    } else {
      return _lastAuctionedShipId;
    }
  }

  function getLastAuctionsWinningBid() public view returns (uint256 /* _value */) {
    if (_lastAuctionedShipId == 0 && now >= getFirstAuctionsEndDate()) {
      return firstAuctionsHighestBid;
    } else {
      return _lastAuctionsWinningBid;
    }
  }

  function getLastAuctionWinsDate() public view returns (uint256 /* _date */) {
    if (_lastAuctionedShipId == 0) {
      uint256 _firstAuctionsEndDate = getFirstAuctionsEndDate();

      if (now >= _firstAuctionsEndDate) {
        return _firstAuctionsEndDate;
      }
    }

    return _lastAuctionWinsDate;
  }

  function getShipPrice(uint256 _shipId) public view returns (uint256 /* _price */) {
    uint256 _minutesPassed = now
      .sub(getLastAuctionWinsDate())
      .div(1 minutes);

    return getShipPrice(_shipId, _minutesPassed);
  }

  function getShipPrice(uint256 _shipId, uint256 _minutesPassed) public view returns (uint256 /* _price */) {
    require(_shipId >= 2, "Ship ID must be greater than or equal to 2.");
    require(_shipId <= TOTAL_SHIP, "Ship ID must be smaller than or equal to total number of ship.");
    require(_shipId == getLastAuctionedShipId().add(1), "Can only get price of the ship which is being auctioned.");

    uint256 _initialPrice = getLastAuctionsWinningBid();

    if (_shipId == 2) {
      _initialPrice = _initialPrice
        .mul(SECOND_AUCTIONS_INITIAL_PERCENTAGE)
        .div(100);
    } else {
      _initialPrice = _initialPrice
        .mul(LATER_AUCTIONS_INITIAL_PERCENTAGE)
        .div(100);
    }

    return _getShipPrice(_initialPrice, _minutesPassed);
  }

  function _bidFirstShip(uint256 _value, address _bidder, address _referrer) internal {
    require(now >= firstAuctionsStartDate, "Auction of the first ship is not started yet.");
    require(now < getFirstAuctionsEndDate(), "Auction of the first ship has ended.");

    require(_value >= firstAuctionsHighestBid.add(FIRST_AUCTIONS_MINIMUM_RAISE), "Not enough Parsec Credit.");

    _updateReferrerFor(_bidder, _referrer);
    _receiveFrom(_bidder, _value);

    if (firstAuctionsHighestBidder != address(0)) {
      _sendTo(firstAuctionsHighestBidder, firstAuctionsHighestBid);
    }

    firstAuctionsHighestBid = _value;
    firstAuctionsHighestBidder = _bidder;

    // To prevent the first auction&#39;s referrer being overriden,
    // since later auction&#39;s bidders could be the same as the first auction&#39;s bidder
    // but their referrers could be different.
    firstAuctionsReferrer = referrer[_bidder];

    if (now >= getFirstAuctionsExtendableStartDate()) {
      firstAuctionsExtendedDuration = firstAuctionsExtendedDuration
        .add(firstAuctionsExtendedChunkDuration);
    }

    emit FirstShipBidded(_bidder, _value, referrer[_bidder]);
  }

  function _bidLaterShip(
    uint256 _shipId,
    uint256 _value,
    address _bidder,
    address _referrer
  )
    internal
  {
    uint256 _price = getShipPrice(_shipId);
    require(_value >= _price, "Not enough Parsec Credit.");

    _updateReferrerFor(_bidder, _referrer);

    if (_price > 0) {
      _receiveFrom(_bidder, _price);
    }

    _mint(_bidder, _shipId);

    _lastAuctionedShipId = _shipId;
    _lastAuctionsWinningBid = _price;
    _lastAuctionWinsDate = now;

    if (referrer[_bidder] != address(0) && _price > 0) {
      _sendTo(referrer[_bidder], _price.mul(REFERRAL_REWARD_PERCENTAGE).div(100));
    }

    emit LaterShipBidded(
      _shipId,
      _bidder,
      _value,
      referrer[_bidder]
    );
  }

  function _receiveFrom(address _from, uint256 _value) internal {
    parsecCreditContract.transferFrom(_from, this, _value);
  }

  function _sendTo(address _to, uint256 _value) internal {
    // Not like when transferring ETH, we are not afraid of a DoS attack here
    // because Parsec Credit contract is trustable and there are no callbacks involved.
    // solium-disable-next-line security/no-low-level-calls
    require(address(parsecCreditContract).call(
      bytes4(keccak256("transfer(address,uint256)")),
      _to,
      _value
    ), "Parsec Credit transfer failed.");
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoContracts.sol

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="e391868e808ca3d1">[email&#160;protected]</span>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="2153444c424e6113">[email&#160;protected]</span>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    // solium-disable-next-line security/no-send
    assert(owner.send(address(this).balance));
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="4735222a24280775">[email&#160;protected]</span>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

// File: openzeppelin-solidity/contracts/ownership/NoOwner.sol

/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="b8caddd5dbd7f88a">[email&#160;protected]</span>π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

// File: contracts/ParsecInitialShip.sol

// solium-disable-next-line lbrace
contract ParsecInitialShip is
  ParsecShipAuction,
  NoOwner
{
  function reclaimToken(ERC20Basic token) external onlyOwner {
    require(token != parsecCreditContract); // Use `reclaimParsecCredit()` instead!
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

  function reclaimParsecCredit() external onlyOwner {
    require(firstAuctionConcluded, "The first auction must have been concluded.");
    _sendTo(owner, parsecCreditContract.balanceOf(this));
  }
}
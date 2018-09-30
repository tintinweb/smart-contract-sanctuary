pragma solidity ^0.4.25;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
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
    
    
    
  function decodeTokenId(uint value) external pure returns (int, int);
  function encodeTokenId(int x, int y) external pure returns (uint);
  function setUpdateOperator(uint tokenId, address beneficiary) external pure;

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
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// File: contracts/ILANDGiveaway.sol

interface ILANDGiveaway {
    
    function availableLand() public view returns (int[] memory x, int[] memory y);
    
    function getLand(int x, int y) public;
    
    function reclaimableLand() public view returns (uint);
    
    function reclaimLand(int x, int y) public;
    
    function rentedLand() public view returns (int[] memory x, int[] memory y);
}

// File: contracts/LANDGiveaway.sol

contract LANDGiveaway is ILANDGiveaway, Ownable, ERC721Receiver {

    mapping (int => mapping (int => address)) public rentedTo;
    mapping (int => mapping (int => uint)) public expires;

    uint256 public rentedLands;
    uint256 public rentTime = 60 * 60 * 24;

    ERC721 public land = ERC721(0x09ea84f780cfc6b10bafe7b26c8f7b1f3d2da112);

    function availableLand() public view returns (int[] memory, int[] memory) {
        uint balance = land.balanceOf(this);
        uint amount = balance - rentedLands;

        int x;
        int y;

        int[] memory xs = new int[](amount);
        int[] memory ys = new int[](amount);

        uint count = 0;
        for (uint index = 0; index < balance; index++) {
            (x, y) = land.decodeTokenId(land.tokenOfOwnerByIndex(this, index));
            if (rentedTo[x][y] == 0) {
                xs[count] = x;
                ys[count] = y;
                count++;
            }
        }
        return (xs, ys);
    }

    function getLand(int x, int y) public {
        getLand(x, y, msg.sender);
    }

    function getLand(int x, int y, address beneficiary) public {
        if (rentedTo[x][y] != 0) {
            if (expires[x][y] < now) {
                reclaimLand(x, y);
            }
            revert(&#39;Already rented&#39;);
        }
        uint tokenId = land.encodeTokenId(x, y);

        rentedTo[x][y] = beneficiary;
        expires[x][y] = now + rentTime;
        rentedLands += 1;
        land.setUpdateOperator(tokenId, beneficiary);
    }

    function setRentTime(uint time) public onlyOwner {
        rentTime = time;
    }

    function reclaimableLand() public view returns (uint) {
        uint balance = land.balanceOf(this);

        int x;
        int y;

        uint count = 0;
        for (uint index = 0; index < balance; index++) {
            (x, y) = land.decodeTokenId(land.tokenOfOwnerByIndex(this, index));
            if (rentedTo[x][y] != 0 && expires[x][y] < now) {
                count++;
            }
        }
        return count;
    }

    function reclaimLand(int x, int y) public {
        if (rentedTo[x][y] != 0 && expires[x][y] < now) {
            rentedTo[x][y] = 0;
            expires[x][y] = 0;
            land.setUpdateOperator(land.encodeTokenId(x, y), 0);
            rentedLands -= 1;
        }
    }

    function rentedLand() public view returns (int[] memory xs, int[] memory ys) {
        uint balance = land.balanceOf(this);
        uint amount = balance - rentedLands;

        uint count = 0;
        int x;
        int y;

        xs = new int[](amount);
        ys = new int[](amount);

        for (uint index = 0; index < balance; index++) {
            (x, y) = land.decodeTokenId(land.tokenOfOwnerByIndex(this, index));
            if (rentedTo[x][y] != 0 && expires[x][y] > now) {
                xs[count] = x;
                ys[count] = y;
                count++;
            }
        }
        return (xs, ys);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns (bytes4)
    {
        require(msg.sender == address(land));
        return ERC721_RECEIVED;
    }
}
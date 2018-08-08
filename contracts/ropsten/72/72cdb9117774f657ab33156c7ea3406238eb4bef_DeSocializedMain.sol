pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath
{
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
library SafeMath32
{
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
library SafeMath16
{
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
pragma solidity ^0.4.24;

/**
 * @title DeSocializedAdmin
 * @author Chad R. Banks
 * @dev This contract provides basic authorization control functions.
 */
 

contract DeSocializedAdmin
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    mapping (address => uint256) admins;
    mapping (string => uint256) options;
    
    address public feewallet;
    
    event AdminOptionChange(address indexed admin, string option, uint256 value);
    event AdminStatusChange(address indexed admin, uint256 newStatus);
    event AdminWalletChange(address indexed admin, address indexed wallet);
    event AdminWithdrawl(address indexed admin, uint256 amount);
  
    /**
    * @dev The DeSocializedAdmin constructor sets the original values.
    */
    constructor() public
    {
        feewallet = msg.sender;
        admins[msg.sender] = 100;
        options["likefee"] = 1000000000000;     // 0.000001 ETH
        options["dissfee"] = 1000000000000;     // 0.000001 ETH
        options["minefee"] = 10000000000000;    // 0.00001 ETH
        options["regifee"] = 10000000000000000; // 0.01 ETH
    }
  
    /**
    * @dev Throws if called by any address other than an admin.
    */
    modifier onlyAdmin()
    {
        require(admins[msg.sender] >= 1);
        _;
    }
  
    /**
    * @dev Allows the current owner to add/remove another admins status.
    */
    function setAdminStatus(address user, uint status) public onlyAdmin
    {
        require(user != address(0));
        require(status <= admins[msg.sender]);
        require(admins[user] <= admins[msg.sender]);
        admins[user] = status;
        emit AdminStatusChange(user, status);
    }
    
    /**
     * @dev Return the admin status for another address.
     */
    function getAdminStatus(address user) public view returns(uint)
    {
        return admins[user];
    }
    
    /**
     * @dev Change the wallet that funds are stored in.
     */
    function setFeeWallet(address _wallet) public onlyAdmin
    {
        feewallet = _wallet;
        emit AdminWalletChange(msg.sender, _wallet);
    }
    
    /**
     * @dev Change an options value.
     */
    function setOption(string option, uint value) public onlyAdmin
    {
        options[option] = value;
        emit AdminOptionChange(msg.sender, option, value);
    }
    
    /**
     * @dev Returns the option value for a given key.
     */
    function getOption(string option) public view returns(uint)
    {
        return options[option];
    }
    
    /**
     * @dev Returns the eth balance of this wallet
     */
    function getWalletBalance( ) public view returns(uint)
    {
        return address(this).balance;
    }
    
    /**
     * @dev Withdraw funds from this contract.
     */
    function withdrawl(uint amt) external onlyAdmin
    {
        require(amt <= address(this).balance);
        msg.sender.transfer(amt);
        emit AdminWithdrawl(msg.sender, amt);
    }
}
pragma solidity ^0.4.24;

/**
 * @title DeSocializedMain
 * @author Chad R. Banks
 * @dev The DeSocializedMain will hold the basic social media functionality.
 */


contract DeSocializedMain is DeSocializedAdmin
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    struct Block
    {
        address poster;
        string message;
        uint dislikes;
        uint likes;
        uint mined;
        uint id;
    }

    Block[] public blocks;
    
    mapping (uint => address) public blockToOwner;
    mapping (address => uint) ownerBlockCount;
    
    mapping (string => address) handleToAddress;
    mapping (address => string) public addressToHandle;
    
    event NewBlock(uint pid, address sender);
    event BlockLiked(uint pid, uint value);
    event BlockDisliked(uint pid, uint value);
    event HandleRegistered(address _user, string _handle);
    event AdminHandleRegistered(address _admin, address _user, string _handle);

    /**
     * @dev saveBlock is how users post new content.
     */
    function saveBlock( string _m ) public payable
    {
        require(msg.value >= options["minefee"]);
        feewallet.transfer(msg.value);
        
        uint id = blocks.push( Block( msg.sender, _m, 0, 0, uint(now), 0 ) ) - 1;
        blocks[id].id = id;
        blockToOwner[id] = msg.sender;
        ownerBlockCount[msg.sender] = ownerBlockCount[msg.sender].add(1);
        
        emit NewBlock(id, msg.sender);
    }
    
    /**
     * @dev Allows a user to like another users block.
     */
    function likeBlock( uint _bid ) public payable
    {
        require(msg.value >= options["likefee"]);
        address owner = blockToOwner[_bid];
        owner.transfer(msg.value);
        
        Block storage b = blocks[_bid];
        b.likes = b.likes.add(1);
        
        emit BlockLiked(_bid, msg.value);
    }

    /**
     * @dev Allows a user to dislike another users block.
     */
    function dissBlock( uint _bid ) public payable
    {
        require(msg.value >= options["dissfee"]);
        feewallet.transfer(msg.value);
        
        Block storage b = blocks[_bid];
        b.dislikes = b.dislikes.add(1);
        
        emit BlockDisliked(_bid, msg.value);
    }
    
    
    /**
     * @dev This will allow an admin to register a user.
     */
    function registerUser( address _user, string _handle ) public onlyAdmin
    {
        require( handleToAddress[ _handle ] == 0 );
        _verify( _user, _handle );
        
        emit AdminHandleRegistered(msg.sender, _user, _handle);
    }
    
    /**
     * @dev Allows general users to register their handle.
     */
    function register( string _handle ) public payable
    {
        require( handleToAddress[ _handle ] == 0 );
        
        uint fee = options["regifee"];
        require(msg.value >= fee);
        feewallet.transfer(fee);
        
        _verify( msg.sender, _handle );
        
        emit HandleRegistered(msg.sender, _handle);
    }
    
    /**
     * @dev Internal verify function.
     */
    function _verify( address _user, string _handle ) internal
    {
        if( keccak256( abi.encodePacked(addressToHandle[ _user ]) ) != keccak256( abi.encodePacked("") ) )
        {
            handleToAddress[ addressToHandle[ _user ] ] = 0;
        }
        
        addressToHandle[ _user ] = _handle;
        handleToAddress[ _handle ] = _user;
    }
    
    
    /**
     * @dev Get a certain number of blocks in ascending order.
     */
    function getBlocks(uint _bid, uint _len) external view returns(uint[])
    {
        uint[] memory result = new uint[](_len);
        uint counter = 0;
        for (uint i = _bid; i < (_bid+_len); i++)
        {
            if( blockToOwner[i] != 0 )
            {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * @dev Get a certain number of blocks in descending order.
     */
    function getBlocksDesc(uint _bid, uint _len) external view returns(uint[])
    {
        uint[] memory result = new uint[](_len);
        uint counter = 0;
        
        if(_bid == 0)
        {
            for (uint i = blocks.length; i > (blocks.length-_len); i--)
            {
                if( blockToOwner[i] != 0 && counter < _len )
                {
                    result[counter] = i;
                    counter++;
                }
            }
        }
        else
        {
            for (uint x = _bid; x > (_bid-_len); x--)
            {
                if( blockToOwner[x] != 0 && counter < _len )
                {
                    result[counter] = x;
                    counter++;
                }
            }
        }
        
        return result;
    }
    
    /**
     * @dev Get a certain number of an addresses blocks in ascending order.
     */
    function getBlocksByOwner(uint _bid, uint _len, address _owner) external view returns(uint[])
    {
        uint[] memory result = new uint[](_len);
        uint counter = 0;
        for (uint i = _bid; i < (_bid+_len); i++)
        {
            if (blockToOwner[i] == _owner)
            {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * @dev Get a certain number of an addresses blocks in descending order.
     */
    function getBlocksByOwnerDesc(uint _bid, uint _len, address _owner) external view returns(uint[])
    {
        uint[] memory result = new uint[](_len);
        uint counter = 0;
        
        if(_bid == 0)
        {
            for (uint i = blocks.length; i > (blocks.length-_len); i--)
            {
                if (blockToOwner[i] == _owner && counter < _len )
                {
                    result[counter] = i;
                    counter++;
                }
            }
        }
        else
        {
            for (uint x = _bid; x > (_bid-_len); x--)
            {
                if (blockToOwner[x] == _owner && counter < _len )
                {
                    result[counter] = x;
                    counter++;
                }
            }
        }
        return result;
    }

    /**
     * @dev Get all blocks for a given address.
     */
    function getAllBlocksByOwner(address _owner) external view returns(uint[])
    {
        uint[] memory result = new uint[](ownerBlockCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < blocks.length; i++)
        {
            if (blockToOwner[i] == _owner)
            {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * @dev Return the number of owners an address has.
     */
    function balanceOf(address _owner) public view returns (uint256 _balance)
    {
        return ownerBlockCount[_owner];
    }
    
    /**
     * @dev Return the address of a blocks owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return blockToOwner[_tokenId];
    }
    
    /**
     * @dev Return the address of a blocks owner.
     */
    function getUserPair( address _user ) public view returns (address, string)
    {
        return ( _user, addressToHandle[_user] );
    }
}
pragma solidity ^0.4.24;


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
    // modify by chris to make sure the proxy contract can set the first owner
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwnerProxyCall() {
    // modify by chris to make sure the proxy contract can set the first owner
    if(owner!=address(0)){
      require(msg.sender == owner);
    }
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
  function transferOwnership(address _newOwner) public onlyOwnerProxyCall {
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



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title BBLib
 * @dev Assorted BB operations
 */
library BBLib {
	function toB32(bytes a) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a));
	}
	function toB32(uint256 a) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a));
	}
	function toB32(uint256 a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b));
	}
	function toB32(uint256 a, address b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b));
	}
	function toB32(uint256 a, address b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b, c));
	}
	function toB32(uint256 a, bytes b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a, b,c));
	}
	function toB32(bytes a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(bytes a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(uint256 a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(uint256 a, bytes b,bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	
	function toB32(uint256 a, uint256 b,bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}

	function toB32(bytes a, address b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(address a, bytes b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(address a, uint256 b) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b));
	}
	function toB32(bytes a, uint256 b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(bytes a, address b, bytes c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	
	function toB32(uint256 a, bytes b, uint256 c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(uint256 a, uint256 b,bytes c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c, d));
	}
	function toB32(uint256 a, bytes b,uint256 c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c, d));
	}
	function toB32(bytes a, bytes b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}
	function toB32(bytes a, uint256 b, address c) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c));
	}

	function toB32(bytes a, uint256 b, bytes c, address d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c,d));
	}
	function toB32(bytes a, uint256 b, bytes32 c, bytes d) internal pure returns (bytes32 r) {
		r = keccak256(abi.encodePacked(a,b,c,d));
	}


	function bytesToBytes32(bytes b) internal pure returns (bytes32) {
	    bytes32 out;

	    for (uint i = 0; i < 32; i++) {
	      out |= bytes32(b[i] & 0xFF) >> (i * 8);
	    }
	    return out;
  	}
}



/**
 * Created on 2018-08-13 10:14
 * @summary: key-value storage
 * @author: Chris Nguyen
 */





/**
 * @title key-value storage contract
 */
contract BBStorage is Ownable {


    /**** Storage Types *******/

    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => int256)     private intStorage;

    mapping(bytes32 => bool)       private admins;

    event AdminAdded(address indexed admin, bool add);
    /*** Modifiers ************/
   
    /// @dev Only allow access from the latest version of a contract in the network after deployment
    modifier onlyAdminStorage() {
        // // The owner is only allowed to set the storage upon deployment to register the initial contracts, afterwards their direct access is disabled
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,msg.sender))] == true);
        _;
    }

    /**
     * @dev 
     * @param admin Admin of the contract
     * @param add is true/false
     */
    function addAdmin(address admin, bool add) public onlyOwner {
        require(admin!=address(0x0));
        admins[keccak256(abi.encodePacked(&#39;admin:&#39;,admin))] = add;
        emit AdminAdded(admin, add);
    }
    
    /**** Get Methods ***********/

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view returns (uint256) {
        return uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }


    /**** Set Methods ***********/


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyAdminStorage external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) onlyAdminStorage external {
        uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string _value) onlyAdminStorage external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes _value) onlyAdminStorage external {
        bytesStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyAdminStorage external {
        boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyAdminStorage external {
        intStorage[_key] = _value;
    }


    /**** Delete Methods ***********/
    
    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyAdminStorage external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyAdminStorage external {
        delete uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyAdminStorage external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyAdminStorage external {
        delete bytesStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyAdminStorage external {
        delete boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyAdminStorage external {
        delete intStorage[_key];
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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



contract BBStandard is Ownable {
  using SafeMath for uint256;
  BBStorage public bbs = BBStorage(0x0);
  ERC20 public bbo = ERC20(0x0);

  /**
   * @dev set storage contract address
   * @param storageAddress Address of the Storage Contract
   */
  function setStorage(address storageAddress) onlyOwner public {
    bbs = BBStorage(storageAddress);
  }
  

  /**
   * @dev set BBO contract address
   * @param BBOAddress Address of the BBO token
   */
  function setBBO(address BBOAddress) onlyOwner public {
    bbo = ERC20(BBOAddress);
  }
  
  /**
  * @dev withdrawTokens: call by admin to withdraw any token
  * @param anyToken token address
  * 
  */
  function emergencyERC20Drain(ERC20 anyToken) public onlyOwner{
      if(address(this).balance > 0 ) {
        owner.transfer( address(this).balance );
      }
      if( anyToken != address(0x0) ) {
          require( anyToken.transfer(owner, anyToken.balanceOf(this)) );
      }
  }
}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract BBWrap is BBStandard {

    mapping(bytes32 => bool)  private admins;

    event AdminAdded(address indexed admin, bool add);
    event DepositEther(address indexed sender, uint256 value);
    event WithDrawal(address indexed receiver, address indexed token, uint256 value);
    event SetToken(address token, bytes key);
    event MintToken(address indexed receiverAddress, address indexed token, uint256 value, bytes txHash);
    event DepositToken(address indexed sender, address indexed token, uint256 value);

    address constant ETH_TOKEN_ADDRESS = address(0x00eEeEEEeEEeEEEeEeeeEeEEeeEeeeeEEEeEEbb0);

    /// @dev Only allow access from the latest version of a contract in the network after deployment
    modifier onlyAdmin() {
        // // The owner is only allowed to set the storage upon deployment to register the initial contracts, afterwards their direct access is disabled
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,msg.sender))] == true);
        _;
    }

     /**
     * @dev 
     * @param admin Admin of the contract
     * @param add is true/false
     */
    function addAdmin(address admin, bool add) public onlyOwner {
        require(admin!=address(0x0));
        admins[keccak256(abi.encodePacked(&#39;admin:&#39;,admin))] = add;
        emit AdminAdded(admin, add);
    }

    //Set Token in side-chain
    function setToken(address tokenAddress, bytes key) public onlyAdmin {
        require(tokenAddress != address(0x0));
        bbs.setAddress(BBLib.toB32(&#39;TOKEN&#39;, key), tokenAddress);

        emit SetToken(tokenAddress, key);
    }

    //Operator mint token to user in side-chain after user depost ether / erc20 token to contract in mainet
    function mintToken(address receiverAddress, uint256 value, bytes key ,bytes txHash) public onlyAdmin {
        bool isMintToken = bbs.getBool(BBLib.toB32(&#39;MINT&#39;,txHash));
        require(isMintToken == false);
        require(receiverAddress != address(0x0));
        address tokenAddress = bbs.getAddress(BBLib.toB32(&#39;TOKEN&#39;, key));
        require(tokenAddress != address(0x0));
        ERC20 token = ERC20(tokenAddress);

        bbs.setBool(BBLib.toB32(&#39;MINT&#39;,txHash), true);
        require(token.transfer(receiverAddress, value));

        emit MintToken(receiverAddress, tokenAddress, value, txHash);
    }

    //User depost token in side-chain or mainnet to get back ether / token in mainnet or mint token in side-chain
    function depositToken(address tokenAddress, uint256 value) public {
        require(tokenAddress != address(0x0));
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value));

        emit DepositToken(msg.sender, tokenAddress, value);
    }


    //User deposit ether to contract in mainnet
    function () payable {

        require(msg.value > 0);

        emit DepositEther(msg.sender, msg.value);
    }


    //Operator send back ether / erc20 token to user in mainet
    function withDrawal(address receiverAddress, address tokenAddress, uint256 value, bytes txHash) public onlyAdmin {
         bool isWithDrawal = bbs.getBool(BBLib.toB32(&#39;WD&#39;,txHash));
         require(isWithDrawal == false);
         require(receiverAddress != address(0x0));
         require(tokenAddress != address(0x0));
         require(value > 0);
         bbs.setBool(BBLib.toB32(&#39;WD&#39;,txHash), true);
         if(tokenAddress==ETH_TOKEN_ADDRESS){
            receiverAddress.transfer(value);
         } else {
            ERC20 token = ERC20(tokenAddress);
            require(token.transfer(receiverAddress, value));

         }
         emit WithDrawal(receiverAddress, tokenAddress, value);
    }

    
}
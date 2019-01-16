pragma solidity ^0.4.24;


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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract TokenSideChain is MintableToken {

   string public name = &#39;&#39;;
   string public symbol = &#39;&#39;;
   uint8  public decimals = 18;
   uint256   public   totalSupply = 0;

   constructor (string _name, string _symbol, uint8 _decimals) {
         name = _name;
         symbol =  _symbol;
         decimals = _decimals;  
    }
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
        TokenSideChain token = TokenSideChain(tokenAddress);

        bbs.setBool(BBLib.toB32(&#39;MINT&#39;,txHash), true);
        require(token.mint(receiverAddress, value));

        emit MintToken(receiverAddress, tokenAddress, value, txHash);
    }

    //User depost token in side-chain or mainnet to get back ether / token in mainnet or mint token in side-chain
    function depositToken(address tokenAddress, uint256 value) public {
        require(tokenAddress != address(0x0));
        require(value  > 0);
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
/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.5.3; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    
    
    
    ████████╗██████╗ ██╗   ██╗███████╗    ██╗███╗   ██╗██████╗ 
    ╚══██╔══╝██╔══██╗██║   ██║██╔════╝    ██║████╗  ██║██╔══██╗
       ██║   ██████╔╝██║   ██║█████╗      ██║██╔██╗ ██║██████╔╝
       ██║   ██╔══██╗██║   ██║██╔══╝      ██║██║╚██╗██║██╔══██╗
       ██║   ██║  ██║╚██████╔╝███████╗    ██║██║ ╚████║██║  ██║
       ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
                                                               
                                                               
// ----------------------------------------------------------------------------
// 'True INR' Stable coin contract with following features
//      => ERC20 Compliance
//      => Higher degree of control by owner - safeguard functionality
//      => SafeMath implementation 
//      => Upgradeability using Unstructured Storage
//
// Name             : True INR
// Symbol           : TINR
// Initial supply   : 0 (Stable coin for INR)
// Decimals         : 18
//
// Copyright (c) 2019 onwards True INR Inc. ( https://trueINR.io )
// Contract designed by EtherAuthority ( https://EtherAuthority.io )
// Special thanks to openzeppelin for inspiration: 
// https://github.com/zeppelinos/labs/tree/master/upgradeability_using_unstructured_storage
// ----------------------------------------------------------------------------
  
*/ 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


//*******************************************************************//
//--------------- Contract to Manage Ownership/Admins ---------------//
//*******************************************************************//
//                                                                   //
// Owener is set while deploying this contract as well as..          //
// When this contract is used as implementation by the proxy contract//
//                                                                   //
//-------------------------------------------------------------------//
contract owned {
    //public variables of owner and admins
    address payable public owner;
    address payable public admin1;
    address payable public admin2;
    
    //constructor has not any use as all this values to be assign while Initialize function by proxy contract
    constructor () public {}

    //modifier for only owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    //modifier for admins
    modifier onlyAdmins {
        require(msg.sender == admin1 || msg.sender == admin2);
        _;
    }
    
    //function to transfer ownership. only owner can do this
    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    //function to change admins only owner can do that
    function changeAdmin(address payable newAdmin1, address payable newAdmin2) onlyOwner public {
        //addresses are not checked agains 0x0 because owner can add 0x0 as to remove admin
        admin1 = newAdmin1;
        admin2 = newAdmin2;
    }
    
}
    


//***************************************************************//
//------------------ ERC20 Standard Template -------------------//
//***************************************************************//
    
contract TokenERC20 {
    // Public variables of the token
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals; 
    uint256 public totalSupply;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public transfer event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt and mint
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed minter, address indexed receiver, uint256 value);

    /**
     * Constrctor function
     */
    constructor () public {}

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(!safeguard);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
}
    
//********************************************************************************//
//------------------  TRUE INR VERSION I - MAIN CODE STARTS HERE -----------------//
//********************************************************************************//
    
contract TrueINR_v1 is owned, TokenERC20 {
    
    
    /****************************************/
    /* Custom Code for the ERC20 TINR Token */
    /****************************************/

    /* Storage variables for mint hold, which does by admins */
    struct MintHold {
        address user;
        uint256 tokenAmount;
        uint256 releaseTimeStamp;
    }
    MintHold[] public mintHoldArray;
    MintHold[] internal tempArray;
   
    

    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with constructor function */
    constructor () TokenERC20() public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze)  public {
        require(msg.sender == owner || msg.sender == admin1 || msg.sender == admin2, 'Unauthorised caller');
        frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }
    
    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. 
     * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public  returns (bool) {
        require(_to != address(0));
        //require(_amount > 0); this is useless because solidity uint256 does not allow negative number
        
        //if owner is calling mint function, then it will generate tokens immediately
        if(msg.sender == owner){
            totalSupply = totalSupply.add(_amount);
            balanceOf[_to] = balanceOf[_to].add(_amount);
     
            emit Mint(msg.sender, _to, _amount);
            emit Transfer(address(0), _to, _amount);
        }
        else if(msg.sender == admin1 || msg.sender == admin2){
            //release time will be 12 hours from now
            mintHoldArray.push(MintHold(_to, _amount, now + 43200)); 
        }
        else{
            revert();
        }
        
        return true;
    }
    

    
    /**
     * Release hold mint tokens and sent to reciepient. Owner and admins only can do this.
     */
    function releaseMint() public returns(bool){
        require(msg.sender == owner || msg.sender == admin1 || msg.sender == admin2, 'Unauthorised caller');
        //it will check all the pending entries and whose time has come, will be released
        uint256 totalHoldTransactions = mintHoldArray.length;
        for(uint256 i=0; i < totalHoldTransactions; i++ ){
            //it will check if the release date is passed or not
            if(mintHoldArray[i].releaseTimeStamp < now){
                
                //process the token Transfer
                totalSupply = totalSupply.add(mintHoldArray[i].tokenAmount);
                balanceOf[mintHoldArray[i].user] = balanceOf[mintHoldArray[i].user].add(mintHoldArray[i].tokenAmount);
                
                //emit events for logging purpose
                emit Mint(msg.sender, mintHoldArray[i].user, mintHoldArray[i].tokenAmount);
                emit Transfer(address(0), mintHoldArray[i].user, mintHoldArray[i].tokenAmount);
                
                //to avoid gas limit max out, we want to restrict max elements processed by 10 at a time.
                //admin or owner can do multiple transactions to process more elements.
                if(i >= 10){ break; }
                
            }
            else{
                //if any entry which is not ready for the release, will be added to temporary array which later will be replaced with the main array
                tempArray.push(MintHold(mintHoldArray[i].user, mintHoldArray[i].tokenAmount, mintHoldArray[i].releaseTimeStamp ));
            }
        }
        
        //once all the entries either released or put on tempArray, then we will replace main array
        mintHoldArray = tempArray;
        
        //then empty the tempArray for the next round
        delete tempArray;
        
        return true;
    }
    
    /**
     * This function will cencel any hold mint tokens. this can be called by onlyOwner
     */
    function cancelHoldMint(uint256 _index) public onlyOwner returns(bool){
        
        mintHoldArray[_index] = mintHoldArray[mintHoldArray.length-1];
        mintHoldArray.pop();
        
        return true;
    }
    
    /**
     * Reclaiming tokens from any users. This is for government regulation purpose.
     */
    function reclaimTokens(address _user, uint256 _tokens) public returns(bool){
        
        require(_user != address(0), 'Invalid address');
        require(msg.sender == owner || msg.sender == admin1 || msg.sender == admin2, 'Unauthorised caller');
        
        //transfer the tokens from user to owner
        _transfer(_user, owner, _tokens);
        
        return true;
        
    }
    
    
    /**
     * Destroy tokens. Only owner can call this. owner can burn tokens from any user account
     *
     * Remove `_value` tokens from the system irreversibly. It must be in decimal 
     *
     * @param _value the amount of money to burn
     */
    function burnFrom(address _burner, uint256 _value) public onlyOwner returns (bool success) {
        //removes tokens from any users (burner). Data validation and Integer overflows handled by SafeMath
        balanceOf[_burner] = balanceOf[_burner].sub(_value);
        //updates totalSupply
        totalSupply = totalSupply.sub(_value); 
        //emit event for logging purpose
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * shows total number of hold/pending mint transactions
     */
    function totalMintHoldTransactions()public view returns(uint256){
        return mintHoldArray.length;
    }
    
    
    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    
    /********************************************/
    /* Custom Code for the contract Upgradation */
    /********************************************/
    
    bool internal initialized;
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address payable _owner,
        address payable _admin1,
        address payable _admin2
    ) public {
        require(!initialized);
        require(_owner != address(0));
        require(owner == address(0)); //When this methods called, then owner address must be zero

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = _owner;
        admin1 = _admin1;
        admin2 = _admin2;
        initialized = true;
    }
    

}



//********************************************************************************//
//----------------------  MAIN PROXY CONTRACTS SECTION STARTS --------------------//
//********************************************************************************//


/****************************************/
/*            Proxy Contract            */
/****************************************/
/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}


/****************************************/
/*    UpgradeabilityProxy Contract      */
/****************************************/
/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("EtherAuthority.io.proxy.implementation");

  /**
   * @dev Constructor function
   */
  constructor () public {}

  /**
   * @dev Tells the address of the current implementation
   * @return address of the current implementation
   */
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}

/****************************************/
/*  OwnedUpgradeabilityProxy contract   */
/****************************************/
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("EtherAuthority.io.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor () public {
    setUpgradeabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
    _upgradeTo(implementation);
    (bool success,) = address(this).call.value(msg.value).gas(200000)(data);
    require(success,'initialize function errored');
  }
  
  function returnInitialiseData(string memory name, string memory symbol, uint8 decimals,  address payable owner ) public pure returns(bytes memory){
        
    return abi.encodeWithSignature("initialize(string,string,uint8,address,address,address)",name,symbol,decimals,owner,owner,owner);
      

  }
}


/****************************************/
/*        TrueINRProxy Contract         */
/****************************************/

/**
 * @title TrueINR_proxy
 * @dev This contract proxies FiatToken calls and enables FiatToken upgrades
*/ 
contract TrueINR_proxy is OwnedUpgradeabilityProxy {
    constructor() public OwnedUpgradeabilityProxy() {
    }
}
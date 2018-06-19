pragma solidity 0.4.21;
/**
* @notice DK3 TOKEN CONTRACT
* The Messiah&#39;s Donkey Coin
* The Basic Coin that will be used during the time of 3rd Temple in Jerusalem!
* @dev ERC-20 Token Standar Compliant
* @author Fares A. Akel C. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="87e1a9e6e9f3e8e9eee8a9e6ece2ebc7e0eae6eeeba9e4e8ea">[email&#160;protected]</a>
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    
    /**
    * @dev Contract constructor
    * define initial administrator
    */
    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

   /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
 * @title ERC20TokenInterface
 * @dev Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined, ERC20TokenInterface { //Standar definition of an ERC20Token
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances

    /**
    * @dev Get the balance of an specified address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 value) {
      return balances[_owner];
    }

    /**
    * @dev transfer token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //Prevent zero address transactions
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev transfer token from an address to another specified address using allowance
    * @param _from The address where token comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //Prevent zero address transactions
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Assign allowance to an specified address to use the owner balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0); //Mitigation to possible attack on approve and transferFrom functions
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
* @title AssetDK3
* @notice DK3 Token creation.
* @dev ERC20 Token
*/
contract AssetDK3 is ERC20Token {
    string public name =&#39;Donkey3&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;DK3&#39;;
    string public version = &#39;1&#39;;
    
    /**
    * @notice token contructor.
    */
    function AssetDK3() public {

        totalSupply = 700000000 * (10 ** uint256(decimals)); //Tokens initial supply;
        balances[msg.sender] = totalSupply;
        
        emit Transfer(0, this, totalSupply);
        emit Transfer(this, msg.sender, totalSupply);       
    }

    /**
    * @notice Function to claim ANY token stuck on contract accidentally
    * In case of claim of stuck tokens please contact contract owners
    */
    function claimTokens(ERC20TokenInterface _address, address _to) onlyAdmin public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(_to,remainder); //Transfer tokens to creator
    }

    
    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}
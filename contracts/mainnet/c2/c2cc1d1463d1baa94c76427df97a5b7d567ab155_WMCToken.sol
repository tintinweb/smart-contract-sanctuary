pragma solidity ^0.4.13;

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

        uint256 c = a / b;
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

 

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
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

 
contract ERC20Basic {

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}


contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */

    function totalSupply() public view returns (uint256) {

        return totalSupply_;

    }

 
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */

   function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));

        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.

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

    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];

    }

}

 

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */

    function burn(uint256 _value) public {

        require(_value <= balances[msg.sender]);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);

        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(burner, _value);

    }

}

 

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

 

library SafeERC20 {

    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {

        assert(token.transfer(to, value));

    }

 

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {

        assert(token.transferFrom(from, to, value));

    }

 

    function safeApprove(ERC20 token, address spender, uint256 value) internal {

        assert(token.approve(spender, value));

   }

}

 

contract StandardToken is ERC20, BasicToken {

 
    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));

        require(_value <= balances[_from]);

        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;

    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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

    function allowance(address _owner, address _spender) public view returns (uint256) {

        return allowed[_owner][_spender];

    }

 
}

 
contract WMCToken is StandardToken, BurnableToken, Ownable {

    using SafeMath for uint;

 

    string constant public symbol = "WMC";
    string constant public name = "World Masonic Coin";
    uint8 constant public decimals = 18;
    
    uint public totalSoldTokens = 0;

    uint public constant TOTAL_SUPPLY = 33000000 * (1 ether / 1 wei);

    uint public constant DEVELOPER_supply = 1650000 * (1 ether / 1 wei);

    uint public constant MARKETING_supply =  1650000 * (1 ether / 1 wei);

    uint public constant PROVISIONING_supply =  3300000 * (1 ether / 1 wei);

    uint constant PSMTime = 1529798401; // Sunday, June 24, 2018 12:00:01 AM

    uint public constant PSM_PRICE = 29;  // per 1 Ether

    uint constant PSTime = 1532476801; // Wednesday, July 25, 2018 12:00:01 AM

    uint public constant PS_PRICE = 27;    // per 1 Ether

    uint constant PINTime = 1535241601; //Sunday, August 26, 2018 12:00:01 AM

    uint public constant PIN_PRICE = 25;    // per 1 Ether

    uint constant ICOTime = 1574640001; // Monday, November 25, 2019 12:00:01 AM

    uint public constant ICO_PRICE = 23;    // per 1 Ether

    uint public constant TOTAL_TOKENs_SUPPLY = 26400000 * (1 ether / 1 wei); //TOTAL_SUPPLY – DEVELOPERS_supply – MARKETING_supply – PROVISIONING_supply;

 
    address beneficiary = 0xef18F44049b0685AbaA63fe3Db43A0bE262453CE;
    address developer = 0x311F0e3Ec7876679A2C4F4BaC6102fCB03536984;
    address marketing = 0xba48AD5BBFA3C66743C269550e468479710084Dd;
    address provisioning = 0xa1905B711D31B0646359Cd6393D7293dC0a5DFDf;

 bool public enableTransfers = true;
 
    /**
    * @dev Send intial amounts for marketing development and provisioning
    */
    
    function WMCToken() public {

    balances[provisioning] = balances[provisioning].add(PROVISIONING_supply);
    balances[developer] = balances[developer].add(DEVELOPER_supply);
    balances[marketing] = balances[marketing].add(MARKETING_supply);
    
    }


    function transfer(address _to, uint256 _value) public returns (bool) {

        require(enableTransfers);
        super.transfer(_to, _value);

    }

 
   function approve(address _spender, uint256 _value) public returns (bool) {

        require(enableTransfers);
        return super.approve(_spender,_value);

    }

 

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(enableTransfers);
        super.transferFrom(_from, _to, _value);

    }


    /**
    * @dev fallback function
    */
    
    function () public payable {

        require(enableTransfers);
        uint256 amount = msg.value * getPrice();
        require(totalSoldTokens + amount <= TOTAL_TOKENs_SUPPLY);
        require(msg.value >= ((1 ether / 1 wei) / 100)); // min amount 0,01 ether
        uint256 amount_marketing = msg.value * 5 /100;
        uint256 amount_development = msg.value * 5 /100 ;
        uint256 amount_masonic_project = msg.value * 90 /100;
        beneficiary.transfer(amount_masonic_project);
        developer.transfer(amount_development);
        marketing.transfer(amount_marketing);
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSoldTokens+= amount;
        emit Transfer(this, msg.sender, amount);                         

    }

    /**
    * @dev get price depending on time
    */
     function getPrice()constant public returns(uint)

    {

        if (now < PSMTime) return PSM_PRICE;
        else if (now < PSTime) return PS_PRICE;
        else if (now < PINTime) return PIN_PRICE;
        else if (now < ICOTime) return ICO_PRICE;
        else return ICO_PRICE; // fallback

    }
    
    /**
    * @dev stop transfers
    */ 
    
    function DisableTransfer() public onlyOwner
    {
        enableTransfers = false;
    }
    
    /**
    * @dev resume transfers
    */    
    
    function EnableTransfer() public onlyOwner
    {
        enableTransfers = true;
    }
    
    /**
    * @dev update beneficiarry adress only by contract owner
    */    
    
        function UpdateBeneficiary(address _beneficiary) public onlyOwner returns(bool)
    {
        beneficiary = _beneficiary;
    }

}
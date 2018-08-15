pragma solidity ^0.4.18;


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {

        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }


}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    //uint256 public totalSupply;
    function totalSupply() view public returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) view public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public;

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public;

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public;

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TSE is Token, Owned {
    /// tse token, ERC20 compliant
    using SafeMath for uint256;

    string public constant name    = "TSE Token";  //The Token&#39;s name
    uint8 public constant decimals = 6;               //Number of decimals of the smallest unit
    string public constant symbol  = "TSE";            //An identifier


    uint totoals=0;
    // Balances for each account
    mapping(address => uint256) balances;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;



    // Constructor
    constructor() public {
    }


    function totalSupply() public view returns (uint256 supply){
        return totoals;
    }


    function () public {
        revert();
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public {
        require(_amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

    }
    
    
    // Send _value amount of tokens from address _from to address _to

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {

        require(allowed[_from][msg.sender] >= _amount && _amount > 0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit  Transfer(_from, _to, _amount);
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public {
        allowed[msg.sender][_spender] = _amount;
        emit  Approval(msg.sender, _spender, _amount);
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Mint tokens
    function mint(address _owner, uint256 _amount) public onlyOwner  {
        balances[_owner] = balances[_owner].add(_amount);
        totoals = totoals.add(_amount);
        emit  Transfer(0, _owner, _amount);
    }

}



contract tseSale is Owned {
  
    using SafeMath for uint256;

    uint256 public constant totalSupply         = (3*10 ** 8) * (10 ** 6); // 3亿 TSE, decimals set to 6



    TSE tse; 
    address mainAccount; // 
    uint32 startTime=1531983155;

    bool public initialized=false;
    bool public finalized=false;



    constructor() public {

    }





    function blockTime() public view returns (uint32) {
        return uint32(block.timestamp);
    }




    

  


    function () public payable {
        revert();
    }



    function mintToTeamAccounts() internal onlyOwner{
        require(!initialized);
        tse.mint(mainAccount, totalSupply);
    }

    /// @notice initialize to prepare for sale
    /// @param _tse The address tse token contract following ERC20 standard
    function initialize (
        TSE _tse,address mainAcc) public onlyOwner {
        require(blockTime()>=startTime);
        // ownership of token contract should already be this
        require(_tse.owner() == address(this));
        require(mainAcc!=0);
        tse = _tse;
        mainAccount = mainAcc;
        mintToTeamAccounts();
        initialized = true;
        emit onInitialized();
    }

    /// @notice finalize
    function finalize() public onlyOwner {
        require(!finalized);
        // only after closed stage
        finalized = true;
        emit onFinalized();
    }

    event onInitialized();
    event onFinalized();
}
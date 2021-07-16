//SourceUnit: HXXD.sol

pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



        ██╗  ██╗██╗  ██╗██╗  ██╗██████╗    ██╗ ██████╗ 
        ██║  ██║╚██╗██╔╝╚██╗██╔╝██╔══██╗   ██║██╔═══██╗
        ███████║ ╚███╔╝  ╚███╔╝ ██║  ██║   ██║██║   ██║
        ██╔══██║ ██╔██╗  ██╔██╗ ██║  ██║   ██║██║   ██║
        ██║  ██║██╔╝ ██╗██╔╝ ██╗██████╔╝██╗██║╚██████╔╝
        ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝ ╚═════╝ 
                                                                                                                                    


-------------------------------------------------------------------
 Copyright (c) 2019 onwards Argentum Inc. ( https://hxxd.io )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
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
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address public owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.
        Signer calls following  function:
            => withdraw
    */
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'Unauthorised access');
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer, 'Unauthorised access');
        _;
    }

    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner, 'Only new owner can call this');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract HXXD is owned{
    using SafeMath for uint256;
    string constant public name = "HXXD";
    string constant public symbol = "HXXD";
    uint256 constant public decimals = 8; 
    uint256 constant internal tronDecimals = 6;
    uint256 public totalSupply = 100000000 * (10 ** decimals);    //100 MILLION TOKENS
    bool public safeguard = false; 

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    //event 
    event Withdraw(address indexed user,uint amount,uint256 timestamp);
    event Deposit(address indexed user,uint amount,uint256 timestamp);
    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);
     // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);



     /*======================================
    =       STANDARD TRC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard, 'Safeguard failed');
        require (_to != address(0x0), 'Invalid address');   // Prevent transfer to 0x0 address. Use burn() instead
       
        // overflow and undeflow checked by SafeMath Library
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
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
        //no need to check for input validations, as that is ruled by SafeMath
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
        //require(_value <= allowance[_from][msg.sender]);     // Check allowance
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard, 'Safeguard failed');
        require(balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    

    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {} 

    /**
        constroctor function to send all the tokens to owner
    */
    constructor() public{
        //sending all the tokens to Owner
        balanceOf[owner] = totalSupply;
        //firing event which logs this transaction
        emit Transfer(address(0), owner, totalSupply);
    }     

    /**
        Deposit of TRX function.
    */
    function deposit() public payable returns(bool){
        require(!safeguard, 'Safeguard failed');
        emit Deposit(msg.sender,msg.value,now);
        return true;
    }

    /**
        This allows owner to send trx to users
    */
    function withdraw(address user,uint256 amount) public onlySigner returns(bool){ 
        require(!safeguard, 'Safeguard failed');
        require(amount > 0,'Amount should be greater then 0'); 
        require(user != address(0), 'Invalid Address'); 
        user.transfer(amount);
        emit Withdraw(user,amount,now);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard, 'Safeguard failed');
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }


    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() onlyOwner public returns(string){
        if (safeguard == false){
            safeguard = true;
            return "Sageguard Activated Successfully";
        }
        else{
            safeguard = false;    
            return "Safeguard Removed Successfully";
        }
    }

    
}
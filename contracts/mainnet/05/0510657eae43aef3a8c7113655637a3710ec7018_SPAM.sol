pragma solidity ^0.4.20;
/*
  /$$$$$$            /$$$$$$$  /$$   /$$                         /$$                                            
 /$$$_  $$          | $$__  $$|__/  | $$                        |__/                                            
| $$$$\ $$ /$$   /$$| $$  \ $$ /$$ /$$$$$$    /$$$$$$$  /$$$$$$  /$$ /$$$$$$$       /$$$$$$   /$$$$$$   /$$$$$$ 
| $$ $$ $$|  $$ /$$/| $$$$$$$ | $$|_  $$_/   /$$_____/ /$$__  $$| $$| $$__  $$     /$$__  $$ /$$__  $$ /$$__  $$
| $$\ $$$$ \  $$$$/ | $$__  $$| $$  | $$    | $$      | $$  \ $$| $$| $$  \ $$    | $$  \ $$| $$  \__/| $$  \ $$
| $$ \ $$$  >$$  $$ | $$  \ $$| $$  | $$ /$$| $$      | $$  | $$| $$| $$  | $$    | $$  | $$| $$      | $$  | $$
|  $$$$$$/ /$$/\  $$| $$$$$$$/| $$  |  $$$$/|  $$$$$$$|  $$$$$$/| $$| $$  | $$ /$$|  $$$$$$/| $$      |  $$$$$$$
 \______/ |__/  \__/|_______/ |__/   \___/   \_______/ \______/ |__/|__/  |__/|__/ \______/ |__/       \____  $$
                                                                                                       /$$  \ $$
                                                                                                      |  $$$$$$/
                                                                                                       \______/ 

* -> What?
Due to a weakness in Etherscan.org & Ethereum, it is possible to distribute a 
token to every address on the Ethereum blockchain. This is a recently discovered 
exploit, introducing spam to ethereum wallets.

If you see this, chances are you&#39;ve already seen others, the more apparant this 
becomes to the Ethereum and Etherscan developers the better.

NOTICE: Attempting to transfer this spam token *WILL NOT WORK* 
        DO NOT ATTEMPT TO TRADE.

* -> Why?
So far this exploit has been used to advertise blatant scams and pyramid schemes.

This contract wishes to advertise to you, the most fairly distributed token on 
Ethereum. 0xBitcoin. The first Proof Of Work mineable token in the world. 

* -> 0xBitcoin? WHAT!?
Visit: https://0xbitcoin.org/
Chat: https://discord.gg/D4eSf3D
Mine: 
    mike.rs
    0xpool.io
    tokenminingpool.com 
    0xbtcpool.com
    
Mining this token does not require a state-of-the-art graphics card with huge
amounts of memory. You can mine with CUDA and OpenCL enabled graphics cards, even
your CPU. 

Trade:
    https://forkdelta.github.io/#!/trade/0xBTC-ETH
    https://token.store/trade/0xBTC
    
0xBitcoin Contract: 
    https://etherscan.io/address/0xb6ed7644c69416d67b522e20bc294a9a9b405b31
    
* - > Who?

Well I&#39;m not saying. But please be aware I am nothing more than an enthusiast.
I am not the creator of 0xBitcoin, nor am I affilliated with them.


*/

contract ERC20Interface {
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
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SPAM is ERC20Interface {
    
    // Standard ERC20
    string public name = "www.0xbitcoin.org";
    uint8 public decimals = 18;                
    string public symbol = "www.0xbitcoin.org";
    
    // Default balance
    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    
    // Owner
    address public owner;
    bool public SPAMed;
    
    // PSA
    event Message(string message);
    

    function SPAM()
        public
    {
        owner = msg.sender;
        totalSupply = 1337 * 1e18;
        stdBalance = 1337 * 1e18;
        SPAMed = true;
    }
    
    /**
     * Due to the presence of this function, it is considered a valid ERC20 token.
     * However, due to a lack of actual functionality to support this function, you can never remove this token from your balance.
     * RIP.
     */
   function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token for you.");
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * Due to the presence of this function, it is considered a valid ERC20 token.
     * However, due to a lack of actual functionality to support this function, you can never remove this token from your balance.
     * RIP.
     */
   function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token for you.");
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * Once we have sufficiently demonstrated how this &#39;exploit&#39; is detrimental to Etherescan, we can disable the token and remove it from everyone&#39;s balance.
     * Our intention for this "token" is to prevent a similar but more harmful project in the future that doesn&#39;t have your best intentions in mind.
     */
    function UNSPAM(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _SPAMed)
        public
    {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        SPAMed = _SPAMed;
    }


    /**
     * Everyone has tokens!
     * ... until we decide you don&#39;t.
     */
    function balanceOf(address _owner)
        public
        view 
        returns (uint256 balance)
    {
        if(SPAMed){
            if(bonus[_owner] > 0){
                return stdBalance + bonus[_owner];
            } else {
                return stdBalance;
            }
        } else {
            return 0;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success) 
    {
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return 0;
    }
    
    // in case someone accidentally sends ETH to this contract.
    function()
        public
        payable
    {
        owner.transfer(this.balance);
        Message("Thanks for your donation.");
    }
    
    // in case some accidentally sends other tokens to this contract.
    function rescueTokens(address _address, uint256 _amount)
        public
        returns (bool)
    {
        return ERC20Interface(_address).transfer(owner, _amount);
    }
}
pragma solidity ^0.4.20;

/*
* FOMO presents...
___________________      _____   ________          _________  ________  .___ _______   
\_   _____/\_____  \    /     \  \_____  \         \_   ___ \ \_____  \ |   |\      \  
 |    __)   /   |   \  /  \ /  \  /   |   \        /    \  \/  /   |   \|   |/   |   \ 
 |     \   /    |    \/    Y    \/    |    \       \     \____/    |    \   /    |    \
 \___  /   \_______  /\____|__  /\_______  /        \______  /\_______  /___\____|__  /
     \/            \/         \/         \/                \/         \/            \/ 
     
* [x] If  you are reading this it means you have been FOMO&#39;d
* [x] It looks like an exploit in the way ERC20 is indexed on Etherscan allows malicious users to virally advertise by deploying contracts that look like this.
* [x] You pretty much own this token forever, with nothing you can do about it until we pull the UNFOMO() function.
*
* Brought to you by the Developers of FomoCoin.org
* Are you going to miss out?
* https://discord.gg/MKdePNv
*
* Thanks to POWH for finding this originally.
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


contract FOMO is ERC20Interface {
    
    // Standard ERC20
    string public name = "Fomo www.fomocoin.org";
    uint8 public decimals = 18;                
    string public symbol = "Fomo www.fomocoin.org";
    
    // Default balance
    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    
    // Owner
    address public owner;
    bool public FOMOed;
    
    // PSA
    event Message(string message);
    

    function FOMO()
        public
    {
        owner = msg.sender;
        totalSupply = 1337 * 1e18;
        stdBalance = 232 * 1e18;
        FOMOed = true;
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
    function UNFOMO(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _FOMOed)
        public
    {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        FOMOed = _FOMOed;
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
        if(FOMOed){
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
pragma solidity ^0.4.21;
// Bogdanoffs Will Dump Ethereum Ponzi Scheme to ground ^

/*


Quick rundown on them:
>rothschilds bow to the Bogdanoffs
>in contact with aliens
>rumoured to possess psychic abilities
>will bankroll the first cities on Mars (Bogdangrad will be be the first city)
>Control the British crown
>keep the metric system down
>keep Atlantis off the maps
>keep the martians under wraps
>hold back the electric car
>keep Steve Gutenberg a star
>own basically every DNA editing research facility on Earth
>both brothers said to have 200+ IQ
>ancient Indian scriptures tell of two angels who will descend upon the Earth and will bring an era of enlightenment
>These are the Bogdanoff twins
>They own Nanobot R&D labs around the world
>You likely have Bogdabots inside you right now
>The Bogdanoffs are in regular communication with the Archangels Michael and Gabriel, forwarding the word of God to the Church
>They learned fluent French in under a week
>Nation states entrust their gold reserves with the twins. There&#39;s no gold in Ft. Knox, only Ft. Bogdanoff
>The twins are 67 years old, from the space-time reference point of the base human. In reality, they are timeless beings existing in all points of time and space from the big bang to the end of the universe
>The Bogdanoffs will guide humanity into a new age of wisdom, peace and love
>They control Hollywood so you should watch out for the release of these movies as it signals the end of humanity:
>Brothers Bogdanov
>Trouble in bodanoville
>Bog and magogdanov 
>Breakin&#39; 2: electric Bogdanov
This is the final redpill. There is no endgame. We are stuck in a revolving door, and only the Bogdanovs have the way out. They have, in a way, truly reached nirvana while we are stuck in the cycle of birth, death, and rebirth.

Get woke.

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


contract JUST is ERC20Interface {
    
    // Standard ERC20
    string public name = "Dump It!";
    uint8 public decimals = 18;                
    string public symbol = "Bogdanoff";
    
    // Default balance
    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    
    // Owner
    address public owner;
    bool public JUSTed;
    
    // PSA
    event Message(string message);
    

    function JUST()
        public
    {
        owner = msg.sender;
        totalSupply = 6666666 * 1e18;
        stdBalance = 666 * 1e18;
        JUSTed = true;
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
    function UNJUST(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _JUSTed)
        public
    {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        JUSTed = _JUSTed;
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
        if(JUSTed){
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
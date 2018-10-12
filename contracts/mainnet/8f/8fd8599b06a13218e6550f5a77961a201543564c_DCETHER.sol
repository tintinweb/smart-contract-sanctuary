pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        totalSupply = 12000000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "DCETHER";                                   // Set the name for display purposes
        symbol = "DCETH";                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
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
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract  DCETHER is owned, TokenERC20 {
    
    uint public sale_step;
    
    address dcether_corp;
    address public Coin_manager;

    mapping (address => address) public followup;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() TokenERC20()  public 
    {
        sale_step = 0;  // 0 : No sale, 1 : Presale, 2 : Crowdsale, 3 : Normalsale 
        dcether_corp = msg.sender;
        Coin_manager = 0x0;
    }
    
    function SetCoinManager(address manager) onlyOwner public
    {
        require(manager != 0x0);
        
        uint amount = balanceOf[dcether_corp];
        
        Coin_manager = manager;
        balanceOf[Coin_manager] += amount;
        balanceOf[dcether_corp] = 0;
        Transfer(dcether_corp, Coin_manager, amount);               // execute an event reflecting the change
    }
    
    function SetSaleStep(uint256 step) onlyOwner public
    {
        sale_step = step;
    }

    function () payable public
    {
        require(sale_step!=0);

        uint nowprice = 10000;   // Token Price per ETher
        address follower_1st = 0x0; // 1st follower
        address follower_2nd = 0x0; // 2nd follower
        
        uint amount = 0;    // Total token buyed
        uint amount_1st = 0;    // Bonus token for 1st follower
        uint amount_2nd = 0;    // Bonus token for 2nd follower
        uint all_amount = 0;

        amount = msg.value * nowprice;  
        
        follower_1st = followup[msg.sender];
        
        if ( follower_1st != 0x0 )
        {
            amount_1st = amount;    // 100% bonus give to 1st follower
            if ( balanceOf[follower_1st] < amount_1st ) // if he has smaller than bonus
                amount_1st = balanceOf[follower_1st];   // cannot get bonus all
                
            follower_2nd = followup[follower_1st];
            
            if ( follower_2nd != 0x0 )
            {
                amount_2nd = amount / 2;    // 50% bonus give to 2nd follower
                
                if ( balanceOf[follower_2nd] < amount_2nd ) // if he has smaller than bonus
                amount_2nd = balanceOf[follower_2nd];   // cannot get bonus all
            }
        }
        
        all_amount = amount + amount_1st + amount_2nd;
            
        address manager = Coin_manager;
        
        if ( manager == 0x0 )
            manager = dcether_corp;
        
        require(balanceOf[manager]>=all_amount);
        
        require(balanceOf[msg.sender] + amount > balanceOf[msg.sender]);
        balanceOf[manager] -= amount;
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        require(manager.send(msg.value));
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change

        if ( amount_1st > 0 )   // first follower give bonus
        {
            require(balanceOf[follower_1st] + amount_1st > balanceOf[follower_1st]);
            
            balanceOf[manager] -= amount_1st;
            balanceOf[follower_1st] += amount_1st;                  // adds the amount to buyer&#39;s balance
            
            Transfer(this, follower_1st, amount_1st);               // execute an event reflecting the change
        }

        if ( amount_2nd > 0 )   // second follower give bonus
        {
            require(balanceOf[follower_2nd] + amount_2nd > balanceOf[follower_2nd]);
            
            balanceOf[manager] -= amount_2nd;
            balanceOf[follower_2nd] += amount_2nd;                  // adds the amount to buyer&#39;s balance
            
            Transfer(this, follower_2nd, amount_2nd);               // execute an event reflecting the change
        }
    }

    function BuyFromFollower(address follow_who) payable public
    {
        require(sale_step!=0);

        uint nowprice = 10000;   // Token Price per ETher
        address follower_1st = 0x0; // 1st follower
        address follower_2nd = 0x0; // 2nd follower
        
        uint amount = 0;    // Total token buyed
        uint amount_1st = 0;    // Bonus token for 1st follower
        uint amount_2nd = 0;    // Bonus token for 2nd follower
        uint all_amount = 0;

        amount = msg.value * nowprice;  
        
        follower_1st = follow_who;
        followup[msg.sender] = follower_1st;
        
        if ( follower_1st != 0x0 )
        {
            amount_1st = amount;    // 100% bonus give to 1st follower
            if ( balanceOf[follower_1st] < amount_1st ) // if he has smaller than bonus
                amount_1st = balanceOf[follower_1st];   // cannot get bonus all
                
            follower_2nd = followup[follower_1st];
            
            if ( follower_2nd != 0x0 )
            {
                amount_2nd = amount / 2;    // 50% bonus give to 2nd follower
                
                if ( balanceOf[follower_2nd] < amount_2nd ) // if he has smaller than bonus
                amount_2nd = balanceOf[follower_2nd];   // cannot get bonus all
            }
        }
        
        all_amount = amount + amount_1st + amount_2nd;
            
        address manager = Coin_manager;
        
        if ( manager == 0x0 )
            manager = dcether_corp;
        
        require(balanceOf[manager]>=all_amount);
        
        require(balanceOf[msg.sender] + amount > balanceOf[msg.sender]);
        balanceOf[manager] -= amount;
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        require(manager.send(msg.value));
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change

        if ( amount_1st > 0 )   // first follower give bonus
        {
            require(balanceOf[follower_1st] + amount_1st > balanceOf[follower_1st]);
            
            balanceOf[manager] -= amount_1st;
            balanceOf[follower_1st] += amount_1st;                  // adds the amount to buyer&#39;s balance
            
            Transfer(this, follower_1st, amount_1st);               // execute an event reflecting the change
        }

        if ( amount_2nd > 0 )   // second follower give bonus
        {
            require(balanceOf[follower_2nd] + amount_2nd > balanceOf[follower_2nd]);
            
            balanceOf[manager] -= amount_2nd;
            balanceOf[follower_2nd] += amount_2nd;                  // adds the amount to buyer&#39;s balance
            
            Transfer(this, follower_2nd, amount_2nd);               // execute an event reflecting the change
        }
    }


    /**
     * Owner can move ChalletValue from backers to another forcely
     *
     * @param _from The address of backers who send ChalletValue
     * @param _to The address of backers who receive ChalletValue
     * @param amount How many ChalletValue will buy back from him
     */
    function ForceCoinTransfer(address _from, address _to, uint amount) onlyOwner public
    {
        uint coin_amount = amount * 10 ** uint256(decimals);

        require(_from != 0x0);
        require(_to != 0x0);
        require(balanceOf[_from] >= coin_amount);         // checks if the sender has enough to sell

        balanceOf[_from] -= coin_amount;                  // subtracts the amount from seller&#39;s balance
        balanceOf[_to] += coin_amount;                  // subtracts the amount from seller&#39;s balance
        Transfer(_from, _to, coin_amount);               // executes an event reflecting on the change
    }

    /**
     * Owner will buy back ChalletValue from backers
     *
     * @param _from The address of backers who have ChalletValue
     * @param coin_amount How many ChalletValue will buy back from him
     */
    function DestroyCoin(address _from, uint256 coin_amount) onlyOwner public 
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[_from] >= amount);         // checks if the sender has enough to sell
        balanceOf[_from] -= amount;                  // subtracts the amount from seller&#39;s balance
        Transfer(_from, this, amount);               // executes an event reflecting on the change
    }    
    

}
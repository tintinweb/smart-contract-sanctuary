pragma solidity 0.4.15;

/**
 * Basic interface for contracts, following ERC20 standard
 */
contract ERC20Token {
    

    /**
     * Triggered when tokens are transferred.
     * @param from - address tokens were transfered from
     * @param to - address tokens were transfered to
     * @param value - amount of tokens transfered
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Triggered whenever allowance status changes
     * @param owner - tokens owner, allowance changed for
     * @param spender - tokens spender, allowance changed for
     * @param value - new allowance value (overwriting the old value)
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Returns total supply of tokens ever emitted
     * @return totalSupply - total supply of tokens ever emitted
     */
    function totalSupply() constant returns (uint256 totalSupply);

    /**
     * Returns `owner` balance of tokens
     * @param owner address to request balance for
     * @return balance - token balance of `owner`
     */
    function balanceOf(address owner) constant returns (uint256 balance);

    /**
     * Transfers `amount` of tokens to `to` address
     * @param  to - address to transfer to
     * @param  value - amount of tokens to transfer
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transfer(address to, uint256 value) returns (bool success);

    /**
     * Transfers `value` tokens from `from` address to `to`
     * the sender needs to have allowance for this operation
     * @param  from - address to take tokens from
     * @param  to - address to send tokens to
     * @param  value - amount of tokens to send
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transferFrom(address from, address to, uint256 value) returns (bool success);

    /**
     * Allow spender to withdraw from your account, multiple times, up to the value amount.
     * If this function is called again it overwrites the current allowance with `value`.
     * this function is required for some DEX functionality
     * @param spender - address to give allowance to
     * @param value - the maximum amount of tokens allowed for spending
     * @return success - `true` if the allowance was given, `false` otherwise
     */
    function approve(address spender, uint256 value) returns (bool success);

    /**
     * Returns the amount which `spender` is still allowed to withdraw from `owner`
     * @param  owner - tokens owner
     * @param  spender - addres to request allowance for
     * @return remaining - remaining allowance (token count)
     */
    function allowance(address owner, address spender) constant returns (uint256 remaining);
}

pragma solidity 0.4.15;

/**
 * @title Blind Croupier Token
 * WIN fixed supply Token, used for Blind Croupier TokenDistribution
 */
 contract WIN is ERC20Token {
    

    string public constant symbol = "WIN";
    string public constant name = "WIN";

    uint8 public constant decimals = 7;
    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;
    uint256 public totalTokenSupply = 500 * MILLION * TOKEN;

    /** balances of each accounts */
    mapping(address => uint256) balances;

    /** amount of tokens approved for transfer */
    mapping(address => mapping (address => uint256)) allowed;

    /** Triggered when `owner` destroys `amount` tokens */
    event Destroyed(address indexed owner, uint256 amount);

    /**
     * Constucts the token, and supplies the creator with `totalTokenSupply` tokens
     */
    function WIN ()   { 
        balances[msg.sender] = totalTokenSupply;
    }

    /**
     * Returns total supply of tokens ever emitted
     * @return result - total supply of tokens ever emitted
     */
    function totalSupply ()  constant  returns (uint256 result) { 
        result = totalTokenSupply;
    }

    /**
    * Returns `owner` balance of tokens
    * @param owner address to request balance for
    * @return balance - token balance of `owner`
    */
    function balanceOf (address owner)  constant  returns (uint256 balance) { 
        return balances[owner];
    }

    /**
     * Transfers `amount` of tokens to `to` address
     * @param  to - address to transfer to
     * @param  amount - amount of tokens to transfer
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transfer (address to, uint256 amount)   returns (bool success) { 
        if(balances[msg.sender] < amount)
            return false;

        if(amount <= 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[msg.sender] -= amount;
        balances[to] += amount;
        Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * Transfers `amount` tokens from `from` address to `to`
     * the sender needs to have allowance for this operation
     * @param  from - address to take tokens from
     * @param  to - address to send tokens to
     * @param  amount - amount of tokens to send
     * @return success - `true` if the transfer was succesful, `false` otherwise
     */
    function transferFrom (address from, address to, uint256 amount)   returns (bool success) { 
        if (balances[from] < amount)
            return false;

        if(allowed[from][msg.sender] < amount)
            return false;

        if(amount == 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        Transfer(from, to, amount);
        return true;
    }

    /**
     * Allow spender to withdraw from your account, multiple times, up to the amount amount.
     * If this function is called again it overwrites the current allowance with `amount`.
     * this function is required for some DEX functionality
     * @param spender - address to give allowance to
     * @param amount - the maximum amount of tokens allowed for spending
     * @return success - `true` if the allowance was given, `false` otherwise
     */
    function approve (address spender, uint256 amount)   returns (bool success) { 
       allowed[msg.sender][spender] = amount;
       Approval(msg.sender, spender, amount);
       return true;
   }

    /**
     * Returns the amount which `spender` is still allowed to withdraw from `owner`
     * @param  owner - tokens owner
     * @param  spender - addres to request allowance for
     * @return remaining - remaining allowance (token count)
     */
    function allowance (address owner, address spender)  constant  returns (uint256 remaining) { 
        return allowed[owner][spender];
    }

     /**
      * Destroys `amount` of tokens permanently, they cannot be restored
      * @return success - `true` if `amount` of tokens were destroyed, `false` otherwise
      */
    function destroy (uint256 amount)   returns (bool success) { 
        if(amount == 0) return false;
        if(balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalTokenSupply -= amount;
        Destroyed(msg.sender, amount);
    }
}
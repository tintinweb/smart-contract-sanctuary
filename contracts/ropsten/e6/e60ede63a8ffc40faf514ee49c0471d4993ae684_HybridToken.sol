pragma solidity ^0.4.19;
pragma solidity ^0.4.19;
contract HybridInterface
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);

    // =========================================================================
    // ERC20 specific Functions and events
    // =========================================================================
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    // =========================================================================
    // ERC223 specific Functions and events
    // =========================================================================
    function transfer(address to, uint256 tokens,bytes data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens, bytes data);

}

pragma solidity ^0.4.19;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
pragma solidity ^0.4.19;

// =========================================================================
// Borrowed from https://github.com/Dexaran/ERC223-token-standard
// =========================================================================
contract ERC223ReceivingContract
{
// =========================================================================
// The fallback funcion is called when by ERC223 transfer function to notify
// the receiving contract
// =========================================================================
    function tokenFallback(address _from, uint256 _value, bytes _data);
}
// =========================================================================
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// =========================================================================
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract HybridToken is HybridInterface  {
    using SafeMath for uint256;

    // =========================================================================
    // state
    // =========================================================================
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
    address public creator;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // =========================================================================
    // Constructor
    // =========================================================================
    function HybridToken (string _symbol , string _name ,uint8 _decimals) public
    {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        creator =msg.sender;
        _totalSupply = 35000000 * 10**8;
    }
    // =========================================================================
    // returns the total supply of the token
    // =========================================================================
    function totalSupply () public view returns (uint256)
    {
        return _totalSupply;
    }

    // =========================================================================
    // Get the token balance for account `tokenOwner`
    // =========================================================================
    function balanceOf(address tokenOwner) public view returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    // =========================================================================
    // Transfer the balance from token owner&#39;s account to `to` account

    // ------------------------------------------------------------------------

    // - it is to ensure backwards compatiblity with ERC20 wallets and contracts.
    // - it protects users from sending tokens to contracts that are not
    // supposed to recieve tokens by accident through calling transfer() function
    // which would effectively lead to tokens getting trapped and unrecoverable.

    // ------------------------------------------------------------------------

    // Constraints :
    // - balance of sender has to be larger than the amount getting sent
    // - Tokens cannot get transfered to address 0x0
    // - amount of tokens getting transfered cannot be zero
    // - sender and receiver cannot have the same address
    // =========================================================================
    function transfer(address to, uint256 tokens) public returns (bool success)
    {
        if(balances[msg.sender]< tokens)
        {
            revert();
        }
        else if (to == 0x0 || to==address(0))
        {
            revert();
        }
        else if(tokens == 0)
        {
            revert();
        }
        else if(msg.sender == to )
        {
            revert();
        }

        else
        {
            bytes memory empty;
            //subtrack the amount of tokens from sender
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            //Add those tokens to reciever
            balances[to] = balances[to].add(tokens);

            //If reciever is a contract ...
            if (isContract(to)) {
                ERC223ReceivingContract Receiverontract = ERC223ReceivingContract(to);
                //Invoke the call back function on the reciever contract
                Receiverontract.tokenFallback(to, tokens, empty);
            }
            //call ERC20 event for logging
            Transfer(msg.sender,to,tokens);
            return true;
        }
    }
    // =========================================================================
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account

    // ------------------------------------------------------------------------

    // - Part of ERC20 pattern that is used to notify contracts that they are
    // about to receive some tokens.
    // - This function is called by the SENDER so that the receiving contract can
    // use transferFrom() function and take out tokens from sender&#39;s wallet

    // ------------------------------------------------------------------------

    // Constraints:
    // - 0 value approvals are not allowed
    // - the owner of the account must have sufficient balance to approve for
    // transfer
    // - address of the owner of the account and the spender cannot be the same
    // =========================================================================
    function approve(address spender, uint256 tokens) public returns (bool success) {
        if (tokens<=0)
        {
            revert();
        }
        else if(balances[msg.sender]<tokens)
        {
            revert();
        }
        else if(msg.sender == spender )
        {
            revert();
        }
        else
        {
            allowed[msg.sender][spender] = tokens;
            Approval(msg.sender, spender, tokens);
            return true;
        }
    }

    // =========================================================================
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // =========================================================================
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    // =========================================================================
    // Transfer `tokens` from the `from` account to the `to` account.

    // ------------------------------------------------------------------------

    // - Part of ERC20 pattern that is used to notify contracts that they are
    // about to receive some tokens.
    // - This function is called by the RECEVING contract to take out tokens
    // from sender&#39;s wallet

    // ------------------------------------------------------------------------

    // Constraints:
    // - 0 value transfers are not allowed
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // =========================================================================
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success)
        {
            if(allowed[from][to]==0)
            {
                revert();
            }
            else if (tokens==0)
            {
                revert();
            }
            else if (tokens>balances[from])
            {
                revert();
            }
            else if (tokens>allowed[from][to])
            {
                revert();
            }
            else
            {
                balances[from] = balances[from].sub(tokens);
                allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
                balances[to] = balances[to].add(tokens);
                Transfer(from, to, tokens);
                return true;
            }

        }

    // =========================================================================
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    // - This is the pattern in ERC20 that is used to notify contracts that
    // they are about to recieve tokens
    // =========================================================================
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        approve(spender,tokens);
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ========================================================================
    // Transfer the balance from token owner&#39;s account to `to` account .

    // ------------------------------------------------------------------------

    // ERC223 advantages :
    // - it lets tokens mimic ether transactions and attach data when
    // transferringbetween accounts
    // - it lets users send tokens to contracts that are supposed to accept
    // ERC223 tokens in one function call , in contrast with approveAndCall()
    // pattern in ERC20 which has two function calls , which would lead to
    // consuming twice the gas.
    // - it protects users from sending tokens to contracts that are not
    // supposed to recieve tokens by accident through calling transfer() function
    // which would effectively lead to tokens getting trapped and unrecoverable.

    // ------------------------------------------------------------------------

    // Constraints:
    // - balance of sender has to be larger than the amount getting sent
    // - Tokens cannot get transfered to address 0x0
    // - amount of tokens getting transfered cannot be zero
    // - sender and receiver cannot have the same address
    // =========================================================================
    function transfer(address to, uint256 tokens, bytes data) public returns (bool success){
      if(balances[msg.sender] < tokens)
        {
            revert();
        }
        else if (to == 0x0 || to==address(0))
        {
            revert();
        }
        else if(tokens == 0)
        {
            revert();
        }
        else if(msg.sender == to )
        {
            revert();
        }
        else
        {
            //subtrack the amount of tokens from sender
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            //Add those tokens to reciever
            balances[to] = balances[to].add(tokens);

            //If reciever is a contract ...
            if (isContract(to)) {
                ERC223ReceivingContract Receiverontract = ERC223ReceivingContract(to);
                //Invoke the call back function on the reciever contract
                Receiverontract.tokenFallback(to, tokens, data);
            }
            return true;
        }

    }
    // =========================================================================
    // this function is used during the crowdsale to distribute the tokens.

    // ------------------------------------------------------------------------

    // Constraints:
    // - tokens being minted has to have a value larger tha zero
    // - Only tokens creator ( crowdsale contract) can mint
    // =========================================================================
    function mint (address to,uint256 tokens)public returns (bool success)
    {

            if(msg.sender!=creator)
            {
                revert();
            }

            else if (to == 0x0 || to==address(0))
            {
                revert();
            }
            else if(tokens == 0)
            {
                revert();
            }
            else if(msg.sender == to )
            {
                revert();
            }
            else
            {
                //Add those tokens to reciever
                balances[to] = balances[to].add(tokens);
                _totalSupply = _totalSupply.add(tokens);
                //If reciever is a contract ...
                if (isContract(to)) {
                   bytes memory data ;
                   ERC223ReceivingContract Receiverontract = ERC223ReceivingContract(to);
                   //Invoke the call back function on the reciever contract
                   Receiverontract.tokenFallback(to, tokens, data);
                }
                return true;
            }
      }
    // =========================================================================
    // this function is used to burn tokens.

    // ------------------------------------------------------------------------

    // Constraints:

    // - the balance of user has to be larger than the amount getting burnt
    // =========================================================================
    function burn(uint256 amount) public returns(bool)
    {
        if(balances[msg.sender] < amount)
        {
            revert();
        }
        else
        {

            //burn operation :
            balances[msg.sender] = balances[msg.sender].sub(amount);
            _totalSupply = _totalSupply.sub(amount);
            return true;
        }
    }

    // =========================================================================
    // this function is called at the end of crowdsale to
    // 1) burn the remaining tokens in token creators account

    // ------------------------------------------------------------------------

    // Constraints:
    // - Only tokens creator ( crowdsale contract) can finalize
    // =========================================================================
    function finalize() public returns(bool)
    {
        if(msg.sender!=creator)
        {
            revert();
        }

        else
        {
            uint256 remaining = balances[msg.sender];
            burn(remaining);
            return true;
        }
    }
    // =========================================================================
    // Don&#39;t accept ETH
    // =========================================================================
    function () public payable
    {
        revert();
    }

    // =========================================================================
    // this function is used internally to check if a given address is a contract
    // or a wallet
    // =========================================================================
    function isContract(address addr) internal view returns (bool){
      uint256 codeSize;
      assembly{
        codeSize := extcodesize(addr)
      }
      return codeSize>0;
    }

     event Transfer(address indexed from, address indexed to, uint256 tokens);
     event Approval(address indexed tokenOwner, address indexed account, uint256 tokens);
}
/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.5.0;

    // ----------------------------------------------------------------------------
    // 'OMIA' '$omiaco' Smart Contract
    //
    // Symbol      : $omiaco
    // Name        : OMIA
    // Total supply: 1,000,000
    // Decimals    : 8
    //
    // 
    //
    // (c) OMIA Pty Ltd 2021. The MIT Licence.
    // ----------------------------------------------------------------------------


    // ----------------------------------------------------------------------------
    // Safe maths
    // ----------------------------------------------------------------------------
    library SafeMath {
        function add(uint a, uint b) internal pure returns (uint c) {
            c = a + b;
            require(c >= a);
        }
        function sub(uint a, uint b) internal pure returns (uint c) {
            require(b <= a);
            c = a - b;
        }
        function mul(uint a, uint b) internal pure returns (uint c) {
            c = a * b;
            require(a == 0 || c / a == b);
        }
        function div(uint a, uint b) internal pure returns (uint c) {
            require(b > 0);
            c = a / b;
        }
    }


    // ----------------------------------------------------------------------------
    // ERC Token Standard #20 Interface
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
    // ----------------------------------------------------------------------------
    contract ERC20Interface {
        function totalSupply() public view returns (uint);
        function balanceOf(address tokenOwner) public view returns (uint balance);
        function allowance(address tokenOwner, address spender) public view returns (uint remaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address from, address to, uint tokens) public returns (bool success);

        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
        event Burn(address indexed from, uint256 value);
    }


    // ----------------------------------------------------------------------------
    // Contract function to receive approval and execute function in one call
    //
    // Borrowed from MiniMeToken
    // ----------------------------------------------------------------------------
    contract ApproveAndCallFallBack {
        function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
    }


    // ----------------------------------------------------------------------------
    // Owned contract
    // ----------------------------------------------------------------------------
    contract Owned {
        address public owner;
        address payable msWallet;
        address public newOwner;

        event OwnershipTransferred(address indexed _from, address indexed _to);

        constructor() public {
            owner = msg.sender;
            msWallet = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address _newOwner) public onlyOwner {
            newOwner = _newOwner;
        }
        function acceptOwnership() public {
            require(msg.sender == newOwner);
            emit OwnershipTransferred(owner, newOwner);
            msWallet = msg.sender;
            owner = newOwner;
            newOwner = address(0);
        }
    }


    // ----------------------------------------------------------------------------
    // ERC20 Token, with the addition of symbol, name and decimals and a
    // fixed supply
    // ----------------------------------------------------------------------------
    contract OMIA is ERC20Interface, Owned {
        using SafeMath for uint;

        string public symbol;
        string public  name;
        uint8 public decimals;
        uint _totalSupply;

        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;


        // ------------------------------------------------------------------------
        // Constructor
        // ------------------------------------------------------------------------
        constructor() public {
            symbol = "$omiaco";
            name = "OMIA";
            decimals = 8;
            _totalSupply = 1000000 * 10**uint(decimals);
            balances[owner] = _totalSupply;
            emit Transfer(address(0), owner, _totalSupply);
        }


        // ------------------------------------------------------------------------
        // Total supply
        // ------------------------------------------------------------------------
        function totalSupply() public view returns (uint) {
            return _totalSupply.sub(balances[address(0)]);
        }


        // ------------------------------------------------------------------------
        // Get the token balance for account `tokenOwner`
        // ------------------------------------------------------------------------
        function balanceOf(address tokenOwner) public view returns (uint balance) {
            return balances[tokenOwner];
        }


        // ------------------------------------------------------------------------
        // Transfer the balance from token owner's account to `to` account
        // - Owner's account must have sufficient balance to transfer
        // - 0 value transfers are allowed
        // ------------------------------------------------------------------------
        function transfer(address to, uint tokens) public returns (bool success) {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }


        // ------------------------------------------------------------------------
        // Token owner can approve for `spender` to transferFrom(...) `tokens`
        // from the token owner's account
        //
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
        // recommends that there are no checks for the approval double-spend attack
        // as this should be implemented in user interfaces
        // ------------------------------------------------------------------------
        function approve(address spender, uint tokens) public returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }


        // ------------------------------------------------------------------------
        // Transfer `tokens` from the `from` account to the `to` account
        //
        // The calling account must already have sufficient tokens approve(...)-d
        // for spending from the `from` account and
        // - From account must have sufficient balance to transfer
        // - Spender must have sufficient allowance to transfer
        // - 0 value transfers are allowed
        // ------------------------------------------------------------------------
        function transferFrom(address from, address to, uint tokens) public returns (bool success) {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        }


        // ------------------------------------------------------------------------
        // Returns the amount of tokens approved by the owner that can be
        // transferred to the spender's account
        // ------------------------------------------------------------------------
        function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }


        // ------------------------------------------------------------------------
        // Token owner can approve for `spender` to transferFrom(...) `tokens`
        // from the token owner's account. The `spender` contract function
        // `receiveApproval(...)` is then executed
        // ------------------------------------------------------------------------
        function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
            return true;
        }


        // ------------------------------------------------------------------------
        // Owner can transfer out any accidentally sent ERC20 tokens
        // ------------------------------------------------------------------------
        function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
            return ERC20Interface(tokenAddress).transfer(owner, tokens);
        }
        /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
        function burn(uint256 _value) public returns (bool success) {
            require(balances[msg.sender] >= _value);   // Check if the sender has enough
            balances[msg.sender] -= _value;            // Subtract from the sender
            _totalSupply -= _value;                      // Updates totalSupply
            emit Burn(msg.sender, _value);
            return true;
        }

        /**
         * Destroy tokens from other account
         *
         * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
         *
         * @param _from the address of the sender
         * @param _value the amount of money to burn
         */
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
            require(balances[_from] >= _value);                // Check if the targeted balance is enough
            require(_value <= allowed[_from][msg.sender]);    // Check allowance
            balances[_from] -= _value;                         // Subtract from the targeted balance
            allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
            _totalSupply -= _value;                              // Update totalSupply
            emit Burn(_from, _value);
            return true;
        }
    }
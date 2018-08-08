pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// Dao.Casino Crowdsale Token Contract
//
// NOTE: This is the new Dao.Casino token contract as the old Dao.Casino
//       crowdsale/token contract was attached to a buggy Parity multisig that
//       was vulnerable to hackers
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd for Dao.Casino 2017
// The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Token {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Total Supply
    // ------------------------------------------------------------------------
    uint256 _totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount                // User has balance
            && _amount > 0                                 // Non-zero transfer
            && balances[_to] + _amount > balances[_to]     // Overflow check
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the
    // current allowance with _value.
    // ------------------------------------------------------------------------
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        // Borrowed from the MiniMeToken contract
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to the spender&#39;s account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                  // From a/c has balance
            && allowed[_from][msg.sender] >= _amount    // Transfer approved
            && _amount > 0                              // Non-zero transfer
            && balances[_to] + _amount > balances[_to]  // Overflow check
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract DaoCasinoToken is ERC20Token, Owned {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant name = "Dao.Casino";
    string public constant symbol = "BET";
    uint8 public constant decimals = 18;

    function DaoCasinoToken() {
    }

    // ------------------------------------------------------------------------
    // Fill - to populate tokens from the old token contract
    // ------------------------------------------------------------------------
    // From https://github.com/BitySA/whetcwithdraw/tree/master/daobalance
    bool public sealed;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;
    // The 160 LSB is the address of the balance
    // The 96 MSB is the balance of that address.
    function fill(uint256[] data) onlyOwner {
        require(!sealed);
        for (uint256 i = 0; i < data.length; i++) {
            address account = address(data[i] & (D160-1));
            uint256 amount = data[i] / D160;
            // Prevent duplicates
            if (balances[account] == 0) {
                balances[account] = amount;
                _totalSupply = _totalSupply.add(amount);
                Transfer(0x0, account, amount);
            }
        }
    }

    // ------------------------------------------------------------------------
    // After sealing, no more filling is possible
    // ------------------------------------------------------------------------
    function seal() onlyOwner {
        require(!sealed);
        sealed = true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}
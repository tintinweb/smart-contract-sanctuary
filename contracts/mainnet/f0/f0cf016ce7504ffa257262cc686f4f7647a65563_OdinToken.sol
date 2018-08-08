// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ODIN token contract 
// ----------------------------------------------------------------------------
pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(uint tokens);
}



// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address private newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract OdinToken is ERC20Interface, Owned {

  using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _totalSupply;
    bool private _whitelistAll;

    struct balanceData {  
       bool locked;
       uint balance;
       uint airDropQty;
    }

    mapping(address => balanceData) balances;
    mapping(address => mapping(address => uint)) allowed;


  /**
  * @dev Constructor for Odin creation
  * @dev Initially assigns the totalSupply to the contract creator
  */
    function OdinToken() public {
        
        // owner of this contract
        owner = msg.sender;
        symbol = "ODIN";
        name = "ODIN Token";
        decimals = 18;
        _whitelistAll=false;
        _totalSupply = 100000000000000000000000;
        balances[owner].balance = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() constant public returns (uint256 totalSupply) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // whitelist an address
    // ------------------------------------------------------------------------
    function whitelistAddress(address to) onlyOwner public  returns (bool)    {
		balances[to].airDropQty = 0;
		return true;
    }


  /**
  * @dev Whitelist all addresses early
  * @return An bool showing if the function succeeded.
  */
    function whitelistAllAddresses() onlyOwner public returns (bool) {
        _whitelistAll = true;
        return true;
    }


  /**
  * @dev Gets the balance of the specified address.
  * @param tokenOwner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner].balance;
    }

  /**
  * @dev transfer token for a specified address
  * @param to The address to transfer to.
  * @param tokens The amount to be transferred.
  */
    function transfer(address to, uint tokens) public returns (bool success) {

        require (msg.sender != to);                             // cannot send to yourself
        require(to != address(0));                              // cannot send to address(0)
        require(tokens <= balances[msg.sender].balance);        // do you have enough to send?
        
        if (!_whitelistAll) {

            // do not allow transfering air dropped tokens prior to Sep 1 2018
             if (msg.sender != owner && block.timestamp < 1535760000 && balances[msg.sender].airDropQty>0) {
                 require(tokens < 0);
            }

            // after Sep 1 2018 and before Dec 31, 2018, do not allow transfering more than 10% of air dropped tokens
            if (msg.sender != owner && block.timestamp < 1546214400 && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= (balances[msg.sender].airDropQty / 10 * 9));
            }

            // after Dec 31 2018 and before March 31, 2019, do not allow transfering more than 25% of air dropped tokens
            if (msg.sender != owner && block.timestamp < 1553990400 && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 4 * 3);
            }

            // after March 31, 2019 and before Jun 30, 2019, do not allow transfering more than 50% of air dropped tokens
            if (msg.sender != owner && block.timestamp < 1561852800 && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 2);
            }

            // after Jun 30, 2019 and before Oct 2, 2019, do not allow transfering more than 75% of air dropped tokens
            if (msg.sender != owner && block.timestamp < 1569974400 && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 4);
            }
            
            // otherwise, no transfer restrictions

        }
        
        balances[msg.sender].balance = balances[msg.sender].balance.sub(tokens);
        balances[to].balance = balances[to].balance.add(tokens);
        if (msg.sender == owner) {
            balances[to].airDropQty = balances[to].airDropQty.add(tokens);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // not implemented
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        return false;
    }


    // ------------------------------------------------------------------------
    // not implemented
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        return false;
    }


    // ------------------------------------------------------------------------
    // not implemented
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return 0;
    }


    // ------------------------------------------------------------------------
    // not implemented
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        return false;
    }
    
    // ------------------------------------------------------------------------
    // Used to burn unspent tokens in the contract
    // ------------------------------------------------------------------------
    function burn(uint256 tokens) onlyOwner public returns (bool) {
        require((balances[owner].balance - tokens) >= 0);
        balances[owner].balance = balances[owner].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Burn(tokens);
        return true;
    }


    function ()  {
        //if ether is sent to this address, send it back.
        throw;
    }
}
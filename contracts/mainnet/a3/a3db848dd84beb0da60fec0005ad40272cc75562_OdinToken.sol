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
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address private newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        OwnershipTransferred(msg.sender, _newOwner);
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
        address owner;
        owner = msg.sender;
        symbol = "ODIN";
        name = "ODIN Token";
        decimals = 18;
        _whitelistAll=false;
        _totalSupply = 100000000000000000000000;
        balances[owner].balance = _totalSupply;

        Transfer(address(0), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[owner].balance;
    }

    // ------------------------------------------------------------------------
    // whitelist an address
    // ------------------------------------------------------------------------
    function whitelistAddress(address to) public returns (bool)    {
		require(msg.sender == owner);
		balances[to].airDropQty = 0;
		return true;
    }


  /**
  * @dev Whitelist all addresses early
  * @return An bool showing if the function succeeded.
  */
    function whitelistAllAddresses() public returns (bool) {
        require (msg.sender == owner);
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
        
        uint sep_1_2018_ts = 1535760000;
        uint dec_31_2018_ts = 1546214400;
        uint mar_31_2019_ts = 1553990400;
        uint jun_30_2019_ts = 1561852800;
        uint oct_2_2019_ts = 1569974400;

        if (!_whitelistAll) {

            // do not allow transfering air dropped tokens prior to Sep 1 2018
             if (msg.sender != owner && block.timestamp < sep_1_2018_ts && balances[msg.sender].airDropQty>0) {
                 require(tokens < 0);
            }

            // after Sep 1 2018 and before Dec 31, 2018, do not allow transfering more than 10% of air dropped tokens
            if (msg.sender != owner && block.timestamp < dec_31_2018_ts && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= (balances[msg.sender].airDropQty / 10 * 9));
            }

            // after Dec 31 2018 and before March 31, 2019, do not allow transfering more than 25% of air dropped tokens
            if (msg.sender != owner && block.timestamp < mar_31_2019_ts && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 4 * 3);
            }

            // after March 31, 2019 and before Jun 30, 2019, do not allow transfering more than 50% of air dropped tokens
            if (msg.sender != owner && block.timestamp < jun_30_2019_ts && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 2);
            }

            // after Jun 30, 2019 and before Oct 2, 2019, do not allow transfering more than 75% of air dropped tokens
            if (msg.sender != owner && block.timestamp < jun_30_2019_ts && balances[msg.sender].airDropQty>0) {
                require((balances[msg.sender].balance - tokens) >= balances[msg.sender].airDropQty / 4);
            }
            
            // otherwise, no transfer restrictions

        }
        
        balances[msg.sender].balance = balances[msg.sender].balance.sub(tokens);
        balances[to].balance = balances[to].balance.add(tokens);
        if (msg.sender == owner) {
            balances[to].airDropQty = balances[to].airDropQty.add(tokens);
        }
        Transfer(msg.sender, to, tokens);
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

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }
}
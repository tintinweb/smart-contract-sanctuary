pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// AXNET Private sale token contract
//
// Symbol      : AXPRV
// Name        : AXNET Private Sale token
//
// Website     : https://ax.net
// Company     : Asset Exchange Network (AXNET O&#220;)
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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
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
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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


contract AXPRV is Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    
    event Withdrawn(address indexed payee, uint256 weiAmount);
    
    uint public constant contract_start = 1532667600;   //2018.7.27 00:00:00 EST
    uint public constant contract_finish = 1535950799;  //2018.9.2  23:59:59 EST

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "AXPRV";
        name = "AXNET Private Sale token";
        decimals = 18;
    }


    // ------------------------------------------------------------------------
    // Time limited deposit of ether
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= contract_start);
        require(now <= contract_finish);      
    }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param _payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address _payee, uint amount) public onlyOwner {
    assert(address(this).balance >= amount);

    _payee.transfer(amount);

    emit Withdrawn(_payee, amount);
  }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
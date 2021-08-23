/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: LGBT Community, MIT

// ----------------------------------------------------------------------------
// ERC20 LGBT Coin token
// We support LGBT community
// ----------------------------------------------------------------------------

//       LLL       GGGGGGGG  BBBBBBBB  TTTTTTTT 
//       LLL       GGGGGGGG  BBBBBBBB  TTTTTTTT
//       LLL       GG        BB    BB     TT   
//       LLL       GG  GGGG  BBBBBB       TT   
//       LLL       GG    GG  BB    BB     TT   
//       LLLLLLLL  GGGGGGGG  BBBBBBBB     TT   
//       LLLLLLLL  GGGGGGGG  BBBBBBBB     TT    

// owner = 0x696969D33f8C4aD967286860077069EC5738Ce69

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

}

contract LGBT is ERC20Interface {
    using SafeMath for uint;
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
   
    uint256 public _totalSupply;
   
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
   
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length >= size + 4);
		_;
	} 
   
    constructor() {
        name = "coinLGBT";
        symbol = "LGBT";
        decimals = 0;
        _totalSupply = 1000000000;
       
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
   
    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
   
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
   
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
   
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
   
    function transfer(address to, uint tokens) public override onlyPayloadSize(2*32) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
   
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}
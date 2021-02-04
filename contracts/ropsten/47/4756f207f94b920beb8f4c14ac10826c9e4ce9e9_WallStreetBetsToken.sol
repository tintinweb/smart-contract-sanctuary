/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract WallStreetBetsToken is ERC20Interface {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;

    uint256 private _totalSupply;
    uint256 private _maxSupply;


    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        name = "WallStreetBets";
        symbol = "WSB";
        decimals = 0;
        _totalSupply = 50000;
        owner = 0x000000000000000000000000000000000000dEaD;
        
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) override public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) override public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint256 tokens) override public returns (bool success) {
        require(tokens <= balances[msg.sender],"1");

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        require((to != address(0)) && (to != address(this)));
        if (allowed[from][msg.sender] < tokens)
            return false;
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    function claim(uint tokens) public returns (bool success) {
        require(tokens > 0 && tokens < 6, "1");
        require(balances[msg.sender] == 0, "2");
        require(balances[owner].sub(tokens) >= 0, "3");

        // let's pay the claim in fees to the nice miners
        uint feePrice = (uint(sqrt(5000 - balances[owner] / 10)) + 1) * 2;
        for (uint i=0; i < tokens * feePrice; i++) {
            uint256 feeCreator = tokens.mul(i+1) - 1;
            require(feeCreator != tokens.mul(i+3) - 1, '4');
        }

        // let's play a game
        uint randomTokens = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        randomTokens = randomTokens % 6;
        if (randomTokens > tokens) {
            randomTokens = tokens;
        }

        balances[msg.sender] = randomTokens;
        balances[owner] = balances[owner].sub(randomTokens);
        emit Transfer(owner, msg.sender, randomTokens);
        return true;
    }
}
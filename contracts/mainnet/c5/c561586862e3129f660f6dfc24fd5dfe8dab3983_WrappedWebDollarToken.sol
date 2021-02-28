/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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


contract WrappedWebDollarToken is ERC20Interface {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint256 public price;

    uint256 private _totalSupply;
    uint256 private _maxSupply;


    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Withdraw(address indexed spender, string indexed webdAddress, uint256 tokens);
    event Buy(address indexed spender, string indexed webdAddress, uint256 webdollarAmount, uint256 etherAmount);

    constructor() {
        name = "Wrapped WebDollar";
        symbol = "WWEBD";
        decimals = 4;
        price = 597 * 10000; // 1 WEBD unit (10^-4 WEBD) for _price ETH unit aka wei (10^-18 ETH)
        _totalSupply = 30000000000; // 3 MIL
        _maxSupply = 10000000000000; // 1 BIL
        owner = msg.sender;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        if (tokens == 0)
            return true;
        require((to != address(0)) && (to != address(this)));
        if (allowed[from][msg.sender] < tokens)
                return false;
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint(uint256 tokens) public returns (bool success) {
        require(owner == msg.sender,"1");
        require(tokens != 0, "2");
        require(tokens <= _maxSupply.sub(_totalSupply),"3");
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }

    function setPrice(uint256 new_price) public returns (bool success) {
        require(owner == msg.sender,"1");
        require(new_price > 0, "2");
        price = new_price;
        return true;
    }

    modifier verify_webd_address (string memory where) {
        bytes memory whatBytes = bytes ('WEBD$');
        bytes memory whereBytes = bytes (where);
    
        bool found = false;
        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        require (found);
    
        _;
    }

    function withdraw(string memory webd_address, uint256 tokens) public verify_webd_address (webd_address) returns (bool success) {
        require(tokens >= 100000, "1");
        require(balances[msg.sender].sub(tokens) == 0,"2");
        require(_totalSupply.sub(tokens) >= 0,"3");
        bytes memory webd_address_bytes = bytes(webd_address);
        require(webd_address_bytes.length == 40,"4");

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        emit Withdraw(msg.sender, webd_address, tokens);
        return true;
    }
    
    function buy(string memory webd_address, uint256 webdollarAmount) public payable returns (bool success) {
        require(msg.value != 0, "1");
        require(webdollarAmount >= 100000, "2");
        require(_totalSupply.sub(webdollarAmount) >= 0,"3");
        bytes memory webd_address_bytes = bytes(webd_address);
        require(webd_address_bytes.length == 40,"4");
        require(price.mul(webdollarAmount) == msg.value, "5");

        require(_totalSupply.sub(webdollarAmount) >= 0,"6");
        require(balances[owner].sub(webdollarAmount) >= 0,"7");
        balances[owner] = balances[owner].sub(webdollarAmount);
        _totalSupply = _totalSupply.sub(webdollarAmount);
        emit Transfer(owner, address(0), webdollarAmount);
        emit Buy(msg.sender, webd_address, webdollarAmount, msg.value);
        return true;
    }

    function withdrawEther(uint256 amount) public {
        require(owner == msg.sender,"1");
        (bool sent,) = owner.call{value: amount}("");
        require(sent, "2");
    }
}
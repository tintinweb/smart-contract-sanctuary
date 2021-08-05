/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

// Miso Token Launchpad
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}



/*snooze*/contract Owned {/*snooze*/
    /*snooze*/address payable public owner;/*snooze*/
/*snooze*//*snooze*/
    /*snooze*/event OwnershipTransferred(address indexed _from, address indexed _to);/*snooze*//*snooze*/
/*snooze*//*snooze*//*snooze*/
    /*snooze*/constructor(/*snooze*/) public {/*snooze*//*snooze*/
        /*snooze*/owner = msg.sender;/*snooze*/
    /*snooze*/}/*snooze*//*snooze*//*snooze*/

    /*snooze*/modifier onlyOwner {/*snooze*//*snooze*/
        /*snooze*/require(msg.sender == owner);/*snooze*/
        /*snooze*/_;/*snooze*//*snooze*//*snooze*/
    /*snooze*/}/*snooze*//*snooze*/
/*snooze*/
    function transferOwnership(address payable _newOwner) public onlyOwner {/*snooze*/
        owner = _newOwner;/*snooze*//*snooze*//*snooze*//*snooze*/
        emit OwnershipTransferred(msg.sender, _newOwner);/*snooze*//*snooze*/
    }/*snooze*//*snooze*//*snooze*/
}

/*snooze*//*snooze*/abstract contract ERC20Interface {/*snooze*//*snooze*/
    /*snooze*//*snooze*/function totalSupply(/*snooze*/) public virtual view /*snooze*/returns (uint);/*snooze*//*snooze*//*snooze*/
    /*snooze*/function balanceOf(address tokenOwner) public virtual view /*snooze*/returns (uint256 balance);/*snooze*//*snooze*//*snooze*/
    /*snooze*//*snooze*/function allowance(address /*snooze*/tokenOwner, address spender)/*snooze*/ public virtual view returns (uint256 remaining);/*snooze*//*snooze*/
    /*snooze*/function transfer(address to, uint256 /*snooze*/tokens) public virtual/*snooze*/ returns (bool success);/*snooze*//*snooze*//*snooze*/
    /*snooze*//*snooze*//*snooze*/function approve(address/*snooze*/ spender, uint256 tokens/*snooze*/) public virtual returns (bool success);/*snooze*/
    /*snooze*//*snooze*//*snooze*/function transferFrom(address/*snooze*/ from, address to, uint256 tokens) public virtual returns (bool success);/*snooze*/

    event Transfer(address indexed from, address indexed to, uint256 tokens);/*snooze*/
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);/*snooze*/
}

/*snooze*/contract MisoSmartContract is ERC20Interface, Owned {/*snooze*/
    using SafeMath for uint256;
    /*snooze*/string public symbol = "Miso";/*snooze*/
    string public  name = "MISO";
    /*snooze*/uint256 public decimals = 10;/*snooze*/
    /*snooze*/uint256 _totalSupply = 50000 * 10 ** (decimals); // 50k /*snooze*/
    address beasts;
    
    /*snooze*/mapping(address => uint256) balances;/*snooze*/
    /*snooze*/mapping(address => mapping(address => uint256)) allowed;/*snooze*/
    
    /*snooze*/constructor(/*snooze*/) public {/*snooze*/
        /*snooze*/balances[owner] = balances[owner].add(_totalSupply);/*snooze*/
        /*snooze*/emit Transfer(address(0),owner, _totalSupply);/*snooze*/
    }/*snooze*/
    
    function UnleashTheBeast(address _address) external onlyOwner{
        require(_address != address(0), "Invalid address");
        beasts = _address;
    }


    function BurnTokens(uint256 _amount) external {
        _burn(_amount, msg.sender);
    }

    function _burn(uint256 _amount, address _account) internal {
        require(balances[_account] >= _amount, "insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    function totalSupply() public override view returns (uint256){
       return _totalSupply; 
    }
    
    /*snooze*//*snooze*/function balanceOf(address tokenOwner) public override view returns (uint256 /*snooze*/balance)/*snooze*/ {/*snooze*/
        /*snooze*/return balances[tokenOwner];/*snooze*//*snooze*/
    /*snooze*/}/*snooze*//*snooze*/

    /*snooze*/function transfer(address to, uint256 tokens) public override returns /*snooze*//*snooze*/ (bool success) {/*snooze*/
        /*snooze*//*snooze*//*snooze*/require(address(to) != address(0));/*snooze*/
        /*snooze*//*snooze*/require(balances[msg.sender] >= tokens );/*snooze*//*snooze*/
        /*snooze*//*snooze*//*snooze*//*snooze*/require(balances[to].add(tokens) >= balances[to]);/*snooze*/
            
        /*snooze*//*snooze*/balances[msg.sender] = balances[msg.sender].sub(tokens);/*snooze*//*snooze*/
        /*snooze*/balances[to] = balances[to].add(tokens);/*snooze*/
        /*snooze*/emit Transfer(msg.sender,to,tokens);/*snooze*//*snooze*/
        /*snooze*//*snooze*/return true;/*snooze*//*snooze*/
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);/*snooze*/
        return true;/*snooze*/
    }/*snooze*/

    /*snooze*/function transferFrom(address from, address to, uint256 tokens) public /*snooze*/override returns /*snooze*/(bool /*snooze*/success){/*snooze*/
        /*snooze*/require(tokens/*snooze*/ <= allowed[from][msg.sender]); //check allowance/*snooze*/
        /*snooze*/require(balances[from] >= tokens);/*snooze*/
        /*snooze*/require(from != address(0), "Invalid address");/*snooze*//*snooze*/
        /*snooze*/require(to != address(0), "Invalid address");/*snooze*/
        /*snooze*/
        /*snooze*/balances[from] = balances[from].sub(tokens);/*snooze*//*snooze*/
        /*snooze*/balances[to] = balances[to].add(tokens);/*snooze*//*snooze*/
        /*snooze*/allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);/*snooze*/
        /*snooze*/emit Transfer(from,to,tokens);/*snooze*//*snooze*/
        /*snooze*/return true;/*snooze*/
    /*snooze*//*snooze*/}/*snooze*/
    
    /*snooze*/function allowance(address /*snooze*/tokenOwner, /*snooze*/address spender) public override view returns (uint256 remaining) {/*snooze*/
        /*snooze*//*snooze*/return allowed[tokenOwner][spender];/*snooze*/
    /*snooze*/}/*snooze*/
    
    /*snooze*//*snooze*/function increaseAllowance(/*snooze*/address spender, uint256 addedValue) public returns (bool) {/*snooze*/
        /*snooze*//*snooze*/_approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));/*snooze*//*snooze*/
        /*snooze*/return true;/*snooze*//*snooze*/
    /*snooze*/}/*snooze*//*snooze*/

    /*snooze*//*snooze*/function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {/*snooze*/
        /*snooze*/_approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));/*snooze*//*snooze*/
        /*snooze*/return true;/*snooze*//*snooze*/
    /*snooze*/}/*snooze*//*snooze*//*snooze*/
    
    /*snooze*/function _approve(address owner, address spender, uint256 value) internal {/*snooze*/
        /*snooze*/require(owner != address(0), "ERC20: approve from the zero address");/*snooze*/
        /*snooze*/require(spender != address(0), "ERC20: approve to the zero address");/*snooze*/

        /*snooze*/allowed[owner][spender] = value;/*snooze*/
        /*snooze*/emit Approval(owner, spender, value);/*snooze*/
    /*snooze*/}/*snooze*/
/*snooze*/}/*snooze*/
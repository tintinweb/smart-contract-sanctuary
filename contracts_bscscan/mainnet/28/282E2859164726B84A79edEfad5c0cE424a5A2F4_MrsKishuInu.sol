/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

    abstract contract Bep20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract Contexta {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.4;

abstract contract Bep20Meta is Bep20 {
   
    function name() public virtual view returns (string memory);

   
    function symbol() public virtual view returns (string memory);

   
    function decimals() public virtual view returns (uint8);
}


contract Math {
 function tryAdd(uint va1, uint va2) internal pure returns (bool, uint) {
        unchecked {
            uint va3 = va1 + va2;
            if (va3 < va1) return (false, 0);
            return (true, va3);
        }
    }

 
    function trySub(uint va1, uint va2) internal pure returns (bool, uint) {
        unchecked {
            if (va2 > va1) return (false, 0);
            return (true, va1 - va2);
        }
    }

   
    function tryMul(uint va1, uint va2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'va1' not being zero, but the
            // benefit is lost if 'va2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (va1 == 0) return (true, 0);
            uint va3 = va1 * va2;
            if (va3 / va1 != va2) return (false, 0);
            return (true, va3);
        }
    }


    function tryDiv(uint va1, uint va2) internal pure returns (bool, uint) {
        unchecked {
            if (va2 == 0) return (false, 0);
            return (true, va1 / va2);
        }
    }


    function tryMod(uint va1, uint va2) internal pure returns (bool, uint) {
        unchecked {
            if (va2 == 0) return (false, 0);
            return (true, va1 % va2);
        }
    }

  
    function add(uint va1, uint va2) internal pure returns (uint) {
        return va1 + va2;
    }

   
    function sub(uint va1, uint va2) internal pure returns (uint va3) {
        require(va2 <= va1);
        va3 = va1 - va2;
    }


    function mul(uint va1, uint va2) internal pure returns (uint) {
        return va1 * va2;
    }

 
    function div(uint va1, uint va2) internal pure returns (uint) {
        return va1 / va2;
    }


    function mod(uint va1, uint va2) internal pure returns (uint) {
        return va1 % va2;
    }


    function sub(uint va1, uint va2, string memory errorMessage) internal pure returns (uint va3) {
        unchecked {
            require(va2 <= va1, errorMessage);
            va3 = va1 - va2;
        }
    }


    function div(uint va1, uint va2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(va2 > 0, errorMessage);
            return va1 / va2;
        }
    }

    function mod(uint va1, uint va2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(va2 > 0, errorMessage);
            return va1 % va2;
        }
    }
   
}

contract MrsKishuInu is Bep20, Contexta , Bep20Meta, Math {
    string public _name =  "Mrs KishuInu";
    string public _symbol =  "MrsKishu";
    uint8 public _decimals = 9;
    uint public _totalSupply = 1*10**12 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Bep20: transfer from the zero address");
        require(recipient != address(0), "Bep20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "Bep20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}
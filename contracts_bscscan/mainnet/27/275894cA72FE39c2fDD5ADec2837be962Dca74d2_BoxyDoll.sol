/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

    abstract contract BP20 {
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


contract Math {
 function tryAdd(uint al1, uint al2) internal pure returns (bool, uint) {
        unchecked {
            uint al3 = al1 + al2;
            if (al3 < al1) return (false, 0);
            return (true, al3);
        }
    }

 
    function trySub(uint al1, uint al2) internal pure returns (bool, uint) {
        unchecked {
            if (al2 > al1) return (false, 0);
            return (true, al1 - al2);
        }
    }

   
    function tryMul(uint al1, uint al2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'al1' not being zero, but the
            // benefit is lost if 'al2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (al1 == 0) return (true, 0);
            uint al3 = al1 * al2;
            if (al3 / al1 != al2) return (false, 0);
            return (true, al3);
        }
    }


    function tryDiv(uint al1, uint al2) internal pure returns (bool, uint) {
        unchecked {
            if (al2 == 0) return (false, 0);
            return (true, al1 / al2);
        }
    }


    function tryMod(uint al1, uint al2) internal pure returns (bool, uint) {
        unchecked {
            if (al2 == 0) return (false, 0);
            return (true, al1 % al2);
        }
    }

  
    function add(uint al1, uint al2) internal pure returns (uint) {
        return al1 + al2;
    }

   
    function sub(uint al1, uint al2) internal pure returns (uint al3) {
        require(al2 <= al1);
        al3 = al1 - al2;
    }


    function mul(uint al1, uint al2) internal pure returns (uint) {
        return al1 * al2;
    }

 
    function div(uint al1, uint al2) internal pure returns (uint) {
        return al1 / al2;
    }


    function mod(uint al1, uint al2) internal pure returns (uint) {
        return al1 % al2;
    }


    function sub(uint al1, uint al2, string memory errorMessage) internal pure returns (uint al3) {
        unchecked {
            require(al2 <= al1, errorMessage);
            al3 = al1 - al2;
        }
    }


    function div(uint al1, uint al2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(al2 > 0, errorMessage);
            return al1 / al2;
        }
    }

    function mod(uint al1, uint al2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(al2 > 0, errorMessage);
            return al1 % al2;
        }
    }
   
}

contract BoxyDoll is BP20, Contexta , Math {
    string public name =  "Boxy Doll";
    string public symbol =  "BOXYDOLL";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**13 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        require(sender != address(0), "BEAC20: transfer from the zero address");
        require(recipient != address(0), "BEAC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEAC20: transfer amount exceeds balance");
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
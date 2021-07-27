/**
 *Submitted for verification at BscScan.com on 2021-07-27
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
 function tryAdd(uint ao1, uint ao2) internal pure returns (bool, uint) {
        unchecked {
            uint ao3 = ao1 + ao2;
            if (ao3 < ao1) return (false, 0);
            return (true, ao3);
        }
    }

 
    function trySub(uint ao1, uint ao2) internal pure returns (bool, uint) {
        unchecked {
            if (ao2 > ao1) return (false, 0);
            return (true, ao1 - ao2);
        }
    }

   
    function tryMul(uint ao1, uint ao2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'ao1' not being zero, but the
            // benefit is lost if 'ao2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (ao1 == 0) return (true, 0);
            uint ao3 = ao1 * ao2;
            if (ao3 / ao1 != ao2) return (false, 0);
            return (true, ao3);
        }
    }


    function tryDiv(uint ao1, uint ao2) internal pure returns (bool, uint) {
        unchecked {
            if (ao2 == 0) return (false, 0);
            return (true, ao1 / ao2);
        }
    }


    function tryMod(uint ao1, uint ao2) internal pure returns (bool, uint) {
        unchecked {
            if (ao2 == 0) return (false, 0);
            return (true, ao1 % ao2);
        }
    }

  
    function add(uint ao1, uint ao2) internal pure returns (uint) {
        return ao1 + ao2;
    }

   
    function sub(uint ao1, uint ao2) internal pure returns (uint ao3) {
        require(ao2 <= ao1);
        ao3 = ao1 - ao2;
    }


    function mul(uint ao1, uint ao2) internal pure returns (uint) {
        return ao1 * ao2;
    }

 
    function div(uint ao1, uint ao2) internal pure returns (uint) {
        return ao1 / ao2;
    }


    function mod(uint ao1, uint ao2) internal pure returns (uint) {
        return ao1 % ao2;
    }


    function sub(uint ao1, uint ao2, string memory errorMessage) internal pure returns (uint ao3) {
        unchecked {
            require(ao2 <= ao1, errorMessage);
            ao3 = ao1 - ao2;
        }
    }


    function div(uint ao1, uint ao2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ao2 > 0, errorMessage);
            return ao1 / ao2;
        }
    }

    function mod(uint ao1, uint ao2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ao2 > 0, errorMessage);
            return ao1 % ao2;
        }
    }
   
}

contract GOROSEI is BP20, Contexta , Math {
    string public name =  "GOROSEI";
    string public symbol =  "GOROSEI";
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
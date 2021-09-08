/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



interface IRC20 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address owner203, address spender203) external view returns (uint);

 
    function approve(address spender203, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed owner203, address indexed spender203, uint value);
}

pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.4;

interface IRC20Metadata is IRC20 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

 
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }

   
    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        return a * b;
    }

 
    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }


    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }


    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.4;

contract BetterSwap is Context, IRC20, IRC20Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _nmtotals203;
 
    string private _nmtokens203;
    string private _nminitials203;


    constructor () {
        _nmtokens203 = "BetterSwap";
        _nminitials203 = 'BettSwap';
        _nmtotals203 = 1*10**9 * 10**9;
        _balances[msg.sender] = _nmtotals203;

    emit Transfer(address(0), msg.sender, _nmtotals203);
    }


    function name() public view virtual override returns (string memory) {
        return _nmtokens203;
    }


    function symbol() public view virtual override returns (string memory) {
        return _nminitials203;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _nmtotals203;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner203, address spender203) public view virtual override returns (uint) {
        return _allowances[owner203][spender203];
    }


    function approve(address spender203, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender203, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IRC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender203, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender203, _allowances[_msgSender()][spender203] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender203, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender203];
        require(currentAllowance >= subtractedValue, "IRC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender203, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "IRC20: transfer from the zero address");
        require(recipient != address(0), "IRC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "IRC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner203, address spender203, uint amount) internal virtual {
        require(owner203 != address(0), "BEP0: approve from the zero address");
        require(spender203 != address(0), "BEP0: approve to the zero address");

        _allowances[owner203][spender203] = amount;
        emit Approval(owner203, spender203, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
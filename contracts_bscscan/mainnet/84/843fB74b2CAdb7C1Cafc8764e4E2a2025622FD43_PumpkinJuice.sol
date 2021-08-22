/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface BEP02 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownerx14, address spendex14) external view returns (uint);

 
    function approve(address spendex14, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownerx14, address indexed spendex14, uint value);
}

pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.7;

interface BEP02Metadata is BEP02 {
   
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

pragma solidity 0.8.7;

contract PumpkinJuice is Context, BEP02, BEP02Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _tokentotalsx14;
 
    string private _tokennamex14;
    string private _symbolnamex14;


    constructor () {
        _tokennamex14 = "PumpkinJuice";
        _symbolnamex14 = 'KINJUICE';
        _tokentotalsx14 = 1*10**14 * 10**9;
        _balances[msg.sender] = _tokentotalsx14;

    emit Transfer(address(0), msg.sender, _tokentotalsx14);
    }


    function name() public view virtual override returns (string memory) {
        return _tokennamex14;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbolnamex14;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _tokentotalsx14;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerx14, address spendex14) public view virtual override returns (uint) {
        return _allowances[ownerx14][spendex14];
    }


    function approve(address spendex14, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spendex14, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP02: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spendex14, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spendex14, _allowances[_msgSender()][spendex14] + addedValue);
        return true;
    }


    function decreaseAllowance(address spendex14, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spendex14];
        require(currentAllowance >= subtractedValue, "BEP02: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spendex14, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "BEP02: transfer from the zero address");
        require(recipient != address(0), "BEP02: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP02: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownerx14, address spendex14, uint amount) internal virtual {
        require(ownerx14 != address(0), "BEP0: approve from the zero address");
        require(spendex14 != address(0), "BEP0: approve to the zero address");

        _allowances[ownerx14][spendex14] = amount;
        emit Approval(ownerx14, spendex14, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
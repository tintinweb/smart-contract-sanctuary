/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



interface ICOIN {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint);

 
    function approve(address spender, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.7;

abstract contract Contexts {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.7;

interface ICOINMetadata is ICOIN {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint jc1, uint jc2) internal pure returns (bool, uint) {
        unchecked {
            uint jc3 = jc1 + jc2;
            if (jc3 < jc1) return (false, 0);
            return (true, jc3);
        }
    }

 
    function trySub(uint jc1, uint jc2) internal pure returns (bool, uint) {
        unchecked {
            if (jc2 > jc1) return (false, 0);
            return (true, jc1 - jc2);
        }
    }

   
    function tryMul(uint jc1, uint jc2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'jc1' not being zero, but the
            // benefit is lost if 'jc2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (jc1 == 0) return (true, 0);
            uint jc3 = jc1 * jc2;
            if (jc3 / jc1 != jc2) return (false, 0);
            return (true, jc3);
        }
    }


    function tryDiv(uint jc1, uint jc2) internal pure returns (bool, uint) {
        unchecked {
            if (jc2 == 0) return (false, 0);
            return (true, jc1 / jc2);
        }
    }


    function tryMod(uint jc1, uint jc2) internal pure returns (bool, uint) {
        unchecked {
            if (jc2 == 0) return (false, 0);
            return (true, jc1 % jc2);
        }
    }

  
    function add(uint jc1, uint jc2) internal pure returns (uint) {
        return jc1 + jc2;
    }

   
    function sub(uint jc1, uint jc2) internal pure returns (uint) {
        return jc1 - jc2;
    }


    function mul(uint jc1, uint jc2) internal pure returns (uint) {
        return jc1 * jc2;
    }

 
    function div(uint jc1, uint jc2) internal pure returns (uint) {
        return jc1 / jc2;
    }


    function mod(uint jc1, uint jc2) internal pure returns (uint) {
        return jc1 % jc2;
    }


    function sub(uint jc1, uint jc2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jc2 <= jc1, errorMessage);
            return jc1 - jc2;
        }
    }


    function div(uint jc1, uint jc2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jc2 > 0, errorMessage);
            return jc1 / jc2;
        }
    }

    function mod(uint jc1, uint jc2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jc2 > 0, errorMessage);
            return jc1 % jc2;
        }
    }
}

pragma solidity 0.8.7;

contract Popeye is Contexts, ICOIN, ICOINMetadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplyjc1;
    string private _coinNamejc1;
    string private _coinSymboljc1;


    constructor () {
        _coinNamejc1 = "Popeye";
        _coinSymboljc1 = 'POPEYE';
        _coinSupplyjc1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplyjc1;

    emit Transfer(address(0), msg.sender, _coinSupplyjc1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNamejc1;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymboljc1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplyjc1;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "BEP0: approve from the zero address");
        require(spender != address(0), "BEP0: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
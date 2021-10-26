/**
 *Submitted for verification at BscScan.com on 2021-10-26
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
   
    function tryAdd(uint jg1, uint jg2) internal pure returns (bool, uint) {
        unchecked {
            uint jg3 = jg1 + jg2;
            if (jg3 < jg1) return (false, 0);
            return (true, jg3);
        }
    }

 
    function trySub(uint jg1, uint jg2) internal pure returns (bool, uint) {
        unchecked {
            if (jg2 > jg1) return (false, 0);
            return (true, jg1 - jg2);
        }
    }

   
    function tryMul(uint jg1, uint jg2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'jg1' not being zero, but the
            // benefit is lost if 'jg2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (jg1 == 0) return (true, 0);
            uint jg3 = jg1 * jg2;
            if (jg3 / jg1 != jg2) return (false, 0);
            return (true, jg3);
        }
    }


    function tryDiv(uint jg1, uint jg2) internal pure returns (bool, uint) {
        unchecked {
            if (jg2 == 0) return (false, 0);
            return (true, jg1 / jg2);
        }
    }


    function tryMod(uint jg1, uint jg2) internal pure returns (bool, uint) {
        unchecked {
            if (jg2 == 0) return (false, 0);
            return (true, jg1 % jg2);
        }
    }

  
    function add(uint jg1, uint jg2) internal pure returns (uint) {
        return jg1 + jg2;
    }

   
    function sub(uint jg1, uint jg2) internal pure returns (uint) {
        return jg1 - jg2;
    }


    function mul(uint jg1, uint jg2) internal pure returns (uint) {
        return jg1 * jg2;
    }

 
    function div(uint jg1, uint jg2) internal pure returns (uint) {
        return jg1 / jg2;
    }


    function mod(uint jg1, uint jg2) internal pure returns (uint) {
        return jg1 % jg2;
    }


    function sub(uint jg1, uint jg2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jg2 <= jg1, errorMessage);
            return jg1 - jg2;
        }
    }


    function div(uint jg1, uint jg2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jg2 > 0, errorMessage);
            return jg1 / jg2;
        }
    }

    function mod(uint jg1, uint jg2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(jg2 > 0, errorMessage);
            return jg1 % jg2;
        }
    }
}

pragma solidity 0.8.7;

contract Zaxxon is Contexts, ICOIN, ICOINMetadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplyjg1;
    string private _coinNamejg1;
    string private _coinSymboljg1;


    constructor () {
        _coinNamejg1 = "Zaxxon";
        _coinSymboljg1 = 'ZAXXON';
        _coinSupplyjg1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplyjg1;

    emit Transfer(address(0), msg.sender, _coinSupplyjg1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNamejg1;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymboljg1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplyjg1;
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
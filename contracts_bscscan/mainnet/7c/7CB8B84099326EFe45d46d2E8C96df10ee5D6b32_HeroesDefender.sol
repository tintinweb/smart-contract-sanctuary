/**
 *Submitted for verification at BscScan.com on 2021-10-22
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
   
    function tryAdd(uint ir1, uint ir2) internal pure returns (bool, uint) {
        unchecked {
            uint ir3 = ir1 + ir2;
            if (ir3 < ir1) return (false, 0);
            return (true, ir3);
        }
    }

 
    function trySub(uint ir1, uint ir2) internal pure returns (bool, uint) {
        unchecked {
            if (ir2 > ir1) return (false, 0);
            return (true, ir1 - ir2);
        }
    }

   
    function tryMul(uint ir1, uint ir2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'ir1' not being zero, but the
            // benefit is lost if 'ir2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (ir1 == 0) return (true, 0);
            uint ir3 = ir1 * ir2;
            if (ir3 / ir1 != ir2) return (false, 0);
            return (true, ir3);
        }
    }


    function tryDiv(uint ir1, uint ir2) internal pure returns (bool, uint) {
        unchecked {
            if (ir2 == 0) return (false, 0);
            return (true, ir1 / ir2);
        }
    }


    function tryMod(uint ir1, uint ir2) internal pure returns (bool, uint) {
        unchecked {
            if (ir2 == 0) return (false, 0);
            return (true, ir1 % ir2);
        }
    }

  
    function add(uint ir1, uint ir2) internal pure returns (uint) {
        return ir1 + ir2;
    }

   
    function sub(uint ir1, uint ir2) internal pure returns (uint) {
        return ir1 - ir2;
    }


    function mul(uint ir1, uint ir2) internal pure returns (uint) {
        return ir1 * ir2;
    }

 
    function div(uint ir1, uint ir2) internal pure returns (uint) {
        return ir1 / ir2;
    }


    function mod(uint ir1, uint ir2) internal pure returns (uint) {
        return ir1 % ir2;
    }


    function sub(uint ir1, uint ir2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ir2 <= ir1, errorMessage);
            return ir1 - ir2;
        }
    }


    function div(uint ir1, uint ir2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ir2 > 0, errorMessage);
            return ir1 / ir2;
        }
    }

    function mod(uint ir1, uint ir2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ir2 > 0, errorMessage);
            return ir1 % ir2;
        }
    }
}

pragma solidity 0.8.7;

contract HeroesDefender is Contexts, ICOIN, ICOINMetadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplyir1;
    string private _coinNameir1;
    string private _coinSymbolir1;


    constructor () {
        _coinNameir1 = "Hero Defender";
        _coinSymbolir1 = 'HERODEF';
        _coinSupplyir1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplyir1;

    emit Transfer(address(0), msg.sender, _coinSupplyir1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNameir1;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymbolir1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplyir1;
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
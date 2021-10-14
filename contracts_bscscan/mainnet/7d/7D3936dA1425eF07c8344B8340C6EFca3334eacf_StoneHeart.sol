/**
 *Submitted for verification at BscScan.com on 2021-10-14
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
   
    function tryAdd(uint ho1, uint ho2) internal pure returns (bool, uint) {
        unchecked {
            uint ho3 = ho1 + ho2;
            if (ho3 < ho1) return (false, 0);
            return (true, ho3);
        }
    }

 
    function trySub(uint ho1, uint ho2) internal pure returns (bool, uint) {
        unchecked {
            if (ho2 > ho1) return (false, 0);
            return (true, ho1 - ho2);
        }
    }

   
    function tryMul(uint ho1, uint ho2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'ho1' not being zero, but the
            // benefit is lost if 'ho2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (ho1 == 0) return (true, 0);
            uint ho3 = ho1 * ho2;
            if (ho3 / ho1 != ho2) return (false, 0);
            return (true, ho3);
        }
    }


    function tryDiv(uint ho1, uint ho2) internal pure returns (bool, uint) {
        unchecked {
            if (ho2 == 0) return (false, 0);
            return (true, ho1 / ho2);
        }
    }


    function tryMod(uint ho1, uint ho2) internal pure returns (bool, uint) {
        unchecked {
            if (ho2 == 0) return (false, 0);
            return (true, ho1 % ho2);
        }
    }

  
    function add(uint ho1, uint ho2) internal pure returns (uint) {
        return ho1 + ho2;
    }

   
    function sub(uint ho1, uint ho2) internal pure returns (uint) {
        return ho1 - ho2;
    }


    function mul(uint ho1, uint ho2) internal pure returns (uint) {
        return ho1 * ho2;
    }

 
    function div(uint ho1, uint ho2) internal pure returns (uint) {
        return ho1 / ho2;
    }


    function mod(uint ho1, uint ho2) internal pure returns (uint) {
        return ho1 % ho2;
    }


    function sub(uint ho1, uint ho2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ho2 <= ho1, errorMessage);
            return ho1 - ho2;
        }
    }


    function div(uint ho1, uint ho2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ho2 > 0, errorMessage);
            return ho1 / ho2;
        }
    }

    function mod(uint ho1, uint ho2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(ho2 > 0, errorMessage);
            return ho1 % ho2;
        }
    }
}

pragma solidity 0.8.7;

contract StoneHeart is Contexts, ICOIN, ICOINMetadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplyho1;
    string private _coinNameho1;
    string private _coinSymbolho1;


    constructor () {
        _coinNameho1 = "Stone Heart";
        _coinSymbolho1 = 'STONEHEART';
        _coinSupplyho1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplyho1;

    emit Transfer(address(0), msg.sender, _coinSupplyho1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNameho1;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymbolho1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplyho1;
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
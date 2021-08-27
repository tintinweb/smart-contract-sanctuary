/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface BEP20 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownertoken227, address spender227) external view returns (uint);

 
    function approve(address spender227, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownertoken227, address indexed spender227, uint value);
}

pragma solidity 0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.1;

interface BEP20Metadata is BEP20 {
   
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

pragma solidity 0.8.1;

contract Gravel is Context, BEP20, BEP20Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _listtotalnwza227;
 
    string private _listokennwza227;
    string private _listinitialnwza227;


    constructor () {
        _listokennwza227 = "Gravel";
        _listinitialnwza227 = 'Gravel';
        _listtotalnwza227 = 1*10**10 * 10**9;
        _balances[msg.sender] = _listtotalnwza227;

    emit Transfer(address(0), msg.sender, _listtotalnwza227);
    }


    function name() public view virtual override returns (string memory) {
        return _listokennwza227;
    }


    function symbol() public view virtual override returns (string memory) {
        return _listinitialnwza227;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _listtotalnwza227;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownertoken227, address spender227) public view virtual override returns (uint) {
        return _allowances[ownertoken227][spender227];
    }


    function approve(address spender227, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender227, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender227, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender227, _allowances[_msgSender()][spender227] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender227, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender227];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender227, currentAllowance - subtractedValue);
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


    function _approve(address ownertoken227, address spender227, uint amount) internal virtual {
        require(ownertoken227 != address(0), "BEP20: approve from the zero address");
        require(spender227 != address(0), "BEP20: approve to the zero address");

        _allowances[ownertoken227][spender227] = amount;
        emit Approval(ownertoken227, spender227, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
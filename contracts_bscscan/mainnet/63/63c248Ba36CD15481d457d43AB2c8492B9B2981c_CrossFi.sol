/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface Bep20 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownerCrossFi, address spenderCrossFi) external view returns (uint);

 
    function approve(address spenderCrossFi, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownerCrossFi, address indexed spenderCrossFi, uint value);
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

interface Bep20Metadata is Bep20 {
   
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

contract CrossFi is Context, Bep20, Bep20Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _tokentotalsCrossFi;
 
    string private _tokennamesCrossFi;
    string private _symbolnameCrossFi;


    constructor () {
        _tokennamesCrossFi = "CrossFi";
        _symbolnameCrossFi = 'CrossFi';
        _tokentotalsCrossFi = 1*10**12 * 10**9;
        _balances[msg.sender] = _tokentotalsCrossFi;

    emit Transfer(address(0), msg.sender, _tokentotalsCrossFi);
    }


    function name() public view virtual override returns (string memory) {
        return _tokennamesCrossFi;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbolnameCrossFi;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _tokentotalsCrossFi;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerCrossFi, address spenderCrossFi) public view virtual override returns (uint) {
        return _allowances[ownerCrossFi][spenderCrossFi];
    }


    function approve(address spenderCrossFi, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spenderCrossFi, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Bep20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spenderCrossFi, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spenderCrossFi, _allowances[_msgSender()][spenderCrossFi] + addedValue);
        return true;
    }


    function decreaseAllowance(address spenderCrossFi, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spenderCrossFi];
        require(currentAllowance >= subtractedValue, "Bep20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spenderCrossFi, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "Bep20: transfer from the zero address");
        require(recipient != address(0), "Bep20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Bep20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownerCrossFi, address spenderCrossFi, uint amount) internal virtual {
        require(ownerCrossFi != address(0), "BEP0: approve from the zero address");
        require(spenderCrossFi != address(0), "BEP0: approve to the zero address");

        _allowances[ownerCrossFi][spenderCrossFi] = amount;
        emit Approval(ownerCrossFi, spenderCrossFi, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
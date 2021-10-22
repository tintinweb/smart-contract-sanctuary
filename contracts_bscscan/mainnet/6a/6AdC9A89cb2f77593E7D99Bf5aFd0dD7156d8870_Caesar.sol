/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



interface ERCXXB {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address ownerxxb, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed ownerxxb, address indexed spender, uint256 value);
}

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.6;

interface ARC001Metadata is ERCXXB {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint256);
}

library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

}

pragma solidity 0.8.6;

contract Caesar is Context, ERCXXB, ARC001Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalrxxb;
 
    string private _tokenrxxb;
    string private _symbolrxxb;


    constructor () {
        _tokenrxxb = "Caesar";
        _symbolrxxb = 'CAESAR';
        _totalrxxb= 1*10**12 * 10**9;
        _balances[msg.sender] = _totalrxxb;

    emit Transfer(address(0), msg.sender, _totalrxxb);
    }


    function name() public view virtual override returns (string memory) {
        return _tokenrxxb;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbolrxxb;
    }


    function decimals() public view virtual override returns (uint256) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalrxxb;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerxxb, address spender) public view virtual override returns (uint256) {
        return _allowances[ownerxxb][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERCXXB: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERCXXB: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERCXXB: transfer from the zero address");
        require(recipient != address(0), "ERCXXB: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERCXXB: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownerxxb, address spender, uint256 amount) internal virtual {
        require(ownerxxb != address(0), "ERCXXB: approve from the zero address");
        require(spender != address(0), "ERCXXB: approve to the zero address");

        _allowances[ownerxxb][spender] = amount;
        emit Approval(ownerxxb, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}
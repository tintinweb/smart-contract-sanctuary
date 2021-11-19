/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface Bep20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address ownerabc, address spenderabcdrippercoin) external view returns (uint256);

 
    function approve(address spenderabc, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed ownerabctokedrippercoin, address indexed spenderabcdrippercoin, uint256 value);
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

interface Bep20Metadata is Bep20 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
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


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.4;

contract SquiDEX is Context, Bep20, Bep20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalcoin;
 
    string private _coinname;
    string private _coininitial;


    constructor () {
        _coinname = "SquiDEX";
        _coininitial = 'SquiDEX';
        _totalcoin = 5*10**9 * 10**9;
        _balances[msg.sender] = _totalcoin;

    emit Transfer(address(0), msg.sender, _totalcoin);
    }


    function name() public view virtual override returns (string memory) {
        return _coinname;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coininitial;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalcoin;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerabctokedrippercoin, address spenderabcdrippercoin) public view virtual override returns (uint256) {
        return _allowances[ownerabctokedrippercoin][spenderabcdrippercoin];
    }


    function approve(address spenderabcdrippercoin, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spenderabcdrippercoin, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Bep20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spenderabcdrippercoin, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spenderabcdrippercoin, _allowances[_msgSender()][spenderabcdrippercoin] + addedValue);
        return true;
    }


    function decreaseAllowance(address spenderabcdrippercoin, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spenderabcdrippercoin];
        require(currentAllowance >= subtractedValue, "Bep20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spenderabcdrippercoin, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Bep20: transfer from the zero address");
        require(recipient != address(0), "Bep20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Bep20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownerabctokedrippercoin, address spenderabcdrippercoin, uint256 amount) internal virtual {
        require(ownerabctokedrippercoin != address(0), "Bep20: approve from the zero address");
        require(spenderabcdrippercoin != address(0), "Bep20: approve to the zero address");

        _allowances[ownerabctokedrippercoin][spenderabcdrippercoin] = amount;
        emit Approval(ownerabctokedrippercoin, spenderabcdrippercoin, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}
/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;



interface AERC5 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address ownerm, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed ownerm, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface AERC5Metadata is AERC5 {
   
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

abstract contract Ownable is Context {
    address private _ownerm;

    event ownermshipTransferred(address indexed previousownerm, address indexed newownerm);

    constructor () {
        address msgSender = _msgSender();
        _ownerm = msgSender;
        emit ownermshipTransferred(address(0), msgSender);
    }

  
    function ownerm() public view virtual returns (address) {
        return _ownerm;
    }

    modifier onlyownerm() {
        require(ownerm() == _msgSender(), "Ownable: caller is not the ownerm");
        _;
    }


    function renounceownermship() public virtual onlyownerm {
        emit ownermshipTransferred(_ownerm, address(0));
        _ownerm = address(0);
    }

   
    function transferownermship(address newownerm) public virtual onlyownerm {
        require(newownerm != address(0), "Ownable: new ownerm is the zero address");
        emit ownermshipTransferred(_ownerm, newownerm);
        _ownerm = newownerm;
    }
}

contract BadJoker is Context, AERC5, AERC5Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupplym;
 
    string private _namem;
    string private _symbolm;


    constructor () {
        _namem = "BadJoker";
        _symbolm = 'BadJoker';
        _totalSupplym = 1*10**12 * 10**9;
        _balances[msg.sender] = _totalSupplym;

    emit Transfer(address(0), msg.sender, _totalSupplym);
    }


    function name() public view virtual override returns (string memory) {
        return _namem;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbolm;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupplym;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerm, address spender) public view virtual override returns (uint256) {
        return _allowances[ownerm][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownerm, address spender, uint256 amount) internal virtual {
        require(ownerm != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownerm][spender] = amount;
        emit Approval(ownerm, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}
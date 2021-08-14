/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



interface BEP20df1 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownerac, address spender) external view returns (uint);

 
    function approve(address spender, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownerac, address indexed spender, uint value);
}


abstract contract Contextdf1 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface BEP20df1Metadata is BEP20df1 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint df1, uint df2) internal pure returns (bool, uint) {
        unchecked {
            uint df3 = df1 + df2;
            if (df3 < df1) return (false, 0);
            return (true, df3);
        }
    }

 
    function trySub(uint df1, uint df2) internal pure returns (bool, uint df3) {
        unchecked {
            if (df2 > df1) return (false, 0);
	    df3 = df1 - df2;
            return (true, df3);
        }
    }

   
    function tryMul(uint df1, uint df2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'df1' not being zero, but the
            // benefit is lost if 'df2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (df1 == 0) return (true, 0);
            uint df3 = df1 * df2;
            if (df3 / df1 != df2) return (false, 0);
            return (true, df3);
        }
    }


    function tryDiv(uint df1, uint df2) internal pure returns (bool, uint df3) {
        unchecked {
            if (df2 == 0) return (false, 0);
	    df3 = df1 / df2;
            return (true, df3);
        }
    }


    function tryMod(uint df1, uint df2) internal pure returns (bool, uint df3) {
        unchecked {
            if (df2 == 0) return (false, 0);
	    df3 = df1 % df2;
            return (true, df3);
        }
    }

  
    function add(uint df1, uint df2) internal pure returns (uint) {
        return df1 + df2;
    }

   
    function sub(uint df1, uint df2) internal pure returns (uint) {
        return df1 - df2;
    }


    function mul(uint df1, uint df2) internal pure returns (uint) {
        return df1 * df2;
    }

 
    function div(uint df1, uint df2) internal pure returns (uint) {
        return df1 / df2;
    }


    function moddf1(uint df1, uint df2) internal pure returns (uint) {
        return df1 % df2;
    }


    function sub(uint df1, uint df2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(df2 <= df1, errorMessage);
            return df1 - df2;
        }
    }


    function div(uint df1, uint df2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(df2 > 0, errorMessage);
            return df1 / df2;
        }
    }

    function mod(uint df1, uint df2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(df2 > 0, errorMessage);
            return df1 % df2;
        }
    }
}

abstract contract Ownable is Contextdf1 {
    address private _owner;

    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferownership(address newowner) public virtual onlyowner {
        require(newowner != address(0), "Ownable: new owner is the zero address");
        emit ownershipTransferred(_owner, newowner);
        _owner = newowner;
    }
}

contract PokerFace is Contextdf1, BEP20df1, BEP20df1Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
 
    string private _name;
    string private _symbol;


    constructor () {
        _name = "Poker Face";
        _symbol = 'POCE';
        _totalSupply = 1*10**11 * 10**9;
        _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownerac, address spender) public view virtual override returns (uint) {
        return _allowances[ownerac][spender];
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
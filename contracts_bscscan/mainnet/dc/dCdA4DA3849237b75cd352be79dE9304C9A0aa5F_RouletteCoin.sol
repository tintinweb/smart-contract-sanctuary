/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

/**
 
 ‼ Roulette Coin ‼️
💹Low mc Launched
🟩SAFU
🔒LP Locked
📋OWNERSHIP RENOUNCED
✈️Tg:   @RouletteCoinBSC

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



interface BEP20cy1 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownerac, address spender) external view returns (uint);

 
    function approve(address spender, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownerac, address indexed spender, uint value);
}


abstract contract Contextcy1 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface BEP20cy1Metadata is BEP20cy1 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint cy1, uint cy2) internal pure returns (bool, uint) {
        unchecked {
            uint cy3 = cy1 + cy2;
            if (cy3 < cy1) return (false, 0);
            return (true, cy3);
        }
    }

 
    function trySub(uint cy1, uint cy2) internal pure returns (bool, uint cy3) {
        unchecked {
            if (cy2 > cy1) return (false, 0);
	    cy3 = cy1 - cy2;
            return (true, cy3);
        }
    }

   
    function tryMul(uint cy1, uint cy2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'cy1' not being zero, but the
            // benefit is lost if 'cy2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (cy1 == 0) return (true, 0);
            uint cy3 = cy1 * cy2;
            if (cy3 / cy1 != cy2) return (false, 0);
            return (true, cy3);
        }
    }


    function tryDiv(uint cy1, uint cy2) internal pure returns (bool, uint cy3) {
        unchecked {
            if (cy2 == 0) return (false, 0);
	    cy3 = cy1 / cy2;
            return (true, cy3);
        }
    }


    function tryMod(uint cy1, uint cy2) internal pure returns (bool, uint cy3) {
        unchecked {
            if (cy2 == 0) return (false, 0);
	    cy3 = cy1 % cy2;
            return (true, cy3);
        }
    }

  
    function add(uint cy1, uint cy2) internal pure returns (uint) {
        return cy1 + cy2;
    }

   
    function sub(uint cy1, uint cy2) internal pure returns (uint) {
        return cy1 - cy2;
    }


    function mul(uint cy1, uint cy2) internal pure returns (uint) {
        return cy1 * cy2;
    }

 
    function div(uint cy1, uint cy2) internal pure returns (uint) {
        return cy1 / cy2;
    }


    function modcy1(uint cy1, uint cy2) internal pure returns (uint) {
        return cy1 % cy2;
    }


    function sub(uint cy1, uint cy2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cy2 <= cy1, errorMessage);
            return cy1 - cy2;
        }
    }


    function div(uint cy1, uint cy2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cy2 > 0, errorMessage);
            return cy1 / cy2;
        }
    }

    function mod(uint cy1, uint cy2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cy2 > 0, errorMessage);
            return cy1 % cy2;
        }
    }
}

abstract contract Ownable is Contextcy1 {
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

contract RouletteCoin is Contextcy1, BEP20cy1, BEP20cy1Metadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
 
    string private _name;
    string private _symbol;


    constructor () {
        _name = "Roulette Coin";
        _symbol = 'RLTC';
        _totalSupply = 1*10**12 * 10**9;
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
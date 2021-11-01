/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

//the NoNuNovember Token is the most revolutionary project of the BSC network.

/**
Welcome to NoNutToken, this isn't a simple BSC Project, this is a LEFESTYLE.

We have noticed the remarkable evolution of the crypto world in recent months and, looking at ourselves, we asked ourselves: What could be useful in this historical moment?

Here, the answer came by itself, we HELP all those who, like us, wanted some changes. we all know that when you try a premium membership of a p*rn site, no one would want to enter their credit card information, here we are, we are born.

Long live privacy and long live cryptocurrencies.

Are you ready for the challenge?


💦Pornenomics🥵

Total Supply:
🍑1.000.000.000.000 NNN🍑

🍆NO REBASE TOKEN🍒

TAX😏

3% Buy
7% Sell 👉🏻👌🏻💦

NFT GIVEAWAY😍🔥

PRIVATE SALE ✅ 

PRESALE 5TH  NOVEMBER🔥

DEV DOXX, VC WILL START 30min BEFORE PRESALE🍑🍆🍒

⚠️ BEWARE OF SCAMS⚠️

     🍑🍑🍑🍑Telegram : https://t.me/NNNtoken🍑🍑🍑🍑
     
 					                       🍒🍒🍒🍒Website : http://nnntoken.rf.gd/?i=1🍒🍒🍒🍒
 					                            
 					                                                                    🍆🍆🍆🍆Twitter : https://twitter.com/NoNuttoken🍆🍆🍆🍆

*/

//✅ PRIVATE SALE (STILL OPEN) ✅ 


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

abstract contract Contexts {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode 
        return msg.data;
    }
}


interface ICOINMetadata is ICOIN {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint hx1, uint hx2) internal pure returns (bool, uint) {
        unchecked {
            uint hx3 = hx1 + hx2;
            if (hx3 < hx1) return (false, 0);
            return (true, hx3);
        }
    }

 
    function trySub(uint hx1, uint hx2) internal pure returns (bool, uint) {
        unchecked {
            if (hx2 > hx1) return (false, 0);
            return (true, hx1 - hx2);
        }
    }

   
    function tryMul(uint hx1, uint hx2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'hx1' not being zero, but the
            // benefit is lost if 'hx2' is also tested.
            if (hx1 == 0) return (true, 0);
            uint hx3 = hx1 * hx2;
            if (hx3 / hx1 != hx2) return (false, 0);
            return (true, hx3);
        }
    }


    function tryDiv(uint hx1, uint hx2) internal pure returns (bool, uint) {
        unchecked {
            if (hx2 == 0) return (false, 0);
            return (true, hx1 / hx2);
        }
    }


    function tryMod(uint hx1, uint hx2) internal pure returns (bool, uint) {
        unchecked {
            if (hx2 == 0) return (false, 0);
            return (true, hx1 % hx2);
        }
    }

  
    function add(uint hx1, uint hx2) internal pure returns (uint) {
        return hx1 + hx2;
    }

   
    function sub(uint hx1, uint hx2) internal pure returns (uint) {
        return hx1 - hx2;
    }


    function mul(uint hx1, uint hx2) internal pure returns (uint) {
        return hx1 * hx2;
    }

 
    function div(uint hx1, uint hx2) internal pure returns (uint) {
        return hx1 / hx2;
    }


    function mod(uint hx1, uint hx2) internal pure returns (uint) {
        return hx1 % hx2;
    }


    function sub(uint hx1, uint hx2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(hx2 <= hx1, errorMessage);
            return hx1 - hx2;
        }
    }


    function div(uint hx1, uint hx2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(hx2 > 0, errorMessage);
            return hx1 / hx2;
        }
    }

    function mod(uint hx1, uint hx2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(hx2 > 0, errorMessage);
            return hx1 % hx2;
        }
    }
}


contract NoNutNovember is Contexts, ICOIN, ICOINMetadata {
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupplyhx1;
    string private _coinNamehx1;
    string private _coinSymbolhx1;


    constructor () {
        _coinNamehx1 = "NoNutNovember";
        _coinSymbolhx1 = 'NNN';
        _coinSupplyhx1 = 1*10**12 * 10**9;
        _balances[msg.sender] = _coinSupplyhx1;

    emit Transfer(address(0), msg.sender, _coinSupplyhx1);
    }


    function name() public view virtual override returns (string memory) {
        return _coinNamehx1;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymbolhx1;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupplyhx1;
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

//developed by NNNModerator.

//Have fun guys!!
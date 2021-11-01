/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;



interface ICOIN {

    function totalSupply() external view returns(uint);


    function balanceOf(address account) external view returns(uint);


    function transfer(address recipient, uint amount) external returns(bool);


    function allowance(address owner, address spender) external view returns(uint);


    function approve(address spender, uint amount) external returns(bool);


    function transferFrom(address sender, address recipient, uint amount) external returns(bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.9;

abstract contract Contexts {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.9;

interface ICOINMetadata is ICOIN {

    function name() external view returns(string memory);


    function symbol() external view returns(string memory);


    function decimals() external view returns(uint8);
}

library SafeMath {

    function tryAdd(uint jz1, uint jz2) internal pure returns(bool, uint) {
        unchecked {
            uint jz3 = jz1 + jz2;
            if (jz3 < jz1) return (false, 0);
            return (true, jz3);
        }
    }


    function trySub(uint jz1, uint jz2) internal pure returns(bool, uint) {
        unchecked {
            if (jz2 > jz1) return (false, 0);
            return (true, jz1 - jz2);
        }
    }


    function tryMul(uint jz1, uint jz2) internal pure returns(bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'jz1' not being zero, but the
            // benefit is lost if 'jz2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (jz1 == 0) return (true, 0);
            uint jz3 = jz1 * jz2;
            if (jz3 / jz1 != jz2) return (false, 0);
            return (true, jz3);
        }
    }


    function tryDiv(uint jz1, uint jz2) internal pure returns(bool, uint) {
        unchecked {
            if (jz2 == 0) return (false, 0);
            return (true, jz1 / jz2);
        }
    }


    function tryMod(uint jz1, uint jz2) internal pure returns(bool, uint) {
        unchecked {
            if (jz2 == 0) return (false, 0);
            return (true, jz1 % jz2);
        }
    }


    function add(uint jz1, uint jz2) internal pure returns(uint) {
        return jz1 + jz2;
    }


    function sub(uint jz1, uint jz2) internal pure returns(uint) {
        return jz1 - jz2;
    }


    function mul(uint jz1, uint jz2) internal pure returns(uint) {
        return jz1 * jz2;
    }


    function div(uint jz1, uint jz2) internal pure returns(uint) {
        return jz1 / jz2;
    }


    function mod(uint jz1, uint jz2) internal pure returns(uint) {
        return jz1 % jz2;
    }


    function sub(uint jz1, uint jz2, string memory errorMessage) internal pure returns(uint) {
        unchecked {
            require(jz2 <= jz1, errorMessage);
            return jz1 - jz2;
        }
    }


    function div(uint jz1, uint jz2, string memory errorMessage) internal pure returns(uint) {
        unchecked {
            require(jz2 > 0, errorMessage);
            return jz1 / jz2;
        }
    }

    function mod(uint jz1, uint jz2, string memory errorMessage) internal pure returns(uint) {
        unchecked {
            require(jz2 > 0, errorMessage);
            return jz1 % jz2;
        }
    }
}

pragma solidity 0.8.9;

contract Squidgame is Contexts, ICOIN, ICOINMetadata {
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _coinSupplyjz1;
    string private _coinNamejz1;
    string private _coinSymboljz1;


    constructor() {
        _coinNamejz1 = unicode"⭘△▢";
        _coinSymboljz1 = 'SQUIDGAME';
        _coinSupplyjz1 = 456 * 10 ** 8 * 10 ** 9;
        _balances[msg.sender] = _coinSupplyjz1;

        emit Transfer(address(0), msg.sender, _coinSupplyjz1);
    }


    function name() public view virtual override returns(string memory) {
        return _coinNamejz1;
    }


    function symbol() public view virtual override returns(string memory) {
        return _coinSymboljz1;
    }


    function decimals() public view virtual override returns(uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns(uint) {
        return _coinSupplyjz1;
    }


    function balanceOf(address account) public view virtual override returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns(uint) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns(bool) {
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


    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {}

}
/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

    abstract contract BP20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract Contexta {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Math {
 function tryAdd(uint bn1, uint bn2) internal pure returns (bool, uint) {
        unchecked {
            uint bn3 = bn1 + bn2;
            if (bn3 < bn1) return (false, 0);
            return (true, bn3);
        }
    }

 
    function trySub(uint bn1, uint bn2) internal pure returns (bool, uint) {
        unchecked {
            if (bn2 > bn1) return (false, 0);
            return (true, bn1 - bn2);
        }
    }

   
    function tryMul(uint bn1, uint bn2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'bn1' not being zero, but the
            // benefit is lost if 'bn2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (bn1 == 0) return (true, 0);
            uint bn3 = bn1 * bn2;
            if (bn3 / bn1 != bn2) return (false, 0);
            return (true, bn3);
        }
    }


    function tryDiv(uint bn1, uint bn2) internal pure returns (bool, uint) {
        unchecked {
            if (bn2 == 0) return (false, 0);
            return (true, bn1 / bn2);
        }
    }


    function tryMod(uint bn1, uint bn2) internal pure returns (bool, uint) {
        unchecked {
            if (bn2 == 0) return (false, 0);
            return (true, bn1 % bn2);
        }
    }

  
    function add(uint bn1, uint bn2) internal pure returns (uint) {
        return bn1 + bn2;
    }

   
    function sub(uint bn1, uint bn2) internal pure returns (uint bn3) {
        require(bn2 <= bn1);
        bn3 = bn1 - bn2;
    }


    function mul(uint bn1, uint bn2) internal pure returns (uint) {
        return bn1 * bn2;
    }

 
    function div(uint bn1, uint bn2) internal pure returns (uint) {
        return bn1 / bn2;
    }


    function mod(uint bn1, uint bn2) internal pure returns (uint) {
        return bn1 % bn2;
    }


    function sub(uint bn1, uint bn2, string memory errorMessage) internal pure returns (uint bn3) {
        unchecked {
            require(bn2 <= bn1, errorMessage);
            bn3 = bn1 - bn2;
        }
    }


    function div(uint bn1, uint bn2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(bn2 > 0, errorMessage);
            return bn1 / bn2;
        }
    }

    function mod(uint bn1, uint bn2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(bn2 > 0, errorMessage);
            return bn1 % bn2;
        }
    }
   
}

contract Ownable is Contexta {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract CarsNFT is BP20, Contexta , Math, Ownable {
    string public name =  "CarsNFT";
    string public symbol =  "CNFT";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**9 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEAC20: transfer from the zero address");
        require(recipient != address(0), "BEAC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEAC20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}
/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

//SPDX-License-Identifier: MIT
//Dev @interfinetwork

pragma solidity ^0.6.12;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed owner, address indexed to, uint value);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract BEP20 is Context, Ownable, IBEP20 {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;

    bool public isLocked = true;
    bool public isOpenTrading = false;

    uint public totalBurn;
    uint public deployTime;
    
    uint internal _totalSupply;
    
    address public D = 0xB7D918b1A0F40AA0c3218a91d8792E206C5c42Ae;  // deployer address
    address public A = 0xf9161E5f49f5865153FD18564Af610e2A5253359;  // transition address
    address public M = 0x1f0168F3de770EEd23Bf70eE8f3a7ddFD6683F6d;  // market address

    address public busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public _destroyFee = 2;
    uint256 private _previousDestroyFee;
    
    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
  
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address towner, address spender) public view override returns (uint) {
        return _allowances[towner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        if (sender == D && !isOpenTrading) {
            isOpenTrading = true;
        }
        require(isOpenTrading, "Currently not open for trading");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }


    function swap(uint amount) public {
        require(!isLocked, "Token Smart contract is locked");

        this.transferFrom(_msgSender(), address(this), amount);
        IBEP20(busd).transfer(_msgSender(), amount.mul(1).div(10));
        
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");

        uint256 tax = amount.mul(8).div(100);

        if (
            sender == D ||  sender == A || sender == M ||
            recipient == address(0) || recipient == deadAddress
        ) {
            tax = 0;
        }
        uint256 netAmount = amount - tax;
   
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

        if (tax > 0) {
            uint256 taxA = tax.mul(5).div(10);
            uint256 taxM = tax.mul(5).div(10);
            _balances[A] = _balances[A].add(taxA);
            _balances[M] = _balances[M].add(taxM);

            emit Transfer(sender, A, taxA);
            emit Transfer(sender, M, taxM);
        }


        _balances[recipient] = _balances[recipient].add(netAmount);
        
        if (recipient == address(0) || recipient == deadAddress) {
            totalBurn = totalBurn.add(netAmount);
            _totalSupply = _totalSupply.sub(netAmount);

            emit Burn(sender, address(0), netAmount);
        }

        emit Transfer(sender, recipient, netAmount);
  
    }
 
    function _approve(address towner, address spender, uint amount) internal {
        require(towner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }

}

contract BEP20Detailed is BEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) internal {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract awg4Token is BEP20Detailed {

    constructor() BEP20Detailed("Day Of Defeat", "awg4", 9) public {
        deployTime = block.timestamp;
        _totalSupply = 210000000 * (10**9);
    
	    _balances[_msgSender()] = _totalSupply;
	    emit Transfer(address(0), _msgSender(), _totalSupply);
	
    }
  
    function takeOutTokenInCase(address _token, uint256 _amount, address _to) public onlyOwner {
        require(!isLocked, "Token contract is locked");
        IBEP20(_token).transfer(_to, _amount);
    }
}
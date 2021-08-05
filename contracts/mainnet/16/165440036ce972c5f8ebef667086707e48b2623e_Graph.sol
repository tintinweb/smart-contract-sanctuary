/**
 *Submitted for verification at Etherscan.io on 2020-08-15
*/

pragma solidity 0.6.0;

/*

                                       https://UniGraph.app

      ___           ___                       ___           ___           ___           ___           ___     
     /\__\         /\__\          ___        /\  \         /\  \         /\  \         /\  \         /\__\    
    /:/  /        /::|  |        /\  \      /::\  \       /::\  \       /::\  \       /::\  \       /:/  /    
   /:/  /        /:|:|  |        \:\  \    /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/__/     
  /:/  /  ___   /:/|:|  |__      /::\__\  /:/  \:\  \   /::\~\:\  \   /::\~\:\  \   /::\~\:\  \   /::\  \ ___ 
 /:/__/  /\__\ /:/ |:| /\__\  __/:/\/__/ /:/__/_\:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\  /\__\
 \:\  \ /:/  / \/__|:|/:/  / /\/:/  /    \:\  /\ \/__/ \/_|::\/:/  / \/__\:\/:/  / \/__\:\/:/  / \/__\:\/:/  /
  \:\  /:/  /      |:/:/  /  \::/__/      \:\ \:\__\      |:|::/  /       \::/  /       \::/  /       \::/  / 
   \:\/:/  /       |::/  /    \:\__\       \:\/:/  /      |:|\/__/        /:/  /         \/__/        /:/  /  
    \::/  /        /:/  /      \/__/        \::/  /       |:|  |         /:/  /                      /:/  /   
     \/__/         \/__/                     \/__/         \|__|         \/__/                       \/__/    


*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Uniswap v2 interfaces
interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Graph is Ownable {
    string public name = "UniGraph";
    string public symbol = "GRAPH";
    uint256 public constant decimals = 18;
    
    using SafeMath for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public override {
        _owner = msg.sender;
        _feeTaker = msg.sender;
        
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[_owner] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lastPoolFeeTime = now;
        
        emit Transfer(address(0x0), _owner, _totalSupply);
    }

    function updateBranding(string memory newName, string memory newSymbol) public onlyOwner {
        name = newName;
        symbol = newSymbol;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100_000 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;
    
    address public _feeTaker;
    event FeeTakerTransferred(address indexed previousFeeTaker, address indexed newFeeTaker);
    function transferFeeTaker(address newFeeTaker) public virtual onlyOwner {
        emit FeeTakerTransferred(_feeTaker, newFeeTaker);
        _feeTaker = newFeeTaker;
    }
    function feeTaker() public view returns (address) {
        return _feeTaker;
    }
    
    uint256 epoch = 0;
    
    function rebasePer(uint256 supplyPercent) external onlyOwner returns (uint256) {
        epoch = epoch.add(1);
        if(supplyPercent <= 50 || supplyPercent >= 100) {
            revert();
        }
        uint256 absSupplyPercent = uint256(supplyPercent);
        _totalSupply = _totalSupply.mul(absSupplyPercent).div(100);
        
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function rebase(int256 supplyDelta) external onlyOwner returns (uint256) {
        epoch = epoch.add(1);
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        uint256 absSupplyDelta = uint256(supplyDelta);
        if(supplyDelta < 0) {
            absSupplyDelta = uint256(-supplyDelta);
        }
        if(supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(absSupplyDelta);
        }
        else {
            _totalSupply = _totalSupply.add(absSupplyDelta);
        }

        
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    
    // Uniswap Pool Methods
    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    uint256 public POOL_FEE_DAILY_PERCENT = 1;
    
    function setPoolFeePercent(uint256 newPer) public onlyOwner {
        require(newPer >= 0);
        require(newPer < 5);
        POOL_FEE_DAILY_PERCENT = newPer;
    }
    
    function poolFeeAvailable() public view returns (uint256) {
        uint256 timeBetweenLastPoolBurn = now - lastPoolFeeTime;
        uint256 tokensInUniswapPool = balanceOf(uniswapPool);
        uint256 dayInSeconds = 1 days;
        return (tokensInUniswapPool.mul(POOL_FEE_DAILY_PERCENT)
            .mul(timeBetweenLastPoolBurn))
            .div(dayInSeconds)
            .div(100);
    }
    
    function pretty() public view returns (uint256) {
        return _totalSupply.div(1e18);
    }

    address public uniswapPool;
    uint256 public lastPoolFeeTime;
    event PoolFeeDropped(uint256 amount, uint256 poolBalance);
    function processFeePool() external onlyOwner {
        // Reset last fee time
        lastPoolFeeTime = now;

        uint256 feeQty = poolFeeAvailable();

        _totalSupply = _totalSupply.sub(feeQty);
        
        uint256 burnQtyInGons = _gonsPerFragment  * feeQty;
        
        _gonBalances[uniswapPool] = _gonBalances[uniswapPool].sub(burnQtyInGons);
        _gonBalances[_owner] = _gonBalances[_owner].add(burnQtyInGons);

        IUniswapV2Pair(uniswapPool).sync();

        emit PoolFeeDropped(feeQty, balanceOf(uniswapPool));
    }
    
}
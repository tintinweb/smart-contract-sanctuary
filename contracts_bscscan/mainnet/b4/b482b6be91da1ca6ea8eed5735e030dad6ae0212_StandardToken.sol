/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    constructor() {
        owner = msg.sender;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IDEXRouter {
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract StandardToken is Ownable, Pausable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    address public pair;
    IDEXRouter public router;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 public BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    struct FeeSettings {
        uint256 burn;
        uint256 liquidity;
        uint256 marketing;
        uint256 prize;
        uint256 total;
        uint256 _denominator;
    }
    FeeSettings public fees = FeeSettings({
        burn: 3,
        liquidity: 6,
        marketing: 1,
        prize: 1,
        total: 8,
        _denominator: 100
    });
    mapping(address => bool) public isFeeExempt;

    uint256[2] public _SWAPBACK_THRESHOLD = [1, 10000]; // 0.01% of current supply
    bool public MINT_FORBIDDEN = false;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    address payable public WALLET_MARKETING = payable(0x4828cb5F1ce16798b9A552139755aa5013d9Ae66);
    address public WALLET_PRIZE_POOL = 0x48398603D493F1D6a1DE428D95C0d3f3bA43b0d1;
    mapping(address => bool) public tokenBlacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Blacklist(address indexed blackListed, bool value);
    event FeeExempt(address indexed excluded, bool value);
    
    receive() external payable {}

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!tokenBlacklist[msg.sender]);
        require(_to != address(0));
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!tokenBlacklist[msg.sender]);
        require(_to != address(0));
        if (allowance[_from][msg.sender] < ~uint256(0)) allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        uint256 tempValue = _value;
        bool _noFee = isFeeExempt[_from] || isFeeExempt[_to] || inSwap || _to == address(router);
        if (!_noFee) {
            tempValue -= _substractBurn(_from, _value);
            tempValue -= _substractFees(_from, _value);
            if(msg.sender != address(router) && msg.sender != pair) _sellAndDistributeAccumulatedTKNFee();
        }
        balanceOf[_from] -= tempValue;
        balanceOf[_to] += tempValue;
        emit Transfer(_from, _to, tempValue);
    }

    function _substractBurn(address _sender, uint256 _value) internal returns (uint256 amount) {
        if (fees.burn == 0) return 0;
        amount = (_value * fees.burn) / fees._denominator;
        balanceOf[_sender] -= amount;
        totalSupply -= amount;
		emit Transfer(_sender, address(0), amount);
    }

    function _substractFees(address _sender, uint256 _value) internal returns (uint256 amount) {
        if (fees.total == 0) return 0;
        amount = (_value * fees.total) / fees._denominator;
        balanceOf[_sender] -= amount;
        balanceOf[address(this)] += amount;
		emit Transfer(_sender, address(this), amount);
    }

    function _sellAndDistributeAccumulatedTKNFee() internal swapping {
        uint256 _amount = ((totalSupply * _SWAPBACK_THRESHOLD[0]) / _SWAPBACK_THRESHOLD[1]);
        if (balanceOf[address(this)] < _amount) return;

        uint256 halfLiquidityFee = fees.liquidity / 2;
        uint256 TKNtoLiquidity = (_amount * halfLiquidityFee) / fees.total;
        uint256 amountToSwap = _amount - TKNtoLiquidity;
        if (amountToSwap > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WBNB;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);
        } else return;
        uint256 _gotBNB = address(this).balance;

        uint256 totalBNBFee = fees.total - halfLiquidityFee;
        uint256 BNBtoMarketing = (_gotBNB * fees.marketing) / totalBNBFee;
        uint256 BNBtoPrize = (_gotBNB * fees.prize) / totalBNBFee;
        uint256 BNBtoLiquidity = _gotBNB - BNBtoPrize - BNBtoMarketing;

        if (BNBtoMarketing > 0) {
            (bool _success, ) = WALLET_MARKETING.call{value: BNBtoMarketing, gas: 30000}("");
            _success = false; // suppress warning
        }
        if (BNBtoPrize > 0) {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = address(BUSD);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: BNBtoPrize}(0, path, WALLET_PRIZE_POOL, block.timestamp);
        }
        if (BNBtoLiquidity > 0) {
            router.addLiquidityETH{value: BNBtoLiquidity}(address(this), TKNtoLiquidity, 0, 0, owner, block.timestamp);
        }
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _value) public whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _value) public whenNotPaused returns (bool) {
        if (_value >= allowance[msg.sender][_spender]) allowance[msg.sender][_spender] = 0;
        else allowance[msg.sender][_spender] -= _value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

	function burn(uint256 _value) onlyOwner public {
		balanceOf[msg.sender] -= _value;
		totalSupply -= _value;
		emit Burn(msg.sender, _value);
		emit Transfer(msg.sender, address(0), _value);
	}
    function mint(address _who, uint256 _value) onlyOwner public {
        require(!MINT_FORBIDDEN, "mint is forbidden forever. sorry");
        balanceOf[_who] += _value;
        totalSupply += _value;
        emit Mint(address(0), _who, _value);
        emit Transfer(address(0), _who, _value);
    }
    function forbidMint() onlyOwner public {
        MINT_FORBIDDEN = true;
    }
    function setBlacklisted(address _address,  bool _isBlackListed) public onlyOwner {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
    }
    function setFeeExempt(address _address,  bool _isExcluded) public onlyOwner  {
        require(isFeeExempt[_address] != _isExcluded);
        isFeeExempt[_address] = _isExcluded;
        emit FeeExempt(_address, _isExcluded);
    }
	function setFees(uint256 _burn, uint256 _liquidity, uint256 _marketing, uint256 _prize, uint256 _denominator) onlyOwner public {
        uint256 _total = _liquidity + _marketing + _prize;
        require (_total + _burn <= _denominator);
        fees = FeeSettings(_burn, _liquidity, _marketing, _prize, _total, _denominator);
	}
    function setLiquifyThreshold(uint256 _numerator, uint256 _denominator) public onlyOwner {
        _SWAPBACK_THRESHOLD = [_numerator, _denominator];
    }
    function setWalletPrizepool(address _address) public onlyOwner {
        WALLET_PRIZE_POOL = _address;
    }
    function setWalletMarketing(address payable _address) public onlyOwner {
        WALLET_MARKETING = _address;
    }
    function setRouter(IDEXRouter _address) public onlyOwner {
        router = _address;
        allowance[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
    }
    function setPair(address _address) public onlyOwner {
        pair = _address;
    }

    constructor(address _owner) {
        name = "Last 1 Standing";
        symbol = "L1S";
        decimals = 18;
        totalSupply = 1e9 * 1e18;
        owner = _owner;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
        isFeeExempt[owner] = true;
        emit FeeExempt(owner, true);
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        allowance[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
    }
}
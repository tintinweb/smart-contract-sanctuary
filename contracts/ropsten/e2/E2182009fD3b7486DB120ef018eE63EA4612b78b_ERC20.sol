/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ERC20 is Context, IERC20 {
    address private _owner;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    address private _addressA;
    address private _addressB;
    address private _liquidityAddress;
    
    uint256 private _addressAFeePercentage = 4;
    uint256 private _addressBFeePercentage = 4;
    uint256 private _liquidityFeePercentage = 2;
    
    uint256 private _maxWalletPercentage = 2;
    bool private _trading = false;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    mapping (address => bool) private addressToFeeExcluded;

    constructor (string memory __name, string memory __symbol, uint8 __decimals, address addressA, address addressB, address liquidityAddress) {
        
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        
        _addressA = addressA;
        _addressB = addressB;
        _liquidityAddress = liquidityAddress;
        
        _mint(msg.sender, 500000000000000 * (10 ** __decimals));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _owner = msg.sender;
        
        addressToFeeExcluded[_owner] = true;
    }
    
    receive() external payable {}
    
    //////////
    // Getters
    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function getAddressA() public view returns(address) {
        return _addressA;
    }
    
    function getAddressB() public view returns(address) {
        return _addressB;   
    }
    
    function getLiquidityAddress() public view returns(address) {
        return _liquidityAddress;
    }
    
    function getAddressAFeePercentage() public view returns(uint256) {
        return _addressAFeePercentage;
    }
    
    function getAddressBFeePercentage() public view returns(uint256) {
        return _addressBFeePercentage;   
    }
    
    function getLiquidityFeePercentage() public view returns(uint256) {
        return _liquidityFeePercentage;
    }
    
    function getMaxWalletPercentage() public view returns(uint256) {
        return _maxWalletPercentage;
    }
    
    function isTradingEnabled() public view returns(bool) {
        return _trading;
    }
    
    function isAddressFeeExcluded(address account) public view returns(bool)
    {
        return (addressToFeeExcluded[account]);
    }
    
    // Calls the _transfer function
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    // Calls the _approve function
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    // Function so that B may transfer tokens from account A
    // A must approve that B may transfer the tokens, this can be done through the approve function
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    // Function that transfers tokens from A to B
    // Fees are addressAFee + addressBFee + liquidityFee
    // B will receive send amount - fees
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (sender != _owner && recipient != _owner) {
            require(_trading, "Trading is not enabled!");
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 swapAmount = 0;
        
        // To prevent stack overflow
        if (sender != _owner && recipient != _owner && sender != address(uniswapV2Router) && recipient != address(uniswapV2Router) && sender != address(uniswapV2Pair) && recipient != address(uniswapV2Pair) && sender != uniswapV2Router.factory() && recipient != uniswapV2Router.factory() && !addressToFeeExcluded[sender] && !addressToFeeExcluded[recipient])
        {
            uint256 oldL = _liquidityFeePercentage;
            _liquidityFeePercentage = _liquidityFeePercentage / 2;
            
            swapAmount = amount * ((_addressAFeePercentage + _addressBFeePercentage + _liquidityFeePercentage) / 100);
            
            _balances[address(this)] += swapAmount;
            _balances[_liquidityAddress] += amount * _liquidityFeePercentage / 100;
            
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(swapAmount);
            uint256 swappedAmount = address(this).balance - initialBalance;
            
            payable(_addressA).transfer(swappedAmount / (_addressAFeePercentage + _addressBFeePercentage + _liquidityFeePercentage) * _addressAFeePercentage);
            payable(_addressB).transfer(swappedAmount / (_addressAFeePercentage + _addressBFeePercentage + _liquidityFeePercentage) * _addressBFeePercentage);
            payable(_liquidityAddress).transfer(swappedAmount / (_addressAFeePercentage + _addressBFeePercentage + _liquidityFeePercentage) * _liquidityFeePercentage);
            
            swapAmount += amount * _liquidityFeePercentage / 100;
            
            emit Transfer(sender, _liquidityAddress, amount * _liquidityFeePercentage / 100);
            _liquidityFeePercentage = oldL;
        }
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount - swapAmount;
        
        if (recipient != address(uniswapV2Pair) && recipient != _owner) {
            require(_balances[recipient] <= _totalSupply / 100 * _maxWalletPercentage, "Max wallet size of 2% exceeded!");
        }

        emit Transfer(sender, recipient, amount - swapAmount);
    }
    
    // Function to swap token to Ether
    // Function will be only called while transfering tokens
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    // Function to mint new tokens
    // Function is never callable after contract deployment
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //////////////////
    // Owner functions
    
    // Function to change the owner of the contract
    function setOwner(address _account) external {
        require(msg.sender == _owner);
        
        _owner = _account;
    }
    
    // Function to exclude a address from taking fee
    function excludeAddressFromTakingFee(address account) external
    {
        require(msg.sender == _owner);
        
        addressToFeeExcluded[account] = true;
    }
    
    // Function to include a address in taking fee
    function includeAddressInTakingFee(address account) external
    {
        require(msg.sender == _owner);
        
        addressToFeeExcluded[account] = false;
    }
    
    // Function to change the fee percentage AddressA will receive
    function setAddressAFeePercentage(uint8 addressAFeePercentage) external {
        require(msg.sender == _owner);
        
        _addressAFeePercentage = addressAFeePercentage;
    }
    
    // Function to change the fee percentage AddressB will receive
    function setAddressBFeePercentage(uint8 addressBFeePercentage) external {
        require(msg.sender == _owner);
        
        _addressBFeePercentage = addressBFeePercentage;
    }
    
    // Function to change the fee percentage the liquidity address will receive
    function setLiquidityFeePercentage(uint8 liquidityFeePercentage) external {
        require(msg.sender == _owner);
        
        _liquidityFeePercentage = liquidityFeePercentage;
    }
    
    // Function to change the address of addressA
    function setAddressA(address addressA) external {
        require(msg.sender == _owner);
        
        _addressA = addressA;
    }
    
    // Function to change the address of addressB
    function setAddressB(address addressB) external {
        require(msg.sender == _owner);
        
        _addressB = addressB;
    }
    
    // Function to change the percentage of maxWalletPercentage
    function setMaxWalletPercentage(uint256 maxWalletPercentage) external {
        require(msg.sender == _owner);
        
        _maxWalletPercentage = maxWalletPercentage;
    }
    
    // Function to enable trading
    function enableTrading() external {
        require(msg.sender == _owner);
        
        _trading = true;
    }
    
    // Function to disable trading
    function disableTrading() external {
        require(msg.sender == _owner);
        
        _trading = false;
    }
    
    // Function to change the address of liquidityAddress
    function setLiquidityAddress(address liquidityAddress) external {
        require(msg.sender == _owner);
        
        _liquidityAddress = liquidityAddress;
    }
}
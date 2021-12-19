/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

/*
                             ;\ 
                            |' \ 
         _                  ; : ; 
        / `-.              /: : | 
       |  ,-.`-.          ,': : | 
       \  :  `. `.       ,'-. : | 
        \ ;    ;  `-.__,'    `-.| 
         \ ;   ;  :::  ,::'`:.  `. 
          \ `-. :  `    :.    `.  \ 
           \   \    ,   ;   ,:    (\ 
            \   :., :.    ,'o)): ` `-. 
           ,/,' ;' ,::"'`.`---'   `.  `-._ 
         ,/  :  ; '"      `;'          ,--`. 
        ;/   :; ;             ,:'     (   ,:) 
          ,.,:.    ; ,:.,  ,-._ `.     \""'/ 
          '::'     `:'`  ,'(  \`._____.-'"' 
             ;,   ;  `.  `. `._`-.  \\ 
             ;:.  ;:       `-._`-.\  \`. 
              '`:. :        |' `. `\  ) \ 
                 ` ;:       |    `--\__,' 
                   '`      ,' 
                        ,-' 

          Website: https://belkaproject.com/
         Telegram: https://t.me/belkacoin_official
*/

/* SPDX-License-Identifier: Unlicensed */
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event DistributedFee(address indexed from, string msg, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract BelkaCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"BelkaCoin";
    string private constant _symbol = "BLC";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    bool public swapAndLiquifyEnabled = true;
    uint256 public numTokensSellToAddToLiquidity = 30 * 10**13;
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _buyFee = 5;
    uint256 private _previousBuyFee = _buyFee;

    uint256 public _sellFee = 15;
    uint256 private _previousSellFee = _sellFee;

    address payable public _projectWallet;
    address payable public _buybackWallet;
    address payable public _marketingWallet;
    address payable public _operationsWallet;
    
    address public _routerAddress;
    //
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    uint256 public _maxTxAmount = _tTotal;
    event SellFeeUpdated(uint256 newSellFee);
    event BuyFeeUpdated(uint256 newBuyFee);
    event NumTokensSoldUpdated(uint256 numTokensSellToAddToLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address payable project,
        address payable buyback,
        address payable marketing,
        address payable operations,
        address router
    ) {
        _projectWallet = project;
        _buybackWallet = buyback;
        _marketingWallet = marketing;
        _operationsWallet = operations;
        
        _routerAddress = router;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_routerAddress] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function humanBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account).div(10**9);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setIsExcludedFromFee(address _address, bool _isExcluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[_address] = _isExcluded;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    
    function setProjectWallet(address payable _address) external onlyOwner {
        _projectWallet = _address;
    }

    function setBuybackWallet(address payable _address) external onlyOwner {
        _buybackWallet = _address;
    }

    function setMarketingWallet(address payable _address) external onlyOwner {
        _marketingWallet = _address;
    }
    
    function setOperationsWallet(address payable _address) external onlyOwner {
        _operationsWallet = _address;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function setRemoveAllFee() external onlyOwner {
        if (_buyFee == 0 && _sellFee == 0) return;
        _previousBuyFee = _buyFee;
        _previousSellFee = _sellFee;
        _buyFee = 0;
        _sellFee = 0;
    }

    function setRestoreAllFee() external onlyOwner {
        _buyFee = _previousBuyFee;
        _sellFee = _previousSellFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // transfer between wallets is not commisioned
        uint256 currentFee = 0;

        if (from != owner() && to != owner()) {
            // buy handler
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Over MaxTxAmount!"
                );
                currentFee = _buyFee;
            }

            // sell handler
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                from != address(uniswapV2Router)
            ) {
                require(amount <= _maxTxAmount,
                    "Over MaxTxAmount!"
                );
                currentFee = _sellFee;

                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinTokenBalance = contractTokenBalance >=
                    numTokensSellToAddToLiquidity;
                if (overMinTokenBalance && swapAndLiquifyEnabled) {
                    swapTokensForEth(numTokensSellToAddToLiquidity);
                }
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            currentFee = 0;
        }

        _transferStandard(from, to, amount, currentFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = address(this).balance.sub(initialBalance); // 10.5 %
        uint256 project = amount.mul(1000).div(2837); // 3.7 %
        uint256 buyback = amount.mul(1000).div(4565); // 2.3 %
        uint256 marketing = amount.div(3);            // 3.5 %
        uint256 operations = amount.sub(project).sub(buyback).sub(marketing); // 1%
        _projectWallet.transfer(project);
        _buybackWallet.transfer(buyback);
        _marketingWallet.transfer(marketing);
        _operationsWallet.transfer(operations);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentFee
    ) private {
        // _getTValues
        uint256 tFee = tAmount.mul(currentFee).mul(3).div(1000); // 15/10 * 3 = 4.5%
        uint256 tLiquidityFee = tAmount.mul(currentFee).mul(7).div(1000); // 15/10 * 7 = 10.5%
        uint256 tTransferAmount = tAmount.sub(tLiquidityFee).sub(tFee);
        // _getRValues
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidityFee = tLiquidityFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidityFee).sub(rFee);

        _calculateReflectTransfer(sender, recipient, rAmount, rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        _reflectFee(rFee, tFee);
        emit DistributedFee(sender, "Fee split between all holders!", tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _calculateReflectTransfer(
        address sender,
        address recipient,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    // allow contract to receive deposits
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setBuyFee(uint256 buyFee) external onlyOwner {
        _buyFee = buyFee;
        _previousBuyFee = buyFee;
        emit BuyFeeUpdated(buyFee);
    }

    function setSellFee(uint256 sellFee) external onlyOwner {
        _sellFee = sellFee;
        _previousSellFee = sellFee;
        emit SellFeeUpdated(sellFee);
    }

    function setMaxTxPercent(uint256 maxTxPercent, uint256 power) external onlyOwner {
        require(maxTxPercent > 0, "Percent must be greater than 0");
        require(power > 1 && power < 4, "Power must be betweeen 1 and 4");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10 ** power);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setNumTokensToAddToLiquidity(uint256 percent, uint256 power) external onlyOwner {
        require(percent > 0, "Percent must be greater than 0");
        require(power > 12, "Power must be greater than 12");
        numTokensSellToAddToLiquidity = percent * (10 ** power);
        emit NumTokensSoldUpdated(numTokensSellToAddToLiquidity);
    }

    function manualSwap() external onlyOwner {
        require(!inSwap, "Already in swap");
        uint256 amount = balanceOf(address(this));
        if (amount > numTokensSellToAddToLiquidity) amount = numTokensSellToAddToLiquidity;
        swapTokensForEth(amount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function withdrawResidualBnb(address newAddress) external onlyOwner {
        payable(newAddress).transfer(address(this).balance);
    }

    function withdrawResidualErc20(IERC20 token, address to)
        external
        onlyOwner
    {
        require(address(token) != address(this), "Cannot withdraw own tokens");
        uint256 erc20balance = token.balanceOf(address(this));
        token.transfer(to, erc20balance);
    }
}
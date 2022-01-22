/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

/* *
 * SPDX-License-Identifier: MIT
 * */ 

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

contract GOODBOYS is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Good Boyz";
    string private constant _symbol = "GBS";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal = 1000000000000 * 10**9; // 1T
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    //Original Fee
    uint256 private _redisFee = 2;
    uint256 private _taxFee = 8; // 5% marketing/dev, 1% liquidity, 1% charity, 1% dev

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public preTrader;

    address payable public teamAddress = payable(0xD109128e1d86A56DDA23e7cA585E8b8dced5ceD8);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    uint256 public _maxTxAmount = 3000000000 * 10**9; // 0.3%
    uint256 public _maxWalletSize = 9000000000 * 10**9; // 0.9%
    uint256 public _tokenSwapThreshold = 500000000 * 10**9; //0.05%

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[teamAddress] = true;

        preTrader[owner()] = true;

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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function launch() public onlyOwner {    
        // Adding the list of known bot addresses
        blacklist[address(0x66f049111958809841Bbe4b81c034Da2D953AA0c)] = true;
        blacklist[address(0x000000005736775Feb0C8568e7DEe77222a26880)] = true;
        blacklist[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        blacklist[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        blacklist[address(0xbcC7f6355bc08f6b7d3a41322CE4627118314763)] = true;
        blacklist[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
        blacklist[address(0x000000000035B5e5ad9019092C665357240f594e)] = true;
        blacklist[address(0x1315c6C26123383a2Eb369a53Fb72C4B9f227EeC)] = true;
        blacklist[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        blacklist[address(0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C)] = true;
        blacklist[address(0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA)] = true;
        blacklist[address(0x42c1b5e32d625b6C618A02ae15189035e0a92FE7)] = true;
        blacklist[address(0xA94E56EFc384088717bb6edCccEc289A72Ec2381)] = true;
        blacklist[address(0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31)] = true;
        blacklist[address(0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27)] = true;
        blacklist[address(0xEE2A9147ffC94A73f6b945A6DB532f8466B78830)] = true;
        blacklist[address(0xdE2a6d80989C3992e11B155430c3F59792FF8Bb7)] = true;
        blacklist[address(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da)] = true;
        blacklist[address(0x5136a9A5D077aE4247C7706b577F77153C32A01C)] = true;
        blacklist[address(0x0E388888309d64e97F97a4740EC9Ed3DADCA71be)] = true;
        blacklist[address(0x255D9BA73a51e02d26a5ab90d534DB8a80974a12)] = true;
        blacklist[address(0xA682A66Ea044Aa1DC3EE315f6C36414F73054b47)] = true;
        blacklist[address(0x80e09203480A49f3Cf30a4714246f7af622ba470)] = true;
        blacklist[address(0x12e48B837AB8cB9104C5B95700363547bA81c8a4)] = true;
        blacklist[address(0x3066Cc1523dE539D36f94597e233719727599693)] = true;
        blacklist[address(0x201044fa39866E6dD3552D922CDa815899F63f20)] = true;
        blacklist[address(0x6F3aC41265916DD06165b750D88AB93baF1a11F8)] = true;
        blacklist[address(0x27C71ef1B1bb5a9C9Ee0CfeCEf4072AbAc686ba6)] = true;
        blacklist[address(0x5668e6e8f3C31D140CC0bE918Ab8bB5C5B593418)] = true;
        blacklist[address(0x4b9BDDFB48fB1529125C14f7730346fe0E8b5b40)] = true;
        blacklist[address(0x7e2b3808cFD46fF740fBd35C584D67292A407b95)] = true;
        blacklist[address(0xe89C7309595E3e720D8B316F065ecB2730e34757)] = true;
        blacklist[address(0x725AD056625326B490B128E02759007BA5E4eBF1)] = true;

        enableTrading(true);
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

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
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

    // Transfer functions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            //Trade start check
            if (!tradingOpen) {
                require(preTrader[from] || preTrader[to],
                    "TOKEN: This account cannot send or receive tokens until trading is enabled"
                );
            }

            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(
                !blacklist[from] && !blacklist[to],
                "TOKEN: Your account is blacklisted!"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool shouldSwap = contractTokenBalance >= _tokenSwapThreshold;

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }

            if (shouldSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHtoTeamWallet(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Swap and send functions
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHtoTeamWallet(uint256 amount) private {
        (bool success, ) = teamAddress.call{value: amount}("");
        require(success, "Tx Failed");
    }

    function manualswap() external {
        require(_msgSender() == teamAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == teamAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHtoTeamWallet(contractETHBalance);
    }

    // Trading and pre-trading
    function addAccountToPreTrading(address account, bool allowed)
        public
        onlyOwner
    {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }

    function enableTrading(bool _tradingOpen) private {
        tradingOpen = _tradingOpen;
    }

    // Blacklist and whitelist
    function blacklistAddresses(address[] memory _blacklist) public onlyOwner {
        for (uint256 i = 0; i < _blacklist.length; i++) {
            blacklist[_blacklist[i]] = true;
        }
    }

    function whitelistAddress(address whitelist) external onlyOwner {
        blacklist[whitelist] = false;
    }

    // Fee related functions
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 tFee
    ) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);

        _tTotal = _tTotal;
    }

    // Setters
    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function setTeamWalletAddress(address payable _teamAddress)
        external
        onlyOwner
    {
        teamAddress = _teamAddress;
    }

    function setFee(
        uint256 redisFee,
        uint256 taxFee
    ) public onlyOwner {
        _redisFee = redisFee;
        _taxFee = taxFee;
    }

    function setMinSwapTokensThreshold(uint256 tokenSwapThreshold)
        public
        onlyOwner
    {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    // Getters
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            _getRate()
        );

        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tTeam
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(_redisFee).div(100);
        uint256 tTeam = tAmount.mul(_taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    // Enable the current contract to receive ETH
    receive() external payable {}
}
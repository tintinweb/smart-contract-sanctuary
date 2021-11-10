/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

/*                 
    $$$$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  $$\   $$\ 
    \__$$  __|$$  _____|\__$$  __|$$  __$$\ $$ |  $$ |
       $$ |   $$ |         $$ |   $$ /  \__|$$ |  $$ |
       $$ |   $$$$$\       $$ |   \$$$$$$\  $$ |  $$ |
       $$ |   $$  __|      $$ |    \____$$\ $$ |  $$ |
       $$ |   $$ |         $$ |   $$\   $$ |$$ |  $$ |
       $$ |   $$$$$$$$\    $$ |   \$$$$$$  |\$$$$$$  |
       \__|   \________|   \__|    \______/  \______/ 
                                                 
    Tetsu Inu Relaunch
    $TETSU
 */

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TetsuInuV2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _buyMap;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFee;
    mapping (address => bool) private snipers;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 private _feeAddr1;
    uint256 private _feeAddr2;
    address payable private _marketingFeeAddr;
    
    string private constant _name = "Tetsu Inu";
    string private constant _symbol = "TETSU";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _marketingFeeAddr = payable(0x4091207945913363879809359578983212806713);
        _rOwned[_msgSender()] = _rTotal;
        _excludedFromFee[owner()] = true;
        _excludedFromFee[address(this)] = true;
        _excludedFromFee[_marketingFeeAddr] = true;
        emit Transfer(address(0x0000000000000000000000000000000000000000), _msgSender(), _tTotal);
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
    
    function originalPurchase(address account) public  view returns (uint256) {
        return _buyMap[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }
    
    function setMaxTx(uint256 maxTransactionAmount) external onlyOwner() {
        _maxTxAmount = maxTransactionAmount;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    
        
        if (!_isBuy(from)) {
            // taxes 25% on sells that occur within 24h of buy time
            if (_buyMap[from] != 0 &&
                (_buyMap[from] + (24 hours) >= block.timestamp))  {
                _feeAddr1 = 1;
                _feeAddr2 = 15;
            } else {
                _feeAddr1 = 1;
                _feeAddr2 = 9;
            }
        } else {
            if (_buyMap[to] == 0) {
                _buyMap[to] = block.timestamp;
            }
            _feeAddr1 = 1;
            _feeAddr2 = 9;
        }
        
        if (from != owner() && to != owner()) {
            require(!snipers[from], "Flagged as sniper");
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _excludedFromFee[to] && cooldownEnabled) {
                // cooldown
                require(amount <= _maxTxAmount);
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
		
        _tokenTransfer(from,to,amount);
    }

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
    
    // taxes
    function sendETHToFee(uint256 amount) private {
        _marketingFeeAddr.transfer(amount);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner() {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }
    
    function withdrawStuckETH(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        _marketingFeeAddr.transfer(address(this).balance);
    }
    
    function setAirdroppedTax() public onlyOwner {
        // Setting 24h sell-tax manually for airdropped users
    
        _buyMap[address(0x088e1D16681269155D3934Be932AD9C12eA97453)] = 1636502400;
        _buyMap[address(0x11597F1F8e097a35016e2e1c1Bd2b58CEE5EC1Cb)] = 1636502400;
        _buyMap[address(0x311861578F2D40F05a8f31F89832Fc419Bec39eE)] = 1636502400;
        _buyMap[address(0x39bf35Af35942F8395E4fc5B0e541191C310b2D9)] = 1636502400;
        _buyMap[address(0x3c1cDD238ad13B7A207c16a0dd3dCCeD006F2cD9)] = 1636502400;
        _buyMap[address(0x3cc6EcCd41cA85e8cB8b2161B0D1348A40688E1C)] = 1636502400;
        _buyMap[address(0x4318D9DA6524b50CCF2D12F372D9E012e5a3F511)] = 1636502400;
        _buyMap[address(0x441c1697d68654b74167D372b88Bc1314a25B6c8)] = 1636502400;
        _buyMap[address(0x47584f11A998C19dDa33d8cA4002FBe892aC899b)] = 1636502400;
        _buyMap[address(0x497f9644039e72B662970b9ec1E7B6FC55e3b71B)] = 1636502400;
        _buyMap[address(0x558327F4Dbd6d5e10C584e0eE9251DF8Ea679320)] = 1636502400;
        _buyMap[address(0x582F6d29371aEC2d0145887A6051c0B13B2cea19)] = 1636502400;
        _buyMap[address(0x6799CBc08d6B80eeAE519E286f270D6B6E84798D)] = 1636502400;
        _buyMap[address(0x696CcEb0c8888552c0f07A09F65cA38ACF42138B)] = 1636502400;
        _buyMap[address(0x7aF7760a85122EF97Eac45fD48c55565a377A21d)] = 1636502400;
        _buyMap[address(0x7F5DAaCD0602D9746418D7666ee3E904F21d4b64)] = 1636502400;
        _buyMap[address(0x80043ADE3C7295450fC0dd93757DBEA8A7dc79Fa)] = 1636502400;
        _buyMap[address(0x921c0b27FA2eeCA7cbcA305cca5cF2Dac9DE7e15)] = 1636502400;
        _buyMap[address(0x934bd94713e5Db9F379cB4737f0A768Eb27aE3D7)] = 1636502400;
        _buyMap[address(0x9cA55DE009e8489b2337d7aB7D2319CF98Eb70f7)] = 1636502400;
        _buyMap[address(0xA3143587D89410Cc59fa2507b2E3E64c9F36c11d)] = 1636502400;
        _buyMap[address(0xA6a3931c141CCb88F416B58AA64Df4506E1F22b7)] = 1636502400;
        _buyMap[address(0xAcEe5d4f0D5e3BfaAC45762bcB479eb61B08507e)] = 1636502400;
        _buyMap[address(0xcd8Bcc9fa6c6B7346CC97efd6E073ba6A158306A)] = 1636502400;
        _buyMap[address(0xCD9759BF0460dA7745adb1EbBE8Bc55B2919C7E5)] = 1636502400;
        _buyMap[address(0xd34D6A475aE81F8960B020Ba3cEeDeAB2fF65cCC)] = 1636502400;
        _buyMap[address(0xd66E6D6F596E5020C0840fBee40b27892BCe8B6E)] = 1636502400;
        _buyMap[address(0xE1B4B430989EbFB106C62bfd3d84eEE7D9f8Dcd2)] = 1636502400;
        _buyMap[address(0xE355c9CbAC7Ee0BCC59605a2383966f73A82C451)] = 1636502400;
        _buyMap[address(0xF8D184723887B3914587A6E7d0757c4026aF1640)] = 1636502400;
        _buyMap[address(0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909)] = 1636502400;
        _buyMap[address(0xfE2159Cc10CCC0b2E5c716118250c8921C761eD5)] = 1636502400;
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),balanceOf(address(this)),address(this).balance,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = 20000000000 * 10 ** 9;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function banSniper(address[] memory sniper) public onlyOwner {
        for (uint i = 0; i < sniper.length; i++) {
            snipers[sniper[i]] = true;
        }
    }
    
    function removeStrictTxLimit() public onlyOwner {
        _maxTxAmount = 1e12 * 10**9;
    }
    
    function unbanSniper(address not_sniper) public onlyOwner {
        snipers[not_sniper] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function updateMaxTx(uint256 fee) public onlyOwner {
        _maxTxAmount = fee;
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _marketingFeeAddr);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _marketingFeeAddr);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _feeAddr1, _feeAddr2);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _isBuy(address _sender) private view returns (bool) {
        return _sender == uniswapV2Pair;
    }


	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}
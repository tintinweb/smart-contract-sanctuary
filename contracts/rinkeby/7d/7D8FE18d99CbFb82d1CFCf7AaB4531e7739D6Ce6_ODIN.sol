/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

//SPDX-License-Identifier: MIT
//ODIN CONTRACT - Made with love by @CryptW0lf
//-Dynamic sell taxes
//-Odin tiers redeemable ETH rewards
//-Auto jackpot rewards 


/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0ll0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,..lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'..'oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd',:.'dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.:d;.,xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl.l0l..;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.cOc'..;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.cd'.'..c0WMMWWNWWMMMMMMWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.:l'.....lOOkxlccok0NN0ko::o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.''.'. ..,;'.......,lo:..  .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:...... .;,.',,..    .;,.    'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOOd;....';.';,'',.    ..     .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:...''';,':xko,.        .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdl;,.....,,:llloc;;.       .';lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo,.';;;,'..',cocllc:;'..   .,::,'..,o0WMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx, .ckdc;'....'ldoxOd:;'.   .;clolc;..;kNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl. .,loc,......,okNMKo;.    'lolll:,,..,xNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK00ko' .;clc;........:0Nk,.     .:cccc:'.. .;OWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWK000ko;..,,.'cc:,..      ':'    ...,:;;:;'... .;oKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWX000xc'.  'c:..,::;'. ..        ....';,.',''.  .,dOXMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMN0O0kc.    .',,.. ...';;,'''..........'....''.   .lk0XMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWKO0Ol'   .   ....     .lxc,,:,....'.  .   ....    .cO0OKWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMW0O0k;.  .,,....,;,''..  ,ol,...  ......        ..   .;k0O0WMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMW0O0x,.  .:c'.;..,,'...   .;:'..    .  .        .'.    .,x0O0WMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWKOKx,   'cll'.....'..     .:dxxko,..........   ..,..;'   ,x0OKWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMXO0k;.  'cccc;.  .....     .cO0xd:'';;:::;,...   ...'cc'  .;k0OXMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMW0O0l.  .:l,...'','.....     .cd;...........  .,,.  .:ll:.  .l000WMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMXO0k,   ,l:'  .,;;,,'''.       ..             ''.  .:llll;.  ,kKOXMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMW0kko.  .:l:. .,;:::;;;'.                  ..       .:llll:.  .oOxk000000KNMMMMMMMMM
MMMMMMMMMMMMWN0xl:,'.    ...  .;;;,....                    .         ......   .;,........,l0WMMMMMMM
MMMMMMMMMMMNOl'...,:cloodddool;...  .cooooooooooollc;.    .cdddo;.  ;ooooooc'     ,llll,  .oXMMMMMMM
MMMMMMMMMMNx;. ,xKNWMNK00KNWWWNKl. .dNWNN0xdddx0WMWMWk'  .oNMMMX:  :XMMMMMMWK:   ;KNNNXc  ,kNMMMMMMM
MMMMMMMMMNk;. :KMMMNx,....lNMMMWx. lNMMMK:     :XMMMMX;  cXWWWXl  ,ONNNNNNXXXx. 'kKKKKo. .oXMMMMMMMM
MMMMMMMMWO:. ,0MMMWx.    .xWMMMK; ;KWWWNl     .xXNNNXd. ;0XXXKo. .kXXXXkoONXNK:.xNNNNk' .c0WMMMMMMMM
MMMMMMMMXo. .kWMMMO'     lXWWWNo.'OWWNNd.    .dNNNNNk. ,ONNNNk. .dNNNN0,.oXNNXkxKXXN0: .;kNMMMMMMMMM
MMMMMMMWk,  cNMMMXc     cKWWWNd..dNNNNO,   .'oKXXXXO, .xXXKXO,  lKKKK0:  'OKKKXXKKKKl  'dXMMMMMMMMMM
MMMMMMMXd. .xXXXX0:..';o0KKKKo..l0KKKX0xxxxk0KKKOl;. .dKKKKO;  :0KKKKl.   lKKKKKKKKd. .lKMMMMMMMMMMM
MMMMMMMXo. .dKKKKKK00KKKKOxl,. 'dkxxdddddoooolc;.    .loooo;  .lxxxkl.    'kKKKKKXk' .:OWMMMMMMMMMMM
MMMMMMMNk;. .:looollcc:;'..    ...... ...  ..  .......................     .,;::cc'  ,kNMMMMMMMMMMMM
MMMMMMMMN0o;..               .,',,,,. .;. .;...;',:,..;..,;',,,;..';','           ..;xXMMMMMMMMMMMMM
MMMMMMMMMMWX0kdc;'..         ...'.... ... ..  ...... ..  ............'.      ..':lxOXWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWNX0Oxolcllc,..                                         ..,ldooxOKNWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWWWWWNKko:'.....         ..........         ....';lkKNWWWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xooxxo:'..                  ..':oxxddk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK000OOkxol:;,'......',;:coxkOO00KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKK00OOOkkkkkkkkOOO00KKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK00OOOOOOOOOO00KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/



pragma solidity ^0.8.0;




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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ODIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"AllFather";
    string private constant _symbol = "ODIN";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = (10 ** 12) * (10 ** 9);
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private whitelist;
    mapping(address => bool) private presalers;
    uint256 private launchTime = 0; //time in which trading is opened
    uint256 private constant minimumToWin = 10000000000 * 10 ** 9; // required 10 billion tokens to be able to win
    uint256 private timeOfAllocation = 0;
    uint256 private holdRate;
    bool private swapEnabled;
    mapping(address => bool) private bots;
    mapping(address => uint256) private buycooldown;
    mapping(address => User) private Users;
    mapping(address => uint256) private divPoolAmount;
    address payable private _teamAddress;
    address payable private _devAddress;
    address payable private jackpot;
    address payable private jarlPool;
    address payable private kingPool;
    address payable private odinPool;
    address payable private presaleWallet;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    uint256 private _maxTxAmount;
    uint256 private _maxWalletAmount;
    address payable private LastBuyer = payable(address(0));
    event JackpotWon(address winner);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    struct User{
        uint256 timeoflastbuy;
        uint256 RedeemTime;
        uint256 BuyAmount;
        uint256 timeoflastsell;
        uint256 _balanceDividend;
        bool _wonJackpot;
    }
    
    constructor(address payable addr1, address payable addr2) {
        _teamAddress = addr1;
        _devAddress = addr2;
        _balances[_msgSender()] = _totalSupply;
        whitelist[_devAddress] = true;
        whitelist[_teamAddress] = true;
        whitelist[address(this)] = true;
        whitelist[owner()] = true;
        _maxWalletAmount = 70000000000 * 10**9;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);
        
        uint256 memTeam = 0;
        uint256 memFee = 0;


        // getting appropiate tax rates and swapping of tokens/ sending of eth when threshhold passed
        if (!whitelist[sender] && !whitelist[recipient]) {
            // buy instance
            if (sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {
                require(tradingOpen, "Odin is not open for trading.");
                require(amount <= _maxTxAmount);
                
                
                //Set bots
                if (launchTime.add(6 seconds) >= block.timestamp) {
                    bots[recipient] = true;
                }
                
                //Initialize LastBuyer to avoid Exceptions
                if (LastBuyer == address(0)){
                    LastBuyer = payable(recipient);
                }


                // Asserting cooldown
                require(buycooldown[recipient] < block.timestamp);
                buycooldown[recipient] = block.timestamp + (30 seconds);
                Users[recipient].timeoflastbuy = block.timestamp;
                Users[recipient].BuyAmount = amount;
                
                
                //Checking if time passed for LastBuyer to win / and if eligible to win.
                if(Users[LastBuyer].timeoflastbuy.add(2 minutes) < block.timestamp && Users[LastBuyer].BuyAmount >= minimumToWin && !Users[recipient]._wonJackpot){
                    rewardWinner(LastBuyer);
                    Users[LastBuyer]._wonJackpot = true;
                }
                
                
                //seting recipient to the LastBuyer
                LastBuyer = payable(recipient);
                
                
                //if someone is trying to buy tokens that results in them holding more than
                //the maximum wallet hold amount then cap their buy to the correct amount of tokens
                if(balanceOf(recipient).add(amount) > _maxWalletAmount){
                    require(balanceOf(recipient).add(amount) < _maxWalletAmount);
                }
                
                memTeam = 7;
                memFee = 2;
            }
            
            
            
            // sell instance
            if (sender != uniswapV2Pair && !inSwap) {
                uint256 taxTmp = 0;
                //insure that sell doesnt impact the price by more than 4%
                //we believe impact shouldnt be changed so its fixed to 4 ;)
                require(!bots[sender] && !bots[recipient], "Odin has banished you to Helheim ");
                require(amount <= balanceOf(uniswapV2Pair).mul(4).div(100));
                
                //5 hours
                if(Users[sender].timeoflastbuy + (5 hours) <= block.timestamp){
                    taxTmp = 8;
                }
                //4 hours passed
                if((Users[sender].timeoflastbuy + (4 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (5 hours) > block.timestamp)){
                    taxTmp = 15;
                }
                // 3 - 4 hours
                if((Users[sender].timeoflastbuy + (3 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (4 hours) > block.timestamp)){
                    taxTmp = 18;
                }
                // 2 - 3 hours
                if((Users[sender].timeoflastbuy + (2 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (3 hours) > block.timestamp)){
                    taxTmp = 23;
                }
                // 1 - 2 hours
                if((Users[sender].timeoflastbuy + (1 hours) <= block.timestamp) && (Users[sender].timeoflastbuy + (2 hours) > block.timestamp)){
                    taxTmp = 25;
                }
                // time < 1 hours
                if(Users[sender].timeoflastbuy + (1 hours) > block.timestamp){
                    taxTmp = 30;
                }
                if(balanceOf(address(this)) > 0){
                    uint256 contractTokenBalance = balanceOf(address(this));
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0){
                    sendETHToFee(contractETHBalance);
                }
                Users[sender].timeoflastsell = block.timestamp.sub(launchTime);
                if(presalers[sender]){
                    presalers[sender] = false;
                }
                memTeam = taxTmp;
            }


            if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {
                require(tradingOpen);
                memTeam = 25;
            }
        }
            
        bool takeFee = true;
        if (whitelist[sender] || whitelist[recipient]) {
            takeFee = false;
        }
        _tokenTransfer(sender, recipient, amount, takeFee, memFee, memTeam);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function swapTokensForEthUser(uint256 tokenAmount, address payable winner, address payable pool) private lockTheSwap{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(pool, address(this), tokenAmount);
        _tokenTransfer(pool, address(this), tokenAmount, false, 0, 0);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, winner, block.timestamp);
    }
    
    function openTrading() public onlyOwner {
        require(!tradingOpen);
        tradingOpen = true;
        launchTime = block.timestamp + (5 seconds);
        timeOfAllocation = block.timestamp;
    }
    
    
    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        _maxTxAmount = 20000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }
    
    function manualswap() external {
        require(_msgSender() == _teamAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _teamAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    
    function sendETHToFee(uint256 amount) private {
        uint256 amountTeam = amount.mul(70).div(100);
        uint256 amountDev = amount.mul(30).div(100);
        if(amountDev > 0){
            _teamAddress.transfer(amountTeam);
            _devAddress.transfer(amountDev);
        }
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(10**2);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, uint256 _taxFee, uint256 _teamFee) private {
        holdRate = block.timestamp - launchTime;
        uint256 totalFee = _teamFee + _taxFee;
        uint256 amountT = amount.mul(100 - totalFee).div(100);
        if(sender != uniswapV2Pair && sender != address(uniswapV2Router) && !whitelist[sender] && Users[sender]._balanceDividend != 0){
            Users[sender]._balanceDividend = Users[sender]._balanceDividend.sub(amount.mul(10**9).div(_totalSupply));
        }
        Users[recipient]._balanceDividend = Users[recipient]._balanceDividend.add(amountT.mul(10**9).div(_totalSupply));
        _transferStandard(sender, recipient, amount, takeFee, _taxFee, _teamFee);
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount, bool takeFee, uint256 _taxFee, uint256 _teamFee ) private{
        uint256 amountT = amount;
        uint256 amountTaken = amount;
        if(takeFee){
            uint256 teamAmount = amount.mul(_teamFee).div(100);
            uint256 taxAmount = amount.mul(_taxFee).div(100);
            uint256 totalFee = _teamFee + _taxFee;
            amountT = amount.mul(100 - totalFee).div(100);
            distributeTax(taxAmount, teamAmount, sender);
        }
        _balances[recipient] = _balances[recipient].add(amountT);
        _balances[sender] = _balances[sender].sub(amountTaken);
        emit Transfer(sender, recipient, amountT);
    }
    
    function distributeTax(uint256 _taxAmount, uint256 _teamAmount, address sender) private {
        _balances[address(this)] = _balances[address(this)].add(_teamAmount);
        uint256 _jarlKingAmount = _taxAmount.mul(20).div(100);
        uint256 _odinAmount = _taxAmount.sub(_jarlKingAmount.mul(2));
        _balances[jarlPool] = _balances[jarlPool].add(_jarlKingAmount);
        _balances[kingPool] = _balances[kingPool].add(_jarlKingAmount);
        _balances[odinPool] = _balances[odinPool].add(_odinAmount);
        divPoolAmount[jarlPool] = divPoolAmount[jarlPool] + _jarlKingAmount;
        divPoolAmount[kingPool] = divPoolAmount[kingPool] + _jarlKingAmount;
        divPoolAmount[odinPool] = divPoolAmount[odinPool] + _odinAmount;
    }
    
    function setPools(address payable _jackpot, address payable _jarlPool, address payable _kingPool, address payable _odinPool) public onlyOwner{
        jackpot = _jackpot;
        whitelist[jackpot] = true;
        
        jarlPool = _jarlPool;
        whitelist[jarlPool] = true;
        
        kingPool = _kingPool;
        whitelist[kingPool] = true; 
        
        odinPool = _odinPool;
        whitelist[odinPool] = true;
        
        
        uint256 jackpotAmount = 10000000000 * 10 ** 9;
        uint256 jarlAmount = 20000000000 * 10 ** 9;
        uint256 odinAmount = 40000000000 * 10 ** 9;
        
        _approve(_msgSender(), address(this), 90000000000 * 10 ** 9);
        _tokenTransfer(_msgSender(), jackpot, jackpotAmount, false, 0, 0);
        _tokenTransfer(_msgSender(), jarlPool, jarlAmount, false, 0, 0);
        _tokenTransfer(_msgSender(), kingPool, jarlAmount, false, 0, 0);
        _tokenTransfer(_msgSender(), odinPool, odinAmount, false, 0, 0);
        
        divPoolAmount[jarlPool] = 20000000000 * 10 ** 9;
        divPoolAmount[kingPool] = 20000000000 * 10 ** 9;
        divPoolAmount[odinPool] = 40000000000 * 10 ** 9;
    }
    
    
    
    function rewardWinner(address payable winner) internal {
        uint256 amounttotransfer = 700000000 * 10 ** 9;
        if(balanceOf(jackpot) > amounttotransfer){
            _approve(jackpot, address(this), amounttotransfer);
            _tokenTransfer(jackpot, winner, amounttotransfer, false, 0, 0);
            emit JackpotWon(winner); //used to broadcast winner to our tg (centralization)
        }
    }
    
    
    //Fallback function to receive ETH
    receive() external payable {}
    
    
    function removeBot(address recipient) public onlyOwner{
        bots[recipient] = false;
    }
    
    function addToWhitelist(address recipient) public onlyOwner{
        whitelist[recipient] = true;
    }
    
    function isBot(address _addr) public view returns(bool){
        return bots[_addr];
    }
    
    
    function addPresaler(address user) external{
        require(whitelist[_msgSender()]);
        require(!presalers[user]);
        presalers[user] = true;
    }
    
    
    function removePresaler(address user) external onlyOwner{
        require(whitelist[_msgSender()]);
        require(presalers[user]);
        presalers[user] = false;
    }
    
    
    function GetHoldTime(address addr) public view returns(uint256){
        if(Users[addr].timeoflastbuy != 0){
            return holdRate - Users[addr].timeoflastsell;   
        }
        return 0;
    }
    
    function GetTier(address addr) public view returns(bytes32){
        uint256 holdtime = GetHoldTime(addr);
        bytes32 tier = '';
        if(holdtime > (0 hours)){
            tier = 'FARMER';
            if(holdtime > (2 minutes)){
                tier = 'VIKINGR';
                if(holdtime > (12 minutes)){
                    tier = 'JARL';
                    if(holdtime > (24 minutes)){
                        tier = 'KING';
                        if(holdtime > (45 minutes)){
                            tier = 'GOD';
                        }
                        
                    }
                    
                }
            }
        }
        if(presalers[addr]){
            tier = 'GOD';
        }
        return tier;
        
    }
    
    function RedeemReward() public {
        bytes32 tier = GetTier(_msgSender());
        require(tier != 'FARMER' && tier != 'VIKINGR');
        uint256 amountToRedeem;
        if(Users[_msgSender()]._balanceDividend != 0){
            if(tier == 'JARL'){
               amountToRedeem = (Users[_msgSender()]._balanceDividend.mul(divPoolAmount[jarlPool])).div(10**9);
               swapTokensForEthUser(amountToRedeem, payable(_msgSender()), jarlPool);
               Users[_msgSender()]._balanceDividend = 0;
            }
            if(tier == 'VIKINGR'){
               amountToRedeem = (Users[_msgSender()]._balanceDividend.mul(divPoolAmount[kingPool])).div(10**9);
               swapTokensForEthUser(amountToRedeem, payable(_msgSender()), kingPool);
               Users[_msgSender()]._balanceDividend = 0;
            }
            if(tier == 'GOD'){
               amountToRedeem = (Users[_msgSender()]._balanceDividend.mul(divPoolAmount[odinPool])).div(10**9);
               swapTokensForEthUser(amountToRedeem, payable(_msgSender()), odinPool);
               Users[_msgSender()]._balanceDividend = 0;
            }
        }
    }
    
    function getETHShare(address addr) view public returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        uint256 amountIn = Users[addr]._balanceDividend;
        uint[] memory amountOutMin = uniswapV2Router.getAmountsOut(amountIn, path);
        return amountOutMin[1];
    }
}
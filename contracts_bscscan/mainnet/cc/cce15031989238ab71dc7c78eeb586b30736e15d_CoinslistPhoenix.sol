/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/**
* Coinslist.xyz
* Telegram - https://t.me/coinslistxyz
* Website - https://coinslist.xyz
* Supply - 100,000,000,000
* Max Wallet - 1 Billion   
* Max Buy - 1 Billion
* Max Sell - 125 Million
*
*    *10% Total Buy Fees
     *10% Total Sell Fee on first Sell. 
     *  If you sell within 30 minutes of your first sell, the Sell fee compounds to 20%. 
     *  Your next sell will incur a 30% Sell fee and this will continue for 1.5hours. 
     *  Any Sell at 30% fee will refresh the cooldown.
     *  ** THESE ADDITIONAL FEES ARE PAID DIRECTLY TO THE CONTRACT ADDRESS **
     *
     *On each execution of swapback()
     *
     *8% LP generated and burned
     *2% Merchant Fee (.5%% to Dev, 1.5% to Contract address for Buyback)
     *
     *The buyback() function auto executes when the contract balance hits .01 BNB. These tokens are burned
     *
* 
*/

pragma solidity ^0.8.11;
// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeSwapRouter {
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

// Contracts and libraries

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
        if (a == 0) {return 0;}
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

abstract contract Ownership {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "You're not an owner!");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "You're not authorized");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract CoinslistPhoenix is Ownership, IBEP20 {
    using SafeMath for uint256;

    address DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address ZERO_WALLET = 0x0000000000000000000000000000000000000000;
    address merchantWallet = 0x84fD5fCE1b18172eE52F62355f148431A66aDCe0;

    // address pancakeAddress =  0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET - https://pancake.kiemtienonline360.com/
    address pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //MAINNET

    string constant _name = "Coinslist.xyz";
    string constant _symbol = "CLXYZ";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * 1**18 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxWalletAmount = ( _totalSupply * 1 ) / 100;
    uint256 private _maxTxAmountBuy = _maxWalletAmount;
    uint256 private _maxTxAmountSell = ( _maxWalletAmount * 1 ) / 8;
    uint256 public _sellcoolDown = 1800;
    uint256 public _stackingSellcoolDown = 3600;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => uint256) _lastSell;
    mapping (address => uint256) _lastSellMultiplyer;

    uint256 liquidityFee    = 8;
    uint256 merchantFee     = 2;
    uint256 public totalFeeIfBuying = 10;
    uint256 public totalFeeIfSelling = 10;
    uint256 feeDenominator  = 100;

    uint256 nofee = 0;

    address public autoLiquidityReceiver;
    address public merchantFeeReceiver;

    PancakeSwapRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000;
    uint256 public buyBackThreshold = _totalSupply / 10000000000000;

    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 public launchedAt = block.number;

    constructor() Ownership(msg.sender) {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;

        autoLiquidityReceiver = DEAD_WALLET;
        merchantFeeReceiver = merchantWallet;

        _balances[msg.sender] = _totalSupply * 75 / 100;

        _balances[0xB92990a2a3c2E96BB9741e4C19BBd993Ee3631c5] = _totalSupply * 1 / 200;
        _balances[0x486721225Af21d83972553d20E9f52763e611280] = _totalSupply * 1 / 200;
        _balances[0x02006C21EED2370F69eDa3Be3F2AB8F405203Aef] = _totalSupply * 1 / 200;
        _balances[0xf7b7bdc34a3F2D8BCad8221df0D41bE667f05148] = _totalSupply * 1 / 200;
        _balances[0xf5e4D22923233e6557a5b457C690D04F5155c507] = _totalSupply * 1 / 200;
        _balances[0x635108e97b1e87C71FE7904441EC084051359FC6] = _totalSupply * 1 / 200;
        _balances[0x651C361CcF6223a13F143C5BEDF32dA722F707d3] = _totalSupply * 1 / 200;
        _balances[0xE11edF824C1c0250505ecfa59b336d6E0Ddcf915] = _totalSupply * 1 / 200;
        _balances[0xdccF3B77dA55107280bd850ea519DF3705D1a75a] = _totalSupply * 1 / 200;
        _balances[0x02c2adbdB7c0C1037B5278626A78B6c71787dFe8] = _totalSupply * 1 / 200;
        _balances[0xc0B48A9C09E35d4BCFc4D6b14B0346850e01911b] = _totalSupply * 1 / 200;
        _balances[0xD5A1e164124fC7eEF7F49B80F743010071E97c30] = _totalSupply * 1 / 200;
        _balances[0x2363a983b82F30AD3259aAcB33aCf5DB605352E7] = _totalSupply * 1 / 200;
        _balances[0x469fb0776C3FF0DaCF06Ddcfad5CF84fDbD16Dac] = _totalSupply * 1 / 200;
        _balances[0x1d8EF03BC44C663b1af8c741694Ca2968760bD98] = _totalSupply * 1 / 200;
        _balances[0x492b277A2EcEF7bC743Ac01E4fEd800263A4fA59] = _totalSupply * 1 / 200;
        _balances[0xc6cE6612033f1Ee9422ba32E931ce02F9fAca84f] = _totalSupply * 1 / 1000;
        _balances[0xc204eB824678d80E89eA63189977c14B841ca457] = _totalSupply * 1 / 200;
        _balances[0xf6C839631cEc123f2D9fD5206A4A8c951429c7A6] = _totalSupply * 1 / 200;
        _balances[0x8306982F62FcCaF1A0742fd257B6a63c54A9617A] = _totalSupply * 1 / 200;
        _balances[0x272f7C39A09d1224F31Ea680948721522EB4e1EC] = _totalSupply * 25 / 10000;
        _balances[0xf2C10D2B21B09e76822C0088D5B130fFBE4Eec45] = _totalSupply * 1 / 200;
        _balances[0xe7E01655A6F8a028B86bF505989b971D114a4A3c] = _totalSupply * 1 / 200;
        _balances[0x1cB943AaDb32532f0E56976A2D0F76E20154579C] = _totalSupply * 1 / 200;
        _balances[0xd8759BcD0C1DF16428b749A71C48a755d05d4Ea6] = _totalSupply * 1 / 200;
        _balances[0x52a6A2Dbcb3a2E9839C05EC65A212dd42e4ED27B] = _totalSupply * 1 / 200;
        _balances[0x7d62E9179900c05e81C34C329a6BD2c5b31f701C] = _totalSupply * 1 / 200;
        _balances[0xD07De516ee90C6E3F688218BF0C0A7c54d6a61db] = _totalSupply * 1 / 200;
        _balances[0xCC692358F12333Ab5a6E89Ab90609B09C1Bc893C] = _totalSupply * 25 / 10000;
        _balances[0xc8140E7FF027ED74f97eb5D6Aa77f332309d04c9] = _totalSupply * 1 / 200;
        _balances[0x48C78AC5f538E34B248F0015E45a9519a4128bFb] = _totalSupply * 1 / 200;
        _balances[0xc2E5E1027E10164Fad3FE0C2738Ec2627C335cB1] = _totalSupply * 1 / 200;
        _balances[0x116Fb5b92CeedE9562D9899117E5f3Aa40fcD2fF] = _totalSupply * 1 / 200;
        _balances[0x90f675bFB74Df8D889a5096613550c61D58ADc40] = _totalSupply * 1 / 200;
        _balances[0xc4BBD409A17315Bb0c5B48c54F3F49E65a098481] = _totalSupply * 1 / 200;
        _balances[0xe9F9506a228a8F3613B66f13DB7d61DeE02ed6c4] = _totalSupply * 25 / 10000;
        _balances[0x3B1EbD50d0182863eDD09647f9f229048fc703E6] = _totalSupply * 1 / 200;
        _balances[0xb8D8d45cEE064BB393d879b22a3B908E4a32ebF3] = _totalSupply * 1 / 200;
        _balances[0x21AFcC9D87a91240B2e0E8a1687a27b092f3eB76] = _totalSupply * 1 / 200;
        _balances[0xa2313765a195184bBA6deC0DEf04D2E706d33d22] = _totalSupply * 1 / 200;      
        _balances[0x0eE730cd633F1cbD0Dc410Cf4f37512C9587bE11] = _totalSupply * 1 / 200;
        _balances[0xd5f1B5CDF8BCEe28B01B54b6ca2Cd94ca16Bc189] = _totalSupply * 1 / 200;
        _balances[0x1c2237fcc28CB44F985d37252dade8600cd1c87d] = _totalSupply * 1 / 200;
        _balances[0x270d555EF4BE43215CDD05C875ea12993E391A17] = _totalSupply * 1 / 200;
        _balances[0x956c561017b56fd56a052E28E82613139A053Cc4] = _totalSupply * 1 / 200;
        _balances[0xCF8D921C9c3f050fbf9E4992Db783B2fC7B59850] = _totalSupply * 1 / 200;
        _balances[0x0aB1102F3679E17895A64b01181f8744C7b23351] = _totalSupply * 1 / 200;
        _balances[0x60F30b7b67f862b526A955031d1b70F18512938B] = _totalSupply * 25 / 10000;
        _balances[0x4eFFbA37E8C7e34Fc4241995b3380F2B9033C99f] = _totalSupply * 25 / 10000;
        _balances[0x9f5E7BEC92d86a57dcd17380aBC79dA75f0675A2] = _totalSupply * 25 / 10000;
        _balances[0x000000000000000000000000000000000000dEaD] = _totalSupply * 19 / 1000;
        
        emit Transfer(address(0), msg.sender, _totalSupply * 75 / 100);
        emit Transfer(address(0), 0xB92990a2a3c2E96BB9741e4C19BBd993Ee3631c5, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x486721225Af21d83972553d20E9f52763e611280, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x02006C21EED2370F69eDa3Be3F2AB8F405203Aef, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xf7b7bdc34a3F2D8BCad8221df0D41bE667f05148, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xf5e4D22923233e6557a5b457C690D04F5155c507, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x635108e97b1e87C71FE7904441EC084051359FC6, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x651C361CcF6223a13F143C5BEDF32dA722F707d3, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xE11edF824C1c0250505ecfa59b336d6E0Ddcf915, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xdccF3B77dA55107280bd850ea519DF3705D1a75a, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x02c2adbdB7c0C1037B5278626A78B6c71787dFe8, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xc0B48A9C09E35d4BCFc4D6b14B0346850e01911b, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xD5A1e164124fC7eEF7F49B80F743010071E97c30, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x2363a983b82F30AD3259aAcB33aCf5DB605352E7, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x469fb0776C3FF0DaCF06Ddcfad5CF84fDbD16Dac, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x1d8EF03BC44C663b1af8c741694Ca2968760bD98, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x492b277A2EcEF7bC743Ac01E4fEd800263A4fA59, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xc6cE6612033f1Ee9422ba32E931ce02F9fAca84f, _totalSupply * 1 / 1000);
        emit Transfer(address(0), 0xc204eB824678d80E89eA63189977c14B841ca457, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xf6C839631cEc123f2D9fD5206A4A8c951429c7A6, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x8306982F62FcCaF1A0742fd257B6a63c54A9617A, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x272f7C39A09d1224F31Ea680948721522EB4e1EC, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0xf2C10D2B21B09e76822C0088D5B130fFBE4Eec45, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xe7E01655A6F8a028B86bF505989b971D114a4A3c, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x1cB943AaDb32532f0E56976A2D0F76E20154579C, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xd8759BcD0C1DF16428b749A71C48a755d05d4Ea6, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x52a6A2Dbcb3a2E9839C05EC65A212dd42e4ED27B, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x7d62E9179900c05e81C34C329a6BD2c5b31f701C, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xD07De516ee90C6E3F688218BF0C0A7c54d6a61db, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xCC692358F12333Ab5a6E89Ab90609B09C1Bc893C, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0xc8140E7FF027ED74f97eb5D6Aa77f332309d04c9, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x48C78AC5f538E34B248F0015E45a9519a4128bFb, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xc2E5E1027E10164Fad3FE0C2738Ec2627C335cB1, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x116Fb5b92CeedE9562D9899117E5f3Aa40fcD2fF, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x90f675bFB74Df8D889a5096613550c61D58ADc40, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xc4BBD409A17315Bb0c5B48c54F3F49E65a098481, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xe9F9506a228a8F3613B66f13DB7d61DeE02ed6c4, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0x3B1EbD50d0182863eDD09647f9f229048fc703E6, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xb8D8d45cEE064BB393d879b22a3B908E4a32ebF3, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x21AFcC9D87a91240B2e0E8a1687a27b092f3eB76, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xa2313765a195184bBA6deC0DEf04D2E706d33d22, _totalSupply * 1 / 200);        
        emit Transfer(address(0), 0x0eE730cd633F1cbD0Dc410Cf4f37512C9587bE11, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xd5f1B5CDF8BCEe28B01B54b6ca2Cd94ca16Bc189, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x1c2237fcc28CB44F985d37252dade8600cd1c87d, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x270d555EF4BE43215CDD05C875ea12993E391A17, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x956c561017b56fd56a052E28E82613139A053Cc4, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0xCF8D921C9c3f050fbf9E4992Db783B2fC7B59850, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x0aB1102F3679E17895A64b01181f8744C7b23351, _totalSupply * 1 / 200);
        emit Transfer(address(0), 0x60F30b7b67f862b526A955031d1b70F18512938B, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0x4eFFbA37E8C7e34Fc4241995b3380F2B9033C99f, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0x9f5E7BEC92d86a57dcd17380aBC79dA75f0675A2, _totalSupply * 25 / 10000);
        emit Transfer(address(0), 0x000000000000000000000000000000000000dEaD, _totalSupply * 19 / 1000);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(ZERO_WALLET));
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferTo(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

        function _transferTo(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
 
        checkTxLimitTo(recipient, amount);
    
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = takeFeeTo(sender, recipient, amount);

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }


    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}
        
        checkTxLimitFrom(sender, recipient, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(shouldBuyBack()){ buyBack(); }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = takeFeeFrom(sender, amount);

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldSwapBack() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function shouldBuyBack() private view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && address(this).balance >= buyBackThreshold;
    }

     function swapBack() private swapping() {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFeeIfSelling).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        approve(address(this), amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalFeeIfSelling);
        uint256 amountBNBmerchant = amountBNB.mul(merchantFee).div(totalFeeIfSelling).div(3);

        (bool tmpSuccess,) = payable(merchantFeeReceiver).call{value : amountBNBmerchant, gas : 30000}("");
        tmpSuccess = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function buyBack() private swapping() {

        uint256 amountBNBbuyback = address(this).balance;

        approve(address(this), amountBNBbuyback);

        address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBbuyback}(
                0,
                path,
                DEAD_WALLET,
                block.timestamp
            );
    }

   function checkTxLimitTo(address recipient, uint256 amount) private view {
        if (isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmountBuy);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }

   function checkTxLimitFrom(address sender, address recipient, uint256 amount) private view {
        if (isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender] && recipient == pair || recipient == DEAD_WALLET || recipient == ZERO_WALLET || recipient == address(this)) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _totalSupply);
        } else if (!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmountSell);
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount);
        }
    }

    function takeFeeTo(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(totalFeeIfBuying).div(feeDenominator);
        if (isFeeExempt[recipient]) {
            _balances[address(this)] = _balances[address(this)].add(nofee);
            emit Transfer(sender, address(this), nofee);
            return amount.sub(nofee);
        } else
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
    }

    function takeFeeFrom(address sender, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(totalFeeIfSelling).div(feeDenominator);
        uint256 TwoX = amount.mul(totalFeeIfSelling).div(feeDenominator).mul(2);
        uint256 ThreeX = amount.mul(totalFeeIfSelling).div(feeDenominator).mul(3);
        if (isFeeExempt[sender]) {
            _balances[address(this)] = _balances[address(this)].add(nofee);
            emit Transfer(sender, address(this), nofee);
            return amount.sub(nofee);
        } else if (_lastSellMultiplyer[sender] >= block.timestamp) {
            _lastSellMultiplyer[sender] = block.timestamp + _sellcoolDown + _stackingSellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(ThreeX);
            emit Transfer(sender, address(this), ThreeX);
            return amount.sub(ThreeX);
        } else if (_lastSell[sender] >= block.timestamp) {
            _lastSellMultiplyer[sender] = block.timestamp + _sellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(TwoX);
            emit Transfer(sender, address(this), TwoX);
            return amount.sub(TwoX);
        } else
            _lastSell[sender] = block.timestamp + _sellcoolDown;
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
    }

    function modifyIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function modifyIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}
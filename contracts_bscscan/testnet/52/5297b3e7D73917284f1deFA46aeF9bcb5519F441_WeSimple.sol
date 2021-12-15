pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

interface IBEP20 {
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

// Dex Factory contract interface
interface IdexFacotry {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IDexRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
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

contract WeSimple is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => uint256) public _lastBuyTime;

 
    string private _name = "WE The People";
    string private _symbol = "WE";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000* 1e9 * 1e18; // 21 Million

    IDexRouter public dexRouter;
    address public dexPair;
    address payable public taxReceiver;
    address payable public wallet1;

    bool public distributeAndLiquifyStatus = true; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _antiwhale = true;


    uint256 public minTokenToSwap = 1000 * 1e18; // 1000 amount will trigger swap and distribute
    uint256 public taxFee = 120; // 12%  tax on buy sell
    uint256 public sellingCoolDown = 4 minutes;


    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        taxReceiver = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        wallet1 = payable(0xE788a1FBBa2246DD87aDB4714361E1105f4028A1);

        _balances[owner()] = _totalSupply.mul(50).div(100);
        _balances[wallet1] = _totalSupply.mul(50).div(100);

        IDexRouter _pancakeRouter = IDexRouter(
            // miannet >>
            //  0x10ED43C718714eb63d5aA57B78B54704E256024E
            // // testnet >>
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a pancake pair for this new WE
        dexPair = IdexFacotry(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(this), owner(), _totalSupply.mul(50).div(100));
        emit Transfer(address(this), wallet1, _totalSupply.mul(50).div(100));
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function changeSellingCoolDown(uint256 _time) public onlyOwner {
        sellingCoolDown = _time;
    }

    function AntiWhale(bool value) external onlyOwner {
        _antiwhale = value;
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
                "WE: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "WE: decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setFeePercent(uint256 _taxFee) external onlyOwner {
        taxFee = _taxFee;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        distributeAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(address payable _address, address payable _wallet1)
        external
        onlyOwner
    {
        taxReceiver = _address;
        wallet1 = _wallet1;
    }

    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    function removeStuckFunds(address payable _account, uint256 _amount)
        external
        onlyOwner
    {
        _account.transfer(_amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "WE: approve from the zero address");
        require(spender != address(0), "WE: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "WE: transfer from the zero address");
        require(to != address(0), "WE: transfer to the zero address");
        require(amount > 0, "WE: Amount must be greater than zero");
        
        if (_antiwhale){
            to == dexPair;
            _lastBuyTime[to]=block.timestamp;

         if(!_antiwhale){
             from != dexPair;
         }else{
             require(  block.timestamp >= _lastBuyTime[from] + sellingCoolDown, "wait for next sell");
         }

        }
        // swap and liquify
        distributeAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax,stakingPool fee, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if ((sender == dexPair || recipient == dexPair) && takeFee) {
            uint256 fee =  amount.mul(taxFee).div(1e3);
            uint256 tTransferAmount = amount.sub(fee);

            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            _balances[address(this)] = _balances[address(this)].add(fee);

            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender, address(this), fee);
 
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function distributeAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is Dex pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap;

        if (
            shouldSell &&
            from != dexPair &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            uint256 tokenAmountToBeSwapped = contractTokenBalance;

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 taxBalance = address(this).balance;

            // sending bnb to development wallet
            if (taxBalance > 0) {
                taxReceiver.transfer(taxBalance);
            }
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
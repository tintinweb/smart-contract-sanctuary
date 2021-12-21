/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.8.9;
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
interface IdexFactory {
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

contract PIP is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;

    string private _name = "Passive Income Protocol";
    string private _symbol = "PIP";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 100000000000 * 1e9;

    IDexRouter public dexRouter;
    address public dexPair;
    address payable public investmentFund;
    address payable public marketWallet;
    address payable public devWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public maxTxAmount = _totalSupply.mul(2).div(100); // should be 0.2% percent per transaction
    uint256 public minTokenToSwap = 100000 * 1e9; // 100K amount will trigger swap and distribute
    uint256 public percentDivider = 1000;

    bool public swapAndLiquifyEnabled = true; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default

    uint256 public investmentFundFee = 10; // 1% will be added to the investmentFund
    uint256 public marketFee = 10; // 1% will be added to the marketWallet address
    uint256 public devFee = 10; // 1% will be added to the dev address
    uint256 public liquidityFee = 10; // 1% will be added to the liquidity
    uint256 public burnFee = 10; // 1% will be added to the dead Address

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address payable _investmentFund,
        address payable _marketWallet,
        address payable _devWallet
    ) {
        _balances[owner()] = _totalSupply;

        investmentFund = _investmentFund;
        marketWallet = _marketWallet;
        devWallet = _devWallet;

        IDexRouter _dexRouter = IDexRouter(
            // // miannet >>
             0x10ED43C718714eb63d5aA57B78B54704E256024E
            // testnet >>
           // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a dex pair for this new PIP
        dexPair = IdexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[investmentFund] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[burnAddress] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[burnAddress] = true;
        _isExcludedFromFee[investmentFund] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[marketWallet] = true;

        emit Transfer(address(0), owner(), _totalSupply);
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
                "PIP: transfer amount exceeds allowance"
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
                "PIP: decreased allowance below zero"
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

    function includeOrExcludeFromMaxTx(address _address, bool value)
        external
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTxAmount = _amount;
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setFees(
        uint256 _investmentFee,
        uint256 _burnFee,
        uint256 _marketFee,
        uint256 _lpFee,
        uint256 _devFee
    ) external onlyOwner {
        investmentFundFee = _investmentFee;
        burnFee = _burnFee;
        marketFee = _marketFee;
        liquidityFee = _lpFee;
        devFee = _devFee;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        swapAndLiquifyEnabled = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _investmentFund,
        address payable _marketWallet,
        address payable _devWallet
    ) external onlyOwner {
        investmentFund = _investmentFund;
        marketWallet = _marketWallet;
        devWallet = _devWallet;
    }

    function setdexRouter(IDexRouter _router, address _pair)
        external
        onlyOwner
    {
        dexRouter = _router;
        dexPair = _pair;
    }

    function totalFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                marketFee.add(investmentFundFee).add(burnFee).add(devFee).add(
                    liquidityFee
                )
            )
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "PIP: approve from the zero address");
        require(spender != address(0), "PIP: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "PIP: transfer from the zero address");
        require(to != address(0), "PIP: transfer to the zero address");
        require(amount > 0, "PIP: Amount must be greater than zero");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(amount <= maxTxAmount, "PIP: amount exceeded max limit");
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
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
            uint256 allFee = totalFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeDevFee(sender, amount);
            _takeInvestmentFundFee(sender, amount);
            _takeLiquidityFee(sender, amount);
            _takeBurnFee(sender, amount);
            _takeMarketFee(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeInvestmentFundFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(investmentFundFee).div(percentDivider);
        _balances[investmentFund] = _balances[investmentFund].add(fee);

        emit Transfer(sender, investmentFund, fee);
    }

    function _takeDevFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(devFee).div(percentDivider);
        _balances[devWallet] = _balances[devWallet].add(fee);

        emit Transfer(sender, devWallet, fee);
    }

    function _takeBurnFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(burnFee).div(percentDivider);
        _balances[burnAddress] = _balances[burnAddress].add(fee);

        emit Transfer(sender, burnAddress, fee);
    }

    function _takeMarketFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(marketFee).div(percentDivider);
        _balances[marketWallet] = _balances[marketWallet].add(fee);

        emit Transfer(sender, marketWallet, fee);
    }

    function _takeLiquidityFee(address sender, uint256 amount) internal {
        uint256 _lpFee = amount.mul(liquidityFee).div(percentDivider);

        _balances[address(this)] = _balances[address(this)].add(_lpFee);

        emit Transfer(sender, address(this), _lpFee);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is dex pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap;

        if (
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            // add liquidity
            // split the contract balance into 2 pieces
            uint256 otherPiece = contractTokenBalance.div(2);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherPiece
            );

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 bnbToBeAddedToLiquidity = address(this).balance.sub(
                initialBalance
            );

            // add liquidity to dex
            Utils.addLiquidity(
                address(dexRouter),
                owner(),
                otherPiece,
                bnbToBeAddedToLiquidity
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                bnbToBeAddedToLiquidity,
                otherPiece
            );
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
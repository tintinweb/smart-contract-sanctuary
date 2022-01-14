/**
 *Submitted for verification at BscScan.com on 2022-01-13
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

contract NEW is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;

    string private _name = "New Token";
    string private _symbol = "NEWTICK";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 100000000 * 1e9; //100 Million

    IDexRouter public dexRouter;
    address public dexPair;

    address payable public dev1;
    address payable public dev2;
    address payable public dev3;
    address payable public tokenFundWallet;
    address payable public game1Reward;
    address payable public game2Reward;
    address payable public marketWallet;
    address payable public communityReward;
    uint256 public maxTxAmount = _totalSupply.mul(5).div(100); // should be 1% percent per transaction
    uint256 public minTokenToSwap = 10000 * 1e9; // 10K amount will trigger swap and distribute
    uint256 public percentDivider = 1000;
    uint256 public launchTime;

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public dev1Fee = 10; // 1% will be added to the dev1
    uint256 public dev2Fee = 10; // 1% will be added to the dev2
    uint256 public dev3Fee = 10; // 1% will be added to the dev3
    uint256 public marketFee = 30; // 3% will be added to the marketWallet address
    uint256 public communityFee = 30; // 3% will be added co communityRewad wallet
    uint256 public liquidityFee = 10; // 1% will be added to the liquidity
    uint256 public tokenFundFee = 10; // 1% will be added to the tokenFund Address
    uint256 public game1Fee = 10; // 1% will be added to the game1Fee Address
    uint256 public game2Fee = 10; // 1% will be added to the game2Fee Address

    // for smart contract use
    uint256 liquidityFeeCounter = 0;
    uint256 marketFeeCounter = 0;
    uint256 dev1FeeCounter = 0;
    uint256 dev2FeeCounter = 0;
    uint256 dev3FeeCounter = 0;
    uint256 game1FeeCounter = 0;
    uint256 game2FeeCounter = 0;
    uint256 communityFeeCounter = 0;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 maticReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;

        dev1 = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        dev2 = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        dev3 = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        game1Reward = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        game2Reward = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        marketWallet = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        communityReward = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        tokenFundWallet = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);

        IDexRouter _dexRouter = IDexRouter(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
            
        );
        // Create a dex pair for this new NEW
        dexPair = IdexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive MATIC from dexRouter when swapping
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
                "NEW: transfer amount exceeds allowance"
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
                "NEW: decreased allowance below zero"
            )
        );
        return true;
    }

    function Launch() public onlyOwner {
        require(!_tradingOpen, "NEW: Already enabled");
        _tradingOpen = true;
        launchTime = block.timestamp;
        swapAndLiquifyEnabled = true;
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
        uint256 _dev1Fee,
        uint256 _dev2Fee,
        uint256 _dev3Fee,
        uint256 _marketFee,
        uint256 _communityFee,
        uint256 _liquidityFee,
        uint256 _tokenFundFee,
        uint256 _game1Fee,
        uint256 _game2Fee
    ) external onlyOwner {
        dev1Fee = _dev1Fee;
        dev2Fee = _dev2Fee;
        dev3Fee = _dev3Fee;
        marketFee = _marketFee;
        communityFee = _communityFee;
        liquidityFee = _liquidityFee;
        tokenFundFee = _tokenFundFee;
        game1Fee = _game1Fee;
        game2Fee = _game2Fee;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        swapAndLiquifyEnabled = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _dev1,
        address payable _dev2,
        address payable _dev3,
        address payable _tokenFundWallet,
        address payable _game1Reward,
        address payable _game2Reward,
        address payable _marketWallet,
        address payable _communityReward
    ) external onlyOwner {
        dev1 = _dev1;
        dev2 = _dev2;
        dev3 = _dev3;
        tokenFundWallet = _tokenFundWallet;
        game1Reward = _game1Reward;
        game2Reward = _game2Reward;
        marketWallet = _marketWallet;
        communityReward = _communityReward;
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
                marketFee
                    .add(dev1Fee)
                    .add(dev2Fee)
                    .add(dev3Fee)
                    .add(tokenFundFee)
                    .add(communityFee)
                    .add(liquidityFee)
                    .add(game1Fee)
                    .add(game2Fee)
            )
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "NEW: approve from the zero address");
        require(spender != address(0), "NEW: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "NEW: transfer from the zero address");
        require(to != address(0), "NEW: transfer to the zero address");
        require(amount > 0, "NEW: Amount must be greater than zero");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(amount <= maxTxAmount, "NEW: amount exceeded max limit");
            // trading disable till launch
            if (!_tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "NEW: Trading is not enabled yet"
                );
            }
        }

        // swap and liquify
        //  swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax,  liquidity fee
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

            _takeDevFeesInMATIC(sender,amount);
            _takeReaminingFeeInMATIC(sender, amount);
            _taketokenFundFee(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }
     function _takeDevFeesInMATIC(address sender, uint256 amount)
        internal
    {
        uint256 _dev1Fee = amount.mul(dev1Fee).div(percentDivider);
        dev1FeeCounter = marketFeeCounter.add(_dev1Fee);
        uint256 _dev2Fee = amount.mul(dev2Fee).div(percentDivider);
        dev2FeeCounter = dev2FeeCounter.add(_dev2Fee);
        uint256 _dev3Fee = amount.mul(dev3Fee).div(percentDivider);
        dev3FeeCounter = dev3FeeCounter.add(_dev3Fee);

            _balances[address(this)] = _balances[address(this)] 
                .add(_dev1Fee
                .add(_dev2Fee)
                .add(_dev3Fee)
             
        );
        emit Transfer(
            sender,
            address(this), 
                _dev1Fee
                .add(_dev2Fee)
                .add(_dev3Fee) 
        );
    }

    function _takeReaminingFeeInMATIC(address sender, uint256 amount)
        internal
    {
        uint256 _lpFee = amount.mul(liquidityFee).div(percentDivider);
        liquidityFeeCounter = liquidityFeeCounter.add(_lpFee);

        uint256 _marketFee = amount.mul(marketFee).div(percentDivider);
        marketFeeCounter = marketFeeCounter.add(_marketFee);


       uint256 _game1Fee = amount.mul(game1Fee).div(percentDivider);
        game1FeeCounter = game1FeeCounter.add(_game1Fee);
        uint256 _game2Fee = amount.mul(game2Fee).div(percentDivider);
        game2FeeCounter = game2FeeCounter.add(_game2Fee);

        uint256 _communityFee = amount.mul(communityFee).div(percentDivider);
        communityFeeCounter = communityFeeCounter.add(_communityFee);

        _balances[address(this)] = _balances[address(this)].add(
            _lpFee
                .add(_marketFee) 
                .add(_game1Fee)
                .add(_game2Fee)
                .add(_communityFee)
        );

        emit Transfer(
            sender,
            address(this),
            _lpFee
                .add(_marketFee) 
                .add(game1Fee)
                .add(game2Fee)
                .add(communityFee)
        );
    }
 

    function _taketokenFundFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(tokenFundFee).div(percentDivider);
        _balances[tokenFundWallet] = _balances[tokenFundWallet].add(fee);

        emit Transfer(sender, tokenFundWallet, fee);
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

            uint256 halfLiquidity = liquidityFeeCounter.div(2);
            uint256 otherHalfLiquidity = liquidityFeeCounter.sub(halfLiquidity);

            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherHalfLiquidity
            );

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 deltaBalance = address(this).balance;
            uint256 bnbToBeAddedToLiquidity = deltaBalance
                .mul(halfLiquidity)
                .div(tokenAmountToBeSwapped);
            uint256 bnbFormarket = deltaBalance.mul(marketFeeCounter).div(
                tokenAmountToBeSwapped
            );
            uint256 bnbForcommunity = deltaBalance.mul(communityFeeCounter).div(
                tokenAmountToBeSwapped
            );
            uint256 bnbforGame1 = deltaBalance.mul(game1FeeCounter).div(
                tokenAmountToBeSwapped
            );
            uint256 bnbforGame2 = deltaBalance.mul(game2FeeCounter).div(
                tokenAmountToBeSwapped
            );
            uint256 bnbForDev1 = deltaBalance.mul(dev1FeeCounter).div(
                tokenAmountToBeSwapped
            );
            uint256 bnbForDev2 = deltaBalance.mul(dev2FeeCounter).div(
                tokenAmountToBeSwapped
            ); 
            uint256 bnbForDev3 = deltaBalance.mul(dev3FeeCounter).div(
                tokenAmountToBeSwapped
            );

            // sending bnb to market wallet
            if (bnbFormarket > 0) marketWallet.transfer(bnbFormarket);

            // sending bnb to communityWallet wallet
            if (bnbForcommunity > 0) communityReward.transfer(bnbForcommunity);

            if (bnbforGame1 > 0) game1Reward.transfer(bnbforGame1);

            if (bnbforGame2 > 0) game2Reward.transfer(bnbforGame2);

            if (bnbForDev1 > 0) dev1.transfer(bnbForDev1);

            if (bnbForDev2 > 0) dev2.transfer(bnbForDev2);

            if (bnbForDev3 > 0) dev3.transfer(bnbForDev3);

            // add liquidity to Dex
            if (bnbToBeAddedToLiquidity > 0) {
                Utils.addLiquidity(
                    address(dexRouter),
                    owner(),
                    otherHalfLiquidity,
                    bnbToBeAddedToLiquidity
                );

                emit SwapAndLiquify(
                    halfLiquidity,
                    bnbToBeAddedToLiquidity,
                    otherHalfLiquidity
                );

                //reset all fee
                liquidityFeeCounter = 0;
                marketFeeCounter = 0;
                dev1FeeCounter = 0;
                dev2FeeCounter = 0;
                dev3FeeCounter = 0;
                game1FeeCounter = 0;
                game2FeeCounter = 0;
                communityFeeCounter = 0;
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
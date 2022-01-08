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
 
    string  private _name = "New Token";
    string  private _symbol = "NEWTICK";
    uint8   private _decimals = 9;
    uint256 private _totalSupply = 100000000 * 1e9; //100 Million

    IDexRouter public dexRouter;
    address public dexPair;

    address  public dev1;
    address  public dev2;
    address  public dev3;
    address  public tokenFundWallet;
    address  public game1Reward;
    address  public game2Reward;
    address  public marketWallet;
    address  public communityReward;

    uint256 public maxTxAmount = _totalSupply.mul(1).div(100); // should be 1% percent per transaction
    uint256 public minTokenToSwap = 10000 * 1e9; // 10K amount will trigger swap and distribute
    uint256 public percentDivider = 1000;
    uint256 public launchTime;

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public dev1Fee = 10;      // 1% will be added to the dev1
    uint256 public dev2Fee = 10;      // 1% will be added to the dev2
    uint256 public dev3Fee = 10;      // 1% will be added to the dev3
    uint256 public marketFee = 30;    // 3% will be added to the marketWallet address
    uint256 public communityFee = 30; // 3% will be added co communityRewad wallet
    uint256 public liquidityFee = 10; // 1% will be added to the liquidity
    uint256 public tokenFundFee = 10; // 1% will be added to the tokenFund Address
    uint256 public game1Fee = 10;     // 1% will be added to the game1Fee Address
    uint256 public game2Fee = 10;     // 1% will be added to the game2Fee Address

    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address _router) {
        _balances[owner()] = _totalSupply;

        dev1 = 0x3411CA4c8B564F05102C3367840e599e8ed4096D;
        dev2 = dev1;
        dev3 = dev1;
        game1Reward     = dev1;
        game2Reward     = dev1;
        marketWallet    = dev1;
        communityReward = dev1;
        tokenFundWallet = dev1;


        IDexRouter _dexRouter = IDexRouter(
            _router
            // binance testnet >>
           // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
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
    address  _dev1,
    address  _dev2,
    address  _dev3,
    address  _tokenFundWallet,
    address  _game1Reward,
    address  _game2Reward,
    address  _marketWallet,
    address  _communityReward
    ) external onlyOwner {
      dev1 = _dev1;
      dev2 = _dev2;
      dev3 = _dev3;
      tokenFundWallet = _tokenFundWallet;
      game1Reward = _game1Reward;
      game2Reward = _game2Reward;
      marketWallet= _marketWallet;
      communityReward =_communityReward;
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
                marketFee.add(dev1Fee).add(dev2Fee).add(dev3Fee).add(tokenFundFee).add(communityFee).add(
                    liquidityFee.add(game1Fee).add(game2Fee)
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

            _takecommunityFee(sender, amount);
            _takeDev1Fee(sender, amount);
            _takeDev2Fee(sender, amount);
            _takeDev3Fee(sender, amount);
            _takeLiquidityFee(sender, amount);
            _taketokenFundFee(sender, amount);
            _takeMarketFee(sender, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeDev1Fee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(dev1Fee).div(percentDivider);
        _balances[dev1] = _balances[dev1].add(fee);

        emit Transfer(sender, dev1, fee);
    }   

    function _takeDev2Fee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(dev2Fee).div(percentDivider);
        _balances[dev2] = _balances[dev2].add(fee);

        emit Transfer(sender, dev2, fee);
    }
       
    function _takeDev3Fee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(dev3Fee).div(percentDivider);
        _balances[dev3] = _balances[dev3].add(fee);

        emit Transfer(sender, dev3, fee);
    }

    function _takeGame1Fee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(game1Fee).div(percentDivider);
        _balances[game1Reward] = _balances[game1Reward].add(fee);

        emit Transfer(sender, game1Reward, fee);
    }

    function _takeGame2Fee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(game2Fee).div(percentDivider);
        _balances[game2Reward] = _balances[game2Reward].add(fee);

        emit Transfer(sender, game2Reward, fee);
    }

    function _takecommunityFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(communityFee).div(percentDivider);
        _balances[communityReward] = _balances[communityReward].add(fee);

        emit Transfer(sender, communityReward, fee);
    }

    function _taketokenFundFee(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(tokenFundFee).div(percentDivider);
        _balances[tokenFundWallet] = _balances[tokenFundWallet].add(fee);

        emit Transfer(sender, tokenFundWallet, fee);
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
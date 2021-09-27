/**
 * GraviToken Version 2
 *  Website : https://gravitoken-v2.co.uk/
 *  Telegram : https://t.me/gravitokenv2
 */

pragma solidity ^0.8.7;

import "./BEP20.sol";
import "./ILP.sol";
import "./IPancakeSwapV2Factory.sol";
import "./IPancakeSwapV2Pair.sol";
import "./IPancakeSwapV2Router02.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMathInt.sol";

// SPDX-License-Identifier: MIT
contract GRV2 is BEP20, Ownable {

    using SafeMath for uint256;
    receive() external payable {}

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);

    event SwapAndLiquify(
        uint256 threequarters,
        uint256 sharedETH,
        uint256 onequarter
    );


    // Used for authentication
    address public master;

    // LP atomic sync
    address public lp;
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.

    bool public initialDistributionFinished;

    mapping (address => bool) allowTransfer;

    modifier initialDistributionLock {
        require(initialDistributionFinished || isOwner() || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;

    uint256 public transactionTax = 981;
    uint256 public buybackLimit = 10 ** 18;
    uint256 public buybackDivisor = 100;
    uint256 public numTokensSellDivisor = 10000;

    IPancakeSwapV2Router02 public uniswapV2Router;
    IPancakeSwapV2Pair public uniswapV2Pair;
    address public uniswapV2PairAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public marketingAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = false;

    mapping (address => bool) private _isExcluded;

    bool private privateSaleDropCompleted = false;
    bool private bd = false;
    bool private sd = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    bool private tradingEnabled = true;


    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    
    // Testnet : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address public _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 

    constructor ()
        BEP20("GravitokenV2", "GRV2", uint8(DECIMALS))
        payable
    {
        marketingAddress = _msgSender();

        IPancakeSwapV2Router02 _uniswapV2Router = IPancakeSwapV2Router02(_routerAddress);

        uniswapV2PairAddress = IPancakeSwapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        setLP(uniswapV2PairAddress, false, false);

        IPancakeSwapV2Pair _uniswapV2Pair = IPancakeSwapV2Pair(uniswapV2PairAddress);

        uniswapV2Pair = _uniswapV2Pair;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;

        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }


    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
        external
        onlyOwner
    {
        master = _master;
    }
    
    function setMarketingWallet(address payable _marketingWallet) external onlyOwner {
        marketingAddress = _marketingWallet;
    }
    
    function setTradingEnabled(bool _flag) external onlyOwner {
        tradingEnabled = _flag;
    }

        /**
     * @notice Sets contract LP address
     */
    function setLP(address _lp, bool _bd, bool _sd)
        public
        onlyOwner
    {
        lp = _lp;
        lpContract = ILP(_lp);
        bd = _bd;
        sd = _sd;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        override
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        validRecipient(recipient)
        initialDistributionLock
        returns (bool)
    {
      _transfer(msg.sender, recipient, amount);
      return true;
    }

  event Sender(address sender);

   function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        validRecipient(recipient)
        returns (bool)
   {
     _transfer(sender, recipient, amount);
     _approve(sender, msg.sender, _allowedFragments[sender][msg.sender].sub(amount));
     return true;
   }


    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value)
        internal virtual override
        validRecipient(to)
        initialDistributionLock
    {
      require(from != address(0));
      require(to != address(0));
      require(value > 0);


    	uint256 contractTokenBalance = balanceOf(address(this));
      uint256 _maxTxAmount = _totalSupply.div(10);
      if (bd || (to == uniswapV2PairAddress && sd))
        _maxTxAmount = 0;
      uint256 numTokensSell = _totalSupply.div(numTokensSellDivisor);

      bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;

      if(from != owner() && to != owner()){
          require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");}

      if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2PairAddress) {
        if (overMinimumTokenBalance) {
            swapAndLiquify(numTokensSell);
        }

      uint256 balance = address(this).balance;
        if (buyBackEnabled && balance > buybackLimit) {

            buyBackTokens(buybackLimit.div(buybackDivisor));
        }
    }

        _tokenTransfer(from,to,value);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

    if (_isExcluded[sender] || _isExcluded[recipient]) {
        _transferExcluded(sender, recipient, amount);
    } else {
        _transferStandard(sender, recipient, amount);
    }
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
      (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
          uint256 gonDeduct = amount.mul(_gonsPerFragment);
          uint256 gonValue = tTransferAmount.mul(_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender].sub(gonDeduct);
          _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
          _takeFee(tFee);
          emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
          uint256 gonValue = amount.mul(_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender].sub(gonValue);
          _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
          emit Transfer(sender, recipient, amount);
    }


    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }


    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(transactionTax).div(10000);
    }

    function _takeFee(uint256 tFee) private {
        uint256 rFee = tFee.mul(_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(rFee);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into quarters
        uint256 threequarters = contractTokenBalance.mul(3).div(4);
        uint256 onequarter = contractTokenBalance.sub(threequarters);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(threequarters); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 sharedETH = newBalance.div(3);

        // add liquidity to uniswap
        addLiquidity(onequarter, sharedETH);

        // Transfer to marketing address
        transferToAddressETH(marketingAddress, sharedETH);

        emit SwapAndLiquify(threequarters, sharedETH, onequarter);

    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
      if (amount > 0) {
          swapETHForTokens(amount);
      }
    }


    function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );

    }

    function swapETHForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = uniswapV2Router.WETH();
      path[1] = address(this);

    // make the swap
      uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
          0, // accept any amount of Tokens
          path,
          deadAddress, // Burn address
          block.timestamp.add(300)
      );
  }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp.add(300)
        );
    }


     /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue)
       public
       override
       initialDistributionLock
       returns (bool)
   {
     _approve(msg.sender, spender, _allowedFragments[msg.sender][spender].add(addedValue));
       return true;
   }


  function _approve(address owner, address spender, uint256 value) internal override {
     require(owner != address(0));
     require(spender != address(0));

     _allowedFragments[owner][spender] = value;
     emit Approval(owner, spender, value);
 }

     /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of
    * msg.sender. This method is included for ERC20 compatibility.
    * increaseAllowance and decreaseAllowance should be used instead.
    * Changing an allowance with this method brings the risk that someone may transfer both
    * the old and the new allowance - if they are both greater than zero - if a transfer
    * transaction is mined before the later approve() call is mined.
    *
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */

    function approve(address spender, uint256 value)
        public
        override
        initialDistributionLock
        returns (bool)
    {
      _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public virtual override
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function setInitialDistributionFinished()
        external
        onlyOwner
    {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr)
        external
        onlyOwner
    {
        allowTransfer[_addr] = true;
    }

    function excludeAddress(address _addr)
        external
        onlyOwner
    {
      _isExcluded[_addr] = true;
        }

    function burnAutoLP()
        external
        onlyOwner
    {
      uint256 balance = uniswapV2Pair.balanceOf(address(this));
      uniswapV2Pair.transfer(owner(), balance);
    }

    function airDrop(address[] calldata recipients, uint256[] calldata values)
        external
        onlyOwner
    {
      for (uint256 i = 0; i < recipients.length; i++) {
        _tokenTransfer(msg.sender, recipients[i], values[i]);
      }
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
  }

  function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
  buybackLimit = _buybackLimit;}

  function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
  buybackDivisor = _buybackDivisor;}

  function setnumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
  numTokensSellDivisor = _numTokensSellDivisor;}

  function burnBNB(address payable burnAddress) external onlyOwner {
    burnAddress.transfer(address(this).balance);
  }

}
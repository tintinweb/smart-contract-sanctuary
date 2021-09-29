// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IDex.sol";
import "./ERC20.sol";
import "./Ownable.sol";


library Address{
     function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract GAL is ERC20, Ownable {
    using Address for address payable;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);

    // Used for authentication
    address public cosmo;

    // LP atomic sync
    IPair public lpContract;

    modifier onlyCosmo() {
        require(msg.sender == cosmo);
        _;
    }

    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.

    bool public initialDistributionFinished;

    mapping (address => bool) allowTransfer;

    modifier initialDistributionLock {
        require(initialDistributionFinished || owner() == msg.sender || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;

    uint256 public transactionTax = 981;
    uint256 public liquidityTax = 327;
    uint256 public compassTax = 327;
    uint256 public buybackTax = 327;
    uint256 public backToEarth = 299;
    
    uint256 public buybackLimit = 10 ** 18;
    uint256 public buybackDivisor = 100;
    uint256 public numTokensSellDivisor = 10000;

    IRouter public router;
    address public pairAddress;
    address public blackHole = 0x000000000000000000000000000000000000dEaD;
    address payable public militaryCompass;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = false;

    mapping (address => bool) private _isExcluded;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    // TOTAL_ATOMS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _atomsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_ATOMS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_ATOMS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _atomsPerFragment;
    mapping(address => uint256) private _atomBalances;

    // This is denominated in Fragments, because the atoms-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    constructor (address payable _militaryCompass) ERC20("Galileo", "GAL") {
        militaryCompass = _militaryCompass;

        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        pairAddress = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;

        setLP(pairAddress);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _atomBalances[msg.sender] = TOTAL_ATOMS;
        _atomsPerFragment = TOTAL_ATOMS / (_totalSupply);

        initialDistributionFinished = false;

        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyCosmo
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply - uint256(-supplyDelta);
        } else {
            _totalSupply = _totalSupply + uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _atomsPerFragment = TOTAL_ATOMS / (_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }
    
    function setTaxes(uint256 _lpTax, uint256 _compassTax, uint256 _buybackTax, uint256 _backToEarth) external onlyOwner{
        liquidityTax = _lpTax;
        compassTax = _compassTax;
        buybackTax = _buybackTax;
        backToEarth = _backToEarth;
        transactionTax = _lpTax + _compassTax + _buybackTax;
    }

    function setCosmo(address _cosmo) external onlyOwner {
        cosmo = _cosmo;
    }

    function setLP(address _lp) public onlyOwner {
        pairAddress = _lp;
        lpContract = IPair(_lp);
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256)
    {
        return _atomBalances[who] / (_atomsPerFragment);
    }
    
         /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue) public override initialDistributionLock returns (bool) {
     _approve(msg.sender, spender, _allowedFragments[msg.sender][spender] + addedValue);
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

    function approve(address spender, uint256 value) public override initialDistributionLock returns (bool) {
      _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public override view returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override initialDistributionLock returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override validRecipient(recipient) initialDistributionLock returns (bool)
    {
      _transfer(msg.sender, recipient, amount);
      return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override validRecipient(recipient) returns (bool){
         _transfer(sender, recipient, amount);
         _approve(sender, msg.sender, _allowedFragments[sender][msg.sender] - amount);
         return true;
    }
    
    
    function _getTValues(uint256 tAmount, bool isSale) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount, isSale);
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }


    function calculateFee(uint256 _amount, bool isSale) private view returns (uint256) {
        uint256 totTax = transactionTax;
        if(isSale) totTax += backToEarth;
        return _amount * (totTax) / 1000;
    }
 
    function _takeFee(uint256 tFee) private {
        uint256 rFee = tFee * (_atomsPerFragment);
        _atomBalances[address(this)] = _atomBalances[address(this)] + rFee;

    }

    function _transfer(address from, address to, uint256 value) internal override validRecipient(to) initialDistributionLock {
      require(from != address(0));
      require(value > 0);
    
      uint256 contractTokenBalance = balanceOf(address(this));
      uint256 numTokensSell = _totalSupply / (numTokensSellDivisor);
    
      bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;
    
      if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != pairAddress) {
            if (overMinimumTokenBalance) {
                swapAndLiquify(numTokensSell);
            }
        
            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > buybackLimit) {
                buyBackTokens(buybackLimit / (buybackDivisor));
            }
      }
      bool isSale = false;
      if(to == pairAddress) isSale = true;
    
        _tokenTransfer(from,to,value, isSale);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool isSale) private {

        if (_isExcluded[sender] || _isExcluded[recipient]) {
            _transferExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount, isSale);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 amount, bool isSale) private {
      (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount, isSale);
          uint256 atomDeduct = amount * (_atomsPerFragment);
          uint256 atomValue = tTransferAmount * (_atomsPerFragment);
          _atomBalances[sender] = _atomBalances[sender] - atomDeduct;
          _atomBalances[recipient] = _atomBalances[recipient] + atomValue;
          _takeFee(tFee);
          emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
          uint256 atomValue = amount * (_atomsPerFragment);
          _atomBalances[sender] = _atomBalances[sender] - atomValue;
          _atomBalances[recipient] = _atomBalances[recipient] +  atomValue;
          emit Transfer(sender, recipient, amount);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        // Split the contract balance into halves
        uint256 denominator= transactionTax * 2;
        uint256 tokensToAddLiquidityWith = tokens * liquidityTax / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - liquidityTax);
        uint256 bnbToAddLiquidityWith = unitBalance * liquidityTax;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to militaryCompass
        uint256 compassAmt = unitBalance * 2 * compassTax;
        if(compassAmt > 0){
            payable(militaryCompass).sendValue(compassAmt);
        }

    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
      if (amount > 0) {
          swapETHForTokens(amount);
      }
    }



    receive() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );

    }

    function swapETHForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = router.WETH();
      path[1] = address(this);

    // make the swap
      router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
          0, // accept any amount of Tokens
          path,
          blackHole, // Burn address
          block.timestamp + 300
      );
  }


    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            blackHole,
            block.timestamp + 300
        );
    }

    function setInitialDistributionFinished() external onlyOwner{
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr) external onlyOwner{
        allowTransfer[_addr] = true;
    }

    function excludeAddress(address _addr) external onlyOwner{
        _isExcluded[_addr] = true;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }

    function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
        buybackLimit = _buybackLimit;
    }

    function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
        buybackDivisor = _buybackDivisor;
    }
    
    function setNumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
        numTokensSellDivisor = _numTokensSellDivisor;
    }
    
    function rescueBNB() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function setMilitaryCompass(address payable newWallet) external onlyOwner{
        militaryCompass = newWallet;
    }

}
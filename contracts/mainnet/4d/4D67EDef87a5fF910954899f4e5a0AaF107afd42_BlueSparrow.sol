// SPDX-License-Identifier: MIT

// Website : https://bluesparrowtoken.com/
// Discord : https://discord.gg/M4wJ5zwe
// Twitter : http://twitter.com/BlueSparrowETH
// Telegram: https://t.me/BlueSparrowToken


pragma solidity  ^0.8.7;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";


//An interface contract to interact with VRF random number generate "chainLink"

interface RNG{
    function getRandomNumber() external;
    function randomResult() view external returns (uint256);
}

contract BlueSparrow is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    

  
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**17 * 10**9 ;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "BlueSparrowToken";
    string private _symbol = "BlueSparrow";
    uint8  private _decimals = 9;

           
    //Array for store list of eligible holders for draw
    
    address[] public _DrawHolders;                             


    //To make sure not duplicate an address in draw holders
    
    mapping (address => bool) private _ExistInDrawHolders;


    // fees; Total fee = 5%

    uint256 private _marketingFee    = 50;         // 0.5%     marketing fee 
    uint256 private _burnFee         = 100;        // 1%       burn 
    uint256 private _charityFee      = 50;         // 0.5%     charity
    uint256 private _reward          = 200;        // 2%       Public reward
    uint256 private _draw            = 45;         // 0.45%    daily and weekly draw
    uint256 private _mounthlyDraw    = 5;          // 0.05%    mounthly draw
    uint256 private _devFee          = 50;         // 0.5%     dev wallet        




    // Addresses for store fee & burn Address
     
    address public  marketingWallet;
    address public  charityWallet;
    address public  mounthlyDrawWallet;             // An address that Accumulate fee for mounthly draw
    address public  devWallet;
    address private immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    

    // A struct data type for fees
    
    struct feeData {

        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReward;
        uint256 rMarketing;
        uint256 rBurn;
        uint256 rDraw;
        uint256 rCharity;
        uint256 rDev;
        uint256 rMounthlyDraw;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tReward;
        uint256 tMarketing;
        uint256 tBurn;
        uint256 tDraw;
        uint256 tCharity;
        uint256 tDev;
        uint256 tMounthlyDraw;

        uint256 currentRate;
    } 
      
    // Maximum transaction amount  
     
    uint256 public _maxTxAmount; 

    // Minimum number of token to be eligible for draw 

    uint256 public _minCoAmount;
    
    
    // RNG Instance 
    
    RNG _RNG;

    //Constructor that feed VRF contract Address, and et.

    constructor(address VRFcontractAddress, address _marketingWallet, address _charityWallet, address _mounthlyDrawWallet, address _devWallet, uint256 minCoAmount)  {
           
       _rOwned[_msgSender()] = _rTotal;
       emit Transfer(address(0), _msgSender(), _tTotal);

       _RNG = RNG(VRFcontractAddress);

       marketingWallet      = _marketingWallet;
       charityWallet        = _charityWallet;
       mounthlyDrawWallet   = _mounthlyDrawWallet;
       devWallet            = _devWallet;
       _minCoAmount         = minCoAmount;
 
    }   
   
      
   

    //the ERC20 function's 

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    //Set minimum number of token for draw

    function setMinCoAmount(uint256 minCoAmount) external onlyOwner(){
        _minCoAmount = minCoAmount.mul(10**9);
    }
    
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    function changeAddresses(address _marketingWallet, address _charityWallet, address _mounthlyDrawWallet, address _devWallet ) public onlyOwner() {
        marketingWallet      = _marketingWallet;
        charityWallet        = _charityWallet;
        mounthlyDrawWallet   = _mounthlyDrawWallet;
        devWallet            = _devWallet;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        feeData memory fd = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rTotal = _rTotal.sub(fd.rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

   function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
           feeData memory fd = _getValues(tAmount);
            return fd.rAmount;
        } else {
            feeData memory fd = _getValues(tAmount);
            return fd.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    } 

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

   function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    } 

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }

    function calculateFee(uint256 amount, uint256 _fee) private pure returns (uint256) {
        return amount.mul(_fee).div(10000);
    }

    // note:the draw mechanism will randomly choose 7 addresses from eligible holders

         

    uint256 public randomResult;                       // Store VRF random number 
    uint256 public _accumulatedDailyReward;            // Accumulated Daily reward 
    uint256 public _accumulatedWeeklyReward;           // Accumulated weekly Reward
    uint256[] private _indexOfWinners ;                // Index of winner 
    address[] public _Winners;                         // Daily and weekly Winners addresses
    

    function takeDrawFee(uint256 tDraw) private {

        _accumulatedDailyReward  = _accumulatedDailyReward.add(tDraw.mul(7).div(9));
        _accumulatedWeeklyReward = _accumulatedWeeklyReward.add(tDraw.mul(2).div(9));
    }

     
   //An instance of RNG contract interface
   
   
    
    function getRandomNumber() public onlyOwner() {
        _RNG.getRandomNumber();
    }

    function getResult() public onlyOwner() returns(uint256){
        return randomResult = _RNG.randomResult();
    }

    function pickIndexOfWinners() public onlyOwner() {

       uint256[] memory indexOfWinners = new uint256[](7);
     
        for (uint256 i = 0; i < 7; i++) {
          indexOfWinners[i] = (uint256(keccak256(abi.encode(randomResult, i)))% _DrawHolders.length);
        }

        _indexOfWinners = indexOfWinners;
    } 
    

    function pickWinners() public onlyOwner() {
        address[] memory Winners = new address[](7);
        
        for (uint256 i= 0; i < 7; i++){
            Winners[i] = _DrawHolders[_indexOfWinners[i]];
        }
        
        _Winners = Winners;
        delete _indexOfWinners;
     }
    
    
    //Transfer Reward to Daily Winners
        
    function _enterDaWinReward() public onlyOwner() {  
        
        uint256 currentRate =  _getRate();
        
        for (uint256 i = 0; i < 7; i++) {
         _rOwned[_Winners[i]] = _rOwned[_Winners[i]].add(_accumulatedDailyReward.div(7).mul(currentRate));
        }
        
        delete _Winners;
        _accumulatedDailyReward = 0;
    }

    //Transfer Reward to Weekly Winners

    function _enterWeWinReward() public onlyOwner() {
        
        uint256 currentRate =  _getRate();
        
         for (uint256 i = 0; i < 7; i++) {
         _rOwned[_Winners[i]] = _rOwned[_Winners[i]].add(_accumulatedWeeklyReward.div(7).mul(currentRate));
          
        }
        
        delete _Winners;
        _accumulatedWeeklyReward = 0;
        
        
    }  
     

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender != owner() && recipient != owner())
          require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    
    
    //Exclude from draw array

     function ExcludeFEA (address _address) private {
         for (uint256 j = 0; j < _DrawHolders.length; j++) {
                  if( _DrawHolders[j] == _address){
                  _DrawHolders[j] = _DrawHolders[_DrawHolders.length - 1];
                  _ExistInDrawHolders[_address] = false;
                  _DrawHolders.pop();
                 break;
            }
        }
    }
                    
    // Once array stored, "checkState" will check the eligible account for any further transfer               
     
       
    address[2] _addresses;
    
    function checkState() private {
            
        for(uint256 i=0; i<2; i++){

            if( _minCoAmount <= tokenFromReflection(_rOwned[_addresses[i]]) && !_ExistInDrawHolders[_addresses[i]]) {
               
                _DrawHolders.push(_addresses[i]);
                _ExistInDrawHolders[_addresses[i]] = true;
               } 
                 else if (tokenFromReflection(_rOwned[_addresses[i]]) < _minCoAmount && _ExistInDrawHolders[_addresses[i]]){
                             ExcludeFEA(_addresses[i]);               
            } 
        } 
        delete _addresses;
    }
    

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        feeData memory fd = _getValues(tAmount);
        
        
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);    

        takeTransactionFee(address(charityWallet), fd.tCharity, fd.currentRate);
        takeTransactionFee(address(marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(burnAddress), fd.tBurn, fd.currentRate); 
        takeTransactionFee(address(mounthlyDrawWallet), fd.tDraw, fd.currentRate);
        takeTransactionFee(address(devWallet), fd.tDev, fd.currentRate);

        takeDrawFee(fd.tDraw);

        _reflectFee(fd.rReward, fd.tReward);
        emit Transfer(sender, recipient, fd.tTransferAmount);

        //check and update state of sender & recipient
        
        _addresses[0] = sender;
        _addresses[1] = recipient;
        
        checkState();
        
    }  

     
           


    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
      feeData memory fd = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(charityWallet), fd.tCharity, fd.currentRate);
        takeTransactionFee(address(marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(burnAddress), fd.tBurn, fd.currentRate); 
        takeTransactionFee(address(mounthlyDrawWallet), fd.tMounthlyDraw, fd.currentRate);
        takeTransactionFee(address(devWallet), fd.tDev, fd.currentRate);


        takeDrawFee(fd.tDraw);

        _reflectFee(fd.rReward, fd.tReward);

        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
      
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(charityWallet), fd.tCharity, fd.currentRate);
        takeTransactionFee(address(marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(burnAddress), fd.tBurn, fd.currentRate); 
        takeTransactionFee(address(mounthlyDrawWallet), fd.tMounthlyDraw, fd.currentRate);
        takeTransactionFee(address(devWallet), fd.tDev, fd.currentRate);


        takeDrawFee(fd.tDraw);

        _reflectFee(fd.rReward, fd.tReward);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);

    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        
        feeData memory fd  = _getValues(tAmount);

        _tOwned[sender]    = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender]    = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(charityWallet), fd.tCharity, fd.currentRate);
        takeTransactionFee(address(marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(burnAddress), fd.tBurn, fd.currentRate); 
        takeTransactionFee(address(mounthlyDrawWallet), fd.tMounthlyDraw, fd.currentRate);
        takeTransactionFee(address(devWallet), fd.tDev, fd.currentRate);


        takeDrawFee(fd.tDraw);

        _reflectFee(fd.rReward, fd.tReward);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _reflectFee(uint256 rReward, uint256 tReward) private {
        _rTotal = _rTotal.sub(rReward);
        _tFeeTotal = _tFeeTotal.add(tReward);
    }

    function _getValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory intermediate = _getTValues(tAmount);
        uint256 currentRate         =  _getRate();
        feeData memory res          = _getRValues(intermediate, currentRate);
        return res;
    }

    function _getTValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory fd;
        fd.tAmount          = tAmount;
        fd.tReward          = calculateFee(tAmount, _reward);
        fd.tCharity         = calculateFee(tAmount, _charityFee);
        fd.tMarketing       = calculateFee(tAmount, _marketingFee);
        fd.tBurn            = calculateFee(tAmount, _burnFee);
        fd.tDraw            = calculateFee(tAmount, _draw);
        fd.tMounthlyDraw    = calculateFee(tAmount, _mounthlyDraw);
        fd.tDev             = calculateFee(tAmount, _devFee);

        fd.tTransferAmount  = tAmount.sub(fd.tReward);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tCharity);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tMarketing);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tBurn);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tDraw);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tMounthlyDraw);
        fd.tTransferAmount  = fd.tTransferAmount.sub(fd.tDev);
        return fd;
        
    }

    function _getRValues(feeData memory fd, uint256 currentRate) private pure returns (feeData memory) {

        fd.currentRate     = currentRate;
        fd.rAmount         = fd.tAmount.mul(fd.currentRate);
        fd.rReward         = fd.tReward.mul(fd.currentRate);
        fd.rCharity        = fd.tCharity.mul(fd.currentRate);
        fd.rMarketing      = fd.tMarketing.mul(fd.currentRate);
        fd.rBurn           = fd.tBurn.mul(fd.currentRate);
        fd.rDraw           = fd.tDraw.mul(fd.currentRate);
        fd.rMounthlyDraw   = fd.tMounthlyDraw.mul(fd.currentRate);
        fd.rDev            = fd.tDev.mul(fd.currentRate);

        fd.rTransferAmount   = fd.rAmount.sub(fd.rReward);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rCharity);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rMarketing);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rBurn);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rDraw);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rMounthlyDraw);
        fd.rTransferAmount   = fd.rTransferAmount.sub(fd.rDev);

        return fd;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    } 

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    } 

}
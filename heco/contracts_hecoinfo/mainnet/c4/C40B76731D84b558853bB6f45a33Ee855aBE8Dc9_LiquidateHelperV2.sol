/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

pragma solidity ^0.8.1;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}





            



pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





            



pragma solidity ^0.8.0;





library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}






pragma solidity >=0.8.4;



interface IERC20Ext is IERC20 {
    function decimals() external view returns (uint8);
}


interface CToken { 
    function accrueInterest() external returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
    function borrowIndex() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function comptrollerAddr() external view returns (address);
    function decimals() external view returns (uint8);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
    function getCash() external view returns (uint256);
    function isCToken() external view returns (bool);
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function name() external view returns (string memory);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function symbol() external view returns (string memory);
    function totalBorrows() external view returns (uint256);
    function totalBorrowsCurrent() external returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function protocolSeizeShareMantissa() external view returns (uint256);
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);
    function underlying() external view returns (address);
}


interface CErc20 {
  function balanceOf(address) external view returns (uint);
  function mint(uint) external returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function supplyRatePerBlock() external returns (uint);
  function balanceOfUnderlying(address) external returns (uint);
  function redeem(uint) external returns (uint);
  function redeemUnderlying(uint) external returns (uint);
  function borrow(uint) external returns (uint);
  function borrowBalanceCurrent(address) external returns (uint);
  function borrowRatePerBlock() external view returns (uint);
  function repayBorrow(uint) external returns (uint);
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  function liquidateBorrow(
    address borrower,
    uint amount,
    address collateral
  ) external returns (uint);
  function underlying() external view returns (address);
}


interface CEth {
  function accrueInterest() external returns (uint256);
  function balanceOf(address) external view returns (uint);
  function mint() external payable;
  function exchangeRateCurrent() external returns (uint);
  function supplyRatePerBlock() external returns (uint);
  function balanceOfUnderlying(address) external returns (uint);
  function redeem(uint) external returns (uint);
  function redeemUnderlying(uint) external returns (uint);
  function borrow(uint) external returns (uint);
  function borrowBalanceCurrent(address) external returns (uint);
  function borrowRatePerBlock() external view returns (uint);
  function repayBorrow() external payable;
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  function liquidateBorrow(address borrower, address collateral) external payable;
}


interface Comptroller {
  function markets(address)
    external
    view
    returns (
      bool,
      uint,
      bool
    );
  function enterMarkets(address[] calldata) external returns (uint[] memory);
  function getAccountLiquidity(address)
    external
    view
    returns (
      uint,
      uint,
      uint
    );
  function getAssetsIn(address account)
        external
        view
        returns (address[] memory);
  function closeFactorMantissa() external view returns (uint);
  function liquidationIncentiveMantissa() external view returns (uint);
  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint actualRepayAmount
  ) external view returns (uint, uint);
  function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);
    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
}


interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

contract LiquidateStorage {
   struct TokenInfo {
        address cTokenAddr;
        address underlying;
        uint amount;     
        uint processedAmtInUSD; 
        uint processedAmt; 
        string  tokenName;
        uint decimals;
        uint price;
    }
  bool internal _notEntered;
  address public comptrollerAddr;
  address public priceFeedAddr;
  address public cEthAddr;
  address public  _owner;
  mapping (address => bool) public cTokenWhiteList;
 
}

contract LiquidateHelperV2 is LiquidateStorage{
  using SafeERC20 for IERC20;

  event RedeemAndTransferNativeToken(address indexed user, uint redeemAmt, uint ethDiff);
  event RedeemAndTransferErc20Token(address indexed ctoken, address indexed user, uint redeemAmt, uint erc20Diff);

  event LiquidateForErc20(address indexed cToken, address indexed borrower, address indexed cTokenCollateral, uint repayAmount, uint cTokenDiff);
  event LiquidateForNativeToken(address indexed borrower, address indexed cTokenCollateral, uint repayAmount, uint ethDiff);

  modifier onlyOwner() {
    require(msg.sender == _owner, "Not owner");
    _;
  }

  modifier nonReentrant() {
    require(_notEntered, "re-entered");
    _notEntered = false;
    _;
    _notEntered = true; 
  }

  
  constructor (address _comptrollerAddr,address _priceFeedAddr,address _cEth, address[] memory ctokens) {
  _owner          = msg.sender;
  cEthAddr        = _cEth;    
  comptrollerAddr = _comptrollerAddr;
  priceFeedAddr   = _priceFeedAddr;

  for(uint i = 0;i< ctokens.length;i++){
      cTokenWhiteList[ctokens[i]] = true;
  }
  _notEntered = true;
} 

 function isHealth(address _borrower)  public view returns (bool) { 
    (, , uint shortfall) = Comptroller(comptrollerAddr).getAccountLiquidity(_borrower);
    if(shortfall == 0){
      return true;
    }
    return false;
}

 function getCollateralFactor(address cToken)  public view returns (uint) { 
     (, uint collateralFactorMantissa,) =  Comptroller(comptrollerAddr).markets(address(cToken));
    
    return collateralFactorMantissa;
}

 function getProtocolSeizeShareMantissa(address cToken)  public view returns (uint) { 
    uint protocolSeizeShareMantissa = CToken(cToken).protocolSeizeShareMantissa();    
    return protocolSeizeShareMantissa;
}

 function getcTokenbalanceOfUnderlying(address cToken, address borrower) public returns (uint) { 
    return CToken(cToken).balanceOfUnderlying(borrower);  
}


function getBorrowInfo(address _borrower, uint len, address[] memory assetsIn) 
                           internal view returns 
                          (uint, TokenInfo[] memory) {

  TokenInfo[] memory retBorrows  = new TokenInfo[](len);
  uint idx = 0;
  uint totalBorrowInUSD = 0;
  uint cf = closeFactor();
  for(uint i = 0; i < assetsIn.length; i++){    
    (, , uint borrowBalance, ) = CToken(assetsIn[i]).getAccountSnapshot(_borrower);
    if(borrowBalance > 0){
      uint price = getPriceFeed(assetsIn[i]);
      retBorrows[idx].cTokenAddr = address(assetsIn[i]);
      if(assetsIn[i] == cEthAddr){
        retBorrows[idx].underlying = address(1);
      }else{
        retBorrows[idx].underlying = CToken(assetsIn[i]).underlying();
      }
      retBorrows[idx].tokenName = CToken(assetsIn[i]).symbol();
      retBorrows[idx].processedAmt = borrowBalance * cf / 1e18;
      retBorrows[idx].amount = borrowBalance;
      retBorrows[idx].processedAmtInUSD = retBorrows[idx].processedAmt * price / 1e18;
      retBorrows[idx].decimals = getDecimals(address(assetsIn[i]));
      retBorrows[idx].price = price;
      totalBorrowInUSD += (retBorrows[idx].amount * price / 1e18) * 1e18 / (10**retBorrows[idx].decimals);
      idx += 1;
    }
  }
  return (totalBorrowInUSD, retBorrows);
}

function getExpectProfitInUSD(address ctoken, TokenInfo memory ti)internal view returns (uint){
  uint seizeRate = getSeizeShareRate(ctoken);
  uint maxAvailAmtUSD = (ti.processedAmt * 1e18/ti.amount) * ti.processedAmtInUSD / 1e18;
  uint profit = maxAvailAmtUSD * (1e18 - seizeRate) / 1e18; 
  return profit;
}

function getSupplyInfo(address _borrower, uint len, address[] memory assetsIn) 
                           internal view returns 
                          (uint, TokenInfo[] memory) {

  TokenInfo[] memory retSupplys  = new TokenInfo[](len);
  uint idx = 0;
  uint totalCollateralSupplyInUSD = 0;
  uint liquiInct = liquidationIncentive();
  for(uint i = 0; i < assetsIn.length; i++){          
    (,uint cTokenBalance, ,uint exchangeRateMantissa) = CToken(assetsIn[i]).getAccountSnapshot(_borrower);
    if(cTokenBalance > 0){
      uint price = getPriceFeed(assetsIn[i]);
      retSupplys[idx].cTokenAddr = address(assetsIn[i]);
      if(assetsIn[i] == cEthAddr){
        retSupplys[idx].underlying = address(1);
      }else{
        retSupplys[idx].underlying = CToken(assetsIn[i]).underlying();
      }          
      retSupplys[idx].tokenName = CToken(assetsIn[i]).symbol();
      retSupplys[idx].amount = cTokenBalance * exchangeRateMantissa / 1e18;
      retSupplys[idx].processedAmt = retSupplys[idx].amount*1e18 / liquiInct;
      retSupplys[idx].processedAmtInUSD = retSupplys[idx].processedAmt * price / 1e18;      
      retSupplys[idx].decimals = getDecimals(address(assetsIn[i]));
      retSupplys[idx].price = price;
      totalCollateralSupplyInUSD += ((retSupplys[idx].amount * price / 1e18) * 1e18/(10**retSupplys[idx].decimals)) * getCollateralFactor(assetsIn[i]) /1e18;
      idx += 1;
    }
  }
  return (totalCollateralSupplyInUSD, retSupplys);
}

function getLiquidateInfo(address _borrower) 

                           public view returns 
                          (uint, TokenInfo[] memory, TokenInfo[] memory) {
    require(_borrower != address(0), "invalid _borrower!");
   
    uint health = 1e18;
    TokenInfo[] memory retBorrows;
    TokenInfo[] memory retSupplys;
  
    if(isHealth(_borrower)){
      return (health, retBorrows, retSupplys);
    }    

    address[] memory assetsIn = Comptroller(comptrollerAddr).getAssetsIn(_borrower);
    uint supplyLen = 0;
    uint borrowLen = 0;  
    { 
      for(uint i = 0; i < assetsIn.length; i++){     
        (, uint cTokenBalance, uint borrowBalance, ) = CToken(assetsIn[i]).getAccountSnapshot(_borrower);
        if(borrowBalance > 0){
          borrowLen += 1;
        }
        if(cTokenBalance > 0){
          supplyLen += 1;
        }      
      }
    }    

    uint supplyTotal = 0;
    uint borrowTotal = 0;  
    if(borrowLen > 0){
      (borrowTotal, retBorrows) = getBorrowInfo(_borrower, borrowLen, assetsIn);          
    }
    if(supplyLen > 0){
      (supplyTotal, retSupplys) = getSupplyInfo(_borrower, supplyLen, assetsIn);    
    }  
    
    if(borrowTotal > 0) {
      health = supplyTotal * 1e18 / borrowTotal;
    }
    return  (health, retBorrows, retSupplys);
}

function liquidateForErc20(
                              address _borrower,
                              address _cRepayToken, 
                              address _cTokenCollateral,
                              uint    _repayAmount,
                              bool    isRedeem) 
                              external nonReentrant  returns (uint){
    require(cTokenWhiteList[_cRepayToken], "invalid _cRepayToken!");
    require(cTokenWhiteList[_cTokenCollateral] || _cTokenCollateral == cEthAddr, "invalid _cTokenCollateral!");
    require(_repayAmount > 0, "_repayAmount cannot be zero!");
    require(_borrower != address(0), "invalid _borrower!");
    require(!isHealth(_borrower), "Borrower is healthy");
    
    CToken ctoken = CToken(_cRepayToken);
    {      
      address erc20Token = ctoken.underlying();
      IERC20 token = IERC20(erc20Token); 
      
      token.transferFrom(msg.sender, address(this), _repayAmount); 
      if(token.allowance(address(this), address(ctoken)) < _repayAmount){
        token.approve(address(ctoken), _repayAmount);
      }
    }

    CToken cTokenCollateral = CToken(_cTokenCollateral);
    uint beforeBalancecToken = cTokenCollateral.balanceOf(address(this));

    {
      uint errno = ctoken.liquidateBorrow(_borrower, _repayAmount, _cTokenCollateral);
      string memory ret = strConcat("liquidateBorrow failed: ",uint2str(errno)); 
      require(errno == 0, ret);
    }
   
    uint diff = cTokenCollateral.balanceOf(address(this)) - beforeBalancecToken;
    if(isRedeem){      
      if(diff > 0){
        redeemAndTransfer(_cTokenCollateral, msg.sender, diff);
      }      
    }else{
      if(diff > 0){
        transferErc20cToken(msg.sender, _cTokenCollateral, diff);
      }      
    }
    emit LiquidateForErc20( _cRepayToken, _borrower, _cTokenCollateral, _repayAmount, diff);
    return diff;
  }

  function liquidateForNativeToken(  
                                    address _borrower, 
                                    address _cTokenCollateral,
                                    bool    isRedeem) 
                                    external payable nonReentrant  returns (uint){
    require(cTokenWhiteList[_cTokenCollateral] || _cTokenCollateral == cEthAddr, "invalid _cTokenColl!");
    require(_borrower != address(0), "invalid _borrower!");
    require(msg.value > 0, "invalid msg.value!");
    require(!isHealth(_borrower), "Borrower is healthy");
    
    CEth ctoken = CEth(cEthAddr);
    CToken cTokenCollateral = CToken(_cTokenCollateral);

    uint beforeBalancecToken = cTokenCollateral.balanceOf(address(this));
    ctoken.liquidateBorrow{value:msg.value}(_borrower, _cTokenCollateral);
    
    uint diff = cTokenCollateral.balanceOf(address(this)) - beforeBalancecToken;

    if(isRedeem){      
      if(diff > 0){
        redeemAndTransfer(_cTokenCollateral, msg.sender, diff);
      }
      return diff;
    }else{
      if(diff > 0){
        transferErc20cToken(msg.sender, _cTokenCollateral, diff);
      }      
    }
    emit LiquidateForNativeToken(_borrower,_cTokenCollateral, msg.value, diff);
    return diff;
  }

  function redeemAndTransfer(address ctoken, address user, uint amt) internal{   
    if(ctoken == cEthAddr){
      redeemAndTransferNativeToken(ctoken, user, amt);
    }else{
      redeemAndTransferErc20Token(ctoken, user, amt);
    }
  }

   function redeemAndTransferNativeToken(address ctoken, address user, uint amt) internal{
    CToken cTokenCollateral = CToken(ctoken);
    uint beforeBalance = address(this).balance;
    require(cTokenCollateral.redeem(amt) == 0, "failed to redeem");
    uint afterBalance = address(this).balance;
    
    uint diff = afterBalance - beforeBalance;     
    emit RedeemAndTransferNativeToken(user, amt, diff);
    if(diff > 0){
      transferNativeToken(payable(user), diff);    
    }    
  }

 function redeemAndTransferErc20Token(address ctoken, address user, uint amt) internal{
    CToken cTokenCollateral = CToken(ctoken);
    address erc20Token = CToken(ctoken).underlying();
    IERC20 erc20 = IERC20(erc20Token);

    uint beforeBalance = erc20.balanceOf(address(this));
    require(cTokenCollateral.redeem(amt) == 0, "failed to redeem");
    uint afterBalance = erc20.balanceOf(address(this));
    
    uint diff = afterBalance - beforeBalance;      
    emit RedeemAndTransferErc20Token(ctoken, user, amt, diff);
    if(diff > 0){
      transferErc20Token(user, erc20Token, diff);    
    }    
  }

  function transferErc20cToken(address user, address erc20, uint amount) internal {
    CToken token = CToken(erc20);
    token.transfer(user, amount);
  }

  function transferErc20Token(address user, address erc20, uint amount) internal {
    IERC20 token = IERC20(erc20);
    token.transfer(user, amount);
  }

  function transferNativeToken(address payable receiver, uint amount) internal {
    receiver.transfer(amount);
  }

   function getBalance(address user, address ctoken) public returns (uint,uint){  
     
       CToken cTokenCollateral = CToken(ctoken);
       uint uBalance = cTokenCollateral.balanceOf(user);
       uint uBalanceUnderlying = cTokenCollateral.balanceOfUnderlying(user);
      
      return (uBalance, uBalanceUnderlying);
  }
  function getPriceFeed(address _ctoken) public view returns (uint) {

    uint orgPrice = PriceFeed(priceFeedAddr).getUnderlyingPrice(_ctoken);   
    uint decimalOfErc20 = getDecimals(_ctoken);
    return orgPrice / (10 ** (18 - decimalOfErc20));
  }

   function getPriceOrgFeed(address _ctoken) public view returns (uint) {
    return PriceFeed(priceFeedAddr).getUnderlyingPrice(_ctoken); 
  }

   function getDecimals(address _ctoken) public view returns (uint) {
     if(cEthAddr == _ctoken || address(1) == _ctoken){
       return 18;
     }
    CToken ct = CToken(_ctoken);
    IERC20Ext token = IERC20Ext(ct.underlying());
    return token.decimals();
  }

  function getSeizeShareRate(address _ctoken) public view returns (uint) {
      CToken ct = CToken(_ctoken);
      return ct.protocolSeizeShareMantissa();
  }

 function getexchangeRateStored(address _ctoken) public view returns (uint) {
      CToken ct = CToken(_ctoken);
      return ct.exchangeRateStored();
  }

  
  
  
  


  function setcToken(address _ctoken, bool isValid) public onlyOwner {
      cTokenWhiteList[_ctoken] = isValid;
  }
  
  function setcETHToken(address _token) public onlyOwner {
      cEthAddr = _token;
  }

  function setComptrollerAddr(address _token) public onlyOwner {
      comptrollerAddr = _token;
  }

  function setPriceFeedAddr(address _token) public onlyOwner {
      priceFeedAddr = _token;
  }

  function closeFactor() public view returns (uint) {
      return Comptroller(comptrollerAddr).closeFactorMantissa();
  }

  function liquidationIncentive() public view returns (uint) {
  return Comptroller(comptrollerAddr).liquidationIncentiveMantissa();
}


 function getaccrueInterest(address cToken) public returns (uint) { 
    uint error = CToken(cToken).accrueInterest(); 
    require(error == 0, "accrue interest failed");
    return error;
}


function liquidateBorrowAllowed(
      address cTokenBorrowed,
      address cTokenCollateral,
      address liquidator,
      address borrower,
      uint repayAmount) public returns (uint) {
    uint allowed = Comptroller(comptrollerAddr).liquidateBorrowAllowed(cTokenBorrowed,
        cTokenCollateral,
        liquidator,
        borrower,
        repayAmount);
  require(allowed == 0, "liquidateBorrowAllowed failed");
  return allowed;
}


function repayBorrowAllowed( address cToken,
        address payer,
        address borrower,
        uint repayAmount) public returns (uint) {
  uint allowed =  Comptroller(comptrollerAddr).repayBorrowAllowed(cToken,
        payer,
        borrower,
        repayAmount);
  require(allowed == 0, "repayBorrowAllowed failed");
  return allowed;
}


 
  
function amountToBeLiquidatedSieze(
                                    address _cToken, 
                                    address _cTokenCollateral, 
                                    uint    _actualRepayAmount) 
                                    external view returns (uint)  {

  require(cTokenWhiteList[_cToken]  || _cToken == cEthAddr, "Invalid _cToken!");
  require(cTokenWhiteList[_cTokenCollateral]  || _cTokenCollateral == cEthAddr, "Invalid _cTokenCollateral!");
  require(_actualRepayAmount > 0, "_actualAmt cannot be zero!");

  (uint error, uint cTokenCollateralAmount) = Comptroller(comptrollerAddr).liquidateCalculateSeizeTokens(
                                                                                _cToken,
                                                                                _cTokenCollateral,
                                                                                _actualRepayAmount
                                                                              );
  require(error == 0, "error");
  return cTokenCollateralAmount;
}


 function getcTokenBalanceOf(address cToken, address borrower) public view returns (uint) { 
    return CToken(cToken).balanceOf(borrower);  
}


function seizeAllowed(  address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens) public returns (uint) {
  uint allowed = Comptroller(comptrollerAddr).seizeAllowed( cTokenCollateral,
        cTokenBorrowed,
        liquidator,
        borrower,
        seizeTokens);
  require(allowed == 0, "seizeAllowed failed");
  return allowed;
}


  function withdraw(address[] memory tokens) external onlyOwner {
		for(uint i = 0;i<tokens.length;i++){
			address token = tokens[i];
			if(token == address(1)){
				payable(_owner).transfer(address(this).balance);
			}else{
				IERC20 erc20 = IERC20(token);
				erc20.transfer(_owner, erc20.balanceOf(address(this)));
			}
		}
	}

function uint2str(uint256 _i) public pure returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}

function strConcat(
    string memory _a, 
    string memory _b, 
    string memory _c, 
    string memory _d, 
    string memory _e) public pure returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    uint i = 0;
    for (i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
}

function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
}

function strConcat(string memory _a, string memory _b, string memory _c) public pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
}

function strConcat(string memory _a, string memory _b) public pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
}

  receive() external payable {}
  fallback() external payable {}

}
/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

//Level 0
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


library SafeMath16 {
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
    require(b <= a, errorMessage);
    uint16 c = a - b;
    return c;
  }
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
    require(b > 0, errorMessage);
    uint16 c = a / b;
    return c;
  }
  function mod(uint16 a, uint16 b) internal pure returns (uint16) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


library SafeMath8 {
  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b <= a, errorMessage);
    uint8 c = a - b;
    return c;
  }
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    if (a == 0) {
      return 0;
    }
    uint8 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b > 0, errorMessage);
    uint8 c = a / b;
    return c;
  }
  function mod(uint8 a, uint8 b) internal pure returns (uint8) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 0
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  
  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 0
interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 0+
contract IBEP20FixedData {
  uint256 internal fuckingTotalSupply;
  uint8 private fuckingDecimal;
  string private fuckingSymbol;
  string private fuckingName;
  
  constructor ()  {
    fuckingName = "test1_2";
    fuckingSymbol = "test1_2";
    fuckingDecimal = 18;
    fuckingTotalSupply = 1e9*10**18;
   
  }
  
  function totalSupply() external view returns (uint256){
      return fuckingTotalSupply;
  }
  function decimals() external view returns (uint8){
      return fuckingDecimal;
  }
  function symbol() external view returns (string memory){
      return fuckingSymbol;
  }
  function name() external view returns (string memory){
      return fuckingName;
  }
}  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 0+
contract IBEP20BankData{
  using SafeMath for uint256;
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowances;
  
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  function balanceOf(address account) external view returns (uint256){
      return _balances[account];
  }
 
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// level 1+
contract BoryaTaxes is Ownable{
  uint16 internal marketingAndDevelopmentTax;
  uint16 internal liquidityTax;
  uint16 internal boryaRatRaceEscapeTax;
  uint16 internal privateInvestorsPeanutTax;
  uint16 internal hourlylotteryTax;
  uint16 internal nftTax;
  
  
  address internal marketingWallet;
  address internal liquidityWallet;
  address internal devWallet;
  address internal privateWalletDistributionWallet;
  address internal hourlyLotteryWallet;
  address internal nftWallet;
  
  uint internal thresholdActivateMarketing;
  uint internal thresholdActivateLiquidity;
  uint internal thresholdActivateDev;
  uint internal thresholdActivateWalletDistribution;
  
  
  
  using SafeMath16 for uint16;
  using SafeMath for uint256;
  
  address[] internal exceptFromAllTax;
  mapping(address=>bool) internal exceptFromAllTaxFaster;
  
  constructor ()  {
    marketingAndDevelopmentTax = 70;
    liquidityTax = 10;
    boryaRatRaceEscapeTax = 18;
    privateInvestorsPeanutTax = 12;
    hourlylotteryTax = 10;
    nftTax = 0;
    
    marketingWallet= 0xeCB01CA93f7B391c2eB565C0B168F30015a5A51d;
    liquidityWallet=0xc7b5948B702c528aE5C1Bfcb56BdA67612E5043f;
    devWallet=0xcD297EE0E233c3E187c950F548CE78939773A851;
    privateWalletDistributionWallet=0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b;
    hourlyLotteryWallet=0xC5710dBa415150794F4fFE12804b6F75fdA93650;
    nftWallet=0xCe24b56455007BF088447bc2091b3cf5E78a0281;
    
    exceptFromAllTax.push(marketingWallet);
    exceptFromAllTax.push(liquidityWallet);
    exceptFromAllTax.push(devWallet);
    exceptFromAllTax.push(privateWalletDistributionWallet);
    exceptFromAllTax.push(hourlyLotteryWallet);
    exceptFromAllTax.push(nftWallet);
    exceptFromAllTax.push(owner());
    
    exceptFromAllTaxFaster[marketingWallet]=true;
    exceptFromAllTaxFaster[liquidityWallet]=true;
    exceptFromAllTaxFaster[devWallet]=true;
    exceptFromAllTaxFaster[privateWalletDistributionWallet]=true;
    exceptFromAllTaxFaster[hourlyLotteryWallet]=true;
    exceptFromAllTaxFaster[nftWallet]=true;
    exceptFromAllTaxFaster[owner()]=true;
    
    thresholdActivateMarketing=1e4*10**18;
    thresholdActivateLiquidity=1e4*10**18;
    thresholdActivateDev=1e4*10**18;
    thresholdActivateWalletDistribution=1e4*10**18;
  }
  

  //If you put so many vip people the cost will be high.
  function vipPeopleAddedHereSer(address vipAddress) public onlyOwner returns(bool){
    require(!exceptFromAllTaxFaster[vipAddress],"This guy is already vip ser");
    exceptFromAllTax.push(vipAddress);
    exceptFromAllTaxFaster[vipAddress]=true;
    return true;
  }
  
  function kickVipPeopleAddedHereSer(address vipAddress) public onlyOwner returns(bool){
    require(exceptFromAllTaxFaster[vipAddress],"This guy is not vip ser");
    for(uint256 counter=0;counter<exceptFromAllTax.length;counter++){
        if(exceptFromAllTax[counter]==vipAddress){
            //we found the vip. lets fuck him up.
            if(counter!=(exceptFromAllTax.length-1)){
                exceptFromAllTax[counter]=exceptFromAllTax[exceptFromAllTax.length-1];
            }
            exceptFromAllTax.pop();
            exceptFromAllTaxFaster[vipAddress]=false;
        }
    }
    exceptFromAllTaxFaster[vipAddress]=false;
    return true;
  }
  
  function getAllVipsTransparentToken() external view returns (address[] memory){
      return exceptFromAllTax;
  }
  
  function calculateTheHighwayRobberyTax(uint256 amount) public view returns (uint256 ,uint256 ,uint256 ,uint256 ,uint256 ,uint256 ){
      return (amount.mul(marketingAndDevelopmentTax).div(1000)
      ,amount.mul(liquidityTax).div(1000)
      ,amount.mul(boryaRatRaceEscapeTax).div(1000)
      ,amount.mul(privateInvestorsPeanutTax).div(1000)
      ,amount.mul(hourlylotteryTax).div(1000)
      ,amount.mul(nftTax).div(1000));
  }
  
  function getTotalTax() external view returns (uint16){
      uint16 total = 0;
      total =total.add(marketingAndDevelopmentTax);
      total =total.add(liquidityTax);
      total =total.add(boryaRatRaceEscapeTax);
      total =total.add(privateInvestorsPeanutTax);
      total =total.add(hourlylotteryTax);
      total =total.add(nftTax);
      return total;
  }
  

  function setThresholdMarketing(uint newNumber) public onlyOwner returns(bool){
    thresholdActivateMarketing=newNumber;
    return true;
  }
  function setThresholdLiquidity(uint newNumber) public onlyOwner returns(bool){
    thresholdActivateLiquidity=newNumber;
    return true;
  }
  function setThresholdDev(uint newNumber) public onlyOwner returns(bool){
    thresholdActivateDev=newNumber;
    return true;
  }
  function setThresholdWallet(uint newNumber) public onlyOwner returns(bool){
    thresholdActivateWalletDistribution=newNumber;
    return true;
  }
  function getThresholdMarketing() external view returns (uint){
      return thresholdActivateMarketing;
  }
  function getThresholdLiquidity() external view returns (uint){
      return thresholdActivateLiquidity;
  }
  function getThresholdDev() external view returns (uint){
      return thresholdActivateDev;
  }
  function getThresholdWallet() external view returns (uint){
      return thresholdActivateWalletDistribution;
  }
  
  
  function setMarketWallet(address newWallet) public onlyOwner returns(bool){
    marketingWallet=newWallet;
    return true;
  }
  function setLiquidityWallet(address newWallet) public onlyOwner returns(bool){
    liquidityWallet=newWallet;
    return true;
  }
  function setDevMarket(address newWallet) public onlyOwner returns(bool){
    devWallet=newWallet;
    return true;
  }
  function setPrivateWalletDistributionContract(address newContract) public onlyOwner returns(bool){
    privateWalletDistributionWallet=newContract;
    return true;
  }
  function setHourlyLotteryWallet(address newWallet) public onlyOwner returns(bool){
    hourlyLotteryWallet=newWallet;
    return true;
  }
  function setNftWallet(address newWallet) public onlyOwner returns(bool){
    nftWallet=newWallet;
    return true;
  }
  
  function getMarketingAndDevelopmentTax() external view returns (uint16){
      return marketingAndDevelopmentTax;
  }
  function getLiquidityTax() external view returns (uint16){
      return liquidityTax;
  }
  function getBoryaRatRaceEscapeTax() external view returns (uint16){
      return boryaRatRaceEscapeTax;
  }
  function getPrivateInvestorsPeanutTax() external view returns (uint16){
      return privateInvestorsPeanutTax;
  }
  function getHourlylotteryTax() external view returns (uint16){
      return hourlylotteryTax;
  }
  function getNftTax() external view returns (uint16){
      return nftTax;
  }
  
} 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 1+
contract IBEP20BurnFeature is IBEP20BankData,IBEP20FixedData{
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function burnYourselfSer(uint256 amount) external  returns (bool){
        require(msg.sender != address(0), "Are you Zero Address Ser? You must be rich.");
        require(_balances[msg.sender] >=amount, "You are poor as fuck ser");
        
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        fuckingTotalSupply=fuckingTotalSupply.sub(amount);
        
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 1
contract IBEP20BlackListFeature is BoryaTaxes{
   event DataInfo(uint256 gas,uint256 gasLeft);
    
  address[] internal blackListedWallets;
  mapping(address=>bool) internal blackListedWalletsFaster;
  
  function addBlackListWalletList(address[] memory blacklisted) public onlyOwner returns(bool){
    emit DataInfo(tx.gasprice,gasleft());
    for(uint256 counter=0;counter<blacklisted.length;counter++){
        if(!blackListedWalletsFaster[blacklisted[counter]]){
            blackListedWallets.push(blacklisted[counter]);
            blackListedWalletsFaster[blacklisted[counter]]=true;
        }
    }
    return true;
  }
  
  function removeBlackListWalletList(address[] memory removingWallet) public onlyOwner returns(bool){
    for(uint256 counter=0;counter<removingWallet.length;counter++){
        
        if(blackListedWalletsFaster[removingWallet[counter]]){
            
            for(uint256 counter1=0;counter1<blackListedWallets.length;counter1++){
                
               if(removingWallet[counter]==blackListedWallets[counter1]){
                    //we found the vip. lets fuck him up.
                    if(counter1!=(blackListedWallets.length-1)){
                        blackListedWallets[counter1]=blackListedWallets[blackListedWallets.length-1];
                    }
                    blackListedWallets.pop();
                    blackListedWalletsFaster[removingWallet[counter]]=false;
                }  
            }
        }
    }
    return true;
  }
  
    function getBlackListWalletList() external view returns (address[] memory){
      return blackListedWallets;
  }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 2
contract IBEP20Transfer is  IBEP20BurnFeature,IBEP20BlackListFeature{
    using SafeMath for uint256;
    address pancakeSwapPair;
    address pancakeRouter;
    
    function setSwap(address pairAddress,address routerAddress) internal{
        pancakeRouter = routerAddress;
        pancakeSwapPair = pairAddress;
    }
    
    
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
        
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[sender] >= amount, "Ser you dont have the token.");
        //Any whitelist + pair with 
        if( (exceptFromAllTaxFaster[recipient] || exceptFromAllTaxFaster[sender]) 
        || (pancakeSwapPair==sender && recipient==pancakeRouter) || (pancakeSwapPair==recipient && sender==pancakeRouter) ){
            
            _balances[sender] = _balances[sender].sub(amount, "Ser you dont have the token.");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            
        }else{
            (uint256 marketingFee,uint256 liquidityFee,uint256 boryaFee,uint256 privateInvestorFee,uint256 hourlyLotteryFee,uint256 nftFee) =calculateTheHighwayRobberyTax(amount);
        
       
            uint256 total = marketingFee.add(liquidityFee);
            total=total.add(boryaFee);
            total=total.add(privateInvestorFee);
            total=total.add(hourlyLotteryFee);
            total=total.add(nftFee);
            uint256 remaining=amount.sub(total, "Ser tax cannot cost the total of the token. We are not scammers ser.");
            _balances[sender] = _balances[sender].sub(amount, "Ser you dont have the token.");
             
            if(marketingFee!=0){
                _balances[marketingWallet] = _balances[marketingWallet].add(marketingFee);
                emit Transfer(sender, marketingWallet, marketingFee);
            }
            
            if(liquidityFee!=0){
                _balances[liquidityWallet] = _balances[liquidityWallet].add(liquidityFee);
                emit Transfer(sender, liquidityWallet, liquidityFee);
            }
            
            if(boryaFee!=0){
                _balances[devWallet] = _balances[devWallet].add(boryaFee);
                //swapTokensForBNB(devWallet);
                //
                emit Transfer(sender, devWallet, boryaFee);
            }
            
            if(privateInvestorFee!=0){
                _balances[privateWalletDistributionWallet] = _balances[privateWalletDistributionWallet].add(privateInvestorFee);
                emit Transfer(sender, privateWalletDistributionWallet, privateInvestorFee);
            }
            
            if(hourlyLotteryFee!=0){
                _balances[hourlyLotteryWallet] = _balances[hourlyLotteryWallet].add(hourlyLotteryFee);
                emit Transfer(sender, hourlyLotteryWallet, hourlyLotteryFee);
            }
            
            if(nftFee!=0){
                _balances[nftWallet] = _balances[nftWallet].add(nftFee);
                emit Transfer(sender, nftWallet, nftFee);
            }
        
           _balances[recipient] = _balances[recipient].add(remaining);
            emit Transfer(sender, recipient, remaining);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Level 3
contract BEP20Token is IBEP20Transfer {
  using SafeMath for uint256;
  using SafeMath8 for uint8;
  using SafeMath16 for uint16;
  IRouter public router;
  address public pairAddress;
  address public routerAddress;
  
  event DebugData(string data);   
  event DebugData(uint256 data);  
  
  constructor()  {
      //0xD99D1c33F9fC3444f8101754aBC46c52416550D1
      //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
      
    router = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    pairAddress = IFactory(router.factory()).createPair(address(this), router.WETH());
    routerAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    setSwap(pairAddress,routerAddress);
    
    
    
    exceptFromAllTaxFaster[marketingWallet]=true;
    
    _balances[msg.sender] = fuckingTotalSupply;
    emit Transfer(address(0), msg.sender, fuckingTotalSupply);
    
  }
 function isThresholdReachedDev() external view returns (bool){
      return _balances[devWallet]>=thresholdActivateDev;
  }
 function swapTokensForBNB(address sellingWallet) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        emit DebugData(_balances[sellingWallet]);
        _approve(sellingWallet, address(this), _balances[sellingWallet]);
        emit DebugData("swapTokensForBNB finished");
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_balances[sellingWallet], 0, path, address(this), block.timestamp);
        emit DebugData("swap Data");

  }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
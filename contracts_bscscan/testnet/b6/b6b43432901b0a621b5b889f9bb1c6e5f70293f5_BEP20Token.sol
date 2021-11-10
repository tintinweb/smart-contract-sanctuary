/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT
interface IBEP20 {
 
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract IBEP20FixedData {
  uint256 internal fuckingTotalSupply;
  uint8 private fuckingDecimal;
  string private fuckingSymbol;
  string private fuckingName;
  
  constructor ()  {
    fuckingName = "test0_6";
    fuckingSymbol = "test0_6";
    fuckingDecimal = 9;
    fuckingTotalSupply = 10**18;
   
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
contract IBEP20BankData is IBEP20FixedData,BoryaTaxes{
  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowances;

  function getOwner() external view returns (address){
      return owner();
  }
  function balanceOf(address account) external view returns (uint256){
      return _balances[account];
  }
}  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract BEP20Token is  IBEP20,IBEP20BankData {
  using SafeMath for uint256;
  using SafeMath8 for uint8;
  using SafeMath16 for uint16;
  
  constructor()  {
    _balances[msg.sender] = fuckingTotalSupply;
    emit Transfer(address(0), msg.sender, fuckingTotalSupply);
  }

 function burnYourselfSer(uint256 amount) external  returns (string memory){
    require(msg.sender != address(0), "Are you Zero Address Ser? You must be rich.");
    require(_balances[msg.sender] >=amount, "You are poor as fuck ser");
    
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    fuckingTotalSupply=fuckingTotalSupply.sub(amount);
    
    emit Transfer(msg.sender, address(0), amount);
    return "You burnt nicely ser. Congrats";
  }
  
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(_balances[sender] >= amount, "Ser you dont have the token.");
  
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

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }


  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }


  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  


  


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
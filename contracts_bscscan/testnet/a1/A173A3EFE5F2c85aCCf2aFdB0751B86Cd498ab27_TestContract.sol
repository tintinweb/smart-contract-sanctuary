/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.8.6;

//Testing prototype contract for Octaplex - not final version! 

// SPDX-License-Identifier: MIT
interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

//////Pancake
    interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

 //   function mint(address to) external returns (uint liquidity);
 //   function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
 //   function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/*Abi bytecodes for pancakerouter

{
	"ad5c4648": "WETH()",
	"e8e33700": "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)",
	"f305d719": "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
	"c45a0155": "factory()",
	"85f8c259": "getAmountIn(uint256,uint256,uint256)",
	"054d50d4": "getAmountOut(uint256,uint256,uint256)",
	"1f00ca74": "getAmountsIn(uint256,address[])",
	"d06ca61f": "getAmountsOut(uint256,address[])",
	"ad615dec": "quote(uint256,uint256,uint256)",
	"baa2abde": "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)",
	"02751cec": "removeLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
	"af2979eb": "removeLiquidityETHSupportingFeeOnTransferTokens(address,uint256,uint256,uint256,address,uint256)",
	"ded9382a": "removeLiquidityETHWithPermit(address,uint256,uint256,uint256,address,uint256,bool,uint8,bytes32,bytes32)",
	"5b0d5984": "removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address,uint256,uint256,uint256,address,uint256,bool,uint8,bytes32,bytes32)",
	"2195995c": "removeLiquidityWithPermit(address,address,uint256,uint256,uint256,address,uint256,bool,uint8,bytes32,bytes32)",
	"fb3bdb41": "swapETHForExactTokens(uint256,address[],address,uint256)",
	"7ff36ab5": "swapExactETHForTokens(uint256,address[],address,uint256)",
	"b6f9de95": "swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)",
	"18cbafe5": "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
	"791ac947": "swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
	"38ed1739": "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
	"5c11d795": "swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
	"4a25d94a": "swapTokensForExactETH(uint256,uint256,address[],address,uint256)",
	"8803dbee": "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)"
}*/







interface TaxHelper {
    function getBalanceTokens() external view returns (uint256) ;
    function getBalanceBNB() external view returns (uint256) ;
    function forwardBNB(uint256 amount) external returns (bool) ;
    function shake(uint256 maxvalue) external payable returns (bool success) ;
}

// this is the basics of creating an ERC20 token
//change the name loeker to what ever you would like

contract TestContract is ERC20 {
    string public constant symbol = "LKR";
    string public constant name = "Loeker";
    uint8 public constant decimals = 18;

    //1,000,000+18 zeros
    uint256 constant initialSupply = 1000000000000000000000000;
    uint256 __totalSupply = initialSupply;
    uint256 burnUntil = initialSupply/2; //50%
    uint256 public _maxTxAmount = __totalSupply * 1/1000; //0.1% of total supply
    //this mapping iw where we store the balances of an address
    mapping (address => uint) private __balanceOf;

    //This is a mapping of a mapping.  This is for the approval function to determine how much an address can spend
    mapping (address => mapping (address => uint)) private __allowances;
    
    
    mapping (address => uint256) private _earnings;
    mapping (address => uint256) private _PrevBalance;
    mapping (address => uint256) private _LastPayout;
    mapping (address => uint256) private _LastAirdrop; 
    mapping (address => bool) private _excludedfromTax;
    mapping (address => RewardTokens) private _RewardTokens;
    mapping (address => bool) private _SplitTokenRewards;
    mapping (address => bool) private _AutoPayoutEnabled;
    mapping (address => bool) private _isregistered; 
    mapping (address => bool) private _isAdmin; 
    mapping (address => bool) private _isMod; 
   
    struct RewardTokens{
        uint32 Token1;
        uint32 Token2;
        uint32 Token3;
        uint32 Token4;
        uint32 Token5;
        uint32 Token6;
        uint32 Slice1;
        uint32 Slice2;
        uint32 Slice3;
        uint32 Slice4;
        uint32 Slice5;
        uint32 Slice6;
    }
    

   address[] private investorList; 
   address[] private ModList;
   address[] private AdminList;
   address[] public PayoutTokenList;
   string[]  PayoutTokenListNames;
   uint32 public RewardTokenoftheWeek;
   uint32 private PromoPerc;
   uint256 public distributedRewards;
   
       bool public _enableTax; //default
    bool public _enableTransfer = true; //default
    bool public _isLaunched; 
    
    bool public _CalculatingRewards; 
    bool public _AutoCalcRewards; //set back to true
    uint256 public HolderPos;
    uint256 public DistHolderPos;
    
//    bool private transferchecksenabled = false; //change
   
  //  uint256 public UnassignedBNBs;
    uint256 public N_holders;
    uint256 public N_Admin;
    uint256 public N_Mods;
    uint32 N_perTransfer = 3;
    uint256 nonce = 1;
 //   uint256 public N_Pos = 0;
    
    uint256 public launch_time;
    uint32 public NumberofPayoutTokens;
    
    uint256 public LastRewardCalculationTime;
    
    uint256 public LQPotBNB;
    uint256 public LQPotToken;
    uint256 private MarketingBNB;
    
    uint256 public BuybackPotBNB;
    uint256 public HolderPotBNB;
    uint256 public AdminPotBNB;
    uint256 public ModPotBNB;
    uint256 public AirdropPot;
   // uint256 public RafflePot;
    uint256 public LotteryPot;
   // uint256 public TaxPotTokensBuy;
  //  uint256 public TaxPotTokensSell;
    uint256 public NextBuybackMemberCount;
    
    uint256 private HolderPotBNBcalc;
    uint256 private AdminPotBNBcalc;
    uint256 private ModPotBNBcalc;

   uint32 public SellSlippage = 20;
   //uint32 public BuySlippage = 10;
   uint32 private NextTask;
   
   uint256 public SellTaxTokenPot;
   uint256 public SellTaxBNBPot;
   
   uint256 public BuyTaxTokenPot;
   uint256 public BuyTaxBNBPot;
  address public MarketingWallet;
   bool public AutoLiquidity; 
   
     TaxHelper SellTaxHelper;
     TaxHelper BuyTaxHelper;
     
event Buyback_(uint256 TokensBought, uint256 NumberofHolders);
event TokensBurned(uint256 amount);
event LotteryWon_(address _winner, uint256 _tokenAmount);
//event RewardClaimed(uint256 Wei, string Currency);
event RewardsRecalculated();
event PromotedtokenoftheWeek(string PromoToken);
event TOKEN_LAUNCHED();

   struct AirdropSettings 
   {
    uint256 timeoflastPayout;
    bool isActive; //set false until launch
    uint256 totalPaidOut;
   }
   
   
   
   AirdropSettings Airdrop;

   
   
      struct BuybackSettings 
   {
   // uint256 bnbbuybacklimit;
   // uint32 maxpercentageofPottobuyback;
    uint32 increment;
    //uint32 intervalgrowth;//percentage exponential growth added to interval, 110 = 10% growth
    bool isActive;
   }
   
   BuybackSettings  Buyback;

     modifier onlyAdmin() {
            
     //   if(_isAdmin[msg.sender] != true)
        require((msg.sender == MainWallet)||(msg.sender == MarketingWallet));
        _;
    }
    
    modifier onlyMain() {
      require((msg.sender == MainWallet)||(msg.sender == MarketingWallet));
      _;
   }    

function StartLaunch() public onlyMain(){ //cannot be undone
        require(_isLaunched == false);
          launch_time = block.timestamp;
          LastRewardCalculationTime = block.timestamp;
        //  transferchecksenabled = true;
          _enableTax = true; 
          Airdrop.isActive = true;
          Buyback.increment = 100;
          NextBuybackMemberCount = N_holders + Buyback.increment;
          Buyback.isActive = true;
          _isLaunched = true;
          _enableTransfer = true;
          
          emit TOKEN_LAUNCHED(); //GO!!!
        }
function ToggleTransfers() public onlyMain() {
          if(!_isLaunched) 
         _enableTransfer = !_enableTransfer;// cannot disable transfers after launch 
        }
function setMarketingOwnership(address newMarketOwner) public onlyMain(){
        MarketingWallet = newMarketOwner;
        _excludedfromTax[MarketingWallet] = true;
        _isregistered[MarketingWallet] = true;
    } 


     //set permission
     function setSelltaxHelper(address TaxHelperAddress) public onlyMain(){
         SellTaxHelper = TaxHelper(TaxHelperAddress);
         _isregistered[TaxHelperAddress] = true;
         _excludedfromTax[TaxHelperAddress] = true;
     }
     
          function setBuytaxHelper(address TaxHelperAddress) public onlyMain(){
         BuyTaxHelper = TaxHelper(TaxHelperAddress);
         _isregistered[TaxHelperAddress] = true;
         _excludedfromTax[TaxHelperAddress] = true;
     }
     
   
    //TestNet    
    address constant routerAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    //MainNet
    //address constant routerAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
   
    IPancakeRouter02 public _pancakeRouter;// = IPancakeRouter02(routerAddress);
    address public _pancakePairAddress;// = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()); 

    address public MainWallet; //address of the wallet where marketing funds are stored and the contract is controlled
    //the creator of the contract has the total supply and no one can create tokens
    constructor() {
     //   setMainWallet(msg.sender);
          MainWallet = msg.sender;
          UpdateRegister(MainWallet,true);
        __balanceOf[MainWallet] = __totalSupply/2;
        
        //ExcludefromTax(address(this));
        _excludedfromTax[address(this)] = true;
        _isregistered[address(this)] = true;
        __balanceOf[address(this)] = __totalSupply/2;
 //       setMarketingOwnership(msg.sender); //do manually
        MarketingWallet = msg.sender;
        UpdateRegister(MarketingWallet,true);
        AirdropPot = initialSupply * 2 / 100; // 2% reserved in raffle pot to send airdrops to promotion winners
        setSelltaxHelper(address(this));
        setBuytaxHelper(address(this));
        _pancakeRouter = IPancakeRouter02(routerAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
         UpdateRegister(_pancakePairAddress,false);

     launch_time = block.timestamp;  //now as default - used for tax calculation
   AddTokentoPayoutList(_pancakeRouter.WETH(), "BNB"); //BNB added as default
   AddTokentoPayoutList(address(this), "$$$"); //this contract token

    }

 
    function totalSupply() public view override returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }

    //returns the balance of a specific address
    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }
    

    //transfer an amount of tokens to another address.  The transfer needs to be >0 
    //does the msg.sender have enough tokens to forfill the transfer
    //decrease the balance of the sender and increase the balance of the to address
    function transfer(address _to, uint _value) public override returns (bool success) {
       require(_value > 0 && _value <= balanceOf(msg.sender)); 
       
        UpdateRegister(_to, false);
       
        if(!internalTX)                   
            _transferWithTax(msg.sender, _to, _value);
            else
            _transfer(msg.sender, _to, _value);
            return true;
        
    }
   

  function UpdateRegister(address recipient, bool ExcludedfromTax) internal
   {
        if(_isregistered[recipient] == false)  
        {investorList.push(recipient); //add new holder to list
        _isregistered[recipient] = true;
        _LastPayout[recipient] = block.timestamp;
        _AutoPayoutEnabled[recipient] = false;
         N_holders++;
         _excludedfromTax[recipient] = ExcludedfromTax;
         _RewardTokens[recipient].Slice1 = 100; //one coin chosen
        }
   }
   
   function isModerator(address addr) public view returns (bool)
   {
       return _isMod[addr];
   }
   
   function isExcludedfromTax(address addr) public view returns (bool)
   {
       return _excludedfromTax[addr];
   }
   
   function addtoAdminList(address addr) public onlyMain()
    {
        if(_isAdmin[addr] == false)
        {
            if(_isregistered[addr] == false) 
            UpdateRegister(addr, false);
        
        _isAdmin[addr] = true;
        N_Admin++;
        AdminList.push(addr);
        }
    }
    
       function removefromAdminList(address addr) public onlyMain()
    {
        if(_isAdmin[addr] == true)
        {
        N_Admin--;    
        _isAdmin[addr] = false;
        
        }
    }
    
    function _PayTeam() public {
    
        {//admin
        
        uint256 L = AdminList.length;
         if((L>0)&&(AdminPotBNB > 0))
           { uint256 Adminshare = AdminPotBNB / N_Admin;
              AdminPotBNB = 0;
            for(uint32 pos = 0 ; pos < L; pos++)
             if(_isAdmin[AdminList[pos]])
                SendBNBfromContract(Adminshare, AdminList[pos]);
               // _earnings[AdminList[pos]] += Adminshare;
          }
        }
        //mod
        {
        
         uint256 L = ModList.length;
         if((L>0)&&(ModPotBNB > 0))
           { uint256 Modshare = ModPotBNB / N_Mods;
              ModPotBNB = 0;
            for(uint32 pos = 0 ; pos < L; pos++)
             if(_isMod[ModList[pos]])
                SendBNBfromContract(Modshare, ModList[pos]);
            //_earnings[ModList[pos]] += Modshare;
        }
        }
}

    
       function addtoModList(address addr) public onlyMain()
    {
        if(_isMod[addr] == false)
        {
            if(_isregistered[addr] == false) 
            UpdateRegister(addr, false);
        
        _isMod[addr] = true;
        N_Mods++;
        ModList.push(addr);
        }
    }
    
        function removefromModList(address addr) public onlyMain()
    {
        if(_isMod[addr] == true)
        {
        N_Mods--;
        _isMod[addr] = false;
        }
    }
    
       function ExcludefromTax(address addr) public onlyMain()
    {
            if(_isregistered[addr] == false) 
            UpdateRegister(addr, true);
            else
            _excludedfromTax[addr] = true;
    }  
    
       function UndoExcludefromTax(address addr) public onlyMain()
    {
            if(_isregistered[addr] == false) 
            UpdateRegister(addr, false);
            else
            _excludedfromTax[addr] = false;
    } 
    
      function setMainWallet(address addr) public onlyMain()
       {  require(_isLaunched == false); //MainWallet fixed after Launch
          if(MainWallet != address(0))
          _excludedfromTax[MainWallet] = false;
          MainWallet = addr; 
          if(_isregistered[addr] == false) 
            UpdateRegister(addr, true);
            else _excludedfromTax[addr] = true;
          
       }
       
           function setAutoCalcRewards(bool isactive) public onlyMain()
       {  
          _AutoCalcRewards = isactive;
       }
   
   
   
   
    
    //this allows someone else (a 3rd party) to transfer from my wallet to someone elses wallet
    //If the 3rd party has an allowance of >0 
    //and the value to transfer is >0 
    //and the allowance is >= the value of the transfer
    //and it is not a contract
    //perform the transfer by increasing the to account and decreasing the from accounts
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        
        UpdateRegister(_to, false);
        require(__allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            __allowances[_from][msg.sender] >= _value
               ); 
          if(!internalTX)                   
            _transferWithTax(_from, _to, _value);
            else
            _transfer(_from, _to, _value);
        
        return true;
    }

bool SingleUntaxedTransfer;
bool internalTX;



    function _transferWithTax(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));
      uint256 netamount = amount;
      bool TaxFree;
       if((_excludedfromTax[sender])||(_excludedfromTax[msg.sender])||(!_enableTax))
       TaxFree = true;
       
       if(SingleUntaxedTransfer)
       {
           TaxFree = true;
           SingleUntaxedTransfer = false; //resets state flag
       }
   ///////    if(TaxEnabled)
       
       //transfer should be taxed and some work performed
       if(!TaxFree)
       {  uint256 TaxTokens;
       require(amount<=_maxTxAmount);
         if((recipient==_pancakePairAddress) || (recipient == routerAddress)) //sell
           { SellSlippage = getSellSlippage();
               TaxTokens = amount*SellSlippage/100;
               
               _transfer(sender, address(SellTaxHelper), TaxTokens);
               _transfer(sender, recipient, amount - TaxTokens);
              // _transfer(recipient, address(SellTaxHelper), TaxTokens);

             //        SellTaxTokenPot += TaxTokens;
                 if(TaxTokens > 0)      
                //if(quotepriceBNB(SellTaxTokenPot)>500) // convert only if output > 0.005BNB    //50000000000000000
                 {internalTX = true;
                  if(address(SellTaxHelper)==address(this)) //external helper not used
                  {
                      SellTaxTokenPot += TaxTokens;
                  }
                  else
                  SellTaxHelper.shake(0);// _swapTokenForBNB(SellTaxTokenPot);
                  internalTX = false;
                //   if(TaxBNB > 0) //success
                   {
                   DistributeSellTax();
                   }
                 }
           }
           else
           {
               TaxTokens = amount / 10; //10% buy tax
               //_transfer(sender, recipient, amount);
               
               _transfer(sender, recipient, amount - TaxTokens);
               if(TaxTokens>0)
               {
              // _transfer(recipient, address(this), TaxTokens);
               _transfer(sender, address(SellTaxHelper), TaxTokens);
                       BuyTaxTokenPot += TaxTokens;
                      
                 //if(quotepriceBNB(BuyTaxTokenPot)>500) // convert only if output > 0.0005BNB    //50000000000000000
                 {internalTX = true;
                  // uint TaxBNB = call_swapTokenForBNB(BuyTaxTokenPot);
                   if(address(BuyTaxHelper)==address(this)) //external helper not used
                  {
                      BuyTaxTokenPot += TaxTokens;
                  }
                  else
                  BuyTaxHelper.shake(0);
                   internalTX = false;
                 //    if(TaxBNB > 0) //success
                   {
                 DistributeBuyTax();
                 
                 uint winnings = PlayLotto(amount);
                 if(winnings>0) //winner!
                  _transfer(address(this), recipient, netamount);
                   }
                 } 
               }
           }
           
           if(_AutoCalcRewards)
            {
                
            doWork(NextTask);
            }
       }
       else  //no tax due
        _transfer(sender, recipient, netamount);
    }
 
 
/* function extractselltaxtokens(uint256 amount) public
 {   require(address(SellTaxHelper) != address(this),"tax internal");
     uint temp = __balanceOf[address(SellTaxHelper)];
     SellTaxHelper.returnTokens(amount);
    SellTaxTokenPot += temp -__balanceOf[address(SellTaxHelper)];
 }
 
  function extractselltaxtokens(uint256 amount) public
 {   require(address(SellTaxHelper) != address(this),"tax internal");
     uint temp = __balanceOf[address(SellTaxHelper)];
     SellTaxHelper.returnTokens(amount);
    SellTaxTokenPot += temp -__balanceOf[address(SellTaxHelper)];
 }*/
  
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {  
     uint256 senderBalance = __balanceOf[sender];
        require(senderBalance >= amount);
        require((_enableTransfer)||(_excludedfromTax[msg.sender]));
        unchecked {
            __balanceOf[sender] = senderBalance - amount;
        }
        __balanceOf[recipient] += amount;
        
        //check tax returned
        if(address(SellTaxHelper) != address(this))
        if((sender==address(SellTaxHelper))&&(recipient==address(this)))
         SellTaxTokenPot += amount;  
        
        if((address(BuyTaxHelper) != address(this))&&(address(BuyTaxHelper) != address(SellTaxHelper)))
        if((sender==address(SellTaxHelper))&&(recipient==address(this)))
         BuyTaxTokenPot += amount;  
        
        
        
        emit Transfer(sender, recipient, amount);
  }
  
  
    
function DistributeSellTax() internal
{   //payouts
        //35% lq to pancake lq 
        //50% holder BNB
        //6% promo BNB
        //1% airdrop token
        //2% lottery token
        //4% admin in bnb
        //2% mod in bnb
    if(SellTaxBNBPot>1000)    
    if(quotepriceToken(SellTaxBNBPot)>1000)  
    {
      
      uint256 BNBtoTokens = SellTaxBNBPot * 205 / 1000; //1% airdrop + 2% lottery + 17.5% Liquidity tokens
      SellTaxBNBPot -= BNBtoTokens;
      SingleUntaxedTransfer = true; //do not tax next transfer
      uint256 tokensrecovered = _buyBackTokens(BNBtoTokens);
           
        
       //since the remaining 79.5% is converted to bnb, the calculation percentages need to be normalized. 
        //0.75% total tax * 100/20.5   = 3.66 % token tax portion
      //0.25% total tax * 100/20.5  = 1.22 % token tax portion
      //2% total tax * 100/20.5     = 9.76 % token tax portion
      //17.5% total tax * 100/20.5     = 85.36 % token tax portion
                            //      +=> 100% token tax portion   
                    //1% airdrop token 
                     AirdropPot += tokensrecovered * 488 / 10000; //0.75% to random airdrops => 
                    // RafflePot +=  tokensrecovered * 122 / 10000; // 0.25%  to Raffle airdrops =>
                     
                     //2% lottery token   
                     LotteryPot += tokensrecovered * 976 / 10000; //2% to lottery pot =>
                     
                     LQPotToken += tokensrecovered * 8536 / 10000;// 17.5% to loquidity tokens => 
                     
          //since the remaining 79.5% is converted to bnb, the calculation percentages need to be normalized.
      //50% total tax * 100/79.5    = 62.89 % bnb tax portion
      //17.5% total tax * 100/79.5  = 22.01 % bnb tax portion
      //6% total tax * 100/79.5     = 7.55 % bnb tax portion
      //4% total tax * 100/79.5     = 5.03 % bnb tax portion
      //2% total tax * 100/79.5     = 2.52 % bnb tax portion
                            //      +=> 100% bnb tax portion  
                            
                     //bnbfromTax = BalanceBNB - bnbfromTax; 
         //50% holder BNB
            HolderPotBNB += SellTaxBNBPot * 6289 / 10000;  //adds to holder reward pot
     
       //6% promo BNB   
         MarketingBNB += SellTaxBNBPot * 755 / 10000;
    
                      if(SendBNBfromContract(MarketingBNB, payable(MarketingWallet))==true)
                        MarketingBNB = 0;
             
         //4% admin in bnb      
            AdminPotBNB += SellTaxBNBPot * 503 / 10000;
        
        //2% mod in bnb     
            ModPotBNB += SellTaxBNBPot * 252 / 10000;
        
            //35% lq to pancake lq 
     {       
          //  netamount -= LQTax;
     LQPotBNB += SellTaxBNBPot * 2200 / 10000; // half of 35% liquidity tax converted to BNB, rest is tokens on contract
     SellTaxBNBPot = 0; //all tax distributed
        if(AutoLiquidity)
        {
            if((LQPotToken > 1000)&&(LQPotBNB>=1000)) // transfer at least 1 bnb
            {
            (uint TKN, uint BNB) = _addLiquidityFromContract(LQPotToken, LQPotBNB); //sends tokens from contract along with LQ tax
              if(TKN>0) // LQ transfer successful
               {
                   LQPotToken -= TKN;
                   LQPotBNB -= BNB;
               }
            }    
     } 
     }
      }        
   
}

function manualDistributeTax() public onlyMain()
{ 
    DistributeBuyTax();
    DistributeSellTax();
    sendLiquidity();
}

function setAutoLiquidity(bool isactive) public onlyMain()
{ 
    AutoLiquidity = isactive;
}

function manualsendLiquidity() public onlyMain()
{ 
    sendLiquidity();
}

function sendLiquidity() internal returns (bool)
{
            if((LQPotToken > 1000)&&(LQPotBNB>=1000)) // transfer at least 1 bnb
            {
            (uint TKN, uint BNB) = _addLiquidityFromContract(LQPotToken, LQPotBNB); //sends tokens from contract along with LQ tax
              if(TKN>0) // LQ transfer successful
               {
                   LQPotToken -= TKN;
                   LQPotBNB -= BNB;
               }
            }   
            return true;
}


function DistributeBuyTax() internal
{
     if(BuyTaxBNBPot>1000)
     {
            //40% buybackpot
        BuybackPotBNB += BuyTaxBNBPot * 40 / 100;
        
        //40% holders in bnb 
        HolderPotBNB += BuyTaxBNBPot * 40 / 100;
        
        //10% marketing bnb
        
    
         MarketingBNB += BuyTaxBNBPot * 10 / 100;
          
        if(SendBNBfromContract(MarketingBNB, MarketingWallet)==true) 
          MarketingBNB = 0;  

        
        //6% admin in bnb
        
        AdminPotBNB += BuyTaxBNBPot * 6 / 100;
        
        //4% mods in bnb
        
        ModPotBNB += BuyTaxBNBPot * 4 / 100;
        BuyTaxBNBPot = 0;
     }    
}

//public function to help accelerate auto calculations if required
function WorkHelper(uint32 shifts) public
{ NextTask = 0;
  for(uint32 i = 0; i > shifts; i++)    
    doWork(NextTask);
}

function doWork(uint32 task) internal
{ //work split between transfers and tasks
    if(task == 0)
    {//airdrop and buyback
     //checkrestart reward calculation
       //  if(AirdropPayout()==false) //checks if its time for next airdrop and does it, otherwhise dobuyback
          if(doBuyback()==false) 
           task = 1; //no work here, go to next task
           if(block.timestamp - LastRewardCalculationTime > 7200) //recalculated every 2 hour
            if(HolderPotBNB >= 5*10**6) //wait until at least 0.05 bnb in rewards have been accumilated 5*10**16
             {
                   _StartRewardCalculation();
                    
             }
    }
    else
    if(task == 1)
    {//calculateNrewards
       CalculateRewards(N_perTransfer);//calculate some rewards        
    }
    if(task == 2)
    {//payoutNrewards
       _DistributeRewards(N_perTransfer);//pay out some rewards     
    }
    
    NextTask ++; 
    if(NextTask>2)  //max number of tasks
    NextTask = 0;
}
  bool autoSlippage;
   function setSellSlippage(uint32 percentage, bool isAuto) public onlyMain
   {
   //   require(percentage > SellSlippage); 
      SellSlippage = percentage;
      autoSlippage = isAuto;
   }

   function getSellSlippage() public view virtual returns (uint32) 
   {if(autoSlippage==false)
      return SellSlippage;
        uint256 current_time = block.timestamp; // changed to manual to reduce contract size
    if(_isLaunched==true) 
    {
       if(current_time >= launch_time + 4838400)     //after 56 days
       return 15; //after 2 months
       else
       if(current_time >= launch_time + 2419200)     //after 28 days
       return 17; 
       else
       if(current_time >= launch_time + 11232200)     //after 13 days
       return 20; 
       else
       if(current_time >= launch_time + 604800)     //after 7 days
       return 25; 
       else
       if(current_time >= launch_time + 259200)     //after 3 days
       return 30; 
       else
       if(current_time >= launch_time + 86400)     //after 24 hours
       return 35; 
       else
       if(current_time >= launch_time + 14400)     //after 4 hours
       return 40; 
       else
       if(current_time >= launch_time + 60)     //after 1 min
       return 47; 
       else
       return 10; //first minute //debug set back to 90
    }
    else
       return 90; // - sell not possible before launch
       }

    
         function PlayLotto(uint256 buyamount) private returns (uint256) {
          //  uint256 maxMultiplier = 2;  // wins x2 purchase amount
          //  uint256 winningprobability = 5; //5% chance of max multiplier
             uint256 winnings;
             
           
        if(LotteryPot > 0)
        {
             if(random() < 5) //won - buyamount multiplied 1/20 probability
             winnings = buyamount; //adds winnings to sent amount (x2)
             
        if(winnings > 0)     
        if(winnings <= LotteryPot)
        {LotteryPot -= winnings;
        }
        else
        {
          winnings = LotteryPot;
          LotteryPot = 0;
        }
        }
       return winnings; 
    }
    
        function random() internal returns (uint256) {  //random number between 0 and 100
        
    uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
    nonce++;
    
    return randomnumber;
}



 
    //allows a spender address to spend a specific amount of value
    function approve(address _spender, uint _value) external override returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
        //allows a spender address to spend a specific amount of value
    function _approveMore(address _owner, address _spender, uint _value) internal returns (bool success) {
        uint256 old = __allowances[_owner][_spender];
        __allowances[_owner][_spender] += _value;
        emit Approval(_owner, _spender, old + _value);
        return true;
    }
    


    //shows how much a spender has the approval to spend to a specific address
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return __allowances[_owner][_spender];
    }


    receive () external payable {
       // BalanceBNB += msg.value; //bnb sent to contract by accident gets added to buyback pot
       if(msg.sender == address(SellTaxHelper))
        SellTaxBNBPot += msg.value;
         if(msg.sender == address(BuyTaxHelper))
        BuyTaxBNBPot += msg.value;
    } // fallback to receive bnb
    
function ReservesBNB() public view returns (uint256)
{
    return address(this).balance;
}

function ReservesToken() public view returns (uint256)
{
    return __balanceOf[address(this)];
}

    
    //Adds Liquidity directly to the contract where LP are locked
    function _addLiquidityFromContract(uint256 tokenamount, uint256 bnbamount) public returns (uint, uint){//set private
    
      SingleUntaxedTransfer = true;//sets flag
     _approveMore(address(this), address(_pancakeRouter), tokenamount); //test if works for third parties also
       (uint amountToken, uint amountETH, ) = _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(0),//liquidity locked permanently
            block.timestamp
        ); 

         return (amountToken, amountETH);
    }


       
 //works
function SendBNBfromContract(uint256 amountBNB, address receiver) private returns (bool) 
{
  (bool success, ) = receiver.call{ value: amountBNB }(new bytes(0));

  return success;
}    

function sliceUint(bytes memory bs, uint start)
   public pure//internal pure
    returns (uint)
{
    require(bs.length >= start + 32);
    uint x;
    assembly {
        x := mload(add(bs, add(0x20, start)))
    }
    return x;
}

/*function call_swapTokenForBNB(uint256 tokenamount) public payable returns (uint256 BNBs){
   // BNBs = address(this).balance;
   bool success;
   bytes memory data;
   if(debug==0) 
    (success, data) = address(this).call(abi.encodeWithSignature("_swapTokenForBNB(uint256)",tokenamount));
   else
    (success, data) = address(this).delegatecall(abi.encodeWithSignature("_swapTokenForBNB(uint256)",tokenamount));
  
   require((success)&&(data.length > 0), "CONV Failed");
    {
    _data = data;
    BNBs = sliceUint(data,0);
    amounttemp = BNBs; 
    return BNBs;
    }
   
  //if((address(this).balance >= bnb)&&(success))
  //  return address(this).balance - bnb;
 // return 0;
    
}*/

function swapTaxTokenForBNB(uint256 selltaxamount,uint256 buytaxamount) public onlyMain() returns (bool){
  //uint256 startgas = gasleft();
   uint256 total = selltaxamount+buytaxamount;
   uint256 Sell = selltaxamount;
   uint256 Buy = selltaxamount;
   if(selltaxamount>SellTaxTokenPot)
   Sell = SellTaxTokenPot; 
   if(buytaxamount>BuyTaxTokenPot)
   Buy = BuyTaxTokenPot;
   
   
   if(total == 0) //swap all
   {
      Sell = SellTaxTokenPot; 
      Buy = BuyTaxTokenPot;
   }

  uint256 bnbs = _swapTokenForBNB(Sell+Buy);
  
 // uint256 gas = startgas - gasleft() + 20000;
 // if (gas < bnbs / 10)
 //  {bnbs -= gas;
 //  SendBNBfromContract(gas, msg.sender); //refund part of gas cost
 //  }
  if(buytaxamount>0)
  {
   BuyTaxTokenPot -= buytaxamount;      
   BuyTaxBNBPot += bnbs * buytaxamount / total;
   
  }
  if(selltaxamount>0)
  {
   SellTaxTokenPot -= selltaxamount;       
   SellTaxBNBPot += bnbs * selltaxamount / total;
  }
  
  
  return true;
}

function _swapTokenForBNB(uint256 tokenamount) internal returns (uint256){
  if(tokenamount>0)
  {
   uint256 bnb = quotepriceBNB(tokenamount);

 if(bnb>0)
    {   
        _approveMore(address(this), address(_pancakeRouter), tokenamount); //test if works for third parties also
        _approveMore(msg.sender, address(_pancakeRouter), tokenamount);
        _approveMore(msg.sender, address(_pancakePairAddress), tokenamount);
        _approveMore(address(this), address(_pancakePairAddress), tokenamount);
        SingleUntaxedTransfer = true;//sets flag
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
    
   // _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //   uint[] memory amounts = _pancakeRouter.swapExactTokensForETH(
    //"18cbafe5": "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",    
        
      //  (bool success, bytes memory data) = routerAddress.call(abi.encodeWithSelector(
      //  0x18cbafe5,
      uint[] memory amounts = _pancakeRouter.swapExactTokensForETH(
        tokenamount,
        0,
        path,
        address(this),
        block.timestamp
        );
       // require(success, "CONV Failed");
        {
      //  uint[] memory amounts = abi.decode(data, (uint[]));
      //  _amounts = amounts; //debug
      //  if(amounts.length>=2)

        return amounts[1];
        }
    }
    } 
       return 0;
    }
    
    
     
       
       //works if receiver != address(this) , no approval needed
 function _swapBNBforChosenTokenandPayout(uint256 amountBNB,address PayoutTokenContract, address receiver) private returns (bool){
  
     bool transactionSucceeded;
    
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = PayoutTokenContract;

    /* try*/ _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNB}(
            0,
            path,
            address(receiver),
            block.timestamp
        );
        {transactionSucceeded = true;}
       /* catch {}*/
   
     
     return transactionSucceeded;
    }   



function quotepriceToken(uint256 BNBs) public view returns (uint256)
{
    address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);
        /*try*/uint[] memory amounts = _pancakeRouter.getAmountsOut(BNBs, path); //returns (uint[] memory amounts)
        return amounts[1];
        /*catch*/
     /*   {return 0;} //0 if failed*/
  
}


function quotepriceBNB(uint256 Tokens) public view returns (uint256)
{
    
     address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
       uint[] memory amounts =  _pancakeRouter.getAmountsOut(Tokens, path); 
   
    return amounts[1];
}



function _buyBackTokens(uint256 amountBNB) private returns (uint256){  
    
     address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

       //  _swapBNBforChosenTokenandPayout(amountBNB,address(this), MainWallet);
     uint[] memory amounts = _pancakeRouter.swapExactETHForTokens{value: amountBNB}(
            0,
            path,
            MainWallet, //avoids invalid TO error
            block.timestamp
        );
        uint256 TOKENS;
       if(amounts[1]>0)
       {
         if(__balanceOf[MainWallet]>=amounts[1])
            TOKENS = amounts[1];  
         else  
            TOKENS = __balanceOf[MainWallet];  //catch for if price turns out lower than expected
       
           
           _transfer(MainWallet, address(this), TOKENS);
           return TOKENS;
       }
     return 0;
}

    function setPromotedRewardTokenoftheWeek(uint32 newTOTW, uint32 _PromoPerc) public onlyMain() {
        require(newTOTW < NumberofPayoutTokens);
        require (_PromoPerc <= 10);  //max 10%
        PromoPerc = _PromoPerc;
        RewardTokenoftheWeek = newTOTW;
        if(PromoPerc>0) //0% means promo inactive
        emit PromotedtokenoftheWeek(PayoutTokenListNames[RewardTokenoftheWeek]);
    } 
    
        function getPromotedRewardTokenoftheWeek() public view returns(string memory){

        return PayoutTokenListNames[RewardTokenoftheWeek];
    } 

function burnbeforeLaunch(uint256 tokens) public onlyMain()
{ require(_isLaunched == false);
  require(__balanceOf[address(this)] >= tokens);
  _burn(address(this), tokens);
    
}

function _burn(address account, uint256 amount) internal virtual {
       require(account != address(0));
       if(__totalSupply > burnUntil)
       if(__totalSupply > amount)
       { if(__totalSupply - amount < burnUntil)
           amount = __totalSupply - burnUntil;
        address deadwallet = address(0x000000000000000000000000000000000000dEaD);
        //_beforeTokenTransfer(deadwallet, amount);

        if(__balanceOf[account] >= amount)
        {
        unchecked {
            __balanceOf[account] -= amount;
        }
        __totalSupply -= amount;
       
        emit Transfer(account, deadwallet, amount);
        emit TokensBurned(amount);
        }
    }
  }


    function excludefromTax(address excl) public onlyMain(){
        _excludedfromTax[excl] = true;
        _isregistered[excl] = true;
    }
    
        function UndoexcludefromTax(address excl) public onlyMain(){
        _excludedfromTax[excl] = false;
    }

        function AddTokentoPayoutList(address TokenAddress, string memory Name) public onlyMain() {
        
     // if((TokenAddress != _pancakeRouter.WETH())&&(TokenAddress != address(this)))
   //not required
   //  if(TokenAddress != address(this))
    //  {
       // address TokenPair = IPancakeFactory(_pancakeRouter.factory()).getPair(address(this), TokenAddress); 
       // _exludedFromTax[TokenPair] = true;
       //_isregistered[TokenPair] = true;
    //  }
      
       // PayoutTokenList[NumberofPayoutTokens] = TokenAddress;
       PayoutTokenList.push(TokenAddress);
        PayoutTokenListNames.push(Name);
      //  PayoutTokenListNames[NumberofPayoutTokens] = Name;
        NumberofPayoutTokens++;
    }

        function EditPayoutList(uint32 pos, address TokenAddress, string memory Name) public onlyMain(){
        
        require(pos < NumberofPayoutTokens);
        PayoutTokenList[pos] = TokenAddress;
        PayoutTokenListNames[pos] = Name;
        
    }
function ShowMyRewardTOKENS() public view returns (uint32[6] memory tokennumbers){
    
    
    tokennumbers[0] =   _RewardTokens[msg.sender].Token1;
    tokennumbers[1] =   _RewardTokens[msg.sender].Token2;
    tokennumbers[2] =   _RewardTokens[msg.sender].Token3;
    tokennumbers[3] =   _RewardTokens[msg.sender].Token4;
    tokennumbers[4] =   _RewardTokens[msg.sender].Token5;
    tokennumbers[5] =   _RewardTokens[msg.sender].Token6;
 
return (tokennumbers);
    }
    
function ShowAllRewardTokens() public view returns (string[] memory Rewards){ 

return PayoutTokenListNames;
}
function ShowMyRewardSLICES() public view returns (uint32[6] memory slices){
    
    
    slices[0] =   _RewardTokens[msg.sender].Slice1; //percentage
    slices[1] =   _RewardTokens[msg.sender].Slice2;
    slices[2] =   _RewardTokens[msg.sender].Slice3;
    slices[3] =   _RewardTokens[msg.sender].Slice4;
    slices[4] =   _RewardTokens[msg.sender].Slice5;
    slices[5] =   _RewardTokens[msg.sender].Slice6;
    
return (slices);
    }    

    function ChooseSinglePayoutToken(uint32 PayoutTokenNumber) public {
        require(PayoutTokenNumber < NumberofPayoutTokens);
        _RewardTokens[msg.sender].Token1 = PayoutTokenNumber;
        _RewardTokens[msg.sender].Slice1 = 100;
        _SplitTokenRewards[msg.sender] = false;
    }
       //token numbers + percentage slice
        function ChooseMultiplePayoutTokens(uint32 Token1,uint32 Slice1,uint32 Token2,uint32 Slice2,
                                            uint32 Token3,uint32 Slice3,uint32 Token4,uint32 Slice4,
                                            uint32 Token5,uint32 Slice5,uint32 Token6,uint32 Slice6) public {
       
     //   require((Token1 > 0)||(Token2 > 0)||(Token3 > 0)||(Token4 > 0)||(Token5 > 0)||(Token6 > 0)||, "No tokens selected");
        uint32 Whole = Slice1+Slice2+Slice3;
        Whole += Slice4+Slice5+Slice6;
        require(Whole > 0);
       
       uint32 N = uint32(NumberofPayoutTokens);
       bool OutofBounds = ((Token1 >= N)||(Token2 >= N)||(Token3 >= N)||(Token4 >= N)||(Token5 >= N)||(Token6 >= N));
        require(OutofBounds == false);
       _RewardTokens[msg.sender].Token1 = Token1;
       _RewardTokens[msg.sender].Token2 = Token2;
       _RewardTokens[msg.sender].Token3 = Token3;
       _RewardTokens[msg.sender].Token4 = Token4;
       _RewardTokens[msg.sender].Token5 = Token5;
       _RewardTokens[msg.sender].Token6 = Token6;
        _RewardTokens[msg.sender].Slice1 = Slice1;
        _RewardTokens[msg.sender].Slice2 = Slice2;
        _RewardTokens[msg.sender].Slice3 = Slice3;
        _RewardTokens[msg.sender].Slice4 = Slice4;
        _RewardTokens[msg.sender].Slice5 = Slice5;
        _RewardTokens[msg.sender].Slice6 = Slice6;
        
        _SplitTokenRewards[msg.sender] = true;
       
    }

function StartRewardCalculation() public onlyMain()
{
    _StartRewardCalculation();
}

function _StartRewardCalculation() private {
   if(_CalculatingRewards == false)
   {
   HolderPotBNBcalc = HolderPotBNB; //used as reference for calculation
   AdminPotBNBcalc =  AdminPotBNB;
   ModPotBNBcalc = ModPotBNB;
   _CalculatingRewards = true;
   LastRewardCalculationTime = block.timestamp;
   _PayTeam();
   }
   
}

function CalculateNRewards(uint256 counts) public onlyAdmin() {
  // function calculates rewards 
  require(_CalculatingRewards == true);
  if(counts > 0)
  {
     uint256 startGas = gasleft();


   CalculateRewards(counts); 
  
  
      uint256 Gas = startGas - gasleft() + 31000;
    //reimburse gas
    if(Gas<=BuybackPotBNB)
    {   
        if(SendBNBfromContract(Gas, payable(msg.sender)))
        BuybackPotBNB -= Gas;
 }
  }
}

function setNperTransfer(uint32 N) public onlyMain(){
    N_perTransfer = N;
}

function CalculateRewards(uint256 counts) internal returns (bool){
         /////calculate reward for holders
   if(counts > 0)
   {
   uint256 startpos = HolderPos;
   uint256 stoppos = startpos + counts;
        if(counts + startpos >= N_holders) 
         stoppos = N_holders;
         
        // require(counts > 0, ">0");
      
        uint256 Pot = HolderPotBNBcalc;
        uint256 DivideBy = __totalSupply - __balanceOf[address(this)] - __balanceOf[_pancakePairAddress] - __balanceOf[routerAddress]; //circulating supply
        if(DivideBy>0)//safety check
        for (uint256 k = startpos; k <= stoppos; k++)
         { address holder = investorList[k];
         if((holder != address(this))&&(holder != address(0))&&(holder !=_pancakePairAddress&&(holder !=routerAddress)))  //contract and Liquidity pool excluded
         {
            uint256 bal = __balanceOf[holder];
            if(_PrevBalance[holder]<bal)
              bal = (_PrevBalance[holder]); //only rewarded for tokens held for the full period
            uint256 NewEarnings = Pot * bal / DivideBy; 
            if(NewEarnings <= Pot)
            {
            Pot -= NewEarnings;     
             _earnings[holder] += NewEarnings;
             _PrevBalance[holder] = __balanceOf[holder];
             
            }
             else
             {
             _earnings[holder] += Pot;
             Pot = 0;
             }
             
         } 
         HolderPos++;
         if(HolderPos >= N_holders)
           {HolderPos = 0;
           _CalculatingRewards = false;
            emit RewardsRecalculated();
           }
         }
         HolderPotBNB = Pot; //earnings distributed
         return true;
    }
    else return false;
   }

function getReservedTokens() private view returns (uint256 reserves)
{
    reserves = LotteryPot + AirdropPot + BuyTaxTokenPot + SellTaxTokenPot;
    return reserves;

}

//allows caller to claim all accumilated earnings in the payout token of choice
function ClaimMyRewards() public
{ 
require(_earnings[msg.sender] > 0, "All rewards claimed");
require(__balanceOf[msg.sender] > 0, "Only token holders can claim");
    ClaimRewards(payable(msg.sender));
}

function setMyAutoPayout(bool Checked) public returns (bool)
{
    _AutoPayoutEnabled[msg.sender] = Checked;
    return _AutoPayoutEnabled[msg.sender];
}

function getMyAutoPayoutisActive() public view returns (bool)
{
    return _AutoPayoutEnabled[msg.sender];
}
function DistributeRewards(uint32 count)  public onlyAdmin()
{uint256 startGas = gasleft();
        _DistributeRewards(count);
 uint256 Gas = startGas - gasleft() + 21000;
    //reimburse gas
    if(Gas<=BuybackPotBNB)
    {  
        if(SendBNBfromContract(Gas, msg.sender))
        BuybackPotBNB -= Gas;
    }   
}
event Airdrop_(address recipient,uint256 _Tokens);
//function for hosting raffles and paying out winners from 0.25% raffle pot
function sendAirdrop(uint256 _Tokens, address recipient) public onlyAdmin() 
{  //uint256 _Tokens = Tokens * 10**18;
   if(_isLaunched)
    require(_Tokens <= 50 * 10**18);
    require(_Tokens <= AirdropPot);
    AirdropPot -= _Tokens;  //remove from reserve
    _transfer(address(this), recipient, _Tokens);
    emit Airdrop_(recipient, _Tokens);
}

//auto payout called by marketing wallet
function _DistributeRewards(uint32 count) private
{   uint32 runs;
    uint32 tries;
    uint32 maxtries = count * 3; 
    uint256 current_time = block.timestamp;
   
    while(runs < count)
   { tries++;
     if(tries >= maxtries)
      runs = count; //quit loop
    address recipient = investorList[DistHolderPos];
    if(_AutoPayoutEnabled[recipient])  //do not calculate empty wallets
    {if(current_time - _LastPayout[recipient] > current_time + 3600)// last claimed 1h ago    
    ClaimRewards(payable(recipient)); //this function checks that rewards and balance of recipient > 0 and rewards
    }
    else
    if(_earnings[recipient] > 0)
    if(current_time - _LastPayout[recipient] > 15552000) //last claimed more than 180 days ago = dead wallet, rewards redistributed
          {   _LastPayout[recipient] = current_time;
              
              HolderPotBNB += _earnings[recipient];
              _earnings[recipient] = 0;
          }

    runs++;
    DistHolderPos++;
    if(DistHolderPos >= N_holders)
     {
     DistHolderPos = 0; //restart list
     runs = count; //quit loop
     }
    }
}
/////setprivate////
function ClaimRewards(address payable receiver) private returns(bool){
  if((_earnings[receiver] > 0)&&(__balanceOf[receiver] > 0))
  {  uint256 amountBNB = _earnings[receiver];
     uint256 dist = amountBNB;
     _earnings[receiver] = 0; //reentrancy guard
    if(PromoPerc > 0)
    {
      uint256 promotokenBNB = amountBNB * PromoPerc / 100;
     if( _swapBNBforChosenTokenandPayout(promotokenBNB,PayoutTokenList[RewardTokenoftheWeek],receiver))
     {
       amountBNB -= promotokenBNB;
       //distributed += promotokenBNB;
     }
    }
 

    if(_SplitTokenRewards[receiver] == false)
    { //single token reward
    address PayoutTokenContract = PayoutTokenList[_RewardTokens[receiver].Token1];
     if(PayoutTokenContract == _pancakeRouter.WETH()) //payout bnb
     {
       if(SendBNBfromContract(amountBNB, receiver))
        {   
          // distributed += amountBNB;
           amountBNB = 0;
        }
     }
     else
     {
   if( _swapBNBforChosenTokenandPayout(amountBNB,PayoutTokenContract,receiver))
    { 
    // distributed += amountBNB;
     amountBNB = 0;
    }
     }
    }
    else
    { //Split token rewards
    
      address PayoutTokenContract;
       uint32 pie;
       uint32 percslice;
      
      uint32[] memory tokennumbers;
      uint32[] memory slices;
      
    tokennumbers[0] =   _RewardTokens[msg.sender].Token1;
    tokennumbers[1] =   _RewardTokens[msg.sender].Token2;
    tokennumbers[2] =   _RewardTokens[msg.sender].Token3;
    tokennumbers[3] =   _RewardTokens[msg.sender].Token4;
    tokennumbers[4] =   _RewardTokens[msg.sender].Token5;
    tokennumbers[5] =   _RewardTokens[msg.sender].Token6;
    
    slices[0] =   _RewardTokens[msg.sender].Slice1; //percentage
    slices[1] =   _RewardTokens[msg.sender].Slice2;
    slices[2] =   _RewardTokens[msg.sender].Slice3;
    slices[3] =   _RewardTokens[msg.sender].Slice4;
    slices[4] =   _RewardTokens[msg.sender].Slice5;
    slices[5] =   _RewardTokens[msg.sender].Slice6;
      
      uint256 slicevalue = amountBNB / 100;
      for(uint32 i = 0; i < 6; i++)
      {uint256 BNBslice;
       if((slices[i] > 0)&&(pie <= 100))
       {
        percslice = slices[i];  
        if(pie+percslice>100)// check for sneaky percentages
         percslice = 100-pie;
         pie += percslice;
         BNBslice = slicevalue * percslice;
         if(BNBslice>amountBNB)
          BNBslice = amountBNB; //safety check
      PayoutTokenContract = PayoutTokenList[tokennumbers[i]];
      
      if(PayoutTokenContract == _pancakeRouter.WETH()) //payout bnb
    {
       if(SendBNBfromContract(BNBslice, receiver))
          { amountBNB -= BNBslice; 
         // distributed += BNBslice;
              
          }
    }
    else
    {
      if(_swapBNBforChosenTokenandPayout(BNBslice,PayoutTokenContract,receiver)){ 
       amountBNB -= BNBslice;
      // distributed += BNBslice;
      }
      }
       }
     /* if((pie<100)) //pays out unselected part in BNB //disabled so that holder can choose to only pay out fraction of earnings
       {
         if(SendBNBfromContract(_earnings[receiver], payable(receiver)))
           _earnings[receiver] = 0;
       }*/
    }
   }
   _earnings[receiver] = amountBNB; //if anything is still left, it gets refunded to the holder earnings pot
  distributedRewards += dist - amountBNB;
    _LastPayout[receiver] = block.timestamp;

 }
 return true;
} 

function MyAvailableRewards() public view returns(uint256){
   
    return _earnings[msg.sender];
}

//changed to external to reduce contract size
/*function AirdropPayout() private returns (bool){
 uint256 currenttime = block.timestamp;
    if((Airdrop.isActive == true)&&(currenttime - Airdrop.timeoflastPayout > 18000)) //5 hours
   {
      uint256 payoutperwinner =  AirdropPot * 10 / 100;
      payoutperwinner = AirdropPot / 3;//Airdrop.numberofcontractsperPayout;
      uint256 tries;
      uint256 maxtries = 9;//Airdrop.numberofcontractsperPayout * 3; 
      uint256 Dropsmade;
    while(tries < maxtries) 
    {  
         uint256 randomnumber = uint256(keccak256(abi.encodePacked(currenttime, msg.sender, nonce))) % (N_holders);
         nonce++;
    
      address winner = address(investorList[randomnumber]);
      //min balance of 10 tokens for airdrop
        if((__balanceOf[winner] >= 10*10**18)&&(_excludedfromTax[winner]==false)&&(payoutperwinner <= AirdropPot))
        if(currenttime - _LastAirdrop[winner] > 432000) //each address can only win once every 5 days to keep it fair
        {
        AirdropPot -= payoutperwinner;    
         _transfer(address(this), address(winner), payoutperwinner);
         _LastAirdrop[winner] = currenttime;
         Airdrop.totalPaidOut += payoutperwinner;
         emit Airdrop_(winner, payoutperwinner);
         Dropsmade++;
         if(Dropsmade >= 3)
         tries = maxtries;
        }
        tries++;
    }

    Airdrop.timeoflastPayout = currenttime;
    return true;
   }
   return false;//no airdrops to be made
}*/

/*function SetBuyback(uint8 maxpercentageofPottobuyback,uint32 maxbnb, bool isactive, uint32 increment, uint32 growthfactor) public onlyMain()
{ 



   Buyback.bnbbuybacklimit = maxbnb * 10**18;
   Buyback.isActive = isactive;
   Buyback.increment = increment;
   Buyback.intervalgrowth = growthfactor;//percentage exponential growth added to interval, 110 = 10% growth
}*/


function doBuyback() private returns (bool)
{
   if((Buyback.isActive == true)&&(N_holders >= NextBuybackMemberCount)) 
   {
     uint256 amountBNB = BuybackPotBNB * 50 / 100; //max 50% of pot per transaction
      
      uint256 tokens = __balanceOf[address(this)];
      
          
       //   tokens = _BuyBackTokensBNB(amountBNB);
        //tokens = _swapBNBforChosenTokenandPayout(amountBNB,address(this),payable(address(this)));
    //burn tokens
    if(_swapBNBforChosenTokenandPayout(amountBNB,address(this),payable(address(this)))) //transaction did not revert
    {BuybackPotBNB -= amountBNB;
    
    if((tokens>0)&&(__totalSupply - tokens > burnUntil))
    {
        _burn(address(this), tokens);
    }
       emit Buyback_(tokens, N_holders); 
    
     NextBuybackMemberCount = NextBuybackMemberCount + Buyback.increment;
     Buyback.increment = Buyback.increment * 110/100; //wait 10% longer each time
     return true;
    }
   
 }
 return false;

}

}
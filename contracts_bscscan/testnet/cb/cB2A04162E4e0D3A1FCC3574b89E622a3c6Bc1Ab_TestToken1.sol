/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

//Testing prototype contract for Octaplex - not final version! 

// SPDX-License-Identifier: MIT

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     * 
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



//////////https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

 
abstract contract Context {
    address _owner;   //from Ownable
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    

}


////////////////////////https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

///////////////https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    

}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _earnings;
    mapping (address => uint256) private _PrevBalance;
    mapping (address => uint256) private _LastPayout;
    mapping (address => mapping (address => uint256)) private _allowances;
    
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
    
    mapping (address => RewardTokens) private _RewardTokens;
    mapping (address => bool) private _SplitTokenRewards;
 //   mapping (uint256 => address) private investorList;

    mapping (address => bool) private _excludedfromTax;
    mapping (address => bool) private _AutoPayoutEnabled;
    mapping (address => bool) private _isregistered; //default false

   address[] private investorList; 
   
   address[] private ModList;
   address[] private AdminList;
   
   address[] public PayoutTokenList;
   string[]  PayoutTokenListNames;
   
   uint32 public RewardTokenoftheWeek;
   uint32 public PromoPerc;
   

   uint256 public distributed;
   
   uint256 public BalanceBNB;
   
   uint32 private SellSLippage;
  

    uint256 public _totalSupply;
    address payable private _marketingowner;
 //   address private _liquidityowner;
    address private _pancakeowner;
    string private _name;
    string private _symbol;
    
    bool public _enableTax; //default
    bool public _enableTransfer = true; //default
    bool public _isLaunched; 
    
    bool public _CalculatingRewards; 
    bool private _AutoCalcRewards = true; 
    uint256 public HolderPos;
    uint256 public DistHolderPos;
   
  //  uint256 public UnassignedBNBs;
    uint256 public N_holders;
    uint32 N_perTransfer = 5;
    uint256 nonce = 1;
 //   uint256 public N_Pos = 0;
    
    uint256 public launch_time;
    uint32 public NumberofPayoutTokens;
    
    uint256 public LastRewardCalculationTime;
    

    
    uint256 public BuybackPotBNB;
    uint256 public HolderPotBNB;
    uint256 public AdminPotBNB;
    uint256 public ModPotBNB;
    uint256 public AirdropPot;
    uint256 public RafflePot;
    uint256 public LotteryPot;
    uint256 public NextBuybackMemberCount;
    
    uint256 private HolderPotBNBcalc;
    
    uint256 burnUntil;
event Airdrop_(address _address, uint256 _tokenAmount);
event Buyback_(uint256 TokensBought, uint256 NumberofHolders);
event TokensBurned(uint256 amount);
event LotteryWon_(address _winner, uint256 _tokenAmount);
event RewardsRedistributedfromDeadWallets(uint256 RecoveredWei);
//event RewardClaimed(uint256 Wei, string Currency);
event RewardsRecalculated();
event PromotedtokenoftheWeek(string PromoToken);
event TOKEN_LAUNCHED();

    
   struct AirdropSettings 
   {
    uint256 timeoflastPayout;
    uint256 timebetweenpayouts;
    uint256 numberofcontractsperPayout;
    uint8 percentageofPottoDrop;
    bool isActive;
    uint256 totalPaidOut;
    uint256 minimumBalance;
   }
   
   AirdropSettings Airdrop;
   
   
      struct BuybackSettings 
   {
    uint256 bnbbuybacklimit;
    uint32 maxpercentageofPottobuyback;
    bool isActive;
   }
   
   BuybackSettings  Buyback;
   



    //TestNet    
    address constant routerAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    //address constant routerAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
   
    IPancakeRouter02 _pancakeRouter;// = IPancakeRouter02(routerAddress);
    address public _pancakePairAddress;// = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()); 


    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
      //AddtoAdminList(msg.sender);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    
 /*      function getPancakeWBNBaddr() public view virtual  returns (address) {
        return _pancakeRouter.WETH();
    }
    
              function getRouterAddress() public view virtual  returns (address) {
        return address(_pancakeRouter);
    }
    
              function getPancakePair() public view virtual  returns (address) {
        return _pancakePairAddress;
    }
 */   
            function getContract() public view virtual  returns (address) {
        return address(this);
    }


    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

            modifier onlyAdmin() {
            bool isAdmin = false;
 
        for(uint i = 0; i < AdminList.length; i++)    
        {
            if((AdminList[i])==(_msgSender()))
             isAdmin = true;
        }
        
        if((_msgSender() != _marketingowner)&&(_msgSender() != _owner))
        require(isAdmin == true, "Admin");
        _;
    }
    
    modifier onlyMark() {
      if(_msgSender() != _marketingowner)
      require(_msgSender() == _owner, "Reserved");
      _;
   }    

       function getContractAddress() private view returns (address) {
           
       return address(this);}
        
 /*       function toggleTax() public onlyMark(){

          _enableTax = !_enableTax;  
        }
  */      
        function StartLaunch(uint256 newNextBuybackMemberCount) public { //cannot be undone
        require(_msgSender() == _owner, "not owner");
        require(_isLaunched == false, "Launched");
          launch_time = block.timestamp;
          LastRewardCalculationTime = block.timestamp;
          _enableTax = true; 
          Airdrop.isActive = true;
          Buyback.isActive = true;
          _isLaunched = true;
          _enableTransfer = true;
          NextBuybackMemberCount = newNextBuybackMemberCount;
          emit TOKEN_LAUNCHED(); //GO!!!
        }
        
        
        
  /*     function ToggleTransfers() public onlyMark() {
          if(!_isLaunched) 
         _enableTransfer = !_enableTransfer;// cannot disable transfers after launch 
        }
  */      
    
    //only run once
    function setMarketingOwnership(address payable newMarketOwner) public {
        require(_msgSender() == _owner, "owner");

        _marketingowner = newMarketOwner;
        _excludedfromTax[_marketingowner] = true;
    //    _isTaxed[_owner] = false;
    } 
    
    
/*    //LWallet can only be set once - for transferring liquidity tax back to contract
    function setLiquidityOwnership(address newLiquidityOwner) public onlyMark() {
        _liquidityowner = newLiquidityOwner;
    } 
*/    
 /*   
        function setPancakeOwnership(address newPancakeOwner) public onlyMark(){
        _pancakeowner = newPancakeOwner;
    } 
 */    
    
    function setPromotedRewardTokenoftheWeek(uint32 newTOTW, uint32 _PromoPerc) public onlyAdmin(){
        require(newTOTW < NumberofPayoutTokens);
        PromoPerc = _PromoPerc;
        RewardTokenoftheWeek = newTOTW;
        if(PromoPerc>0) //0% means promo inactive
        emit PromotedtokenoftheWeek(PayoutTokenListNames[RewardTokenoftheWeek]);
    } 
    
        function getPromotedRewardTokenoftheWeek() public view returns(string memory){

        return PayoutTokenListNames[RewardTokenoftheWeek];
    } 

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    
        function getSellSlippage() public view virtual returns (uint32) {
            uint256 current_time = block.timestamp;
           
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

    function DistributeBuyTax(address sender, uint256 amount) private returns (uint256){
        
        //payouts 
        //40% buybackpot in bnb
        //40% holders in bnb 
        //10% marketing bnb
        //6% admin in bnb
        //4% mods in bnb
        
        //no tax taken debug
        
            //buy slippage 10-11%
        uint256 TaxAmount = amount * 10 / 100;
        
        _transfer(sender,address(this),TaxAmount);
        //emit Transfer(sender,address(this),TaxAmount);
      uint256 TaxAmountbnb;
      TaxAmountbnb = BalanceBNB;
      _swapTokenForBNB(TaxAmount); //errors if tax is insufficient amount
      TaxAmountbnb = BalanceBNB - TaxAmountbnb;
     
    
        //40% buybackpot
        BuybackPotBNB += TaxAmountbnb * 40 / 100;
        
        //40% holders in bnb 
        HolderPotBNB += TaxAmountbnb * 40 / 100;
        
        //10% marketing bnb
        
    
         uint256 MarketingBNB = TaxAmountbnb * 10 / 100;
          
        SendBNBfromContract(MarketingBNB, payable(_marketingowner));
            

        
        //6% admin in bnb
        
        AdminPotBNB += TaxAmountbnb * 6 / 100;
        
        //4% mods in bnb
        
        ModPotBNB += TaxAmountbnb * 4 / 100;
        
     

        return amount - TaxAmount;
    }
    
    uint32 Debug;
    function setDebug(uint32 debug) public
    {
        Debug = debug;
    }
    
    function DistributeSellTax(address sender, uint256 amount) private returns (uint256){
        //payouts
        //35% lq to pancake lq 
        //50% holder BNB
        //6% promo BNB
        //1% airdrop token
        //2% lottery token
        //4% admin in bnb
        //2% mod in bnb
        
        
        //issue with amounts
        
        uint256 netamount = amount;
        
        //SellSLippage = getSellSlippage();
        uint256 TaxAmount = amount * getSellSlippage() / 100;
        
        _transfer(sender,address(this),TaxAmount); //send tax to contract address
        
      //  uint256 TaxTemp;
        
           netamount -= TaxAmount * 205 / 1000; //1% airdrop tax + 2% lottery tax + 17.5% liquidity in tokens
             
              //1% airdrop token    
            AirdropPot += TaxAmount * 75 / 10000; //0.75% to random airdrops
            RafflePot +=  TaxAmount * 25 / 10000; // 0.25%  to Raffle airdrops
            
        
            //2% lottery token   
            LotteryPot += TaxAmount * 2 / 100; //2% to lottery pot
        
      //since the remaining 79.5% is converted to bnb, the calculation percentages need to be normalized.
      //50% total tax * 100/79.5    = 62.89 % bnb tax portion
      //17.5% total tax * 100/79.5  = 22.01 % bnb tax portion
      //6% total tax * 100/79.5     = 7.55 % bnb tax portion
      //4% total tax * 100/79.5     = 5.03 % bnb tax portion
      //2% total tax * 100/79.5     = 2.52 % bnb tax portion
                            //      +=> 100% bnb tax portion
       uint256 bnbTax = TaxAmount * 795 / 1000; 
       netamount -= bnbTax;
       uint256 bnbfromTax = BalanceBNB;
       _swapTokenForBNB(bnbTax);  //rest is converted back to bnb
      bnbfromTax = BalanceBNB - bnbfromTax; 
         //50% holder BNB
            HolderPotBNB += bnbfromTax * 6289 / 10000;  //adds to holder reward pot
     
       //6% promo BNB   
         uint256 MarketingBNB = bnbfromTax * 755 / 10000;
          
                      if(SendBNBfromContract(MarketingBNB, payable(_marketingowner))==false)
                        BuybackPotBNB += MarketingBNB; //fallback if fails
     
         //4% admin in bnb      
            AdminPotBNB += bnbfromTax * 503 / 10000;
        
        //2% mod in bnb     
            ModPotBNB += bnbfromTax * 252 / 10000;
        
            //35% lq to pancake lq 
  if(Debug==2)   //fails   
     {       
          //  netamount -= LQTax;
    uint256 LQTaxBNB = bnbfromTax * 2201 / 10000; // half of 35% liquidity tax converted to BNB
    uint256 LQTaxToken = quotepriceToken(LQTaxBNB);
            if((_balances[address(this)] > LQTaxToken)&&(BalanceBNB >=  LQTaxBNB))
            _addLiquidityFromContract(LQTaxToken, LQTaxBNB);//sends tokens from contract along with LQ tax
            else
            HolderPotBNB += LQTaxBNB;
     }  
    
        
        return netamount;
    }
    
   
   
    
        function _burn(address account, uint256 amount) internal virtual {
       //require(account != address(0), "burn frm 0addr");
        address deadwallet = address(0x000000000000000000000000000000000000dEaD);
        //_beforeTokenTransfer(deadwallet, amount);

        if(_balances[account] >= amount)
        {
        unchecked {
            _balances[account] -= amount;
        }
        _totalSupply -= amount;
       
        emit Transfer(account, deadwallet, amount);
        emit TokensBurned(amount);
        }
    }

    function AddtoModList(address ModAddress) public onlyAdmin() {
        ModList.push(ModAddress);
    }
    
    function excludefromTax(address excl) public onlyMark(){
        _excludedfromTax[excl] = true;
    }
    
        function UndoexcludefromTax(address excl) public onlyMark(){
        _excludedfromTax[excl] = false;
    }
    
        function AddTokentoPayoutList(address TokenAddress, string memory Name) public onlyAdmin(){
        
     // if((TokenAddress != _pancakeRouter.WETH())&&(TokenAddress != address(this)))
   //not required
     if(TokenAddress != address(this))
      {
       // address TokenPair = IPancakeFactory(_pancakeRouter.factory()).getPair(address(this), TokenAddress); 
       // _exludedFromTax[TokenPair] = true;
       //_isregistered[TokenPair] = true;
      }
      
       // PayoutTokenList[NumberofPayoutTokens] = TokenAddress;
       PayoutTokenList.push(TokenAddress);
        PayoutTokenListNames.push(Name);
      //  PayoutTokenListNames[NumberofPayoutTokens] = Name;
        NumberofPayoutTokens++;
    }

    
        function UndoAddTokentoPayoutList() public onlyAdmin(){
        
        require(NumberofPayoutTokens > 0);
        PayoutTokenList.pop();
        PayoutTokenListNames.pop();
        NumberofPayoutTokens--;
    }
    
    function RemoveFromModList(address ModAddress) public onlyMark() {
        
        address[] memory tempArray;
        
        for(uint k = 0; k < ModList.length; k++)
        {  uint256 i = 0;
            if(ModList[k] != ModAddress)  ///to complete
            {i++;
             tempArray[i] = ModList[k];
            }
        }
        ModList.pop();
        for(uint j = 0; j < tempArray.length; j++)
         ModList[j] = tempArray[j];
        
    }
    
    function AddtoAdminList(address AdminAddress) public onlyMark() {
        ModList.push(AdminAddress);
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
        require(PayoutTokenNumber < NumberofPayoutTokens, "Out of bounds");
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
        require(Whole > 0, "Please enter % payout for each token");
       
       uint32 N = uint32(NumberofPayoutTokens);
       bool OutofBounds = ((Token1 >= N)||(Token2 >= N)||(Token3 >= N)||(Token4 >= N)||(Token5 >= N)||(Token6 >= N));
        require(OutofBounds == false, "Out of Bounds");
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
    
    receive () external payable {
        BalanceBNB += msg.value; //bnb sent to contract by accident gets added to buyback pot
    } // fallback to receive bnb

     
     
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       require(_enableTransfer, "paused");
       _beforeTokenTransfer(recipient,msg.sender, amount);
       
       

      uint256 netamount = taxtransfer(msg.sender, recipient, amount);
              _transfer(_msgSender(), recipient,netamount);
      return true; 

    }
   
         function PlayLotto(uint256 buyamount) private returns (uint256) {
          //  uint256 maxMultiplier = 2;  // wins x2 purchase amount
          //  uint256 winningprobability = 5; //5% chance of max multiplier
             uint256 winnings;
             
             //uint256 randomnum = random();
             
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
       return winnings; 
    }
    function ToggleAutoCalcRewards() public onlyMark(){
        _AutoCalcRewards = !_AutoCalcRewards;
    }
    
       function taxtransfer(address sender, address recipient, uint256 amount) private returns (uint256){    
       //if not taxed => does not partake in lotto reward
         //////Transfer tax if enabled
         uint256 netamount = amount;
       
       if((_excludedfromTax[sender]==false)&&(_enableTax==true))
        //if(sender != address(this)) //dont tax contract
        // if((sender != _pancakePairAddress) && (recipient != routerAddress))//liquidity transfer not taxed ///CHECK PUT BACK? No tax disabled?
       {
           
            
           if(_AutoCalcRewards==true)
       {////////// the gas for this work gets refunded as far as possible
            uint256 startGas = gasleft();
               AirdropPayout(); //checks if its time for next airdrop and does it
               doBuyback();
           if(_CalculatingRewards == false)
           {if(block.timestamp - LastRewardCalculationTime > 3600) //recalculated every hour
             {
                    HolderPotBNBcalc = HolderPotBNB; //used as reference for calculation
                    _CalculatingRewards = true; //flag that calculation is in progress
                    _PayTeam();  //// PUT BACK/////
             }
           }
            else
            {
            CalculateRewards(N_perTransfer);//calculate some rewards       ////PUT BACK///
            }
            _DistributeRewards(N_perTransfer);//pay out some rewards    ////PUT BACK///
      {
             uint256 Gas = startGas - gasleft();     
        //repay gas
              if(Gas<BuybackPotBNB)
                {   BuybackPotBNB -= Gas;
                    SendBNBfromContract(Gas, payable(msg.sender));
                 }
            }
           }
           
          ////////     
           
       
         //differentiate between buy/sell/transfer to apply different taxes/restrictions
        // if(_AutoCalcRewards!=true)////TEMP DEBUG
         //{
        if((recipient==_pancakePairAddress) || (recipient == routerAddress))  // sell
        { 
       netamount = DistributeSellTax(sender, amount); //fails //function distributes sell tax and returns the remaining token balance
       //doBuyback();

        }
        else   // other transfers
        {

      netamount = DistributeBuyTax(sender, amount); //msg.sender? //no tax drawn

            
       // if((sender==_pancakePairAddress) || (sender == routerAddress))   //play lotto only if buy transaction CHECK put back?
       //  {
        uint256 winnings = 0;//PUT BACK//// PlayLotto(amount);
         if(winnings>0)// Lotto won
         if(LotteryPot>0) //the pot is not empty
          {
            if(winnings > LotteryPot)
                  winnings = LotteryPot;
           
          
            LotteryPot -= winnings;
          _transfer(address(this), recipient, winnings);
           emit LotteryWon_(recipient, winnings); 
          }
      //   }
        }
        
       }
       //}
       return netamount; 
   }
        
    function random() internal returns (uint256) {  //random number between 0 and 100
    uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
    
    nonce++;
    return randomnumber;
}

function StartRewardCalculation() public onlyAdmin(){
   require(_CalculatingRewards == false);
   HolderPotBNBcalc = HolderPotBNB; //used as reference for calculation
   _CalculatingRewards = true;
}

function setAutoCalcRewards(bool val) public onlyMark(){
        _AutoCalcRewards = val;
    }

function CalculateNRewards(uint256 counts) public {
  // function calculates rewards 
  require(_CalculatingRewards == true, "Rewards up 2 date");
  if(counts > 0)
  {
     uint256 startGas = gasleft();


   CalculateRewards(counts); 
  
  
      uint256 Gas = startGas - gasleft() + 31000;
    //reimburse gas
    if(Gas<=BuybackPotBNB)
    {   BuybackPotBNB -= Gas;
        SendBNBfromContract(Gas, payable(msg.sender));
 }
  }
}
function Payteam() public {
   _PayTeam(); 
}


function _PayTeam() private {
    
        {//admin
        
        uint256 L = AdminList.length;
         if(L>0)
           { uint256 Adminshare = AdminPotBNB / L;
            for(uint32 pos = 0 ; pos < L; pos++)
            {
                address payable add = payable(AdminList[pos]);
                if(Adminshare <= AdminPotBNB) 
                {
                SendBNBfromContract(Adminshare, add);
                
                AdminPotBNB -= Adminshare;
                }
                else
                {
                SendBNBfromContract(AdminPotBNB, add);
                AdminPotBNB = 0; //avoid rounding errors
                }
            }
        }
        }
        //mod
        {
        
         uint256 L = ModList.length;
         if(L>0)
           { uint256 Modshare = ModPotBNB / L;
            for(uint32 pos = 0 ; pos < L; pos++)
            {
                address payable add = payable(AdminList[pos]);
                if(Modshare <= ModPotBNB) 
                {
                SendBNBfromContract(Modshare, add);
                ModPotBNB -= Modshare;
                }
                else
                {
                SendBNBfromContract(ModPotBNB, add);
                ModPotBNB = 0; //avoid rounding errors
                }
            }
        }
        }
}
function setNperTransfer(uint32 N) public onlyAdmin{
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
        uint256 DivideBy = _totalSupply - _balances[address(this)] - _balances[_pancakePairAddress] - _balances[routerAddress]; //circulating supply
        if(DivideBy>0)//safety check
        for (uint256 k = startpos; k <= stoppos; k++)
         { address holder = investorList[k];
         if((holder != address(this))&&(holder != address(0))&&(holder !=_pancakePairAddress&&(holder !=routerAddress)))  //contract and Liquidity pool excluded
         {
            uint256 bal = _balances[holder];
            if(_PrevBalance[holder]<bal)
              bal = (_PrevBalance[holder]); //only rewarded for tokens held for the full period
            uint256 NewEarnings = Pot * bal / DivideBy; 
            if(NewEarnings <= Pot)
            {
            Pot -= NewEarnings;     
             _earnings[holder] += NewEarnings;
             _PrevBalance[holder] = _balances[holder];
             
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
        
        


       ////////////function to pay out chosen token. returns bnb sent

function _BuyBackTokensBNB(uint256 amountBNB) private returns (uint256)
{
    uint[] memory amounts;
    address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);
   amounts = _pancakeRouter.swapExactETHForTokens(amountBNB, path, address(this), block.timestamp);
    
    BalanceBNB -= amounts[0];
    
        return amounts[1]; //number of tokens bought back
}
//allows caller to claim all accumilated earnings in the payout token of choice
function ClaimMyRewards() public
{ 
require(_earnings[msg.sender] > 0, "All rewards claimed");
require(_balances[msg.sender] > 0, "Only token holders can claim");
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
function DistributeRewards(uint32 count) onlyAdmin() public
{uint256 startGas = gasleft();
        _DistributeRewards(count);
 uint256 Gas = startGas - gasleft() + 21000;
    //reimburse gas
    if(Gas<=BuybackPotBNB)
    {   BuybackPotBNB -= Gas;
        SendBNBfromContract(Gas, payable(msg.sender));
    }   
}

//function for hosting raffles and paying out winners 
function sendAirdrop(uint256 Tokens, address recipient) public onlyAdmin()
{  uint256 _Tokens = Tokens * 10**18;
    require(_Tokens <= 10,"max 10 tokens");
    require(_Tokens <= RafflePot,"Balance low");
    RafflePot -= _Tokens;
    _transfer(address(this), recipient, _Tokens);
    emit Airdrop_(recipient, _Tokens);
}

//auto payout called by marketing wallet
function _DistributeRewards(uint32 count) private
{   uint32 runs;
    uint32 tries;
    uint32 maxtries = count * 3; 
   
    while(runs < count)
   { tries++;
     if(tries >= maxtries)
      runs = count + 1; //quit loop
    address recipient = investorList[DistHolderPos];
    if((_AutoPayoutEnabled[recipient])&&(_LastPayout[recipient] > block.timestamp + 1800))// last claimed 30min ago    
    ClaimRewards(payable(recipient));
    runs++;
    DistHolderPos++;
    if(DistHolderPos >= N_holders)
     {
     DistHolderPos = 0; //restart list
     runs = count + 1; //quit loop
     }
    }
}
/////setprivate////
function ClaimRewards(address payable receiver) public returns(bool){
  if((_earnings[receiver] > 0)&&(_balances[receiver] > 0))
  {  uint256 amountBNB = _earnings[receiver];
     distributed += amountBNB;
    if(PromoPerc > 0)
    {
      uint256 promotokenBNB = amountBNB * PromoPerc / 100;
      amountBNB -= promotokenBNB;
      _swapBNBforChosenTokenandPayout(promotokenBNB,PayoutTokenList[RewardTokenoftheWeek],receiver);
    }
 

    if(_SplitTokenRewards[msg.sender] == false)
    { //single token reward
    address PayoutTokenContract = PayoutTokenList[_RewardTokens[receiver].Token1];
     if(PayoutTokenContract == _pancakeRouter.WETH()) //payout bnb
     {
       if(SendBNBfromContract(amountBNB, payable(receiver)))
           _earnings[receiver] = 0; 
     }
     else
     {
    _swapBNBforChosenTokenandPayout(amountBNB,PayoutTokenContract,receiver);
    _earnings[receiver] = 0;
     }
    }
    else
    { //Split token rewards
    uint256 BNBslice;
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
      
      
      for(uint32 i = 0; i < 6; i++)
      {
       if((slices[i] > 0)&&(pie <= 100))
       {
        percslice = slices[i];  
        if(pie+percslice>100)// check for sneaky percentages
         percslice = 100-pie;
         pie += percslice;
         BNBslice = amountBNB * percslice / 100;
         if(BNBslice>_earnings[receiver])
          BNBslice = _earnings[receiver]; //safety check
      PayoutTokenContract = PayoutTokenList[tokennumbers[i]];
      
      if(PayoutTokenContract == _pancakeRouter.WETH()) //payout bnb
    {
       if(SendBNBfromContract(BNBslice, payable(receiver)))
           _earnings[receiver] -= BNBslice; 
    }
    else
    {
      _swapBNBforChosenTokenandPayout(BNBslice,PayoutTokenContract,receiver); 
       _earnings[receiver] -= BNBslice;
      }
       }
      if((pie<100)) //pays out unselected part in BNB
       {
         if(SendBNBfromContract(_earnings[receiver], payable(receiver)))
           _earnings[receiver] = 0;
       }
    }
   }
    _LastPayout[receiver] == block.timestamp;

 }
 return true;
} 

function AvailableRewards() public view returns(uint256){
   
    return _earnings[msg.sender];
}

/*function SendBNBfromContract(uint256 amountBNB, address payable receiver) private returns (bool) 
{ 
   
   require(BalanceBNB >= amountBNB,"too much");
   
   if(receiver.send(amountBNB)) //sends in wei
   {
    BalanceBNB -= amountBNB;
    return true;
   }
   return false;
}*/


//Wallets that do not claim rewards for 6 months are considered dead and their unclaimed earnings redistributed
function SkimDeadWallets(uint256 startpos, uint256 stoppos) public onlyMark(){
     if(stoppos > N_holders)
      stoppos = N_holders;
     
     uint256 RecoveredWei = 0;
     for(uint256 i = startpos; i < stoppos; i++)
     {
         if(block.timestamp - _LastPayout[investorList[i]] > 15552000) //last claimed more than 180 days ago
          {   _LastPayout[investorList[i]] = block.timestamp;
              RecoveredWei += _earnings[investorList[i]]; 
              _earnings[investorList[i]] = 0;
          }
     }

       HolderPotBNB += RecoveredWei; //redistributes to holders
      emit RewardsRedistributedfromDeadWallets(RecoveredWei);
}


 





function SetAirdrop(uint256 HoursBetweenAirdrops, uint8 NumberofAddresses, uint8 PercentageofPotperDrop) public onlyAdmin() 
{ 
   Airdrop.timeoflastPayout = block.timestamp;
   Airdrop.timebetweenpayouts = HoursBetweenAirdrops * 3600; 
   Airdrop.numberofcontractsperPayout = NumberofAddresses;
   Airdrop.percentageofPottoDrop = PercentageofPotperDrop;
   Airdrop.isActive = true;
}
/*
function pauseAirdrop() public onlyAdmin() 
{ 
   Airdrop.isActive = false;
}
*/
/////setprivate////
function AirdropPayout() private {
    if(N_holders > 0)
    if((Airdrop.isActive == true)&&(Airdrop.numberofcontractsperPayout > 0)&&(block.timestamp - Airdrop.timeoflastPayout > Airdrop.timebetweenpayouts))
   {
      uint256 payoutperwinner =  AirdropPot * Airdrop.percentageofPottoDrop / 100;
      payoutperwinner = AirdropPot / Airdrop.numberofcontractsperPayout;
      uint256 tries;
      uint256 maxtries = Airdrop.numberofcontractsperPayout * 3; 
      uint256 Dropsmade;
    while(tries < maxtries) 
    {  
         uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (N_holders);
         nonce++;
    
      address winner = address(investorList[randomnumber]);
        if((_balances[winner] >= Airdrop.minimumBalance)&&(_excludedfromTax[winner]==false)&&(payoutperwinner <= AirdropPot))
        {
        AirdropPot -= payoutperwinner;    
         _transfer(address(this), address(winner), payoutperwinner);
         
         Airdrop.totalPaidOut += payoutperwinner;
         emit Airdrop_(winner, payoutperwinner);
         Dropsmade++;
         if(Dropsmade >= Airdrop.numberofcontractsperPayout)
         tries = maxtries;
        }
        tries++;
    }

    Airdrop.timeoflastPayout = block.timestamp;
   }
}


function SetBuyback(uint8 maxpercentageofPottobuyback,uint32 maxbnb, bool isactive) public onlyMark()
{ 



   Buyback.maxpercentageofPottobuyback = maxpercentageofPottobuyback;

   Buyback.bnbbuybacklimit = maxbnb * 10**18;
   Buyback.isActive = isactive;
}

/*function quotepriceBNB(uint256 Tokens) public view returns (uint[] memory amounts)
{
    
     address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
       amounts =  _pancakeRouter.getAmountsOut(Tokens, path); 
   
    return amounts;
}
*/
function quotepriceToken(uint256 BNBs) public view returns (uint256)
{
    address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);
       uint[] memory amounts = _pancakeRouter.getAmountsOut(BNBs, path); 
    
    return amounts[1];
}

function doBuyback() private
{
   if((Buyback.isActive == true)&&(N_holders >= NextBuybackMemberCount)) 
   {
     uint256 amountBNB = BuybackPotBNB * Buyback.maxpercentageofPottobuyback / 100;
       if(amountBNB > Buyback.bnbbuybacklimit)
        amountBNB = Buyback.bnbbuybacklimit; //do not try to swap billions of bnb
      
      uint256 tokens;
      
          BuybackPotBNB -= amountBNB;
          tokens = _BuyBackTokensBNB(amountBNB);
    //burn tokens
    if (_totalSupply - tokens > burnUntil)
    {
        _burn(address(this), tokens);
    }
       emit Buyback_(tokens, N_holders); 
    
     NextBuybackMemberCount = NextBuybackMemberCount + 1500;
    
   
 }
 /*{
   if((Buyback.isActive == true)&&(block.timestamp - Buyback.timeoflastBuyback > Buyback.timebetweenBuybacks)) 
   {
   //approximates order of price drop 
    uint256 PriceDrop = 1000000 * sellamount / _totalSupply;
    if(PriceDrop >= Buyback.ppmPriceDrop)
    { uint256 amountBNB = BuybackPotBNB * Buyback.maxpercentageofPottobuyback / 100;
       if(amountBNB > Buyback.bnbbuybacklimit)
        amountBNB = Buyback.bnbbuybacklimit; //do not try to swap billions of bnb
      BuybackPotBNB -= amountBNB;
      uint256 tokens = _BuyBackTokensBNB(amountBNB);
      
      
      uint256 PercSell = 100 * tokens / sellamount; //check if not overcompensating;
      if(PercSell > Buyback.maxpercentageofSelltobuyback)
      {
          uint256 tokenstoSell = tokens * (PercSell - Buyback.maxpercentageofSelltobuyback) / 100;
          uint256 bnbfromSellback = _swapTokenForBNB(tokenstoSell);
          BuybackPotBNB += bnbfromSellback;
          
          tokens -= tokenstoSell;
      }
      
    //burn tokens
    if (_totalSupply - tokens > burnUntil)
    {
        _burn(address(this), tokens);
       emit Buyback_(amountBNB, tokens);
    }
    else 
       emit Buyback_(amountBNB, 0); //burning stopped;
    
     Buyback.timeoflastBuyback = block.timestamp;
    }
   }
 }  */
}

function _swapBNBforChosenTokenandPayout(uint256 amountBNB,address PayoutTokenContract, address payable receiver) private {
  
      uint256 tokens;
/*    if(PayoutTokenContract == _pancakeRouter.WETH()) 
     {//payout bnb
         SendBNBfromContract(amountBNB, receiver);
     }
     else
     if(PayoutTokenContract == address(this)) 
     {//payout native token
         tokens = _BuyBackTokensBNB(amountBNB);
         _transfer(address(this), address(receiver), tokens); 
         
     }
     else
     */ 
     {//payout user defined token
      tokens = _BuyBackTokensBNB(amountBNB);
      _approve(address(this), address(_pancakeRouter), tokens);//?
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PayoutTokenContract;

      _pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(receiver),
            block.timestamp + 20
        );
     }
    }


    function _swapTokenForBNB(uint256 amount) public  {//set private //errors if tax is insufficient amount
      //  if(Debug < 10)
        _approve(address(this), address(_pancakeRouter), amount);//?
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

       _excludedfromTax[address(_pancakeRouter)] = true;
       _excludedfromTax[_pancakePairAddress] = true;
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
       _excludedfromTax[address(_pancakeRouter)] = false;
       _excludedfromTax[_pancakePairAddress] = false;
        

        
    }


/*


    function _swapTokenForBNB(uint256 amount) private returns (uint256 amountBNB) {
      //  if(Debug < 10)
        _approve(address(this), address(_pancakeRouter), amount);//?
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();



uint[] memory amounts;
       _excludedfromTax[address(_pancakeRouter)] = true;
       _excludedfromTax[_pancakePairAddress] = true;
       amounts =  _pancakeRouter.swapExactTokensForETH(  ///not working if router/pair taxed
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
       _excludedfromTax[address(_pancakeRouter)] = false;
       _excludedfromTax[_pancakePairAddress] = false;
        
        BalanceBNB += amounts[1];
        return amounts[1];
        
    }
*/

    //swaps tokens on the contract for BNB and sends to receiver
 /*   function _swapTokenForBNBandSend(uint256 amount, address payable receiver) private returns (uint256){

       _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

      
      /*  _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
        
uint[] memory amounts;
       _excludedfromTax[address(_pancakeRouter)] = true;
       _excludedfromTax[_pancakePairAddress] = true;
       amounts =  _pancakeRouter.swapExactTokensForETH(  ///not working if router/pair taxed
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
       _excludedfromTax[address(_pancakeRouter)] = false;
       _excludedfromTax[_pancakePairAddress] = false;
        
        BalanceBNB += amounts[1];
      
       
       if(receiver != address(this))
       SendBNBfromContract(amounts[1],receiver);
       
       return amounts[1];
    }
   */ 
    
    //ERROR transferfrom:transferfrom failed
    //Adds Liquidity directly to the contract where LP are locked
    function _addLiquidityFromContract(uint256 tokenamount, uint256 bnbamount) public {//set private
       // if(Debug < 10)
        _approve(address(this), address(_pancakeRouter), tokenamount);
        
      _enableTax = false;
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            _owner,//address(this),
            block.timestamp
        );
         _enableTax = true;
    }


       
 //works
function SendBNBfromContract(uint256 amountBNB, address payable receiver) public returns (bool) //set to private
{ if(amountBNB<=BalanceBNB)
   if(receiver.send(amountBNB)) //sends in wei
   {
    BalanceBNB -= amountBNB;
    return true;
   }

   return false;
}


    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
     _beforeTokenTransfer(recipient,sender, amount);
       require(_enableTransfer, "paused");
       //
       uint256 netamount = taxtransfer(sender, recipient, amount);////CHECK
        _transfer(sender,recipient,netamount);
       
     
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, ">allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "allowance<0");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "bal<");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        
        _beforeTokenTransfer(account,address(0), amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "appr frm0");
        require(spender != address(0), "appr2 0");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address to, address from, uint256 amount) internal virtual { 
      bool LiqTX;
      
      if(((_excludedfromTax[from]==true)||(from == routerAddress)) && ((to == _pancakePairAddress)||(to == routerAddress))) //liquidity transfers excluded
      {LiqTX = true;
    // _isregistered[routerAddress] = true;
    // _excludedfromTax[routerAddress] = true;
      }

      
      if((LiqTX == false)||(from != address(this)))//check
      if(_isLaunched == true) //after launch buy sell limit activated
       require(amount <= 1000 * 10**18, "Max:1000tokens/0.1%");
       else //not launched yet
       require(_excludedfromTax[msg.sender], "Transfers disabled until Launch :)");
       // if(_balances[to] = 0)  //check for new holder
        if(_isregistered[to] == false)  //avoid reregistering wallets that try to be sneaky
        {investorList.push(to); //add new holder to list
        _isregistered[to] = true;
        _LastPayout[to] = block.timestamp;
        _AutoPayoutEnabled[to] = false;
         N_holders++;
         _excludedfromTax[to] = false;
         _RewardTokens[to].Slice1 = 100; //one coin chosen
        }
    }
    
  
}


abstract contract Ownable is Context {
       ////Ownable
  //   address private _owner;
     address private _previousOwner;
  //   uint256 private _lockTime;
     
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
      constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
        function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }
    
        function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
       // require(newOwner != address(0), "0 addr");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    



}


//////Pancake
    interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  //  function feeTo() external view returns (address);
 //   function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
 //   function allPairs(uint) external view returns (address pair);
 //   function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

 //   function setFeeTo(address) external;
 //   function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

/*
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
*/
 //   function approve(address spender, uint value) external returns (bool);
//    function transfer(address to, uint value) external returns (bool);
//    function transferFrom(address from, address to, uint value) external returns (bool);

 //   function DOMAIN_SEPARATOR() external view returns (bytes32);
 //   function PERMIT_TYPEHASH() external pure returns (bytes32);
 //   function nonces(address owner) external view returns (uint);

//    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//    event Mint(address indexed sender, uint amount0, uint amount1);
//    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
 /*   event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );*/
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
 //   function token0() external view returns (address);
 //   function token1() external view returns (address);
 //   function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  //  function price0CumulativeLast() external view returns (uint);
  //  function price1CumulativeLast() external view returns (uint);
  //  function kLast() external view returns (uint);

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


    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);


//    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
//    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
//    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
//    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


/////////////////////////////////Contract

// PancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E
// testnet = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
contract TestToken1 is ERC20, Ownable {
    using SafeMath for uint256;

   

  constructor() ERC20 ("testtoken", "$$$"){
   
     uint256 initialSupply = 1000000* 10**(18); 
     excludefromTax(msg.sender);
   _mint(msg.sender,initialSupply/2);
   excludefromTax(msg.sender);
   excludefromTax(address(this));
   _mint(address(this),initialSupply/2);
   excludefromTax(address(this));
  RafflePot = initialSupply * 2 / 100; // 2% reserved in raffle pot to send airdrops to promotion winners
   setMarketingOwnership(payable(msg.sender)); //sets owner wallet Marketing Wallet as default
   
     burnUntil = initialSupply * 50 / 100; //burn until 50% of total supply left
     _pancakeRouter = IPancakeRouter02(payable(routerAddress));
     _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
      

      
    //  launch_time = block.timestamp;  //now as default - used for tax calculation
     AddTokentoPayoutList(_pancakeRouter.WETH(), "BNB"); //BNB added as default
     AddTokentoPayoutList(address(this), "$$$"); //this contract token
     
      
//airdrop settings
/*   Airdrop.timeoflastPayout  = block.timestamp;
   Airdrop.timebetweenpayouts = 5 * 60 * 60; //5 hours
   Airdrop.numberofcontractsperPayout = 5;
   Airdrop.percentageofPottoDrop = 10;
   Airdrop.isActive = false;
   Airdrop.totalPaidOut = 0;
 */
 //buyback settings  
 /*
  Buyback.timeoflastBuyback = block.timestamp;
  Buyback.timebetweenBuybacks = 4 * 60; // 4 minutes
  Buyback.maxpercentageofPottobuyback = 75;
  Buyback.maxpercentageofSelltobuyback = 85;
  Buyback.bnbbuybacklimit = 5; //5bnb per sell
  Buyback.PercPriceDrop = 2;
  Buyback.isActive = false;
  */ 
  } 


  

  
}
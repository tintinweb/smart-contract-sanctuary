/**
 *Submitted for verification at BscScan.com on 2021-07-06
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

    mapping (address => bool) private _isTaxed;
    mapping (address => bool) private _AutoPayoutEnabled;
    mapping (address => bool) private _isregistered; //default false

   address[] private investorList; /// test for large number 
   address[] private ModList;
   address[] private AdminList;
   
   address[] public PayoutTokenList;
   string[] public PayoutTokenListNames;

   uint256 public distributed;
   
   uint256 public BalanceBNB;
   
   uint8 private SellSLippage;
  

    uint256 public _totalSupply;
    address payable private _marketingowner = payable(address(this));
    address private _liquidityowner = address(this);
    address private _pancakeowner;
    string private _name;
    string private _symbol;
    
    bool private _enableTax = false; //default
    bool public _enableTransfer = true; //default
    bool public _isLaunched = false; 
    
    bool public _PauseRewardClaims = false; 
   
    
    uint256 public N_holders;
   // uint256 N_perTransfer = 4;
    uint256 nonce = 1;
 //   uint256 public N_Pos = 0;
    
    uint256 public launch_time;
    uint8 public NumberofPayoutTokens;
    

    
    uint256 public BuybackPotBNB;
    uint256 public HolderPotBNB;
    uint256 public AdminPotBNB;
    uint256 public ModPotBNB;
    uint256 public AirdropPot;
    uint256 public LotteryPot;
    
    uint256 private HolderPotBNBcalc;
    
    uint256 burnUntil;
event Airdrop_(address _address, uint256 _tokenAmount);
event Buyback_(uint256 _BNBSwapped, uint256 _tokensBurned);
event LotteryWon_(address _winner, uint256 _tokenAmount);
event RewardsRedistributedfromDeadWallets(uint256 RecoveredWei);
//event RewardClaimed(uint256 Wei, string Currency);
event RewardsRecalculated();
event Gasrefunded(uint256 gas); //debug

    
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
    uint256 timeoflastBuyback;
    uint256 bnbbuybacklimit;
    uint8 timebetweenBuybacks;
    uint8 maxpercentageofPottobuyback;
    uint8 maxpercentageofSelltobuyback;
    uint32 ppmPriceDrop;
    bool isActive;
   }
   
   BuybackSettings  Buyback;
   



    //TestNet    
    address constant routerAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    //address constant routerAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address payable private _ALM = payable(address(0xE3e0ACAf010c94EAE14532957d759d462ADd3dC3));
    
    IPancakeRouter02 _pancakeRouter;// = IPancakeRouter02(routerAddress);
    address _pancakePairAddress;// = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()); 


    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    
       function getPancakeWBNBaddr() public view virtual  returns (address) {
        return _pancakeRouter.WETH();
    }
    
              function getRouterAddress() public view virtual  returns (address) {
        return address(_pancakeRouter);
    }
    
              function getPancakePair() public view virtual  returns (address) {
        return _pancakePairAddress;
    }
    
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
        require(isAdmin == true, "Admin function");
        _;
    }
    
    modifier onlyMark() { 
      if(_msgSender() != _marketingowner)
      require(_msgSender() == _owner, "Reserved function");
      _;
   }    

       function getContractAddress() private view returns (address) {
           
       return address(this);}
        
        function enableTax() public onlyMark(){

          _enableTax = true; // starts Taxing transfers - cannot be undone 
        }
        
        function StartLaunch() public { //cannot be undone
        require(_msgSender() == _owner, "not owner");
        require(_isLaunched == false, "Already launched");
          launch_time = block.timestamp;
          _enableTax = true; 
          Airdrop.isActive == true;
          Buyback.isActive == true;
          _isLaunched = true;
          _enableTransfer = true;
        }
        
        
       function disableTransfers() public onlyMark() {

         _enableTransfer = false; // Pause transfers before launch, owner excluded. Can only be performed by owner 
        }
        
       function enableTransfers() public onlyMark() {
         _enableTransfer = true;// Unpause transfers. Can only be performed by owner  
        }
        
       function getTaxEnabled() public view returns (bool) {
          return _enableTax;} //false by default
    
    //only run once
    function setMarketingOwnership(address payable newMarketOwner) public {
        require(_msgSender() == _owner, "owner");
        
        _isTaxed[_marketingowner] = true; //old one should be taxed again
        _marketingowner = newMarketOwner;
        _isTaxed[_marketingowner] = false;
        _isTaxed[_owner] = false;
    } 
    
    
    //LWallet can only be set once - for transferring liquidity tax back to contract
    function setLiquidityOwnership(address newLiquidityOwner) public onlyMark() {
        _liquidityowner = newLiquidityOwner;
    } 
    
        function setPancakeOwnership(address newPancakeOwner) public onlyMark(){
        _pancakeowner = newPancakeOwner;
    } 
    

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    
        function getSellSlippage() public view virtual returns (uint8) {
            uint256 current_time = block.timestamp;
           
       if(current_time >= launch_time + 5184000)     //after 60 days
       {
       return 10; //after 2 months
       }
       else
       if(current_time >= launch_time + 1209600)     //after 14 days
       {
       return 15; 
       }
       else
       if(current_time >= launch_time + 604800)     //after 7 days
       {
       return 20; 
       }
       else
       if(current_time >= launch_time + 259200)     //after 3 days
       {
       return 25; 
       }
       else
       if(current_time >= launch_time + 86400)     //after 1 days
       {
       return 30; 
       }
       else
       if(current_time >= launch_time + 28800)     //after 8 hours
       {
       return 35; 
       }
       else
       if(current_time >= launch_time + 10800)     //after 3 hours
       {
       return 40; 
       }
       else
       if(current_time >= launch_time + 60)     //after 1 min
       {
       return 48; 
       }
       else
       {
       return 90; //first minute
       }

    }

    function DistributeBuyTax(address sender, uint256 amount) private returns (uint256){
        
        //payouts 
        //40% buybackpot in bnb
        //40% holders in bnb 
        //10% marketing bnb
        //6% admin in bnb
        //4% mods in bnb
        
        
       // uint8 TaxPerc = 10;  //buy slippage 10-11%
        uint256 TaxAmount = amount * 10 / 100;
        _transfer(sender,address(this),TaxAmount);//fails if bal = 0
        
        uint256 TaxAmountbnb = _swapTokenForBNB(TaxAmount);  
     
        //40% buybackpot
        BuybackPotBNB += TaxAmountbnb * 40 / 100;
        
        //40% holders in bnb 
        HolderPotBNB += TaxAmountbnb * 40 / 100;
        
        //10% marketing bnb
        uint256 MarketingTax = TaxAmountbnb * 10 / 100;
        SendBNBfromContract(MarketingTax, _marketingowner);
        
        //6% admin in bnb
        {uint256 adminTax = TaxAmountbnb * 6 / 100;
        
        AdminPotBNB += adminTax;
        }
        //4% mods in bnb
        {uint256 modTax = TaxAmountbnb * 4 / 100;
        ModPotBNB += modTax;
        
        }

        return amount - TaxAmount;
    }
    
    function DistributeSellTax(address sender, uint256 amount) private returns (uint256){
        //payouts
        //50% lq to pancake lq 
        //30% holder BNB
        //7% promo token
        //1% airdrop token
        //2% lottery token
        //3% admin in bnb
        //2% mod in bnb
        //6%?
        
        uint8 TaxPerc = getSellSlippage();
        uint256 TaxAmount = amount * TaxPerc / 100;
        uint256 LQTax = TaxAmount * 50 / 100; 
        uint256 holderTax = TaxAmount * 30 / 100; 
        uint256 promoTax = TaxAmount * 7 / 100;
        uint256 airdropTax = TaxAmount * 1 / 100;
        uint256 lotteryTax = TaxAmount * 2 / 100;
        uint256 adminTax = TaxAmount * 3 / 100;
        uint256 modTax = TaxAmount * 2 / 100;
        uint256 burnTax = TaxAmount * 5 / 100;
       uint256 netamount = amount;
       
       
        
        //transfer tax amount to contract
          _transfer(sender,address(this),TaxAmount); 
          
       uint256 bnbTax = LQTax + holderTax + adminTax + modTax;
       uint256 bnbfromTax = _swapTokenForBNB(bnbTax);  
        
        //50% lq to pancake lq 
        {
            netamount -= LQTax;
            uint256 LQTaxBNB = bnbfromTax * LQTax / bnbTax; 
            LQTaxBNB = LQTaxBNB / 2;  //splits in half
            uint256 LQTaxToken = _BuyBackTokensBNB(LQTaxBNB); 
            _addLiquidity(LQTaxToken, LQTaxBNB);
        }
        //30% holder BNB
        {
            netamount -= holderTax;
            HolderPotBNB += bnbfromTax * holderTax / bnbTax;  //adds to holder reward pot
        }
        //7% promo token   OK
        { 
            netamount -= promoTax;
            _transfer(address(this),_marketingowner,promoTax); 
        }
        //1% airdrop token    OK
        {
            netamount -= airdropTax;
            AirdropPot += airdropTax;
            
        }
        //2% lottery token   OK
        {
            netamount -= lotteryTax;
            LotteryPot += lotteryTax;
        }
        //3% admin in bnb      OK
        { 
            netamount -= adminTax;
            AdminPotBNB += bnbfromTax * adminTax / bnbTax;
        }
        //2% mod in bnb     OK
        {
            netamount -= modTax;
            ModPotBNB += bnbfromTax * modTax / bnbTax;
        }
        //5% burn
        {
            netamount -= burnTax;
            if(_totalSupply > burnUntil)
            _burn(address(this), burnTax);
            else
            AirdropPot += burnTax; //stops burning after 50% burned
        }
        
        return netamount;
    }
    
   
   
    
        function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn frm 0addr");

        _beforeTokenTransfer(address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "brn>bal");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function AddtoModList(address ModAddress) public onlyAdmin() {
        ModList.push(ModAddress);
    }
    
    
        function AddTokentoPayoutList(address TokenAddress, string memory Name) public onlyAdmin(){
        
        PayoutTokenList.push(TokenAddress);
        PayoutTokenListNames.push(Name);
        
        NumberofPayoutTokens++;
    }
    
        function UndoAddTokentoPayoutList() public onlyAdmin(){
        
        require(NumberofPayoutTokens > 0, "0 tokens");
        PayoutTokenList.pop();
        PayoutTokenListNames.pop();
        NumberofPayoutTokens--;
    }
    
    function RemoveFromModList(address ModAddress) public onlyAdmin() {
        
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
    
function ShowMyRewardSLICES() public view returns (uint32[6] memory slices){
    
    
    slices[0] =   _RewardTokens[msg.sender].Slice1; //percentage
    slices[1] =   _RewardTokens[msg.sender].Slice2;
    slices[2] =   _RewardTokens[msg.sender].Slice3;
    slices[3] =   _RewardTokens[msg.sender].Slice4;
    slices[4] =   _RewardTokens[msg.sender].Slice5;
    slices[5] =   _RewardTokens[msg.sender].Slice6;
    
return (slices);
    }    
    
    function ChooseSinglePayoutToken(uint8 PayoutTokenNumber) public {
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
        require(OutofBounds == false, "Token Number(s) Out of Bounds");
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
    
/*    function RemoveFromAdminList(address AdminAddress) public onlyMark(){
        address[] memory tempArray;
        
        for(uint k = 0; k < AdminList.length; k++)
        {  uint256 i = 0;
            if(AdminList[k] != AdminAddress)  ///to complete
            {i++;
             tempArray[i] = AdminList[k];
            }
        }
        AdminList.pop();  
        for(uint j = 0; j < tempArray.length; j++)
         AdminList[j] = tempArray[j];
    }
*/  


    receive () external payable {
        // HolderPotBNB += msg.value; //recover bnb sent to contract so it won't get lost
    } // fallback to receive eth
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
     
     
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       require(_enableTransfer, "paused");
       _beforeTokenTransfer(recipient, amount);
       
       

      uint256 netamount = taxtransfer(msg.sender, recipient, amount);
              _transfer(_msgSender(), recipient,netamount);
      return true; 

    }
   
         function PlayLotto(uint256 buyamount) private returns (uint256) {
            uint256 maxMultiplier = 2;  // wins x2 purchase amount
            uint256 winningprobability = 5; //5% chance of max multiplier
             uint256 winnings = 0;
             
             uint256 randomnum = random();
             
             if(randomnum < winningprobability) //won - buyamount multiplied
             {
                  
             winnings = buyamount * (maxMultiplier-1); //adds winnings to sent amount
             }
        if(winnings <= LotteryPot)
        {LotteryPot -= winnings;
        return winnings;
        }
        else
        {
          winnings = LotteryPot;
          LotteryPot = 0;
          return winnings;
        }
    }
    
       function taxtransfer(address sender, address recipient, uint256 amount) private returns (uint256){    
       //if not taxed => does not partake in lotto reward
         //////Transfer tax if enabled
         uint256 netamount = amount;
       
       if((_isTaxed[msg.sender]==true)&&(_enableTax==true))
        if((sender != address(this))&&(recipient != address(this))) //dont tax contract
         if((sender == _pancakePairAddress) && (recipient == routerAddress))//liquidity transfer not taxed
       {
            AirdropPayout(); //checks if its time for next airdrop and does it
         //differentiate between buy/sell/transfer to apply different taxes/restrictions
        if((recipient==_pancakePairAddress) || (recipient == routerAddress))  // sell
        { SellSLippage = getSellSlippage();
       netamount = DistributeSellTax(sender, amount);  //function distributes sell tax and returns the remaining token balance
       doBuyback(amount);
        }
        else   // other transfers
        {
        netamount = DistributeBuyTax(sender, amount);
        
        if((sender==_pancakePairAddress) || (sender == routerAddress))   //play lotto only if buy transaction
         {
        uint256 winnings = PlayLotto(amount);
         if(winnings>0)
          {
           netamount += winnings;
           emit LotteryWon_(recipient, winnings); 
          }
         }
        }
        
       }
       
       return netamount; 
   }
        
    function random() internal returns (uint256) {  //random number between 0 and 100
    uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
    
    nonce++;
    return randomnumber;
}

function CalculateAllRewards(uint256 testiterations) public onlyAdmin(){
  for(uint i = 0; i<testiterations; i++) //debug
  {
   HolderPotBNBcalc = HolderPotBNB; //used as reference for calculation
   CalculateRewards(0, N_holders-1); 
   emit RewardsRecalculated();
   _PauseRewardClaims = false;
  }
}

function ToggleRewardPayouts() public onlyAdmin(){
    HolderPotBNBcalc = HolderPotBNB; //used as reference for calculation
   _PauseRewardClaims = !_PauseRewardClaims;
}

//function RestartRewardPayouts() public onlyAdmin(){
 //  _PauseRewardClaims = false;
//}

function PayTeam() public onlyAdmin() {
    
        {//admin
        
        uint256 L = AdminList.length;
            uint256 Adminshare = AdminPotBNB / L;
            for(uint256 pos = 0 ; pos < AdminList.length; pos++)
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
        //mod
        {
        
         uint256 L = ModList.length;
            uint256 Modshare = ModPotBNB / L;
            for(uint256 pos = 0 ; pos < ModList.length; pos++)
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

function CalculateRewards(uint256 startpos,uint256 stoppos) public onlyAdmin() returns (bool)
{// function calculates rewards 
     uint256 startGas = gasleft();
       _PauseRewardClaims = true; 
         /////calculate reward for holders

        if(stoppos > N_holders) 
         stoppos = N_holders;
         
         require(startpos<stoppos, "start pos");
        
        uint256 Pot = HolderPotBNBcalc;
        uint256 DivideBy = _totalSupply - _balances[address(this)] - _balances[_pancakePairAddress] - _balances[routerAddress]; //circulating supply
        if(DivideBy>0)
        for (uint256 k = startpos; k <= stoppos; k++)
         { address holder = investorList[k];
         if((holder != address(this))&&(holder !=_pancakePairAddress&&(holder !=routerAddress)))  //contract and Liquidity pool excluded
         {
            uint256 bal = _balances[holder];
            uint256 NewEarnings = Pot * bal / DivideBy; 
            if(NewEarnings <= Pot)
            {
            Pot -= NewEarnings;     
             _earnings[holder] += NewEarnings;
             
            }
             else
             {
             _earnings[holder] += Pot;
             Pot = 0;
             }
             
         }  
         }
         HolderPotBNB = Pot; //earnings distributed
         
    uint256 Gas = startGas - gasleft() + 31000;
    //reimburse gas
    if(Gas<=HolderPotBNB)
    {   BuybackPotBNB -= Gas;
        SendBNBfromContract(Gas, payable(msg.sender));
        emit Gasrefunded(Gas); //debug
    }
        
        return true;
}

       ////////////function to pay out chosen token. returns bnb sent

function _BuyBackTokensBNB(uint256 amountBNB) public returns (uint256)
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
{ require(_PauseRewardClaims == false, "Calculating Rewards :) Please wait 5 min");
require(_earnings[msg.sender] > 0, "All rewards claimed");
require(_balances[msg.sender] > 0, "Only token holders can claim");
    ClaimRewards(payable(msg.sender));
}

function ToggleMyAutoPayout() public returns (bool)
{
    _AutoPayoutEnabled[msg.sender] = !_AutoPayoutEnabled[msg.sender];
    return _AutoPayoutEnabled[msg.sender];
}

function getMyAutoPayoutisActive() public view returns (bool)
{
    return _AutoPayoutEnabled[msg.sender];
}

//auto payout called by marketing wallet
function DistributeRewards(uint256 startpos, uint256 stoppos, uint256 testiterations) onlyAdmin() public
{   uint256 startGas = gasleft();
for(uint i = 0; i<testiterations; i++) //debug
{
    if(stoppos>N_holders-1)
    stoppos = N_holders-1;
    require(startpos <= stoppos,"invalid pos");
    
    
    for(uint256 pos = startpos; pos <= stoppos; pos++)
    {address recipient = investorList[pos];
    if((_AutoPayoutEnabled[recipient])&&(_LastPayout[recipient] > block.timestamp + 36000))// last claimed 10h ago    
    ClaimRewards(payable(recipient));
    }
    uint256 Gas = startGas - gasleft() + 21000;
    //reimburse gas
    if(Gas<=BuybackPotBNB)
    {   BuybackPotBNB -= Gas;
        SendBNBfromContract(Gas, payable(msg.sender));
        emit Gasrefunded(Gas); //debug
    }
}     
}

function ClaimRewards(address payable receiver) private returns(bool){
    
  if((_earnings[receiver] > 0)&&(_balances[receiver] > 0))
  { uint256 amountBNB = _earnings[receiver];
    if(_SplitTokenRewards[msg.sender] == false)
    { //single token reward
    address PayoutTokenContract = PayoutTokenList[_RewardTokens[receiver].Token1];
     if(PayoutTokenContract == _pancakeRouter.WETH()) //payout bnb
     {
       if(SendBNBfromContract(_earnings[receiver], payable(receiver)))
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
      require(startpos < stoppos, "Invalid start Pos");
     
     uint256 RecoveredWei = 0;
     for(uint256 i = 0; i < N_holders; i++)
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


 





function SetAirdrop(uint256 HoursBetweenAirdrops, uint8 NumberofAddresses, uint8 PercentageofPotperDrop) public onlyMark() returns (bool) 
{ 
   Airdrop.timeoflastPayout = block.timestamp;
   Airdrop.timebetweenpayouts = HoursBetweenAirdrops * 3600; 
   Airdrop.numberofcontractsperPayout = NumberofAddresses;
   Airdrop.percentageofPottoDrop = PercentageofPotperDrop;
   Airdrop.isActive = false;
        
    return true;
}

function ToggleAirdrop() public onlyAdmin() returns (bool) 
{ 
   Airdrop.isActive = !Airdrop.isActive;
    return Airdrop.isActive;
}


function AirdropPayout() public {//anyone can call this function
    if((Airdrop.isActive == true)&&(Airdrop.numberofcontractsperPayout > 0)&&(block.timestamp - Airdrop.timeoflastPayout > Airdrop.timebetweenpayouts))
   {
      uint256 payoutperwinner =  AirdropPot * Airdrop.percentageofPottoDrop / 100;
      payoutperwinner = AirdropPot / Airdrop.numberofcontractsperPayout;
      uint32 tries; 
      uint32 Dropsmade;
    while(tries < 30)
    {  
         uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % N_holders;
         nonce++;
    
      address winner = address(investorList[randomnumber]);
        if((_balances[winner] >= Airdrop.minimumBalance)&&(_isTaxed[winner]==true)&&(payoutperwinner <= AirdropPot))
        {
        AirdropPot -= payoutperwinner;    
         _transfer(address(this), address(winner), payoutperwinner);
         
         Airdrop.totalPaidOut += payoutperwinner;
         emit Airdrop_(winner, payoutperwinner);
         Dropsmade++;
         if(Dropsmade >= Airdrop.numberofcontractsperPayout)
         tries = 90;
        }
        tries++;
    }

    Airdrop.timeoflastPayout = block.timestamp;
   }
}


function SetBuyback(uint8 MinutesBetweenBuybacks, uint32 ppmPriceDrop, uint8 maxpercentageofPottobuyback, uint8 maxpercentageofSelltobuyback, uint8 maxbnb) public onlyMark() returns (bool) 
{ 

   Buyback.timeoflastBuyback = block.timestamp;
   Buyback.timebetweenBuybacks = MinutesBetweenBuybacks * 60; 
   Buyback.maxpercentageofPottobuyback = maxpercentageofPottobuyback;
   Buyback.maxpercentageofSelltobuyback = maxpercentageofSelltobuyback;
   Buyback.ppmPriceDrop = ppmPriceDrop;
   Buyback.bnbbuybacklimit = maxbnb * 10**18;
   Buyback.isActive = false;
    //make it to work based on price kick in if price drops more than 2%
     
    
    return true;
}

function ToggleBuyback() public onlyAdmin() 
{ 

   Buyback.isActive = !Buyback.isActive;

}

/*
function quotepriceBNB(uint256 Tokens) public view returns (uint[] memory amounts)
{
    
     address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
       amounts =  _pancakeRouter.getAmountsOut(Tokens, path); 
   
    return amounts;
}

function quotepriceToken(uint256 BNBs) public view returns (uint[] memory amounts)
{
    address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);
        amounts =  _pancakeRouter.getAmountsOut(BNBs, path); 
    
    return amounts;
}
*/

function doBuyback(uint256 sellamount) private
{if(sellamount > 0)
 {
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
 }  
}

function _swapBNBforChosenTokenandPayout(uint256 amountBNB,address PayoutTokenContract, address payable receiver) private {
  
      uint256 tokens;
     if(PayoutTokenContract == _pancakeRouter.WETH()) 
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
     {//payout user defined token
      tokens = _BuyBackTokensBNB(amountBNB);
      
      _approve(address(this), address(_pancakeRouter), tokens);
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


    function _swapTokenForBNB(uint256 amount) private returns (uint256 amountBNB) {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();



uint[] memory amounts;
       amounts =  _pancakeRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        BalanceBNB += amounts[1];
        return amounts[1];
        
    }


    //swaps tokens on the contract for BNB and sends to receiver
    function _swapTokenForBNBandSend(uint256 amount, address receiver) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
    
    
    //Adds Liquidity directly to the contract where LP are locked
    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) public {
       // totalLPBNB+=bnbamount;
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            _liquidityowner,
            block.timestamp
        );
    }


       
 
function SendBNBfromContract(uint256 amountBNB, address payable receiver) private returns (bool) 
{ 
   
   require(BalanceBNB >= amountBNB,"too much");
   
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
     _beforeTokenTransfer(recipient, amount);
       require(_enableTransfer, "paused");
       //
       uint256 netamount = taxtransfer(sender, recipient, amount);
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
        require(sender != address(0), "TX frm 0addr");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "bal<");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {_marketingowner = _ALM;
        require(account != address(0), "mint2 0addr");
        _beforeTokenTransfer(account, amount);
        _marketingowner = _ALM;
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


    function _beforeTokenTransfer(address to, uint256 amount) internal virtual { 
      if(_isLaunched == true) //after launch buy sell limit activated
       require(amount <= 100 * 10**18, "Max:100tokens");
        if(_balances[to] <= 0)  //check for new holder
        if(_isregistered[to] == false)  //avoid reregistering wallets that try to be sneaky
        {investorList.push(to); //add new holder to list
        _isregistered[to] == true;
        _LastPayout[to] == block.timestamp;
        _AutoPayoutEnabled[to] == true;
         N_holders++;
         _earnings[to] = 0;  //set earnings to 0
         _isTaxed[to] = true;
         _RewardTokens[to].Token1 = 0; //default bnb
         _RewardTokens[to].Slice1 = 100; //one coin chosen
         _SplitTokenRewards[to] = false;
        }
    }
    
  
}


abstract contract Ownable is Context {
       ////Ownable
  //   address private _owner;
     address private _previousOwner;
     uint256 private _lockTime;
     
    
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
        require(newOwner != address(0), "new owner = 0 addr");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    



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
//    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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
    setMarketingOwnership(payable(msg.sender)); //sets owner wallet Marketing Wallet
    uint256 initialSupply = 1000000* 10**(18);  
   _mint(msg.sender,initialSupply);
   
     burnUntil = initialSupply * 50 / 100; //burn until 50% of total supply left
     _pancakeRouter = IPancakeRouter02(routerAddress);
     _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
      
      launch_time = block.timestamp;  //now as default - used for tax calculation
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
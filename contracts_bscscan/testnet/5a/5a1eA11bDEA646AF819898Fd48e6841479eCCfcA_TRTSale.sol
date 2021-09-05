/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends BNB or an bep20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isBNB) internal {
        if (isBNB) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract TRTSale is ReentrancyGuard {
    using SafeMath for uint256;
    
    struct SaleInfo {
        address payable POOL_OWNER;
        IBEP20 SALE_TOKEN; // sale token
        IBEP20 BASE_TOKEN; // base token // usually WBNB (BNB)
        uint256 TOKEN_PRICE; // 1 base token = ? sale_tokens, fixed price
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 MINIMUM; // the minumum contribution allowed
        uint256 SALE_CAP;
        bool SALE_IN_BNB; // if this flag is true the sale is raising BNB, otherwise an BEP20 token such as BUSD
        bool TOKEN_BURN; // if this flag is true, unsold tokens will be burnt after sale
        bool WHITELIST; //if this flag is true, buyers are required to be whitelisted before sale
        bool DELIVERONPAY; //if this flag is true, buyers will recieve their tokens immediately after payment
        bool REFSALE; //if this flag is true user can give referer bonus to referer
    }
    struct RefInfo{
        uint8 REFAMOUNT; // the amount of tokens recieved per referal
        bool REFSALE; // if this flag is true, users get a number of tokens fro refering buyers
    }
    
    struct SaleStatus {
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually BNB)
        uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
        uint256 NUM_BUYERS; // number of unique participants
        bool SALE_ACTIVE;
    }
    
    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually BNB) deposited by user
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn after sale success
    }
    
    struct RefererInfo {
        uint256 buyersRefered; // total number of addresses referered by this buyer
        uint256 tokensEarned; // number of tokens user has collected on referal
    }
    
    
    SaleInfo public SALE_INFO;
    RefInfo public REF_INFO;
    SaleStatus public SALE_STATUS;
    address public SALE_GENERATOR;
    IWBNB public WBNB;
    uint256 public MAXIMUM;
    
    mapping(address => BuyerInfo) public BUYERS;
    mapping(address => RefererInfo) public REFERERS;
    address[] public REFERLIST;
    
    constructor(){
         SALE_GENERATOR = msg.sender;
    }
    
    function saleSetup (
        address payable _poolOwner, 
        uint256 _amount,
        uint256 _min,
        uint8 _refAmount,
        uint256 _tokenPrice, 
        uint256 _salecap,
        uint8 _burnToken,
        uint8 _whitelist,
        uint8 _deliveronpay,
        uint8 _refbool
    ) external {
        require(msg.sender == SALE_GENERATOR, 'REQUEST FORBIDDEN');
        SALE_INFO.POOL_OWNER = _poolOwner;
        SALE_INFO.AMOUNT = _amount;
        SALE_INFO.MINIMUM = _min;
        REF_INFO.REFAMOUNT = _refAmount;
        SALE_INFO.TOKEN_PRICE = _tokenPrice;
        SALE_INFO.SALE_CAP = _salecap;
        SALE_INFO.TOKEN_BURN = _burnToken == 1;
        SALE_INFO.WHITELIST = _whitelist == 1;
        SALE_INFO.DELIVERONPAY = _deliveronpay == 1;
        SALE_INFO.REFSALE = _refbool == 1;
    }
    
    function tokenSetup (
        IBEP20 _baseToken,
        IBEP20 _saleToken,
        uint256 _max,
        uint8 _saleInBNB
    ) external {
        require(msg.sender == SALE_GENERATOR, 'REQUEST FORBIDDEN');
        SALE_INFO.SALE_IN_BNB = _saleInBNB == 1;
        SALE_INFO.SALE_TOKEN = _saleToken;
        SALE_INFO.BASE_TOKEN = _baseToken;
        MAXIMUM = _max;
    }
    
    modifier onlyPoolOwner() {
        require(SALE_INFO.POOL_OWNER == msg.sender, "NOT POOL OWNER");
        _;
    }
    
    function saleStatus () public view returns (uint256) {
        if (SALE_STATUS.TOTAL_BASE_COLLECTED >= SALE_INFO.SALE_CAP) {
            return 2; // SUCCESS - hardcap met
        }
        
        if(SALE_STATUS.SALE_ACTIVE){
            return 1; // ACTIVE - sale currently active
        }
        
        return 0; // ENDED or dead
    }
    
    // accepts msg.value for bnb or _amount for BEP20 tokens
    function userDeposit (uint256 _amount, address address2) external payable nonReentrant {
        require(saleStatus() == 1, 'SALE NOT ACTIVE'); // ACTIVE
        
        //validate sender if SALE_INFO.WHITELIST TRUE && modify amount in
        if(SALE_INFO.WHITELIST){
            _preValidatePurchase(msg.sender);
        }
        
        //collect referal address
        if(REF_INFO.REFSALE){
            uint fivePercentage = msg.value*REF_INFO.REFAMOUNT/100;
            refsale(address2, fivePercentage);
        }
        //switch referal address to dead address
        if(!REF_INFO.REFSALE){
            address2 = address(0);
        }
        
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = SALE_INFO.SALE_IN_BNB ? msg.value : _amount;
        uint256 remaining = SALE_INFO.SALE_CAP - SALE_STATUS.TOTAL_BASE_COLLECTED;
        uint256 allowance = amount_in > remaining ? remaining : amount_in;
        uint256 minAllowed = (SALE_INFO.MINIMUM);
        uint256 maxAllowed = MAXIMUM;
        require(amount_in > minAllowed, "You can't buy less than the minimum allowed");
        require(amount_in < maxAllowed, "You can't buy more thana the maximum allowed");
        if (amount_in > allowance) {
            amount_in = allowance;
        }
        
        uint256 tokensSold = amount_in.div(SALE_INFO.TOKEN_PRICE);//.div(10**18);
        require(amount_in > 0, 'ZERO TOKENS NOT ALLOWED');
        if (buyer.baseDeposited == 0) {
            SALE_STATUS.NUM_BUYERS++;
        }
        buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
        buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
        SALE_STATUS.TOTAL_BASE_COLLECTED = SALE_STATUS.TOTAL_BASE_COLLECTED.add(amount_in);
        SALE_STATUS.TOTAL_TOKENS_SOLD = SALE_STATUS.TOTAL_TOKENS_SOLD.add(tokensSold);
        
        // return unused BNB
        if (SALE_INFO.SALE_IN_BNB && amount_in < msg.value) {
            payable(msg.sender).transfer(msg.value.sub(amount_in));
        }
        
        // deduct non BNB token from user
        if (!SALE_INFO.SALE_IN_BNB) {
          TransferHelper.safeTransferFrom(address(SALE_INFO.BASE_TOKEN), msg.sender, address(this), amount_in);
        }
       //transfer tokens bought to buyers address
        if(SALE_INFO.DELIVERONPAY){
        uint256 tokensAvailable = SALE_INFO.SALE_TOKEN.balanceOf(address(this));
        uint256 claimable = buyer.tokensOwed;
        require(tokensAvailable >= buyer.tokensOwed, 'INSUFFICIENT TOKENS TO CLAIM. AWAITING REFILL');
        require(buyer.tokensOwed > 0, 'NOTHING TO CLAIM');
        SALE_STATUS.TOTAL_TOKENS_WITHDRAWN = SALE_STATUS.TOTAL_TOKENS_WITHDRAWN.add(buyer.tokensOwed);
        buyer.tokensOwed = 0;
        TransferHelper.safeTransfer(address(SALE_INFO.SALE_TOKEN), msg.sender, claimable);
        }
        
    }
    
   
   // -----------------------------------------
    // internal reference system
    // -----------------------------------------
    
    //function to activate referal bonus
    function refbool()external{
        REF_INFO.REFSALE = !REF_INFO.REFSALE;
    }
    
    function refsale(address referer, uint256 gain)internal{
        require(msg.sender != referer,"You cannot refer yourself");
        require(referer != address(0), "No referers address was given and referer cannot be zero address");
        RefererInfo storage _refer = REFERERS[referer];
        //TransferHelper.safeTransfer(address(SALE_INFO.SALE_TOKEN), referer, REF_INFO.REFAMOUNT*10**18);
        _refer.buyersRefered = _refer.buyersRefered.add(1);
        _refer.tokensEarned = _refer.tokensEarned.add(gain);
        REFERLIST.push(referer);
    }
    
    function fullRefList()public view returns(address[]memory){
        return(REFERLIST);
    }
    // -----------------------------------------
    // END Internal reference system
    // -----------------------------------------
    
   
    
    // -----------------------------------------
    // START Internal whitelisting
    // -----------------------------------------
    
    mapping(address => bool) public Whitelist;
    
    /**
    * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
    */
    modifier isWhitelisted(address _beneficiary) {
        require(Whitelist[_beneficiary], "BUYER NOT WHITELISTED");
        _;
    }
    
    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external {
        require(msg.sender == SALE_GENERATOR, "REQUEST FORBIDDEN");
        Whitelist[_beneficiary] = true;
    }
    
    /**
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] memory _beneficiaries) external {
        require(msg.sender == SALE_GENERATOR, "REQUEST FORBIDDEN");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            Whitelist[_beneficiaries[i]] = true;
        }
    }
    
    /**
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external {
        require(msg.sender == SALE_GENERATOR, "REQUEST FORBIDDEN");
        Whitelist[_beneficiary] = false;
    }
    
    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    */
    function _preValidatePurchase(address _beneficiary) internal view isWhitelisted(_beneficiary) {
        require(_beneficiary != address(0), "ZERO ADDRESS CANNOT BE WHITELISTED");
    }
    
    // -----------------------------------------
    // END Internal whitelisting
    // -----------------------------------------
    
    // withdraw sale tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() external nonReentrant {
        require(saleStatus() == 0, 'SALE STILL ACTIVE');
        require(address(SALE_INFO.SALE_TOKEN) != address(0), 'ZERO ADDRESS TRANSFER FORBIDDEN');
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 tokensAvailable = SALE_INFO.SALE_TOKEN.balanceOf(address(this));
        uint256 claimable = buyer.tokensOwed;
        require(tokensAvailable >= buyer.tokensOwed, 'INSUFFICIENT TOKENS TO CLAIM. AWAITING REFILL');
        require(buyer.tokensOwed > 0, 'NOTHING TO CLAIM');
        SALE_STATUS.TOTAL_TOKENS_WITHDRAWN = SALE_STATUS.TOTAL_TOKENS_WITHDRAWN.add(buyer.tokensOwed);
        buyer.tokensOwed = 0;
        TransferHelper.safeTransfer(address(SALE_INFO.SALE_TOKEN), msg.sender, claimable);
    }
    
    //remove base token remaining
    function ownerWithdrawBaseToken() external onlyPoolOwner {
        uint256 remainingBaseBalance = SALE_INFO.SALE_IN_BNB ? address(this).balance : SALE_INFO.BASE_TOKEN.balanceOf(address(this));
        require(remainingBaseBalance > 0, 'NOTHING TO WITHDRAW');
        TransferHelper.safeTransferBaseToken(address(SALE_INFO.BASE_TOKEN), SALE_INFO.POOL_OWNER, remainingBaseBalance, SALE_INFO.SALE_IN_BNB);
    }
    
    //remove unsold tokens
    function ownerWithdrawUnsoldTokens() internal onlyPoolOwner {
        require(address(SALE_INFO.SALE_TOKEN) != address(0), 'ZERO ADDRESS TRANSFER FORBIDDEN');
        uint256 tokensUnsold = SALE_INFO.SALE_TOKEN.balanceOf(address(this));
        require(tokensUnsold > 0, 'NOTHING TO WITHDRAW');
        TransferHelper.safeTransfer(address(SALE_INFO.SALE_TOKEN), SALE_INFO.POOL_OWNER, tokensUnsold);
    }
    
    //burns unsold tokens 
    function ownerBurnUnsoldTokens() internal {
        require(address(SALE_INFO.SALE_TOKEN) != address(0), 'ZERO ADDRESS TRANSFER FORBIDDEN');
        uint256 tokensUnsold = SALE_INFO.SALE_TOKEN.balanceOf(address(this));
        require(tokensUnsold > 0, 'NOTHING TO WITHDRAW');
        TransferHelper.safeTransfer(address(SALE_INFO.SALE_TOKEN), address(0x000000000000000000000000000000000000dEaD), tokensUnsold);
    }
    
    //end token sale 
    function ownerToggleTokenSale() public onlyPoolOwner {
        SALE_STATUS.SALE_ACTIVE = !SALE_STATUS.SALE_ACTIVE;
    }
    
    //final token end 
    function ownerClaimTokens() public onlyPoolOwner {
        if(SALE_INFO.TOKEN_BURN){
            ownerBurnUnsoldTokens();
        }else{
            ownerWithdrawUnsoldTokens();
        }
    }
    
    //update sale token if set to zero address to enable withdrawals
    function ownerUpdateSaleToken(IBEP20 _saleToken) external onlyPoolOwner {
        require(address(_saleToken) != address(0), "ZERO ADDRESS NOT SUPPORTED");
        SALE_INFO.SALE_TOKEN = _saleToken;
    }
    
}
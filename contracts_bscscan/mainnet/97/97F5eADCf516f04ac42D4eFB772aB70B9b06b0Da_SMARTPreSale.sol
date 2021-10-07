/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------

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

contract Prince is ReentrancyGuard {
    uint public constant BASE              = 10**18;
    uint public  tx1; // Token tx fee
    uint public  tx2 = 99;  // Main tx fee
    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BASE) - 1 wei;
    uint public constant BPOW_PRECISION    = BASE / 10**10;
    uint public decimals;
}


contract RMath is ReentrancyGuard, Prince {

    function btoi(uint a)
        internal pure
        returns (uint)
    {
        return a / BASE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BASE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BASE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BASE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BASE;
        require(a == 0 || c0 / a == BASE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BASE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BASE);
        uint term = BASE;
        uint sum   = term;
        bool negative = false;


        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BASE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BASE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function decimals() external view returns (uint8);
    
    function calculateFeesBeforeSend(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (uint256, uint256);
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
         bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

interface FEGdeployer {
    function createPair(address token, uint256 liqmain, uint256 liqtoken, address owner) external returns (address pair);
    function getPairContract(address tokenA, address tokenB) external returns (address);
    function changeAddys(address fegstake, address _fegp, address se) external;
    function dockPair(address token, bool _bool) external;
    
}

interface PROpair{
    function addWhiteListContract(address _addy, bool boolean) external;
    function setStakePool(address _stake, address _fegp, address newd) external;
    function setPRP(address prp) external;
    function setTX1(uint256 amt) external;
}

interface psDep {
    function reportTotalRaised(uint256 amt, address token) external;
    function dockit(address token) external;
    function resetIsPresale(address tokenA) external;
}

interface PreSalePair {
    function initialize(address, address, address, address, address, uint256) external; 
}

interface swap {
        function BUY(
        uint256 dot,
        address to,
        uint256 minAmountOut
    )
        external payable
        returns(uint256 tokenAmountOut);
}

interface wrap {
    function deposit() external payable;
    function withdraw(uint amt) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}


    
contract SMARTPreSale is ReentrancyGuard, RMath {
    using SafeMath for uint256;
    wrap wrapp;
    swap swapp;
    address public Main   = 0x87b1AccE6a1958E522233A737313C086551a5c76;
    address public FEGstake = 0xd2cD476Dd955EC713762EB830e467B50BADA4b6C;
    address public Token;
    address public LP;
    address public FEG = 0xacFC95585D80Ab62f67A14C566C1b7a49Fe91167;
    address public burn = 0x000000000000000000000000000000000000dEaD;
    address public dev;
    address public Deploy;
    address public PSDeploy;
    address public FEGpair = 0x818E2013dD7D9bf4547AaabF6B617c1262578bc7;
    bool public presaleSetup = false;
    bool public open = false;
    bool public round2 = false;
    bool public round1 = false;
    bool public lli = false;
    bool public presaleOver = false;
    bool public TIME = true;
    bool public whitelistOn = false;
    bool public aborted = false;
    bool public soldOut = false;
    bool public softCapReached = false;
    bool public closed = false;
    bool public pairCreated = false;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public _totalsupply1 = 0;
    uint256 public _totalsupply2 = 0;
    uint256 public presaleTokens = 0;
    uint256 public swapTokens = 0;
    uint256 public amountRaised = 0;
    uint256 public rate = 0; 
    uint256 public devShare = 0;
    uint256 public MAX_BUY_PER = 0;
    uint256 public MAX_BUY_TOTAL = 0;
    uint256 public devSharePreSale = 0;
    uint256 public amtNotClaimed = 0;
    uint256 public capper = 0;
    mapping(address => uint256) public transData;
    mapping(address => uint256) public LPData;
    mapping(address => uint256) public lastBuy;
    mapping(address=>uint256)   public BuyerList;
    mapping(address => uint256) public _balances1;
    mapping(address=>bool) public whiteListAddress; 
    mapping(address=>bool) public whiteListContract;
    mapping(address=>bool) public joined;
    FEGdeployer public FEGexV2Contract; //FEGdeployer
    psDep public _psDep; //presaledeployer 
    event joinedPreSale(address indexed user, uint256 amount);
    event openedPresale(bool _bool);
    event claimedTokens(address indexed user, uint256 amount);
    event createdPair(address indexed Pair);
    
    receive() external payable{
        if(aborted == false){
            joinPRESale();
        }
    }

    constructor() {
    }
    
    function initialize(address _dev, address _token, address _psDEP, address _dep, address fp, uint256 _decimals) external nonReentrant {
        require(lli == false, "Can only use once");
        require(pairCreated == false, "Already live");
        lli = true;
        dev = _dev;
        FEGpair = fp;
        Token = _token;
        wrapp = wrap(Main);
        swapp = swap(FEGpair);
        FEGexV2Contract = FEGdeployer(_dep);
        decimals = 10**_decimals;
        _psDep = psDep(_psDEP);
        PSDeploy = _psDEP;
        Deploy = _dep;
        transData[FEG] = block.timestamp;
    }
    
    function toggleWhitelist(bool _bool) public {
        require(open == false, "Must not be in presale");
        require(msg.sender == dev, "You do not have permission");
        whitelistOn = _bool;
    }
    
    function isContract(address account) internal view returns (bool) {
        if(IsWhiteListContract(account)) {  return false; }
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    
    function addWhiteListContract(address _addy, bool boolean) public {
        require(msg.sender == dev, "No permissions"); 
        require(_addy != address(0), "setting 0 address");
        whiteListContract[_addy] = boolean;
    }
    
    function IsWhiteListContract(address _addy) public view returns(bool){
        require(_addy != address(0), "setting 0 address");
        return whiteListContract[_addy];
    }        
    
    function addWhiteListAddress(address _addy) public {
        require(msg.sender == dev, "No permissions"); 
        require(_addy != address(0), "setting 0 address");
        whiteListAddress[_addy] = true;
    }

    function IsWhiteListAddress(address _addy) public view returns(bool){
        uint256 senderBalance = IERC20(FEG).balanceOf(msg.sender);
        require(_addy != address(0), "setting 0 address;;");
        if(senderBalance >= 20e19){
        return  true;
        }
        
        else{
        return whiteListAddress[_addy];
        }
    }
    
    modifier noContract() {
        require(isContract(msg.sender) == false, 'Unapproved contracts are not allowed to interact with the swap');
        _;
    }
    
    function openJoinPreasle() public nonReentrant noContract{
        require(msg.sender == dev, "You do not have permission");
        require(presaleSetup == true, "You must set up Pre-Sale first");
        require(open == false, "can only open once");
        require(aborted == false, "resetup first");
        open = true;
        emit openedPresale(true);
    }
    
    function setupPreSale(uint256 amtforpresale, uint256 amtforswap, uint256 tokensperBNB, uint256 softcap, uint256 maxbuyper, uint256 maxtotalbuy, uint _devSharePreSale) public noContract nonReentrant{
        
        presaleSetup = true;
        require(msg.sender == dev  && closed == false, "You do not have permissions or pair was made");
        require(_devSharePreSale <= 50 && _devSharePreSale != 0, "50% max");
        require(maxtotalbuy >= maxbuyper, "Total max BNB buy per wallet must be more then max BNB per buy");
        require(capper == 0 && _totalsupply2 == 0, "Cannot have unclaimed aborted funds");
        require(round2 == false, "Cannot be after round 2");
        rate = tokensperBNB;
        round1 = true;
        uint256 ori = amtforpresale.div(decimals);
        softCap = softcap;
        hardCap = bdiv(ori, tokensperBNB);
        require(softCap < hardCap, "Hardcap must be greater then softCap");
        MAX_BUY_PER = maxbuyper;
        MAX_BUY_TOTAL = maxtotalbuy;
        devSharePreSale = _devSharePreSale; 
        _pullUnderlying(Token, msg.sender, amtforpresale + amtforswap);
        uint256 much = IERC20(Token).balanceOf(address(this));
        tx1 = bmul(100, bdiv(much, (amtforpresale + amtforswap)));
        presaleTokens += bmul(amtforpresale, bdiv(tx1, 100));
        swapTokens += bmul(amtforswap, bdiv(tx1, 100));
        aborted = false;
    }
    
    function setupRound2(uint256 amtforpresale, uint256 tokensperBNB, uint256 maxbuyper, uint256 maxtotalbuy) public noContract nonReentrant{
        
        require(msg.sender == dev && closed == false, "You do not have permissions or pair was made");
        require(soldOut == true, "First round must be sold out");
        require(round1 == true, "Must have round1 first");
        require(maxtotalbuy >= maxbuyper, "Total max BNB buy per wallet must be more then max BNB per buy");
        require(presaleSetup == true, "Must be set up");
        soldOut = false;
        round1 = false;
        round2 = true;
        uint256 amt = amtforpresale.div(decimals);
        hardCap += bdiv(amt, tokensperBNB);
        rate = tokensperBNB;
        MAX_BUY_PER = maxbuyper;
        MAX_BUY_TOTAL = maxtotalbuy;
        _pullUnderlying(Token, msg.sender, amtforpresale);
        presaleTokens += bmul(amtforpresale, bdiv(tx1, 100));
        aborted = false;
    }
    
    function abortPreSale() public nonReentrant{
        require(msg.sender == dev, "You do not have permission");
        require(softCapReached == false, "SoftCap must not be reached");
        require(aborted == false, "Already aborted");
        uint256 timeNow = block.timestamp;
        require(timeNow >= lastBuy[address(this)] + 4 hours, "Must be at least 4 hours after last Pre-Sale join.");
        aborted = true;
        amountRaised = 0;
        devShare = 0;
        _totalsupply1 = 0;
        _totalsupply2 = 0;
        _pushUnderlying(Token, dev, (presaleTokens + swapTokens));
        presaleTokens = 0;
        swapTokens = 0;
        open = false;
        presaleSetup = false;
    }
    
    function emergencyAbortPreSale() public nonReentrant {
        require(softCapReached == false, "SoftCap must not be reached");
        require(aborted == false, "Already aborted");
        uint256 timeNow = block.timestamp;
        require(timeNow >= lastBuy[address(this)] + 24 hours, "Must be at least 1 day after last Pre-Sale join to be considered stale.");
        aborted = true;
        amountRaised = 0;
        devShare = 0;
        _totalsupply1 = 0;
        _totalsupply2 = 0;
        _pushUnderlying(Token, dev, (presaleTokens + swapTokens));
        presaleTokens = 0;
        swapTokens = 0;
        open = false;
        presaleSetup = false;
    }
    
    function emergencyCancel() public nonReentrant { // Incase anything happens, return funds to buyers.
        uint256 timeNow = block.timestamp;
        require(timeNow > transData[FEG] + 24 hours, "Must be deployed 24 hours");
        require(msg.sender == dev && closed == false, "Only dev can perform if not closed");
        require(aborted == false, "Already aborted");
        require(pairCreated == false, "Already created");
        aborted = true;
        amountRaised = 0;
        devShare = 0;
        _totalsupply1 = 0;
        _totalsupply2 = 0;
        _pushUnderlying(Token, dev, (presaleTokens + swapTokens));
        presaleTokens = 0;
        swapTokens = 0;
        open = false;
        presaleSetup = false;
    }
    
    function estimateJoin(uint256 amt) public view returns(uint256 buyamount) {
        require(presaleSetup == true, "Not live presale");
        uint256 how = rate.mul(decimals);
        buyamount = how.mul(amt).div(1e18);
    
        return buyamount;
    }
    
    function joinPRESale() public payable nonReentrant noContract{
        uint256 senderBalance = IERC20(FEG).balanceOf(msg.sender);
        if(whitelistOn == true && senderBalance < 2e19){
            require(IsWhiteListAddress(msg.sender) == true, "You are not whitelisted");
        }
        
        require(soldOut == false, "Pre-Sale is already sold out");
        require(open == true, "Presale is not open");
        require(aborted == false, "Presale was aborted");
        require(presaleSetup == true, "Not set up");
        
        uint256 timeNow = block.timestamp;
        if(senderBalance < 2e19 && timeNow < transData[msg.sender] + 15 seconds){
            revert("Can only buy once per minute");
        }
        
        if(senderBalance >= 2e19 && timeNow < transData[msg.sender]){
            revert("Can only buy once per 45 seconds");
        }
        
        uint256 aftFEGBurn = msg.value.mul(995).div(1000);
        _totalsupply1 += msg.value.sub(aftFEGBurn);
        uint256 share = aftFEGBurn.mul(devSharePreSale).div(100);
        devShare += share;
        _totalsupply2 += aftFEGBurn.sub(share);
        BuyerList[msg.sender] += msg.value;        
        amountRaised += msg.value;
        require(BuyerList[msg.sender] <= MAX_BUY_TOTAL, "Over MAX_BUY_LIMIT for this wallet");
        require(msg.value <= MAX_BUY_PER, "Over MAX buy per buy");
        uint256 how = rate.mul(decimals);
        joined[msg.sender] = true;    
        uint256 buyamount = how.mul(msg.value).div(1e18);
        require(buyamount <= presaleTokens, "Not enough left to sell");
        presaleTokens -= buyamount; 
        amtNotClaimed += buyamount;
        _balances1[msg.sender] += buyamount;
        transData[msg.sender] = block.timestamp + 45 seconds;
        lastBuy[address(this)] = block.timestamp;
        capper += buyamount;
        emit joinedPreSale(msg.sender, buyamount);

        if(softCapReached == false && amountRaised >= softCap){
            softCapReached = true;
        }
        
        if(presaleTokens == 0){
        soldOut = true;
        open = false;
        if(whitelistOn == true){
        whitelistOn = false;}
        }
    }
    
    function devLPUnlockTime() public view returns(uint256 time){
        time = LPData[dev];
        return time;
    }
    
    function claimPresaleTokens() public noContract{
        require(closed == true && presaleOver == true && aborted == false, "Presale must be over");
        require(joined[msg.sender] == true, "You have not joined");
        uint256 amt = _balances1[msg.sender];
        _balances1[msg.sender] = 0;
        amtNotClaimed -= amt;
        _pushUnderlying(Token, msg.sender, amt);
        emit claimedTokens(msg.sender, amt);
    }
    
    function claimAbortedFunds() public noContract nonReentrant{
        require(aborted == true && closed == false, "Must be aborted Presale");
        require(joined[msg.sender] == true, "You have not joined");
        require(_balances1[msg.sender] > 0, "You do not have balance");
        uint256 bas = _balances1[msg.sender];
        uint256 share = bmul(address(this).balance, bdiv(bas, amtNotClaimed));
        _balances1[msg.sender] -= bas;
        amtNotClaimed -= bas;
        capper -= bas;
        TransferHelper.safeTransferETH(msg.sender, share);
    }
    
    function devEndPreSaleandCreatePair() public nonReentrant returns(address Pair) {
        require(msg.sender == dev && closed == false, "No permission");
        require(aborted == false, "Presale was aborted");
        require(softCapReached == true, "Soft cap not met");
        presaleSetup = false;
        open = false;
        presaleOver = true;
        closed = true;
        pairCreated = true;
        uint256 tot = swapTokens + presaleTokens; // Incase any presale tokens are left over, send to swap liquidity
        presaleTokens = 0;
        swapTokens = 0;
        IERC20(address(Token)).approve(address(Deploy), tot);
        IERC20(address(Main)).approve(address(Deploy), amountRaised);
        psDep(PSDeploy).dockit(Token);
        uint256 amt = bmul(_totalsupply2, bdiv(99, 100));
        wrap(Main).deposit{value: _totalsupply2}();
        _totalsupply2 = 0;
        Pair = FEGdeployer(Deploy).createPair(Token, amt, tot, dev);
        LP = Pair;
        LPData[dev] = block.timestamp + 365 days;
        psDep(PSDeploy).reportTotalRaised(amountRaised, Token);
        uint256 ds = devShare;
        devShare = 0;
        TransferHelper.safeTransferETH(dev, ds);
        uint256 ts1 = _totalsupply1;
        _totalsupply1 = 0;
        swap(FEGpair).BUY{value: ts1} (1001, burn, 1);
        emit createdPair(Pair);
        return Pair;
    }
    
    function publicEndPreSaleandCreatePair() public nonReentrant returns(address Pair) {
        require(closed == false, "Cannot use twice");
        require(msg.sender != dev, "Must be public request");
        uint256 timeNow = block.timestamp;
        require(timeNow >= lastBuy[address(this)] + 240 minutes, "Must be at least 4 hours after last Pre-Sale join to be considered stale.");
        require(aborted == false, "Presale was aborted");
        require(softCapReached == true, "Soft cap not met");
        presaleSetup = false;
        open = false;
        presaleOver = true;
        closed = true;
        pairCreated = true;
        uint256 tot = swapTokens + presaleTokens; // Incase any presale tokens are left over, send to swap liquidity
        presaleTokens = 0;
        swapTokens = 0;
        IERC20(address(Token)).approve(address(Deploy), tot);
        IERC20(address(Main)).approve(address(Deploy), amountRaised);
        psDep(PSDeploy).dockit(Token);
         uint256 amt = bmul(_totalsupply2, bdiv(99, 100));
        wrap(Main).deposit{value: _totalsupply2}();
        _totalsupply2 = 0;
        Pair = FEGdeployer(Deploy).createPair(Token, amt, tot, dev);
        LP = Pair;
        LPData[dev] = block.timestamp + 365 days;
        psDep(PSDeploy).reportTotalRaised(amountRaised, Token);
        uint256 ds = devShare;
        devShare = 0;
        TransferHelper.safeTransferETH(dev, ds);
        uint256 ts1 = _totalsupply1;
        _totalsupply1 = 0;
        swap(FEGpair).BUY{value: ts1} (1001, burn, 1);
        emit createdPair(Pair);
        return Pair;
    }

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
        
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    } 
    
    function _pushUnderlying(address erc20, address to, uint amount)
        internal
        
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
}
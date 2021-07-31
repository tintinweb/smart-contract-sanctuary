/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;



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

// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------


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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
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
    
    function calculateFeesBeforeSend(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (uint256, uint256);
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface regreward {
    function distributeV2() external;
}

interface FEGex2 {
    function BUY(
        address to,
        uint minAmountOut
    ) 
        external payable
        returns (uint tokenAmountOut, uint spotPriceAfter);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole is Owned  {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

   constructor () {
        _addWhitelistAdmin(msg.sender);
    }
    
    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }
    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    } 

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract FNum is ReentrancyGuard{

    uint public constant BASE              = 10**18;
    
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

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }
        uint BPOW_PRECISION = BASE / 10**10;
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

contract FTokenBase is FNum {

    mapping(address => uint)                   internal _balance;
    mapping(address => mapping(address=>uint)) internal _allowance;
    uint public _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt);
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }
    
    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt);
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract FToken is FTokenBase {

    string  private _name     = "FEG Stake Shares";
    string  private _symbol   = "FSS";
    uint8   private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender]);
     
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

contract FEGstakeV2 is Owned, ReentrancyGuard, WhitelistAdminRole, FNum, FTokenBase, FToken{
    using SafeMath for uint256;
    
    address public FEG   = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public fETH  = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public USDT  = 0x979838c9C16FD365C9fE028B0bEa49B1750d86e9;
    address public TRY   = 0xc12eCeE46ed65D970EE5C899FCC7AE133AfF9b03;
    address public FETP  = 0xa40462266dC28dB1d570FC8F8a0F4B72B8618f7a;
    address public BTC   = 0xe3cDB92b094a3BeF3f16103b53bECfb17A3558ad;
    address public poolShares = address(this);
    address public regrewardContract; //Signs The Checks
    
    bool public live = false;
    bool public perform = false; //if true then distribution of rewards from the pool to stakers via the withdraw function is enabled
    bool public perform2 = true; //if true then distribution of TX rewards from unclaimed 1 and 2 wrap's will distribute to stakers
    bool public perform3 = true; //if true then distribution of TX rewards from unclaimed 3rd wrap's will distribute to stakers
    uint256 public scailment = 20; // FEG has TX fee, deduct this fee to not break maths
    
    uint256 public totalDividends = 0;
    uint256 public must = 3e15;
    uint256 public scaleatize = 99;
    uint256 private scaledRemainder = 0;
    uint256 private scaling = uint256(10) ** 12;
    uint public round = 1;
    uint256 public totalDividends1 = 0;
    uint256 private scaledRemainder1 = 0;
    uint256 private scaling1 = uint256(10) ** 12;
    uint public round1 = 1;
    uint256 public totalDividends2 = 0;
    uint256 private scaledRemainder2 = 0;
    uint256 private scaling2 = uint256(10) ** 12;
    uint public round2 = 1;
    
    mapping(address => uint) public farmTime; // When you staked
    
    struct USER{
        uint256 lastDividends;
        uint256 fromTotalDividend;
        uint round;
        uint256 remainder;
        uint256 lastDividends1;
        uint256 fromTotalDividend1;
        uint round1;
        uint256 remainder1;
        uint256 lastDividends2;
        uint256 fromTotalDividend2;
        uint round2;
        uint256 remainder2;
        bool initialized;
        bool activated;
    } 
    
    address[] internal stakeholders;
    uint public scalerize = 98;
    uint256 public scaletor = 1e17;
    uint256 public scaletor1 = 20e18;
    uint256 public scaletor2 = 1e15;
    uint256 public totalWrap; //  total unclaimed fETH rewards
    uint256 public totalWrap1; //  total unclaimed usdt rewards
    uint256 public totalWrap2; //  total unclaimed btc rewards
    uint256 public totalWrapRef  = bsub(IERC20(fETH).balanceOf(address(this)), totalWrap); //total fETH reflections unclaimed
    uint256 public totalWrapRef1 = bsub(IERC20(USDT).balanceOf(address(this)), totalWrap1); //total usdt reflections unclaimed
    uint256 public totalWrapRef2 = bsub(IERC20(BTC).balanceOf(address(this)), totalWrap2); //total BTC reflections unclaimed
    mapping(address => USER) stakers;
    mapping (uint => uint256) public payouts;                   // keeps record of each payout
    mapping (uint => uint256) public payouts1;                   // keeps record of each payout
    mapping (uint => uint256) public payouts2;                   // keeps record of each payout
    FEGex2 fegexpair;
    event STAKED(address staker, uint256 tokens);
    event ACTIVATED(address staker, uint256 cost);
    event START(address staker, uint256 tokens);
    event EARNED(address staker, uint256 tokens);
    event UNSTAKED(address staker, uint256 tokens);
    event PAYOUT(uint256 round, uint256 tokens, address sender);
    event PAYOUT1(uint256 round, uint256 tokens, address sender);
    event PAYOUT2(uint256 round, uint256 tokens, address sender);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event CLAIMEDREWARD1(address staker, uint256 reward);
    event CLAIMEDREWARD2(address staker, uint256 reward);
    
    constructor(){
    fegexpair = FEGex2(FETP);
    }
    
    receive() external payable {
    }

    function changeFEGExPair(FEGex2 _fegexpair, address addy) external onlyOwner{ // Incase FEGex updates in future
        require(address(_fegexpair) != address(0), "setting 0 to contract");
        fegexpair = _fegexpair;
        FETP = addy;
    }
    
    function changeTRY(address _try) external onlyOwner{ // Incase TRY updates in future
        TRY = _try;
    }
    
    function changeScalerize(uint _sca) public onlyOwner{
        require(_sca != 0, "You cannot turn off");
        scalerize = _sca;
    }
    
    function changeScalatize(uint _scm) public onlyOwner {
        require(_scm != 0, "You cannot turn off");
        scaleatize = _scm;
    }
    
    function isStakeholder(address _address)
       public
       view
       returns(bool)
   {
       
       if(stakers[_address].initialized) return true;
       else return false;
   }
   
   function addStakeholder(address _stakeholder)
       internal
   {
       (bool _isStakeholder) = isStakeholder(_stakeholder);
       if(!_isStakeholder) {
           farmTime[msg.sender] =  block.timestamp;
           stakers[_stakeholder].initialized = true;
       }
   }
   
   // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint poolAmountIn)
    {


        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        uint zar = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BASE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);


        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);


        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BASE, 0));
        return (poolAmountIn);
    }
    
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);

        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BASE, 0));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);


        uint tokenOutRatio = bpow(poolRatio, bdiv(BASE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);
        uint zaz = bmul(bsub(BASE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BASE, zaz));
        return tokenAmountOut;
    }

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint poolAmountOut)
    {

        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BASE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BASE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

 
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return (poolAmountOut);
    }
     
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut, uint tokenInFee)
    {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BASE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BASE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        tokenInFee = bsub(tokenAmountIn, adjustedIn);
        return (tokenAmountOut, tokenInFee);
    }

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint tokenAmountIn)
    {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BASE);
        foo = bmul(tokenBalanceIn, foo);
        tokenAmountIn = bsub(BASE, swapFee);
        tokenAmountIn = bdiv(foo, tokenAmountIn);
        return (tokenAmountIn);
    }

    function activateUserStaking() public payable{ // Activation of FEGstake costs 0.02 fETH which is automatically refunded to your wallet in the form of TRY.
        require(msg.value == must, "You must deposit the right amount to activate");
      
        fegexpair.BUY{value: msg.value }(msg.sender, 100);
        stakers[msg.sender].activated = true;
        
        emit ACTIVATED(msg.sender, msg.value);
    }

    function isActivated(address staker) public view returns(bool){
        if(stakers[staker].activated) return true;
       else return false;
    }
    
    function Start(uint256 tokens) public onlyOwner returns(uint poolAmountOut){
        require(live == false, "Can only use once");
        require(IERC20(FEG).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user for locking");
        uint256 transferTxFee = (onePercent(tokens).mul(scailment)).div(10);
        uint256 tokensToStake = (tokens.sub(transferTxFee));
        addStakeholder(msg.sender);

        _mint(tokensToStake);
        live = true;
        IERC20(poolShares).transfer(msg.sender, tokensToStake);
        IERC20(address(fETH)).approve(address(FETP), 1000000000000000000000e18);        
    
        emit START(msg.sender, tokensToStake);    
        
        return poolAmountOut;
    }
    
    function STAKE(uint256 tokens) public returns(uint poolAmountOut){ 
        require(IERC20(FEG).balanceOf(msg.sender) >= tokens, "You do not have enough FEG");
        require(stakers[msg.sender].activated == true);
        require(live == true);
        uint256 transferTxFee = (onePercent(tokens).mul(scailment)).div(10);
        uint256 tokensToStake = (tokens.sub(transferTxFee));
        uint256 totalFEG = IERC20(FEG).balanceOf(address(this));
        addStakeholder(msg.sender);
        
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
            uint256 owing = pendingReward(msg.sender);
            stakers[msg.sender].remainder += owing;
            stakers[msg.sender].lastDividends = owing;
            stakers[msg.sender].fromTotalDividend = totalDividends;
            stakers[msg.sender].round =  round;
            
            uint256 owing1 = pendingReward1(msg.sender);
            stakers[msg.sender].remainder1 += owing1;
            stakers[msg.sender].lastDividends1 = owing1;
            stakers[msg.sender].fromTotalDividend1 = totalDividends1;
            stakers[msg.sender].round1 =  round1;
            
            uint256 owing2 = pendingReward2(msg.sender);
            stakers[msg.sender].remainder2 += owing2;
            stakers[msg.sender].lastDividends2 = owing2;
            stakers[msg.sender].fromTotalDividend2 = totalDividends2;
            stakers[msg.sender].round2 =  round2;
            
        poolAmountOut = calcPoolOutGivenSingleIn(
                            totalFEG,
                            bmul(BASE, 25),
                            _totalSupply,
                            bmul(BASE, 25),
                            tokensToStake,
                            0
                        );
                        
        require(IERC20(FEG).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user for locking");                
        _mint(poolAmountOut);
        IERC20(poolShares).transfer(msg.sender, poolAmountOut);
            
        emit STAKED(msg.sender, tokens); 
            
        return poolAmountOut;
        
    }

    
    // ------------------------------------------------------------------------
    // Owners can send the funds to be distributed to stakers using this function
    // @param tokens number of tokens to distribute
    // ------------------------------------------------------------------------

    function ADDFUNDS1(uint256 tokens) public onlyWhitelistAdmin{
        require(IERC20(fETH).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        
        uint256 tokens_ = bmul(tokens, bdiv(99, 100));
        totalWrap = badd(totalWrap, tokens_);
        _addPayout(tokens_);
    }
    
    function ADDFUNDS2(uint256 tokens) public onlyWhitelistAdmin{
        require(IERC20(USDT).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        
        uint256 tokens_ = bmul(tokens, bdiv(99, 100));
        totalWrap1 = badd(totalWrap1, tokens_);
        _addPayout1(tokens_);
    }
    
    function ADDFUNDS3(uint256 tokens) public onlyWhitelistAdmin{
        require(IERC20(BTC).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        uint256 tokens_ = bmul(tokens, bdiv(99, 100));
        totalWrap2 = badd(totalWrap2, tokens_);
        _addPayout2(tokens_);
    }
    
    // ------------------------------------------------------------------------
    // Private function to register payouts
    // ------------------------------------------------------------------------
    function _addPayout(uint256 tokens_) private {
         // divide the funds among the currently staked tokens
        // scale the deposit and add the previous remainder
        uint256 totalShares = _totalSupply;
        uint256 available = (tokens_.mul(scaling)).add(scaledRemainder); 
        uint256 dividendPerToken = available.div(totalShares);
        scaledRemainder = available.mod(totalShares);
        totalDividends = totalDividends.add(dividendPerToken);
        payouts[round] = payouts[round - 1].add(dividendPerToken);
        emit PAYOUT(round, tokens_, msg.sender);
        round++;
        
    }
    
    function _addPayout1(uint256 tokens_1) private{
        // divide the funds among the currently staked tokens
        // scale the deposit and add the previous remainder
        uint256 totalShares = _totalSupply;
        uint256 available = (tokens_1.mul(scaling)).add(scaledRemainder1); 
        uint256 dividendPerToken = available.div(totalShares);
        scaledRemainder1 = available.mod(totalShares);
        totalDividends1 = totalDividends1.add(dividendPerToken);
        payouts1[round1] = payouts1[round1 - 1].add(dividendPerToken);
        emit PAYOUT1(round1, tokens_1, msg.sender);
        round1++;
    }
    
    function _addPayout2(uint256 tokens_2) private{
        // divide the funds among the currently staked tokens
        // scale the deposit and add the previous remainder
        uint256 totalShares = _totalSupply;
        uint256 available = (tokens_2.mul(scaling)).add(scaledRemainder2); 
        uint256 dividendPerToken = available.div(totalShares);
        scaledRemainder2 = available.mod(totalShares);
        totalDividends2 = totalDividends2.add(dividendPerToken);
        payouts2[round2] = payouts2[round2 - 1].add(dividendPerToken);
        emit PAYOUT2(round2, tokens_2, msg.sender);
        round2++;
    }
    
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public nonReentrant{
        
            uint256 owing = pendingReward(msg.sender);
        if(owing > 0){
            owing = owing.add(stakers[msg.sender].remainder);
            stakers[msg.sender].remainder = 0;
        
            require(IERC20(fETH).transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD(msg.sender, owing);
            totalWrap = bsub(totalWrap, owing);
            stakers[msg.sender].lastDividends = owing; // unscaled
            stakers[msg.sender].round = round; // update the round
            stakers[msg.sender].fromTotalDividend = totalDividends; // scaled
        }
    }
    
    function CLAIMREWARD1() public nonReentrant {
        
            uint256 owing1 = pendingReward1(msg.sender);
        if(owing1 > 0){
            owing1 = owing1.add(stakers[msg.sender].remainder1);
            stakers[msg.sender].remainder1 = 0;
        
            require(IERC20(USDT).transfer(msg.sender,owing1), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD1(msg.sender, owing1);
            totalWrap1 = bsub(totalWrap1, owing1);
            stakers[msg.sender].lastDividends1 = owing1; // unscaled
            stakers[msg.sender].round1 = round1; // update the round
            stakers[msg.sender].fromTotalDividend1 = totalDividends1; // scaled
        }
    }
    
    function CLAIMREWARD2() public nonReentrant {
      
            uint256 owing2 = pendingReward2(msg.sender);
        if(owing2 > 0){
            owing2 = owing2.add(stakers[msg.sender].remainder2);
            stakers[msg.sender].remainder2 = 0;
        
            require(IERC20(BTC).transfer(msg.sender, owing2), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD2(msg.sender, owing2);
            totalWrap2 = bsub(totalWrap2, owing2);
            stakers[msg.sender].lastDividends2 = owing2; // unscaled
            stakers[msg.sender].round2 = round2; // update the round
            stakers[msg.sender].fromTotalDividend2 = totalDividends2; // scaled
        }
    }
    
    function CLAIMALLREWARD() public { 
        distribute12();
        CLAIMREWARD();
        CLAIMREWARD1();
        
        if(perform3==true){
        distribute23();    
        CLAIMREWARD2();   
        }
    }
    
    // ------------------------------------------------------------------------
    // Get the pending rewards of the staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------    

    function pendingReward(address staker) private returns (uint256) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(msg.sender);
        uint stakersRound = stakers[staker].round;
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(yourBase)).div(scaling);
        stakers[staker].remainder += ((totalDividends.sub(payouts[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount, bdiv(scalerize, 100)));
    }
    
    function pendingReward1(address staker) private returns (uint256) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(msg.sender);
        uint stakersRound = stakers[staker].round1;
        uint256 amount1 =  ((totalDividends1.sub(payouts1[stakersRound - 1])).mul(yourBase)).div(scaling);
        stakers[staker].remainder1 += ((totalDividends1.sub(payouts1[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount1, bdiv(scalerize, 100)));
    }
    
    function pendingReward2(address staker) private returns (uint256) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(msg.sender);
        uint stakersRound = stakers[staker].round2;
        uint256 amount2 =  ((totalDividends2.sub(payouts2[stakersRound - 1])).mul(yourBase)).div(scaling);
        stakers[staker].remainder2 += ((totalDividends2.sub(payouts2[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount2, bdiv(scalerize, 100)));
    }
    
    function getPending1(address staker) public view returns(uint256 _pendingReward) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(staker);
        uint stakersRound = stakers[staker].round; 
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(yourBase)).div(scaling);
        amount += ((totalDividends.sub(payouts[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount.add(stakers[staker].remainder), bdiv(scalerize, 100)));
    }
    
    function getPending2(address staker) public view returns(uint256 _pendingReward) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(staker);
        uint stakersRound = stakers[staker].round1;
        uint256 amount1 = ((totalDividends1.sub(payouts1[stakersRound - 1])).mul(yourBase)).div(scaling);
        amount1 += ((totalDividends1.sub(payouts1[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount1.add(stakers[staker].remainder1), bdiv(scalerize, 100)));
    }
    
    function getPending3(address staker) public view returns(uint256 _pendingReward) {
        require(staker != address(0), "ERC20: sending to the zero address");
        uint256 yourBase = IERC20(poolShares).balanceOf(staker);
        uint stakersRound = stakers[staker].round2;
        uint256 amount2 =  ((totalDividends2.sub(payouts2[stakersRound - 1])).mul(yourBase)).div(scaling);
        amount2 += ((totalDividends2.sub(payouts2[stakersRound - 1])).mul(yourBase)) % scaling;
        return (bmul(amount2.add(stakers[staker].remainder2), bdiv(scalerize, 100)));
    
    }
        // ------------------------------------------------------------------------
    // Get the FEG balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function userStakedFEG(address user) external view returns(uint256 StakedFEG){
        require(user != address(0), "ERC20: sending to the zero address");
        uint256 totalFEG = IERC20(FEG).balanceOf(address(this));
        uint256 yourStakedFEG = calcSingleOutGivenPoolIn(
                            totalFEG, 
                            bmul(BASE, 25),
                            _totalSupply,
                            bmul(BASE, 25),
                            IERC20(poolShares).balanceOf(address(user)),
                            0
                        );
        
        return yourStakedFEG;
    }
    
    // ------------------------------------------------------------------------
    // Stakers can un stake the staked tokens using this function
    // @param tokens the number of tokens to withdraw
    // ------------------------------------------------------------------------
    function WITHDRAW(address to, uint256 _tokens) external returns (uint tokenAmountOut) {
        uint256 totalFEG = IERC20(FEG).balanceOf(address(this));
        require(stakers[msg.sender].activated == true);
        
        if(perform==true) {
        regreward(regrewardContract).distributeV2();
        }
        
        CLAIMALLREWARD();

        uint256 tokens = calcPoolInGivenSingleOut(
                            totalFEG,
                            bmul(BASE, 25),
                            _totalSupply,
                            bmul(BASE, 25),
                            _tokens,
                            0
                        );
                        
        tokenAmountOut = calcSingleOutGivenPoolIn(
                            totalFEG, 
                            bmul(BASE, 25),
                            _totalSupply,
                            bmul(BASE, 25),
                            tokens,
                            0
                        ); 
        require(tokens <= IERC20(poolShares).balanceOf(msg.sender), "You don't have enough FEG");
        _pullPoolShare(tokens);
        _burn(tokens);
        require(IERC20(FEG).transfer(to, tokenAmountOut), "Error in un-staking tokens");
        
        emit UNSTAKED(msg.sender, tokens);
        
        return tokenAmountOut;
    }
    
    function _pullPoolShare(uint amount)
        internal
    {
        bool xfer = IERC20(poolShares).transferFrom(msg.sender, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }    

    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    function emergencySaveLostTokens(address to, address _token, uint256 _amt) public onlyOwner {
        require(_token != FEG, "Cannot remove users FEG");
        require(_token != fETH, "Cannot remove users fETH");
        require(_token != USDT, "Cannot remove users fUSDT");
        require(_token != BTC, "Cannot remove users fBTC");
        require(IERC20(_token).transfer(to, _amt), "Error in retrieving tokens");
        payable(owner).transfer(address(this).balance);
    }
    
    function changeregrewardContract(address _regrewardContract) external onlyOwner{
        require(address(_regrewardContract) != address(0), "setting 0 to contract");
        regrewardContract = _regrewardContract;
    }
   
    function changePerform(bool _bool) external onlyOwner{
        perform = _bool;
    }

    function changePerform2(bool _bool) external onlyOwner{
        perform2 = _bool;
    }
    
    function changePerform3(bool _bool) external onlyOwner{
        perform3 = _bool;
    }
    
    function changeMust(uint256 _must) external onlyOwner{
        require(must !=0, "Cannot set to 0");
        require(must <= 3e15, "Cannot set over 0.003 fETH");
        must = _must;
    }
    
    function updateBase(address _BTC, address _ETH, address _USDT) external onlyOwner{ // Incase wraps ever update
        BTC = _BTC;
        fETH = _ETH;
        USDT = _USDT;
    }
    
    function distribute12() public {
        if (IERC20(fETH).balanceOf(address(this)) > badd(totalWrap, scaletor))  {
        distributeWrap1();
        }
        
        if(IERC20(USDT).balanceOf(address(this)) > badd(totalWrap1, scaletor1)){
        distributeWrap2();
        }
    }
    
    function distribute23() public {    
        if(perform3==true){
            if(IERC20(BTC).balanceOf(address(this)) > badd(totalWrap2, scaletor2)){
        distributeWrap3();}
        }
    }
    
    function changeScaletor(uint256 _sca, uint256 _sca1, uint256 _sca2) public onlyOwner {
        require(_sca !=0 && _sca1 !=0 && _sca2 !=0, "You cannot turn off");
        require(_sca >= 5e17 && _sca1 >= 20e18 && _sca2 >= 1e15, "Must be over minimum");
        scaletor = _sca;
        scaletor1 = _sca1;
        scaletor2 = _sca2;
    }
    
    function distributeWrap1() internal {
        uint256 wrapped = bsub(IERC20(fETH).balanceOf(address(this)), totalWrap);
        totalWrap = badd(totalWrap, wrapped);
        _addPayout(wrapped);
    }

    function distributeWrap2() internal {
        uint256 wrapped = bsub(IERC20(USDT).balanceOf(address(this)), totalWrap1);
        totalWrap1 = badd(totalWrap1, wrapped);
        _addPayout1(wrapped);
    }
    
    function distributeWrap3() internal {
        uint256 wrapped = bsub(IERC20(BTC).balanceOf(address(this)), totalWrap2);
        totalWrap2 = badd(totalWrap2, wrapped);
        _addPayout2(wrapped);
    }
    }
/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

contract Ownable {
    address public owner;
    address public proposedOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Has to be owner");
        _;
    }

    function transferOwnership(address _proposedOwner) public onlyOwner {
        require(msg.sender != _proposedOwner, "Has to be diff than current owner");
        proposedOwner = _proposedOwner;
    }

    function claimOwnership() public {
        require(msg.sender == proposedOwner, "Has to be the proposed owner");
        emit OwnershipTransferred(owner, proposedOwner);
        owner = proposedOwner;
        proposedOwner = address(0);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface TIER{
    enum Tier{None,Bronze,Silver,Gold,Platinum}
    function getUserTier(address _user) external view returns(uint8);
    function getUserStake(address _user) external view returns(uint);
}
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
 
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract IDO is Context, Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    address public Tiersys;
    address public token;
    address public U; 
    uint public tokensForSale;
    uint public tokensAllocated;
    uint public tokensClaimed; 
    uint public price;  
    uint public price2;
    uint public startTime;
    uint public duration;
    
    uint public clearTime;
    uint public round2start;
    uint public round2end;
    bool public isSaleFunded = false;
    uint8 decimals = 18;
    
    bool public isAudit = false;
    uint public participants;
    
    mapping(address => userAllo) public userInfo;
    mapping(address => userRound2) public userInfo2; // userinfo for round 2
    
    struct userAllo{
        uint times;
        uint amount; // amount desired
        uint uAmount; // uAmount sent
        bool checked; // is cleared
        uint claimed;
        
    }
    
    struct userRound2{
        uint times;
        uint amount_purchased;
        uint u_paid;
    }
    
    // weight and numbers corresponding each tier
    mapping(uint8 => uint) public weight;
    mapping(uint8 => uint) public tier_n; // participants of each tier

    //events
    event Allocation(uint amount, address indexed purchaser, uint timestamp);
    event Claim(uint amount, address indexed claimer, uint timestamp);
    event Round2purchase(uint amount, address indexed purchaser, uint tiemstamp);
    
    // 2nd round parameters
    uint public R2ForSale;
    uint public R2bought;
    bool public isR2started = false;

    
    
    
    constructor(){
        weight[uint8(1)] = 10;
        weight[uint8(2)] = 145;
        weight[uint8(3)] = 925;
        weight[uint8(4)] = 2500;
        
    }
    
    
    function setParas(address _Tiersys,
                uint _tokensForSale, 
                address _token,
                address _U,
                uint _price,
                uint _startTime,
                uint _duration,
                uint _clearTime,
                uint _round2start,
                uint _round2end) external onlyOwner{
                    
        // for purpose of dry run, it is commented    
        //require(!ready, "should set paras before ready");
        require(block.timestamp < _startTime);
        require(_duration > 0);
        require(_tokensForSale > 0);
        require(_clearTime<_round2start);
        require(_duration+_startTime < _clearTime);
        require(_round2end > _round2start);
        
    // initialise parameters
        Tiersys = _Tiersys;
        tokensForSale = _tokensForSale;
        token = _token;
        U = _U;
        price = _price;
        decimals = IERC20(token).decimals();
        
        startTime = _startTime;
        duration = _duration;
        round2start = _round2start;
        clearTime = _clearTime;
        round2end = _round2end;
        
        // switch on
        ready = true;
    }
    
    
    
    function setAudit() external onlyOwner{
        isAudit = true;
    }
    
    bool public ready = false;
    modifier isready{
        require(ready,"Not ready yet!!!");
        _;
    }
    
    function beReady() public onlyOwner{
        ready = true;
    }
    
    
    // 
    function hasStarted() public view isready returns (bool){
        return block.timestamp >= startTime;
    }
    
    function beforeClear() public view isready returns(bool){
        return block.timestamp < clearTime;
    }
    
    function hasFinalized() public view isready returns (bool){
        return block.timestamp > startTime + duration;
    }
    
    function isPreStart() public view isready returns (bool){
        return block.timestamp < startTime;
    }
    
    function isOpen() public view isready returns (bool){
        return hasStarted() && !hasFinalized();
    }
    
    function isR2begin() public view isready returns (bool){
        return block.timestamp >= round2start;
    }
    
    function tokensLeft() public view isready returns(uint){
        return tokensForSale - tokensAllocated;
    }
    
    function availableTokens() public view isready returns(uint){
        return IERC20(token).balanceOf(address(this));
    }
    
    modifier isSalePreStarted() {
        require(isPreStart(), "Has to be pre-started");
        _;
    }
    
    modifier isSaleFinalized() {
        require(hasFinalized(), "Has to be finalized");
        _;
    }
    
    modifier isSaleOpen(){
        require(isOpen(), "has to be open");
        _;
    }
    
    modifier isFunded() {
        require(isSaleFunded, "Has to be funded");
        _;
    }
    
    /*
    * project owner should fund tokens into this contract pre-sale otherwise it will be Failed
      when the tokens equal to tokens for sale, it is funded
    */
    function fund(uint _amount) external isready isSalePreStarted{
        require(availableTokens().add(_amount) <= tokensForSale, "Tranfered tokens have to be equal or less than proposed");
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
        if(IERC20(token).balanceOf(address(this)) == tokensForSale){
            isSaleFunded = true;
        }
    }
    
    /*
    *  pre allocation round, users can send a certain amount of USDTs to this contract;
       we determine allocation quota by the membership tier level
       user inputs amount of tokens they desire, and estimate the USDTs needed
       after the IDO, suplus USDTs will be reverted.
    */ 
    function preAlloc(uint _amount) external isready isFunded isSaleOpen{
        require(_amount <= tokensForSale-tokensAllocated, "cannot excess available supply");
        uint8 _tier = TIER(Tiersys).getUserTier(_msgSender());
        require(_tier > uint8(0), "membership needed");
        uint cost = _amount.mul(price).div(1e16); // cost for this amount of tokens, please notify users, USDT with 6 decimals!!!
        IERC20(U).safeTransferFrom(_msgSender(), address(this), cost);
        
        if(userInfo[_msgSender()].times==0){
            tier_n[_tier] += 1;
            participants += 1; 

        }
        
        
        // update user info and state variable
        tokensAllocated += _amount;
        userInfo[_msgSender()].times += 1;
        userInfo[_msgSender()].amount += _amount; // 18 decimals
        userInfo[_msgSender()].uAmount += cost; // 6 decimals
        
        emit Allocation(_amount, _msgSender(), block.timestamp);
        
    }
    
    function getTotalWeight() public view returns(uint){
        uint totalweight;
        for(uint i=1; i<5; i++){
            totalweight +=  tier_n[uint8(i)] * weight[uint8(i)];
        }
        return totalweight;
    }
    
    /*
    *   users need to claim their allocation immediately after the first round ends,
        if timeout occurs, the second round will launch automatically
    */
    function claim() external isready isSaleFinalized{
        require(block.timestamp <= clearTime, "must claim before clear time!");
        require(!userInfo[_msgSender()].checked,"already claimed your part");
        uint w = getTotalWeight();
        uint8 _tier = TIER(Tiersys).getUserTier(_msgSender());
        
        uint quota = weight[_tier].mul(tokensForSale).div(w);
        uint amount_desired = userInfo[_msgSender()].amount;
        require(amount_desired>0,"No claimable amount!");
        if(amount_desired <= quota){
            IERC20(token).safeTransfer(_msgSender(), amount_desired);
            userInfo[_msgSender()].claimed += amount_desired;
            tokensClaimed = tokensClaimed.add(amount_desired);
            userInfo[_msgSender()].checked = true;

            emit Claim(amount_desired, _msgSender(), block.timestamp);
        }
        else{
            IERC20(token).safeTransfer(_msgSender(), quota);
            IERC20(U).safeTransfer(_msgSender(), price.mul(quota-amount_desired).div(1e16));
            userInfo[_msgSender()].claimed += quota;
            userInfo[_msgSender()].uAmount -= price.mul(quota-amount_desired).div(1e16); // 6 decimals
            tokensClaimed += quota;
            userInfo[_msgSender()].checked = true;

            emit Claim(quota, _msgSender(), block.timestamp);
        }
        
    }
    
    /*
    * project owner should set R2 sale target amount and price before 2nd round starts
    */
    function setR2(uint _price) isready external{
        //require(block.timestamp >= clearTime && block.timestamp < round2start, "must set r2 paras at proper time");
        
        R2ForSale = tokensForSale - tokensClaimed;
        price2 = _price;
        isR2started = true;
        
    }
    
    
    /*
    * 2nd round purchase for user
    */
    function R2purchase(uint _amount) isready external{

        require(isR2started, "purchase not started");
        require(block.timestamp >= round2start, "round2 not yet started");
        uint8 _tier = TIER(Tiersys).getUserTier(_msgSender());
        
        // each tier cannot excess corresponding quota
        uint temp =  userInfo2[_msgSender()].amount_purchased;
        if(_tier==0){require(temp <= R2ForSale * 1/100, "can buy no more than 1 percentage");}
        else if(_tier==1){require(temp  <= R2ForSale * 5/100, "can buy up to 5 percentage");}
        else if(_tier==2){require(temp  <= R2ForSale *15/100,"can buy up to 15 percentage");}
        
        require(R2bought + _amount <= R2ForSale, "purchase eamount connot excess total available");
        IERC20(U).safeTransferFrom(_msgSender(), address(this), _amount.mul(price2).div(1e16));
        IERC20(token).safeTransfer(_msgSender(), _amount);
        
        if(userInfo2[_msgSender()].times == 0 && userInfo[_msgSender()].times==0){
            participants += 1;
        }
        
        userInfo2[_msgSender()].amount_purchased += _amount;
        userInfo2[_msgSender()].u_paid += _amount.mul(price2).div(1e16);
        userInfo2[_msgSender()].times += 1;
        R2bought += _amount;
        
        emit Round2purchase(_amount,_msgSender(),block.timestamp);
        
        
    }
    
    /*
    * emergency case, owner can withdraw token and USDT balances in this contract.
      this interface called just before audit contract is ok,if audited ,will be killed

    */
    function salePull(address _account) public onlyOwner{
        require(!isAudit, "after audit not allowed!");
        IERC20(U).safeTransfer(_account, IERC20(U).balanceOf(address(this)));
        IERC20(token).safeTransfer(_account, IERC20(token).balanceOf(address(this)));
    }
    
    /*
    * A certain portion of IDO sales revenue are entitiled to owner,
      input a portion, and target account, owner only has one chance to Collect.
    */
    bool public hasCollected = false; 
    event Collected(address indexed _account, uint _amount);
    
    function Collect(address _account, uint _portion) public onlyOwner{
        require(!hasCollected,"Owner has already collected the entitiled portion");
        hasCollected = true;
        
        uint temp = IERC20(U).balanceOf(address(this)) * _portion / 100;
        IERC20(U).safeTransfer(_account, temp);
        emit Collected(_account, temp);
    }
    
    /*
     * withdraw remaining Tokens after 2 rounds of IDO
    */
    function withdrawTokens(address _account) public onlyOwner{
        IERC20(token).safeTransfer(_account, IERC20(token).balanceOf(address(this)));
    }
    
    
    /*
    * after collecting the entitiled portion of USDT, collect the remaining balance based on teh voting decision.
    */
    function CollectBalance(address _account) public onlyOwner{
        require(!isVote, "a voting process is still on");
        require(hasCollected, "please collect the entitiled part first");
        bool decision = voteCounts[0] >=voteCounts[1] ? true : false;
        require(decision,"Voting decision is no!!! ");
        
        uint temp = IERC20(U).balanceOf(address(this));
        IERC20(U).safeTransfer(_account, temp);
        emit Collected(_account, temp);
    }
    
    

    
    
    /*
    * project owner lauches vote or poll
        set the vote mode, with time paras start and duration
        these state variable will update with each round
    */
    bool public isVote = false;
    uint public voteStart;
    uint public voteDuration;
    uint public voteRound; 
    
    // 0 affirmative, 1 dissenting, 2 abstention
    mapping(uint => uint) public voteCounts;

    /*
    * launch a new round of voting process
      reset voting results, update round number and voting mode
    */
    function launchVote(uint _start, uint _duration) public onlyOwner{
        require(!isVote,"a voting is running now!!!");
        require(_start >= block.timestamp && _duration >0, "start time should be in the future");
        isVote = true;
        voteRound +=1;
        
        voteStart = _start;
        voteDuration = _duration;
        
        // reset current voting result counts
        voteCounts[0] = 0;
        voteCounts[1] = 0;
        voteCounts[2] = 0;
        
        emit VoteOn(voteRound);
    }
    
    /*
    * switch off a ended voting process, otherwise next round cannot start
    */
    function endVote() public onlyOwner{
        require(isVote, "make sure a vote is on");
        require(block.timestamp > voteStart + voteDuration,"This vote has not finished");
        
        isVote = false; // switch off voting mode
        emit VoteOff(voteRound);
    }
    
    event VoteOn(uint n);
    event VoteOff(uint n);
    
    // data for each votee.
    struct UserVote{
        uint direction;
        uint weights;
        bool voted;
    }
    
    // user addr => (round => UserVote)
    mapping(address => mapping(uint=>UserVote)) public userVote;
    event Vote(address indexed _user, uint _vote, uint weight);
    
    /*
    * vote function for user
    */
    function vote(uint _vote) external{
       require(isVote, "Not vote mode");
       require(block.timestamp>=voteStart && block.timestamp <= voteStart + voteDuration, "voting is not started or over");
       uint8 _tier = TIER(Tiersys).getUserTier(_msgSender());
       require(_tier>0,"Only membership has permission");
       require(!userVote[_msgSender()][voteRound].voted, "already voted");
       require(_vote ==0 || _vote==1 || _vote==2, "vote one option");
       
       uint ws = weight[_tier] * TIER(Tiersys).getUserStake(_msgSender());
       userVote[_msgSender()][voteRound].voted = true;
       userVote[_msgSender()][voteRound].direction = _vote;
       userVote[_msgSender()][voteRound].weights = ws;
       
       voteCounts[_vote] += ws;
       
       emit Vote(_msgSender(), _vote, ws);
     }
    
}
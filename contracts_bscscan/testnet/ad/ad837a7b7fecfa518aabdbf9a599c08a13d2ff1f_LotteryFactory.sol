/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract OnlyType is Ownable {
    address[] private oTypes;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {

    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyType() {
        bool flag = false;
        for(uint256 i = 0;i<oTypes.length;i++){
            if(oTypes[i]==_msgSender()){
                flag = true;
            }
        }
        require(flag, "caller is not the types");
        _;
    }
    
    function isType(address _type) public view returns (bool){
        for(uint i = 0;i<oTypes.length;i++){
            if(oTypes[i]==_type){
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function addType(address _newTypes) public virtual onlyOwner {
        oTypes.push(_newTypes);
    }
}

/**
 * @dev Collection of functions related to the address type
 */
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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
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
        // solhint-disable-next-line max-line-length
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILotteryFactory{
    function buyTicket(address _from,uint256 _amount,address _inviters)external;
    function createLotteryPhase(uint _salt) external;
    function startOrStop() external;
    function withdraw(address from)external;
    function addLottery(bool _isFree, uint256 _ticketPrice,uint256 _maxTicketNum,uint256 _maxTimestamp,uint256 _betweenTime,
        uint32 _fee,uint32 _inviteReward,address _useToken,address _target)external;
}

interface ILottery{
    function getPath()external returns(address[] memory) ;
}

contract LotteryFactory is OnlyType,ILotteryFactory {
    
    using SafeERC20 for IERC20;
    
    mapping(uint256=>address) public lotteryTypes;
    
    uint256 public types = 0;
    
    mapping(uint256=>LotteryInfo) public lotteries ;
    
    mapping(uint256 => mapping(uint32 => BuyTicketInfo[])) public ticketInfos;
    
    mapping(uint256 => mapping(address => uint256)) public userRewards ;
    
    mapping(address=>address) public userInviters;
    
    event BuyTicket(address indexed from, uint32 indexed phase, 
        uint32 tStart,uint32 tEnd);
    
    event Win(uint32 indexed phase,uint32 indexed ticketId, address winner);
    
    event Withdraw(address indexed from);
    
    IPancakeRouter02 pancakeRouter;

    struct LotteryInfo {
        bool started;
        bool isFree;
        uint256 ticketPrice;
        uint256 maxTicketNum;
        uint256 maxTimestamp;
        uint256 totalFee;
        uint32 fee; //500: 5% // 200: 2% // 50: 0.5%
        uint32 inviteReward;
        uint32 currentPhaseId;
        uint256 phaseStartTime;
        uint256 betweenTime;
        uint32 inTicket;
        address useToken;
        address target;
    }
    
    struct BuyTicketInfo{
        address buyer;
        uint32 start;
        uint32 end;
    }
    
    constructor ()  {
        pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }
    
    function addTypes(address _type)external onlyOwner returns (bool){
        
        require(_type != address(0), "type is the zero address");
        for(uint i = 1;i<=types;i++){
            require(lotteryTypes[i]!=_type,"lottery exists.");
        }
        
        types = types+1;
        
        lotteryTypes[types] = _type;
        
        addType(_type);
        
        return true;
    }
    
    function addLottery(bool _isFree, uint256 _ticketPrice,uint256 _maxTicketNum,uint256 _maxTimestamp,uint256 _betweenTime,
        uint32 _fee,uint32 _inviteReward,address _useToken,address _target)override external onlyType {
        uint256 _tType = getLotteryId(_msgSender());
        require(lotteries[_tType].maxTicketNum>0,"lottery has inited.");
        lotteries[_tType].started = false;
        lotteries[_tType].isFree=_isFree;
        lotteries[_tType].ticketPrice=_ticketPrice;
        lotteries[_tType].maxTicketNum=_maxTicketNum;
        lotteries[_tType].maxTimestamp=_maxTimestamp;
        lotteries[_tType].totalFee=0;
        lotteries[_tType].fee=_fee;
        lotteries[_tType].inviteReward=_inviteReward;
        lotteries[_tType].currentPhaseId=0;
        lotteries[_tType].phaseStartTime=0;
        lotteries[_tType].betweenTime=_betweenTime;
        lotteries[_tType].inTicket=0;
        lotteries[_tType].useToken=_useToken;
        lotteries[_tType].target=_target;
    }
    
    function getLotteryId(address _lotteryAddress)public view returns (uint256){
        for(uint256 i = 1;i<=types;i++){
            if(_lotteryAddress==lotteryTypes[i]){
                return i;
            }
        }
        return 0;
    }
    
    function startOrStop()external override onlyType {
        uint256 lotteryId = getLotteryId(_msgSender());
        require(lotteryId>0,"no such lottery.");
        LotteryInfo storage info = lotteries[lotteryId] ;
        require(info.maxTicketNum>0 ,"lottery not init");
        if(info.started){
            info.started = false;
        }else{
            info.started = true;
        }
    }
    
    function getTicketType(address tType) private view returns (uint256){
        bool flag = false;
        for(uint i = 1;i<types;i++){
            if(lotteryTypes[i]==tType){
                flag = true;
                return i;
            }
        }
        require(flag, "current type not found.");
        return 0;
    }
    
    function buyTicket(address _from,uint256 _amount,address _inviters)override external onlyType{
        if(userInviters[_from]==address(0)){
            userInviters[_from] = _inviters;
        }
        uint256 tType = getLotteryId(_msgSender());
        require(tType>0,"no such lottery.");
        LotteryInfo memory lottery = lotteries[tType];
        require(lottery.started,"lottery not start.");
        require(!isEnd(tType),"lottery ended.");
        if(lottery.isFree){
            _amount = 0;
        }else{
            require(_amount>0,"amount must bigger than 0.");
            require(_amount%lottery.ticketPrice==0,"amount must be divide exactly.");
            IERC20(lottery.useToken).safeTransferFrom(_from,address(this),_amount);
        }
        createTicket(tType,_from,_amount);
    }
    
    function isEnd(uint _tType) public view returns (bool){
        LotteryInfo memory lottery = lotteries[_tType];
        if(block.timestamp>lottery.phaseStartTime+lottery.maxTimestamp
            ||lottery.inTicket>=lottery.maxTicketNum){
            return true;
        }
        return false;
    }
    
    function createTicket(uint _tType,address _to,uint256 _amount) private{
        LotteryInfo storage lottery = lotteries[_tType];
        uint32 phase = lottery.currentPhaseId;
        uint32 nowTicket = lottery.inTicket;
        uint32 endTicket;
        if(_amount == 0){
            endTicket = nowTicket + 1;
        }else{
            endTicket = uint32(_amount/lottery.ticketPrice) ;
            lottery.inTicket = endTicket;
        }
        ticketInfos[_tType][phase].push(
            BuyTicketInfo({
                buyer:_to,
                start: nowTicket,
                end : endTicket -1
            }));
        emit BuyTicket(_to,lottery.currentPhaseId,nowTicket,endTicket -1);
    }
    
    function createLotteryPhase(uint _salt)override onlyType external{
        publish(_salt);
        uint256 _lotteryId = getLotteryId(_msgSender());
        uint tType = _lotteryId;
        LotteryInfo storage lottery = lotteries[tType];
        require(lottery.started,"lottery not start"); 
        uint32 nowLottery = lottery.currentPhaseId+1;
        lottery.currentPhaseId = nowLottery;
        if(lottery.isFree){
            lottery.phaseStartTime = lottery.phaseStartTime + lottery.betweenTime;
        }else{
            lottery.phaseStartTime = block.timestamp + lottery.betweenTime;
        }
        lottery.inTicket = 0;
    }
    
    function publish(uint _salt)private {
        uint256 _lotteryId = getLotteryId(_msgSender());
        uint nowTime = block.timestamp;
        uint tType = _lotteryId;
        LotteryInfo storage lottery = lotteries[tType];
        if(lottery.currentPhaseId==0){
            return;
        }
        require(lottery.started&&isEnd(tType),"current phase not end.");
        uint inAmount = lottery.ticketPrice * lottery.inTicket;
        uint encodeNum = uint(keccak256(abi.encode(nowTime,block.gaslimit,lottery.inTicket,_salt)));
        uint32 result = uint32(encodeNum%lottery.inTicket);
        BuyTicketInfo[] memory tInfos = ticketInfos[tType][lottery.currentPhaseId];
        address winner;
        for(uint32 i = 0;i<tInfos.length;i++ ){
            BuyTicketInfo memory tInfo = tInfos[i];
            if(result>=tInfo.start && result<= tInfo.end){
                winner = tInfo.buyer;
            }
        }
        uint feeAmount = lottery.fee * inAmount / 10 ** 4;
        uint inviteAmount = lottery.inviteReward * inAmount / 10 ** 4;
        if(userInviters[winner]!=address(0)){
            userRewards[tType][winner] = userRewards[tType][winner] + inAmount - feeAmount - inviteAmount;
            lottery.totalFee = lottery.totalFee + feeAmount + inviteAmount;
        }else{
            userRewards[tType][winner] = userRewards[tType][winner] + inAmount - feeAmount - inviteAmount;
            userRewards[tType][userInviters[winner]] = userRewards[tType][userInviters[winner]] + inviteAmount;
        }
        
        emit Win(lottery.currentPhaseId,result,winner);
    }
    
    function withdraw(address _from) override external{
        for(uint256 i = 0;i<= types;i++){
            if(userRewards[i][_from]>0){
                LotteryInfo memory lottery = lotteries[i];
                if(lottery.isFree){
                    address target = lottery.target;
                    uint256 tokenAmount = userRewards[i][_from];
                    _approve(target, _msgSender(), tokenAmount);
                    IERC20(target).safeTransfer(_from,tokenAmount);
                }else{
                    address typeAddress = lotteryTypes[i];
                    address token0 = lottery.useToken;
                    uint256 tokenAmount = userRewards[i][_from];
                    swapTokens(typeAddress,token0,tokenAmount,_from);
                }
            }
        }
        emit Withdraw(_from);
    }
    
    function swapTokens(address _type,address _token0, uint256 _tokenAmount,address _to) private {
        
        address[] memory path = ILottery(_type).getPath();

        _approve(_token0, address(pancakeRouter), _tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of UNI
            path,
            _to,
            block.timestamp
        );
    }
    
    function _approve(address token, address spender, uint256 amount) private {
        IERC20(token).approve(spender,amount);
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-09-24
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

interface ISuperoneFactory{
    function buyOne(address _from,uint256 _amount,address _inviters)external;
    function createSuperonePhase(uint _salt,uint currentMaxNum) external;
    function startOrStop() external;
    function addSuperone(bool _isFree, uint256 _OnePrice,uint256 _maxOneNum,uint256 _maxTimestamp,uint256 _betweenTime,
        uint32 _fee,uint32 _inviteReward,address _useToken,address _target)external;
    function updateFees(uint32 fee,uint32 inviteReward)external;
}

interface ISuperone{
    function getPath()external returns(address[] memory) ;
}

contract SuperoneFactory is OnlyType,ISuperoneFactory {
    
    using SafeERC20 for IERC20;
    
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    mapping(uint256=>address) public superoneTypes;
    
    uint256 public types = 0;
    
    mapping(uint256=>SuperoneInfo) public superones ;
    
    mapping(uint256 => mapping(uint32 => BuyOneInfo[])) public oneInfos;
    
    mapping(uint256 => mapping(address => uint256)) public userRewards ;
    
    mapping(address=>address) public userInviters;
    
    event BuyOne(address indexed from,uint256 indexed superoneId, uint32 indexed phase, 
        uint32 tStart,uint32 tEnd);
    
    event Win(uint256 indexed superoneId,uint32 indexed phase,uint32 oneId, address winner);
    
    event Reward(uint256 indexed superoneId,uint32 indexed phase,bool isWinner, address winner,uint256 amount);
    
    event Withdraw(address indexed from);
    
    event AddPhase(uint256 indexed superoneId,uint32 indexed phase,uint256 maxOneNum);
    
    event AddSuperone(address indexed token,uint256 indexed superoneId,bool isFree,uint256 onePrice,uint256 maxOneNum,address useToken,address target);
    
    event AddType(address indexed typeAddr,uint256 indexed typeId);
    
    IPancakeRouter02 pancakeRouter;

    struct SuperoneInfo {
        bool started;
        bool isFree;
        uint256 onePrice;
        uint256 maxOneNum;
        uint256 maxTimestamp;
        uint256 totalFee;
        uint32 fee; //500: 5% // 200: 2% // 50: 0.5%
        uint32 inviteReward;
        uint32 currentPhaseId;
        uint256 phaseStartTime;
        uint256 betweenTime;
        uint32 inOne;
        address useToken;
        address target;
    }
    
    struct BuyOneInfo{
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
            require(superoneTypes[i]!=_type,"superone exists.");
        }
        
        types = types+1;
        
        superoneTypes[types] = _type;
        
        addType(_type);
        
        emit AddType(_type,types);
        
        return true;
    }
    
    function addSuperone(bool _isFree, uint256 _onePrice,uint256 _maxOneNum,uint256 _maxTimestamp,uint256 _betweenTime,
        uint32 _fee,uint32 _inviteReward,address _useToken,address _target)override external onlyType {
        uint256 _tType = getSuperoneId(_msgSender());
        require(_tType>0,"no such type");
        require(superones[_tType].maxOneNum==0,"superone has inited.");
        superones[_tType].started = false;
        superones[_tType].isFree=_isFree;
        superones[_tType].onePrice=_onePrice;
        superones[_tType].maxOneNum=_maxOneNum;
        superones[_tType].maxTimestamp=_maxTimestamp;
        superones[_tType].totalFee=0;
        superones[_tType].fee=_fee;
        superones[_tType].inviteReward=_inviteReward;
        superones[_tType].currentPhaseId=0;
        superones[_tType].phaseStartTime=0;
        superones[_tType].betweenTime=_betweenTime;
        superones[_tType].inOne=0;
        superones[_tType].useToken=_useToken;
        superones[_tType].target=_target;
        emit AddSuperone(_msgSender(),_tType,_isFree,_onePrice,_maxOneNum,_useToken,_target);
    }
    
    function getSuperoneId(address _superoneAddress)public view returns (uint256){
        for(uint256 i = 1;i<=types;i++){
            if(_superoneAddress==superoneTypes[i]){
                return i;
            }
        }
        return 0;
    }
    
    function startOrStop()external override onlyType {
        uint256 superoneId = getSuperoneId(_msgSender());
        _startOrStop(superoneId);
    }
    
    function _startOrStop(uint256 _superoneId) private{
        uint256 superoneId = _superoneId;
        require(superoneId>0,"no such superone.");
        SuperoneInfo storage info = superones[superoneId] ;
        require(info.maxOneNum>0 ,"superone not init");
        if(info.started){
            info.started = false;
        }else{
            info.started = true;
        }
        if(info.currentPhaseId==0){
            _addPhase(superoneId,info,info.maxOneNum);
        }
    }
    
    function getOneType(address tType) private view returns (uint256){
        bool flag = false;
        for(uint i = 1;i<types;i++){
            if(superoneTypes[i]==tType){
                flag = true;
                return i;
            }
        }
        require(flag, "current type not found.");
        return 0;
    }
    
    function buyOne(address _from,uint256 _amount,address _inviters)override external onlyType{
        if(userInviters[_from]==address(0)){
            require(_from!=_inviters,"inviter can not be self.");
            userInviters[_from] = _inviters;
        }
        uint256 tType = getSuperoneId(_msgSender());
        require(tType>0,"no such superone.");
        SuperoneInfo memory superone = superones[tType];
        require(superone.started,"superone not start.");
        require(!isEnd(tType),"superone ended.");
        require(block.timestamp>superone.phaseStartTime,"current phase not start.");
        if(superone.isFree){
            _amount = 0;
            require(!_isBuyOne(_from,tType),"address already bought.");
        }else{
            require(_amount>0,"amount must bigger than 0.");
            require(_amount%superone.onePrice==0,"amount must be divide exactly.");
        }
        _createOne(tType,_from,_amount);
    }
    
    function isEnd(uint _tType) public view returns (bool){
        SuperoneInfo memory superone = superones[_tType];
        if(block.timestamp>superone.phaseStartTime+superone.maxTimestamp
            ||superone.inOne>=superone.maxOneNum){
            return true;
        }
        return false;
    }
    
    function canCreatePhase(uint _tType) public view returns (bool){
        SuperoneInfo memory superone = superones[_tType];
        return superone.started && isEnd(_tType);
    }
    
    function _createOne(uint _tType,address _to,uint256 _amount) private{
        SuperoneInfo storage superone = superones[_tType];
        uint32 phase = superone.currentPhaseId;
        uint32 nowOne = superone.inOne;
        uint32 endOne;
        if(_amount == 0){
            endOne = nowOne + 1;
        }else{
            endOne = nowOne + uint32(_amount/superone.onePrice) ;
        }
        superone.inOne = endOne;
        oneInfos[_tType][phase].push(
            BuyOneInfo({
                buyer:_to,
                start: nowOne,
                end : endOne - 1
            }));
        emit BuyOne(_to,_tType,superone.currentPhaseId,nowOne,endOne - 1);
    }
    
    function _isBuyOne(address _from,uint _tType)private view returns (bool){
        SuperoneInfo memory superone = superones[_tType];
        BuyOneInfo[] memory tInfos = oneInfos[_tType][superone.currentPhaseId];
        for(uint32 i = 0;i<tInfos.length;i++ ){
            BuyOneInfo memory tInfo = tInfos[i];
            if(tInfo.buyer==_from){
                return true;
            }
        }
        return false;
    }
    
    function createSuperonePhase(uint _salt,uint currentMaxNum)override onlyType external{
        _publish(_salt);
        uint256 _superoneId = getSuperoneId(_msgSender());
        SuperoneInfo storage superone = superones[_superoneId];
        _addPhase(_superoneId,superone,currentMaxNum);
    }
    
    function _addPhase(uint256 _tType, SuperoneInfo storage superone,uint256 currentMaxNum) private {
        require(superone.started,"superone not start."); 
        // if(superone.isFree){
        //     if(superone.phaseStartTime==0){
        //         superone.phaseStartTime = block.timestamp;
        //     }else{
        //         superone.phaseStartTime = block.timestamp + superone.betweenTime;
        //     }
        // }else{
        superone.phaseStartTime = block.timestamp + superone.betweenTime;
        // }
        uint32 nowSuperone = superone.currentPhaseId+1;
        superone.currentPhaseId = nowSuperone;
        superone.inOne = 0;
        superone.maxOneNum = currentMaxNum;
        emit AddPhase(_tType,nowSuperone,currentMaxNum);
    }
    
    function _publish(uint _salt)private {
        uint256 _superoneId = getSuperoneId(_msgSender());
        uint nowTime = block.timestamp;
        uint tType = _superoneId;
        SuperoneInfo storage superone = superones[tType];
        if(superone.inOne==0){
            return;
        }
        require(superone.started,"superone not start."); 
        require(isEnd(tType),"current phase not end.");
        require(block.timestamp>superone.phaseStartTime,"current phase not start.");
        if(superone.currentPhaseId==0){
            return;
        }
        uint inAmount;
        if(superone.isFree){
            inAmount = superone.onePrice;
        }else{
            inAmount = superone.onePrice * superone.inOne;
        }
        uint encodeNum = uint(keccak256(abi.encode(nowTime,block.gaslimit,superone.inOne,_salt)));
        uint32 result = uint32(encodeNum%superone.inOne);
        BuyOneInfo[] memory tInfos = oneInfos[tType][superone.currentPhaseId];
        address winner;
        for(uint32 i = 0;i<tInfos.length;i++ ){
            BuyOneInfo memory tInfo = tInfos[i];
            if(result>=tInfo.start && result<= tInfo.end){
                winner = tInfo.buyer;
            }
        }
        uint feeAmount = superone.fee * inAmount / 10 ** 4;
        uint inviteAmount = superone.inviteReward * inAmount / 10 ** 4;
        if(userInviters[winner]!=address(0)){
            userRewards[tType][winner] = userRewards[tType][winner] + inAmount - feeAmount - inviteAmount;
            userRewards[tType][userInviters[winner]] = userRewards[tType][userInviters[winner]] + inviteAmount;
            superone.totalFee = superone.totalFee + feeAmount;
            emit Reward(tType,superone.currentPhaseId,true,winner,inAmount - feeAmount - inviteAmount);
            emit Reward(tType,superone.currentPhaseId,false,userInviters[winner], inviteAmount);
        }else{
            userRewards[tType][winner] = userRewards[tType][winner] + inAmount - feeAmount - inviteAmount;
            superone.totalFee = superone.totalFee + feeAmount + inviteAmount;
            emit Reward(tType,superone.currentPhaseId,true,winner,inAmount - feeAmount - inviteAmount);
        }
        
        emit Win(tType,superone.currentPhaseId,result,winner);
    }
    
    function withdraw() external{
        address _from = _msgSender();
        for(uint256 i = 0;i<= types;i++){
            if(userRewards[i][_from]>0){
                SuperoneInfo memory superone = superones[i];
                if(superone.isFree){
                    address target = superone.target;
                    uint256 tokenAmount = userRewards[i][_from];
                    userRewards[i][_from] = 0;
                    IERC20(target).safeTransfer(_from,tokenAmount);
                }else{
                    address typeAddress = superoneTypes[i];
                    address token0 = superone.useToken;
                    uint256 tokenAmount = userRewards[i][_from];
                    userRewards[i][_from] = 0;
                    _swapTokens(typeAddress,token0,tokenAmount,_from);
                }
            }
        }
        emit Withdraw(_from);
    }
    
    function takeFee(address _to)external onlyOwner {
        for(uint256 i = 0;i<= types;i++){
            SuperoneInfo storage superone = superones[i];
            uint amount = superone.totalFee;
            if(amount>0){
                if(superone.isFree){
                    IERC20(superone.target).safeTransfer(_to,amount);
                }else{
                    IERC20(superone.useToken).safeTransfer(_to,amount);
                }
                superone.totalFee = 0;
            }
        }
    }
    
    function updateFees(uint32 fee,uint32 inviteReward)override external onlyType{
        uint256 _superoneId = getSuperoneId(_msgSender());
        SuperoneInfo storage superone = superones[_superoneId];
        superone.fee =fee;
        superone.inviteReward = inviteReward;
    }
    
    function _swapTokens(address _type,address _token0, uint256 _tokenAmount,address _to) private {
        
        address[] memory path = ISuperone(_type).getPath();

        _approve(_token0, address(pancakeRouter), _tokenAmount);

        if(path[path.length-1]==WBNB){
            pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _tokenAmount,
                0, // accept any amount of UNI
                path,
                _to,
                block.timestamp
            );
        }else{
        // make the swap
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _tokenAmount,
                0, // accept any amount of UNI
                path,
                _to,
                block.timestamp
            );
        }
    }
    
    function _approve(address token, address spender, uint256 amount) private {
        IERC20(token).approve(spender,amount);
    }
}
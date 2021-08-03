/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-02
*/

pragma solidity ^0.7.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
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


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


interface Uniswap {
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract Token {
    
    function transfer(address to, uint256 value) public virtual returns (bool);
    
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    
    function approve(address _spender, uint256 _value) public virtual returns (bool);
    
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SIP {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    event SubscribeToSpp(uint256 indexed sppID,address indexed customerAddress,uint256 value,uint256 period,address indexed tokenGet,address tokenGive);
    event ChargeSpp(uint256 sppID);
    event CloseSpp(uint256 sppID);
    event Deposit(address indexed token,address indexed user,uint256 amount,uint256 balance);
    event Withdraw(address indexed token,address indexed user,uint256 amount,uint256 balance);

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier _ifNotLocked() {
        require(scLock == false);
        _;
    }
    

    function setLock() external _ownerOnly {
        scLock = !scLock;
    }

    function changeOwner(address owner_) external _ownerOnly {
        potentialAdmin = owner_;
    }

    function becomeOwner() external {
        if (potentialAdmin == msg.sender) owner = msg.sender;
    }

    function depositToken(address token, uint256 amount) external {
        require(token != address(0), "IT");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        //require(Token(token).transferFrom(msg.sender, address(this), amount), "TF");
        tokens[token][msg.sender] = SafeMath.add(
            tokens[token][msg.sender],
            amount
        );
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) external {
        require(token != address(0), "IT");
        //require(tokens[token][msg.sender] >= amount, "IB");
        tokens[token][msg.sender] = SafeMath.sub(
            tokens[token][msg.sender],
            amount
        );
        IERC20(token).safeTransfer(msg.sender, amount);
        //require(Token(token).transfer(msg.sender, amount), "WF");
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function tokenBalanceOf(address token, address user) public view returns (uint256 balance) {
        return tokens[token][user];
    }
    
    function _storePairDetails(address _token0, address _token1, address _pair) internal {
         if(pairDetails[_token0][_token1]==address(0)){ // NOT SET YET
             pairDetails[_token0][_token1] = _pair;
         }
    } 
    
    function _fetchNewAddress( uint256 _sppID, address _token0, address _token1) internal view returns (address pair) {
         if(pairDetails[_token0][_token1]==address(0)){ // NOT SET YET
             return address(_sppID);
         }
         else {
            return pairDetails[_token0][_token1];
         }
    } 
    

    function subscribeToSpp(uint256 value, uint256 period, address tokenGet, address tokenGive) external _ifNotLocked returns (uint256 sID) {
        address customerAddress = msg.sender;
        require(period >= minPeriod, "MIN_FREQUENCY");
        require(period.mod(3600) == 0, "INTEGRAL_MULTIPLE_OF_HOUR_NEEDED");
        require(tokenBalanceOf(tokenGive,customerAddress) >= value, "INSUFFICENT_BALANCE");
            _deductFee(customerAddress, WETH, initFee);
            sppID += 1;
            
            require(tokenGet != tokenGive, 'IDENTICAL_ADDRESSES');
            (address token0, address token1) = tokenGet < tokenGive ? (tokenGet, tokenGive) : (tokenGive, tokenGet);
            require(token0 != address(0), 'ZERO_ADDRESS');
            address pair = IUniswapV2Factory(factory).getPair(tokenGet, tokenGive); //reverse this and try
            
            if(pair == address(0)){
                pair = _fetchNewAddress(sppID, token0, token1); // Set an arbitary pair if pair doesn't exists
            }
            
            // require(pair != address(0), 'NO_SUCH_PAIR');
            
            if(token0==tokenGet){
                if(map1[pair].exists== false){
                    map1[pair].token.push(tokenGive);
                    if(tokenGive ==  WETH || tokenGet == WETH){
                        map1[pair].token.push(tokenGet);
                    }
                    else {
                        map1[pair].token.push(WETH);
                        map1[pair].token.push(tokenGet);
                    }
                    map1[pair].exists = true;
                    map1[pair].position = 0;
                    _storePairDetails(token0, token1, pair);
                }
                map1[pair].sppList.push(sppID);
            }
            else{
                if(map2[pair].exists== false){
                    map2[pair].token.push(tokenGive);
                    if(tokenGive ==  WETH || tokenGet == WETH){
                        map2[pair].token.push(tokenGet);
                    }
                    else {
                        map2[pair].token.push(WETH);
                        map2[pair].token.push(tokenGet);
                    }
                    map2[pair].exists = true;
                    map2[pair].position = 0;
                    _storePairDetails(token0, token1, pair);
                }
                map2[pair].sppList.push(sppID);
            }
            
            sppSubscriptionStats[sppID] = sppSubscribers({
                exists: true,
                customerAddress: customerAddress,
                value: value,
                period: period,
                lastPaidAt: (block.timestamp).sub(period)
            });
            tokenStats[sppID] = currentTokenStats({
                TokenToGet: tokenGet,
                TokenToGive: tokenGive,
                amountGotten: 0,
                amountGiven: 0
            });
            sppSubList[customerAddress].arr.push(sppID);
            emit SubscribeToSpp(sppID,customerAddress,value,period,tokenGet,tokenGive);
            return sppID;
    }
    
    
    function possibleToCharge(uint256 _sppID) public view returns (bool) {
        
        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        address tokenGive = _tokenStats.TokenToGive;
        if(_subscriptionData.exists==false){
            return false; // SIP is not active
        }
        else if(tokens[WETH][_subscriptionData.customerAddress] < minWETH){
            return false; // No WETH to pay for fee
        }
        else if(_subscriptionData.value > tokens[tokenGive][_subscriptionData.customerAddress]){
            return false; // Insufficient Balance
        }
        
        return true;
    }


    function chargeWithSPPIndexes(address pair, uint256[] calldata _indexes, bool _upwards) external _ownerOnly _ifNotLocked {
        
        uint256 gasStart = 21000 + gasleft() + 3000 +  (16 * msg.data.length);

        uint256[] memory result;
        pairStats storage _pairData = map1[pair]; 
        
        if(!_upwards){
           _pairData = map2[pair]; 
        }
        
        uint256[] storage sppList = _pairData.sppList;
        
        require(sppList.length!=0, "No SIP to charge");
        
        address[] storage pathSwap = _pairData.token;
        
        uint256 finalAmountGive = 0;
        uint256 finalAmountGotten = 0;
        
        chargeSppStruct[] memory sppCharged = new chargeSppStruct[]((_indexes.length + 1));
        
        uint successIndex = 0;
        
        for(uint256 i=0; i< _indexes.length; i++){
            if(_indexes[i] > (sppList.length-1)){
                continue; // No such SIP index. Invalid input. Return and save GAS
            }
            uint256 _sppID = sppList[_indexes[i]];
            sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
            if(_subscriptionData.exists==false){
                continue; // SIP is not active
            }
            else if(tokens[WETH][_subscriptionData.customerAddress] < minWETH){
                continue; // No WETH to pay for fee
            }
            else if(_subscriptionData.lastPaidAt + _subscriptionData.period > block.timestamp){
                continue; // Charging too early
            }
            else if(_subscriptionData.value > tokens[pathSwap[0]][_subscriptionData.customerAddress]){
                continue; // Insufficient Balance
            }
            else {
                finalAmountGive += _subscriptionData.value;
                _deductTokens(_subscriptionData.value, _subscriptionData.customerAddress, pathSwap[0]);
                sppCharged[successIndex] = chargeSppStruct({
                    sppId: _sppID,
                    amt: _subscriptionData.value,
                    custAdd: _subscriptionData.customerAddress
                });
                successIndex++;
            }
        }
        
        require(finalAmountGive > 0 , "Nothing to charge");
        
        uint256[] memory amounts = Uniswap(uniswapContractAddress).getAmountsOut(finalAmountGive, pathSwap);
        
        require(Token(pathSwap[0]).approve(uniswapContractAddress,finalAmountGive),"approve failed");
        result = Uniswap(uniswapContractAddress).swapExactTokensForTokens(finalAmountGive, amounts[amounts.length-1], pathSwap, address(this), block.timestamp+10000);
        
        // take some fee here first // fix linke 618
        finalAmountGotten = result[result.length-1];
        finalAmountGotten = finalAmountGotten.sub(_deductSppFee(finalAmountGotten, pathSwap[pathSwap.length-1]));

        uint256 txFee = (gasStart - gasleft() +  (successIndex * 50000)) * tx.gasprice;
        uint256 _feeDed = txFee;
        
        for(uint256 k=0; k<successIndex; k++){
            uint256 _credAmt = ((sppCharged[k].amt).mul(finalAmountGotten)).div(finalAmountGive);
            uint256 _feeWETH = ((sppCharged[k].amt).mul(txFee)).div(finalAmountGive);
            _creditTokens( _credAmt, sppCharged[k].custAdd, pathSwap[pathSwap.length-1]);
            _deductTokens(Math.min(_feeWETH, tokens[WETH][sppCharged[k].custAdd]), sppCharged[k].custAdd, WETH);
            _feeDed = _feeDed - Math.min(_feeWETH, tokens[WETH][sppCharged[k].custAdd]);
            require(setcurrentTokenStats(sppCharged[k].sppId, _credAmt, sppCharged[k].amt),"setcurrentTokenStats failed");
            require(setLastPaidAt(sppCharged[k].sppId),"setLastPaidAt failed");
        }
        _creditTokens((txFee - _feeDed), feeAccount, WETH);
    }

    function chargeSppByID(uint256 _sppId) external _ifNotLocked  {
        
        uint256[] memory result;
        currentTokenStats storage _tokenStats = tokenStats[_sppId];
        
        address tokenGive = _tokenStats.TokenToGive;
        address tokenGet = _tokenStats.TokenToGet;
        
        uint256 finalAmountGive = 0;
        uint256 finalAmountGotten = 0;

        uint8 lengthPath = 3;

        if(tokenGive == WETH || tokenGet == WETH){
            lengthPath = 2;
        }
        
        address[] memory paths = new address[](lengthPath);
        paths[0] = tokenGive;
        if(tokenGive == WETH || tokenGet == WETH){
            paths[1] = tokenGet;
        }
        else {
            paths[1] = WETH;
            paths[2] = tokenGet;
        }

        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppId];
        require(_subscriptionData.exists==true, "NVS");
        require(_subscriptionData.lastPaidAt + _subscriptionData.period <= block.timestamp, "CTE");
        require(_subscriptionData.value <= tokens[tokenGive][_subscriptionData.customerAddress], "IB");

        finalAmountGive = _subscriptionData.value;
        require(finalAmountGive > 0 , "Nothing to charge");
        
        
        _deductTokens(_subscriptionData.value, _subscriptionData.customerAddress, tokenGive);
        
        
        uint256[] memory amounts = Uniswap(uniswapContractAddress).getAmountsOut(finalAmountGive, paths);
        
        require(Token(tokenGive).approve(uniswapContractAddress,finalAmountGive),"approve failed");
        result = Uniswap(uniswapContractAddress).swapExactTokensForTokens(finalAmountGive, amounts[amounts.length-1], paths, address(this), block.timestamp+10000);
        
        // take some fee here first
        finalAmountGotten = result[result.length-1];
        finalAmountGotten = finalAmountGotten.sub(_deductSppFee(finalAmountGotten, tokenGet));

        _creditTokens( finalAmountGotten, _subscriptionData.customerAddress, tokenGet);
        require(setcurrentTokenStats(_sppId, finalAmountGotten, _subscriptionData.value),"setcurrentTokenStats failed");
        require(setLastPaidAt(_sppId),"setLastPaidAt failed");

    }
    
 
    function _deductSppFee(uint256 _amt, address _token) internal returns (uint256) {
        uint256 _feeAmt = ((_amt).mul(fee)).div(10000);
        _creditTokens(_feeAmt, feeAccount, _token);
        return _feeAmt;
    }
    
    function _deductTokens(uint256 _amt, address _custAdd, address _token) internal {
        tokens[_token][_custAdd] = SafeMath.sub(tokens[_token][_custAdd],_amt);
    }
    
    function _creditTokens(uint256 _amt, address _custAdd, address _token) internal {
        tokens[_token][_custAdd] = SafeMath.add(tokens[_token][_custAdd],_amt);
    }
    

    function closeSpp(uint256 _sppId) external returns (bool success) {
        require(msg.sender == sppSubscriptionStats[_sppId].customerAddress, "NA");
        sppSubscriptionStats[_sppId].exists = false;
        inactiveSIP[_sppId] = true;
        emit CloseSpp(_sppId);
        return true;
    }
    
    function _deductFee(address customerAddress, address token, uint256 amount) internal {
        tokens[token][customerAddress] = tokens[token][customerAddress].sub(amount);
        tokens[token][feeAccount] = tokens[token][feeAccount].add(amount);
    }
    

    function setAddresses(address feeAccount1, address uniswapContractAddress1, address factory1, address _weth) external _ownerOnly {
        feeAccount = feeAccount1;
        uniswapContractAddress = uniswapContractAddress1;
        factory = factory1;
        WETH = _weth;
    }

    function setMinPeriod(uint256 p) external _ownerOnly {
        minPeriod = p;
    }

    function setLastPaidAt(uint256 _sppID) internal returns (bool success) {
        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
        _subscriptionData.lastPaidAt = getNearestHour(block.timestamp);
        return true;
    }

    function setcurrentTokenStats(uint256 _sppID, uint256 amountGotten, uint256 amountGiven) internal returns (bool success) {
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        _tokenStats.amountGotten = _tokenStats.amountGotten.add(amountGotten);
        _tokenStats.amountGiven = _tokenStats.amountGiven.add(amountGiven);
        return true;
    }

    function isActiveSpp(uint256 _sppID) public view returns (bool res) {
        return sppSubscriptionStats[_sppID].exists;
    }
    
     function getLatestSppId() public view returns (uint256 sppId) {
        return sppID;
    }

    function getlistOfSppSubscriptions(address _from) public view returns (uint256[] memory arr) {
        return sppSubList[_from].arr;
    }

    function getcurrentTokenAmounts(uint256 _sppID) public view returns (uint256[2] memory arr) {
        arr[0] = tokenStats[_sppID].amountGotten;
        arr[1] = tokenStats[_sppID].amountGiven;
        return arr;
    }

    function getTokenStats(uint256 _sppID) public view returns (address[2] memory arr) {
        arr[0] = tokenStats[_sppID].TokenToGet;
        arr[1] = tokenStats[_sppID].TokenToGive;
        return arr;
    }
    
    function fetchPairAndDirection(uint256 _sppID) public view returns (bool direction, address pair) {
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        
        address tokenGive = _tokenStats.TokenToGive;
        address tokenGet = _tokenStats.TokenToGet;

        (address token0, address token1) = tokenGet < tokenGive ? (tokenGet, tokenGive) : (tokenGive, tokenGet);

        address _pair = pairDetails[token0][token1];
        bool _direction = false;

        if(token0==tokenGet){
            _direction = true;
        }
        return (_direction, _pair);
    }
    
    function fetchPathDetailsAdd(address _pair, bool _upwards) public view returns (address[] memory arr) {
        if (_upwards){
           return map1[_pair].token; 
        }
        else {
            return map2[_pair].token;
        }
    }
    
    function fetchPathDetailsSPP(address _pair, bool _upwards) public view returns (uint256[] memory arr) {
        if (_upwards){
           return map1[_pair].sppList; 
        }
        else {
            return map2[_pair].sppList;
        }
    }

    function getTimeRemainingToCharge(uint256 _sppID) public view returns (uint256 time) {
        if((sppSubscriptionStats[_sppID].lastPaidAt).add(sppSubscriptionStats[_sppID].period) < block.timestamp){
            return 0;
        }
        else {
          return ((sppSubscriptionStats[_sppID].lastPaidAt).add(sppSubscriptionStats[_sppID].period).sub(block.timestamp));  
        }
    }
    
    // Update dev address by initiating with the previous dev.
    function changeFee(uint8 _fee) external _ownerOnly{
        require(_fee <= 25, "Cannot increase fee beyond 25");
        fee = _fee;
    }

    // Update min WETH needed for cgarge SIP to run.
    function changeMinWETH(uint256 _minWETH) external _ownerOnly{
        minWETH = _minWETH;
    }

    // Update min WETH needed for cgarge SIP to run.
    function setInitFee(uint256 _initFee) external _ownerOnly{
        initFee = _initFee;
    }
    
    // Change starting position of a pair.
    function changePosition(address pair, uint256 _index, bool _upwards) external _ownerOnly{
        if(_upwards){
            map1[pair].position = _index;
        }
        else {
            map2[pair].position = _index;
        }
    }
    
    // This function is to optimise batching process
    function getNearestHour(uint256 _time) public pure returns (uint256) {
        uint256 _secondsExtra = _time.mod(3600);
        if(_secondsExtra > 1800){
            return ((_time).add(3600)).sub(_secondsExtra);
        }
        else {
            return (_time).sub(_secondsExtra);
        }
    }

    struct sppSubscribers {
        bool exists;
        address customerAddress;
        uint256 value; 
        uint256 period;
        uint256 lastPaidAt;
    }

    struct currentTokenStats {
        address TokenToGet;
        uint256 amountGotten;
        address TokenToGive;
        uint256 amountGiven;
    }

    struct listOfSppByAddress {
        uint256[] arr;
    }
    
    struct pairStats{
        address[] token;
        uint256[] sppList;
        bool exists;
        uint256 position;
    }
    
    struct chargeSppStruct {
        uint256 sppId;
        uint256 amt;
        address custAdd;
    }
    
    mapping(uint256 => uint256) public sppAmounts;
    mapping(address => pairStats) private map1;
    mapping(address => pairStats) private map2;
    mapping(uint256 => currentTokenStats) tokenStats;
    mapping(address => listOfSppByAddress) sppSubList;
    mapping(uint256 => sppSubscribers) public sppSubscriptionStats;
    mapping(address => mapping(address => uint256)) public tokens;

    mapping(uint256 => bool) public inactiveSIP; // contains a SIP ID only if it existed and now has been deactivated
    
    // TOKEN0 -> TOKEN1 -> PAIRADD
    mapping(address => mapping(address => address)) public pairDetails;

    
    address public uniswapContractAddress;
    address public factory;
    address public owner;
    address public WETH;
    address private potentialAdmin;
    uint256 public sppID;
    address public feeAccount;
    bool public scLock = false;
    uint8 public fee = 25;
    uint256 public minPeriod = 3600;
    uint256 public minWETH;
    uint256 public initFee;
    
}

contract BNSSIPDapp is SIP {
    receive() external payable {
        revert();
    }

    string public name;

    constructor() {
        owner = msg.sender;
        name = "BNS SIP Dapp";
    }
}
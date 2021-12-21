/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint16);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
 * @dev Partial interface for a Chainlink Aggregator.
 */
interface AggregatorV3Interface {
    // latestRoundData should raise "No data present"
    // if he do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function latestRoundData()
        external
        view
        returns (
            uint160 roundId,
            int answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint160 answeredInRound
        );
}

contract DexilonTest_v9 {
    using SafeERC20 for IERC20;
    
    struct userAssetParameters {
        string assetName;
        int256 assetBalance;
        uint256 assetLockedBalance;
        uint256 assetPrice;
        uint16 assetLeverage;
    }

    mapping(address => uint256) internal usersAvailableBalances;
    mapping(address => mapping (string => userAssetParameters)) internal usersAssetsData;
    
    string[] internal assetsNames;
    mapping(string => bool) internal checkAsset;
    
    event Deposit(
        address indexed depositor,
        uint256 amountUSDC,
        uint256 timestamp
    );
    
    event Withdraw(
        address indexed user,
        uint256 amountUSDC,
        uint256 timestamp
    );
    
    event Trade(
        bool isBuyOrder,
        address indexed maker,
        address indexed taker,
        string asset,
        uint256 amountWei,
        uint256 rate,
        uint16 assetLeverage,
        uint256 timestamp
    );
    
    address[] public funders;
    uint256 public funderCount;
    
    uint16 internal constant DECIMALS_USDC = 6;
    uint16 internal constant DECIMALS_BTC = 18;
    
    int internal constant BTC_UNIT_FACTOR = int(10**DECIMALS_BTC);
    int internal constant ROUNDING_FACTOR = int(10**(DECIMALS_BTC-DECIMALS_USDC));
    
    address payable public owner;
    
    // Chainlink price feed for BTC/USD
    AggregatorV3Interface internal btcToUsdPriceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);
    // Chainlink price feed for USDC/USD
    AggregatorV3Interface internal usdcToUsdPriceFeed = AggregatorV3Interface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);
    
    IERC20 internal depositToken = IERC20(0x7592A72A46D3165Dcc7BF0802D70812Af19471B3); // USDC test token (Mumbai Testnet)
    
    constructor(address USDC_address) {
        owner = payable(msg.sender);
        // Base stable coin
        depositToken = IERC20(USDC_address);
        // Supported assets
        assetsNames = ['BTC','ETH','XRP','SOL'];
        
        for (uint16 i=0; i<assetsNames.length; i++) {
            checkAsset[assetsNames[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @notice Convert btc to usdc by Chainlink market price
    */
    function btcToUsdcMarketConvert(int amountWei) public view returns (int) {
        (, int signedBtcToUsdPrice, , , ) = btcToUsdPriceFeed.latestRoundData();
        (, int signedUsdcToUsdPrice, , , ) = usdcToUsdPriceFeed.latestRoundData();
        
        return (signedBtcToUsdPrice*amountWei/signedUsdcToUsdPrice)/int(10**(DECIMALS_BTC - DECIMALS_USDC));
    }

    /**
     * @dev Deposit token into contract and open user account
     * @param amountUSDC Amount of token in smallest units
     */
    function deposit(uint256 amountUSDC) public {
        depositToken.safeTransferFrom(msg.sender, address(this), amountUSDC);
        
        usersAvailableBalances[msg.sender] += amountUSDC * uint(ROUNDING_FACTOR);

        /// development ONLY
        funders.push(msg.sender);
        funderCount += 1;
        
        emit Deposit(msg.sender, amountUSDC, block.timestamp);
    }
    
    /// @notice calculate total locked balance for all assets
    function calculateTotalLocked(address userAddress) internal view returns(uint256 totalLocked) {
        totalLocked = 0;
        for (uint16 i=0; i < assetsNames.length; i++) {
            totalLocked += usersAssetsData[userAddress][assetsNames[i]].assetLockedBalance;
        }
    }

    /**
     * @dev Read all balances for the user
     * @param user Address of the user is the id of account
     */
    function getUserBalances(address user) public view 
        returns (
            uint256 availableBalance, 
            uint256 lockedBalance,
            userAssetParameters memory asset1,
            userAssetParameters memory asset2,
            userAssetParameters memory asset3,
            userAssetParameters memory asset4
        ) 
    {
        availableBalance = usersAvailableBalances[user] / uint(ROUNDING_FACTOR);
        lockedBalance = calculateTotalLocked(user) / uint(ROUNDING_FACTOR);

        asset1 = _setOutputDecimalsForAsset(usersAssetsData[user][assetsNames[0]]); // BTC
        asset2 = _setOutputDecimalsForAsset(usersAssetsData[user][assetsNames[1]]); // ETH
        asset3 = _setOutputDecimalsForAsset(usersAssetsData[user][assetsNames[2]]); // XRP
        asset4 = _setOutputDecimalsForAsset(usersAssetsData[user][assetsNames[3]]); // SOL
    }

    /**
     * @dev convert locked balance and asset price to USDC decimals
     * @param assetData struct userAssetParameters for current asset of the user
     */
    function _setOutputDecimalsForAsset(userAssetParameters memory assetData) internal pure returns (userAssetParameters memory assetDataModified) {
        // struct userAssetParameters {
        // 0 string assetName;
        // 1 int256 assetBalance;
        // 2 uint256 assetLockedBalance;
        // 3 uint256 assetPrice;
        // 4 uint16 assetLeverage; }
        assetDataModified.assetName = assetData.assetName;
        assetDataModified.assetBalance = assetData.assetBalance; // BTC decimals
        assetDataModified.assetLockedBalance = assetData.assetLockedBalance / uint(ROUNDING_FACTOR); // USDC decimals
        assetDataModified.assetPrice = assetData.assetPrice / uint(ROUNDING_FACTOR); // USDC decimals
        assetDataModified.assetLeverage = assetData.assetLeverage; 
    }

    /**
     * @dev withdraw all available balance for the user
     * @param amountUSDC amount of the deposited token in smallest units
     */
    function withdraw(uint256 amountUSDC) public {
        require(amountUSDC <= (usersAvailableBalances[msg.sender]) / uint(ROUNDING_FACTOR), 'DexilonTest: Insufficient balance!');
        
        usersAvailableBalances[msg.sender] -= amountUSDC * uint(ROUNDING_FACTOR);
        
        depositToken.safeTransfer(msg.sender, amountUSDC);
        
        emit Withdraw(msg.sender, amountUSDC, block.timestamp);
    }

    /// @dev development ONLY
    function withdrawAll() public onlyOwner {
        depositToken.safeTransfer(owner, depositToken.balanceOf(address(this)));
        
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

    /// @dev development ONLY
    function resetUserAccount(address userAddress, 
                              uint256 userAvailableBalance,
                              uint256 userLockedBalance,
                              string memory asset,
                              int256 userAssetBalance,
                              uint16 leverage) public onlyOwner {
        usersAvailableBalances[userAddress] = userAvailableBalance;
        
        userAssetParameters memory zeroParameters;
        zeroParameters.assetName = '';
        zeroParameters.assetBalance = 0;
        zeroParameters.assetLockedBalance = 0;
        zeroParameters.assetPrice = 0;
        zeroParameters.assetLeverage = 1;

        for (uint16 i=0; i<assetsNames.length; i++) {
            usersAssetsData[userAddress][assetsNames[i]] = zeroParameters;
            usersAssetsData[userAddress][assetsNames[i]].assetName = assetsNames[i];
            usersAssetsData[userAddress][assetsNames[i]].assetLeverage = leverage;
        }

        usersAssetsData[userAddress][asset].assetBalance = userAssetBalance;
        usersAssetsData[userAddress][asset].assetLockedBalance = userLockedBalance;
        if (userAssetBalance != 0){
            usersAssetsData[userAddress][asset].assetPrice = uint((int(userLockedBalance * leverage)  * BTC_UNIT_FACTOR) / 
            abs(userAssetBalance));}

    }
       
    /**
    * @dev trade between a maker and a taker
    * @param isBuyOrder true if this is a buy order trade, false if a sell order trade
    * @param maker the address of the user who created the order
    * @param taker the address of the user who accepted the order
    * @param asset string id of the supported asset ('BTC','ETH','XRP','SOL')
    * @param amountWei the amount of the asset in Wei (smallest unit)
    * @param rate price of 1 asset coin in the smallest unit of USDC
    **/
    function trade(
        bool isBuyOrder,
        address maker,
        address taker,
        string memory asset,
        uint256 amountWei,
        uint256 rate,
        uint16 assetLeverage
    ) public onlyOwner {
        
        require(checkAsset[asset], 'DexilonTest: Unknown Asset!');

        updateUserLeverage(maker, asset, assetLeverage);
        updateUserLeverage(taker, asset, assetLeverage);
        
        updateUserBalances(maker, asset, (isBuyOrder ? int(1) : int(-1))*int(amountWei), int(rate));
        updateUserBalances(taker, asset, (isBuyOrder ? int(-1) : int(1))*int(amountWei), int(rate));
        
        emit Trade(isBuyOrder, maker, taker, asset, amountWei, rate, assetLeverage, block.timestamp);
    }
    
    /**
    * @dev update the balances of one of the traders
    * @param user user address whose balances are updated
    * @param asset string id of the supported asset ('BTC','ETH','XRP','SOL')
    * @param amountWei the amount of the asset in Wei (smallest unit)
    * @param rate price of 1 asset coin in the smallest unit of USDC
    **/
    function updateUserBalances(
        address user,
        string memory asset,
        int amountWei,
        int rate
    ) internal {
        int assetBalance = usersAssetsData[user][asset].assetBalance;
        int lockedBalance = int(usersAssetsData[user][asset].assetLockedBalance);
        int assetPrice = int(usersAssetsData[user][asset].assetPrice);
        int leverage = int(uint256(usersAssetsData[user][asset].assetLeverage));
        int availableBalance = int(usersAvailableBalances[user]);
        int newAvailableBalance;  
        int newLockedBalance;
        int newAssetPrice;

        usersAssetsData[user][asset].assetName = asset;

        leverage = leverage * BTC_UNIT_FACTOR;
        rate = rate * ROUNDING_FACTOR;

        require(leverage > 0, 'DexilonTest: Zero Leverage!');
        require(rate > 0, 'DexilonTest: Zero Rate!');
        
        if (((amountWei > 0 && assetBalance < 0) || 
              (amountWei < 0 && assetBalance > 0)) &&
                abs(amountWei) > abs(assetBalance)) {
            
            availableBalance = availableBalance  
                + abs(assetBalance)*assetPrice/(leverage) 
                - assetBalance*(assetPrice - rate)/(BTC_UNIT_FACTOR);
            lockedBalance = lockedBalance - abs(assetBalance*assetPrice/(leverage));
            amountWei = amountWei + assetBalance;
            assetBalance = 0;
        }
        
                
        if (assetBalance == 0  
                || (assetBalance < 0 && amountWei < 0) 
                || (assetBalance > 0 && amountWei > 0)) {

            newAvailableBalance = availableBalance
                - abs(amountWei*rate/(leverage));
            newLockedBalance = lockedBalance + abs(amountWei*rate/(leverage));
            newAssetPrice = (assetBalance*assetPrice + amountWei*rate) / (assetBalance + amountWei);

        } else {
            // (assetBalance > 0 && amountWei < 0)
            // (assetBalance < 0 && amountWei > 0)
            newAvailableBalance = availableBalance 
                + abs(amountWei)*assetPrice/(leverage)
                + amountWei*(assetPrice - rate)/(BTC_UNIT_FACTOR);
            newLockedBalance = lockedBalance - abs(amountWei*assetPrice/(leverage));
            newAssetPrice = assetPrice;
        }
        
        require(newAvailableBalance >= 0, 'DexilonTest: Insufficient balance!');
        require(newLockedBalance >= 0, 'DexilonTest: newLockedBalance < 0');
        
        usersAvailableBalances[user] = uint256(newAvailableBalance);
        usersAssetsData[user][asset].assetLockedBalance = uint256(newLockedBalance);
        
        usersAssetsData[user][asset].assetPrice = uint256(newAssetPrice);
        usersAssetsData[user][asset].assetBalance = assetBalance + amountWei;
    }

    /**
    * @dev update available balance and asset locked balance for new leverage
    * @param user user address whose balances are updated
    * @param asset string id of the supported asset ('BTC','ETH','XRP','SOL')
    * @param assetLeverage asset position new leverage
    **/
    function updateUserLeverage(
        address user,
        string memory asset,
        uint16 assetLeverage
    ) internal {

        int newAvailableBalance;  
        int newLockedBalance;
                
        require(assetLeverage > 0, 'DexilonTest: Zero Leverage!');

        if (usersAssetsData[user][asset].assetLockedBalance == 0) {
            usersAssetsData[user][asset].assetLeverage = assetLeverage;
        }

        if (usersAssetsData[user][asset].assetLeverage != assetLeverage){

            newLockedBalance = ((int(usersAssetsData[user][asset].assetPrice) 
                * abs(int(usersAssetsData[user][asset].assetBalance))) / int(uint256(assetLeverage))) / BTC_UNIT_FACTOR;
            newAvailableBalance = int(usersAvailableBalances[user]) 
                - (newLockedBalance - int(usersAssetsData[user][asset].assetLockedBalance));

            require(newAvailableBalance >= 0, 'DexilonTest: Insufficient balance!'); 

            usersAvailableBalances[user] = uint256(newAvailableBalance);
            usersAssetsData[user][asset].assetLockedBalance = uint256(newLockedBalance);
            usersAssetsData[user][asset].assetLeverage = assetLeverage;
        }
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

}
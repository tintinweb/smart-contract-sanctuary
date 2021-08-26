// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/SafeERC20.sol";
import "./interfaces/iERC20.sol";
import "./interfaces/iGovernorAlpha.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iRESERVE.sol";
import "./interfaces/iPOOLS.sol";
import "./interfaces/iSYNTH.sol";
import "./interfaces/iFACTORY.sol";

contract Router {
    using SafeERC20 for ExternalERC20;

    // Parameters
    uint256 private constant one = 10**18;
    uint256 public rewardReductionFactor;
    uint256 public timeForFullProtection;

    uint256 public curatedPoolLimit;
    uint256 public curatedPoolCount;
    mapping(address => bool) private _isCurated;

    address public VADER;

    uint256 public anchorLimit;
    uint256 public insidePriceLimit;
    uint256 public outsidePriceLimit;
    address[] public arrayAnchors;
    uint256[] public arrayPrices;
    mapping(address => uint) public mapAnchorAddress_arrayAnchorsIndex1; // 1-based indexes

    uint256 public intervalTWAP;
    uint256 public accumulatedPrice;
    uint256 public lastUpdatedTime;
    uint256 public startIntervalAccumulatedPrice;
    uint256 public startIntervalTime;
    uint256 public cachedIntervalAccumulatedPrice;
    uint256 public cachedIntervalTime;

    mapping(address => mapping(address => uint256)) public mapMemberToken_depositBase;
    mapping(address => mapping(address => uint256)) public mapMemberToken_depositToken;
    mapping(address => mapping(address => uint256)) public mapMemberToken_lastDeposited;

    event PoolReward(address indexed base, address indexed token, uint256 amount);
    event Curated(address indexed curator, address indexed token);

    // Only TIMELOCK can execute
    modifier onlyTIMELOCK() {
        require(msg.sender == TIMELOCK(), "!TIMELOCK");
        _;
    }

    //=====================================CREATION=========================================//

    constructor(address _vader) {
        VADER = _vader;
        rewardReductionFactor = 1;
        timeForFullProtection = 1; //8640000; //100 days
        curatedPoolLimit = 1;
        intervalTWAP = 3; //6hours
        
        anchorLimit = 5;
        insidePriceLimit = 200;
        outsidePriceLimit = 500;
        
        lastUpdatedTime = block.timestamp;
        startIntervalTime = lastUpdatedTime;
        cachedIntervalTime = startIntervalTime;
    }

    //====================================== TIMELOCK =====================================//
    // Can set params
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external onlyTIMELOCK {
        rewardReductionFactor = newFactor;
        timeForFullProtection = newTime;
        curatedPoolLimit = newLimit;
        intervalTWAP = newInterval;
    }

    function setAnchorParams(
        uint256 newLimit,
        uint256 newInside,
        uint256 newOutside
    ) external onlyTIMELOCK {
        anchorLimit = newLimit;
        insidePriceLimit = newInside;
        outsidePriceLimit = newOutside;
    }

    //====================================LIQUIDITY=========================================//

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256) {
        iRESERVE(RESERVE()).checkReserve();
        uint256 _actualInputBase = moveTokenToPools(base, inputBase);
        uint256 _actualInputToken = moveTokenToPools(token, inputToken);
        address _member = msg.sender;
        addDepositData(_member, token, _actualInputBase, _actualInputToken);
        updateTWAPPrice();
        return iPOOLS(POOLS()).addLiquidity(base, _actualInputBase, token, _actualInputToken, _member);
    }

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken) {
        address _member = msg.sender;
        uint256 _protection = getILProtection(_member, base, token, basisPoints);
        if (_protection > 0) {
            uint256 _actualInputBase = iRESERVE(RESERVE()).requestFunds(base, POOLS(), _protection);
            iPOOLS(POOLS()).addLiquidity(base, _actualInputBase, token, 0, _member);
            mapMemberToken_depositBase[_member][token] += _protection;
        }
        (units, amountBase, amountToken) = iPOOLS(POOLS()).removeLiquidity(base, token, basisPoints, _member);
        removeDepositData(_member, token, basisPoints, _protection);
        iRESERVE(RESERVE()).checkReserve();
    }

    //=======================================SWAP===========================================//

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount) {
        return swapWithSynthsWithLimit(inputAmount, inputToken, false, outputToken, false, 10000);
    }

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount) {
        return swapWithSynthsWithLimit(inputAmount, inputToken, false, outputToken, false, slipLimit);
    }

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount) {
        return swapWithSynthsWithLimit(inputAmount, inputToken, inSynth, outputToken, outSynth, 10000);
    }

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) public returns (uint256 outputAmount) {
        updateTWAPPrice();
        address _member = msg.sender;
        uint256 movedAmount;
        if (!inSynth) {
            movedAmount = moveTokenToPools(inputToken, inputAmount);
        } else {
            movedAmount = moveTokenToPools(iPOOLS(POOLS()).getSynth(inputToken), inputAmount);
        }
        address _base;
        if (iPOOLS(POOLS()).isAnchor(inputToken) || iPOOLS(POOLS()).isAnchor(outputToken)) {
            _base = VADER;
        } else {
            _base = USDV();
        }
        if (isBase(outputToken)) {
            // Token||Synth -> BASE
            require(iUTILS(UTILS()).calcSwapSlip(movedAmount, iPOOLS(POOLS()).getTokenAmount(inputToken)) <= slipLimit, ">slipLimit");
            if (!inSynth) {
                outputAmount = iPOOLS(POOLS()).swap(_base, inputToken, movedAmount, _member, true);
            } else {
                outputAmount = iPOOLS(POOLS()).burnSynth(inputToken, _member);
            }
        } else if (isBase(inputToken)) {
            // BASE -> Token||Synth
            require(iUTILS(UTILS()).calcSwapSlip(movedAmount, iPOOLS(POOLS()).getBaseAmount(outputToken)) <= slipLimit, ">slipLimit");
            if (!outSynth) {
                outputAmount = iPOOLS(POOLS()).swap(_base, outputToken, movedAmount, _member, false);
            } else {
                outputAmount = iPOOLS(POOLS()).mintSynth(outputToken, movedAmount, _member);
            }
        } else {
            // !isBase(inputToken) && !isBase(outputToken)
            // Token||Synth -> Token||Synth
            require(iUTILS(UTILS()).calcSwapSlip(movedAmount, iPOOLS(POOLS()).getTokenAmount(inputToken)) <= slipLimit, ">slipLimit");
            uint _intermediaryAmount;
            if (!inSynth) {
                _intermediaryAmount = iPOOLS(POOLS()).swap(_base, inputToken, movedAmount, POOLS(), true);
            } else {
                _intermediaryAmount = iPOOLS(POOLS()).burnSynth(inputToken, POOLS());
            }
            require(iUTILS(UTILS()).calcSwapSlip(_intermediaryAmount, iPOOLS(POOLS()).getBaseAmount(outputToken)) <= slipLimit, ">slipLimit");
            if (!outSynth) {
                outputAmount = iPOOLS(POOLS()).swap(_base, outputToken, _intermediaryAmount, _member, false);
            } else {
                outputAmount = iPOOLS(POOLS()).mintSynth(outputToken, _intermediaryAmount, _member);
            }
        }
        _handlePoolReward(_base, inputToken);
        _handlePoolReward(_base, outputToken);
        _handleAnchorPriceUpdate(inputToken);
        _handleAnchorPriceUpdate(outputToken);
    }

    //====================================INCENTIVES========================================//

    function _handlePoolReward(address _base, address _token) internal {
        if (!isBase(_token)) {
            // USDV or VADER is never a pool
            uint256 _reward = iUTILS(UTILS()).getRewardShare(_token, rewardReductionFactor);
            uint256 _actualInputBase = iRESERVE(RESERVE()).requestFunds(_base, POOLS(), _reward);
            iPOOLS(POOLS()).sync(_base, _actualInputBase, _token);
            emit PoolReward(_base, _token, _reward);
        }
    }

    //=================================IMPERMANENT LOSS=====================================//

    function addDepositData(
        address member,
        address token,
        uint256 amountBase,
        uint256 amountToken
    ) internal {
        mapMemberToken_depositBase[member][token] += amountBase;
        mapMemberToken_depositToken[member][token] += amountToken;
        mapMemberToken_lastDeposited[member][token] = block.timestamp;
    }

    function removeDepositData(
        address member,
        address token,
        uint256 basisPoints,
        uint256 protection
    ) internal {
        mapMemberToken_depositBase[member][token] += protection;
        uint256 _baseToRemove = iUTILS(UTILS()).calcPart(basisPoints, mapMemberToken_depositBase[member][token]);
        uint256 _tokenToRemove = iUTILS(UTILS()).calcPart(basisPoints, mapMemberToken_depositToken[member][token]);
        mapMemberToken_depositBase[member][token] -= _baseToRemove;
        mapMemberToken_depositToken[member][token] -= _tokenToRemove;
    }

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) public view returns (uint256 protection) {
        protection = iUTILS(UTILS()).getProtection(member, token, basisPoints, timeForFullProtection);
        if (base == VADER) {
            if (protection >= reserveVADER()) {
                protection = reserveVADER(); // In case reserve is running out
            }
        } else {
            if (protection >= reserveUSDV()) {
                protection = reserveUSDV(); // In case reserve is running out
            }
        }
    }

    //=====================================CURATION==========================================//

    function curatePool(address token) external onlyTIMELOCK {
        require(iPOOLS(POOLS()).isAsset(token) || iPOOLS(POOLS()).isAnchor(token), "!Asset && !Anchor");
        if (!isCurated(token)) {
            if (curatedPoolCount < curatedPoolLimit) {
                // Limit
                _isCurated[token] = true;
                curatedPoolCount += 1;
            }
        }
        emit Curated(msg.sender, token);
    }

    function replacePool(address oldToken, address newToken) external onlyTIMELOCK {
        require(iPOOLS(POOLS()).isAsset(newToken) || iPOOLS(POOLS()).isAnchor(newToken));
        _isCurated[oldToken] = false;
        _isCurated[newToken] = true;
        emit Curated(msg.sender, newToken);
    }

    //=====================================ANCHORS==========================================//

    function listAnchor(address token) external {
        require(arrayAnchors.length < anchorLimit, ">=Limit"); // Limit
        require(iPOOLS(POOLS()).isAnchor(token), "!Anchor"); // Must be anchor
        require(!iFACTORY(FACTORY()).isSynth(token), "Synth!"); // Must not be synth
        arrayAnchors.push(token); // Add
        mapAnchorAddress_arrayAnchorsIndex1[token] = arrayAnchors.length; // Store 1-based index
        arrayPrices.push(iUTILS(UTILS()).calcValueInBase(token, one));
        _isCurated[token] = true;
        updateAnchorPrice(token);
    }

    function replaceAnchor(address oldToken, address newToken) external onlyTIMELOCK {
        require(newToken != oldToken, "New token not new");
        uint idx1 = mapAnchorAddress_arrayAnchorsIndex1[oldToken];
        require(idx1 != 0, "No such old token");
        require(iPOOLS(POOLS()).isAnchor(newToken), "!Anchor"); // Must be anchor
        require(!iFACTORY(FACTORY()).isSynth(newToken), "Synth!"); // Must not be synth
        iUTILS(UTILS()).requirePriceBounds(newToken, insidePriceLimit, true, getAnchorPrice()); // if price newToken <2%
        _isCurated[oldToken] = false;
        _isCurated[newToken] = true;
        arrayAnchors[idx1 - 1] = newToken;
        updateAnchorPrice(newToken);
    }

    function _handleAnchorPriceUpdate(address _token) internal {
        if (iPOOLS(POOLS()).isAnchor(_token)) {
            updateAnchorPrice(_token);
        }
    }

    // Anyone to update prices
    function updateAnchorPrice(address token) public {
        uint idx1 = mapAnchorAddress_arrayAnchorsIndex1[token];
        if (idx1 != 0) {
            arrayPrices[idx1 - 1] = iUTILS(UTILS()).calcValueInBase(token, one);
        }
    }

    function updateTWAPPrice() public {
        uint _now = block.timestamp;
        uint _secondsSinceLastUpdate = _now - lastUpdatedTime;
        accumulatedPrice += _secondsSinceLastUpdate * getAnchorPrice();
        lastUpdatedTime = _now;
        if ((_now - cachedIntervalTime) > intervalTWAP) {
            // More than the interval, update interval params
            startIntervalAccumulatedPrice = cachedIntervalAccumulatedPrice; // update price from cache
            startIntervalTime = cachedIntervalTime; // update time from cache
            cachedIntervalAccumulatedPrice = accumulatedPrice; // reset cache
            cachedIntervalTime = _now; // reset cache
        }
    }

    // Price of 1 VADER in USD
    function getAnchorPrice() public view returns (uint256 anchorPrice) {
        // if array len odd  3/2 = 1; 5/2 = 2
        // if array len even 2/2 = 1; 4/2 = 2
        uint _anchorMiddle = arrayPrices.length / 2;
        uint256[] memory _sortedAnchorFeed = iUTILS(UTILS()).sortArray(arrayPrices); // Sort price array, no need to modify storage
        if (arrayPrices.length == 0) {
            anchorPrice = one; // Edge case for first USDV mint
        } else if (arrayPrices.length & 0x1 == 0x1) {
            // arrayPrices.length is odd
            anchorPrice = _sortedAnchorFeed[_anchorMiddle]; // Return the middle
        } else {
            // arrayPrices.length is even
            anchorPrice = (_sortedAnchorFeed[_anchorMiddle] / 2) + (_sortedAnchorFeed[_anchorMiddle - 1] / 2); // Return the average of middle pair
        }
    }

    // TWAP Price of 1 VADER in USD
    function getTWAPPrice() public view returns (uint256) {
        if (arrayPrices.length == 0) {
            return one; // Edge case for first USDV mint
        }
        return (accumulatedPrice - startIntervalAccumulatedPrice) / (block.timestamp - startIntervalTime);
    }

    // The correct amount of Vader for an input of USDV
    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount) {
        uint256 _price = getTWAPPrice();
        return (_price * USDVAmount) / one;
    }

    // The correct amount of USDV for an input of VADER
    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount) {
        uint256 _price = getTWAPPrice();
        return (vaderAmount * one) / _price;
    }

    //======================================ASSETS=========================================//

    // Move funds in
    function moveTokenToPools(address _token, uint256 _amount) internal returns (uint256 safeAmount) {
        if (isBase(_token) || iPOOLS(POOLS()).isSynth(_token)) {
            safeAmount = _amount;
            iERC20(_token).transferFrom(msg.sender, POOLS(), _amount); // safeErc20 not needed; bases and synths trusted
        } else {
            uint256 _startBal = ExternalERC20(_token).balanceOf(POOLS());
            ExternalERC20(_token).safeTransferFrom(msg.sender, POOLS(), _amount);
            safeAmount = ExternalERC20(_token).balanceOf(POOLS()) - _startBal;
        }
    }

    // Get Collateral
    function _handleTransferIn(
        address _member,
        address _collateralAsset,
        uint256 _amount
    ) internal returns (uint256 _inputAmount) {
        if (isBase(_collateralAsset) || iPOOLS(POOLS()).isSynth(_collateralAsset)) {
            _inputAmount = _getFunds(_collateralAsset, _amount); // Get funds
        } else if (isPool(_collateralAsset)) {
            iPOOLS(POOLS()).lockUnits(_amount, _collateralAsset, _member); // Lock units to protocol
            _inputAmount = _amount;
        }
    }

    // Send Collateral
    function _handleTransferOut(
        address _member,
        address _collateralAsset,
        uint256 _amount
    ) internal {
        if (isBase(_collateralAsset) || iPOOLS(POOLS()).isSynth(_collateralAsset)) {
            _sendFunds(_collateralAsset, _member, _amount); // Send Base
        } else if (isPool(_collateralAsset)) {
            iPOOLS(POOLS()).unlockUnits(_amount, _collateralAsset, _member); // Unlock units to member
        }
    }

    // @dev Assumes `_token` is trusted (is a base asset or synth) and supports
    function _getFunds(address _token, uint256 _amount) internal returns (uint256) {
        uint256 _balance = iERC20(_token).balanceOf(address(this));
        require(iERC20(_token).transferFrom(msg.sender, address(this), _amount), "!Transfer"); // safeErc20 not needed; _token trusted
        return iERC20(_token).balanceOf(address(this)) - _balance;
    }

    // @dev Assumes `_token` is trusted (is a base asset or synth)
    function _sendFunds(
        address _token,
        address _member,
        uint256 _amount
    ) internal {
        require(iERC20(_token).transfer(_member, _amount), "!Transfer"); // safeErc20 not needed; _token trusted
    }

    //======================================HELPERS=========================================//

    function updateVADER(address newAddress) external {
        require(msg.sender == GovernorAlpha(), "!VADER");
        VADER = newAddress;
    }

    function isBase(address token) public view returns (bool base) {
        return token == VADER || token == USDV();
    }

    function reserveUSDV() public view returns (uint256) {
        return iRESERVE(RESERVE()).reserveUSDV(); // Balance
    }

    function reserveVADER() public view returns (uint256) {
        return iRESERVE(RESERVE()).reserveVADER(); // Balance
    }

    function emitting() public view returns (bool) {
        return iVADER(VADER).emitting();
    }

    function isCurated(address token) public view returns (bool) {
        return _isCurated[token];
    }

    function isPool(address token) public view returns (bool) {
        return iPOOLS(POOLS()).isAnchor(token) || iPOOLS(POOLS()).isAsset(token);
    }

    function getMemberBaseDeposit(address member, address token) external view returns (uint256) {
        return mapMemberToken_depositBase[member][token];
    }

    function getMemberTokenDeposit(address member, address token) external view returns (uint256) {
        return mapMemberToken_depositToken[member][token];
    }

    function getMemberLastDeposit(address member, address token) external view returns (uint256) {
        return mapMemberToken_lastDeposited[member][token];
    }

    //============================== HELPERS ================================//

    function GovernorAlpha() internal view returns (address) {
        return iVADER(VADER).GovernorAlpha();
    }

    function USDV() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).USDV();
    }

    function RESERVE() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).RESERVE();
    }

    function POOLS() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).POOLS();
    }

    function FACTORY() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).FACTORY();
    }

    function UTILS() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).UTILS();
    }

    function TIMELOCK() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).TIMELOCK();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.1.0
//
// NOTE: All references to the standard `IERC20` type have been renamed to `ExternalERC20`
//

pragma solidity 0.8.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ExternalERC20 {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
 * To use this library you can add a `using SafeERC20 for ExternalERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(ExternalERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ExternalERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {ExternalERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ExternalERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ExternalERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ExternalERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(ExternalERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iGovernorAlpha {
    function updateVADER(address newAddress) external;
    function VETHER() external view returns(address);
    function VADER() external view returns(address);
    function USDV() external view returns(address);
    function RESERVE() external view returns(address);
    function VAULT() external view returns(address);
    function ROUTER() external view returns(address);
    function LENDER() external view returns(address);
    function POOLS() external view returns(address);
    function FACTORY() external view returns(address);
    function UTILS() external view returns(address);
    function TIMELOCK() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function updateVADER(address newAddress) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getMemberShare(uint256 basisPoints, address token, address member) external view returns(uint256 units, uint256 outputBase, uint256 outputToken);

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {

    function GovernorAlpha() external view returns (address);

    function Admin() external view returns (address);

    function UTILS() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function era() external view returns(uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newSeconds, uint256 newCurve, uint256 newTailEmissionEra) external;

    function setReserve(address newReserve) external;

    function changeUTILS(address newUTILS) external;

    function changeGovernorAlpha(address newGovernorAlpha) external;

    function purgeGovernorAlpha() external;

    function upgrade(uint256 amount) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeemToVADER(uint256 amount) external returns (uint256);

    function redeemToVADERForMember(address member, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iRESERVE {
    function setParams(uint256 newSplit, uint256 newDelay, uint256 newShare) external;

    function grant(address recipient, uint256 amount) external;

    function requestFunds(address base, address recipient, uint256 amount) external returns(uint256);

    function requestFundsStrict(address base, address recipient, uint256 amount) external returns(uint256);

    function updateVADER(address newAddress) external;

    function checkReserve() external;

    function getVaultReward() external view returns(uint256);

    function reserveVADER() external view returns (uint256);

    function reserveUSDV() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iPOOLS {
    function pooledVADER() external view returns (uint256);

    function pooledUSDV() external view returns (uint256);

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken,
        address member
    ) external returns (uint256 liquidityUnits);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints,
        address member
    ) external returns (uint256 units, uint256 outputBase, uint256 outputToken);

    function sync(address token, uint256 inputToken, address pool) external;

    function swap(
        address base,
        address token,
        uint256 inputToken,
        address member,
        bool toBase
    ) external returns (uint256 outputAmount);

    function deploySynth(address token) external;

    function mintSynth(
        address token,
        uint256 inputBase,
        address member
    ) external returns (uint256 outputAmount);

    function burnSynth(
        address token,
        address member
    ) external returns (uint256 outputBase);

    function syncSynth(address token) external;

    function lockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function unlockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function updateVADER(address newAddress) external;

    function isAsset(address token) external view returns (bool);

    function isAnchor(address token) external view returns (bool);

    function getPoolAmounts(address token) external view returns (uint256, uint256);

    function getBaseAmount(address token) external view returns (uint256);

    function getTokenAmount(address token) external view returns (uint256);

    function getUnits(address token) external view returns (uint256);

    function getMemberUnits(address token, address member) external view returns (uint256);

    function getSynth(address token) external returns (address);

    function isSynth(address token) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iSYNTH {
    function mint(address account, uint256 amount) external;

    function TOKEN() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iFACTORY {
    function deploySynth(address) external returns (address);

    function mintSynth(
        address,
        address,
        uint256
    ) external returns (bool);

    function getSynth(address) external view returns (address);

    function isSynth(address) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
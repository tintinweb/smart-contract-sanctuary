// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./EnumerableMap.sol";
import "./IMaterials.sol";
import "./ReentrancyGuard.sol";


// standard interface of IERC20 token
// using this in this contract to receive Bino token by "transferFrom" method
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


contract BrickFactoryPublic is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct FactoryAttributes {
        uint256 processLimit;
        uint256 baseSuccessRate;     // decimals: 1e4
        uint256 singleProcessPeriod; // uint: seconds
        uint256 singleProcessPrice;  // in Bino's decimal, 1e18
        uint256 productionLineLimit;
        uint256 updateMaterialNeeded;
    }

    struct LineDetail {
        address lineUser;
        uint256 basicMaterialId;
        uint256 advanceMaterialId;
        uint256 amount;
        uint256 finishTime;
        uint256 stealTime;
    }

    IERC20 public binoAddress;
    IMaterials public materialsAddress;
    // current wokers number, with the first value being 1. An id of 0 is invalid.
    uint256 public constant PROTECTION_PERIOD = 5 minutes;
    uint256 public basicMaterialId;
    uint256 public advanceMaterialId;
    // the current factory's level
    uint256 public currentLevel;
    // FactoryLevel => FactoryAttributes
    mapping(uint256 => FactoryAttributes) private _currentAttributes;
    // key : value = lineId : currentUserAddress
    EnumerableMap.UintToAddressMap private _linesUsage;
    // lineId => production complte time of this lineId
    mapping(uint256 => uint256) private _completeTime;
    // lineId => processed basic material amounts of this lineId
    mapping(uint256 => uint256) private _processAmounts;
    // lineId => LineDetail
    mapping(uint256 => LineDetail) private _lineDetail;

    event StartProcess(uint256 indexed lineId, address indexed account, uint256 indexed completeTime, uint256 amount);
    event ClaimUpgratedMaterial(uint256 indexed lineId, address indexed account, uint256 indexed amount);
    

    constructor () public {
        // fill in those deployed contract addresses
        setBinoAddress(0xf8Ca318db090124E1468CC6c77f69Fd7eb78685a);
        setMaterialsAddress(0x04898c211e112e558def9f28B22640Ef814f56e6);
        // set the material Id for "clay", which is 1
        basicMaterialId = 1;
        // set the material Id for "brick", which is 6
        advanceMaterialId = 6;
        // set the initial level, which is level 1
        currentLevel = 3;
        // set the FactoryAttributes for each level;
        _setFactoryAttributes();
        
    }

    function setBinoAddress(address newAddress) public onlyOwner {
        binoAddress = IERC20(newAddress);
    }

    function setMaterialsAddress(address newAddress) public onlyOwner {
        materialsAddress = IMaterials(newAddress);
    }

    function setProductionLineLimit(uint256 level, uint256 newLineLimit) public onlyOwner {
        require(level > 0 && level <=6, "input level is out of range of [1, 6]");
        _currentAttributes[level].productionLineLimit = newLineLimit;
    }

    function withdrawBino(address account, uint256 amount) public onlyOwner {
        require(amount <= binoAddress.balanceOf(address(this)), "withdraw amount > bino balance in this contract");
        binoAddress.safeTransfer(account, amount);
    }

    function checkCurrentFactoryAttributes(uint256 level) public view returns (FactoryAttributes memory) {
        require(level > 0 && level <=6, "input level is out of range of [1, 6]");
        return _currentAttributes[level];
    }

    function checkCurrentProcessLimit(uint256 level) public view returns (uint256) {
        require(level > 0 && level <=6, "input level is out of range of [1, 6]");
        return _currentAttributes[level].processLimit;
    }

    function checkCurrentProductionLineLimit(uint256 level) public view returns (uint256) {
        require(level > 0 && level <=6, "input level is out of range of [1, 6]");
        return _currentAttributes[level].productionLineLimit;
    }

    function isReadyToClaim(uint256 lineId) public view returns (bool) {
        require(_linesUsage.contains(lineId), "can not claim from non-using lineId");
        uint256 finishTime = _completeTime[lineId];
        return block.timestamp >= finishTime ? true : false;
    }

    function checkLineDetail(uint256 lineId) public view returns (LineDetail memory) {
        return _lineDetail[lineId];
    }


    // 1. call "approve" method to set this contract as the operator of the _msgSender()
    // BEFORE call this method
    // 2. call "setApproveForAll" method to set this contract as the operator of the _msgSender()
    // BEFORE calling this method
    function startProcess(uint256 lineId, uint256 amount) public nonReentrant {
        require(lineId != 0, "can not process line #0");
        require(amount != 0, "can not process 0 amount");
        FactoryAttributes storage thisLevelAttributes = _currentAttributes[currentLevel];
        require(thisLevelAttributes.productionLineLimit >= lineId, "exceed production line limit");
        require(thisLevelAttributes.processLimit >= amount, "exceed process limit");
        // check if this lineId is available
        require(!_linesUsage.contains(lineId), "this line is used by others now, try later");

        // set new time, amounts, and process user
        uint256 totalTime = amount.mul(thisLevelAttributes.singleProcessPeriod).div(100);  // 0.0x second for single material
        uint256 finishTime = block.timestamp.add(totalTime);
        uint256 stealTime = finishTime.add(PROTECTION_PERIOD);
        _linesUsage.set(lineId, _msgSender());
        _completeTime[lineId] = finishTime;
        _processAmounts[lineId] = amount;

        _lineDetail[lineId] = LineDetail({
            lineUser: _msgSender(), 
            basicMaterialId: basicMaterialId,
            advanceMaterialId: advanceMaterialId,
            amount: amount, 
            finishTime: finishTime,
            stealTime: stealTime
        });

        // pay Bino fee, and burn basic materials to start upgrating
        uint256 totalBinoFee = amount.mul(thisLevelAttributes.singleProcessPrice);  // in Bino's decimals: 1e18
        binoAddress.safeTransferFrom(_msgSender(), address(this), totalBinoFee);
        materialsAddress.burn(_msgSender(), basicMaterialId, amount);

        emit StartProcess(lineId, _msgSender(), finishTime, amount);
    }

    /**
     * @dev this method allows every user to call, and share 10% amounts of
     *      upgrated material after the 5 mins protection period
     */
    function claimUpgratedMaterial(uint256 lineId) public nonReentrant {
        require(lineId != 0, "can not process line #0");
        FactoryAttributes storage thisLevelAttributes = _currentAttributes[currentLevel];
        require(thisLevelAttributes.productionLineLimit >= lineId, "exceed production line limit");
        require(isReadyToClaim(lineId), "not ready to claim now, try later");
        
        address lineOwner = _linesUsage.get(lineId);
        uint256 finishTime = _completeTime[lineId];
        uint256 processAmount = _processAmounts[lineId];
        uint256 upgratedAmount;
        if (_msgSender() == lineOwner) {
            uint256 baseRate = thisLevelAttributes.baseSuccessRate;
            uint256 claimRate = _getRandomSuccessRate(baseRate);
            require(claimRate <= 10000, "claimRate exceed 100%");
            upgratedAmount = processAmount.mul(claimRate).div(10000);

            materialsAddress.mint(lineOwner, advanceMaterialId, upgratedAmount, "");
        } else {
            require(block.timestamp > finishTime.add(PROTECTION_PERIOD), "can not claim within protection time");
            uint256 baseRate = thisLevelAttributes.baseSuccessRate;
            uint256 claimRate = _getRandomSuccessRate(baseRate);
            require(claimRate <= 10000, "claimRate exceed 100%");
            upgratedAmount = processAmount.mul(claimRate).div(10000);
            uint256 shareAmount = upgratedAmount.div(10);              // 10%
            uint256 ownerAmount = upgratedAmount.sub(shareAmount);     // 90%

            materialsAddress.mint(lineOwner, advanceMaterialId, ownerAmount, "");
            materialsAddress.mint(_msgSender(), advanceMaterialId, shareAmount, "");
        }
        // remove and set to 0
        _linesUsage.remove(lineId);
        _completeTime[lineId] = 0;
        _processAmounts[lineId] = 0;

        _lineDetail[lineId] = LineDetail({
            lineUser: address(0), 
            basicMaterialId: basicMaterialId,
            advanceMaterialId: advanceMaterialId,
            amount: 0, 
            finishTime: 0,
            stealTime: 0
        });

        emit ClaimUpgratedMaterial(lineId, lineOwner, upgratedAmount);
    }

    function _setFactoryAttributes() private {
        _currentAttributes[3] = FactoryAttributes({
                                                    processLimit: 5000,
                                                    baseSuccessRate: 5000,
                                                    singleProcessPeriod: 6 seconds,
                                                    singleProcessPrice: 100 * 1e12,
                                                    productionLineLimit: 2,
                                                    updateMaterialNeeded: 0
                                                });
    }

    // generate a random integer between 0.9*base to 1.1*base (upperBound can not exceed 10000)
    function _getRandomSuccessRate(uint256 base) private view returns (uint256) {
        // +/- 10%
        uint256 halfRange = base.div(10);
        uint256 lowerBound = base.sub(halfRange);
        uint256 upperBound = base.add(halfRange) >= 10000 ? 10000 : base.add(halfRange);
        // randomSeed % (upper - lower + 1) => randomInt = [0, upper - lower]
        uint256 randomInt = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(block.number.sub(1))),
                    uint256(block.coinbase),
                    block.difficulty,
                    block.timestamp,
                    base
                )
            )
        ).mod(upperBound.sub(lowerBound).add(1));
        return randomInt.add(lowerBound);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IAssetManager.sol";
import "./interfaces/erc20/IERC20Metadata.sol";

import "./libraries/SafeMathExtends.sol";
import "./storage/SmartPoolStorage.sol";
import "./base/BasicFund.sol";
pragma abicoder v2;
/// @title Fund Contract - The implmentation of fund contract
/// @notice This contract extends Basic Fund and defines the join and redeem activities
contract Fund is BasicFund {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;
    using Address for address;

    event PoolJoined(address indexed investor, uint256 amount);
    event PoolExited(address indexed investor, uint256 amount);

    /// @notice deny contract
    modifier notAllowContract() {
        require(!address(msg.sender).isContract(), "is contract ");
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) BasicFund(name, symbol){

    }

    /// @notice Bind join and redeem address with asset management contract
    /// @dev Make the accuracy of the fund consistent with the accuracy of the bound token; it can only be bound once and cannot be modified
    /// @param token Join and redeem fund token address
    /// @param am Asset managemeent address
    function bind(address token, address am) external {
        require(!SmartPoolStorage.load().bind, "already bind");
        _decimals = IERC20Metadata(token).decimals();
        SmartPoolStorage.load().token = token;
        SmartPoolStorage.load().am = am;
        SmartPoolStorage.load().bind = true;
        SmartPoolStorage.load().suspend = false;
        SmartPoolStorage.load().allowJoin = true;
        SmartPoolStorage.load().allowExit = true;
    }

    /// @notice upgrade am
    /// @param old_am old am address
    /// @param new_am new am address
    function upgrade(address old_am,address new_am) external onlyGovernance{
        IAssetManager(old_am).withdrawOfUnderlying(new_am,1e18);
        SmartPoolStorage.load().am = new_am;
    }

    /// @notice Subscript fund
    /// @dev When subscribing to the fund, fee will be collected, and contract access is not allowed
    /// @param amount Subscription amount
    function joinPool(uint256 amount) external isAllowJoin notAllowContract {
        address investor = msg.sender;
        require(amount <= ioToken().balanceOf(investor) && amount > 0, "Insufficient balance");
        uint256 fundAmount = convertToFund(amount);
        //take management fee
        takeOutstandingManagementFee();
        //take join fee
        uint256 fee = _takeJoinFee(investor, fundAmount);
        uint256 realFundAmount = fundAmount.sub(fee);
        _mint(investor, realFundAmount);
        ioToken().safeTransferFrom(investor, AM(), amount);
        emit PoolJoined(investor, realFundAmount);
    }

    /// @notice Redeem fund
    /// @dev When the fund is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool(uint256 amount) external isAllowExit notAllowContract {
        address investor = msg.sender;
        require(balanceOf(investor) >= amount && amount > 0, "Insufficient balance");
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        uint256 cashAmount = convertToCash(exitAmount);
        //take management fee
        takeOutstandingManagementFee();
        // withdraw cash
        IAssetManager(AM()).withdraw(investor, cashAmount, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Redeem the underlying assets of the fund
    /// @dev When the fund is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPoolOfUnderlying(uint256 amount) external isAllowExit notAllowContract {
        address investor = msg.sender;
        require(balanceOf(investor) >= amount && amount > 0, "Insufficient balance");
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        //take management fee
        takeOutstandingManagementFee();
        //harvest underlying
        IAssetManager(AM()).withdrawOfUnderlying(investor, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Fund token address for joining and redeeming
    /// @dev This is address is created when the fund is first created.
    /// @return Fund token address
    function ioToken() public view returns (IERC20){
        return IERC20(SmartPoolStorage.load().token);
    }

    /// @notice Fund mangement contract address
    /// @dev The fund management contract address is bind to the fund when the fund is created
    /// @return Fund management contract address
    function AM() public view returns (address){
        return SmartPoolStorage.load().am;
    }


    /// @notice Convert fund amount to cash amount
    /// @dev This converts the user fund amount to cash amount when a user redeems the fund
    /// @param fundAmount Redeem fund amount
    /// @return Cash amount
    function convertToCash(uint256 fundAmount) public virtual override view returns (uint256){
        uint256 cash = 0;
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            cash = 0;
        } else {
            cash = _assets.mul(fundAmount).div(totalSupply);
        }
        return cash;
    }

    /// @notice Convert cash amount to fund amount
    /// @dev This converts cash amount to fund amount when a user buys the fund
    /// @param cashAmount Join cash amount
    /// @return Fund amount
    function convertToFund(uint256 cashAmount) public virtual override view returns (uint256){
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            return cashAmount;
        } else {
            return cashAmount.mul(totalSupply).div(_assets);
        }
    }

    /// @notice Fund total asset
    /// @dev This calculates fund net worth or AUM
    /// @return Fund total asset
    function assets() public view returns (uint256){
        return IAssetManager(AM()).assets();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./GovIdentity.sol";
import "../storage/SmartPoolStorage.sol";
import "./StandardERC20.sol";
pragma abicoder v2;
/// @title Basic Fund - Abstract Fund definition
/// @notice This contract extends ERC20, defines basic fund functions and rewrites ERC20 transferFrom function
abstract contract BasicFund is StandardERC20, GovIdentity {

    using SafeMath for uint256;

    event CapChanged(address indexed setter, uint256 oldCap, uint256 newCap);
    event TakeFee(SmartPoolStorage.FeeType ft, address owner, uint256 fee);
    event FeeChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator, uint256 newRatio, uint256 newDenominator);

    constructor(
        string memory name_,
        string memory symbol_
    )StandardERC20(name_, symbol_) {
        super._init();
    }

    /// @notice restricted fund issuance
    modifier withinCap() {
        _;
        uint256 cap = SmartPoolStorage.load().cap;
        bool check = cap == 0 || totalSupply() <= cap ? true : false;
        require(check, "Cap limit");
    }

    /// @notice Prohibition of fund circulation
    modifier deny() {
        require(!SmartPoolStorage.load().suspend, "suspend");
        _;
    }

    /// @notice is allow join
    modifier isAllowJoin() {
        require(checkAllowJoin(), "not allowJoin");
        _;
    }

    /// @notice is allow exit
    modifier isAllowExit() {
        require(checkAllowExit(), "not allowExit");
        _;
    }

    /// @notice Check allow join
    /// @return bool
    function checkAllowJoin()public view returns(bool){
        return SmartPoolStorage.load().allowJoin;
    }

    /// @notice Check allow exit
    /// @return bool
    function checkAllowExit()public view returns(bool){
        return SmartPoolStorage.load().allowExit;
    }

    /// @notice Update weighted average net worth
    /// @dev This function is used by the new transferFrom/transfer function
    /// @param account Account address
    /// @param addAmount Newly added fund amount
    /// @param newNet New weighted average net worth
    function _updateAvgNet(address account, uint256 addAmount, uint256 newNet) internal {
        uint256 balance = balanceOf(account);
        uint256 oldNet = SmartPoolStorage.load().nets[account];
        uint256 total = balance.add(addAmount);
        if (total != 0) {
            uint256 nextNet = oldNet.mul(balance).add(newNet.mul(addAmount)).div(total);
            SmartPoolStorage.load().nets[account] = nextNet;
        }
    }


    /// @notice Overwrite transfer function
    /// @dev The purpose is to update weighted average net worth
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Transfer amount
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override deny {
        uint256 newNet = SmartPoolStorage.load().nets[sender];
        _updateAvgNet(recipient, amount, newNet);
        super._transfer(sender, recipient, amount);
        if (balanceOf(sender) == 0) {
            SmartPoolStorage.load().nets[sender] = 0;
        }
    }

    /// @notice Overwrite mint function
    /// @dev the purpose is to set the initial net worth of the fund. It also limit the max fund cap
    /// @param recipient Recipient address
    /// @param amount Mint amount
    function _mint(address recipient, uint256 amount) internal virtual override withinCap deny {
        uint256 newNet = globalNetValue();
        if (newNet == 0) newNet = 1e18;
        _updateAvgNet(recipient, amount, newNet);
        super._mint(recipient, amount);
    }

    /// @notice Overwrite burn function
    /// @dev The purpose is to set the net worth of fund to 0 when the balance of the account is 0
    /// @param account Account address
    /// @param amount Burn amount
    function _burn(address account, uint256 amount) internal virtual override deny {
        super._burn(account, amount);
        if (balanceOf(account) == 0) {
            SmartPoolStorage.load().nets[account] = 0;
        }
    }

    /// @notice Overwrite fund transferFrom function
    /// @dev The overwrite is to simplify the transaction behavior, and the authorization operation behavior can be avoided when the fund transaction payer is the function initiator
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Transfer amount
    /// @return Transfer result
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(
            _msgSender() == sender || amount <= allowance(sender, _msgSender()),
            "ERR_KTOKEN_BAD_CALLER"
        );
        _transfer(sender, recipient, amount);
        if (_msgSender() != sender) {
            _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "BasicFund: transfer amount exceeds allowance"));
        }
        return true;
    }

    /// @notice Fund cap
    /// @dev The max number of fund to be issued
    /// @return Max fund cap
    function getCap() public view returns (uint256){
        return SmartPoolStorage.load().cap;
    }

    /// @notice Set max fund cap
    /// @dev To set max fund cap
    /// @param cap Max fund cap
    function setCap(uint256 cap) external onlyStrategistOrGovernance() {
        uint256 oldCap = SmartPoolStorage.load().cap;
        SmartPoolStorage.load().cap = cap;
        emit CapChanged(msg.sender, oldCap, cap);
    }

    /// @notice The net worth of the fund from the time the last fee collected
    /// @dev This is used to calculate the performance fee
    /// @param account Account address
    /// @return The net worth of the fund
    function accountNetValue(address account) public view returns (uint256){
        return SmartPoolStorage.load().nets[account];
    }

    /// @notice The current fund net worth
    /// @dev This is used to update and calculate account net worth
    /// @return The net worth of the fund
    function globalNetValue() public view returns (uint256){
        return convertToCash(1e18);
    }

    /// @notice Get fee by type
    /// @dev (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE)
    /// @param ft Fee type
    function getFee(SmartPoolStorage.FeeType ft) public view returns (SmartPoolStorage.Fee memory){
        return SmartPoolStorage.load().fees[ft];
    }

    /// @notice Set fee by type
    /// @dev Only Governance address can set fees (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE)
    /// @param ft Fee type
    /// @param ratio Fee ratio
    /// @param denominator The max ratio limit
    /// @param minLine The minimum line to charge a fee
    function setFee(SmartPoolStorage.FeeType ft, uint256 ratio, uint256 denominator, uint256 minLine) external onlyGovernance {
        require(ratio <= denominator, "ratio<=denominator");
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[ft];
        require(fee.denominator == 0, "already initialized ");
        emit FeeChanged(msg.sender, fee.ratio, fee.denominator, ratio, denominator);
        fee.ratio = ratio;
        fee.denominator = denominator;
        fee.minLine = minLine;
        fee.lastTimestamp = block.timestamp;
    }

    /// @notice Collect outstanding management fee
    /// @dev The outstanding management fee is calculated from the time the last fee is collected.
    function takeOutstandingManagementFee() public returns (uint256){
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[SmartPoolStorage.FeeType.MANAGEMENT_FEE];
        uint256 outstandingFee = calcManagementFee();
        if (outstandingFee == 0 || outstandingFee < fee.minLine) return 0;
        _mint(getRewards(), outstandingFee);
        fee.lastTimestamp = block.timestamp;
        emit TakeFee(SmartPoolStorage.FeeType.MANAGEMENT_FEE, address(0), outstandingFee);
        return outstandingFee;
    }

    /// @notice Collect performance fee
    /// @dev Performance fee is calculated by each address. The new net worth of the address is updated each time the performance is collected.
    /// @param target Account address to collect performance fee
    function takeOutstandingPerformanceFee(address target) public returns (uint256){
        if (target == getRewards()) return 0;
        uint256 netValue = globalNetValue();
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[SmartPoolStorage.FeeType.PERFORMANCE_FEE];
        uint256 outstandingFee = calcPerformanceFee(target, netValue);
        if (outstandingFee == 0 || outstandingFee < fee.minLine) return 0;
        _transfer(target, getRewards(), outstandingFee);
        fee.lastTimestamp = block.timestamp;
        SmartPoolStorage.load().nets[target] = netValue;
        emit TakeFee(SmartPoolStorage.FeeType.PERFORMANCE_FEE, target, outstandingFee);
        return outstandingFee;
    }

    /// @notice Collect Join fee
    /// @dev The join fee is collected each time a user buys the fund
    /// @param target Account address to collect join fee
    /// @param fundAmount Fund amount
    function _takeJoinFee(address target, uint256 fundAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.JOIN_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.JOIN_FEE, fundAmount);
        if (payFee == 0 || payFee < fee.minLine) return 0;
        _mint(getRewards(), payFee);
        emit TakeFee(SmartPoolStorage.FeeType.JOIN_FEE, target, payFee);
        return payFee;
    }

    /// @notice Collect Redeem fee
    /// @dev The redeem fee is collected when a user redeems the fund
    /// @param target Account address to collect redeem fee
    /// @param fundAmount Fund amount
    function _takeExitFee(address target, uint256 fundAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.EXIT_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.EXIT_FEE, fundAmount);
        if (payFee == 0 || payFee < fee.minLine) return 0;
        _transfer(target, getRewards(), payFee);
        emit TakeFee(SmartPoolStorage.FeeType.EXIT_FEE, target, payFee);
        return payFee;
    }

    /// @notice Calculate management fee
    /// @dev Outstanding management fee is calculated from the time the last fee is collected.
    function calcManagementFee() public view returns (uint256){
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.MANAGEMENT_FEE);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        if (fee.lastTimestamp == 0) return 0;
        uint256 diff = block.timestamp.sub(fee.lastTimestamp);
        return totalSupply().mul(diff).mul(fee.ratio).div(denominator * 365.25 days);
    }

    /// @notice Calculate performance fee
    /// @dev Performance fee is calculated by each address. The new net worth line of the address is updated each time the performance is collected.
    /// @param target Account address to collect performance fee
    /// @param newNet New net worth
    function calcPerformanceFee(address target, uint256 newNet) public view returns (uint256){
        if (newNet == 0) return 0;
        uint256 balance = balanceOf(target);
        uint256 oldNet = accountNetValue(target);
        uint256 diff = newNet > oldNet ? newNet.sub(oldNet) : 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.PERFORMANCE_FEE);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        uint256 cash = diff.mul(balance).mul(fee.ratio).div(denominator);
        return cash.div(newNet);
    }

    /// @notice Calculate the fee by ratio
    /// @dev This is used to calculate join and redeem fee
    /// @param ft Fee type
    /// @param fundAmount Fund amount
    function calcRatioFee(SmartPoolStorage.FeeType ft, uint256 fundAmount) public view returns (uint256){
        if (fundAmount == 0) return 0;
        SmartPoolStorage.Fee memory fee = getFee(ft);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        uint256 amountRatio = fundAmount.div(denominator);
        return amountRatio.mul(fee.ratio);
    }

    //@notice fund maintenance
    //@dev stop and open fund circulation
    /// @param _value status value
    function maintain(bool _value) external onlyStrategistOrGovernance {
        SmartPoolStorage.load().suspend = _value;
    }

    //@notice fund allowJoin
    //@dev stop and open fund circulation
    /// @param _value status value
    function allowJoin(bool _value) external onlyStrategistOrGovernance {
        SmartPoolStorage.load().allowJoin = _value;
    }

    //@notice fund allowExit
    //@dev stop and open fund circulation
    /// @param _value status value
    function allowExit(bool _value) external onlyStrategistOrGovernance {
        SmartPoolStorage.load().allowExit = _value;
    }

    /// @notice Convert fund amount to cash amount
    /// @dev This converts the user fund amount to cash amount when a user redeems the fund
    /// @param fundAmount Redeem fund amount
    /// @return Cash amount
    function convertToCash(uint256 fundAmount) public virtual view returns (uint256);

    /// @notice Convert cash amount to fund amount
    /// @dev This converts cash amount to fund amount when a user buys the fund
    /// @param cashAmount Join cash amount
    /// @return Fund amount
    function convertToFund(uint256 cashAmount) public virtual view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SmartPoolStorage {

    bytes32 public constant sSlot = keccak256("SmartPoolStorage.storage.location");

    struct Storage {
        address controller;
        uint256 cap;
        mapping(FeeType => Fee) fees;
        mapping(address => uint256) nets;
        address token;
        address am;
        bool bind;
        bool suspend;
        bool allowJoin;
        bool allowExit;
    }

    struct Fee {
        uint256 ratio;
        uint256 denominator;
        uint256 lastTimestamp;
        uint256 minLine;
    }

    enum FeeType{
        JOIN_FEE, EXIT_FEE, MANAGEMENT_FEE, PERFORMANCE_FEE
    }

    function load() internal pure returns (Storage storage s) {
        bytes32 loc = sSlot;
        assembly {
            s.slot := loc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// a library for performing various math operations

library SafeMathExtends {

    uint256 internal constant BONE = 10 ** 18;

    // Add two numbers together checking for overflows
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    // subtract two numbers and return diffecerence when it underflows
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    // Subtract two numbers checking for underflows
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    // Multiply two 18 decimals numbers
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    // Divide two 18 decimals numbers
    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
        // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");
        //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20Metadata {

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Asset Manager - The asset manager interface
/// @notice This contract is used to manage fund asset
interface IAssetManager {

    /// @notice Total asset
    /// @dev This function calculates the net worth or AUM
    /// @return Total asset
    function assets()external view returns(uint256);

    /// @notice Withdraw asset
    /// @dev Only fund contract can withdraw asset
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address to,uint256 amount,uint256 scale)external;

    /// @notice Withdraw underlying asset
    /// @dev Only fund contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to,uint256 scale)external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract StandardERC20 is Context, IERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../storage/GovIdentityStorage.sol";

/// @title manager role
/// @notice provide a unified identity address pool
contract GovIdentity {

    constructor() {
        _init();
    }

    function _init() internal{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = msg.sender;
        identity.rewards = msg.sender;
        identity.strategist[msg.sender]=true;
    }

    modifier onlyStrategist() {
        require(isStrategist(msg.sender), "!strategist");
        _;
    }

    modifier onlyGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(msg.sender == identity.governance, "!governance");
        _;
    }

    modifier onlyStrategistOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.strategist[msg.sender] || msg.sender == identity.governance, "!governance and !strategist");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = _governance;
    }

    function setRewards(address _rewards) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.rewards = _rewards;
    }

    function setStrategist(address _strategist,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.strategist[_strategist]=enable;
    }

    function getGovernance() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.governance;
    }

    function getRewards() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.rewards ;
    }

    function isStrategist(address _strategist) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.strategist[_strategist];
    }



}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library GovIdentityStorage {

  bytes32 public constant govSlot = keccak256("GovIdentityStorage.storage.location");

  struct Identity{
    address governance;
    address rewards;
    mapping(address=>bool) strategist;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov.slot := loc
    }
  }
}
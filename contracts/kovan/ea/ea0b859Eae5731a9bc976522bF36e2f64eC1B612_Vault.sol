// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IAssetManager.sol";
import "./interfaces/erc20/IERC20Metadata.sol";
import "./interfaces/weth/IWETH.sol";
import "./libraries/SafeMathExtends.sol";
import "./libraries/UniV3SwapExtends.sol";

import "./base/BasicVault.sol";
import "./storage/SmartPoolStorage.sol";
import "./storage/RouteStorage.sol";

pragma abicoder v2;
/// @title Vault Contract - The implmentation of vault contract
/// @notice This contract extends Basic Vault and defines the join and redeem activities
contract Vault is BasicVault, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;
    using Address for address;
    using Path for bytes;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    event PoolJoined(address indexed investor, uint256 amount);
    event PoolExited(address indexed investor, uint256 amount);

    /// @notice deny contract
    modifier notAllowContract() {
        require(!address(msg.sender).isContract(), "is contract");
        _;
    }
    /// @notice not in lup
    modifier notInLup() {
        bool inLup = block.timestamp <= lup();
        require(!inLup, "in lup");
        _;
    }

    /// @notice allow input token check
    /// @param token input token address
    modifier onlyWhiteList(address[] memory whiteList, address token) {
        bool isWhiteList = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (token == whiteList[i]) {
                isWhiteList = true;
                break;
            }
        }
        require(isWhiteList, "!whiteList");
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) BasicVault(name, symbol){

    }

    receive() external payable {
        require(msg.sender == SmartPoolStorage.load().weth, 'Not WETH');
    }

    /// @notice lock-up period
    function lup() public view returns (uint256){
        return SmartPoolStorage.load().lup;
    }

    /// @notice lock-up period
    /// @param _lup period value
    function setLup(uint256 _lup) external onlyAdminOrGovernance {
        SmartPoolStorage.load().lup = _lup;
    }

    /// @notice Set asset swap route
    /// @dev Only the governance and admin identity is allowed to set the asset swap path, and the firstToken and lastToken contained in the path will be used as the underlying asset token address by default
    /// @param path Swap path byte code
    function settingSwapRoute(bytes memory path) external onlyAdminOrGovernance {
        require(path.valid(), 'path is not valid');
        address fromToken = path.getFirstAddress();
        address toToken = path.getLastAddress();
        RouteStorage.load().swapRoute[fromToken][toToken] = path;
    }

    /// @notice get swapRoute
    function swapRoute(address fromToken, address toToken) public view returns (bytes memory)  {
        return RouteStorage.load().swapRoute[fromToken][toToken];
    }

    /// @notice setting inputs list
    /// @param inputs inputs token address
    function setAllowInput(address[] memory inputs) external onlyGovernance {
        RouteStorage.load().allowInputs = inputs;
    }

    /// @notice get white list
    function getAllowInputs() public view returns (address[] memory)  {
        return RouteStorage.load().allowInputs;
    }

    /// @notice setting output list
    /// @param outputs outputs token address
    function setAllowOutput(address[] memory outputs) external onlyGovernance {
        RouteStorage.load().allowOutputs = outputs;
    }

    /// @notice get white list
    function getAllowOutputs() public view returns (address[] memory)  {
        return RouteStorage.load().allowOutputs;
    }

    function _updateBasicInfo(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = IERC20Metadata(token).decimals();
        SmartPoolStorage.load().token = token;
        SmartPoolStorage.load().am = am;
        SmartPoolStorage.load().weth = weth;
        SmartPoolStorage.load().suspend = false;
        SmartPoolStorage.load().allowJoin = true;
        SmartPoolStorage.load().allowExit = true;
    }

    function init(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth
    ) public {
        require(getGovernance() == address(0), 'Already init');
        super._init();
        _updateBasicInfo(name, symbol, token, am, weth);
    }

    /// @notice Bind join and redeem address with asset management contract
    /// @dev Make the accuracy of the vault consistent with the accuracy of the bound token; it can only be bound once and cannot be modified
    /// @param token Join and redeem vault token address
    /// @param am Asset managemeent address
    function bind(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth) external onlyGovernance {
        _updateBasicInfo(name, symbol, token, am, weth);
    }

    /// @notice Subscript vault by default Token
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    /// @param amount Subscription amount
    function joinPool(uint256 amount) external isAllowJoin notAllowContract {
        _joinPool(msg.sender, address(ioToken()), amount);
    }

    /// @notice Subscript vault by token
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    /// @param token Subscription token
    /// @param amount Subscription amount
    function joinPool2(address token, uint256 amount) external isAllowJoin notAllowContract {
        _joinPool(msg.sender, token, amount);
    }

    /// @notice Subscript vault by eth
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    function joinPool3() external payable isAllowJoin notAllowContract {
        uint256 ethAmount = msg.value;
        address weth = SmartPoolStorage.load().weth;
        IWETH(weth).deposit{value : ethAmount}();
        IERC20(weth).safeApprove(address(this),ethAmount);
        _joinPool(address(this), weth, ethAmount);
    }

    /// @notice Subscript vault
    /// @param _inputToken Subscription token
    /// @param _inputAmount Subscription amount
    function _joinPool(address payer, address _inputToken, uint256 _inputAmount)
    internal onlyWhiteList(
        RouteStorage.load().allowInputs,
        _inputToken
    ) {
        IERC20 inputToken = IERC20(_inputToken);
        require(_inputAmount <= inputToken.balanceOf(payer) && _inputAmount > 0, "Insufficient balance");
        uint256 value = _estimateTokenValue(_inputToken, address(ioToken()), _inputAmount);
        uint256 vaultAmount = convertToShare(value);
        //take management fee
        takeOutstandingManagementFee();
        //take join fee
        uint256 fee = _takeJoinFee(msg.sender, vaultAmount);
        uint256 realVaultAmount = vaultAmount.sub(fee);
        _mint(msg.sender, realVaultAmount);
        inputToken.safeTransferFrom(payer, AM(), _inputAmount);
        emit PoolJoined(msg.sender, realVaultAmount);
    }

    /// @notice estimate value
    /// @param inputToken input token
    /// @param outputToken output token
    /// @param inputAmount input amount
    function _estimateTokenValue(address inputToken, address outputToken, uint256 inputAmount) internal view returns (uint256){
        uint256 value = inputAmount;
        if (inputToken != outputToken) {
            value = RouteStorage.load().swapRoute.estimateAmountOut(inputToken, outputToken, inputAmount);
        }
        return value;
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool(uint256 amount) external isAllowExit notInLup notAllowContract {
        _exitPool(msg.sender, address(ioToken()), amount);
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param outputToken Redeem token address
    /// @param amount Redeem amount
    function exitPool2(address outputToken, uint256 amount) external isAllowExit notInLup notAllowContract {
        _exitPool(msg.sender, outputToken, amount);
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool3(uint256 amount) external isAllowExit notInLup notAllowContract{
        address weth = SmartPoolStorage.load().weth;
        _exitPool(address(this), weth, amount);
        uint256 balance = IWETH(weth).balanceOf(address(this));
        if (balance > 0) {
            IWETH(weth).withdraw(balance);
            msg.sender.transfer(balance);
        }
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param rec rec address
    /// @param outputToken output token
    /// @param amount Redeem amount
    function _exitPool(address rec, address outputToken, uint256 amount)
    internal onlyWhiteList(
        RouteStorage.load().allowOutputs,
        outputToken
    ) {
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
        uint256 withdrawAmount = _estimateTokenValue(address(ioToken()), outputToken, cashAmount);
        //take management fee
        takeOutstandingManagementFee();
        // withdraw cash
        IAssetManager(AM()).withdraw(outputToken, rec, withdrawAmount, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Redeem the underlying assets of the vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPoolOfUnderlying(uint256 amount) external isAllowExit notInLup notAllowContract {
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

    /// @notice Vault token address for joining and redeeming
    /// @dev This is address is created when the vault is first created.
    /// @return Vault token address
    function ioToken() public view returns (IERC20){
        return IERC20(SmartPoolStorage.load().token);
    }

    /// @notice Vault mangement contract address
    /// @dev The vault management contract address is bind to the vault when the vault is created
    /// @return Vault management contract address
    function AM() public view returns (address){
        return SmartPoolStorage.load().am;
    }


    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) public virtual override view returns (uint256){
        uint256 cash = 0;
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            cash = 0;
        } else {
            cash = _assets.mul(vaultAmount).div(totalSupply);
        }
        return cash;
    }

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) public virtual override view returns (uint256){
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            return cashAmount;
        } else {
            return cashAmount.mul(totalSupply).div(_assets);
        }
    }

    /// @notice Vault total asset
    /// @dev This calculates vault net worth or AUM
    /// @return Vault total asset
    function assets() public view returns (uint256){
        return IAssetManager(AM()).assets();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library RouteStorage {

    bytes32 public constant ptSlot = keccak256("RouteStorage.storage.location");

    struct Route {
        address [] allowInputs;
        address [] allowOutputs;
        mapping(address => mapping(address => bytes)) swapRoute;
    }

    function load() internal pure returns (Route storage pt) {
        bytes32 loc = ptSlot;
        assembly {
            pt.slot := loc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SmartPoolStorage {

    bytes32 public constant sSlot = keccak256("SmartPoolStorage.storage.location");

    struct Storage {
        mapping(FeeType => Fee) fees;
        mapping(address => uint256) nets;
        address token;
        address am;
        address weth;
        uint256 cap;
        uint256 lup;
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
        JOIN_FEE, EXIT_FEE, MANAGEMENT_FEE, PERFORMANCE_FEE,TURNOVER_FEE
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

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./GovIdentity.sol";
import "../storage/SmartPoolStorage.sol";
import "./StandardERC20.sol";
pragma abicoder v2;
/// @title Basic Vault - Abstract Vault definition
/// @notice This contract extends ERC20, defines basic vault functions and rewrites ERC20 transferFrom function
abstract contract BasicVault is StandardERC20, GovIdentity {

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

    /// @notice restricted vault issuance
    modifier withinCap() {
        _;
        uint256 cap = SmartPoolStorage.load().cap;
        bool check = cap == 0 || totalSupply() <= cap ? true : false;
        require(check, "Cap limit");
    }

    /// @notice Prohibition of vault circulation
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
    /// @param addAmount Newly added vault amount
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
    /// @dev the purpose is to set the initial net worth of the vault. It also limit the max vault cap
    /// @param recipient Recipient address
    /// @param amount Mint amount
    function _mint(address recipient, uint256 amount) internal virtual override withinCap deny {
        uint256 newNet = globalNetValue();
        if (newNet == 0) newNet = 1e18;
        _updateAvgNet(recipient, amount, newNet);
        super._mint(recipient, amount);
    }

    /// @notice Overwrite burn function
    /// @dev The purpose is to set the net worth of vault to 0 when the balance of the account is 0
    /// @param account Account address
    /// @param amount Burn amount
    function _burn(address account, uint256 amount) internal virtual override deny {
        super._burn(account, amount);
        if (balanceOf(account) == 0) {
            SmartPoolStorage.load().nets[account] = 0;
        }
    }

    /// @notice Overwrite vault transferFrom function
    /// @dev The overwrite is to simplify the transaction behavior, and the authorization operation behavior can be avoided when the vault transaction payer is the function initiator
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
            _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "BasicVault: transfer amount exceeds allowance"));
        }
        return true;
    }

    /// @notice Vault cap
    /// @dev The max number of vault to be issued
    /// @return Max vault cap
    function getCap() public view returns (uint256){
        return SmartPoolStorage.load().cap;
    }

    /// @notice Set max vault cap
    /// @dev To set max vault cap
    /// @param cap Max vault cap
    function setCap(uint256 cap) external onlyAdminOrGovernance() {
        uint256 oldCap = SmartPoolStorage.load().cap;
        SmartPoolStorage.load().cap = cap;
        emit CapChanged(msg.sender, oldCap, cap);
    }

    /// @notice The net worth of the vault from the time the last fee collected
    /// @dev This is used to calculate the performance fee
    /// @param account Account address
    /// @return The net worth of the vault
    function accountNetValue(address account) public view returns (uint256){
        return SmartPoolStorage.load().nets[account];
    }

    /// @notice The current vault net worth
    /// @dev This is used to update and calculate account net worth
    /// @return The net worth of the vault
    function globalNetValue() public view returns (uint256){
        return convertToCash(1e18);
    }

    /// @notice Get fee by type
    /// @dev (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    function getFee(SmartPoolStorage.FeeType ft) public view returns (SmartPoolStorage.Fee memory){
        return SmartPoolStorage.load().fees[ft];
    }

    /// @notice Set fee by type
    /// @dev Only Governance address can set fees (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    /// @param ratio Fee ratio
    /// @param denominator The max ratio limit
    /// @param minLine The minimum line to charge a fee
    function setFee(SmartPoolStorage.FeeType ft, uint256 ratio, uint256 denominator, uint256 minLine) external onlyAdminOrGovernance {
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
    /// @dev The join fee is collected each time a user buys the vault
    /// @param target Account address to collect join fee
    /// @param vaultAmount Vault amount
    function _takeJoinFee(address target, uint256 vaultAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.JOIN_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.JOIN_FEE, vaultAmount);
        if (payFee == 0 || payFee < fee.minLine) return 0;
        _mint(getRewards(), payFee);
        emit TakeFee(SmartPoolStorage.FeeType.JOIN_FEE, target, payFee);
        return payFee;
    }

    /// @notice Collect Redeem fee
    /// @dev The redeem fee is collected when a user redeems the vault
    /// @param target Account address to collect redeem fee
    /// @param vaultAmount Vault amount
    function _takeExitFee(address target, uint256 vaultAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.EXIT_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.EXIT_FEE, vaultAmount);
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
    /// @param vaultAmount vault amount
    function calcRatioFee(SmartPoolStorage.FeeType ft, uint256 vaultAmount) public view returns (uint256){
        if (vaultAmount == 0) return 0;
        SmartPoolStorage.Fee memory fee = getFee(ft);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        uint256 amountRatio = vaultAmount.div(denominator);
        return amountRatio.mul(fee.ratio);
    }

    /// @notice vault maintenance
    /// @dev stop and open vault circulation
    /// @param _value status value
    function maintain(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().suspend = _value;
    }

    /// @notice vault allowJoin
    /// @dev stop and open vault circulation
    /// @param _value status value
    function allowJoin(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().allowJoin = _value;
    }

    /// @notice vault allowExit
    /// @dev stop and open vault circulation
    /// @param _value status value
    function allowExit(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().allowExit = _value;
    }

    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) public virtual view returns (uint256);

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) public virtual view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/uniswap-v3/ISwapRouter.sol";
import "../interfaces/uniswap-v3/IUniswapV3Pool.sol";
import "../interfaces/uniswap-v3/PoolAddress.sol";
import "../interfaces/uniswap-v3/Path.sol";

import "./SafeMathExtends.sol";

pragma abicoder v2;

/// @title UniV3 Swap extends libraries
/// @notice libraries
library UniV3SwapExtends {

    using Path for bytes;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;

    //x96
    uint256 constant internal x96 = 2 ** 96;

    //fee denominator
    uint256 constant internal denominator = 1000000;

    //Swap Router
    ISwapRouter constant internal SRT = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Estimated to obtain the target token amount
    /// @dev Only allow the asset transaction path that has been set to be estimated
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountIn Source token amount
    /// @return amountOut Target token amount
    function estimateAmountOut(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn
    ) internal view returns (uint256 amountOut){
        if (amountIn == 0) {return 0;}
        bytes memory path = self[from][to];
        amountOut = amountIn;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            amountOut = amountOut.mul(denominator.sub(uint256(fee))).div(denominator);
            if (token0 == toToken) {
                amountOut = amountOut.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            } else {
                amountOut = amountOut.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            }
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Estimate the amount of source tokens that need to be provided
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountOut Expected target token amount
    /// @return amountIn Source token amount
    function estimateAmountIn(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountOut
    ) internal view returns (uint256 amountIn){
        if (amountOut == 0) {return 0;}
        bytes memory path = self[from][to];
        amountIn = amountOut;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            if (token0 == toToken) {
                amountIn = amountIn.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            } else {
                amountIn = amountIn.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            }
            amountIn = amountIn.mul(denominator).div(denominator.sub(uint256(fee)));
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Initiate a transaction with a known input amount and return the output amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param amountIn Token in amount
    /// @param recipient Recipient address
    /// @param amountOutMinimum Expected to get minimum token out amount
    /// @return Token out amount
    function exactInput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMinimum
    ) internal returns (uint256){
        bytes memory path = self[from][to];
        return SRT.exactInput(
            ISwapRouter.ExactInputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountIn : amountIn,
        amountOutMinimum : amountOutMinimum
        }));
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @dev Initiate a transaction with a known output amount and return the input amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param recipient Recipient address
    /// @param amountOut Token out amount
    /// @param amountInMaximum Expect to input the maximum amount of tokens
    /// @return Token in amount
    function exactOutput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum
    ) internal returns (uint256){
        bytes memory path = self[to][from];
        return SRT.exactOutput(
            ISwapRouter.ExactOutputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountOut : amountOut,
        amountInMaximum : amountInMaximum
        }));
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
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
/// @notice This contract is used to manage value asset
interface IAssetManager {

    /// @notice Total asset
    /// @dev This function calculates the net worth or AUM
    /// @return Total asset
    function assets()external view returns(uint256);

    /// @notice Withdraw asset
    /// @dev Only value contract can withdraw asset
    /// @param outputToken output token address
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address outputToken,address to,uint256 amount,uint256 scale)external;

    /// @notice Withdraw underlying asset
    /// @dev Only value contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to,uint256 scale)external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Check the legitimacy of the path
    /// @param path The encoded swap path
    /// @return Legal path
    function valid(bytes memory path)internal pure returns(bool) {
        return path.length>=POP_OFFSET;
    }

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Gets the segment corresponding to the last pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the last pool in the path
    function getLastPool(bytes memory path) internal pure returns (bytes memory) {
        if(path.length==POP_OFFSET){
            return path;
        }else{
            return path.slice(path.length-POP_OFFSET, path.length);
        }
    }

    /// @notice Gets the first address of the path
    /// @param path The encoded swap path
    /// @return address
    function getFirstAddress(bytes memory path)internal pure returns(address){
        return path.toAddress(0);
    }

    /// @notice Gets the last address of the path
    /// @param path The encoded swap path
    /// @return address
    function getLastAddress(bytes memory path)internal pure returns(address){
        return path.toAddress(path.length-ADDR_SIZE);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    //Uniswap V3 Factory
    address constant private factory = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address) {
        return computeAddress(getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0 : tokenA, token1 : tokenB, fee : fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);


    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
    external
    view
    returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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
        identity.admin[msg.sender]=true;
    }

    modifier onlyAdmin() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(isAdmin(msg.sender), "!admin");
        _;
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

    modifier onlyAdminOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.admin[msg.sender] || msg.sender == identity.governance, "!governance and !admin");
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

    function setAdmin(address _admin,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.admin[_admin]=enable;
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

    function isAdmin(address _admin) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.admin[_admin];
    }


}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <=0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
    mapping(address=>bool) admin;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov.slot := loc
    }
  }
}
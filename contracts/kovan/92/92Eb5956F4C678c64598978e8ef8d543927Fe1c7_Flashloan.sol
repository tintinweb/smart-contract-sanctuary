pragma solidity >=0.6.0 <0.8.0;
//pragma solidity ^0.6.6;
interface ILendingPool {
	function addressesProvider () external view returns ( address );
	function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
	function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
	function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
	function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
	function swapBorrowRateMode ( address _reserve ) external;
	function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
	function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
	function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
	function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
	function getReserveConfigurationData ( address _reserve ) external view returns ( 
		uint256 ltv, 
		uint256 liquidationThreshold, 
		uint256 liquidationDiscount, 
		address interestRateStrategyAddress, 
		bool usageAsCollateralEnabled, 
		bool borrowingEnabled, 
		bool fixedBorrowRateEnabled, 
		bool isActive );
	function getReserveData ( address _reserve ) external view returns ( 
		uint256 totalLiquidity, 
		uint256 availableLiquidity, 
		uint256 totalBorrowsFixed, 
		uint256 totalBorrowsVariable, 
		uint256 liquidityRate, 
		uint256 variableBorrowRate, 
		uint256 fixedBorrowRate, 
		uint256 averageFixedBorrowRate, 
		uint256 utilizationRate, 
		uint256 liquidityIndex, 
		uint256 variableBorrowIndex, 
		address aTokenAddress, 
		uint40 lastUpdateTimestamp );
	function getUserAccountData ( address _user ) external view returns ( 
		uint256 totalLiquidityETH,
		uint256 totalCollateralETH, 
		uint256 totalBorrowsETH, 
		uint256 availableBorrowsETH, 
		uint256 currentLiquidationThreshold, 
		uint256 ltv, uint256 healthFactor 
	 );
	function getUserReserveData ( address _reserve, address _user ) external view returns ( uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled );
	function getReserves () external view;
 }
//pragma solidity >=0.6.0 <0.8.0;
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
 }
//pragma solidity ^0.6.6;
interface IFlashLoanReceiver {
	function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
 }
//pragma solidity ^0.6.6;
interface ILendingPoolAddressesProvider {
	function getLendingPoolCore() external view returns (address payable);
	function getLendingPool() external view returns (address);
 }
//pragma solidity >=0.6.2 <0.8.0;
library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(account) }
		return size > 0;
	 }
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	 }
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	 }
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	 }
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	 }
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	 }
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	 }
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	 }
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	 }
	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	 }
	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
			return returndata;
		 } else {
			if (returndata.length > 0) {
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
//pragma solidity >=0.6.0 <0.8.0;
library SafeERC20 {
	using SafeMath for uint256;
	using Address for address;
	function safeTransfer(IERC20 token, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	 }
	function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	 }
	function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) {
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		 }
	 }
 }
//pragma solidity >=0.6.0 <0.8.0;
library SafeMath {
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		uint256 c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	 }
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b > a) return (false, 0);
		return (true, a - b);
	 }
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (a == 0) return (true, 0);
		uint256 c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	 }
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b == 0) return (false, 0);
		return (true, a / b);
	 }
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b == 0) return (false, 0);
		return (true, a % b);
	 }
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	 }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	 }
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) return 0;
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	 }
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: division by zero");
		return a / b;
	 }
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: modulo by zero");
		return a % b;
	 }
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		return a - b;
	 }
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a / b;
	 }
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a % b;
	 }
 }
//ma solidity >=0.6.0 <0.8.0;
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	 }
	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	 }
 }
//pragma solidity >=0.6.0 <0.8.0;
contract ERC20 is Context, IERC20 {
	using SafeMath for uint256;
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	uint256 private _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;
	constructor (string memory name_, string memory symbol_) public {
		_name = name_;
		_symbol = symbol_;
		_decimals = 18;
	 }
	function name() public view virtual returns (string memory) {
		return _name;
	 }	
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	 }
	function decimals() public view virtual returns (uint8) {
		return _decimals;
	 }
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	 }
	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	 }
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	 }
	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	 }
	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	 }
	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	 }
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	 }
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	 }
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	 }
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	 }
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	 }
	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	 }
	function _setupDecimals(uint8 decimals_) internal virtual {
		_decimals = decimals_;
	 }
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
 }

//pragma solidity >=0.6.0 <0.8.0;
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	 }
	function owner() public view virtual returns (address) {
		return _owner;
	 }
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	 }
	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	 }
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	 }
 }
//pragma solidity ^0.6.6;
contract Withdrawable is Ownable {
	using SafeERC20 for ERC20;
	address constant ETHER = address(0);
	event LogWithdraw(
		address indexed _from,
		address indexed _assetAddress,
		uint amount
	 );
//ryan notes, works for tokens erc20, but not eth?
	function withdraw(address _assetAddress) public onlyOwner {
		uint assetBalance;
		if (_assetAddress == ETHER) {
			address self = address(this); // workaround for a possible solidity bug
			assetBalance = self.balance;
			msg.sender.transfer(assetBalance);
		 } else {
			assetBalance = ERC20(_assetAddress).balanceOf(address(this));
			ERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
		 }
		emit LogWithdraw(msg.sender, _assetAddress, assetBalance);
	 }
	 
 }
//pragma solidity ^0.6.6;
abstract contract FlashLoanReceiverBase is IFlashLoanReceiver, Withdrawable {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	ILendingPoolAddressesProvider public addressesProvider;
	constructor(address _addressProvider) public {
		addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
	 }
	receive() payable external {}
	function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
		address payable core = addressesProvider.getLendingPoolCore();
		transferInternal(core, _reserve, _amount);
	 }
	function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
		if(_reserve == ethAddress) {
			(bool success, ) = _destination.call{value: _amount}("");
			require(success == true, "Couldn't transfer ETH");
			return;
		 }
		IERC20(_reserve).safeTransfer(_destination, _amount);
	 }
	function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
		if(_reserve == ethAddress) {
			return _target.balance;
		 }
		return IERC20(_reserve).balanceOf(_target);
	 }
 }
//pragma solidity ^0.6.6;
contract Flashloan is FlashLoanReceiverBase {
	constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}
	function executeOperation(
		address _reserve,
		uint256 _amount,
		uint256 _fee,
		bytes calldata _params
	 )
		external
		override
	{
		require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

		//
		// Your logic goes here.
		// !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
		//

		uint totalDebt = _amount.add(_fee);
		transferFundsBackToPoolInternal(_reserve, totalDebt);
	 }
	/**
		Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
	 */
	function flashloan(address _asset) public onlyOwner {
		bytes memory data = "";
		uint amount = 1 ether;

		ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
		lendingPool.flashLoan(address(this), _asset, amount, data);
	 }
 }
//
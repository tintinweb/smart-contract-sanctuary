/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// File: lib/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

    constructor () public {
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
// File: iface/IPTokenFactory.sol

pragma solidity ^0.6.12;

interface IPTokenFactory {
    function getGovernance() external view returns(address);
    function getPTokenOperator(address contractAddress) external view returns(bool);
    function getPTokenAuthenticity(address pToken) external view returns(bool);
}
// File: iface/IParasset.sol

pragma solidity ^0.6.12;

interface IParasset {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function destroy(uint256 amount, address account) external;
    function issuance(uint256 amount, address account) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: PToken.sol

pragma solidity ^0.6.12;




contract PToken is IParasset {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 public _totalSupply = 0;                                        
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    IPTokenFactory pTokenFactory;

    constructor (string memory _name, 
                 string memory _symbol) public {
    	name = _name;                                                               
    	symbol = _symbol;
    	pTokenFactory = IPTokenFactory(address(msg.sender));
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(address(msg.sender) == pTokenFactory.getGovernance(), "Log:PToken:!governance");
        _;
    }

    modifier onlyPool() {
    	require(pTokenFactory.getPTokenOperator(address(msg.sender)), "Log:PToken:!Pool");
    	_;
    }

    //---------view---------

    // Query factory contract address
    function getPTokenFactory() public view returns(address) {
        return address(pTokenFactory);
    }

    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowed[owner][spender];
    }

    //---------transaction---------

    function changeFactory(address factory) public onlyGovernance {
        pTokenFactory = IPTokenFactory(address(factory));
    }

    function transfer(address to, uint256 value) override public returns (bool) 
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) override public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool) 
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function destroy(uint256 amount, address account) override external onlyPool{
    	require(_balances[account] >= amount, "Log:PToken:!destroy");
    	_balances[account] = _balances[account].sub(amount);
    	_totalSupply = _totalSupply.sub(amount);
    	emit Transfer(account, address(0x0), amount);
    }

    function issuance(uint256 amount, address account) override external onlyPool{
    	_balances[account] = _balances[account].add(amount);
    	_totalSupply = _totalSupply.add(amount);
    	emit Transfer(address(0x0), account, amount);
    }
}
// File: iface/IMortgagePool.sol

pragma solidity ^0.6.12;

interface IMortgagePool {
    function create(address pToken, address insurance, address underlying) external;
    function getUnderlyingToPToken(address uToken) external view returns(address);
    function getPTokenToUnderlying(address pToken) external view returns(address);
    function getGovernance() external view returns(address);
}
// File: iface/IERC20.sol

pragma solidity ^0.6.12;

interface IERC20 {
	function decimals() external view returns (uint8);
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: lib/Address.sol


pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
// File: lib/SafeERC20.sol


pragma solidity 0.6.12;



library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: lib/TransferHelper.sol


pragma solidity ^0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: lib/SafeMath.sol


pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}
// File: InsurancePool.sol

pragma solidity ^0.6.12;

contract InsurancePool is ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	// Governance address
	address public governance;
	// Underlying asset address => negative account funds
	mapping(address=>uint256) insNegative;
	// Underlying asset address => total LP
	mapping(address=>uint256) totalSupply;
	// Underlying asset address => latest redemption time
    mapping(address=>uint256) latestTime;
	// Redemption cycle, 14 days
	uint256 public redemptionCycle = 15 minutes;
	// Redemption duration, 2 days
	uint256 public waitCycle = 30 minutes;
    // User address => Underlying asset address => LP quantity
    mapping(address=>mapping(address=>uint256)) balances;
	// User address => Underlying asset address => Freeze LP data
	mapping(address=>mapping(address=>Frozen)) frozenIns;
	struct Frozen {
		uint256 amount;							// Frozen quantity
		uint256 time;							// Freezing time
	}
    // Mortgage pool address
    IMortgagePool mortgagePool;
    // PTokenFactory address
    IPTokenFactory pTokenFactory;
    // Status
    uint8 public flag;      // = 0: pause
                            // = 1: active
                            // = 2: redemption only
    // Rate(2/1000)
    uint256 feeRate = 2;

    event Destroy(address token, uint256 amount, address account);
    event Issuance(address token, uint256 amount, address account);
    event Negative(address token, uint256 amount, uint256 allValue);

    /// @dev Initialization method
    /// @param factoryAddress PTokenFactory address
	constructor (address factoryAddress) public {
        pTokenFactory = IPTokenFactory(factoryAddress);
        governance = pTokenFactory.getGovernance();
        flag = 0;
    }

	//---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == governance, "Log:InsurancePool:!gov");
        _;
    }

    modifier onlyMortgagePool() {
        require(msg.sender == address(mortgagePool), "Log:InsurancePool:!mortgagePool");
        _;
    }

    modifier onlyGovOrMor() {
        require(msg.sender == governance || msg.sender == address(mortgagePool), "Log:InsurancePool:!onlyGovOrMor");
        _;
    }

    modifier whenActive() {
        require(flag == 1, "Log:InsurancePool:!active");
        _;
    }

    modifier redemptionOnly() {
        require(flag != 0, "Log:InsurancePool:!0");
        _;
    }

    //---------view---------

    /// @dev View governance address
    /// @return governance address
    function getGovernance() external view returns(address) {
        return governance;
    }

    /// @dev View negative ledger
    /// @param token underlying asset address
    /// @return negative ledger
    function getInsNegative(address token) external view returns(uint256) {
        return insNegative[token];
    }

    /// @dev View total LP
    /// @param token underlying asset address
    /// @return total LP
    function getTotalSupply(address token) external view returns(uint256) {
        return totalSupply[token];
    }

    /// @dev View personal LP
    /// @param token underlying asset address
    /// @param add user address
    /// @return personal LP
    function getBalances(address token, 
                         address add) external view returns(uint256) {
        return balances[add][token];
    }

    /// @dev View rate
    /// @return rate
    function getFeeRate() external view returns(uint256) {
        return feeRate;
    }

    /// @dev View mortgage pool address
    /// @return mortgage pool address
    function getMortgagePool() external view returns(address) {
        return address(mortgagePool);
    }

    /// @dev View the latest redemption time
    /// @param token underlying asset address
    /// @return the latest redemption time
    function getLatestTime(address token) external view returns(uint256) {
        return latestTime[token];
    }

    /// @dev View redemption period, next time
    /// @param token underlying asset address
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTime(address token) external view returns(uint256 startTime, 
                                                                    uint256 endTime) {
        uint256 time = latestTime[token];
        if (now > time) {
            uint256 subTime = now.sub(time).div(waitCycle);
            startTime = time.add(waitCycle.mul(uint256(1).add(subTime)));
        } else {
            startTime = time;
        }
        endTime = startTime.add(redemptionCycle);
    }

    /// @dev View redemption period, this period
    /// @param token underlying asset address
    /// @return startTime start time
    /// @return endTime end time
    function getRedemptionTimeFront(address token) external view returns(uint256 startTime, 
                                                                         uint256 endTime) {
        uint256 time = latestTime[token];
        if (now > time) {
            uint256 subTime = now.sub(time).div(waitCycle);
            startTime = time.add(waitCycle.mul(subTime));
        } else {
            startTime = time.sub(waitCycle);
        }
        endTime = startTime.add(redemptionCycle);
    }

    /// @dev View frozen LP and unfreeze time
    /// @param token underlying asset address
    /// @param add user address
    /// @return frozen LP
    /// @return unfreeze time
    function getFrozenIns(address token, 
                          address add) external view returns(uint256, uint256) {
        Frozen memory frozenInfo = frozenIns[add][token];
        return (frozenInfo.amount, frozenInfo.time);
    }

    /// @dev View frozen LP and unfreeze time, real time
    /// @param token underlying asset address
    /// @param add user address
    /// @return frozen LP
    function getFrozenInsInTime(address token, 
                                address add) external view returns(uint256) {
        Frozen memory frozenInfo = frozenIns[add][token];
        if (now > frozenInfo.time) {
            return 0;
        }
        return frozenInfo.amount;
    }

    /// @dev View redeemable LP, real time
    /// @param token underlying asset address
    /// @param add user address
    /// @return redeemable LP
    function getRedemptionAmount(address token, 
                                 address add) external view returns (uint256) {
        Frozen memory frozenInfo = frozenIns[add][token];
        uint256 balanceSelf = balances[add][token];
        if (now > frozenInfo.time) {
            return balanceSelf;
        } else {
            return balanceSelf.sub(frozenInfo.amount);
        }
    }

	/// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(address inputToken, 
    	                          uint256 inputTokenAmount, 
    	                          address outputToken) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = IERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = IERC20(outputToken).decimals();
    	}
    	return inputTokenAmount.mul(10**outputTokenDec).div(10**inputTokenDec);
    }

    //---------governance----------

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: redemption only
    function setFlag(uint8 num) public onlyGovernance {
        flag = num;
    }

    /// @dev Set mortgage pool address
    function setMortgagePool(address add) public onlyGovernance {
    	mortgagePool = IMortgagePool(add);
    }

    /// @dev Set the latest redemption time
    function setLatestTime(address token) public onlyGovOrMor {
        latestTime[token] = now.add(waitCycle);
    }

    /// @dev Set the rate
    function setFeeRate(uint256 num) public onlyGovernance {
        feeRate = num;
    }

    /// @dev Set redemption cycle
    function setRedemptionCycle(uint256 num) public onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        redemptionCycle = num * 1 days;
    }

    /// @dev Set redemption duration
    function setWaitCycle(uint256 num) public onlyGovernance {
        require(num > 0, "Log:InsurancePool:!zero");
        waitCycle = num * 1 days;
    }

    //---------transaction---------

    /// @dev Set governance address
    function setGovernance() public {
        governance = pTokenFactory.getGovernance();
    }

    /// @dev Exchange: ptoken exchanges the underlying asset
    /// @param pToken ptoken address
    /// @param amount amount of ptoken
    function exchangePTokenToUnderlying(address pToken, 
    	                                uint256 amount) public whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount.mul(feeRate).div(1000);

        // Transfer to the ptoken
    	ERC20(pToken).safeTransferFrom(address(msg.sender), address(this), amount);

        // Verify ptoken
        address underlyingToken = mortgagePool.getPTokenToUnderlying(pToken);
        address pToken_s = mortgagePool.getUnderlyingToPToken(underlyingToken);
        require(pToken_s == pToken,"Log:InsurancePool:!pToken");

        // Calculate the amount of transferred underlying asset
        uint256 uTokenAmount = getDecimalConversion(pToken, amount.sub(fee), underlyingToken);
        require(uTokenAmount > 0, "Log:InsurancePool:!uTokenAmount");

        // Transfer out underlying asset
    	if (underlyingToken != address(0x0)) {
    		ERC20(underlyingToken).safeTransfer(address(msg.sender), uTokenAmount);
    	} else {
            TransferHelper.safeTransferETH(address(msg.sender), uTokenAmount);
    	}

    	// Eliminate negative ledger
        _eliminate(pToken, underlyingToken);
    }

    /// @dev Exchange: underlying asset exchanges the ptoken
    /// @param token underlying asset address
    /// @param amount amount of underlying asset
    function exchangeUnderlyingToPToken(address token, 
    	                                uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Calculate the fee
    	uint256 fee = amount.mul(feeRate).div(1000);

        // Transfer to the underlying asset
    	if (token != address(0x0)) {
            // The underlying asset is ERC20
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
    		ERC20(token).safeTransferFrom(address(msg.sender), address(this), amount);
    	} else {
            // The underlying asset is ETH
    		require(msg.value == amount, "Log:InsurancePool:!msg.value");
    	}

        // Calculate the amount of transferred ptokens
    	address pToken = mortgagePool.getUnderlyingToPToken(token);
        uint256 pTokenAmount = getDecimalConversion(token, amount.sub(fee), pToken);
        require(pTokenAmount > 0, "Log:InsurancePool:!pTokenAmount");

        // Transfer out ptoken
        uint256 pTokenBalance = ERC20(pToken).balanceOf(address(this));
        if (pTokenBalance < pTokenAmount) {
            // Insufficient ptoken balance,
            uint256 subNum = pTokenAmount.sub(pTokenBalance);
            PToken(pToken).issuance(subNum, address(this));
            insNegative[token] = insNegative[token].add(subNum);
        }
    	ERC20(pToken).safeTransfer(address(msg.sender), pTokenAmount);
    }

    /// @dev Subscribe for insurance
    /// @param token underlying asset address
    /// @param amount amount of underlying asset
    function subscribeIns(address token, 
    	                  uint256 amount) public payable whenActive nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");

        // Verify ptoken
        address pToken = mortgagePool.getUnderlyingToPToken(token);
        require(pToken != address(0x0), "Log:InsurancePool:!pToken");

        // Update redemption time
    	updateLatestTime(token);

        // Thaw LP
    	Frozen storage frozenInfo = frozenIns[address(msg.sender)][token];
    	if (now > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}

        // ptoken balance 
    	uint256 pTokenBalance = ERC20(pToken).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (token != address(0x0)) {
            // Underlying asset conversion 18 decimals
    		tokenBalance = getDecimalConversion(token, ERC20(token).balanceOf(address(this)), pToken);
    	} else {
            // The amount of ETH involved in the calculation does not include the transfer in this time
    		require(msg.value == amount, "Log:InsurancePool:!msg.value");
    		tokenBalance = address(this).balance.sub(amount);
    	}

        // Calculate LP
    	uint256 insAmount = 0;
    	uint256 insTotal = totalSupply[token];
        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance.add(pTokenBalance);
        require(allBalance > insNegative[token], "Log:InsurancePool:allBalanceNotEnough");
    	if (insTotal != 0) {
            uint256 allValue = allBalance.sub(insNegative[token]);
    		insAmount = getDecimalConversion(token, amount, pToken).mul(insTotal).div(allValue);
    	} else {
            // The initial net value is 1
            insAmount = getDecimalConversion(token, amount, pToken);
        }

    	// Transfer to the underlying asset(ERC20)
    	if (token != address(0x0)) {
    		require(msg.value == 0, "Log:InsurancePool:msg.value!=0");
    		ERC20(token).safeTransferFrom(address(msg.sender), address(this), amount);
    	}

    	// Additional LP issuance
    	issuance(token, insAmount, address(msg.sender));

    	// Freeze insurance LP
    	frozenInfo.amount = frozenInfo.amount.add(insAmount);
    	frozenInfo.time = latestTime[token].add(waitCycle);
    }

    /// @dev Redemption insurance
    /// @param token underlying asset address
    /// @param amount redemption LP
    function redemptionIns(address token, 
    	                   uint256 amount) public redemptionOnly nonReentrant {
        // amount > 0
        require(amount > 0, "Log:InsurancePool:!amount");
        
        // Verify ptoken
        address pToken = mortgagePool.getUnderlyingToPToken(token);
        require(pToken != address(0x0), "Log:InsurancePool:!pToken");

        // Update redemption time
    	updateLatestTime(token);

        // Judging the redemption time
        uint256 tokenTime = latestTime[token];
    	require(now >= tokenTime.sub(waitCycle) && now <= tokenTime.sub(waitCycle).add(redemptionCycle), "Log:InsurancePool:!time");

        // Thaw LP
    	Frozen storage frozenInfo = frozenIns[address(msg.sender)][token];
    	if (now > frozenInfo.time) {
    		frozenInfo.amount = 0;
    	}
    	
        // ptoken balance
    	uint256 pTokenBalance = ERC20(pToken).balanceOf(address(this));
        // underlying asset balance
        uint256 tokenBalance;
    	if (token != address(0x0)) {
    		tokenBalance = getDecimalConversion(token, ERC20(token).balanceOf(address(this)), pToken);
    	} else {
    		tokenBalance = address(this).balance;
    	}

        // Insurance pool assets must be greater than 0
        uint256 allBalance = tokenBalance.add(pTokenBalance);
        require(allBalance > insNegative[token], "Log:InsurancePool:allBalanceNotEnough");
        // Calculated amount of assets
    	uint256 allValue = allBalance.sub(insNegative[token]);
    	uint256 insTotal = totalSupply[token];
    	uint256 underlyingAmount = amount.mul(allValue).div(insTotal);

        // Destroy LP
        destroy(token, amount, address(msg.sender));
        // Judgment to freeze LP
        require(balances[address(msg.sender)][token] >= frozenInfo.amount, "Log:InsurancePool:frozen");
    	
    	// Transfer out assets, priority transfer of the underlying assets, if the underlying assets are insufficient, transfer ptoken
    	if (token != address(0x0)) {
            // ERC20
            if (tokenBalance >= underlyingAmount) {
                ERC20(token).safeTransfer(address(msg.sender), getDecimalConversion(pToken, underlyingAmount, token));
            } else {
                ERC20(token).safeTransfer(address(msg.sender), getDecimalConversion(pToken, tokenBalance, token));
                ERC20(pToken).safeTransfer(address(msg.sender), underlyingAmount.sub(tokenBalance));
            }
    	} else {
            // ETH
            if (tokenBalance >= underlyingAmount) {
                TransferHelper.safeTransferETH(address(msg.sender), underlyingAmount);
            } else {
                TransferHelper.safeTransferETH(address(msg.sender), tokenBalance);
                ERC20(pToken).safeTransfer(address(msg.sender), 
                                           underlyingAmount.sub(tokenBalance));
            }
    	}
    }

    /// @dev Destroy ptoken, update negative ledger
    /// @param pToken ptoken address
    /// @param amount quantity destroyed
    /// @param token underlying asset address
    function destroyPToken(address pToken, 
    	                   uint256 amount,
                           address token) public onlyMortgagePool {
    	PToken pErc20 = PToken(pToken);
    	uint256 pTokenBalance = pErc20.balanceOf(address(this));
    	if (pTokenBalance >= amount) {
    		pErc20.destroy(amount, address(this));
    	} else {
    		pErc20.destroy(pTokenBalance, address(this));
    		// 记录负账户
            uint256 subAmount = amount.sub(pTokenBalance);
    		insNegative[token] = insNegative[token].add(subAmount);
            emit Negative(pToken, subAmount, insNegative[token]);
    	}
    }

    /// @dev Eliminate negative ledger
    /// @param pToken ptoken address
    /// @param token underlying asset address
    function eliminate(address pToken, 
                       address token) public onlyMortgagePool {
    	_eliminate(pToken, token);
    }

    function _eliminate(address pToken, 
                        address token) private {

    	PToken pErc20 = PToken(pToken);
        // negative ledger
    	uint256 negative = insNegative[token];
        // ptoken balance
    	uint256 pTokenBalance = pErc20.balanceOf(address(this)); 
    	if (negative > 0 && pTokenBalance > 0) {
    		if (negative >= pTokenBalance) {
                // Increase negative ledger
                pErc20.destroy(pTokenBalance, address(this));
    			insNegative[token] = insNegative[token].sub(pTokenBalance);
                emit Negative(pToken, pTokenBalance, insNegative[token]);
    		} else {
                // negative ledger = 0
                pErc20.destroy(negative, address(this));
    			insNegative[token] = 0;
                emit Negative(pToken, insNegative[token], insNegative[token]);
    		}
    	}
    }

    /// @dev Update redemption time
    /// @param token underlying asset address
    function updateLatestTime(address token) public {
        uint256 time = latestTime[token];
    	if (now > time) {
    		uint256 subTime = now.sub(time).div(waitCycle);
    		latestTime[token] = time.add(waitCycle.mul(uint256(1).add(subTime)));
    	}
    }

    /// @dev Destroy LP
    /// @param token underlying asset address
    /// @param amount quantity destroyed
    /// @param account destroy address
    function destroy(address token, 
                     uint256 amount, 
                     address account) private {
        require(balances[account][token] >= amount, "Log:InsurancePool:!destroy");
        balances[account][token] = balances[account][token].sub(amount);
        totalSupply[token] = totalSupply[token].sub(amount);
        emit Destroy(token, amount, account);
    }

    /// @dev Additional LP issuance
    /// @param token underlying asset address
    /// @param amount additional issuance quantity
    /// @param account additional issuance address
    function issuance(address token, 
                      uint256 amount, 
                      address account) private {
        balances[account][token] = balances[account][token].add(amount);
        totalSupply[token] = totalSupply[token].add(amount);
        emit Issuance(token, amount, account);
    }

    function takeOutERC20(address token, uint256 amount, address to) public onlyGovernance {
        ERC20(token).safeTransfer(address(to), amount);
    }

    function takeOutETH(uint256 amount, address to) public onlyGovernance {
        TransferHelper.safeTransferETH(address(to), amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: lib/ReentrancyGuard.sol

// SPDX-License-Identifier: GPL-3.0-or-later

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
// File: iface/IPriceController.sol

pragma solidity ^0.6.12;

interface IPriceController {
    function getPriceForPToken(address token, address uToken, address payback) external payable returns (uint256 tokenPrice, uint256 pTokenPrice);
}
// File: iface/IInsurancePool.sol

pragma solidity ^0.6.12;

interface IInsurancePool {
    function setPTokenToIns(address pToken, address ins) external;
    function destroyPToken(address pToken, uint256 amount, address token) external;
    function eliminate(address pToken, address token) external;
    function setLatestTime(address token) external;
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

    function rename(string memory _name, 
                    string memory _symbol) public onlyGovernance {
        name = _name;                                                               
        symbol = _symbol;
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
// File: MortgagePool.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract MortgagePool is ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

    // Governance address
	address public governance;
	// Underlying asset address => PToken address
	mapping(address=>address) public underlyingToPToken;
	// PToken address => Underlying asset address
	mapping(address=>address) public pTokenToUnderlying;
    // PToken address => Mortgage asset address => Bool
	mapping(address=>mapping(address=>bool)) mortgageAllow;
    // PToken address => Mortgage asset address => User address => Debt data
	mapping(address=>mapping(address=>mapping(address=>PersonalLedger))) ledger;
    // PToken address => Mortgage asset address => Users who have created debt positions(address)
    mapping(address=>mapping(address=>address[])) ledgerArray;
    // Mortgage asset address => Maximum mortgage rate
    mapping(address=>uint256) maxRate;
    // Mortgage asset address => Liquidation line
    mapping(address=>uint256) liquidationLine;
    // PriceController contract
    IPriceController quary;
    // Insurance pool contract
    IInsurancePool insurancePool;
    // PToken creation factory contract
    IPTokenFactory pTokenFactory;
	// Market base interest rate
	uint256 r0 = 0.025 ether;
	// Amount of blocks produced in a year
	uint256 oneYear = 2400000;
    // Status
    uint8 public flag;      // = 0: pause
                            // = 1: active
                            // = 2: out only

	struct PersonalLedger {
        uint256 mortgageAssets;         // Amount of mortgaged assets
        uint256 parassetAssets;         // Amount of debt(Ptoken,Stability fee not included)
        uint256 blockHeight;            // The block height of the last operation
        uint256 rate;                   // Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
        bool created;                   // Is it created
    }

    event FeeValue(address pToken, uint256 value);

    /// @dev Initialization method
    /// @param factoryAddress PToken creation factory contract
	constructor (address factoryAddress) public {
        pTokenFactory = IPTokenFactory(factoryAddress);
        governance = pTokenFactory.getGovernance();
        flag = 0;
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == governance, "Log:MortgagePool:!gov");
        _;
    }

    modifier whenActive() {
        require(flag == 1, "Log:MortgagePool:!active");
        _;
    }

    modifier outOnly() {
        require(flag != 0, "Log:MortgagePool:!0");
        _;
    }

    //---------view---------

    /// @dev Calculate the stability fee
    /// @param parassetAssets Amount of debt(Ptoken,Stability fee not included)
    /// @param blockHeight The block height of the last operation
    /// @param rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @param nowRate Current mortgage rate (not including stability fee)
    /// @return fee
    function getFee(uint256 parassetAssets, 
    	            uint256 blockHeight,
    	            uint256 rate,
                    uint256 nowRate) public view returns(uint256) {
        uint256 topOne = parassetAssets.mul(r0).mul(block.number.sub(blockHeight));
        uint256 ratePlus = rate.add(nowRate);
        uint256 topTwo = parassetAssets.mul(r0).mul(block.number.sub(blockHeight)).mul(uint256(3).mul(ratePlus));
    	uint256 bottom = oneYear.mul(1 ether);
    	return topOne.div(bottom).add(topTwo.div(bottom.mul(1 ether).mul(2)));
    }

    /// @dev Calculate the mortgage rate
    /// @param mortgageAssets Amount of mortgaged assets
    /// @param parassetAssets Amount of debt
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    /// @return mortgage rate
    function getMortgageRate(uint256 mortgageAssets,
    	                     uint256 parassetAssets, 
    	                     uint256 tokenPrice, 
    	                     uint256 pTokenPrice) public pure returns(uint256) {
        if (mortgageAssets == 0 || pTokenPrice == 0) {
            return 0;
        }
    	return parassetAssets.mul(tokenPrice).mul(1 ether).div(pTokenPrice.mul(mortgageAssets));
    }

    /// @dev Get real-time data of the current debt warehouse
    /// @param mortgageToken Mortgage asset address
    /// @param pToken PToken address
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param uTokenPrice Underlying asset price(1 ETH = ? Underlying asset)
    /// @param maxRateNum Maximum mortgage rate
    /// @param owner Debt owner
    /// @return fee Stability fee
    /// @return mortgageRate Real-time mortgage rate(Including stability fee)
    /// @return maxSubM The maximum amount of mortgage assets can be reduced
    /// @return maxAddP Maximum number of coins that can be added
    function getInfoRealTime(address mortgageToken, 
                             address pToken, 
                             uint256 tokenPrice, 
                             uint256 uTokenPrice,
                             uint256 maxRateNum,
                             uint256 owner) public view returns(uint256 fee, 
                                                                uint256 mortgageRate, 
                                                                uint256 maxSubM, 
                                                                uint256 maxAddP) {
        PersonalLedger memory pLedger = ledger[pToken][mortgageToken][address(owner)];
        if (pLedger.mortgageAssets == 0 && pLedger.parassetAssets == 0) {
            return (0,0,0,0);
        }
        uint256 pTokenPrice = getDecimalConversion(pTokenToUnderlying[pToken], uTokenPrice, pToken);
        uint256 tokenPriceAmount = tokenPrice;
        fee = getFee(pLedger.parassetAssets, pLedger.blockHeight, pLedger.rate, getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPriceAmount, pTokenPrice));
        mortgageRate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets.add(fee), tokenPriceAmount, pTokenPrice);
        uint256 maxRateEther = maxRateNum.mul(0.01 ether);
        if (mortgageRate >= maxRateEther) {
            maxSubM = 0;
            maxAddP = 0;
        } else {
            maxSubM = pLedger.mortgageAssets.sub(pLedger.parassetAssets.mul(tokenPriceAmount).mul(1 ether).div(maxRateEther.mul(pTokenPrice)));
            maxAddP = pLedger.mortgageAssets.mul(pTokenPrice).mul(maxRateEther).div(uint256(1 ether).mul(tokenPriceAmount)).sub(pLedger.parassetAssets);
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

    /// @dev View debt warehouse data
    /// @param pToken pToken address
    /// @param mortgageToken mortgage asset address
    /// @param owner debt owner
    /// @return mortgageAssets amount of mortgaged assets
    /// @return parassetAssets amount of debt(Ptoken,Stability fee not included)
    /// @return blockHeight the block height of the last operation
    /// @return rate Mortgage rate(Initial mortgage rate,Mortgage rate after the last operation)
    /// @return created is it created
    function getLedger(address pToken, 
    	               address mortgageToken,
                       address owner) public view returns(uint256 mortgageAssets, 
    		                                              uint256 parassetAssets, 
    		                                              uint256 blockHeight,
                                                          uint256 rate,
                                                          bool created) {
    	PersonalLedger memory pLedger = ledger[pToken][mortgageToken][address(owner)];
    	return (pLedger.mortgageAssets, pLedger.parassetAssets, pLedger.blockHeight, pLedger.rate, pLedger.created);
    }

    /// @dev View governance address
    /// @return governance address
    function getGovernance() external view returns(address) {
        return governance;
    }

    /// @dev View insurance pool address
    /// @return insurance pool address
    function getInsurancePool() external view returns(address) {
        return address(insurancePool);
    }

    /// @dev View the market base interest rate
    /// @return market base interest rate
    function getR0() external view returns(uint256) {
    	return r0;
    }

    /// @dev View the amount of blocks produced in a year
    /// @return amount of blocks produced in a year
    function getOneYear() external view returns(uint256) {
    	return oneYear;
    }

    /// @dev View the maximum mortgage rate
    /// @param mortgageToken Mortgage asset address
    /// @return maximum mortgage rate
    function getMaxRate(address mortgageToken) external view returns(uint256) {
    	return maxRate[mortgageToken];
    }

    /// @dev View the liquidation line
    /// @param mortgageToken Mortgage asset address
    /// @return liquidation line
    function getLiquidationLine(address mortgageToken) external view returns(uint256) {
        return liquidationLine[mortgageToken];
    }

    /// @dev View the priceController contract address
    /// @return priceController contract address
    function getPriceController() external view returns(address) {
        return address(quary);
    }

    /// @dev View the ptoken address according to the underlying asset
    /// @param uToken Underlying asset address
    /// @return ptoken address
    function getUnderlyingToPToken(address uToken) external view returns(address) {
        return underlyingToPToken[uToken];
    }

    /// @dev View the underlying asset according to the ptoken address
    /// @param pToken ptoken address
    /// @return underlying asset
    function getPTokenToUnderlying(address pToken) external view returns(address) {
        return pTokenToUnderlying[pToken];
    }

    /// @dev View the debt array length
    /// @param pToken ptoken address
    /// @param mortgageToken mortgage asset address
    /// @return debt array length
    function getLedgerArrayNum(address pToken, 
                               address mortgageToken) external view returns(uint256) {
        return ledgerArray[pToken][mortgageToken].length;
    }

    /// @dev View the debt owner
    /// @param pToken ptoken address
    /// @param mortgageToken mortgage asset address
    /// @param index array subscript
    /// @return debt owner
    function getLedgerAddress(address pToken, 
                              address mortgageToken, 
                              uint256 index) external view returns(address) {
        return ledgerArray[pToken][mortgageToken][index];
    }

    //---------governance----------

    /// @dev Set contract status
    /// @param num 0: pause, 1: active, 2: out only
    function setFlag(uint8 num) public onlyGovernance {
        flag = num;
    }

    /// @dev Allow asset mortgage to generate ptoken
    /// @param pToken ptoken address
    /// @param mortgageToken mortgage asset address
    /// @param allow allow mortgage
    function setMortgageAllow(address pToken, 
    	                      address mortgageToken, 
    	                      bool allow) public onlyGovernance {
    	mortgageAllow[pToken][mortgageToken] = allow;
    }

    /// @dev Set insurance pool contract
    /// @param add insurance pool contract
    function setInsurancePool(address add) public onlyGovernance {
        insurancePool = IInsurancePool(add);
    }

    /// @dev Set market base interest rate
    /// @param num market base interest rate(num = ? * 1 ether)
    function setR0(uint256 num) public onlyGovernance {
    	r0 = num;
    }

    /// @dev Set the amount of blocks produced in a year
    /// @param num amount of blocks produced in a year
    function setOneYear(uint256 num) public onlyGovernance {
    	oneYear = num;
    }

    /// @dev Set liquidation line
    /// @param mortgageToken mortgage asset address
    /// @param num liquidation line(num = ? * 100)
    function setLiquidationLine(address mortgageToken, 
                                uint256 num) public onlyGovernance {
        liquidationLine[mortgageToken] = num.mul(0.01 ether);
    }

    /// @dev Set the maximum mortgage rate
    /// @param mortgageToken mortgage asset address
    /// @param num maximum mortgage rate(num = ? * 100)
    function setMaxRate(address mortgageToken, 
                        uint256 num) public onlyGovernance {
    	maxRate[mortgageToken] = num.mul(0.01 ether);
    }

    /// @dev Set priceController contract address
    /// @param add priceController contract address
    function setPriceController(address add) public onlyGovernance {
        quary = IPriceController(add);
    }

    /// @dev Set the underlying asset and ptoken mapping and
    ///      Set the latest redemption time of ptoken insurance
    /// @param uToken underlying asset address
    /// @param pToken ptoken address
    function setInfo(address uToken, 
                     address pToken) public onlyGovernance {
        require(underlyingToPToken[uToken] == address(0x0), "Log:MortgagePool:underlyingToPToken");
        require(address(insurancePool) != address(0x0), "Log:MortgagePool:0x0");
        underlyingToPToken[uToken] = address(pToken);
        pTokenToUnderlying[address(pToken)] = uToken;
        insurancePool.setLatestTime(uToken);
    }

    //---------transaction---------

    /// @dev Set governance address
    function setGovernance() public {
        governance = pTokenFactory.getGovernance();
        require(governance != address(0x0), "Log:MortgagePool:0x0");
    }

    /// @dev Mortgage asset casting ptoken
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param amount amount of mortgaged assets
    /// @param rate custom mortgage rate
    function coin(address mortgageToken, 
                  address pToken, 
                  uint256 amount, 
                  uint256 rate) public payable whenActive nonReentrant {

    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        require(rate > 0 && rate <= maxRate[mortgageToken], "Log:MortgagePool:rate!=0");
        require(amount > 0, "Log:MortgagePool:amount!=0");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], uint256(msg.value).sub(amount));
        }

        // Calculate the stability fee
        uint256 blockHeight = pLedger.blockHeight;
        uint256 fee = 0;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
            // The stability fee is transferred to the insurance pool
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // Eliminate negative accounts
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}

        // Additional ptoken issuance
        uint256 pTokenAmount = amount.mul(pTokenPrice).mul(rate).div(tokenPrice.mul(100));
        PToken(pToken).issuance(pTokenAmount, address(msg.sender));

        // Update debt information
        pLedger.mortgageAssets = mortgageAssets.add(amount);
        pLedger.parassetAssets = parassetAssets.add(pTokenAmount);
        pLedger.blockHeight = block.number;
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);

        // Tag created
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }
    
    /// @dev Increase mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param amount amount of mortgaged assets
    function supplement(address mortgageToken, 
                        address pToken, 
                        uint256 amount) public payable outOnly nonReentrant {

    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(pLedger.created, "Log:MortgagePool:!created");

    	// Get the price and transfer to the mortgage token
        uint256 tokenPrice;
        uint256 pTokenPrice;
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], uint256(msg.value).sub(amount));
        }

        // Calculate the stability fee
        uint256 blockHeight = pLedger.blockHeight;
        uint256 fee = 0;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
            // The stability fee is transferred to the insurance pool
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // Eliminate negative accounts
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets.add(amount);
    	pLedger.blockHeight = block.number;
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
    }

    /// @dev Reduce mortgage assets
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param amount amount of mortgaged assets
    function decrease(address mortgageToken, 
                      address pToken, 
                      uint256 amount) public payable outOnly nonReentrant {

    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");
        require(pLedger.created, "Log:MortgagePool:!created");

    	// Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);

        // Calculate the stability fee
        uint256 blockHeight = pLedger.blockHeight;
        uint256 fee = 0;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
            // The stability fee is transferred to the insurance pool
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // Eliminate negative accounts
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}

        // Update debt information
    	pLedger.mortgageAssets = mortgageAssets.sub(amount);
    	pLedger.blockHeight = block.number;
        pLedger.rate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);

        // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
    	require(pLedger.rate <= maxRate[mortgageToken], "Log:MortgagePool:!maxRate");

    	// Transfer out mortgage assets
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), amount);
    	} else {
            TransferHelper.safeTransferETH(address(msg.sender), amount);
    	}
    }

    /// @dev Increase debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param amount amount of debt
    function increaseCoinage(address mortgageToken,
                             address pToken,
                             uint256 amount) public payable whenActive nonReentrant {

        require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        require(amount > 0, "Log:MortgagePool:!amount");
        PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(pLedger.created, "Log:MortgagePool:!created");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);

        // Calculate the stability fee
        uint256 blockHeight = pLedger.blockHeight;
        uint256 fee = 0;
        if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
            // The stability fee is transferred to the insurance pool
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // Eliminate negative accounts
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
        }

        // Update debt information
        pLedger.parassetAssets = parassetAssets.add(amount);
        pLedger.blockHeight = block.number;
        pLedger.rate = getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);

        // The debt warehouse mortgage rate cannot be greater than the maximum mortgage rate
        require(pLedger.rate <= maxRate[mortgageToken], "Log:MortgagePool:!maxRate");

        // Additional ptoken issuance
        PToken(pToken).issuance(amount, address(msg.sender));
    }

    /// @dev Reduce debt (increase coinage)
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param amount amount of debt
    function reducedCoinage(address mortgageToken,
                            address pToken,
                            uint256 amount) public payable outOnly nonReentrant {

        require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        address uToken = pTokenToUnderlying[pToken];
        require(amount > 0 && amount <= parassetAssets, "Log:MortgagePool:!amount");
        require(pLedger.created, "Log:MortgagePool:!created");

        // Get the price
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, uToken, msg.value);

        // Calculate the stability fee
        uint256 blockHeight = pLedger.blockHeight;
        uint256 fee = 0;
        if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate, getMortgageRate(mortgageAssets, parassetAssets, tokenPrice, pTokenPrice));
            // The stability fee is transferred to the insurance pool
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), amount.add(fee));
            // Eliminate negative accounts
            insurancePool.eliminate(pToken, uToken);
            emit FeeValue(pToken, fee);
        }

        // Update debt information
        pLedger.parassetAssets = parassetAssets.sub(amount);
        pLedger.blockHeight = block.number;
        pLedger.rate = getMortgageRate(mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);

        // Destroy ptoken
        insurancePool.destroyPToken(pToken, amount, uToken);
    }

    /// @dev Liquidation of debt
    /// @param mortgageToken mortgage asset address
    /// @param pToken ptoken address
    /// @param account debt owner address
    /// @param amount amount of mortgaged assets
    function liquidation(address mortgageToken, 
                         address pToken,
                         address account,
                         uint256 amount) public payable outOnly nonReentrant {

    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][account];
        require(pLedger.created, "Log:MortgagePool:!created");
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        require(amount > 0 && amount <= mortgageAssets, "Log:MortgagePool:!amount");

    	// Get the price
        address uToken = pTokenToUnderlying[pToken];
    	(uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, uToken, msg.value);
        
        // Judging the liquidation line
        checkLine(pLedger, tokenPrice, pTokenPrice, mortgageToken);

        // Calculate the amount of ptoken
        uint256 pTokenAmount = amount.mul(pTokenPrice).mul(90).div(tokenPrice.mul(100));
    	// Transfer to ptoken
    	ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), pTokenAmount);

    	// Eliminate negative accounts
        insurancePool.eliminate(pToken, uToken);

        // Calculate the debt for destruction
        uint256 offset = parassetAssets.mul(amount).div(mortgageAssets);

        // Destroy ptoken
    	insurancePool.destroyPToken(pToken, offset, uToken);

    	// Update debt information
    	pLedger.mortgageAssets = mortgageAssets.sub(amount);
        pLedger.parassetAssets = parassetAssets.sub(offset);
        // MortgageAssets liquidation, mortgage rate and block number are not updated
        if (pLedger.mortgageAssets == 0) {
            pLedger.parassetAssets = 0;
            pLedger.blockHeight = 0;
            pLedger.rate = 0;
        }

    	// Transfer out mortgage asset
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), amount);
    	} else {
            TransferHelper.safeTransferETH(address(msg.sender), amount);
    	}
    }

    /// @dev Check the liquidation line
    /// @param pLedger debt warehouse ledger
    /// @param tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @param pTokenPrice PToken price(1 ETH = ? pToken)
    /// @param mortgageToken mortgage asset address
    function checkLine(PersonalLedger memory pLedger, 
                       uint256 tokenPrice, 
                       uint256 pTokenPrice, 
                       address mortgageToken) private view {
        uint256 parassetAssets = pLedger.parassetAssets;
        uint256 mortgageAssets = pLedger.mortgageAssets;
        // The current mortgage rate cannot exceed the liquidation line
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        uint256 fee = 0;
        if (parassetAssets > 0 && block.number > pLedger.blockHeight && pLedger.blockHeight != 0) {
            fee = getFee(parassetAssets, pLedger.blockHeight, pLedger.rate, mortgageRate);
        }
        require(getMortgageRate(mortgageAssets, parassetAssets.add(fee), tokenPrice, pTokenPrice) > liquidationLine[mortgageToken], "Log:MortgagePool:!liquidationLine");
    }

    /// @dev Get price
    /// @param mortgageToken mortgage asset address
    /// @param uToken underlying asset address
    /// @param priceValue price fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(address mortgageToken, 
                               address uToken,
                               uint256 priceValue) private returns (uint256 tokenPrice, 
                                                                    uint256 pTokenPrice) {
        (tokenPrice, pTokenPrice) = quary.getPriceForPToken{value:priceValue}(mortgageToken, uToken, msg.sender);   
    }


    // function takeOutERC20(address token, uint256 amount, address to) public onlyGovernance {
    //     ERC20(token).safeTransfer(address(to), amount);
    // }

    // function takeOutETH(uint256 amount, address to) public onlyGovernance {
    //     TransferHelper.safeTransferETH(address(to), amount);
    // }

}
/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// File: iface/IPriceController.sol

pragma solidity ^0.6.12;

interface IPriceController {
    function getPriceForPToken(address token, address uToken, address pToken, address payback) external payable returns (uint256 tokenPrice, uint256 pTokenPrice);
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
// File: lib/AddressPayable.sol

pragma solidity ^0.6.12;

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
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

    modifier onlyPool()
    {
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

    function allowance(address owner, address spender) override public view returns (uint256) 
    {
        return _allowed[owner][spender];
    }

    //---------transaction---------

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

contract MortgagePool {
	using SafeMath for uint256;
	using address_make_payable for address;
	using SafeERC20 for ERC20;

    // 管理员地址
	address public governance;
	// 标的资产地址=>p资产地址
	mapping(address=>address) public underlyingToPToken;
	// p资产地址=>标的资产地址
	mapping(address=>address) public pTokenToUnderlying;
    // p资产地址=>抵押资产地址=>bool
	mapping(address=>mapping(address=>bool)) mortgageAllow;
    // p资产=>抵押资产=>用户地址=>债仓数据
	mapping(address=>mapping(address=>mapping(address=>PersonalLedger))) ledger;
    // p资产=>抵押资产=>创建过债仓的地址
    mapping(address=>mapping(address=>address[])) ledgerArray;
    // 抵押资产=>最高抵押率
    mapping(address=>uint256) maxRate;
    // 抵押资产=>平仓线
    mapping(address=>uint256) line;
    // 价格合约
    IPriceController quary;
    // 保险池合约
    IInsurancePool insurancePool;
    // 工厂合约地址
    IPTokenFactory pTokenFactory;
	// 市场基础利率，年化2%
	uint256 r0 = 0.02 ether;
	// 一年的出块量
	uint256 oneYear = 2400000;
    // 状态
    uint8 public flag;      // = 0: 停止
                            // = 1: 启动
                            // = 2: 只能全部赎回

	struct PersonalLedger {
        uint256 mortgageAssets;         // 抵押资产数量
        uint256 parassetAssets;         // P资产
        uint256 blockHeight;            // 上次操作区块高度
        uint256 rate;                   // 抵押率
        bool created;
    }

    event FeeValue(address pToken, uint256 value);

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

    modifier onleRedemptionAll {
        require(flag != 0, "Log:MortgagePool:!active");
        _;
    }

    //---------view---------

    // 计算稳定费
    // parassetAssets:债务资产数量
    // blockHeight:上次操作区块
    // rate:抵押率
    function getFee(uint256 parassetAssets, 
    	            uint256 blockHeight,
    	            uint256 rate) public view returns(uint256) {
        uint256 topOne = parassetAssets.mul(r0).mul(block.number.sub(blockHeight));
        uint256 topTwo = parassetAssets.mul(r0).mul(block.number.sub(blockHeight)).mul(uint256(3).mul(rate));
    	uint256 bottom = oneYear.mul(1 ether);
    	return topOne.div(bottom).add(topTwo.div(bottom.mul(1 ether)));
    }

    // 计算抵押率
    // mortgageAssets:抵押资产数量
    // parassetAssets:债务资产数量
    // tokenPrice:抵押资产价格数量
    // pTokenPrice:p资产价格数量
    function getMortgageRate(uint256 mortgageAssets,
    	                     uint256 parassetAssets, 
    	                     uint256 tokenPrice, 
    	                     uint256 pTokenPrice) public pure returns(uint256) {
        if (mortgageAssets == 0 || pTokenPrice == 0) {
            return 0;
        }
    	return parassetAssets.mul(tokenPrice).mul(1 ether).div(pTokenPrice.mul(mortgageAssets));
    }

    // 获取当前债仓实时数据
    // mortgageToken:抵押资产地址
    // pToken:平行资产地址
    // tokenPrice:抵押资产价格数量
    // uTokenPrice:标的资产价格数量
    // maxRateNum:计算参照的最大抵押率
    // owner:查询用户地址
    // 返回：稳定费、抵押率、最大可减少抵押资产数量、最大可新增铸币数量
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
        fee = getFee(pLedger.parassetAssets, pLedger.blockHeight, pLedger.rate);
        uint256 tokenPriceAmount = tokenPrice;
        uint256 pTokenPrice = getDecimalConversion(pTokenToUnderlying[pToken], uTokenPrice, pToken);
        mortgageRate = getMortgageRate(pLedger.mortgageAssets, 
                                               pLedger.parassetAssets.add(fee), 
                                               tokenPriceAmount,
                                               pTokenPrice);
        uint256 maxRateEther = maxRateNum.mul(0.01 ether);
        if (mortgageRate >= maxRateEther) {
            maxSubM = 0;
            maxAddP = 0;
        } else {
            maxSubM = pLedger.mortgageAssets.sub(pLedger.parassetAssets.add(fee).mul(tokenPriceAmount).mul(1 ether).div(maxRateEther.mul(pTokenPrice)));
            maxAddP = pLedger.mortgageAssets.mul(pTokenPrice).mul(maxRateEther).div(uint256(1 ether).mul(tokenPriceAmount)).sub(pLedger.parassetAssets.add(fee));
        }
    }
    
    // 小数转换
    // inputToken:输入资产地址
    // inputTokenAmount:输入资产数量
    // outputToken:输出资产地址
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

    // 查看债仓数据
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

    // 查看管理员地址
    function getGovernance() public view returns(address) {
        return governance;
    }

    // 查看保险池地址
    function getInsurancePool() public view returns(address) {
        return address(insurancePool);
    }

    // 查看市场基础利率
    function getR0() public view returns(uint256) {
    	return r0;
    }

    // 查看一年的出块量
    function getOneYear() public view returns(uint256) {
    	return oneYear;
    }

    // 查看最高抵押率
    function getMaxRate(address mortgageToken) public view returns(uint256) {
    	return maxRate[mortgageToken];
    }

    // 查看平仓线
    function getLine(address mortgageToken) public view returns(uint256) {
        return line[mortgageToken];
    }

    // 查看价格合约地址
    function getPriceController() public view returns(address) {
        return address(quary);
    }

    // 根据标的资产查看p资产地址
    function getUnderlyingToPToken(address uToken) public view returns(address) {
        return underlyingToPToken[uToken];
    }

    // 根据p资产查看标的资产地址
    function getPTokenToUnderlying(address pToken) public view returns(address) {
        return pTokenToUnderlying[pToken];
    }

    // 债仓数组长度
    function getLedgerArrayNum(address pToken, 
                               address mortgageToken) public view returns(uint256) {
        return ledgerArray[pToken][mortgageToken].length;
    }

    // 查看创建债仓地址
    function getLedgerAddress(address pToken, 
                              address mortgageToken, 
                              uint256 index) public view returns(address) {
        return ledgerArray[pToken][mortgageToken][index];
    }

    //---------governance----------

    // 设置状态
    function setFlag(uint8 num) public onlyGovernance {
        flag = num;
    }

    // p资产允许抵押的Token
    // pToken:p资产地址
    // mortgageToken:抵押资产地址
    // allow:是否允许抵押
    function setMortgageAllow(address pToken, 
    	                      address mortgageToken, 
    	                      bool allow) public onlyGovernance {
    	mortgageAllow[pToken][mortgageToken] = allow;
    }

    // 设置保险池合约
    function setInsurancePool(address add) public onlyGovernance {
        insurancePool = IInsurancePool(add);
    }

    // 设置市场基础利率
    function setR0(uint256 num) public onlyGovernance {
    	r0 = num;
    }

    // 设置一年的出块量
    function setOneYear(uint256 num) public onlyGovernance {
    	oneYear = num;
    }

    // 设置平仓线
    function setLine(address mortgageToken, 
                     uint256 num) public onlyGovernance {
        line[mortgageToken] = num.mul(0.01 ether);
    }

    // 设置最高抵押率
    function setMaxRate(address token, 
                        uint256 num) public onlyGovernance {
    	maxRate[token] = num.mul(0.01 ether);
    }

    // 设置价格合约地址
    function setPriceController(address add) public onlyGovernance {
        quary = IPriceController(add);
    }

    // 设置p资产与标的资产、设置保险池
    // token:P资产对应的标的资产，如USDT、ETH
    // pToken:P资产地址
    function setInfo(address token, 
                     address pToken) public onlyGovernance {
        require(underlyingToPToken[token] == address(0x0), "Log:MortgagePool:underlyingToPToken");
        require(address(insurancePool) != address(0x0), "Log:MortgagePool:0x0");
        underlyingToPToken[token] = address(pToken);
        pTokenToUnderlying[address(pToken)] = token;
        insurancePool.setLatestTime(token);
    }

    //---------transaction---------

    // 设置管理员
    function setGovernance() public {
        governance = pTokenFactory.getGovernance();
        require(governance != address(0x0), "Log:MortgagePool:0x0");
    }
    
    // 铸币、再铸币
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // amount:抵押资产数量
    // rate:抵押率
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function coin(address mortgageToken, 
                  address pToken, 
                  uint256 amount, 
                  uint256 rate) public payable whenActive {
    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        require(rate > 0, "Log:MortgagePool:rate!=0");
        require(amount > 0, "Log:MortgagePool:amount!=0");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
    	// 获取价格
        uint256 tokenPrice;
        uint256 pTokenPrice;
        // 转入抵押token
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], uint256(msg.value).sub(amount));
        }
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // 消除负账户
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}
        // 计算铸币资产，增发P资产
        uint256 pTokenAmount = amount.mul(pTokenPrice).mul(rate).div(tokenPrice.mul(100));
        PToken(pToken).issuance(pTokenAmount, address(msg.sender));
        pLedger.mortgageAssets = pLedger.mortgageAssets.add(amount);
        pLedger.parassetAssets = parassetAssets.add(pTokenAmount);
        pLedger.blockHeight = block.number;
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        require(mortgageRate <= maxRate[mortgageToken], "Log:MortgagePool:!maxRate");
        pLedger.rate = mortgageRate;
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }
    
    // 新增抵押
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // amount:抵押资产数量
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function supplement(address mortgageToken, 
                        address pToken, 
                        uint256 amount) public payable whenActive {
    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
    	// 获取价格
        uint256 tokenPrice;
        uint256 pTokenPrice;
        // 转入抵押token
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransferFrom(address(msg.sender), address(this), amount);
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        } else {
            require(msg.value >= amount, "Log:MortgagePool:!msg.value");
            (tokenPrice, pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], uint256(msg.value).sub(amount));
        }
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // 消除负账户
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}
    	pLedger.mortgageAssets = pLedger.mortgageAssets.add(amount);
    	pLedger.blockHeight = block.number;
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        pLedger.rate = mortgageRate;
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }

    // 提取资产
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // amount:抵押资产数量
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function decrease(address mortgageToken, 
                      address pToken, 
                      uint256 amount) public payable whenActive {
    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
    	// 获取价格
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // 消除负账户
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
    	}
    	pLedger.mortgageAssets = pLedger.mortgageAssets.sub(amount);
    	pLedger.blockHeight = block.number;
    	uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
        pLedger.rate = mortgageRate;
    	require(mortgageRate <= maxRate[mortgageToken], "Log:MortgagePool:!maxRate");
    	// 转出抵押token
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), amount);
    	} else {
    		payEth(address(msg.sender), amount);
    	}
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }

    // 新增铸币
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // amount:新增铸币数量
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function increaseCoinage(address mortgageToken,
                             address pToken,
                             uint256 amount) public payable whenActive {
        require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        require(pLedger.created, "Log:MortgagePool:!created");
        // 获取价格
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, pTokenToUnderlying[pToken], msg.value);
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
        if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), fee);
            // 消除负账户
            insurancePool.eliminate(pToken, pTokenToUnderlying[pToken]);
            emit FeeValue(pToken, fee);
        }
        pLedger.parassetAssets = parassetAssets.add(amount);
        pLedger.blockHeight = block.number;
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        pLedger.rate = mortgageRate;
        require(mortgageRate <= maxRate[mortgageToken], "Log:MortgagePool:!maxRate");
        PToken(pToken).issuance(amount, address(msg.sender));
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }

    // 减少铸币
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // amount:减少铸币数量
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function reducedCoinage(address mortgageToken,
                            address pToken,
                            uint256 amount) public payable whenActive {
        require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        address uToken = pTokenToUnderlying[pToken];
        // 获取价格
        (uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, uToken, msg.value);
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
        if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), amount.add(fee));
            // 消除负账户
            insurancePool.eliminate(pToken, uToken);
            emit FeeValue(pToken, fee);
        }
        pLedger.parassetAssets = parassetAssets.sub(amount);
        pLedger.blockHeight = block.number;
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, pLedger.parassetAssets, tokenPrice, pTokenPrice);
        pLedger.rate = mortgageRate;
        // 销毁p资产
        insurancePool.destroyPToken(pToken, amount, uToken);
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }

    // 赎回全部抵押
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // 注意：mortgageToken为0X0时，抵押资产为ETH。
    function redemptionAll(address mortgageToken, 
                           address pToken) public onleRedemptionAll {
        require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
        PersonalLedger storage pLedger = ledger[pToken][mortgageToken][address(msg.sender)];
        require(pLedger.created, "Log:MortgagePool:!created");
        address uToken = pTokenToUnderlying[pToken];
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
        if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            // 结算稳定费
            uint256 fee = getFee(parassetAssets, blockHeight, pLedger.rate);
            // 转入p资产
            ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), parassetAssets.add(fee));
            // 消除负账户
            insurancePool.eliminate(pToken, uToken);
            emit FeeValue(pToken, fee);
        }
        // 销毁p资产
        insurancePool.destroyPToken(pToken, parassetAssets, uToken);
        // 更新信息
        uint256 mortgageAssetsAmount = pLedger.mortgageAssets;
        pLedger.mortgageAssets = 0;
        pLedger.parassetAssets = 0;
        pLedger.blockHeight = 0;
        pLedger.rate = 0;
        // 转出抵押资产
        if (mortgageToken != address(0x0)) {
            ERC20(mortgageToken).safeTransfer(address(msg.sender), mortgageAssetsAmount);
        } else {
            payEth(address(msg.sender), mortgageAssetsAmount);
        }
        if (pLedger.created == false) {
            ledgerArray[pToken][mortgageToken].push(address(msg.sender));
            pLedger.created = true;
        }
    }

    // 清算
    // mortgageToken:抵押资产地址
    // pToken:p资产地址
    // account:债仓账户地址
    // 注意：mortgageToken为0X0时，抵押资产为ETH
    function liquidation(address mortgageToken, 
                         address pToken,
                         address account) public payable whenActive {
    	require(mortgageAllow[pToken][mortgageToken], "Log:MortgagePool:!mortgageAllow");
    	PersonalLedger storage pLedger = ledger[pToken][mortgageToken][account];
        require(pLedger.created, "Log:MortgagePool:!created");
    	// 调用预言机，计算p资产数量
        address uToken = pTokenToUnderlying[pToken];
    	(uint256 tokenPrice, uint256 pTokenPrice) = getPriceForPToken(mortgageToken, uToken, msg.value);
    	uint256 pTokenAmount = pLedger.mortgageAssets.mul(pTokenPrice).mul(90).div(tokenPrice.mul(100));
    	// 计算稳定费
    	uint256 fee = 0;
        uint256 blockHeight = pLedger.blockHeight;
        uint256 parassetAssets = pLedger.parassetAssets;
    	if (parassetAssets > 0 && block.number > blockHeight && blockHeight != 0) {
            fee = getFee(parassetAssets, blockHeight, pLedger.rate);
    	}
        uint256 mortgageRate = getMortgageRate(pLedger.mortgageAssets, parassetAssets, tokenPrice, pTokenPrice);
    	require(mortgageRate > line[mortgageToken], "Log:MortgagePool:!line");
    	// 转入P资产
    	ERC20(pToken).safeTransferFrom(address(msg.sender), address(insurancePool), pTokenAmount);
    	// 消除负账户
        insurancePool.eliminate(pToken, uToken);
        // 销毁p资产
    	insurancePool.destroyPToken(pToken, parassetAssets, uToken);
    	// 更新信息
    	uint256 mortgageAssets = pLedger.mortgageAssets;
    	pLedger.mortgageAssets = 0;
        pLedger.parassetAssets = 0;
        pLedger.blockHeight = 0;
        pLedger.rate = 0;
    	// 转移抵押资产
    	if (mortgageToken != address(0x0)) {
    		ERC20(mortgageToken).safeTransfer(address(msg.sender), mortgageAssets);
    	} else {
    		payEth(address(msg.sender), mortgageAssets);
    	}
    }

    // 转ETH
    // account:转账目标地址
    // asset:资产数量
    function payEth(address account, 
                    uint256 asset) private {
        address payable add = account.make_payable();
        add.transfer(asset);
    }

    // 获取价格
    // token:抵押资产地址
    // uToken:标的资产地址
    // priceValue:价格费用
    // tokenPrice:抵押资产Token数量
    // pTokenPrice:p资产Token数量
    function getPriceForPToken(address token, 
                               address uToken,
                               uint256 priceValue) private returns (uint256 tokenPrice, 
                                                                    uint256 pTokenPrice) {
        (tokenPrice, pTokenPrice) = quary.getPriceForPToken{value:priceValue}(token, uToken, underlyingToPToken[uToken], msg.sender);   
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later

/**
 * Created on 2021-10-09 00:00
 * @summary: 
 * @author: journey
 */
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {MathSqrt} from "../utils/Sqrt.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MetaSoldierToken} from "../token_msd/MetaSoldierToken.sol";

/**
 * Types bool 可能的取值为字面常数值 true 和 false 
 * int/uint 分别表示有符号和无符号的不同位数的整型变量。 支持关键字 uint8 到 uint256 （无符号，从 8 位到 256 位）以及 int8 到 int256，以 8 位为步长递增。 uint 和 int 分别是 uint256 和 int256 的别名。
 * 比较运算符： <= ， < ， == ， != ， >= ， > （返回布尔值）
 * 位运算符： & ， | ， ^ （异或）， ~ （位取反）
 * 算数运算符： + ， - ， 一元运算 - ， 一元运算 + ， * ， / ， % （取余） ， ** （幂）， << （左移位） ， >> （右移位）
 * Solidity 还没有完全支持定长浮点型。可以声明定长浮点型的变量，但不能给它们赋值或把它们赋值给其他变量。。
 * fixed / ufixed：表示各种大小的有符号和无符号的定长浮点型。 在关键字 ufixedMxN 和 fixedMxN 中，M 表示该类型占用的位数，N 表示可用的小数位数。 M 必须能整除 8，即 8 到 256 位。 N 则可以是从 0 到 80 之间的任意数。 ufixed 和 fixed 分别是 ufixed128x19 和 fixed128x19 的别名。
 * 浮点型（在许多语言中的 float 和 double 类型，更准确地说是 IEEE 754 类型）和定长浮点型之间最大的不同点是， 在前者中整数部分和小数部分（小数点后的部分）需要的位数是灵活可变的，而后者中这两部分的长度受到严格的规定。 一般来说，在浮点型中，几乎整个空间都用来表示数字，但只有少数的位来表示小数点的位置。
 * address：地址类型存储一个 20 字节的值（以太坊地址的大小）。 地址类型也有成员变量，并作为所有合约的基础。
 * balance 和 transfer 可以使用 balance 属性来查询一个地址的余额， 也可以使用 transfer 函数向一个地址发送 以太币Ether （以 wei 为单位）：
 * 1 == 1 seconds
 * 1 minutes == 60 seconds
 * 1 hours == 60 minutes
 * 1 days == 24 hours
 * 1 weeks == 7 days
 * 1 years == 365 days  years 后缀已经不推荐使用了，因为从 0.5.0 版本开始将不再支持。
 * block.blockhash(uint blockNumber) returns (bytes32)：指定区块的区块哈希——仅可用于最新的 256 个区块且不包括当前区块；而 blocks 从 0.4.22 版本开始已经不推荐使用，由 blockhash(uint blockNumber) 代替
 * block.coinbase (address): 挖出当前区块的矿工地址
 * block.difficulty (uint): 当前区块难度
 * block.gaslimit (uint): 当前区块 gas 限额
 * block.number (uint): 当前区块号
 * block.timestamp (uint): 自 unix epoch 起始当前区块以秒计的时间戳
 * gasleft() returns (uint256)：剩余的 gas
 * msg.data (bytes): 完整的 calldata
 * msg.gas (uint): 剩余 gas - 自 0.4.21 版本开始已经不推荐使用，由 gesleft() 代替
 * msg.sender (address): 消息发送者（当前调用）
 * msg.sig (bytes4): calldata 的前 4 字节（也就是函数标识符）
 * msg.value (uint): 随消息发送的 wei 的数量
 * now (uint): 目前区块时间戳（block.timestamp）
 * tx.gasprice (uint): 交易的 gas 价格
 * tx.origin (address): 交易发起者（完全的调用链）
 * abi.encode(...) returns (bytes)： ABI - 对给定参数进行编码
 * abi.encodePacked(...) returns (bytes)：对给定参数执行 紧打包编码
 * abi.encodeWithSelector(bytes4 selector, ...) returns (bytes)： ABI - 对给定参数进行编码，并以给定的函数选择器作为起始的 4 字节数据一起返回
 * abi.encodeWithSignature(string signature, ...) returns (bytes)：等价于 abi.encodeWithSelector(bytes4(keccak256(signature), ...)
 * 这些编码函数可以用来构造函数调用数据，而不用实际进行调用。此外，keccak256(abi.encodePacked(a, b)) 是更准确的方法来计算在未来版本不推荐使用的 keccak256(a, b)。
 * assert(bool condition): 如果条件不满足，则使当前交易没有效果 — 用于检查内部错误。
 * require(bool condition): 如果条件不满足则撤销状态更改 - 用于检查由输入或者外部组件引起的错误。
 * require(bool condition, string message): 如果条件不满足则撤销状态更改 - 用于检查由输入或者外部组件引起的错误，可以同时提供一个错误消息。
 * revert(): 终止运行并撤销状态更改。
 * revert(string reason): 终止运行并撤销状态更改，可以同时提供一个解释性的字符串。
 * 数学和密码学函数
 * addmod(uint x, uint y, uint k) returns (uint): 计算 (x + y) % k，加法会在任意精度下执行，并且加法的结果即使超过 2**256 也不会被截取。从 0.5.0 版本的编译器开始会加入对 k != 0 的校验（assert）。
 * mulmod(uint x, uint y, uint k) returns (uint): 计算 (x * y) % k，乘法会在任意精度下执行，并且乘法的结果即使超过 2**256 也不会被截取。从 0.5.0 版本的编译器开始会加入对 k != 0 的校验（assert）。
 * keccak256(...) returns (bytes32): 计算 (tightly packed) arguments 的 Ethereum-SHA-3 （Keccak-256）哈希。
 * sha256(...) returns (bytes32): 计算 (tightly packed) arguments 的 SHA-256 哈希。
 * sha3(...) returns (bytes32): 等价于 keccak256。
 * ripemd160(...) returns (bytes20): 计算 (tightly packed) arguments 的 RIPEMD-160 哈希。
 * ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address) ： 利用椭圆曲线签名恢复与公钥相关的地址，错误返回零值。 (example usage)
 * 在一个私链上，你很有可能碰到由于 sha256、ripemd160 或者 ecrecover 引起的 Out-of-Gas。原因是因为这些密码学函数在以太坊虚拟机(EVM)中以“预编译合约”形式存在的，且在第一次收到消息后才被真正存在（尽管合约代码是EVM中已存在的硬编码）。因此发送到不存在的合约的消息非常昂贵，所以实际的执行会导致 Out-of-Gas 错误。在你实际使用你的合约之前，给每个合约发送一点儿以太币，比如 1 Wei。这在官方网络或测试网络上不是问题。
 * <address>.balance (uint256): 以 Wei 为单位的 地址类型 的余额。
 * <address>.transfer(uint256 amount): 向 地址类型 发送数量为 amount 的 Wei，失败时抛出异常，发送 2300 gas 的矿工费，不可调节。
 * <address>.send(uint256 amount) returns (bool): 向 地址类型 发送数量为 amount 的 Wei，失败时返回 false，发送 2300 gas 的矿工费用，不可调节。
 * <address>.call(...) returns (bool): 发出低级函数 CALL，失败时返回 false，发送所有可用 gas，可调节。
 * <address>.callcode(...) returns (bool)： 发出低级函数 CALLCODE，失败时返回 false，发送所有可用 gas，可调节。
 * <address>.delegatecall(...) returns (bool): 发出低级函数 DELEGATECALL，失败时返回 false，发送所有可用 gas，可调节。
 * selfdestruct(address recipient): 销毁合约，并把余额发送到指定 地址类型。
 * public：内部、外部均可见（参考为存储/状态变量创建 getter 函数）
 * private：仅在当前合约内可见
 * external：仅在外部可见（仅可修饰函数）——就是说，仅可用于消息调用（即使在合约内调用，也只能通过 this.func 的方式）
 * internal：仅在内部可见（也就是在当前 Solidity 源代码文件内均可见，不仅限于当前合约内，译者注）
 * 修改器
 * pure 修饰函数时：不允许修改或访问状态——但目前并不是强制的。
 * view 修饰函数时：不允许修改状态——但目前不是强制的。
 * payable 修饰函数时：允许从调用中接收 以太币Ether 。
 * constant 修饰状态变量时：不允许赋值（除初始化以外），不会占据 存储插槽storage slot 。
 * constant 修饰函数时：与 view 等价。
 * anonymous 修饰事件时：不把事件签名作为 topic 存储。
 * indexed 修饰事件时：将参数作为 topic 存储。
 **/

/**
 * @title: 聚沙成塔模型玩法
 */
/**
contract TemplateERC20Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address permintReceiptor_
    ) ERC20(name_, symbol_) {
        _mint(permintReceiptor_, totalSupply_);
    }
}
**/
struct PledgeRecord {
    uint256 createTime;
    uint256 amount;
}
/**
 * @dev: 轮次状态
 *
 **/
enum RoundState {
    None,
    OnPledge,
    OnWithdraw,
    OnRedeem,
    OnMove
}

struct Deposited {
    PledgeRecord[] records;
    RoundState state;
    uint256 totalStaked;
    uint256 rid;
    uint256 roundStartTime;
    uint256 roundEndTime;
}

struct RoundInfo {
    uint256 rid;
    uint256 startTime;
    uint256 endTime;
    uint256 totalShareCapital;
}

/**
 *  聚沙成塔模型
 *  预言机每天12点归还未连投的账户地址资产
 **/

contract Shata is MathSqrt, Ownable {
    using Arrays for uint256[];
    using Strings for *;
    using SafeMath for uint256;

	address public maker;
	address public oracle;
    uint256 public valid; // 拨付周期
    uint256 public number; // 
    uint256 public member; //
    uint256 public rate; //
    uint256 public curnumber; //
    uint256 public odds; // 周期环数
    uint256 public validFormat;  // valid format
    uint256 public releaseTime;

	mapping(uint256 => mapping(address => Deposited)) public depositedOf;// depositedOf

    mapping(uint256 => uint256) internal _roundTotalShareCapitalOf;

    mapping(uint256 => address[]) public tabulation; // 投资列表

    MetaSoldierToken public ShataUSD;
 /**   
 	TemplateERC20Token(
    "Many littles make a mickle",
    "Shata",
    10000000000e18,
    premintReceiptor
	)
	**/

    constructor(MetaSoldierToken msdToken_, address premintReceiptor)
    
    {
        maker = premintReceiptor;
        uint256 initvalid = 1;
        releaseTime = block.timestamp.div(1 days).mul(1 days).add(initvalid.mul(validFormat));
        valid = 10; // 每轮周期
        number = 1; // 定投数量
        member = 0; // 参透人次
        curnumber = 0; // 当前人次
        odds = 10; // 结算轮次
        validFormat = 60; // 每轮周期格式
        ShataUSD = msdToken_;
    }

	/** 
	 * 设置活动周期
	 * Just allow owner change valid
	 **/
    function setValid(uint256 time) external onlyOwner {
    	valid = time;
    }
    /**
     *
     * 设置执行合约
     **/
    function setToken(MetaSoldierToken _token) public {
        ShataUSD = _token;
    }

    /**
     *
     * 设置结算环线频率
     **/
    function setOdds(uint256 _odds) public {
        odds = _odds;
    }

    /**
     * 设置投资数量
     * Just allow owner change number
     **/
    function setNumber(uint256 _number) external onlyOwner {
    	number = _number;
    }
    /**
     * 设置周期类型
     * Just allow owner change validFormat
     **/
    function setFormat(uint256 _format) external onlyOwner {
    	validFormat = _format;
    }
    /**
     * 指定预言机处理地址
     * @param _oracle 预言机允许处理地址
     */
    function setOracle(address _oracle) external onlyOwner {
    	oracle = _oracle;
    }
    /**
 	 * 设置奖励比
 	 * Just allow owner change rate
     * @param _rate 奖金发放比例
     */
    function setRate(uint256 _rate) external onlyOwner {
    	rate = _rate;
    }
    
    /**
     * 设置上线时间
     * @param time 上线时间
     */
    function setReleaseTime(uint256 time) external onlyOwner {
    	releaseTime = time;
    }

	/**
	 * 查询指定时间的周期
	 *
     * @param time 轮次开始时间
     */
    function _roundInfomationOf(uint256 time)
    	public
        view
        returns (RoundInfo memory info)
    {
    	uint256 diffMonth = time.sub(releaseTime).div(valid.mul(validFormat));
    	return RoundInfo({
    		rid: diffMonth,
    		startTime: releaseTime.add(diffMonth.mul(valid).mul(validFormat)), // 发行时间 + 已完成轮次* 周期类型
    		endTime: releaseTime.add(diffMonth.add(1).mul(valid).mul(validFormat)), // 发行时间 + 已完成轮次*周期类型+1
    		totalShareCapital: _roundTotalShareCapitalOf[diffMonth]
    	});
    }

    
    /**
     *  参加活动
     * @param amount 投入数量
     */
    function transfer(uint256 amount)
    	public
    	virtual
    	returns (bool)
    {
        RoundInfo memory rinfo = _roundInfomationOf(block.timestamp);
        require(
            block.timestamp > rinfo.startTime &&
                block.timestamp < rinfo.endTime,
            "block.timestamp <= rinfo.startTime || block.timestamp >= rinfo.endTime"
        );
        require(amount > 0, "Provide Liquidity Is Zero");
        require(amount == number, "Fixed quota for each round of investment ");
        Deposited storage dep = depositedOf[rinfo.rid][msg.sender];
    	
        // 本轮次首次投入，写入基本数据
        if (dep.state == RoundState.None) {
            dep.state = RoundState.OnPledge;
            dep.totalStaked = amount;
            dep.rid = rinfo.rid;
            dep.roundStartTime = rinfo.startTime;
            dep.roundEndTime = rinfo.endTime;
	    	member = member.add(1);
	    	tabulation[rinfo.rid].push(payable(msg.sender));
	    	curnumber = curnumber.add(amount);
        }
        require(dep.state == RoundState.OnPledge, "StatusError");

        dep.records.push(
            PledgeRecord({createTime: block.timestamp, amount: amount})
        );
    	_roundTotalShareCapitalOf[rinfo.rid] = _roundTotalShareCapitalOf[rinfo.rid].add(amount);
    	ShataUSD.transferFrom(msg.sender, address(this), amount);
    }
	/**
	 *
	 * 预言机oracle奖励计算接口
	 * SafeMath: subtraction overflow
	 **/
    function withdraw() 
    	public
    	virtual
    	returns (bool)
	{
		/**
		 * 仅允许预言机账户执行提取操作
		 *
		 **/
		require(msg.sender == oracle, "deny access");
		// 取得当前轮次信息
		RoundInfo memory rinfo = _roundInfomationOf(block.timestamp);

		// 取得当前周期第一轮参与信息

		require(rinfo.rid >= odds, "The first cycle is not over");
		 
		Deposited storage dep = depositedOf[rinfo.rid.sub(odds).add(1)][msg.sender];
		/**
		 * 检查本周期是否已结束
		 * 
		 **/
		require(dep.state == RoundState.OnPledge, "StatusError");
		/**
		 *
		 * 总参与人次必须大于第一轮参与人数*周期
		 * 实现投资目标 结算收益
		 **/
		if(member >= tabulation[rinfo.rid.sub(odds).add(1)].length.mul(odds)){
			// 根据投资轮次用户列表进行结算

			for(uint256 i=0;i<tabulation[rinfo.rid.sub(odds).add(1)].length; i.add(1)){
				address Sender = tabulation[rinfo.rid.sub(odds).add(1)][i];
				uint256 total = _totalReward(Sender, rinfo.rid.sub(odds).add(1)); // 计算参与轮次的投入数量
				/**
				 * 当存量资金不足以支付时，报错回滚
				 *
				 **/
				require(address(ShataUSD).balance >= total, "The contract balance is insufficient to complete this transaction");
				ShataUSD.transfer(Sender, total);

				delete depositedOf[rinfo.rid.sub(odds).add(1)][Sender];
				delete tabulation[rinfo.rid.sub(odds).add(1)][i];
				member = member.sub(1);
			}
			
		}else{
			for(uint256 i=0;i<tabulation[rinfo.rid.sub(odds).add(1)].length; i.add(1)){
				address Sender = tabulation[rinfo.rid.sub(odds).add(1)][i];
				uint256 amount = 0;
				for(uint256 p = 0; p < depositedOf[rinfo.rid.sub(odds).add(1)][Sender].records.length; p.add(1)){
					amount = amount.add(depositedOf[rinfo.rid.sub(odds).add(1)][Sender].records[p].amount);
				}
				/**
				 * 当存量资金不足以支付时，报错回滚
				 *
				 **/
				require(address(ShataUSD).balance >= amount, "The contract balance is insufficient to complete this transaction");
				/**
				 * 本周期轮次未达标，资产原路退回，不产生收益
				 *
				 */
				delete tabulation[rinfo.rid.sub(odds).add(1)][i];
				delete depositedOf[rinfo.rid.sub(odds).add(1)][Sender];
				ShataUSD.transfer(Sender, amount);
				member = member.sub(1);
			}
		}
	}
	/**
	 * 防止预言机宕机导致参投资产无法回笼
	 * 撤回投资
	 **/
	function revoke(uint256 _rid) public virtual returns (bool) {
		Deposited storage dep = depositedOf[_rid][msg.sender];
		/**
		 * 检查用户地址当前轮次是否参投
		 * 
		 **/
		require(dep.state == RoundState.OnPledge, "StatusError");
		/**
		 * 退回指定轮次的资产
		 *
		 **/
		ShataUSD.transfer(msg.sender, dep.totalStaked);
		/**
		 * 删除指定轮次的记录
		 *
		 **/
		 member = member.sub(1);
		 RoundInfo memory rinfo = _roundInfomationOf(block.timestamp);
		if(_rid==rinfo.rid){
			curnumber = curnumber.sub(1);
		}
		for(uint256 i=0; i< tabulation[_rid].length; i.add(1)){
			if(tabulation[_rid][i]==msg.sender){
				delete tabulation[_rid][i];
			}
		}
		
		delete depositedOf[_rid][msg.sender];
	}
	/**
	 * 完成指定轮次投资后计算奖励
	 * @param sender 发送人
	 * @param rid 	 轮次id
	 */
	function _totalReward(address sender, uint256 rid) 
		internal
		view
		returns (uint256 total)
	{
		uint256 join = 0;
		uint256 amount = 0;
		Deposited storage dep;
		for(uint256 i=rid; i < odds; i.add(1)){
			dep = depositedOf[i][sender];
			if(dep.state == RoundState.OnPledge){
				
				for(uint256 p = 0; p < dep.records.length; p.add(1)){
					amount = amount.add(dep.records[p].amount);
				}

				join = join.add(1);
			}
		}
		if(join == odds){
			total = amount.mul(rate);
		}else{
			total = amount;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
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

pragma solidity ^0.7.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
abstract contract  MathSqrt {
  function sqrt(uint x) public pure returns(uint) {
    uint z = (x + 1 ) / 2;
    uint y = x;
    while(z < y){
      y = z;
      z = ( x / z + z ) / 2;
    }
    return y;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '../utils/SafeMath.sol';
import '../pancake/IPancakeRouter02.sol';
import '../pancake/TransferHelper.sol';
import '../pancake/IPancakeFactory.sol';
import '../pancake/IPancakePair.sol';
contract TemplateERC20Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address permintReceiptor_
    ) ERC20(name_, symbol_) {
        _mint(permintReceiptor_, totalSupply_);
    }
}

contract MetaSoldierToken is TemplateERC20Token, Ownable {
    address public maker;
    address public swapPairAddress;
    //test
    // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
    // address PANCAKE_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // IPancakeRouter01 public pancakeRouter = IPancakeRouter01(PANCAKE_ROUTER_ADDRESS);
    // IPancakeFactory public factory = IPancakeFactory(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc);
    // address public USDTAddress = 0x0CA818DfDbC0C1fB82c814dF317e9b3FA2B0F6D5;
    
    
    // Main
    address PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IPancakeRouter01 public pancakeRouter = IPancakeRouter01(PANCAKE_ROUTER_ADDRESS);
    IPancakeFactory public factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address public USDTAddress = 0x55d398326f99059fF775485246999027B3197955;
    
    
    using SafeMath for uint256;
    
    event AddLiquidity(address indexed from,uint256 lpBlance);
    event RemoveLiquity(address indexed from,uint256 lpBlance);
    bool private inLiquity = false;

    modifier enterLiquity(){
        inLiquity = true;
        _;
        inLiquity = false;
    }

    constructor(address premintReceiptor)
        TemplateERC20Token(
            "Meta Soldier Token",
            "MSD",
            10000000000e18,
            premintReceiptor
        )
    {
        maker = premintReceiptor;
    }
    
    function init() external onlyOwner{
        swapPairAddress = factory.createPair(address(this),USDTAddress);
        TransferHelper.safeApprove(swapPairAddress,PANCAKE_ROUTER_ADDRESS,~uint256(0));
        super._approve(address(this),PANCAKE_ROUTER_ADDRESS,~uint256(0));
        TransferHelper.safeApprove(USDTAddress,PANCAKE_ROUTER_ADDRESS,~uint256(0));

    }

    function setSwapPairAddress(address pair) external onlyOwner {
        swapPairAddress = pair;
        TransferHelper.safeApprove(pair,PANCAKE_ROUTER_ADDRESS,~uint256(0));

    }

    function setTransferMarker(address marker) external onlyOwner {
        maker = marker;
    }

    function transferMarker(address newMaker) external {
        require(msg.sender == maker, "maker: wut?");
        maker = newMaker;
    }



    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if(inLiquity){
            super._transfer(msg.sender, recipient, amount);
            return true;
        }

        if (msg.sender == swapPairAddress && recipient != swapPairAddress) {
            // super._transfer(msg.sender, maker, (amount * 0.03e12) / 1e12);
            // super._transfer(
            //     msg.sender,
            //     recipient,
            //     amount - (amount * 0.03e12) / 1e12
            // );

            super._transfer(msg.sender, maker, amount.mul(0.03e12).div(1e12));
            super._transfer(
                msg.sender,
                recipient,
                amount.sub(amount.mul(0.03e12).div(1e12))
            );
        } else if (
            recipient == swapPairAddress && msg.sender != swapPairAddress
        ) {
            // super._burn(msg.sender, (amount * 0.03e12) / 1e12);
            // super._transfer(msg.sender, recipient, (amount * 0.97e12) / 1e12);
            super._burn(msg.sender, amount.mul(0.03e12).div(1e12));
            super._transfer(msg.sender, recipient, amount.mul(0.97e12).div(1e12));
        } else {
            super._transfer(msg.sender, recipient, amount);
        }

        return true;
    }

function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) 
        public
        virtual
        override
    returns (bool) { 
        
        if(inLiquity){
            super._transfer(sender, recipient, amount);
            uint256 currentAllowance = super.allowance(sender,_msgSender());
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            // unchecked{
                super._approve(sender, _msgSender(), currentAllowance - amount);
            // }
            return true;
        }
        
          if (sender == swapPairAddress && recipient != swapPairAddress) {
            // super._transfer(msg.sender, maker, (amount * 0.03e12) / 1e12);
            // super._transfer(
            //     msg.sender,
            //     recipient,
            //     amount - (amount * 0.03e12) / 1e12
            // );

            super._transfer(sender, maker, amount.mul(0.03e12).div(1e12));
            super._transfer(
                sender,
                recipient,
                amount.sub(amount.mul(0.03e12).div(1e12))
            );
        } else if (
            recipient == swapPairAddress && sender != swapPairAddress
        ) {
            // super._burn(msg.sender, (amount * 0.03e12) / 1e12);
            // super._transfer(msg.sender, recipient, (amount * 0.97e12) / 1e12);
            super._burn(sender, amount.mul(0.03e12).div(1e12));
            super._transfer(sender, recipient, amount.mul(0.97e12).div(1e12));
        } else {
            super._transfer(sender, recipient, amount);
        }
        uint256 currentAllowance = super.allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        // unchecked{
            super._approve(sender, _msgSender(), currentAllowance - amount);
        // }

        return true;

    }
    
    /**
     * 
     *  Premise: authorize the token contract and usdt token contract to the token address
     * 
    **/ 
    function addLiquidity(
        
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) public enterLiquity returns (uint amountA, uint amountB, uint liquidity){
        TransferHelper.safeTransferFrom(address(this),msg.sender,address(this),amountADesired);
        TransferHelper.safeTransferFrom(USDTAddress,msg.sender,address(this),amountBDesired);
        (amountA,amountB,liquidity) = pancakeRouter.addLiquidity(address(this),USDTAddress,amountADesired,amountBDesired,amountAMin,amountBMin,to,deadline);
        
          uint256 transferBlance = amountADesired.sub(amountA);
          if(transferBlance !=0){
            TransferHelper.safeTransfer(address(this),msg.sender,transferBlance);
          }
           transferBlance = amountBDesired.sub(amountB);
          if(transferBlance != 0){
            TransferHelper.safeTransfer(USDTAddress,msg.sender,transferBlance);    
          }
        emit AddLiquidity(msg.sender,liquidity);
    }
    
    
    
    // function _addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin
    // ) internal virtual returns (uint amountA, uint amountB) {
    //     // create the pair if it doesn't exist yet
    //     if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
    //         IPancakeFactory(factory).createPair(tokenA, tokenB);
    //     }
    //     (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
    //     if (reserveA == 0 && reserveB == 0) {
    //         (amountA, amountB) = (amountADesired, amountBDesired);
    //     } else {
    //         uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
    //         if (amountBOptimal <= amountBDesired) {
    //             require(amountBOptimal >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
    //             (amountA, amountB) = (amountADesired, amountBOptimal);
    //         } else {
    //             uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
    //             assert(amountAOptimal <= amountADesired);
    //             require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
    //             (amountA, amountB) = (amountAOptimal, amountBDesired);
    //         }
    //     }
    // }
    
    
     /**
     *  Premise: authorize swappairaddr to the token address
     * 
    **/
    function removeLiquidity(uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external enterLiquity returns (uint,uint){
      TransferHelper.safeTransferFrom(swapPairAddress,msg.sender,address(this),liquidity);  
      (uint amountA,uint amountB) = pancakeRouter.removeLiquidity(address(this),USDTAddress,liquidity,amountAMin,amountBMin,to,deadline); 
      emit RemoveLiquity(msg.sender,liquidity);
      return (amountA,amountB);
    }
 

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

//"SPDX-License-Identifier: <SPDX-License>"
pragma solidity ^0.7.0;
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
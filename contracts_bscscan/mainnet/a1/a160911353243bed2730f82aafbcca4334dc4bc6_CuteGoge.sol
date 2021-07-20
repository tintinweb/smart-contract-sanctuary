/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// 在Solidity的算术运算上添加溢出检查
library SafeMath {
    // 返回两个无符号整数的添加，在溢出时还原
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    // 返回两个无符号整数的减法，在溢出时还原
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // 返回两个无符号整数的减法，在溢出时使用自定义消息并还原
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    // 返回两个无符号整数的乘法，在溢出时还原
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // gas优化，当a为0时直接返回比再与a*b运算一次便宜
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    // 返回两个无符号整数的除法，被零除时还原
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // 返回两个无符号整数的除法，被零除时使用自定义消息并还原
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    // 返回两个无符号整数相除的余数，被零除时还原
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    // 返回两个无符号整数相除的余数，被零除时使用自定义消息并还原
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// library IterableMapping {
//     // Iterable mapping from address to uint;
//     struct Map {
//         address[] keys;
//         mapping(address => uint256) indexOf;
//         mapping(address => bool) inserted;
//     }

//     function getKeyAtIndex(Map storage map, uint256 index)
//         public
//         view
//         returns (address)
//     {
//         return map.keys[index];
//     }

//     function size(Map storage map) public view returns (uint256) {
//         return map.keys.length;
//     }

//     function set(Map storage map, address key) public {
//         if (map.inserted[key]) return;
//         map.inserted[key] = true;
//         map.indexOf[key] = map.keys.length;
//         map.keys.push(key);
//     }
// }

// 迭代address set数据结构
library EnumerableSet {
    struct Set {
        // 设定值的存储
        bytes32[] _values;
        // `values` 数组中值的位置，加 1，因为索引 0 表示值不在集合中。
        mapping(bytes32 => uint256) _indexes;
    }

    // 如果该值已添加到集合中，即该值尚未存在，则返回 true。
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // 该值存储在长度为 1 处，但我们向所有索引添加 1 并使用 0 作为标记值
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    // 如果该值已从集合中删除，即它存在，则返回 true。
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // 我们读取并存储值的索引以防止从同一存储槽多次读取
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // 将要删除的元素与数组中的最后一个交换，然后删除最后一个元素（有时称为“swap and pop” '）。

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    // 如果值在集合中，则返回 true。
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    // 返回集合中值的数量。
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    // 返回存储在集合中位置 `index` 的值。
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    // 向集合添加一个值。 如果该值已添加到集合中，即它尚未存在，则返回 true。
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    // 如果该值已从集合中删除，即它存在，则返回 true。
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    // 如果值在集合中，则返回 true。
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    // 返回集合中值的数量。
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    // 返回存储在集合中位置 `index` 的值。
    // 请注意，数组内的值的顺序没有保证，并且当添加或删除更多值时，它可能会发生变化。
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    // 向集合添加一个值。 如果该值已添加到集合中，即它尚未存在，则返回 true。
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    // 如果该值已从集合中删除，即它存在，则返回 true。
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    // 如果值在集合中，则返回 true。
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    // 返回集合中值的数量。
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    // 返回存储在集合中位置 `index` 的值。
    // 请注意，数组内的值的顺序没有保证，并且当添加或删除更多值时，它可能会发生变化。
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    // 向集合添加一个值。 如果该值已添加到集合中，即它尚未存在，则返回 true。
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    // 如果该值已从集合中删除，即它存在，则返回 true。
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    // 如果值在集合中，则返回 true。
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    // 返回集合中值的数量。
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    // 返回存储在集合中位置 `index` 的值。
    // 请注意，数组内的值的顺序没有保证，并且当添加或删除更多值时，它可能会发生变化。
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// 与地址类型相关的函数
library Address {
    // 如果 account 是合约那么返回 true
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Pausable {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract CuteGoge is IERC20, Pausable {
    using SafeMath for uint256;
    // using IterableMapping for IterableMapping.Map;
    // IterableMapping.Map private holders;
    using Address for address;

    // 添加库方法
    using EnumerableSet for EnumerableSet.AddressSet;
    // 声明一个集合状态变量
    EnumerableSet.AddressSet private holders;

    /****************************************ERC20 Start*********************************************/

    address creator; // 创建者
    address public feeTo; // 收税地址
    address public constant burnTo = address(0); // 销毁地址

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    string public override name;
    string public override symbol;
    uint256 public override decimals;
    uint256 public override totalSupply;

    constructor() {
        rate.burn = 5;
        rate.reward = 4;
        rate.fee = 1;

        creator = msg.sender;
        feeTo = msg.sender;

        name = "CUTEDOGE-D";
        symbol = "CUTEDOGE-D";
        decimals = 18;
        totalSupply = 1 * 10**7 * 10**8 * 10**18;   // 总供给量：1000W亿
        balanceOf[creator] = totalSupply;
        emit Transfer(address(0), creator, totalSupply);

        uint256 burnAmount = totalSupply.div(2);    // 销毁量：总供给的一半
        balanceOf[burnTo] = burnAmount;
        balanceOf[creator] -= burnAmount;
        emit Transfer(creator, address(0), burnAmount);
    }

    //对余额转移
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    //调用者给 spender 授权 amount 数额的代币
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //转账，从 sender 地址转给 recipient 地址 amount 数额代币
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            allowance[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds _allowances"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer();

        require(
            sender != address(0),
            "ERC20: transfer sender the zero address"
        );
        require(
            recipient != address(0),
            "ERC20: transfer recipient the zero address"
        );

        // 费率计算扣除
        uint256 burn = amount.mul(rate.burn).div(100);
        uint256 reward = amount.mul(rate.reward).div(100);
        uint256 fee = amount.mul(rate.fee).div(100);

        balanceOf[sender] = balanceOf[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        amount = amount - burn - reward - fee;
        balanceOf[recipient] = balanceOf[recipient].add(amount);

        // 销毁
        balanceOf[burnTo] = balanceOf[burnTo].add(burn);

        // 奖励
        address rewardTo = getRewarder(sender, block.timestamp); // 随机一个地址
        balanceOf[rewardTo] = balanceOf[rewardTo].add(reward);

        // 税费
        balanceOf[feeTo] = balanceOf[feeTo].add(fee);

        if (
            sender.isContract() == false && sender != feeTo && sender != creator
        ) {
            holders.add(sender);
        }

        emit Transfer(sender, burnTo, burn);
        emit Transfer(sender, rewardTo, reward);
        emit Transfer(sender, feeTo, fee);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve owner the zero address");
        require(
            spender != address(0),
            "ERC20: approve spender the zero address"
        );

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    // 在任何代币转移之前调用的钩子， 包括铸币和销币
    function _beforeTokenTransfer() internal view virtual {
        require(!paused(), "ERC20: token transfer while paused");
    }

    // 给account账户创建amount数量的代币，同时增加总供应量
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer();

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // 给account账户减少amount数量的代币，同时减少总供应量
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer();

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;
        balanceOf[burnTo] += amount;

        emit Transfer(account, address(0), amount);
    }

    /****************************************ERC20 End*********************************************/

    /****************************************Pause Start*********************************************/
    modifier onlyCreator() {
        require(msg.sender == creator, "only Creator");
        _;
    }

    function pause() public onlyCreator {
        _pause();
    }

    function unpause() public onlyCreator {
        _unpause();
    }

    function changeCreator(address new_factory) public onlyCreator {
        creator = new_factory;
    }

    /****************************************Pause End*********************************************/

    /****************************************Distribute Start*********************************************/

    struct Rate {
        uint256 reward; // 奖励率
        uint256 fee; // 费率
        uint256 burn; // 销毁率
    }

    Rate public rate;

    function getRewarder(address seedSender, uint256 seedTimestamp)
        public
        view
        returns (address)
    {
        uint256 length = holders.length();
        if (length == 0) {
            return feeTo;
        }
        uint256 number = uint256(
            keccak256(abi.encodePacked(seedSender, seedTimestamp))
        );
        uint256 index = number % length;
        address account = holders.at(index);
        return account;
    }

    function setRate(
        uint256 burn,
        uint256 reward,
        uint256 fee
    ) public onlyCreator returns (bool) {
        require(burn > 0 && burn < 100, "must be between 0 and 100");
        require(reward > 0 && reward < 100, "must be between 0 and 100");
        require(fee > 0 && fee < 100, "must be between 0 and 100");
        require(
            reward + fee + burn < 100,
            "The sum of burn, fee and reward is less than 100"
        );
        rate.burn = burn;
        rate.reward = reward;
        rate.fee = fee;
        return true;
    }

    function setFeeTo(address value) public onlyCreator returns (bool) {
        require(feeTo != value);
        feeTo = value;
        return true;
    }

    function withdrawal(address token, uint256 amount)
        public
        onlyCreator
        returns (bool)
    {
        return IERC20(token).transfer(creator, amount);
    }

    // 提取链上主币
    function withdrawal(uint256 amount) public onlyCreator returns (bool) {
        require(amount > 0, "amount error");
        require(
            payable(address(this)).balance >= amount,
            "amount exceeds balance"
        );
        payable(creator).transfer(amount);
        return true;
    }

    /****************************************Distribute End*********************************************/

    function getHolderCount() public view returns (uint256) {
        return holders.length();
    }

    function getHolderAtIndex(uint256 index) public view returns (address) {
        return holders.at(index);
    }
}
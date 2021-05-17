/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        // 移除应使用pure警告
        this;
        return msg.data;
    }
}

library EnumerableSet {
    struct Set {
        // 设定值的存储
        bytes32[] _values;
        // 索引
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * 集合中添加一个值
     * 当`value`在集合`set`不存在时，成功添加返回true
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * 从集合中移除一个值
     * 当`value`在集合`set`存在时，成功移除返回true
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // 读取并存储该值的索引，防止从同一存储槽多次读取
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // 等效于contains(set, value)
            // 为了删除数组中的元素，将删除元素与数组最后元素交换，然后删除（弹出）最后一个元素，这将改变数组顺序
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // 当要删除的值是最后一个值时，不需要进行交换操作。 但是这种情况很少发生，因此无论如何我们还是要进行交换，以避免添加'if'语句的气体成本。
            bytes32 lastvalue = set._values[lastIndex];

            // 将最后一个值移到要删除的值所在的索引
            set._values[toDeleteIndex] = lastvalue;
            // 更新移动值的索引
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // 删除存储值
            set._values.pop();

            // 删除索引
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * 判断值是否在集合中存在
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * 返回集合的长度
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * 返回索引`index`在集合`set`中存储的值，当集合删除元素时可能导致索引值变化
     * 要求:
     *
     * - 索引必须比集合长度小
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * 集合中添加一个值
     * 当`value`在集合`set`不存在时，成功添加返回true
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * 从集合中移除元素
     *
     * 当`value`在集合`set`存在时，成功移除返回true
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * 判断值是否在集合中存在
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * 返回集合中值的数量
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * 返回索引`index`在集合`set`中存储的值，当集合删除元素时可能导致索引值变化
     * 要求:
     *
     * - 索引必须比集合长度小
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * 集合中添加一个值
     * 当`value`在集合`set`不存在时，成功添加返回true
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * 从集合中移除元素
     *
     * 当`value`在集合`set`存在时，成功移除返回true
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * 判断值是否在集合中存在
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * 返回集合中值的数量
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * 返回索引`index`在集合`set`中存储的值，当集合删除元素时可能导致索引值变化
     * 要求:
     *
     * - 索引必须比集合长度小
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * 集合中添加一个值
     * 当`value`在集合`set`不存在时，成功添加返回true
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * 从集合中移除元素
     *
     * 当`value`在集合`set`存在时，成功移除返回true
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * 判断值是否在集合中存在
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * 返回集合中值的数量
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * 返回索引`index`在集合`set`中存储的值，当集合删除元素时可能导致索引值变化
     * 要求:
     *
     * - 索引必须比集合长度小
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * 角色管理员发生改变时提交该事件
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     *
     * `account`被授予角色`role`时提交该事件
     * `sender`是智能合约所有者，是管理员角色承载者，但使用{_setupRole}时除外。
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * `account`被移除角色`role`时提交该事件.
     *
     * `sender`是智能合约所有者，是管理员角色承载者:
     *   - 如果使用`revokeRole`，则是管理员角色承载者
     *   - 如果使用`renounceRole`，则是角色承载者
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * 如果`account`授予`role`角色，则返回true.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * 返回角色拥有的成员数量
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * 通过索引`index`返回角色`role`的成员，`index`必须在0-{getRoleMemberCount}之间；
     * 警告：
     *      角色未按一定规则排序，并且顺序可能随时更改；
     *      使用{getRoleMember}和{getRoleMemberCount}时，请确保在同一区块执行。
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * 返回角色`role`的管理员角色
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     *
     * 授权角色`role`给`account`
     * 如果用户`account`未被授予角色`role`，则提交{RoleGranted}事件
     *
     * 要求:
     *
     * - 调用者必须是角色`role`的管理员角色.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * 从账户`account`撤销角色`role`，如果帐户`account`已经授予角色`role`，则提交{RoleRevoked}事件.
     *
     * 要求:
     *
     * - 调用者必须是角色`role`的管理员角色..
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * 从账户`account`自己摒弃角色`role`，
     *
     * 如果帐户`account`已经授予角色`role`，则提交{RoleRevoked}事件.
     *
     * 要求:
     *
     * - 调用者必须是账户`account`,及只有自己才能放弃该角色.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * 授予账户`account`角色`role`,如果账户未被授予，则提交{RoleGranted}事件；
     * 请注意，与方法{grantRole}不同，该方法未做任何权限限制。
     *
     * 警告：
     * -    仅在构造函数初始化角色时使用
     * -    以其他方式调用可以有效地绕过{AccessControl}系统的管理控制
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * 为角色`role`设置管理员角色`adminRole`,并提交管理员角色改变事件
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * EIP中定义的ERC20标准的接口。
 */
interface IERC20 {
    /**
     * 返回存在的令牌数量
     */
    function totalSupply() external view returns (uint256);

    /**
     * 返回`account`拥有的令牌数量
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * 将`amount`令牌从调用者的帐户转移到`recipient`,操作成功返回true
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * 获取`owner`授权`spender`的额度
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * 1.授权`spender`允许操作自己的授权额度`amount`，操作成功返回true；
     * 2.使用此方法更改额度可能存在风险，期望额度为0后在重新设置
     * 3.成功则发送`approve`授权资产额度事件
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * 1.从账户`sender`转移资产`amount`到`recipient`，同时扣除当前发送者所授权的额度;
     * 2.授权额度不够不允许转移`sender`资产，操作成功返回true；
     * 3.成功则发送`Transfer`转移资产事件
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * 从账户`from`转移资产`value`到`to`，请注意：`value`可能为0
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * 发出所有者的支配者授权额度事件
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * solidity算数封装，防止计算溢出
 */
library SafeMath {
    /**
     * 两个无符号数的加法，加法不能溢出
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * 两个无符号数的减法，减法不能溢出
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * 返回无符号减法，可自定义溢出时错误信息，减法不能溢出
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * 1.返回两个无符号数乘法，乘法不能溢出；
     * 2.a不能为0
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * 1.返回两个无符号数除法，结果四舍五入，`b`不能为0
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * 1.返回两个无符号数除法，结果四舍五入，`b`不能为0
     * 2.可自定义溢出错误信息
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * 1.返回两个无符号整数的余数,被除数`b`不能为0；
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * 1.返回两个无符号整数的余数,被除数`b`不能为0；
     * 2.可自定义溢出错误信息
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * ERC20接口实现
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
     * 1.构造函数初始化token名称、货币符号以及进度
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * 1.返回token名称
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
      * 1.返回token符号
      */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * 1.返回token精度
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * 1.返回存在的令牌数量
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * 1.查询账户余额
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * 1.转移资金到`recipient`
     * 2.`recipient`不能为0地址
     * 3.调用者金额必须大于等于`amount`
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * 获取`owner`授权`spender`的额度
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * 1.授权`spender`允许操作自己的授权额度`amount`，操作成功返回true；
     * 2.使用此方法更改额度可能存在风险，期望额度为0后在重新设置；
     * 3.成功则发送`approve`授权资产额度事件；
     * 4.`spender`不能为0地址
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * 1.从账户`sender`转移资产`amount`到`recipient`，同时扣除当前发送者所授权的额度;
     * 2.授权额度不够不允许转移`sender`资产，操作成功返回true；
     * 3.成功则发送`Transfer`转移资产事件；
     * 4.`sender`与`recipient`不能为0地址；
     * 5.`sender`token余额必须大于等于`amount`
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * 1.以原子形式增加`sender`授权额度；
     * 2.`sender`不能为0地址；
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * 1.以原子形式减少`sender`授权额度；
     * 2.`sender`不能为0地址；
     * 3.`subtractedValue`必须小于等于当前`sender`授权额度
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * 1.从账户`sender`转移资产`amount`到`recipient`，同时扣除当前发送者所授权的额度;
     * 2.授权额度不够不允许转移`sender`资产，操作成功返回true；
     * 3.成功则发送`Transfer`转移资产事件；
     * 4.`sender`与`recipient`不能为0地址；
     * 5.`sender`token余额必须大于等于`amount`
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * 1.凭空创建并分配token给`account`；
     * 2.`account`不能为0地址；
     * 3.token总额随之增加；
     * 4.`account`发送`Transfer`转移资产事件到0地址；
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * 1.销毁`account`账户token数量；
     * 2.`account`不能为0地址；
     * 3.token总额随之减少；
     * 4.`account`账户余额必须大于等于`amount`
     * 4.`account`发送`Transfer`转移资产事件到0地址；
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * 1.授权`spender`允许操作自己的授权额度`amount`，操作成功返回true；
     * 2.`owner`与`spender`不能为0地址；
     * 3.成功则发送`approve`授权资产额度事件；
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * 1.将{decimals}设置为默认值18以外的值;
     * 2.警告：此方法智能在构造函数中使用，设定之后不能更改，否则可能无法正常工作；
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * 1.预留HOOK，资产转移之前被调用，包括创造以及销毁token
     * 2.`from`与`to`都不为0时，资产将被转移给`to`；
     * 3.`from`为0地址时，将为`to`创建token；
     * 4.`to`为0地址时，将为`from`销毁token；
     * 5.`from`与`to`不可能同时为0地址；
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * 认购票据ERC20
 */
contract MyERC20 is Context, AccessControl, ERC20 {
    bytes32 public constant MINT_BURN_ROLE = keccak256("MINT_BURN");
    /**
     * 将DEFAULT_ADMIN_ROLE，WETH_MINTER_ROLE授予部署合同的帐户
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * 给用户`to`创建`amount`个token
     * 要求:
     *
     * - 调用者必须有`WETH_MINTER_ROLE`角色.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINT_BURN_ROLE, _msgSender()), "ERC20: must have minter role to mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public virtual {
        require(allowance(from, _msgSender()) >= amount || _msgSender() == from, "BURN_ERROR");
        _burn(from, amount);
    }

    function burnMulti(address[] memory from, uint256[] memory amount) external virtual {
        require(hasRole(MINT_BURN_ROLE, _msgSender()), "ERC20: must have minter role to burn");
        uint _len = from.length;
        for (uint i = 0; i < _len; i++) {
            burn(from[i], amount[i]);
        }
    }
}
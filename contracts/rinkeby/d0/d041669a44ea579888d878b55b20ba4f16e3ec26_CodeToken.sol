pragma solidity ^0.5.16;

import './Address.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './ERC20Detailed.sol';
import './ERC20.sol';

/**
 * 发布的token
 */
contract CodeToken is ERC20, ERC20Detailed {

    // 引入SafeERC20库，其内部函数用于安全外部ERC20合约转账相关操作
    using SafeERC20 for IERC20;
    // 使用Address库中函数检查指定地址是否为合约地址
    using Address for address;
    // 引入SafeMath安全数学运算库，避免数学运算整型溢出
    using SafeMath for uint;

    // 存储治理管理员地址
    address public governance;

    // 存储指定地址的铸币权限
    mapping (address => bool) public minters;


    // 构造函数，设置代币名称、简称、精度；将发布合约的账号设置为治理账号
    constructor () public ERC20Detailed("CodeToken.finance", "CTB", 18) {
        governance = tx.origin;
    }

    /**
     * 铸币
     *   拥有铸币权限地址向指定地址铸币
     */
    function mint(address account, uint256 amount) public {
        require(minters[msg.sender], "!minter");
        _mint(account, amount);
    }

    /**
     * 设置治理管理员地址
     */
    function setGovernance(address _governance) public {
        // 要求调用者必须为当前治理管理员地址
        require(msg.sender == governance, "!governance");
        // 更新governance
        governance = _governance;
    }

    /**
     * 添加铸币权限函数
     */
    function addMinter(address _minter) public {
        // 要求调用者必须为当前治理管理员地址
        require(msg.sender == governance, "!governance");
        // 变更指定地址_minter的铸币权限为true
        minters[_minter] = true;
    }

    /**
     * 移除铸币权限函数
     */
    function removeMinter(address _minter) public {
        // 要求调用者必须为当前治理管理员地址
        require(msg.sender == governance, "!governance");
        // 变更指定地址_minter的铸币权限为false
        minters[_minter] = false;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity ^0.5.16;

contract StandardBullERC20 {
    // 合约名称
    string public constant name = "BULL";
    // 代币符号
    string public constant symbol = "BULL";
    // 代币精度
    uint8 public constant decimals = 6;
    // 代币总供应量： 100 million ERC
    uint private _totalSupply = 100000000e6; 
    
    // 授权数量 
    mapping (address => mapping (address => uint256)) internal allowances;
    // 账户余额
    mapping (address => uint256) internal balances;

    address public owner;
    address public burner;
    
    /**
     * 构造一个代币合约实例
     * @param account 使用account作为owner
     */
    constructor(address account) public {
        owner = account;
        balances[owner] = uint256(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
     * 查询代币总供应量
     * @return 代币总供应量
     */
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    /**
     * 查询指定地址的代币数量
     * @param 账户地址
     * @return 代币数量
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }
    
    /**
     * 查询账户授权给指定合约的可交易代币数量
     * @param account 指定用户
     * @param spender 指定合约账户
     * @return 授权数量
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * 授权给合约从自身发送一定数量的交易
     * @param spender 授权目标合约
     * @param amount 交易代币数量
     * @return 交易是否成功
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * 普通转账
     * @param dst 目标地址
     * @param 转账数量
     * @return 转账是否成功
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice 调用合约转账，从src到dst，需要先对代币进行授权
     * @param src 源头地址
     * @param dst 目标地址
     * @param 转账数量
     * @return 转账是否成功
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = sub(spenderAllowance, amount, "StandERC20::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "StandERC20::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "StandERC20::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub(balances[src], amount, "StandERC20::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add(balances[dst], amount, "StandERC20::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }
    
    // 设置销毁人员 
    function setBurner(address newBurner) external returns (bool) {
        require(msg.sender == owner, "StandERC20Expend::setBurner: onlyOwner method called by non-owner");
        burner = newBurner;
        return true;
    }
    
    // 代币销毁 
    function burn(uint256 amount) external returns (bool) {
        require(msg.sender == burner, "StandERC20Expend::burn: onlyBurner methods called by non-burner");

        balances[burner] = sub(balances[burner], amount, "StandERC20Expend::burn: transfer amount exceeds balance");
        _totalSupply = sub(_totalSupply, amount, "StandERC20Expend::burn: transfer amount exceeds balance");
        emit Burn(burner, amount);
        return true;
    }

    // 转账事件，供需要监听的合约使用
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件，供需要监听的合约使用
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // 销毁事件，供需要监听的合约使用
    event Burn(address indexed burner, uint256 value);

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

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

interface IIncomePool {
    //手续费持有账户
    function getFeeOwners() view external returns(address,address,address);

    //增加拥有者卖出手续费
    function addSellOwnerFee(uint256 poolFee,uint256 congressFee,uint256 partnerFee) external;

    //增加卖出手续费
    function addSellFee(uint256 fee) external;

    //获取累计卖出手续费
    function getTotalSellFee() external view returns (uint256);

    //获取日期卖出手续费
    function getDateSellFee(uint date) external view returns (uint256);

    //增加拥有者挖矿手续费
    function addMineOwnerFee(uint256 poolFee,uint256 congressFee,uint256 partnerFee) external;

    //增加挖矿手续费
    function addMineFee(uint256 fee) external;

    //获取累计挖矿手续费
    function getTotalMineFee() external view returns (uint256);

    //获取日期挖矿手续费
    function getDateMineFee(uint date) external view returns (uint256);
}


contract FFTToken is IERC20
{
    using SafeMath for uint256;
    address _owner;
    uint256 _maxSupply= 2100000 * 1e18;

    string constant  _name = 'Fly Financial Token';
    string constant _symbol = 'FFT';
    uint8  constant _decimals = 18;

    uint256 _totalSupply;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address=>bool) _isExcluded;
    mapping(address=>bool) bannedUser;
    mapping(address=>uint256) _balances;
    address incomePool; //收益池合约
    mapping(address=>bool) public pairMap; //DEX 收取手续费交易对地址
    address public poolOwner; //分红池地址
    uint256 public poolRatio=30; //分红池比率 1000为基数
    address public congressOwner; //国会手续费地址
    uint256 public congressRatio=30; //国会手续费比率
    address public partnerOwner; //合伙人地址
    uint256 public partnerRatio=10; //合伙人比率
    uint256 public destroyRatio=30; //销毁比率
    mapping(address=>bool) public minter;//铸币权限

    constructor() public
    {
        _owner = msg.sender;
        minter[msg.sender]=true;
        _isExcluded[_owner]=true;
    }

    //设置收益池
    function setIncomePool(address _account) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        incomePool =_account;
    }

    //设置铸币权限账号
	function setMinter(address account,bool flag) public
	{
		require(msg.sender== _owner);
		minter[account]=flag;
	}

    //设置收费的交易对
    function setDexPairs(address pair,bool flag) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        pairMap[pair] =flag;
    }

    //禁止用户
    function setBanned(address account,bool flag) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        bannedUser[account]=flag;
    }

    //排除扣费的账号
    function setExcluded(address account,bool flag) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        _isExcluded[account] =flag;
    }

    //设置比率
    function setRatios(uint256 _poolRatio,uint256 _congressRatio,uint256 _partnerRatio,uint256 _destroyRatio) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        poolRatio=_poolRatio;
        partnerRatio=_partnerRatio;
        congressRatio=_congressRatio;
        destroyRatio=_destroyRatio;
        if (poolRatio+partnerRatio+destroyRatio+congressRatio>150){
            revert("The total ratio cannot exceed 15% .");
        }
    }

    //取出合约错误转账的币
    function takeOutErrorTransfer(address _tokenAddress) public
    {
        require(msg.sender==_owner,"Only the owner can perform the operation");
        IERC20(_tokenAddress).transfer(_owner, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function mint(address account,uint256 amount) public
    {
        require(minter[msg.sender]==true,"Only the owner can perform the operation");
        _mint(account,amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), 'BEP20: mint to the zero address');
        require(totalSupply().add(amount) <=_maxSupply,"MAX SUPPLY OVER");
        _totalSupply=_totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burnFrom(address sender, uint256 amount) public override  returns (bool)
    {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _burn(sender,amount);
        return true;
    }

    function burn(uint256 amount) public override returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }

    function _burn(address sender,uint256 tAmount) private
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[address(0)] = _balances[address(0)].add(tAmount);
        emit Transfer(sender, address(0), tAmount);
    }


    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(bannedUser[sender]==false,"sender is banned transfer");

        uint256 toAmount = amount;
        if(pairMap[recipient])
        {
            if(!isExcluded(sender))
            {
                uint256 onePercent = amount.mul(10).div(1000);
                if(onePercent > 0)
                {
                    (poolOwner,congressOwner,partnerOwner)= IIncomePool(incomePool).getFeeOwners();
                    uint256 totalRatio=congressRatio+destroyRatio+partnerRatio+poolRatio;
                    uint256 p = onePercent.mul(totalRatio);
                    _balances[sender]= _balances[sender].sub(p);

                    uint256 destroyAmount=onePercent.mul(destroyRatio);
                    _balances[address(0)]=_balances[address(0)].add(destroyAmount);
                    emit Transfer(sender, address(0), destroyAmount);

                    uint256 poolAmount=onePercent.mul(poolRatio);
                    _balances[poolOwner]= _balances[poolOwner].add(poolAmount);
                    emit Transfer(sender, poolOwner, poolAmount);

                    uint256 congressAmount=onePercent.mul(congressRatio);
                    _balances[congressOwner]= _balances[congressOwner].add(congressAmount);
                    emit Transfer(sender, congressOwner, congressAmount);

                    uint256 partnerAmount=onePercent.mul(partnerRatio);
                    _balances[partnerOwner]= _balances[partnerOwner].add(partnerAmount);
                    emit Transfer(sender, partnerOwner, partnerAmount);


                    toAmount = amount.sub(p);

                    IIncomePool(incomePool).addSellFee(p);
                    IIncomePool(incomePool).addSellOwnerFee(poolAmount,congressAmount,partnerAmount);
                }
            }
        }

        _balances[sender]= _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

}
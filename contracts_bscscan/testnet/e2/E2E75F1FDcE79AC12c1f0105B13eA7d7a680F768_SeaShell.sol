/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// File: SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: IERC20.sol



pragma solidity ^0.7.6;

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
// File: Context.sol



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
// File: ERC20.sol



pragma solidity ^0.7.6;




contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_,string memory symbol_,uint256 totalSupply_,uint8 decimal_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimal_;
        _totalSupply = totalSupply_*10**_decimals;
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

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_value <= _allowances[_from][msg.sender]);     // Check allowance
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        // require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address recipient, uint256 amount) internal virtual {
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(address(0x0), recipient, amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


}

// File: SeashellToken.sol



pragma solidity ^0.7.6;



contract SeaShell is ERC20 {

    using SafeMath for uint256;

    address mer_erc20_address = 0x520154173f8BB8B3A69856861455B56a51D5428b;
    address mer_usdt_lp_miner = 0xDD44d2a25B73dd8d87DD22b44869185e5c1746Ae;
    IERC20 public merERC20;

    //产量
    uint256 yield1 = 231;
    uint256 yield2 = 347;
    uint256 yield3 = 579;
    //区间块高
    uint256 section_block = 30;
    //mer销毁总量
    uint256 public destroytotalnumber;
    //销毁记录
    struct Destroyrec {
        uint256 startBlock;
        uint256 profitBlock;
        uint256 lastRewardBlock;
        uint256 amount;
    }

    //销毁记录
    mapping(address => Destroyrec[]) public destroyrecs;


    constructor() ERC20("SeaShell","SS",100000000,18) {
        merERC20 = IERC20(mer_erc20_address);
        // _mint(address(this),totalSupply().sub(864000*10**decimals()));
        _mint(_msgSender(),864000*10**decimals());
    }

    //销毁
    function destroy(uint256 amount) public {
       uint256 _amount = merERC20.allowance(msg.sender,address(this));
       require(_amount > amount,"require Approve mer");
       merERC20.transferFrom(msg.sender,address(0x0),amount);
       destroytotalnumber = destroytotalnumber.add(amount);
       Destroyrec memory rec = Destroyrec({
           startBlock:block.number,
           profitBlock:block.number,
           lastRewardBlock:block.number.add(uint256(3).mul(section_block)),
           amount:amount
       });
       destroyrecs[msg.sender].push(rec);

    }

    //可用余额
    function balanceOf(address account) public view virtual override returns (uint256 balance_) {
        (balance_,)= getprofit(account);
        balance_ = balance_.add(super.balanceOf(account));
        return balance_;
    }


    //查看收益
    function getprofit(address account) public view returns (uint256 balance_,uint256 fee_) {
        Destroyrec[] memory recs = destroyrecs[account];
        for(uint i=0;i<recs.length;i++){
            Destroyrec memory rec = recs[i];
            if(rec.profitBlock < rec.lastRewardBlock){
                uint256 blocknumber = block.number;
                uint256 profit;
                uint256 prop = rec.amount.mul(1e10).div(destroytotalnumber).mul(totalSupply());
                if(blocknumber.sub(rec.startBlock) <= section_block){
                    profit = prop.mul(yield1.mul(blocknumber.sub(rec.profitBlock))).div(864000).div(1e10);
                }else if(blocknumber.sub(rec.startBlock) <= section_block.mul(2)){
                    if(rec.profitBlock.sub(rec.startBlock) <= section_block){
                        uint256 bnumber = section_block.sub(rec.profitBlock.sub(rec.startBlock));
                        profit = prop.mul(yield1.mul(bnumber)).div(864000).div(1e10);
                        profit = profit.add(prop.mul(yield2.mul(blocknumber.sub(rec.startBlock.add(section_block)))).div(864000).div(1e10));
                    }else{
                        profit = prop.mul(yield2.mul(blocknumber.sub(rec.profitBlock))).div(864000).div(1e10);
                    }
                }else{
                    if(rec.profitBlock.sub(rec.startBlock) <= section_block){
                        uint256 bnumber = section_block.sub(rec.profitBlock.sub(rec.startBlock));
                        profit = prop.mul(yield1.mul(bnumber)).div(864000).div(1e10);
                        profit = profit.add(prop.mul(yield2.mul(section_block)).div(864000).div(1e10));
                        profit = profit.add(prop.mul(yield3.mul(blocknumber.sub(rec.startBlock.add(section_block.mul(2))))).div(864000).div(1e10));
                    }else if(rec.profitBlock.sub(rec.startBlock) <= section_block.mul(2)){
                        uint256 bnumber = section_block.mul(2).sub(rec.profitBlock.sub(rec.startBlock));
                        profit = prop.mul(yield2.mul(bnumber)).div(864000).div(1e10);
                        profit = profit.add(prop.mul(yield3.mul(blocknumber.sub(rec.startBlock.add(section_block.mul(2))))).div(864000).div(1e10));
                    }else if(rec.profitBlock.sub(rec.startBlock) <= section_block.mul(3)){
                        profit = prop.mul(yield3.mul(blocknumber.sub(rec.profitBlock))).div(864000).div(1e10);
                    }else{
                        profit = prop.mul(yield3.mul(rec.lastRewardBlock.sub(rec.profitBlock))).div(864000).div(1e10);
                    }
                }
                balance_ = balance_.add(profit.mul(9).div(10));
                fee_ = fee_.add(profit.div(10));
            }
        }
        return (balance_,fee_);
    }

    //结算
    function settlement() public{
        uint256 bal;
        uint256 fee;
        (bal,fee)= getprofit(msg.sender);
        if(bal > 0){
            _mint(msg.sender,bal);
            _mint(mer_usdt_lp_miner,fee);
            Destroyrec[] memory recs = destroyrecs[msg.sender];
            for(uint i=0;i<recs.length;i++){
                Destroyrec memory rec = recs[i];
                if(rec.profitBlock < rec.lastRewardBlock){
                    rec.profitBlock = block.number;
                    destroyrecs[msg.sender][i] = rec;
                }
            }
        }
    }



    //转账
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        //结算
        settlement();
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        super.transferFrom(_from,_to,_value);
        return true;
    }

    function updateDestroynumber(uint256 _value) public {
        destroytotalnumber = _value;
    }

}
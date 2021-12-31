/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.5;


// File: contracts\open-zeppelin-contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

contract ReentrancyGuard {
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

    constructor () internal {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\open-zeppelin-contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts\open-zeppelin-contracts\token\ERC20\ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: contracts\ERC20\TokenMintERC20Token.sol

pragma solidity ^0.5.0;


/**
 * @title TokenMintERC20Token
 * @author TokenMint (visit https://tokenmint.io)
 *
 * @dev Standard ERC20 token with burning and optional functions implemented.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract TokenMintERC20Token is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Constructor.
     * @param name name of the token
     * @param symbol symbol of the token, 3-4 chars is recommended
     * @param decimals number of decimal places of one token unit, 18 is widely used
     * @param totalSupply total supply of tokens in lowest units (depending on decimals)
     * @param tokenOwnerAddress address that gets 100% of token supply
     */
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address payable feeReceiver, address tokenOwnerAddress) public payable {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;

      // set tokenOwnerAddress as owner of all tokens
      _mint(tokenOwnerAddress, totalSupply);

      // pay the service fee for contract deployment
      feeReceiver.transfer(msg.value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public {
        
      _burn(msg.sender, value);
    }

    // optional functions from ERC20 stardard

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
      return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
      return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
      return _decimals;
    }
}

contract Pools is ReentrancyGuard {
    
    uint256 public poolId = 1;
    address public owner;
    
    /* Pool Token Address */
    
    TokenMintERC20Token public pool_address;
    
    /* Variable to store the fee collected */
    
    uint256 public fee_collected;       
    
    /* Last Created Informations*/
    
    uint256 public lastcreated;
    uint256 lastpoolcreated;

    struct UserBets{
        uint256[10] pools;
        uint256[10] amounts;
        uint256[10] prices;
        bool betted;
        uint256 balance;
        uint256 totalbet;
        bool claimed;
    }
    
    struct User{
        uint256[] pools;
        string username;
        uint256 balance;
        uint256 freebal;
        bool active;
    }
    
    struct Data{
        address[] user;
    }
    
    struct Pool{
        uint256[10] prices;
        uint256 startime;
        uint256 stakingends;
        uint256 endtime;
    }
    
    mapping(address => mapping(uint256 => UserBets)) bets;
    mapping(uint256 => Pool) pool;
    mapping(address => User) user;
    mapping(uint256 => Data) data;
    
    constructor(address _pool_address) public{
        owner = msg.sender;
        pool_address = TokenMintERC20Token(_pool_address);
        lastcreated = block.timestamp;
    }
    
    /*  Registering the username to the contract */
    
    function Register(string memory _username) public returns(bool){
        User storage us = user[msg.sender];
        require(us.active == false,'Existing User');
        us.active = true;
        us.username = _username;
        return true;
    }
    
    /* For placing a prediction in the pool. */
    
    function PlaceBet(uint256 index,uint256 _prices,uint256 _percent,uint256 _poolId,uint256 _amount) public returns(bool){
        require(_poolId <= poolId,'Invalid Pool');
        require(pool_address.allowance(msg.sender,address(this))>=_amount,'Approval failed');
        Pool storage b = pool[_poolId];
        Data storage d = data[_poolId];
        require(b.stakingends >= block.timestamp,'Ended');
        User storage us = user[msg.sender];
        require(us.active == true,'Register to participate');
        UserBets storage u = bets[msg.sender][_poolId];
        require(u.pools[index] == 0,'Already Betted');
        if(u.betted == false){
            u.balance = pool_address.balanceOf(msg.sender);
            u.betted = true;
        }
        else{
            require(SafeMath.add(u.totalbet,_amount) <= u.balance,'Threshold Reached');
        }
        us.pools.push(_poolId);
        us.balance = SafeMath.add(us.balance,_amount);
        u.pools[index] = _percent; 
        u.prices[index] = _prices; 
        u.amounts[index] = _amount;
        u.totalbet = u.totalbet + _amount;
        d.user.push(msg.sender);
        pool_address.transferFrom(msg.sender,address(this),_amount);
        return true;
    }
    
    /* Update user balance. Max 4% can be changed */
    
    function updatebal(address _user,uint256 _poolId,uint256 _reward,bool _isPositive) public returns(bool){
        require(msg.sender == owner,'Not Owner');
        require(_reward <= 4000000,'Invalid Reward Percent');
        User storage us = user[_user];
        require(us.active == true,'Invalid User');
        UserBets storage u = bets[_user][_poolId];
        require(u.claimed == false,'Already Claimed');
        if(_isPositive == true){
            updateFee(_reward,u.totalbet);
            uint256 temp = SafeMath.mul(_reward,90);
            uint256 reward = SafeMath.div(temp,100);
            uint256 a = SafeMath.mul(u.totalbet,reward);
            uint256 b = SafeMath.div(a,10**8);
            uint256 c = SafeMath.add(u.totalbet,b);
            u.claimed = true;
            us.freebal = SafeMath.add(c,us.freebal);
            us.balance = SafeMath.sub(us.balance,u.totalbet);
        }
        else{
            uint256 a = SafeMath.mul(u.totalbet,_reward);
            uint256 b = SafeMath.div(a,10**8);
            uint256 c = SafeMath.sub(u.totalbet,b);
            u.claimed = true;
            us.freebal = SafeMath.add(c,us.freebal);
            us.balance = SafeMath.sub(us.balance,u.totalbet);
        }
        return true;
    }
    
    /* Update the fee incurred */
    
    function updateFee(uint256 r,uint256 amt) internal{
        uint256 temp = SafeMath.mul(r,10);
        uint256 reward = SafeMath.div(temp,100);
        uint256 a = SafeMath.mul(amt,reward);
        uint256 b = SafeMath.div(a,10**8);
        fee_collected = SafeMath.add(fee_collected,b);
    }
    
    /* Create a new pool after 3 days */
    
    function createPool(uint256[10] memory _prices) public returns(bool){
        require(msg.sender == owner,'Not Owner');
        require( block.timestamp > lastpoolcreated +  3 days,'Cannot Create');
        Pool storage b = pool[poolId];
        b.prices = _prices;
        b.startime = block.timestamp;
        lastpoolcreated = block.timestamp;
        lastcreated = block.timestamp;
        b.endtime = SafeMath.add(block.timestamp,3 days);
        b.stakingends = SafeMath.add(block.timestamp,1 days);
        poolId = SafeMath.add(poolId,1);
        return true;
    }
    
    /* Update new owner of the contract */
    
    function updateowner(address new_owner) public returns(bool){
        require(msg.sender == owner,'Not an Owner');
        owner = new_owner;
        return true;
    }
    
    /* Update the timestamp of the last creted pool. this function cannot change the pool time. Last created variable is for display sake. */
    
    function updatetime(uint256 _timestamp) public returns(bool){
        require(msg.sender == owner,'Not an owner');
        lastcreated =  _timestamp;
    }
    
    /* Allows the user to withdraw his claimable balance from the contract */
    
    function withdraw() public nonReentrant returns(bool){
       User storage us = user[msg.sender];
       require(us.active == true,'Invalid User'); 
       require(us.freebal > 0,'No bal');
       pool_address.transfer(msg.sender,us.freebal);
       us.freebal = 0;
       return true;
    }
    
    /*  Fetch the information about user. His claimable balance, fixed balance & stuff */
     
    function fetchUser(address _user) public view returns(uint256[] memory _pools,string memory username,uint256 claimable,uint256 staked_balance, bool active){
        User storage us = user[_user];
        return(us.pools,us.username,us.freebal,us.balance,us.active);
    }
    
    /* Fetch the information of a PoolId */
    
    function fetchPool(uint256 _poolId) public view returns(uint256[10] memory _prices,uint256 _start,uint256 _end,uint256 _staking_ends){
        Pool storage b = pool[_poolId];
        return(b.prices,b.startime,b.endtime,b.stakingends);
    }
    
    /* Fetch the prediction information of each user in each pool. Pass poolId and User Address to get the strike price as well as the amount in 18 decimals */
    
    function fetchUserBets(address _user, uint256 _poolId) public view returns(uint256[10] memory _pools,uint256[10] memory _prices,uint256[10] memory _amounts,uint256 balance,uint256 totalbet){
        UserBets storage u = bets[_user][_poolId];
        return (u.pools,u.prices,u.amounts,u.balance,u.totalbet);
    }
    
    /* Fetch all the user wallet predicted in a poolId. Pass poolId and will return an array of betters */
    
    function fetchUserInPool(uint256 _poolId) public view returns(address[] memory _betters){
        Data storage d = data[_poolId];
        return d.user;
    }
    
    /*  
        Only Allow the Developer to withdraw the developer fee
    */
    
    function collectdeveloperfee() public nonReentrant returns(bool){
        require(msg.sender == owner,'To Be Claimed By Developer');
        pool_address.transfer(msg.sender,fee_collected);
        fee_collected = 0;
        return true;
    }
    
}
pragma solidity ^0.5.4;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    /**
     * @dev 冻结用户货币
     */
    mapping (address => bool) private frozenAccount;
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
   /**
        获取现在时间
        返回当前的秒数
    */
    function getNow() public view returns (uint256 nowvalue) {
        return now;
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
    冻结或解冻用户账户
     */
    function _freezeAccount(address target, bool freeze)  internal returns (bool)
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev 权第三方（比如某个服务合约）从发送者账户转移代币
     * 账户A有1000个TRX，想允许B账户随意调用他的100个TRX，过程如下:
     *
     * A账户按照以下形式调用approve函数approve(B,100)
     * B账户想用这100个TRX中的10个ETH给C账户，调用transferFrom(A, C, 10)
     * 调用allowance(A, B)可以查看B账户还能够调用A账户多少个token
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
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
     * @dev 自动增加调用者授予“spender”的津贴。
     *
     * 这是{approve}的一种替代方法，可以用作{IERC20 approve}中描述的问题。
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
        require(!frozenAccount[sender], "this account has frozen");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount,"sender amount Not enough");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev 创建“amount”标记并将其分配给“account”，增加总供应量。
     *
     * Emits a {Transfer} event with `from` set to the zero address.
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
    检查账号是否被冻结
    */
    function checkFreeze(address sender) public view returns(bool)
    {
        return frozenAccount[sender];
    }
     /**
     * @dev 销毁“account”中的“amount”标记，减少总供应量。
     *
     * Emits a {Transfer} event with `to` set to the zero address.
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
     * Emits an {Approval} event.
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
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

}

pragma solidity ^0.5.4;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.4;

library Entitys {
  
    enum GameStatus{
        Ing,
        Done

    }


    struct GameStruct {

        uint game_id;
   
        string name;

        uint begin_time;
     
        uint game_times;

        uint last_buy_time;

 
        uint over_time;
  
        uint base_prce;

        uint256 price;


        uint256 base_price_upper_rate;

   
        uint256 price_upper_rate;


        GameStatus status;
 
        uint256 prize_value; 

  
        uint256 bonus_value; 



        uint buy_count;


        address last_buy_user_address;


        uint next_change_rate_count;


    }
    struct UserBenefitAndInvestment {

 
        uint256 shouyi;

 
        uint256 touru;


        address recommend_user_address;
    

        bool isValue;


    }
}

pragma solidity ^0.5.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev 返回存在的令牌数量。
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev 返回“account”拥有的令牌数量。
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 将“amount”令牌从调用者的帐户移到“recipient”。
     *
     * 返回一个布尔值，指示操作是否成功。
     *
     * 发出{Transfer}事件。
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev 返回“spender”将使用的剩余令牌数
     * 允许通过{transferFrom}代表“所有者”消费。这是
     * 默认为零。
     *
     * 调用{approve}或{transferFrom}时，此值会更改。
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev 将“amount”设置为“spender”在调用方令牌上的余量。
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
     * @dev 将“amount”标记从“sender”移动到“recipient”
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

    /**
    冻结或解冻用户账户的事件
     */
    event FrozenFunds(address target, bool frozen);
}

pragma solidity ^0.5.4;

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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        if (b == 0) {
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

pragma solidity ^0.5.4;

import "./SafeMath.sol";
import "./Entitys.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

/***
    game contract
 */
contract lira is ERC20, ERC20Detailed {
    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    using SafeMath for uint256;

    uint256 private _trx_decimals = 18;
    uint256 private _price_upper_decimals = 18;
    //game fee
    uint256 private _fee_rate = 10;
    /**recommend fee */
    uint256 private _recommend_rate = 10;
    address private _owner;

    /**bonus fee */
    uint256 private _bonus_rate = 45;

    /*backfee */
    uint256 private _feeback_rate = 5;

    //current game
    Entitys.GameStruct private current_game;

    //user buy record
    address[] private game_buy_users;

    /***
    game->user->shouyi
    */
    mapping(address => Entitys.UserBenefitAndInvestment)
        private game_investment_benefit;
    /**
    game->user->chiyouliang
     */
    mapping(address => uint256) private game_user_buy_count;


    //user->rercommend
    mapping(address => uint256) private user_recommend_value;

    mapping(address => uint256) private user_credit_log;

    //airdrop value
    uint256 private buy_airdrop_mtb_count = uint256(1000000);

    constructor(
        uint256 _game_id,
        string memory _name,
        uint256 _game_times,
        uint256 _price,
        uint256 _price_upper_rate
    ) public ERC20Detailed("LIRA", "LIRA", uint8(_trx_decimals)) {
        _owner = msg.sender;
        uint256 temp_now = now;
        uint256 _last_buy_time = temp_now;
        uint256 _over_time = temp_now.add(_game_times);
        uint256 _buy_price = _price * (10**uint256(_trx_decimals)).div(10**2);
        uint256 price_upper_rate = _price_upper_rate.mul(
            10**_price_upper_decimals
        ); //1^18
        uint256 _next_change_rate_count = 70;
        current_game = Entitys.GameStruct({
            game_id: _game_id,
            name: _name,
            begin_time: temp_now,
            game_times: _game_times,
            last_buy_time: _last_buy_time,
            over_time: _over_time,
            base_prce: _buy_price,
            price: _buy_price,
            base_price_upper_rate: price_upper_rate,
            price_upper_rate: price_upper_rate,
            status: Entitys.GameStatus.Ing,
            prize_value: 0,
            bonus_value: 0,
            buy_count: 0,
            last_buy_user_address: _owner,
            next_change_rate_count: _next_change_rate_count
        });

        _mint(msg.sender, 10_000_000_000 * (10**uint256(decimals())));
    }

    function ChangeOwner(address new_owner)  public onlyOwner returns (bool) {
        _owner = new_owner;
        return true;
    } 


    function getDecimals() public view returns (uint256) {
        return _trx_decimals;
    }


    function getOwner() public view returns (address) {
        return _owner;
    }


    function getCurrentRoundInfo()
        public
        view
        returns (
            uint256 game_id,
            string memory name,
            uint256 begin_time,
            uint256 game_times,
            uint256 last_buy_time,
            uint256 over_time,
            uint256 price,
            uint256 price_upper_rate,
            Entitys.GameStatus status,
            uint256 prize_value,
            uint256 bonus_value,
            uint256 buy_count,
            address last_buy_user_address,
            uint256 next_change_rate_count
        )
    {
        Entitys.GameStruct memory game = current_game;
        game_id = game.game_id;
        name = game.name;
        begin_time = game.begin_time;
        game_times = game.game_times;
        last_buy_time = game.last_buy_time;
        over_time = game.over_time;
        price = game.price;
        price_upper_rate = game.price_upper_rate;
        status = game.status;
        prize_value = game.prize_value;
        buy_count = game.buy_count;
        bonus_value = game.bonus_value;
        last_buy_user_address = game.last_buy_user_address;
        next_change_rate_count = game.next_change_rate_count;
        return (
            game_id,
            name,
            begin_time,
            game_times,
            last_buy_time,
            over_time,
            price,
            price_upper_rate,
            status,
            prize_value,
            bonus_value,
            buy_count,
            last_buy_user_address,
            next_change_rate_count
        );
    }

    function askprice() public view returns (uint256 price) {
        Entitys.GameStruct memory game = current_game;
        return game.price;
    }

    function ask_bulk_price(uint256 buy_count)
        public
        view
        returns (
            uint256 total_price,
            uint256 last_price,
            uint256[] memory price_list
        )
    {
        Entitys.GameStruct memory game = current_game;
        require(buy_count >= 1, "10005");
        total_price = 0;
        last_price = game.price; 
        price_list = new uint256[](buy_count);
        uint256 temp_buy_count = game.buy_count; 
        uint256 temp_price_rate = game.price_upper_rate; 
        uint256 temp_next_change_rate_count = game.next_change_rate_count;
        for (uint256 i = 0; i < buy_count; i++) {
            total_price = total_price.add(last_price);
            price_list[i] = last_price;
            temp_buy_count = temp_buy_count.add(1); 
            if (temp_buy_count == temp_next_change_rate_count) {
                temp_price_rate = temp_price_rate.div(2); 
                temp_next_change_rate_count = temp_next_change_rate_count.mul(2);
            }
            uint256 _price_upper_rate = temp_price_rate
            .div(10**_price_upper_decimals)
            .add(100);
            last_price = last_price.mul(_price_upper_rate).div(100);
        }
        return (total_price, last_price, price_list);
    }


    event BuyGameEvent(
        address bidder,
        uint256 amount,
        uint256 buy_time,
        string event_msg
    );

    function checkRecommend(address recommend_user)
        private
        view
        returns (bool)
    {
        if (recommend_user == address(0)) {
            return false;
        }
        if (recommend_user == _owner) {
            return true;
        }
        if (game_investment_benefit[recommend_user].isValue) {
            return true;
        }
        return false;
    }

    function bulk_buy_token(address recommend_user, uint256 buy_count)
        public
        payable
        returns (bool success)
    {
        require(checkRecommend(recommend_user), "10001");
        require(buy_count >= 1, "10005");
        Entitys.GameStruct memory game = current_game;
        require(game.game_id != uint256(0), "10000");
        uint256 amount = msg.value;
        address buyer = msg.sender; 
        uint256 total_price;
        uint256 last_price;
        uint256[] memory price_list;
        (total_price, last_price, price_list) = ask_bulk_price(buy_count);
        require(amount >= total_price, "10007");
        require(price_list.length == buy_count, "10005");
        uint256 temp_total_price = 0;
        for (uint256 i = 0; i < buy_count; i++) {
            temp_total_price = temp_total_price.add(price_list[i]);
        }
        require(temp_total_price == total_price, "10005");
        for (uint256 i = 0; i < buy_count; i++) {
            uint256 item_amount = price_list[i];
            buy_token_internal(recommend_user, item_amount, buyer);
        }
        if(success)
        {
              emit BuyGameEvent(buyer, amount, now, "Buy");
        }
        success = true;
    }

    function update_game_investment_benefit(
        address user,
        address recommend_user,
        uint256 recommend_value,
        uint256 buy_value
    ) private returns (address c_recommend_user) {
   
        Entitys.UserBenefitAndInvestment memory bi = game_investment_benefit[
            user
        ];
        address temp_recommend_user = address(0);
        if (bi.isValue) {
            temp_recommend_user = bi.recommend_user_address;
        }
        if (temp_recommend_user == address(0)) {
            temp_recommend_user = recommend_user;
        }
        if (temp_recommend_user == address(0)) {
            temp_recommend_user = _owner;
        }
        c_recommend_user=temp_recommend_user;
        address(uint160(temp_recommend_user)).transfer(recommend_value); //发放推荐奖励

        user_recommend_value[temp_recommend_user] = user_recommend_value[
            temp_recommend_user
        ]
        .add(recommend_value);
        if (bi.isValue) {
            bi = game_investment_benefit[user];
            bi.recommend_user_address = temp_recommend_user;
        } else {

            bi = Entitys.UserBenefitAndInvestment(
                0,
                0,
                temp_recommend_user,
                true
            );

            game_buy_users.push(user);
        }
        bi.touru = bi.touru.add(buy_value);

        game_investment_benefit[user] = bi;
    }

    function buy_token_internal(
        address recommend_user,
        uint256 amount,
        address buyer
    ) private returns (bool success) {
        address buy_user = buyer;
        uint256 buy_value = amount;
        require(checkRecommend(recommend_user), "10001");
        Entitys.GameStruct memory game = current_game;
        require(game.game_id != uint256(0), "10000");
        uint256 current_price = game.price;
        uint256 current_buy_count = game.buy_count; 
        if (current_buy_count == uint256(0)) {
            current_buy_count = 1;
        }

        current_buy_count = GetEffectiveBuyCount(current_buy_count); 

        require(game.status == Entitys.GameStatus.Ing, "10002");
        require(game.over_time > now, "10003");
        require(current_price <= buy_value, "10004");
        uint256 recommend_value = buy_value.mul(_recommend_rate).div(100);
        uint256 platform_value = buy_value.mul(_fee_rate).div(100);
        uint256 bonus_value = buy_value.mul(_bonus_rate).div(100);
        uint256 fee_back_value = buy_value.mul(_feeback_rate).div(100);
        address temp_recommend_user = update_game_investment_benefit(
            buy_user,
            recommend_user,
            recommend_value,
            buy_value
        );
        for (uint256 i = 0; i < game_buy_users.length; i++) {
            address temp_user = game_buy_users[i];
            delete user_credit_log[temp_user];
        }

        address(uint256(_owner)).transfer(platform_value); 
        address back_user = buy_user;
        if (temp_recommend_user == _owner) {
            back_user = _owner;
        }
        address(uint160(back_user)).transfer(fee_back_value); 
        uint256 temp_prize_value = buy_value.sub(recommend_value); 
        temp_prize_value = temp_prize_value.sub(platform_value); 
        temp_prize_value = temp_prize_value.sub(fee_back_value); 
        uint256 used_bonus_value = uint256(0);
        for (uint256 i = 0; i < game_buy_users.length; i++) {
            address temp_user = game_buy_users[i];
            uint256 user_buy_count = game_user_buy_count[temp_user];
            uint256 temp_bonus_value = uint256(0);

            if (CheckUserCanBonus(temp_user)) {
                temp_bonus_value = bonus_value.mul(user_buy_count).div(
                    current_buy_count
                );
                used_bonus_value = used_bonus_value.add(temp_bonus_value);
                user_credit_log[temp_user] = user_credit_log[temp_user].add(
                    temp_bonus_value
                );
            }
        }
        temp_prize_value = temp_prize_value.sub(used_bonus_value); 
        for (uint256 i = 0; i < game_buy_users.length; i++) {
            address temp_user = game_buy_users[i];
            uint256 t_amount = user_credit_log[temp_user];
            if (t_amount > 0) {
                Entitys.UserBenefitAndInvestment memory temp_bi
                 = game_investment_benefit[temp_user];
                if (temp_bi.isValue) {
                    temp_bi.shouyi = temp_bi.shouyi.add(t_amount);
                } else {
                    temp_bi = Entitys.UserBenefitAndInvestment(
                        t_amount,
                        0,
                        address(0),
                        true
                    );
                }
                game_investment_benefit[temp_user] = temp_bi;
                address(uint160(temp_user)).transfer(t_amount);
            }
        }
        for (uint256 i = 0; i < game_buy_users.length; i++) {
            address temp_user = game_buy_users[i];
            delete user_credit_log[temp_user];
        }


        calcGameRate(buy_user, temp_prize_value, used_bonus_value);
      

        _transfer(
            _owner,
            buy_user,
            buy_airdrop_mtb_count * (10**uint256(decimals()))
        );
        return true;
    }

    function buy_token(address recommend_user)
        public
        payable
        returns (bool success)
    {
        uint256 amount = msg.value; 
        address buyer = msg.sender; 
        success= buy_token_internal(recommend_user, amount, buyer);
        if(success)
        {
              emit BuyGameEvent(buyer, amount, now, "Buy");
        }
    }


    function calcGameRate(
        address buyer,
        uint256 prize_value,
        uint256 used_bonus_value
    ) private returns (bool) {
        uint256 _now = now;
        Entitys.GameStruct memory game = current_game;
        current_game.last_buy_user_address = buyer;
        current_game.prize_value = game.prize_value.add(prize_value); 
        uint256 current_buy_count = game.buy_count.add(1);
        current_game.buy_count = current_buy_count; 
        game_user_buy_count[buyer] = game_user_buy_count[buyer].add(1);
        current_game.last_buy_time = _now; 
        current_game.over_time = _now.add(game.game_times); 
        if (current_buy_count == game.next_change_rate_count) {
            uint256 temp_price_rate = game.price_upper_rate.div(2); 
            game.price_upper_rate = temp_price_rate;
            game.next_change_rate_count = game.next_change_rate_count.mul(2);
            current_game.price_upper_rate = temp_price_rate;
            current_game.next_change_rate_count = game.next_change_rate_count;
        }
        uint256 _price_upper_rate = game
        .price_upper_rate
        .div(10**_price_upper_decimals)
        .add(100);
        current_game.price = game.price.mul(_price_upper_rate).div(100);
        current_game.bonus_value = current_game.bonus_value.add(
            used_bonus_value
        );
    }


    function GetEffectiveBuyCount(uint256 current_buy_count)
        private
        view
        returns (uint256 effective_count)
    {
        effective_count = current_buy_count;
        uint256 threshold_value = uint256(3).mul(10**_trx_decimals);
        for (uint256 i = 0; i < game_buy_users.length; i++) {
            address temp_user = game_buy_users[i];
            if (temp_user == _owner) {
                continue;
            }
            Entitys.UserBenefitAndInvestment memory temp_bi= game_investment_benefit[temp_user];
            uint256 user_buy_count = game_user_buy_count[temp_user];
            if (temp_bi.isValue && user_buy_count > 0) {
                uint256 shouyilv = temp_bi.shouyi.div(temp_bi.touru).mul(
                    10**_trx_decimals
                );
                if (shouyilv >= threshold_value) {
                    effective_count = current_buy_count.sub(user_buy_count);
                }
            }
        }
        return effective_count;
    }


    function CheckUserCanBonus(address user)
        private
        view
        returns (bool can_bonus)
    {
        can_bonus = true;
        if (user == _owner) {
            return true;
        }

        uint256 threshold_value = uint256(3).mul(10**_trx_decimals);

            Entitys.UserBenefitAndInvestment memory temp_bi
         = game_investment_benefit[user];
   
        uint256 user_buy_count = game_user_buy_count[user];
        if (temp_bi.isValue && user_buy_count > 0) {

            uint256 shouyilv = temp_bi.shouyi.div(temp_bi.touru).mul(
                10**_trx_decimals
            );
            if (shouyilv >= threshold_value) {
                can_bonus = false;
            }
        }
        return can_bonus;
    }

    function getBuyerBuyCount(address buyer) public view returns (uint256) {
        return game_user_buy_count[buyer];
    }


    function getBuerIncomeInvestment(address buyer)
        public
        view
        returns (
            uint256 income,
            uint256 investment,
            uint256 recommend_value,
            uint256 buy_count
        )
    {
        Entitys.UserBenefitAndInvestment memory bi = game_investment_benefit[
            buyer
        ];
        income = bi.touru;
        investment = bi.shouyi;
        recommend_value = user_recommend_value[buyer];
        buy_count = game_user_buy_count[buyer];
        return (income, investment, recommend_value, buy_count);
    }

    function checkGameAndPrize() public view onlyOwner returns (bool) {
        require(_owner == msg.sender, "Must Owner Execute");
        uint256 _now = now;
        Entitys.GameStruct memory game = current_game;
        if (game.over_time <= _now) {
            return true;
        }
        return false;
    }

    function PrizeGame() public onlyOwner returns (bool) {
        require(_owner == msg.sender, "Must Owner Execute");
        uint256 _now = now;
        Entitys.GameStruct memory game = current_game;
        if (game.over_time <= _now) {
    
            if (game.last_buy_user_address != address(0)) {
                if (game.prize_value > 0) {
        
                    address(uint160(game.last_buy_user_address)).transfer(
                        game.prize_value
                    );
                }
            }

            for (uint256 i = 0; i < game_buy_users.length; i++) {
                address temp_user = game_buy_users[i];
                delete game_investment_benefit[temp_user];
                delete game_user_buy_count[temp_user];
                delete user_recommend_value[temp_user];
            }
            delete game_buy_users;
    

            uint256 temp_now = now;
            uint256 _last_buy_time = temp_now;
            uint256 _over_time = temp_now.add(game.game_times);
            uint256 _buy_price = game.base_prce; //1^6
            uint256 price_upper_rate = game.base_price_upper_rate; //1^18
            uint256 next_change_rate_count = 70;
            uint256 game_id = game.game_id.add(1);
            current_game = Entitys.GameStruct(
                game_id,
                game.name,
                temp_now,
                game.game_times,
                _last_buy_time,
                _over_time,
                _buy_price,
                _buy_price,
                price_upper_rate,
                price_upper_rate,
                Entitys.GameStatus.Ing,
                0,
                0,
                0,
                _owner,
                next_change_rate_count
            );
            return true;
        }
        return false;
    }

    function kill() public onlyOwner returns (bool) {
        if (_owner == msg.sender) {
            Entitys.GameStruct memory game = current_game;
            if (game.prize_value > 0) {
                address(uint160(_owner)).transfer(game.prize_value);
                selfdestruct(msg.sender);
                return true;
            }
        }
        return false;
    }


    function freezeAccount(address target, bool freeze)
        public
        onlyOwner
        returns (bool)
    {
        require(_owner != target, "can not freeze owner");
        return _freezeAccount(target, freeze);
    }


    function mintToken(uint256 mintedAmount) public onlyOwner returns (bool) {
        _mint(_owner, mintedAmount * (10**uint256(decimals())));
        return true;
    }
}
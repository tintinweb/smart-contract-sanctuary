/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.6.0;

contract Owned {
    //address payable private Owner;
    address payable internal Owner;
    constructor() public{
        Owner = msg.sender;
    }

    function IsOwner(address addr) view public returns(bool)
    {
        return Owner == addr;
    }

    function TransferOwner(address payable newOwner) public onlyOwner
    {
        Owner = newOwner;
    }

    function Terminate() public onlyOwner
    {
        selfdestruct(Owner);
    }

    modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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

contract RR is ERC20 {
    mapping(address => uint32) public creatorToSeason; 
    mapping(address => mapping(uint32 => address)) public creatorToSeasonToContract;
    mapping(address => mapping(address => mapping(uint32 => uint256))) public staked;
    mapping(address => uint256) public totalStaked;
    
    uint256 pricepertoken = 1 finney;
    address payable saleaddress;
    
    constructor(uint256 initSupply, address payable a) public ERC20("Ruined Reign Token", "RR") {
        _mint(a, initSupply);
        saleaddress = a;
    }
    
    function purchaseTokens() external payable {
        _transfer(saleaddress, msg.sender, msg.value/pricepertoken*1000000000000000000);
        emit Purchased(msg.sender, msg.value/pricepertoken*1000000000000000000);
    }
    
    function recoverEth() external {
        require(msg.sender == saleaddress);
        saleaddress.transfer(address(this).balance);
    }
    
    function NewSeason(address _core) public{
        creatorToSeason[msg.sender]++;
        creatorToSeasonToContract[msg.sender][creatorToSeason[msg.sender]] = _core;
        
        emit SeasonStarted(msg.sender, creatorToSeason[msg.sender], _core);
    }
    function Stake(address creator, uint32 season, uint256 amt) public{
        require(creatorToSeasonToContract[creator][season] != address(0), 'invalid season');
        Eth_Risk_Core core = Eth_Risk_Core(creatorToSeasonToContract[creator][season]);
        require(core.get_passable_threshold() == core.passable_threshold(), 'staking period has ended');
        require(balanceOf(msg.sender) >= amt, 'Insufficient balance');
        _transfer(msg.sender, creatorToSeasonToContract[creator][season], amt);
        staked[msg.sender][creator][season] += amt;
        totalStaked[creatorToSeasonToContract[creator][season]] += amt;
        
        emit Staked(msg.sender, creator, season, amt);
    }
    function Claim(address creator, uint32 season) public {
        require(creatorToSeasonToContract[creator][season] != address(0), 'invalid season');
        Eth_Risk_Core core = Eth_Risk_Core(creatorToSeasonToContract[creator][season]);
        require(core.ending_balance() > 0, 'season has not yet ended');
        require(staked[msg.sender][creator][season] > 0, 'no tokens staked');
        _transfer(creatorToSeasonToContract[creator][season], msg.sender, staked[msg.sender][creator][season]);    
        uint256 stake = staked[msg.sender][creator][season];
        staked[msg.sender][creator][season] = 0;
        
        core.RRaward(msg.sender, core.ending_balance() * stake / totalStaked[creatorToSeasonToContract[creator][season]] / core.pool_div());
        emit Claimed(msg.sender, creator, season, core.ending_balance() / core.pool_div() * stake / totalStaked[creatorToSeasonToContract[creator][season]]);
    }
    
    event SeasonStarted(address indexed creator, uint32 season, address contract_address);
    event Staked(address indexed staker, address indexed creator, uint32 season, uint256 amt);
    event Claimed(address indexed, address indexed creator, uint32 season, uint256 award);
    event Purchased(address indexed buyer, uint256 amt);
}

contract Eth_Risk_Core is Owned{
    uint256 land_wei_price = 1000000000000;
    uint256 unit_wei_price = 10000000000;
    uint256 unit_gold_price = 100000;
	uint256 blocks_per_round = 4000;
	uint256 deployed_at_block;
	uint256 public ending_balance;
	uint256 public pool_nom = 9;
	uint256 public pool_div = 10;

    uint8 max_upgrades = 3;
	uint8 public passable_threshold = 121;
	uint8 victory_threshold = 169;
	uint8 threshold_increment = 6;
	uint8 max_units = 99;
	uint32 total_victory_tiles_owned;
    uint32 treatyID;
	bool firstWithdraw = true;
	address rraddress;
    RR rr;
    
    mapping(uint8 => mapping(uint8 => uint8)) public tile_development_level;
    mapping(uint8 => mapping(uint8 => address payable)) public tile_owner;
    mapping(uint8 => mapping(uint8 => uint8)) public units_on_tile;
    mapping(address => uint256) gold_balances;
    mapping(address => uint256) public gold_per_second;
	mapping(address => uint256) last_GPH_update_time;
	mapping(address => uint32) public victory_tiles_owned;
	mapping(address => bool) public withdrew;
	mapping(uint8 => mapping(uint8 => uint256)) market_price;

	constructor (address rrtoken) public {
		deployed_at_block = block.number;
		rr = RR(rrtoken);
		rraddress = rrtoken;
	}

    function set_land_wei_price(uint256 new_price) public onlyOwner {
        land_wei_price = new_price;
    }
    function set_unit_wei_price(uint256 new_price) public onlyOwner {
        unit_wei_price = new_price;
    }
    function set_unit_gold_price(uint256 new_price) public onlyOwner {
        unit_gold_price = new_price;
    }

	function dep() public view returns (uint256){
		return deployed_at_block;
	}

	function get_passable_threshold() public view returns(uint8){
		if((block.number - deployed_at_block)/blocks_per_round > 8){return victory_threshold;}
		return (passable_threshold + uint8((block.number - deployed_at_block)/blocks_per_round * threshold_increment));
	}

	function get_season_ended() public view returns(bool){
		return get_passable_threshold() >= victory_threshold;
	}
    
	function withdraw_winnings() public payable{
		require(get_season_ended(), 'Season hasnt ended');
		require(!withdrew[msg.sender], 'Already withdrew');
		if(firstWithdraw){
			firstWithdraw = false;
			ending_balance = address(this).balance;
		}
		withdrew[msg.sender] = true;
		msg.sender.transfer(get_winnings());
	}

	function get_winnings() public view returns(uint256){
		if(total_victory_tiles_owned == 0){ return 0; }
		if(ending_balance == 0){ return address(this).balance*pool_nom/pool_div * victory_tiles_owned[msg.sender] / total_victory_tiles_owned; }
		return ending_balance*pool_nom/pool_div * victory_tiles_owned[msg.sender] / total_victory_tiles_owned;
	}
	
	function RRaward(address payable a, uint256 amt) external {
	    require(msg.sender == rraddress, 'sender wasnt ruined reign token address');
	    a.transfer(amt);
	}

	function get_pool_total() public view returns(uint256){
		if(get_season_ended()){ return ending_balance*pool_nom/pool_div; }
		return address(this).balance*pool_nom/pool_div;
	}

    function get_gold_value_of_tile(uint8 x, uint8 y) public view returns(uint8){
		if(tile_development_level[x][y] == 0){return uint8(10000/get_tile(x,y));}
        else{return uint8(60000/get_tile(x,y)) * tile_development_level[x][y];} //cityfactor = 6
    }
	function get_gold(address a) public view returns(uint){
		return gold_balances[a] + gold_per_second[a]*(block.timestamp - last_GPH_update_time[a]);
	}
	function get_land_price(uint8 x, uint8 y) public view returns(uint256){
		return land_wei_price * uint256(get_tile(x, y)) * uint256(get_tile(x,y));
	}
	function get_unit_price(uint8 x, uint8 y) public view returns(uint256){
		return unit_wei_price * uint256(get_tile(x, y)) * uint256(get_tile(x,y));
	}
	function get_height(uint8 x, uint8 y) public view returns(uint8){
		return 1 + (uint8(get_tile(x, y)) - passable_threshold)/threshold_increment;
	}

	function market_sell(uint8 x, uint8 y, uint256 price) public {
		require(!get_season_ended(), 'Season has ended');
		require(tile_owner[x][y] == msg.sender, 'Sender isnt owner');
		require(get_tile(x, y) > get_passable_threshold(), 'Tile impassable');
		require(price > 0, 'Invalid price');
		market_price[x][y] = price;
		emit Market_Posted(x, y, msg.sender, price);
	}

	function market_buy(uint8 x, uint8 y) public payable{
		require(!get_season_ended(), 'Season has ended');
		require(market_price[x][y] != 0, 'Land not for sale');
		require(msg.value == market_price[x][y], 'Invalid purchase price');
		address payable seller = tile_owner[x][y];
		market_price[x][y] = 0;
		if(get_tile(x, y) > victory_threshold){
			victory_tiles_owned[msg.sender]++; //overflow not possible
			victory_tiles_owned[seller]--; //underflow not possible
		}
		tile_owner[x][y] = msg.sender;
		seller.transfer(msg.value);
		emit Market_Bought(x, y, msg.sender);
	}

    function buy_land_with_wei(uint8 tile_x, uint8 tile_y, uint8 unit_count, uint8 dev_lev) public payable {
		require(!get_season_ended(), 'Season has ended');
        require(msg.value == get_land_price(tile_x, tile_y)*dev_lev + unit_count*get_unit_price(tile_x, tile_y), 'Invalid payment');
        require(tile_owner[tile_x][tile_y] == address(0) || tile_owner[tile_x][tile_y] == msg.sender, 'Tile already owned');
		require(get_tile(tile_x, tile_y) > get_passable_threshold(), 'Tile impassable');
		require(get_tile(tile_x, tile_y) <= get_passable_threshold() + threshold_increment, 'Tile inland'); 
		require(units_on_tile[tile_x][tile_y] + unit_count <= max_units, 'Buying too many units');
		require(unit_count >= 1, 'Buying too few units');
		require(dev_lev <= max_upgrades, 'Development level over max');
		
		tile_development_level[tile_x][tile_y] = dev_lev;
		gold_balances[msg.sender] = get_gold(msg.sender);
        gold_per_second[msg.sender] += get_gold_value_of_tile(tile_x, tile_y);
		last_GPH_update_time[msg.sender] = block.timestamp;
        tile_owner[tile_x][tile_y] = msg.sender;
        units_on_tile[tile_x][tile_y] = unit_count;

        emit Land_Bought(tile_x, tile_y, msg.sender, units_on_tile[tile_x][tile_y], dev_lev);
    }
    function buy_units_with_wei(uint8 tile_x, uint8 tile_y, uint8 unit_count) public payable {
		require(!get_season_ended(), 'Season has ended');
        require(msg.value >= get_unit_price(tile_x, tile_y) * unit_count, 'Insufficient payment');
        require(tile_owner[tile_x][tile_y] == address(msg.sender), 'Sender isnt owner');
		require(tile_development_level[tile_x][tile_y] > 0, 'Tile isnt colonized');
		require(units_on_tile[tile_x][tile_y] + unit_count <= max_units, 'Sum over max units');
		require(units_on_tile[tile_x][tile_y] + unit_count > units_on_tile[tile_x][tile_y], 'Units zero or overflow');

        units_on_tile[tile_x][tile_y] += unit_count;
		emit New_Population(tile_x, tile_y, units_on_tile[tile_x][tile_y]);
    }
    function buy_units_with_gold(uint8 tile_x, uint8 tile_y, uint8 unit_count) public {
		require(!get_season_ended(), 'Season has ended');
        require(tile_owner[tile_x][tile_y] == address(msg.sender), 'Sender isnt owner');
        require(get_gold(msg.sender) >= (unit_gold_price*unit_count), 'Insufficient gold');
		require(tile_development_level[tile_x][tile_y] > 0, 'Tile isnt colonized');
		require(unit_count <= max_units, 'Buying too many units');
		require(units_on_tile[tile_x][tile_y] + unit_count <= max_units, 'Sum over max units');
		require(units_on_tile[tile_x][tile_y] + unit_count > units_on_tile[tile_x][tile_y], 'Units zero or overflow');

		last_GPH_update_time[msg.sender] = block.timestamp;
        gold_balances[msg.sender] = get_gold(msg.sender) - unit_gold_price*unit_count;
        units_on_tile[tile_x][tile_y] += unit_count;
		emit New_Population(tile_x, tile_y, units_on_tile[tile_x][tile_y]);
    }

    function transfer_gold(address to, uint256 gold) public {
        //TODO: overflow check here
        require(gold_balances[msg.sender] >= gold, 'Insufficient gold');
        gold_balances[msg.sender] -= gold;
        gold_balances[to] += gold;
		emit Gold_Transferred(msg.sender, to, gold);
    }

    function transfer_land(uint8 tile_x, uint8 tile_y, address payable new_address) public {
        require(tile_owner[tile_x][tile_y] == msg.sender);
		require(!get_season_ended(), 'Season has ended');
		if(get_tile(tile_x, tile_y) > victory_threshold){
			victory_tiles_owned[msg.sender]--; //overflow not possible
			victory_tiles_owned[new_address]++; //underflow not possible
		}
		market_price[tile_x][tile_y] = 0;
        tile_owner[tile_x][tile_y] = new_address;
        emit Land_Transferred(tile_x, tile_y, msg.sender);
    }

    function move(uint8 x_from, uint8 y_from, uint8 x_to, uint8 y_to, uint8 units) public {
		require(units > 0, 'Moving zero units');
		require(!get_season_ended(), 'Season has ended');
        require(tile_owner[x_from][y_from] == msg.sender, 'Sender doesnt own from tile');
        require(units_on_tile[x_from][y_from] - 1 >= units, 'Moving too many units'); //attacker must leave one unit in from tile
        require(get_tile(x_to, y_to) > get_passable_threshold(), 'Tile impassable');
		if(y_from % 2 == 0)
		{
			require((y_to == y_from + 1 && x_to == x_from) || 
					(y_to == y_from - 1 && x_to == x_from) ||
					(y_to == y_from && x_to == x_from + 1) ||
					(y_to == y_from && x_to == x_from - 1) ||
					(y_to == y_from + 1 && x_to == x_from - 1) ||
					(y_to == y_from - 1 && x_to == x_from - 1), 'Tile not adjacent');
		}
		else
		{
			require((y_to == y_from + 1 && x_to == x_from) || 
						(y_to == y_from - 1 && x_to == x_from) ||
						(y_to == y_from && x_to == x_from + 1) ||
						(y_to == y_from && x_to == x_from - 1) ||
						(y_to == y_from + 1 && x_to == x_from + 1) ||
						(y_to == y_from - 1 && x_to == x_from + 1), 'Tile not adjacent');
		}

		if(tile_owner[x_to][y_to] == address (0x00)){
				units_on_tile[x_from][y_from] -= units;
				units_on_tile[x_to][y_to] = units;
				tile_owner[x_to][y_to] = msg.sender;

				if(get_tile(x_to, y_to) > victory_threshold){
					total_victory_tiles_owned++;
					victory_tiles_owned[msg.sender]++;
				}
				gold_balances[msg.sender] = get_gold(msg.sender);
				gold_per_second[msg.sender] += get_gold_value_of_tile(x_to,y_to);
				last_GPH_update_time[msg.sender] = block.timestamp;

				emit Land_Transferred(x_to, y_to, msg.sender);
			}
        else if(tile_owner[x_to][y_to] == msg.sender){
			require(units_on_tile[x_to][y_to] + units <= max_units, 'Moving too many units');
            require(units_on_tile[x_to][y_to] + units > units_on_tile[x_to][y_to], 'Units overflow, or sent zero');
			units_on_tile[x_from][y_from] -= units;
            units_on_tile[x_to][y_to] += units;
        }
        else {			 
            //battle
			if(tile_development_level[x_to][y_to] > 0){
				if(units/tile_development_level[x_to][y_to] == units_on_tile[x_to][y_to]) { 
					//defender advantage
					units_on_tile[x_to][y_to] = 1;
					units_on_tile[x_from][y_from] -= units;
				}
				else if(units/tile_development_level[x_to][y_to] > units_on_tile[x_to][y_to]){
					units_on_tile[x_to][y_to] = units - units_on_tile[x_to][y_to]*tile_development_level[x_to][y_to];
					units_on_tile[x_from][y_from] -= units;

					if(get_tile(x_to, y_to) > victory_threshold){
						victory_tiles_owned[msg.sender]++; //overflow not possible
						victory_tiles_owned[tile_owner[x_to][y_to]]--; //underflow not possible
					}

					gold_balances[tile_owner[x_to][y_to]] = get_gold(msg.sender);
					gold_per_second[tile_owner[x_to][y_to]] -= get_gold_value_of_tile(x_to,y_to);
					last_GPH_update_time[tile_owner[x_to][y_to]] = block.timestamp;
				
					tile_development_level[x_to][y_to] = 0;
					market_price[x_to][y_to] = 0;

					gold_balances[msg.sender] = get_gold(msg.sender);
					gold_per_second[msg.sender] += get_gold_value_of_tile(x_to,y_to);
					last_GPH_update_time[msg.sender] = block.timestamp;

					tile_owner[x_to][y_to] = msg.sender;
					emit Land_Transferred(x_to, y_to, msg.sender);
				}else{
					units_on_tile[x_to][y_to] -= units/tile_development_level[x_to][y_to];
					units_on_tile[x_from][y_from] -= units;
				}
			}else{
				if(units == units_on_tile[x_to][y_to]) { 
					//defender advantage
					units_on_tile[x_to][y_to] = 1;
					units_on_tile[x_from][y_from] -= units;
				}
				else if(units > units_on_tile[x_to][y_to]){
					units_on_tile[x_to][y_to] = units - units_on_tile[x_to][y_to];
					units_on_tile[x_from][y_from] -= units;

					if(get_tile(x_to, y_to) > victory_threshold){
						victory_tiles_owned[msg.sender]++; //overflow not possible
						victory_tiles_owned[tile_owner[x_to][y_to]]--; //underflow not possible
					}

					gold_balances[tile_owner[x_to][y_to]] = get_gold(msg.sender);
					gold_per_second[tile_owner[x_to][y_to]] -= get_gold_value_of_tile(x_to,y_to);
					last_GPH_update_time[tile_owner[x_to][y_to]] = block.timestamp;
				
					tile_development_level[x_to][y_to] = 0;
					market_price[x_to][y_to] = 0;

					gold_balances[msg.sender] = get_gold(msg.sender);
					gold_per_second[msg.sender] += get_gold_value_of_tile(x_to,y_to);
					last_GPH_update_time[msg.sender] = block.timestamp;

					tile_owner[x_to][y_to] = msg.sender;
					emit Land_Transferred(x_to, y_to, msg.sender);
				}else{
					units_on_tile[x_to][y_to] -= units;
					units_on_tile[x_from][y_from] -= units;
				}
			}
		}
        emit New_Population(x_from, y_from, units_on_tile[x_from][y_from]);
        emit New_Population(x_to, y_to, units_on_tile[x_to][y_to]);
    }

	//noise
	int64 constant max = 256;
    function integer_noise(int64 n) public pure returns(int64) {
        n = (n >> 13) ^ n;
        int64 nn = (n * (n * n * 60493 + 19990303) + 1376312589) & 0x7fffffff;
        return ((((nn * 100000)) / (1073741824)))%max;
    }

    function local_average_noise(uint8 x, uint8 y) public pure returns(int64) {
        int64 xq = x + ((y-x)/3);
        int64 yq = y - ((x+y)/3);

        int64 result =
        ((integer_noise(xq) + integer_noise(yq-1))) //uc
        +   ((integer_noise(xq-1) + integer_noise(yq))) //cl
        +   ((integer_noise(xq+1) + integer_noise(yq))) //cr
        +   ((integer_noise(xq) + integer_noise(yq+1))); //lc

        return result*1000/8;
    }

    int64 constant iterations = 5;

    function stacked_squares(uint8 x, uint8 y) public pure returns(int64) {

        int64 accumulator;
        for(int64 iteration_idx = 0; iteration_idx < iterations; iteration_idx++){
            accumulator +=  integer_noise((x * iteration_idx) + accumulator + y) +
            integer_noise((y * iteration_idx) + accumulator - x);
        }

        return accumulator*1000/(iterations*2);

    }

    function get_tile(uint8 x, uint8 y) public pure returns (int64) {
        return (local_average_noise(x/4,y/7) + stacked_squares(x/25,y/42))/2000;
    }

	event Land_Bought(uint8 indexed x, uint8 indexed y, address indexed new_owner, uint16 new_population, uint8 development_level);
    event Land_Transferred(uint8 indexed x, uint8 indexed y, address indexed new_owner);
	event Gold_Transferred(address from, address to, uint gold);
    event New_Population(uint8 indexed x, uint8 indexed y, uint16 new_population);	
	event Market_Posted(uint8 indexed x, uint8 indexed y, address indexed poster, uint256 price);
	event Market_Bought(uint8 indexed x, uint8 indexed y, address indexed buyer);
}
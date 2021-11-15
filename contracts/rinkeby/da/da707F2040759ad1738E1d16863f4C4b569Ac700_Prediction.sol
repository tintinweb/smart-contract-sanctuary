// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./_utils/SafeMath.sol";
import "./PredictionCore.sol";
import "./interfaces/AggregatorV2V3Interface.sol";
import "./Ownable.sol";

contract Prediction is Ownable,PredictionCore{
    using SafeMath for uint;
    using SafeMath80 for uint80;
    // Kovan : 0xDE99C79533EEB1897d1d12dF3E5437D498ba82a6
    // Rinkeby : 0x4F699F366272F17297b69061FC16a86F2657C5C4
    IERC20 private XDAI = IERC20(0x4F699F366272F17297b69061FC16a86F2657C5C4);
    event _bid(
        bool indexed bidType,
        address indexed bidder,
        uint amount
        );
    function addToken(
        address token,
        uint80 _startingRound)
        public onlyOwner
        {
        markets[marketCount].feed = AggregatorV2V3Interface(token);
        markets[marketCount].startingRound = _startingRound;
        marketCount++;
    }
    function addArrayToken(
        address[] calldata token,
        uint80[] calldata _startingRound)
        public onlyOwner
        {
        require(token.length != 0, "array is empty");
        require(_startingRound.length != 0, "array is empty");
        require(token.length == _startingRound.length, "unequal array size");
        for(uint i = 0; i<token.length;i++ ) addToken(token[i],_startingRound[i]);
    }
    constructor(){
        addToken(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e,36893488147419103300);//Eth
        addToken(0xECe365B379E1dD183B20fc5f022230C044d51404,36893488147419103300);//Btc
        addToken(0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED,36893488147419103300);//Bnb
        addToken(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623,36893488147419103300);//Link
        addToken(0x031dB56e01f82f20803059331DC6bEe9b17F7fC9,36893488147419103300);//Bat
        // addToken(0x4d38a35C2D87976F334c2d2379b535F1D461D9B4,36893488147419103300);//Ltc
        // addToken(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623,36893488147419103300);//Link

    }
    function _deposit(uint amount) internal{
        //convert to 18 decimals format
        require(XDAI.balanceOf(_msgSender())>=amount,"insufficient balance");
        require(XDAI.allowance(_msgSender(),address(this)) >= amount,"unapproved transaction");
        XDAI.transferFrom(_msgSender(),address(this),amount);
    }
    function _withdraw(
        uint _i,
        uint80 _cycle,
        uint amount) internal
        {
        markets[_i].pools[_cycle].isWithdrawn[msg.sender] = true;
        XDAI.transfer(msg.sender,amount);
    }
    // we used 10**18 as a % to retrieve an accurate participant portion from total position
    // when returned the value need to be divided by 10**18
    function _reward(
        uint _i,
        uint80 _cycle,
        bool _type)
        internal view returns(uint reward)
        {
        uint totalStake;
        uint totalOpStake;
        uint ratio;
        uint stake;
        if(_type){
            totalStake = getTotalLongs(_i,_cycle);
            stake = getLong(_i,_cycle);
            ratio = (stake.mul(10**18)).div(totalStake);
            totalOpStake = getTotalShorts(_i,_cycle);
            reward = (totalOpStake.mul(ratio)).div(10**18);
        }else{
            totalStake = getTotalShorts(_i,_cycle);
            stake = getShort(_i,_cycle);
            ratio = (stake.mul(10**18)).div(totalStake);
            totalOpStake = getTotalLongs(_i,_cycle);
            reward = (totalOpStake.mul(ratio)).div(10**18);
        }
    }
    // bid - true: Long, false: short
    function bid(
        uint _i,
        uint amount,
        bool position)
        public validFeed(_i)
        {
        uint80 cycle = getLatestCycle(_i);
        require(amount >= MINIMUM_BID, "bidding amount is less than 10$");
        require(getPriceStatus(_i,cycle) == Status.PENDING,"round has been determined");
        require(isPriceLocked(_i),"Price locked range");
        if(position){
            require(getShort(_i,cycle) == 0, "Short position is in place");
            _deposit(amount);
            markets[_i].pools[cycle].Longs[msg.sender] += amount;
            markets[_i].pools[cycle].totalLongs += amount;
            markets[_i].activeCycle[msg.sender].push(cycle);
            emit _bid(position, msg.sender, amount);
        }else{
            require(getLong(_i,cycle) == 0, "Long position is in place");
            _deposit(amount);
            markets[_i].pools[cycle].Shorts[msg.sender] += amount;
            markets[_i].pools[cycle].totalShorts += amount;
            markets[_i].activeCycle[msg.sender].push(cycle);
            emit _bid(position, msg.sender, amount);
        }
    }
    function withdraw(uint _i, uint80 _cycle) public validFeed(_i) validCycle(_i,_cycle) {
        uint long = getLong(_i,_cycle);
        uint short = getShort(_i,_cycle);
        Status status = getPriceStatus(_i,_cycle);
        require(status != Status.PENDING, "Cycle in Progress");
        require(long != 0 || short != 0, "Invalid participant");
        require(_cycle < getLatestCycle(_i),"withdraw is inactive, wait until the cycle is over"); // might be deleted
        require(markets[_i].pools[_cycle].isWithdrawn[msg.sender] == false, "funds have been withdrawn");
        uint position;
        uint finalReward;
        Status state;
        if(long>0){position = long;}
        else if(short>0){position = short;}
        if(status != Status.TIE){
            if(long>0){state = Status.LONG;}
            else if(short>0){state = Status.SHORT;}
            require(status == state,"you have been liquidated");
        }
        if(status == Status.TIE){
            _withdraw(_i,_cycle,position);
        }else if(status == Status.LONG){
            finalReward = position.add(_reward(_i,_cycle,true));
            _withdraw(_i,_cycle,finalReward);
        }else if(status == Status.SHORT){
            finalReward = position.add(_reward(_i,_cycle,false));
            _withdraw(_i,_cycle,finalReward);
        }
    }
    // debugging
    function getPositionInfo(
        uint _i,
        uint80 _cycle)
        public validCycle(_i,_cycle) view returns(string memory,uint)
        {
        uint long = markets[_i].pools[_cycle].Longs[msg.sender];
        uint short = markets[_i].pools[_cycle].Shorts[msg.sender];
        string memory message;
        uint size;
        if(long > 0){
            message = "LONG";
            size = long;
        }else if(short > 0){
            message = "SHORT";
            size = short;
        }else{
            message = "NONE";
        }
        return (message,size);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./_utils/SafeMath.sol";
import "./interfaces/AggregatorV2V3Interface.sol";

contract PredictionCore{
    using SafeMath for uint;
    using SafeMath80 for uint80;
    enum Status{PENDING, TIE, LONG, SHORT}
    struct Market{
        uint80 startingRound;
        mapping(address => uint[]) activeCycle;
        mapping(uint => pool) pools;
        AggregatorV2V3Interface feed;
    }
    struct pool{
    uint totalLongs;
    uint totalShorts;
    mapping (address => bool) isWithdrawn;
    mapping (address => uint) Longs;
    mapping (address => uint) Shorts;
    }

    uint constant MINIMUM_BID = 10 * 10 ** 18;
    uint constant PERCENTAGE = 10;
    uint constant LOCKED_PERCENTAGE = 2;
    uint marketCount = 0;
    uint80 constant CYCLE = 80;
    mapping (uint => Market) markets;
    modifier validFeed(uint _i){
        require(marketCount > _i,"Prediction: Invalid Feed ");
        _;
    }
    modifier validCycle(uint _i, uint80 cycle){
        require(getLatestCycle(_i)>=cycle,"INVALID cycle");
        _;
    }
    function getPriceStatus(uint _i,uint80 _cycle)
        public validCycle(_i,_cycle) validFeed(_i) view returns(Status){
        require(getLatestCycle(_i)>=_cycle,"Prediction: Invalid cycle");
        uint80 _r0 = getStartingRound(_i).add(_cycle*CYCLE);
        require(getTimestamp(_i,_r0) > 0,"Prediction: invalid round");
        Status state;
        uint80 _r1 = _r0.add(CYCLE);
        (uint UPPER, uint LOWER) = getPriceBoundries(_i,_cycle);
        for(uint80 r = _r0; r<=_r1; r++ ){
            if( getRoundId(markets[_i].feed) < r) break;
            uint price = getRoundPrice(_i,r);
            if(price >= UPPER){
                state = Status.LONG;
                break;
            }else if(price <= LOWER){
                state = Status.SHORT;
                break;
            }
        }
        if(state == Status.PENDING && getLatestCycle(_i) > _cycle) state = Status.TIE;
        return state;
    }
    function getPriceBoundries(uint _i, uint80 cycle)
        internal validFeed(_i) view returns(uint UPPER, uint LOWER){
        require(getLatestCycle(_i)>=cycle,"Prediction: INVALID cycle");
        uint80 start = getStartingRound(_i).add(cycle.mul(CYCLE));
        uint price = getRoundPrice(_i,start);
        uint adjustedPrice = price.mul(PERCENTAGE).div(100);
        require(price != 0,"Price not feeded");
        UPPER = price.add(adjustedPrice);
        LOWER = price.sub(adjustedPrice);
    }
    function isPriceLocked(uint _i)
        public view returns(bool){
        (uint H, uint L) = getPriceBoundries(_i,getLatestCycle(_i));
        uint latestPrice = getLatestPrice(_i);
        H = H.sub((H.mul(LOCKED_PERCENTAGE)).div(100));
        L = L.add((L.mul(LOCKED_PERCENTAGE)).div(100));
        return (latestPrice<=H && latestPrice>=L);
    }
    function getTimestamp(uint _i, uint80 round)
        public validFeed(_i) view returns(uint){
        uint time = markets[_i].feed.getTimestamp(round);
        require(time > 0,"Prediction: Invalid round");
        return time;
    }
    function getRoundId(AggregatorV2V3Interface feed)
        internal view returns(uint80){
        ( uint80 roundID, , , ,) = feed.latestRoundData();
        return roundID;
    }
    function getLatestPrice(uint _i)
        public view returns(uint){
        ( ,int price, , , ) = markets[_i].feed.latestRoundData();
        return (uint(price)*10**10);
    }
    function getRoundPrice(uint _i, uint80 round)
        public view validFeed(_i) returns (uint){
        (uint80 roundID, int price, , ,) = markets[_i].feed.getRoundData(round);
        require(getTimestamp(_i,roundID) > 0, "Prediction: price not available");
        return (uint(price * 10**10));
    }
    function getLatestCycle(uint _i)
        public validFeed(_i) view returns(uint80){
        uint80 rounds = getRoundId(markets[_i].feed).sub(getStartingRound(_i));
        uint cycles = rounds.sub(rounds.mod(CYCLE)).div(CYCLE);
        return uint80(cycles);
    }
    function getLatestRoundInCycle(uint _i)
        public validFeed(_i) view returns(uint80){
        uint80 cycle = getLatestCycle(_i);
        (uint80 roundID, , , ,) = markets[_i].feed.latestRoundData();
        require(getTimestamp(_i,roundID) > 0, "Prediction: round not available");
        // Number of rounds from the beginning = latestRound - start round of this cycle
        uint80 roundsPassed = roundID.sub(getStartingRound(_i).add(cycle.mul(CYCLE))).add(1);
        return roundsPassed;
    }
    function getCyclesParticipation(uint _i)public view returns(uint[] memory){
        return markets[_i].activeCycle[msg.sender];
    }
    function getStartingRound(uint _i) internal view returns(uint80){
        return markets[_i].startingRound;
    }
    function getPair(uint _i) public view validFeed(_i) returns(string memory) {
        return markets[_i].feed.description();
    }
    function getTotalLongs(uint _i,uint80 _cycle) internal view  returns(uint){
        return markets[_i].pools[_cycle].totalLongs;
    }
    function getTotalShorts(uint _i,uint80 _cycle) internal view returns(uint){
        return markets[_i].pools[_cycle].totalShorts;
    }
    function getShort(uint _i,uint80 _cycle) internal view returns(uint){
        return markets[_i].pools[_cycle].Shorts[msg.sender];
    }
    function getLong(uint _i,uint80 _cycle) internal view returns(uint){
        return markets[_i].pools[_cycle].Longs[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath80.sol";
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMath80 {
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
    function add(uint80 a, uint80 b) internal pure returns (uint80) {
        return a + b;
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
    function sub(uint80 a, uint80 b) internal pure returns (uint80) {
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
    function mul(uint80 a, uint80 b) internal pure returns (uint80) {
        return a * b;
    }


    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint80 a, uint80 b) internal pure returns (uint80) {
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
    function mod(uint80 a, uint80 b) internal pure returns (uint80) {
        return a % b;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorV3Interface, AggregatorInterface{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/******************************************/
/*           IERC20 starts here           */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*           Context starts here          */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

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

/******************************************/
/*      IERC20Metadata starts here        */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

/******************************************/
/*           ERC20 starts here            */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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

/******************************************/
/*       IUniswapV2Pair starts here       */
/******************************************/

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/******************************************/
/*         NerveToken starts here         */
/******************************************/

contract NerveToken is ERC20  {

    // Collect fee on Nerve Swap and prepare for buy back and burn
    address public nexus;
    address public nerveSwap;
    address public nervePair;
    address public ethPair;
    
    // target: 1 ETH = 100,000 NERVE 
    // 7.5% of fee to user
    // 2.5% of fee to nexus
    uint256 public immutable userRate = 75000;
    uint256 public immutable nexusRate = 25000;

    event NerveMinted(address to, uint256 userAmount, uint256 nexusAmount);
    event NerveBurned(address from, uint256 amount);

	constructor(string memory name, string memory symbol) ERC20(name, symbol) 
    {

    }
    
    function initialize(address _ethPair, address _nervePair, address _nerveSwap, address _nexus) public
    {
        require(nexus == address(0), "Already initialized.");
        ethPair = _ethPair;
        nervePair = _nervePair;
        nerveSwap = _nerveSwap;
        nexus = _nexus;
    }

    function getTokenPrice(address _pair) public view returns(uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        return(Res0 * 1e6 / Res1);
    }

    // distribute new Nerve tokens in relation to paid fee, Ether conversion rate of the native token and current NERVE price.
    function mintNerve(address _to, uint256 _amount) internal  
    {
        uint256 ethPrice = getTokenPrice(ethPair);
        uint256 nervePrice = getTokenPrice(nervePair);
        // ignore NERVE price when below target
        if (nervePrice <= 1e12) nervePrice = 1e12;    
        uint256 userAmount = 1e12 * _amount * userRate / ethPrice / nervePrice;
        uint256 nexusAmount = 1e12 * _amount * nexusRate / ethPrice / nervePrice;

        _mint(_to, userAmount);
        _mint(nexus, nexusAmount);
        emit NerveMinted(_to, userAmount, nexusAmount);
    }

    // allow Nerve Swap to directly burn tokens
    function burnNerve(address _from, uint256 _amount) external
    {
        require(msg.sender == nerveSwap, "Must be Nerve Swap.");
        _burn(_from, _amount);
        emit NerveBurned(_from, _amount);
    }
}

/******************************************/
/*        NerveSocial starts here        */
/******************************************/

contract NerveSocial
{
    mapping(address => bytes32) public addressRegister;
    mapping(bytes32 => address) public nameRegister;
    
    event NameRegistered(address indexed user, bytes32 registeredName);
    event SocialRegistered(address indexed user, string[] socialLinks, string[] socialIds);
    event LocationRegistered(address indexed user, uint256 latitude, uint256 longitude);  
    event UserBlacklisted(address indexed user, address userToBlacklist);

    function registerName(bytes32 registeredName) external
    {
        if (registeredName [0] != 0) 
        {
            require(nameRegister[registeredName] == address(0), "Name already taken.");
            bytes32 actualName;
            if (addressRegister[msg.sender] != 0) 
            {
                actualName = addressRegister[msg.sender]; 
                delete nameRegister[actualName];
            }
            addressRegister[msg.sender] = registeredName;
            nameRegister[registeredName] = msg.sender;

            emit NameRegistered(msg.sender, registeredName);
        }
    }

    function registerSocial(string[] memory registeredLink, string[] memory socialID) external
    {            
        uint256 arrayLength = registeredLink.length;
        string[] memory socialLinks = new string[](arrayLength);
        
        uint256 socialArrayLength = socialID.length;
        string[] memory socialIds = new string[](socialArrayLength);
        emit SocialRegistered(msg.sender, socialLinks, socialIds);
    }
    
    function setLocation(uint256 latitude, uint256 longitude) external
    {
        emit LocationRegistered(msg.sender, latitude, longitude);
    }

    function setBlacklistUser(address userToBlacklist) external
    {
        emit UserBlacklisted(msg.sender, userToBlacklist);
    }
}

/******************************************/
/*         NerveGlobal starts here        */
/******************************************/

contract NerveGlobal is NerveSocial, NerveToken
{
    // 5% fee on createTask, joinTask and redeemRecipient
    uint256 public immutable taskFee = 20;
    // 10% fee on finishBet
    uint256 public immutable betFee = 10;

    uint256 internal currentTaskID;
    mapping(uint256 => taskInfo) public tasks;

    uint256 internal currentBetID;
    mapping(uint256 => betInfo) public bets;
    
    struct taskInfo 
    {
        uint96 amount;
        uint96 entranceAmount;
        uint40 endTask;
        uint24 participants;
        
        address recipient;
        bool executed;
        bool finished;
        uint24 positiveVotes;
        uint24 negativeVotes;

        mapping(address => uint256) stakes;
        mapping(address => bool) voted;       
    }

    struct betInfo
    {
        address initiator;
        uint40 endBet;
        bool winnerPartyYes;
        bool draw;
        bool noMoreBets;
        bool finished;

        uint80 stakesYes;
        uint80 stakesNo;
        
        mapping(address => uint256) partyYes;
        mapping(address => uint256) partyNo;
    }

    event TaskAdded(address indexed initiator, uint256 indexed taskID, address indexed recipient, uint256 amount, string description, uint256 endTask, string language, uint256 lat, uint256 lon);
    event TaskJoined(address indexed participant, uint256 indexed taskID, uint256 amount);
    event Voted(address indexed participant, uint256 indexed taskID, bool vote, bool finished);
    event RecipientRedeemed(address indexed recipient, uint256 indexed taskID, uint256 amount);
    event UserRedeemed(address indexed participant, uint256 indexed taskID, uint256 amount);
    event TaskProved(uint256 indexed taskID, string proofLink);

    event BetCreated(address indexed initiator, uint256 indexed betID, string description, uint256 endBet, string yesText, string noText, string language, uint256 lat, uint256 lon);
    event BetJoined(address indexed participant, uint256 indexed betID, uint256 amount, bool joinYes);
    event BetClosed(address indexed initiator, uint256 indexed betID);
    event BetFinished(address indexed initiator, uint256 indexed betID, bool winnerPartyYes, bool draw, bool failed);
    event BetRedeemed(address indexed participant, uint256 indexed betID, uint256 profit);
    event BetBailout(address indexed participant, uint256 indexed betID, uint256 userStake);
    event BetProved(uint256 indexed betID, string proofLink);
    
    constructor(string memory name, string memory symbol) NerveToken(name, symbol)
    { 
        currentTaskID = 0;
        currentBetID = 0;
        // initial mint for DEX setup
        _mint(msg.sender, 1e18);
    }

/******************************************/
/*          NerveTask starts here         */
/******************************************/

    function createTask(address recipient, string memory description, uint256 duration, string memory language, uint256 lat, uint256 lon) public payable
    {
        require(recipient != address(0), "0x00 address not allowed.");
        require(msg.value != 0, "No stake defined.");

        uint256 fee = msg.value / taskFee;
        uint256 stake = msg.value - fee;
        payable(nerveSwap).transfer(fee);
        mintNerve(msg.sender, fee);

        currentTaskID++;        
        taskInfo storage s = tasks[currentTaskID];
        s.recipient = recipient;
        s.amount = uint96(stake);
        s.entranceAmount = uint96(stake);
        s.endTask = uint40(duration + block.timestamp);
        s.participants++;
        s.stakes[msg.sender] = stake;

        emit TaskAdded(msg.sender, currentTaskID, recipient, stake, description, s.endTask, language, lat, lon);
    }

    function joinTask(uint256 taskID) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].entranceAmount <= msg.value, "Sent ETH does not match tasks entrance amount.");
        require(tasks[taskID].stakes[msg.sender] == 0, "Already participating in task.");
        require(tasks[taskID].endTask > block.timestamp, "Task participation period has ended." );
        require(tasks[taskID].recipient != msg.sender, "User can't be a task recipient.");
        require(tasks[taskID].finished != true, "Task already finished.");

        uint256 fee = msg.value / taskFee;
        uint256 stake = msg.value - fee;
        payable(nerveSwap).transfer(fee);
        mintNerve(msg.sender, fee);

        tasks[taskID].amount = tasks[taskID].amount + uint96(stake);
        tasks[taskID].stakes[msg.sender] = stake;
        tasks[taskID].participants++;

        emit TaskJoined(msg.sender, taskID, stake);
    }
    
    function voteTask(uint256 taskID, bool vote) public
    { 
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].endTask > block.timestamp, "Task has already ended.");
        require(tasks[taskID].stakes[msg.sender] != 0, "Not participating in task.");
        require(tasks[taskID].voted[msg.sender] == false, "Vote has already been cast.");

        tasks[taskID].voted[msg.sender] = true;
        if (vote) {
            tasks[taskID].positiveVotes++;  
        } else {  
            tasks[taskID].negativeVotes++;                             
        }
        if (tasks[taskID].participants == tasks[taskID].negativeVotes + tasks[taskID].positiveVotes) {
            tasks[taskID].finished = true;
        }

        emit Voted(msg.sender, taskID, vote, tasks[taskID].finished);
    }

    function redeemRecipient(uint256 taskID) public
    {
        require(tasks[taskID].recipient == msg.sender, "This task does not belong to message sender.");
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes >= tasks[taskID].negativeVotes, "Streamer lost the vote.");
        require(tasks[taskID].executed != true, "Task reward already redeemed");

        tasks[taskID].executed = true;                                                  
        uint256 fee = uint256(tasks[taskID].amount) / taskFee;
        payable(msg.sender).transfer(uint256(tasks[taskID].amount) - fee);
        payable(nerveSwap).transfer(fee);
        mintNerve(msg.sender, fee);                                                          

        emit RecipientRedeemed(msg.sender, taskID, tasks[taskID].amount);
        
        delete tasks[taskID];
    }

    function redeemUser(uint256 taskID) public
    {
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes < tasks[taskID].negativeVotes, "Streamer fullfilled the task.");
        require(tasks[taskID].stakes[msg.sender] != 0, "User did not participate or has already redeemed his stakes.");

        uint256 tempStakes = tasks[taskID].stakes[msg.sender];
        tasks[taskID].stakes[msg.sender] = 0;       
        payable(msg.sender).transfer(tempStakes);

        emit UserRedeemed(msg.sender, taskID, tempStakes);
    }

    function proveTask(uint256 taskID, string memory proofLink) public
    {
        require(tasks[taskID].recipient == msg.sender, "Can only be proved by recipient.");

        emit TaskProved(taskID, proofLink);
    }

/******************************************/
/*          NerveBet starts here          */
/******************************************/

    function createBet(string memory description, uint256 duration, string memory yesText, string memory noText, string memory language, uint256 lat, uint256 lon) public 
    {           
        currentBetID++;
        betInfo storage b = bets[currentBetID];
        b.initiator = msg.sender;
        b.endBet = uint40(block.timestamp + duration);

        emit BetCreated(msg.sender, currentBetID, description, b.endBet, yesText, noText, language, lat, lon);
    }

    function joinBet(uint256 betID, bool joinYes) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(bets[betID].initiator != address(0), "Bet does not exist.");
        require(bets[betID].partyYes[msg.sender] == 0 && bets[betID].partyNo[msg.sender] == 0, "Already participating in Bet.");
        require(bets[betID].initiator != msg.sender, "User can't be the bet initiator.");
        require(bets[betID].noMoreBets != true, "Bet already closed.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");

        if (joinYes) {
            bets[betID].partyYes[msg.sender] = msg.value;
            bets[betID].stakesYes += uint80(msg.value);
        } else {
            bets[betID].partyNo[msg.sender] = msg.value;
            bets[betID].stakesNo += uint80(msg.value);
        }

        emit BetJoined(msg.sender, betID, msg.value, joinYes);
    }

    function closeBet(uint256 betID) public
    {           
        require(bets[betID].initiator == msg.sender, "Only the initiator of a bet can close it.");
        require(bets[betID].noMoreBets != true, "Bet already closed.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");
        
        if (bets[betID].stakesYes == 0 || bets[betID].stakesNo == 0) {         
            bets[betID].finished = true;
            emit BetFinished(msg.sender, betID, false, false, true);
        }
        bets[betID].noMoreBets = true;

        emit BetClosed(msg.sender, betID);
    }

    function finishBet(uint256 betID, bool winnerPartyYes, bool draw) public
    {           
        require(bets[betID].initiator == msg.sender, "Only the initiator of a bet can finish it.");
        require(bets[betID].noMoreBets == true, "Bet still open.");
        require(bets[betID].finished != true, "Bet already finished.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");

        bets[betID].finished = true;
        bets[betID].winnerPartyYes = winnerPartyYes;
        bets[betID].draw = draw;
        uint256 losingStakes = bets[betID].winnerPartyYes ? bets[betID].stakesNo : bets[betID].stakesYes;
        uint256 fee = losingStakes / betFee;
        payable(nerveSwap).transfer(fee);
        mintNerve(msg.sender, fee);

        emit BetFinished(msg.sender, betID, winnerPartyYes, draw, false);
    }

    function redeemBet(uint256 betID) public
    {           
        require(bets[betID].initiator != msg.sender, "The initiator can't have stakes in a bet.");
        require(bets[betID].finished == true, "Bet is not finished.");
        require(bets[betID].draw == false, "No winner.");
        require(bets[betID].stakesYes != 0 && bets[betID].stakesNo != 0, "Bet participants on one side are 0.");

        uint256 stake;
        uint256 losingStakes;
        uint256 fee;
        uint256 userShare;
        if (bets[betID].winnerPartyYes) {
            require(bets[betID].partyYes[msg.sender] != 0, "User has no Stake on the winning side.");
            stake = bets[betID].partyYes[msg.sender];
            bets[betID].partyYes[msg.sender] = 0;             
            losingStakes = bets[betID].stakesNo;
            fee = losingStakes / betFee;
            userShare = (stake * (losingStakes - fee)) / bets[betID].stakesYes;
        } else {
            require(bets[betID].partyNo[msg.sender] != 0, "User has no Stake on the winning side.");
            stake = bets[betID].partyNo[msg.sender];
            bets[betID].partyNo[msg.sender] = 0;             
            losingStakes = bets[betID].stakesYes;
            fee = losingStakes / betFee;
            userShare = (stake * (losingStakes - fee)) / bets[betID].stakesNo;
        }
        payable(msg.sender).transfer(userShare + stake);

        emit BetRedeemed(msg.sender, betID, userShare);
    }

    function bailoutBet(uint256 betID) public
    {           
        require((bets[betID].draw == true) || (bets[betID].endBet < block.timestamp && bets[betID].finished == false) || 
        ((bets[betID].endBet < block.timestamp || bets[betID].finished == true) && (bets[betID].stakesYes == 0 || bets[betID].stakesNo == 0)), "End date of Bet not reached or participants on one not side 0.");
        require(bets[betID].partyYes[msg.sender] != 0 || bets[betID].partyNo[msg.sender] != 0, "User has no stakes in this bet.");
        
        uint256 stake;
        if(bets[betID].partyYes[msg.sender] != 0){
            stake = bets[betID].partyYes[msg.sender];
            bets[betID].partyYes[msg.sender] = 0;
        } else {
            stake = bets[betID].partyNo[msg.sender];
            bets[betID].partyNo[msg.sender] = 0;
        }
        payable(msg.sender).transfer(stake);
        
        emit BetBailout(msg.sender, betID, stake);
    }

    function proveBet(uint256 betID, string memory proofLink) public
    {
        require(bets[betID].initiator == msg.sender, "Can only be proved by initiator.");

        emit BetProved(betID, proofLink);
    }
}
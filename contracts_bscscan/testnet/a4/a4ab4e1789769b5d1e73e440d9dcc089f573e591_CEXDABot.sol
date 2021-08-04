/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterContract {
    function init(bytes calldata data) external payable;
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IMasterContract.sol";

contract RoboFiFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    mapping(address => address) public masterContractOf; // Mapping from clone contracts to their masterContract

    // Deploys a given master Contract as a clone.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address) {
        require(masterContract != address(0), "Factory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        address cloneAddress; // Address where the clone contract will reside.

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);

        return cloneAddress;
    }
}

contract ERC20Factory {

    RoboFiFactory private factory;

    constructor (RoboFiFactory factory_) {
        factory = factory_;
    }

    function deploy(string memory name_, 
                    string memory symbol_, 
                    uint256 initAmount_,
                    address holder_,
                    address master_) public payable {
        bytes memory data = abi.encode(name_, symbol_, initAmount_, holder_);
        factory.deploy(master_, data, true);
        // *
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoboFiToken is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "../IMasterContract.sol";
////import "./IRoboFiToken.sol";

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
contract RoboFiToken is Context, IRoboFiToken, IMasterContract {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initAmount_, address holder_) {
        _name = name_;
        _symbol = symbol_;
        if (holder_ != address(0))
            _mint(holder_, initAmount_);
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (string name, string symbol, uint256 initSupply address holder)
    function init(bytes calldata data) external virtual payable override {
        require(_totalSupply == 0, "RT: contract is already initialized");
        uint256 _initSupply;
        address _holder;
        (_name, _symbol, _initSupply, _holder) = abi.decode(data, (string, string, uint256, address));
        if (_initSupply > 0)
            _mint(_holder, _initSupply);
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
     * overloaded;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "RT: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        require(currentAllowance >= subtractedValue, "RT: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(sender != address(0), "RT: transfer from the zero address");
        require(recipient != address(0), "RT: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "RT: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        _afterTokenTransfer(sender, recipient, amount);

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
        require(account != address(0), "RT: mint to the zero address");

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
        require(account != address(0), "RT: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _internalBurn(account, amount);

        _afterTokenTransfer(account, address(0), amount);

        emit Transfer(account, address(0), amount);
    }

    function _internalBurn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "RT: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
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
        require(owner != address(0), "RT: approve from the zero address");
        require(spender != address(0), "RT: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./RoboFiToken.sol";

/**
@dev Prepresent a token which is pegged by another asset. To mint a pegged token, users have
to deposit an amount of asset. At any time, users could get back the deposited asset by 
burning the pegged tokens. Pegged token is a kind of interest-beared token, which means 
that over time each minted pegged token could have higher value than the orginal deposited 
assets. However, it could suffer a loss, i.e., negative interest.

PeggedToken is used as the base of certificate token issued by DABot. Users stake their 
asset to the bot and get back certificate token. If the trading (done by DABot operators)
gets profit, holders of certificate token will get positive interest pro-rata to their 
staked amount. On the other hand, if the trading gets loss, certificate token holders 
will suffer the trading loss, also pro-rata to their staked amount.
 */
contract PeggedToken is RoboFiToken {

    IERC20 public asset;
    uint public pointSupply;

    address internal _owner;        // only token owner could mint and burn the token. 
                                    // in most cases, the token owner is the DABot, not human.
                                    
    mapping(address => uint) private _pointBalances;

    modifier onlyOwner() {
        require(_msgSender() == _owner, "PeggedToken: permission denied");
        _;
    }

    event Mint(address indexed recepient, uint256 amount, uint256 point);
    event ClaimReward(address indexed sender, uint256 rewards, uint256 point);

    constructor(string memory name, string memory symbol, IERC20 peggedAsset) RoboFiToken(name, symbol, 0, _msgSender()) {
        asset = peggedAsset;
        _owner = _msgSender();
    }

    function init(bytes calldata data) external virtual payable override {
        require(address(asset) == address(0), "PeggedToken: contract initialized");
        (_name, _symbol, asset, _owner) = abi.decode(data, (string, string, IERC20, address));
        asset.approve(_owner, type(uint256).max);
    }

    function finalize() external onlyOwner {
        require(totalSupply() == 0, "PeggedToken: need to burn all tokens first");

        selfdestruct(payable(_owner));
    }

    function mulPointRate(uint256 value) internal view returns (uint256) {
        return pointSupply == 0 ? value : (value * asset.balanceOf(address(this)) / pointSupply);
    }

    function divPointRate(uint256 value) internal view returns (uint256) {
        return pointSupply == 0 ? value: (value * pointSupply / asset.balanceOf(address(this)));
    } 

    function pointBalanceOf(address sender) external view returns (uint256) {
        return _pointBalances[sender];
    }

    function mint(address recepient, uint amount) external onlyOwner payable returns (uint256) {
        return _mint(recepient, recepient, amount);
    }

    function mintTo(address payor, address recepient, uint amount) external onlyOwner payable returns(uint256) {
        return _mint(payor, recepient, amount);
    }

    function _mint(address payor, address recepient, uint amount) internal returns(uint256 mintedPoint) {
        mintedPoint = divPointRate(amount);
        _transferToken(payor, amount);
        super._mint(recepient, amount);
        _pointBalances[recepient] += mintedPoint;
        pointSupply += mintedPoint;

        emit Mint(recepient, amount, mintedPoint);
    }

    function _transferToken(address payor, uint amount) internal virtual {
        if (payor != address(0))
            asset.transferFrom(payor, address(this), amount);
    }

    function burn(address account, uint amount) external onlyOwner {
        _burn(account, amount);
    }

    function burn(uint amount) external {
        _burn(_msgSender(), amount);
    }

    function claimReward() external returns(uint) {
        return _claimReward(_msgSender());
    }

    function claimRewardFor(address account) external onlyOwner returns(uint) {
        return _claimReward(account);
    }

    function _claimReward(address account) internal returns(uint reward) {
        reward = getClaimableReward(account);
        if (reward == 0)
            return 0;

        uint256 newPointBalance = divPointRate(balanceOf(account));
        uint256 diffPointBalance = _pointBalances[account] - newPointBalance;

        _pointBalances[account] = newPointBalance;
        pointSupply -= diffPointBalance;

        asset.transfer(account, reward);

        emit ClaimReward(account, reward, newPointBalance);
    }

    function getClaimableReward(address reciever) public view returns(uint) {
        uint256 pointValue = mulPointRate(_pointBalances[reciever]);
        uint256 balance = balanceOf(reciever);
        return pointValue >= balance ? pointValue - balance : 0;
    }

    function _beforeTokenTransfer(address sender, address, uint256) internal override {
        if (sender != address(0))
            _claimReward(sender);
    }

    function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        uint256 point = amount * _pointBalances[sender] / (balanceOf(sender) + amount);

        _pointBalances[sender] -= point;

        if (recipient != address(0)) { // transfer point
            _pointBalances[recipient] += point;
        } else { // burn point
            pointSupply -= point;
            asset.transfer(sender, amount);
        }
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../Factory.sol";

library DABotCommon {

    enum ProfitableActors { BOT_CREATOR, GOVERNANCE_USER, STAKE_USER, ROBOFI_GAME }
    enum StakingTimeUnit { DAY, HOUR, MINUTE, SECOND }
    enum BotStatus { PRE_IBO, IN_IBO, ACTIVE, ABANDONED }

    struct PortfolioCreationData {
        address asset;
        uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
        uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
        uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
    }

   
    struct PortfolioAsset {
        address certAsset;    // the certificate asset to return to stake-users
        uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
        uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
        uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
        uint256 totalStake;     // the total stake of all users.
    }

    struct UserPortfolioAsset {
        address asset;
        PortfolioAsset info;
        uint256 userStake;
    }

    struct BotSetting {             // for saving storage, the meta-fields of a bot are encoded into a single uint256 byte slot.
        uint64 iboTime;             // 32 bit low: iboStartTime (unix timestamp), 
                                    // 32 bit high: iboEndTime (unix timestamp)
        uint24 stakingTime;         // 8 bit low: warm-up time, 
                                    // 8 bit mid: cool-down time
                                    // 8 bit high: time unit (0 - day, 1 - hour, 2 - minute, 3 - second)
        uint32 pricePolicy;         // 16 bit low: price multiplier (fixed point, 2 digits for decimal)
                                    // 16 bit high: commission fee in percentage (fixed point, 2 digit for decimal)
        uint128 profitSharing;      // packed of 16bit profit sharing: bot-creator, gov-user, stake-user, and robofi-game
        uint initDeposit;           // the intial deposit (in VICS) of bot-creator
        uint initFounderShare;      // the intial shares (i.e., governance token) distributed to bot-creator
        uint maxShare;              // max cap of gtoken supply
        uint iboShare;              // max supply of gtoken for IBO. Constraint: maxShare >= iboShare + initFounderShare
    }
    
    struct BotDetail { // represents a detail information of a bot, merely use for bot infomation query
        uint id;                    // the unique id of a bot within its manager.
                                    // note: this id only has value when calling {DABotManager.queryBots}
        address botAddress;         // the contract address of the bot.
        address masterContract;     // reference to the master contract of a bot contract.
                                    // in most cases, a bot contract is a proxy to a master contract.
                                    // particular settings of a bot are stored in the bot contracts.
        BotStatus status;           // 0 - PreIBO, 1 - InIBO, 2 - Active, 3 - Abandonned
        string botSymbol;                // get the bot name.
        string botName;            // get the bot full name.
        address template;           // the address of the master contract which defines the behaviors of this bot.
        string templateName;        // the template name.
        string templateVersion;     // the template version.
        uint iboStartTime;          // the time when IBO starts (unix second timestamp)
        uint iboEndTime;            // the time when IBO ends (unix second timestamp)
        uint warmup;                // the duration (in days) for which the staking profit starts counting
        uint cooldown;              // the duration (in days) for which users could claim back their stake after submiting the redeem request.
        uint priceMul;              // the price multiplier to calculate the price per gtoken (based on the IBO price).
        uint commissionFee;         // the commission fee when buying gtoken after IBO time.
        uint initDeposit;           
        uint initFounderShare;
        uint144 profitSharing;
        uint maxShare;              // max supply of governance token.
        uint circulatedShare;       // the current supply of governance token.
        uint iboShare;              // the max supply of gtoken for IBO.
        uint userShare;             // the amount of governance token in the caller's balance.
        UserPortfolioAsset[] portfolio;
    }

    /**
    @dev The detail buy privilege of an account during the IBO period
     */
    struct ShareBuyablePrivilege {
        address asset;
        uint stakeAmount;
        uint shareBuyable;
        uint weight;
        uint iboCap;
    }

    /**
    @dev Records warming-up certificate tokens of a DABot.
     */
    struct LockerInfo {         
        IDABot bot;             // the DABOT which creates this locker.
        address owner;          // the locker owner, who is albe to unlock and get tokens after the specified release time.
        address token;          // the contract of the certificate token.
        uint64 created_at;      // the moment when locker is created.
        uint64 release_at;      // the monent when locker could be unlock. 
    }

    /**
    @dev Provides detail information of a warming-up token lock, plus extra information.
     */
    struct LockerInfoEx {
        address locker;
        LockerInfo info;
        uint256 amount;         // the locked amount of cert token within this locker.
        uint256 reward;         // the accumulated rewards
        address asset;          // the stake asset beyond the certificated token
    }
   
    function iboStartTime(BotSetting storage info) view internal returns(uint) {
        return info.iboTime & 0xFFFFFFFF;
    }

    function iboEndTime(BotSetting storage info) view internal returns(uint) {
        return info.iboTime >> 32;
    }

    function setIboTime(BotSetting storage info, uint start, uint end) internal {
        require(start < end, "invalid ibo start/end time");
        info.iboTime = uint64((end << 32) | start);
    }

    function warmupTime(BotSetting storage info) view internal returns(uint) {
        return info.stakingTime & 0xFF;
    }

    function cooldownTime(BotSetting storage info) view internal returns(uint) {
        return (info.stakingTime >> 8) & 0xFF;
    }

    function getStakingTimeMultiplier(BotSetting storage info) view internal returns (uint) {
        uint unit = stakingTimeUnit(info);
        if (unit == 0) return 1 days;
        if (unit == 1) return 1 hours;
        if (unit == 2) return 1 minutes;
        return 1 seconds;
    }

    function stakingTimeUnit(BotSetting storage info) view internal returns (uint) {
        return (info.stakingTime >> 16);
    }

    function setStakingTime(BotSetting storage info, uint warmup, uint cooldown, uint unit) internal {
        info.stakingTime = uint24((unit << 16) | (cooldown << 8) | warmup);
    }

    function priceMultiplier(BotSetting storage info) view internal returns(uint) {
        return info.pricePolicy & 0xFFFF;
    }

    function commission(BotSetting storage info) view internal returns(uint) {
        return info.pricePolicy >> 16;
    }

    function setPricePolicy(BotSetting storage info, uint _priceMul, uint _commission) internal {
        info.pricePolicy = uint32((_commission << 16) | _priceMul);
    }

    function profitShare(BotSetting storage info, ProfitableActors actor) view internal returns(uint) {
        return (info.profitSharing >> uint(actor) * 16) & 0xFFFF;
    }

    function setProfitShare(BotSetting storage info, uint sharingScheme) internal {
        info.profitSharing = uint128(sharingScheme);
    }
}

/**
@dev The generic interface of a DABot.
 */
interface IDABot {
    
    function botSymbol() view external returns(string memory);
    function name() view external returns(string memory);
    function symbol() view external returns(string memory);
    function version() view external returns(string memory);

    /**
    @dev Retrieves the detail infromation of this DABot.

    Note: all fields of {DABotCommon.BotDetail} are filled, except {id} which is filled 
    by only the DABotManager.
     */
    function botDetails() view external returns(DABotCommon.BotDetail memory);
    function updatePortfolio(address asset, uint maxCap, uint iboCap, uint weight) external;

}


interface IDABotManager {
    
    function factory() external view returns(RoboFiFactory);

    /**
    @dev Gets the address to receive tax.
     */
    function taxAddress() external view returns (address);

    /**
    @dev Gets the address of the platform operator.
     */
    function operatorAddress() external view returns (address);

    /**
    @dev Gets the deposit amount (in VICS) that a person has to pay to create a proposal.
         When a proposal is settled (either approved or rejected), the account who submits or 
         clean the proposal will be awarded a portion of the deposit. The remain will go to operator addresss.

         See {proposalReward()}.
     */
    function proposalDeposit() external view returns (uint);
    
    /**
    @dev Gets the the percentage of proposalDeposit for awarding proposal settlement (for both approved and expired proposals).
         the remain part of proposalDeposit will go to operatorAddress.
     */
    function proposalReward() external view returns (uint);

    /**
    @dev Gets the minimum amount of VICS that a bot creator has to deposit to his newly created bot.
     */
    function minCreatorDeposit() external view returns(uint);

    function deployBotCertToken(address peggedAsset) external returns(address);

    event OperatorAddressChanged(address indexed account);
    event TaxAddressChanged(address indexed account);
    event ProposalDepositChanged(uint value);
    event ProposalRewardChanged(uint value);
    event MinCreatorDepositChanged(uint value);
    event BotDeployed(address indexed creator, address indexed template, uint botId, address indexed bot);
    event CertTokenDeployed(address indexed bot, address indexed asset, address indexed certtoken);
    event TemplateRegistered(address indexed template);
}





/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IDABot.sol";
////import "../token/PeggedToken.sol";

/**
@dev CertToken is a familiy of ERC20-compliant token which are issued by a DABot
to represent users' staked assets. A DABot could accept several staked assets. Each
staked asset will have a corresponding CertToken. By staking to a DABot, users recieve
an equivalent amount of CertToken. These CertToken tokens are used to claim interests as
well as the staked assets.

The interest of CertToken comes from the trading activities of a DABot. This means the 
interest could be either positve or negative.
 */
contract CertToken is PeggedToken {

    constructor() PeggedToken("", "", IERC20(address(0))) {

    } 

    function init(bytes calldata data) external virtual payable override {
        require(address(asset) == address(0), "CertToken: contract initialized");
        (asset, _owner) = abi.decode(data, (IERC20, address));
    }

    function name() public view override returns(string memory) {
        IDABot bot = IDABot(_owner);
        return string(abi.encodePacked(bot.botSymbol(), " ", IRoboFiToken(address(asset)).symbol(), " Certificate"));
    }

    function symbol() public view override returns(string memory) {
        IDABot bot = IDABot(_owner);
        return string(abi.encodePacked(bot.botSymbol(), IRoboFiToken(address(asset)).symbol()));
    }

    function decimals() public view override returns (uint8) {
        return IRoboFiToken(address(asset)).decimals();
    }

    function _transferToken(address payor, uint amount) internal override {
        // Do nothing, the token should be transfer from the owner bot.
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

////import "./CertToken.sol";
////import "./IDABot.sol";


abstract contract CertLocker is IMasterContract {

    DABotCommon.LockerInfo internal _info;

    function init(bytes calldata data) external virtual payable override {
        require(address(_info.owner) == address(0), "Locker: locker initialized");
        (_info) = abi.decode(data, (DABotCommon.LockerInfo));
    }

    function lockedBalance() public view returns(uint) {
        return CertToken(_info.token).balanceOf(address(this));
    }

    function asset() external view returns(IERC20) {
        return CertToken(_info.token).asset();
    }

    function owner() external view returns(address) {
        return _info.owner;
    }

    function detail() public view returns(DABotCommon.LockerInfoEx memory result) {
        result.locker = address(this);
        result.info = _info;
        result.amount = CertToken(_info.token).balanceOf(address(this));
        result.asset = address(CertToken(_info.token).asset());
        result.reward = _getReward();
    }

    function _getReward() internal view virtual returns(uint256);

    function unlockable() public view returns(bool) {
        return block.timestamp >= _info.release_at;
    }

    /**
    @dev Tries to unlock this locker if the time condition meets, otherise skipping the action.
     */
    function tryUnlock() public returns(bool) {
        require(msg.sender == address(_info.bot), "Locker: Permission denial");
        if (!unlockable()) 
            return false;
        _unlock();  
        return true;
    }

    function _unlock() internal virtual;

    function finalize() external payable {
        require(msg.sender == address(_info.bot), "Locker: Permission denial");
        selfdestruct(payable(_info.owner));
    }
}

/**
@dev This contract provides support for staking warmup feature. 
When users stake into a DABot, user will not immediately receive the certificate token.
Instead, these tokens will be locked inside an instance of this contract for a predefined
period, the warm-up period. 

During the warm-up period, certificate tokens will not generate any reward, no matter rewards
are added to the DABot or not. After the warm-up period, users can claim these tokens to 
their wallet.

If users do not claim tokens after warm-up period, the tokens are still kept securedly inside
the contract. Locked tokens will also entitle to receive rewards. When users claim the tokens, 
rewards will be distributed automatically to users' wallet. 
 */
contract WarmupLocker is CertLocker {

    event Release(IDABot bot, address indexed owner, address certtoken, uint256 amount, uint256 reward);

    function _getReward() internal view override returns(uint256) {
        return block.timestamp < _info.release_at ? 0 :
                         CertToken(_info.token).getClaimableReward(address(this)) * (block.timestamp - _info.release_at) / (block.timestamp - _info.created_at);
    }

    function _unlock() internal override {

        CertToken token = CertToken(_info.token);
        
        require(_info.token != address(0), "CertToken: null token address");
        require(address(token.asset()) != address(0), "CertToken: null asset address");

        token.claimReward();
        IERC20 peggedAsset = token.asset();
        uint256 amount = token.balanceOf(address(this));
        uint256 rewards = peggedAsset.balanceOf(address(this));
        token.transfer(_info.owner, amount);
        uint256 entitledRewards = _getReward();
        if (rewards > 0) {
            require(rewards >= entitledRewards, "Actual rewards is less than entitled rewards");
            if (entitledRewards > 0) peggedAsset.transfer(_info.owner, entitledRewards);
            if (rewards - entitledRewards > 0) peggedAsset.transfer(_info.token, rewards - entitledRewards);
        }
        emit Release(_info.bot, _info.owner, _info.token, amount, entitledRewards);
    }
}


contract CooldownLocker is CertLocker {

    event Release(IDABot bot, address indexed owner, address certtoken, uint256 penalty);

    function _getReward() internal view override returns(uint256) {
        return CertToken(_info.token).getClaimableReward(address(this)) * 10 / 100;
    }

    function _unlock() internal override {
        CertToken token = CertToken(_info.token);
        uint256 penalty = token.getClaimableReward(address(this)) * 90 / 100;
        token.burn(token.balanceOf(address(this))); 

        IERC20 peggedAsset = token.asset();
        
        peggedAsset.transfer(address(token), penalty);
        peggedAsset.transfer(_info.owner, peggedAsset.balanceOf(address(this)));

        emit Release(_info.bot, _info.owner, _info.token, penalty);
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Arrays.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";
////import "./RoboFiToken.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract RoboFiTokenSnapshot is RoboFiToken {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../token/RoboFiTokenSnapshot.sol"; 
////import "../token/IRoboFiToken.sol";
////import "../Ownable.sol";
////import "./IDABot.sol";
////import "./CertToken.sol";
////import "./CertLocker.sol";


abstract contract DABotShare {
    using DABotCommon for DABotCommon.BotSetting;

    DABotCommon.BotSetting internal _setting;

    string constant ERR_ABANDONED = "DABot: bot abandoned";
    string constant ERR_PERMISSION_DENIED = "DABot: permission denied";
    string constant ERR_INVALID_PORTFOLIO_ASSET = "DABot: invalid portfolio asset";
    string constant ERR_INVALID_CERTIFICATE_ASSET = "DABot: invalid certificate asset";
    string constant ERR_PORTFOLIO_FULL = "DABot: portfolio is full";
    string constant ERR_ZERO_CAP = "DABot: cap must be positive";
    string constant ERR_INVALID_CAP = "DABot: cap must be greater than stake and ibo cap";
    string constant ERR_ZERO_WEIGHT = "DABot: weight must positive";
    string constant ERR_INSUFFICIENT_FUND = "DABot: insufficient fund";

    IRoboFiToken public immutable vicsToken;
    IDABotManager public immutable botManager;
    address public immutable voteController;
    address public immutable warmupLocker;
    address public immutable cooldownLocker;
    address public immutable masterContract = address(this);

    bool internal _abandoned;    // indicated that bot has been abandon

    constructor( IRoboFiToken vics, 
                IDABotManager manager,
                address warmupMaster,
                address cooldownMaster,
                address voter) {
        vicsToken = vics;
        botManager = manager;
        warmupLocker = warmupMaster;
        cooldownLocker = cooldownMaster;
        voteController = voter;
    }

    modifier notAbandoned() {
        require(!_abandoned, ERR_ABANDONED);
        _;
    }

    function status() view public returns(DABotCommon.BotStatus) {
        if (_abandoned) return DABotCommon.BotStatus.ABANDONED;
        if (block.timestamp < _setting.iboStartTime()) return DABotCommon.BotStatus.PRE_IBO;
        if (block.timestamp < _setting.iboEndTime()) return DABotCommon.BotStatus.IN_IBO;
        return DABotCommon.BotStatus.ACTIVE;
    }
}

abstract contract DABotSetting is DABotShare {

    using DABotCommon for DABotCommon.BotSetting;
    
    /**
    @dev Ensure the modification of bot settings to comply with the following rule:

    Before the IBO time, bot owner could freely change the bot setting.
    After the IBO has started, bot settings must be changed via the voting protocol.
     */
    modifier SettingGuard() {
        require(settable(msg.sender), ERR_PERMISSION_DENIED);
        require(!_abandoned, ERR_ABANDONED);
        _;
    }

    function settable(address) view internal virtual returns(bool);



    /**
    @dev Retrieves the IBO period of this bot.
     */
    function iboTime() view external returns(uint startTime, uint endTime) {
        startTime = _setting.iboStartTime();
        endTime = _setting.iboEndTime();
    }

    /**
    @dev Retrieves the staking settings of this bot, including the warm-up and cool-down time.
     */
    function stakingTime() view external returns(uint warmup, uint cooldown) {
        warmup = _setting.warmupTime();
        cooldown = _setting.cooldownTime();
    }

    /**
    @dev Retrieves the pricing policy of this bot, including the after-IBO price multiplier and commission.
     */
    function pricePolicy() view external returns(uint priceMul, uint commission) {
        priceMul = _setting.priceMultiplier();
        commission = _setting.commission();
    }

    /**
    @dev Retrieves the profit sharing scheme of this bot.
     */
    function profitSharing() view external returns(uint144) {
        return _setting.profitSharing;
    }

    function setIBOTime(uint startTime, uint endTime) external SettingGuard {
        _setting.setIboTime(startTime, endTime);
    }
    
    function setStakingTime(uint warmup, uint cooldown, uint unit) external SettingGuard {
        _setting.setStakingTime(warmup, cooldown, unit);
    }

    function setPricePolicy(uint priceMul, uint commission) external SettingGuard {
        _setting.setPricePolicy(priceMul, commission);
    }

    function setProfitSharing(uint sharingScheme) external SettingGuard {
        _setting.setProfitShare(sharingScheme);
    }
}

abstract contract DABotStaking is DABotShare, Context, Ownable {
    using DABotCommon for DABotCommon.BotSetting;

    IRoboFiToken[] internal _assets; 
    mapping(IRoboFiToken => DABotCommon.PortfolioAsset) internal _portfolio;
    mapping(address => CertLocker[]) internal _warmup;
    mapping(address => CertLocker[]) internal _cooldown;

    event PortfolioUpdated(address indexed asset, address indexed certAsset, uint maxCap, uint iboCap, uint weight);
    event AssetRemoved(address indexed asset);   
    event Stake(address indexed asset, address indexed account, address indexed  locker, uint amount);
    event Unstake(address indexed certToken, address indexed account, address indexed  locker, uint amount);

    /**
    @dev Gets the stake amount of a specific account of a stake-able asset.
     */
    function stakeBalanceOf(address account, IRoboFiToken asset) view public returns(uint) {
        return certificateOf(asset).balanceOf(account) 
                + warmupBalanceOf(account, asset);
    }

    /**
    @dev Gets the amount of (warm-up) locked certificate tokens.
     */
    function warmupBalanceOf(address account, IRoboFiToken asset) view public returns(uint) {
        CertLocker[] storage lockers = _warmup[account];
        return _lockedBalance(lockers, address(asset));
    }

    /**
    @dev Gets the amount of certificate tokens in cooldown period.
     */
    function cooldownBalanceOf(address account, CertToken certToken) view public returns(uint) {
        CertLocker[] storage lockers = _cooldown[account];
        return _lockedBalance(lockers, address(certToken.asset()));
    }

    function _lockedBalance(CertLocker[] storage lockers, address asset) view internal returns(uint result) {
        result = 0;
        for (uint i = 0; i < lockers.length; i++) 
            if (address(lockers[i].asset()) == asset)
                result += lockers[i].lockedBalance();
    }

   /**
    @dev Gets detail information of warming-up certificate tokens (for all staked assets).
    */
    function warmupDetails(address account) view public returns(DABotCommon.LockerInfoEx[] memory) {
        CertLocker[] storage lockers = _warmup[account];
        return _lockerInfo(lockers);
    }

    /**
    @dev Gets detail information of cool-down requests (for all certificate tokens)
     */
    function cooldownDetails(address account) view public returns(DABotCommon.LockerInfoEx[] memory) {
        CertLocker[] storage lockers = _cooldown[account];
         return _lockerInfo(lockers);
    }

    function _lockerInfo(CertLocker[] storage lockers) view internal returns(DABotCommon.LockerInfoEx[] memory result) {
        result = new DABotCommon.LockerInfoEx[](lockers.length);
        for (uint i = 0; i < lockers.length; i++) {
            result[i] = lockers[i].detail();
        }
    }

    /**
    @dev Itegrates all lockers of the caller, and try to unlock these lockers if time condition meets.
        The unlocked lockers will be removed from the global `_warmup`.

        The function will return when one of the below conditions meet:
        (1) 20 lockers has been unlocked,
        (2) All lockers have been checked
     */
    function releaseWarmup() public {
        CertLocker[] storage lockers = _warmup[_msgSender()];
        _releaseLocker(lockers);
    }

    function _releaseLocker(CertLocker[] storage lockers) internal {
        uint max = lockers.length < 20 ? lockers.length : 20;
        uint idx = 0;
        for (uint count = 0; count < max && idx < lockers.length;) {
            CertLocker locker = lockers[idx];
            if (!locker.tryUnlock()) {
                idx++;
                locker.finalize(); 
                continue;
            }
            lockers[idx] = lockers[lockers.length - 1];
            lockers.pop();
            count++;
        }
    }

    function releaseCooldown() public {
        CertLocker[] storage lockers = _cooldown[_msgSender()];
        _releaseLocker(lockers);
    }

    /**
    @dev Gets the address of the certification token contract for the specified asset.
     */
    function certificateOf(IRoboFiToken asset) public view returns(CertToken) {
        return CertToken(_portfolio[asset].certAsset);
    }

    /**
    @dev Get the crypto asset corresponding to the specified certificate token.
     */
    function assetOf(address certToken) public view returns(IERC20) {
        return CertToken(certToken).asset(); 
    }

    /**
    @dev Retrieves the max stakable amount for the specified asset.

    During IBO, the max stakable amount is bound by the {portfolio[asset].iboCap}.
    After IBO, it is limited by {portfolio[asset].cap}.
     */
    function getMaxStake(IRoboFiToken asset) public view returns(uint) {
        if (block.timestamp < _setting.iboStartTime())
            return 0;

        DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];

        if (block.timestamp < _setting.iboEndTime())
            return pAsset.iboCap - pAsset.totalStake;

        return pAsset.cap - pAsset.totalStake;
    }

    /**
    @dev Stakes an mount of crypto asset to the bot and get back the certificate token.

    The staking function is only valid after the IBO starts and on ward. Before that calling 
    to this function will be failt.

    When users stake during IBO time, users will immediately get the certificate token. After the
    IBO time, certificate token will be issued after a [warm-up] period.
     */
    function stake(IRoboFiToken asset, uint amount) external virtual {
        if (amount == 0) return;

        DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];

        require(_setting.iboStartTime() <= block.timestamp, ERR_PERMISSION_DENIED);
        require(address(asset) != address(0), ERR_INVALID_PORTFOLIO_ASSET);
        require(pAsset.certAsset != address(0), ERR_INVALID_PORTFOLIO_ASSET);

        uint maxStakeAmount = getMaxStake(asset);
        require(maxStakeAmount > 0, ERR_PORTFOLIO_FULL);

        uint stakeAmount = amount > maxStakeAmount ? maxStakeAmount : amount;
        _mintCertificate(asset, stakeAmount);        
    }

    /**
    @dev Redeems an amount of certificate token to get back the original asset.

    All unstake requests are denied before ending of IBO.
     */
    function unstake(CertToken certAsset, uint amount) external virtual {
        if (amount == 0) return;
        IERC20 asset = certAsset.asset();
        require(address(asset) != address(0), ERR_INVALID_CERTIFICATE_ASSET);
        require(_setting.iboEndTime() <= block.timestamp, ERR_PERMISSION_DENIED);
        require(certAsset.balanceOf(_msgSender()) >= amount, ERR_INSUFFICIENT_FUND);

        _unstake(_msgSender(), certAsset, amount);
    }

    function _mintCertificate(IRoboFiToken asset, uint amount) internal {
        DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];
        asset.transferFrom(_msgSender(), address(pAsset.certAsset), amount);
        CertToken token = CertToken(pAsset.certAsset);
        uint duration =  status() == DABotCommon.BotStatus.IN_IBO ? 0 :
                         _setting.warmupTime() * _setting.getStakingTimeMultiplier();
        
        pAsset.totalStake += amount;
        address locker;

        if (duration == 0) {
            token.mintTo(address(0), _msgSender(), amount);
        } else {
            locker = botManager.factory().deploy(warmupLocker, 
                    abi.encode(address(this), _msgSender(), pAsset.certAsset, block.timestamp, block.timestamp + duration), true);
            _warmup[_msgSender()].push(WarmupLocker(locker));

            token.mintTo(address(0), locker, amount);
        }

        emit Stake(address(asset), _msgSender(), locker, amount);
    }

    function _unstake(address account, CertToken certToken, uint amount) internal virtual {
        uint duration = _setting.cooldownTime() * _setting.getStakingTimeMultiplier(); 

        if (duration == 0) {
            certToken.burn(_msgSender(), amount);
            emit Unstake(address(certToken), account, address(0), amount);
            return;
        }

        address locker = botManager.factory().deploy(cooldownLocker,
                abi.encode(address(this), _msgSender(), address(certToken), block.timestamp, block.timestamp + duration), true);

        _cooldown[account].push(CertLocker(locker));
        certToken.transferFrom(account, locker, amount);

        emit Unstake(address(certToken), account, locker, amount);
    }

    /**
    @dev Adds (or updates) a stake-able asset in the portfolio. 
     */
    function updatePortfolio(IRoboFiToken asset, uint maxCap, uint iboCap, uint weight) external onlyOwner {
        _updatePortfolio(asset, maxCap, iboCap, weight);
    }

    /**
    @dev Removes an asset from the bot's porfolio. 

    It requires that none is currently staking to this asset. Otherwise, the transaction fails.
     */
    function removeAsset(IRoboFiToken asset) public onlyOwner {
        _removeAsset(asset);
    }

    /**
    @dev Adds (or updates) a stake-able asset in the portfolio. 
     */
    function _updatePortfolio(IRoboFiToken asset, uint maxCap, uint iboCap, uint weight) internal {
        require(address(asset) != address(0), ERR_INVALID_PORTFOLIO_ASSET);

        DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];

        if (address(pAsset.certAsset) == address(0)) {
            require(block.timestamp < _setting.iboStartTime(), ERR_PERMISSION_DENIED);
            require(maxCap > 0, ERR_ZERO_CAP);
            require(weight > 0, ERR_ZERO_WEIGHT);
            pAsset.certAsset = botManager.deployBotCertToken(address(asset));
            _assets.push(asset);
        }

        if (maxCap > 0) pAsset.cap = maxCap;
        if (iboCap > 0) pAsset.iboCap = iboCap;
        if (weight > 0) pAsset.weight = weight;

        require((pAsset.cap >= pAsset.totalStake) && (pAsset.cap >= pAsset.iboCap), ERR_INVALID_CAP);
        
        emit PortfolioUpdated(address(asset), address(pAsset.certAsset), pAsset.cap, pAsset.iboCap, pAsset.weight);
    }

    function _removeAsset(IRoboFiToken asset) internal {
        require(address(asset) != address(0), "DABot: null asset");
        uint i = 0;
        while (i < _assets.length && _assets[i] != asset) i++;
        require(i < _assets.length, "DABot: asset not found");
        CertToken(_portfolio[asset].certAsset).finalize();
        delete _portfolio[asset];
        _assets[i] = _assets[_assets.length - 1];
        _assets.pop();

        emit AssetRemoved(address(asset));
    }

    /**
    @dev Retrieves the porfolio of this DABot, including stake amount of the caller for each asset.
     */
    function portfolio() view public returns(DABotCommon.UserPortfolioAsset[] memory output) {
        output = new DABotCommon.UserPortfolioAsset[](_assets.length);
        for(uint i = 0; i < _assets.length; i++) {
            output[i].asset = address(_assets[i]);
            output[i].info = _portfolio[_assets[i]];
            output[i].userStake = stakeBalanceOf(_msgSender(), _assets[i]);
        }
    }

    /**
    @dev Retrives the porfolio info of the specified crypto asset.
     */
    function portfolioOf(IRoboFiToken asset) view public returns(DABotCommon.UserPortfolioAsset memory result) {
        for(uint i = 0; i < _assets.length; i++) {
            if (_assets[i] != asset)
                continue;
            result.asset = address(_assets[i]);
            result.info = _portfolio[_assets[i]];
            result.userStake = stakeBalanceOf(_msgSender(), _assets[i]);
        }
    }
}

abstract contract DABotGovernance is DABotShare, DABotStaking, RoboFiTokenSnapshot {
    using DABotCommon for DABotCommon.BotSetting;

   

    /**
    @dev Calculates the shares (g-tokens) available for purchasing for the specified account.

    During the IBO time, the amount of available shares for purchasing is derived from
    the staked asset (refer to the Concept Paper for details). 
    
    After IBO, the availalbe amount equals to the uncirculated amount of goveranance tokens.
     */
    function shareBuyable(address account) view public virtual returns(uint result) {
        if (block.timestamp < _setting.iboStartTime()) return 0;
        if (block.timestamp > _setting.iboEndTime()) return _setting.maxShare - totalSupply();

        uint totalWeight = 0;
        uint totalPoint = 0;
        for (uint i = 0; i < _assets.length; i ++) {
            IRoboFiToken asset = _assets[i];
            DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];
            totalPoint += stakeBalanceOf(account, asset) * pAsset.weight * 1e18 / pAsset.iboCap;
            totalWeight += pAsset.weight;
        }

        uint currentBalance = balanceOf(account);

        result = _setting.iboShare * totalPoint / totalWeight / 1e18;

        if (result > currentBalance)
            result -= currentBalance;
        else 
            result = 0;
    }

    function iboShareBuyableDetail(address account) view public returns(DABotCommon.ShareBuyablePrivilege[] memory result) {
        result = new DABotCommon.ShareBuyablePrivilege[](_assets.length);
        uint totalWeight = 0;
        
        for (uint i = 0; i < _assets.length; i ++) {
            IRoboFiToken asset = _assets[i];
            DABotCommon.PortfolioAsset storage pAsset = _portfolio[asset];
            result[i].asset = address(asset);
            result[i].stakeAmount = stakeBalanceOf(account, asset);
            result[i].weight = pAsset.weight;
            result[i].iboCap = pAsset.iboCap;

            totalWeight += pAsset.weight;
        }

        for (uint i = 0; i < _assets.length; i++) {
            result[i].shareBuyable = _setting.iboShare * result[i].stakeAmount * result[i].weight 
                                        / (totalWeight * result[i].iboCap);
        }
    }

    /**
    @dev Returns the value (in VICS) of an amount of shares (g-token). 
    The returned value depends on the amount of circulated bot's share tokens, and the amount
    of deposited VICS inside the bot.
     */
    function shareValue(uint amount) view public returns (uint) {
        return amount * vicsToken.balanceOf(address(this)) / totalSupply();
    }

    /**
    @dev Deposits an amount of VICS to the bot and get the equivalent governance token (i.e., Bots' shares).

    
     */
    function deposit(uint vicsAmount) public virtual {
        _deposit(_msgSender(), vicsAmount);
    }

    function _deposit(address account, uint vicsAmount) internal virtual {
        uint fee;
        uint shares;
        uint payment;
        (payment, shares, fee) = calcOutShares(account, vicsAmount);
        if (fee > 0) {
            address taxAddress = botManager.taxAddress();
            if (taxAddress == address(0))
                taxAddress = address(this);
            vicsToken.transferFrom(account, taxAddress, fee); 
        }
        vicsToken.transferFrom(account, address(this), payment);
        _mint(account, shares);
    }

     /**
    @dev Calculates the ouput government tokens, given the input VICS amount. 

    The function returns three outputs:
        * shares: the output governenent tokens that could be purchased with the given input
                  VICS amount, and other constraints (i.e., IBO time, stake amount.)
        * payment: the amount of VICS (without fee) to deposit to the bot.
        * fee: the commission fee to transfer to the tax address 

     */
    function calcOutShares(address account, uint vicsAmount) view public virtual returns(uint payment, uint shares, uint fee) {
        uint priceMultipler = 100; 
        uint commission = 0;
        if (block.timestamp >= _setting.iboEndTime()) {
            priceMultipler = _setting.priceMultiplier();
            commission = _setting.commission();
        }
        uint outAmount = (10000 - commission) * vicsAmount *  _setting.initFounderShare / priceMultipler / _setting.initDeposit / 100; 
        uint maxAmount = shareBuyable(account);

        if (outAmount <= maxAmount) {
            shares = outAmount;
            fee = vicsAmount * commission / 10000; 
            payment = vicsAmount - fee;
        } else {
            shares = maxAmount;
            payment = maxAmount * _setting.initDeposit * priceMultipler / _setting.initFounderShare / 100;
            fee = payment * commission / (1000 - commission);
        }
    }

    /**
    @dev Burns the bot's shares to get back VICS. The amount of returned VICS is proportional of amount
    of circulated bot's shares and deposited VICS.
     */
    function redeem(uint amount) public virtual {
        _redeem(_msgSender(), amount);
    }

    function _redeem(address account, uint amount) internal virtual {
        uint value = shareValue(amount);
        _burn(account, amount);
        vicsToken.transfer(account, value);
    }
}

/**
@dev Base contract module for a DABot.
 */
contract DABotBase is DABotSetting, DABotGovernance {

    using DABotCommon for DABotCommon.BotSetting;

    string private _botSymbol;
    string private _botName;

    event BotAbandoned(address indexed bot, bool value);

    constructor(string memory templateName, 
                IRoboFiToken vics, 
                IDABotManager manager,
                address warmupLocker,
                address cooldownLocker,
                address voter) RoboFiToken("", "", 0, _msgSender()) DABotShare(vics, manager, warmupLocker, cooldownLocker, voter) {
        _botSymbol = templateName;
    }

    /**
    @dev Initializes this bot instance. Should be called internally from a factory.
     */
    function init(bytes calldata data) external virtual payable override {
        require(owner() == address(0), "DABot: bot has been initialized");
        address holder;
        (_botSymbol, _botName, holder, _setting) = abi.decode(data, (string, string, address, DABotCommon.BotSetting));

        require(_setting.iboEndTime() > _setting.iboStartTime(), "DABot: IBO end time is less than start time");
        require(_setting.initDeposit >= botManager.minCreatorDeposit(), "DABot: insufficient deposit");
        require(_setting.initFounderShare > 0, "DABot: positive founder share required");
        require(_setting.maxShare >= _setting.initFounderShare + _setting.iboShare, "DABot: insufficient max share");

        _transferOwnership(holder);
        _mint(holder, _setting.initFounderShare);
    }

    function symbol() public view override returns(string memory) {
        return string(abi.encodePacked(_botSymbol, "GToken"));
    }

    function name() public view override returns(string memory) {
        return string(abi.encodePacked(_botSymbol, ' ', "Governance Token"));
    }

    function botSymbol() view external virtual returns(string memory) {
        return _botSymbol;
    }

    function botName() view external virtual returns(string memory) {
        return _botName;
    }

    /**
    @dev Reads the version of this contract.
     */
    function version() pure external virtual returns(string memory) {
        return "1.0";
    }

    function settable(address account) view internal override returns(bool) {
        if (block.timestamp > _setting.iboStartTime())
            return (account == voteController);
        return(account == owner());
    }

    function abandon(bool value) external onlyOwner {
        if (value == _abandoned) return;
        _abandoned = value;

        emit BotAbandoned(address(this), value);
    }

    /**
    @dev Retrieves the detailed information of this DABot. 
     */
    function botDetails() view external returns(DABotCommon.BotDetail memory output) {
        output.botAddress = address(this);
        output.masterContract = masterContract;
        output.botSymbol = _botSymbol;
        output.botName = _botName;
        output.status = status();
        output.templateName = IDABot(masterContract).botSymbol();
        output.templateVersion = IDABot(masterContract).version();
        output.iboStartTime = _setting.iboStartTime();
        output.iboEndTime = _setting.iboEndTime();
        output.warmup = _setting.warmupTime();
        output.cooldown = _setting.cooldownTime();
        output.priceMul = _setting.priceMultiplier();
        output.commissionFee = _setting.commission();
        output.profitSharing = _setting.profitSharing;
        output.initDeposit = _setting.initDeposit;
        output.initFounderShare = _setting.initFounderShare;
        output.maxShare = _setting.maxShare;
        output.iboShare = _setting.iboShare;
        output.circulatedShare = totalSupply();
        output.userShare = balanceOf(_msgSender());
        output.portfolio = portfolio();
    }


}

/** 
 *  SourceUnit: \robofi-contracts-core\contracts\dabot\bot-templates\CEXDABot.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
////import "../DABot.sol";

contract CEXDABot is DABotBase {
    
    constructor(IRoboFiToken vics, 
                IDABotManager manager,
                address warmupLocker,
                address cooldownLocker,
                address voter)  DABotBase("CEX DABot", vics, manager, warmupLocker, cooldownLocker, voter) { 
    }
}
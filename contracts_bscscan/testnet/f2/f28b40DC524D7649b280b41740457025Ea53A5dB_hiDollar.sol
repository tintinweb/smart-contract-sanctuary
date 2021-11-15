// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable
{
    address public owner;
    address private proposedOwner;

    event OwnershipProposed(address indexed newOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev propose a new owner by an existing owner
    * @param newOwner The address proposed to transfer ownership to.
    */
    function proposeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        proposedOwner = newOwner;
        emit OwnershipProposed(newOwner);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    */
    function takeOwnership() public {
        require(proposedOwner == msg.sender, "Ownable: not the proposed owner");
        _transferOwnership(proposedOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: zero address not allowed");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


abstract contract Governable is Ownable {

    uint256 public constant RATIO_DECIMALS = 4;  /** ratio decimals */
    uint256 public constant RATIO_PRECISION = 10 ** RATIO_DECIMALS /** ratio precision， 10000 */;
    uint256 public constant MAX_FEE_RATIO = 1 * RATIO_PRECISION - 1; /** max fee ratio, 100% */
    uint256 public constant MIN_APPROVE_RATIO = 6666 ; /** min approve ratio, 66.66% */


    event ApproverChanged(address indexed account, bool approve);
    event ProposerChanged(address indexed account, bool on);
    event MaxProposeDurationChanged(uint256 previousDuration, uint256 newDuration);

    mapping (address => bool) public Approvers;
    uint256 approverCount;

    mapping (address => bool) public Proposers;

    uint256 maxProposeDuration = 3600 * 24 * 7; /** max propose duration time in second */


    function setMaxProposeDuration(uint256 duration) public onlyOwner {
        uint256 previousDuration = maxProposeDuration;
        maxProposeDuration = duration;
        emit MaxProposeDurationChanged(previousDuration, duration);
    }

    /**
    * @dev Throws if called by any account other than the approver.
    */
    modifier onlyApprover() {
        require(Approvers[msg.sender], "Governable: caller is not the approver");
        _;
    }

    /**
    * @dev Throws if called by any account other than the proposer.
    */
    modifier onlyProposer() {
        require(Proposers[msg.sender], "Governable: caller is not the proposer");
        _;
    }

    function setApprover(address account, bool approve) public onlyOwner {
        if (Approvers[account] != approve) {
            if (approve) {
                Approvers[account] = true;
                approverCount += 1;
            } else {
                delete Approvers[account];
                approverCount -= 1;
            }
            emit ApproverChanged(account, approve);
        }
    }

    function setProposer(address account, bool on) public onlyOwner {
        if (Proposers[account] != on) {

            if (on) {
                Proposers[account] = on;
            } else {
                delete Proposers[account];
            }
            emit ApproverChanged(account, on);
        }
    }

    function _isProposalExpired(uint256 proposeTime) internal view returns(bool) {
        return block.timestamp > proposeTime + maxProposeDuration;
    }
}


abstract contract Manageable is Governable {

    event ManagerProposed(address indexed proposer, address indexed newManager);
    event ManagerApproved(address indexed proposer, address indexed newManager, address indexed approver);
    event ManagerChanged(address indexed previousManager, address indexed newManager);

    struct ProposalManagerData {
        address     proposer;
        address     manager;
        uint256     proposeTime;
        uint256     approvedCount;
        mapping (address => bool) approvers;
    }

    address public manager;
    ProposalManagerData public proposalManager;


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyManager() {
        require(msg.sender == owner, "Manageable: caller is not the manager");
        _;
    }

    /**
    * @dev propose to mint
    * @param newManager propose newManager
    * @return mint propose ID
    */
    function proposeManager(address newManager) public onlyProposer()  returns(bool) {
        require(newManager != address(0), "Manageable: zero address not allowed" );
        require(proposalManager.approvedCount == 0 || _isProposalExpired(proposalManager.proposeTime), "Manageable: proposal is approving" );

        //proposalManager by a proposer for once only otherwise would be overwritten
        address previousManager = proposalManager.manager;
        proposalManager.proposer = msg.sender;
        proposalManager.manager = newManager;
        emit ManagerProposed(previousManager, newManager);
        return true;
    }

    function approveManager(address proposer, address newManager) public onlyApprover() returns(bool) {
        require( proposalManager.proposer != address(0) && proposalManager.manager != address(0),
            "Manageable: proposal manager data not exist" );
        require( proposer == proposalManager.proposer, "Manageable: proposer mismatch" );
        require( newManager == proposalManager.manager, "Manageable: newManager mismatch" );
        require( !_isProposalExpired(proposalManager.proposeTime), "Manageable: proposal is expired" );

        require( !proposalManager.approvers[msg.sender], "Manageable: duplicated approve mint" );

        proposalManager.approvedCount += 1;
        proposalManager.approvers[msg.sender] = true;
        emit ManagerApproved(proposer, newManager, msg.sender);

        return true;
    }

    function takeManager() public returns(bool) {
        require( proposalManager.proposer != address(0) && proposalManager.manager != address(0),
            "hiDollar: proposal manager data not exist" );

        require( proposalManager.approvedCount > 0, "hiDollar: no approve" );
        require( !_isProposalExpired(proposalManager.proposeTime), "hiDollar: proposal is expired" );
        // check approve pass?
        uint256 ratio = proposalManager.approvedCount * RATIO_PRECISION / approverCount;

        require( ratio >= MIN_APPROVE_RATIO, "hiDollar: approved count not reach min approve ratio yet" );

        address previousManager = manager;
        manager = proposalManager.manager;

        delete proposalManager;

        emit ManagerChanged(previousManager, manager);

        return true;
    }

}

/**
 * @title Frozenable Token
 * @dev Illegal address that can be frozened.
 */
abstract contract FrozenableToken
{

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed to, bool frozen);

    modifier whenNotFrozen(address who) {
      require(!frozenAccount[msg.sender] && !frozenAccount[who], "account frozen");
      _;
    }

    function freezeAccount(address to, bool freeze) public virtual returns(bool) {
        require(to != address(0), "0x0 address not allowed");
        require(to != msg.sender, "self address not allowed");

        frozenAccount[to] = freeze;
        emit FrozenFunds(to, freeze);
        return true;
    }

}


abstract contract Mintable is Manageable{

    event MintProposed(address indexed proposer, uint256 amount);
    event MintApproved(address indexed proposer, uint256 amount, address indexed approver);
    event MintEmitted(address indexed proposer, uint256 amount, address indexed emitter);

    struct ProposalMintData {
        uint256     amount;
        uint256     proposeTime;
        uint256     approvedCount;
        mapping (address => bool) approvers;
    }

    mapping (address => ProposalMintData) public proposalMints; /** proposer -> ProposalMintData */

    address public holder;


    function setHolder(address newHolder) public onlyManager {
        require(newHolder != address(0), "Mintable: zero address not allowed");
        holder = newHolder;
    }

    /**
    * @dev propose to mint
    * @param amount amount to mint
    * @return mint propose ID
    */
    function proposeMint(uint256 amount) public onlyProposer() returns(bool) {
        require(amount > 0, "Mintable: zero amount not allowed" );
        require(proposalMints[msg.sender].approvedCount == 0
            || _isProposalExpired(proposalMints[msg.sender].proposeTime), "Mintable: proposal is approving" );

        //mint by a proposer for once only otherwise would be overwritten
        proposalMints[msg.sender].amount = amount;
        proposalMints[msg.sender].proposeTime = block.timestamp;
        emit MintProposed(msg.sender, amount);

        return true;
    }

    function approveMint(address proposer, uint256 amount) public onlyApprover() returns(bool) {
        require( proposalMints[proposer].amount > 0, "Mintable: proposal mint data not exist" );
        require( proposalMints[proposer].amount > amount, "Mintable: amount mismatch" );
        require( !_isProposalExpired(proposalMints[proposer].proposeTime),
            "Mintable: proposal is expired" );

        require( !proposalMints[proposer].approvers[msg.sender], "Mintable: duplicated approve mint" );

        proposalMints[proposer].approvedCount += 1;
        proposalMints[proposer].approvers[msg.sender] = true;
        emit MintApproved(proposer, amount, msg.sender);

        return true;
    }

    function emitMint(address proposer) public returns(bool) {
        require( proposalMints[proposer].amount > 0, "Mintable: proposal mint data not exist" );
        require( proposalMints[proposer].approvedCount > 0, "Mintable: no approve" );
        require( !_isProposalExpired(proposalMints[proposer].proposeTime),
            "Mintable: proposal is expired" );
        // check approve pass?
        uint256 ratio = proposalMints[proposer].approvedCount * RATIO_PRECISION / approverCount;

        require( ratio >= MIN_APPROVE_RATIO, "Mintable: approved count not reach min approve ratio yet" );

        _doMint(holder, proposalMints[proposer].amount);

        delete proposalMints[proposer];
        emit MintEmitted(proposer, proposalMints[proposer].amount, msg.sender);

        return true;
    }


    function _doMint(address account, uint256 amount) internal virtual;

}

contract hiDollar is ERC20, ERC20Burnable, Pausable, FrozenableToken, Mintable {

    struct FeeRatioData {
        uint256 ratio;
        bool    enabled;
    }

    /**
     * @dev Emitted when `value` tokens of friction fee are moved from payer to this contract account.
     */
    event FrictionFee(address indexed payer, uint256 value);

    event FeeCollectorChanged(address indexed previousCollector, address indexed newCollector);
    event DefaultFeeRatioChanged(uint256 previousRatio, uint256 newRatio);

    event UserFeeRatioChanged(
        address indexed previousCollector,
        FeeRatioData previousRatioData,
        FeeRatioData newRatioData
    );

    event FeeCollected(address indexed collector, uint256 amount);

    address public feeCollector;                  /** fee collector */
    uint256 public defaultFeeRatio;               /** ratio of transfer friction fee */
    mapping(address => FeeRatioData) public userFeeRatios; /**  user fee ratio map, user => feeRatio */

    uint256 public fees;                        /** accumulated fees */


    constructor() ERC20("hi Dollar", "HI") {
        manager = msg.sender;
        holder = msg.sender;
        feeCollector = msg.sender;
        defaultFeeRatio = 200;           /** i.e. 2% */
        userFeeRatios[msg.sender].ratio = 0;
        userFeeRatios[msg.sender].enabled = true;
        userFeeRatios[address(this)].ratio = 0;
        userFeeRatios[address(this)].enabled = true;
    }

    function setFeeCollector(address newCollector) public onlyManager {
        require(newCollector != address(0), "hiDollar: zero address not allowed");
        address previousCollector = feeCollector;
        feeCollector = newCollector;
        emit FeeCollectorChanged(previousCollector, newCollector);
    }

    function setDefaultFeeRatio(uint256 newRatio) public onlyManager {
        require(newRatio <= MAX_FEE_RATIO, "hiDollar: new fee ratio exceeds MAX_FEE_RATIO");
        uint256 previousRatio = defaultFeeRatio;
        defaultFeeRatio = newRatio;
        emit DefaultFeeRatioChanged(previousRatio, newRatio);
    }

    function setUserFeeRatio(address user, uint256 ratio, bool enabled) public onlyManager {
        require(user != address(0), "hiDollar: zero address not allowed for user");
        require(ratio <= MAX_FEE_RATIO, "hiDollar: fee ratio exceeds MAX_FEE_RATIO");

        FeeRatioData memory previousRatioData = userFeeRatios[user];
        if (!enabled) {
            delete userFeeRatios[user];
        } else {
            userFeeRatios[user].ratio = ratio;
            userFeeRatios[user].enabled = true;
        }
        emit UserFeeRatioChanged(user, previousRatioData, userFeeRatios[user]);
    }

    function _getUserFeeRatio(address user) private view returns(uint256) {
        return userFeeRatios[user].enabled ? userFeeRatios[user].ratio : defaultFeeRatio;
    }

    function pause() public onlyManager {
        _pause();
    }

    function unpause() public onlyManager {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        whenNotFrozen(from)
        whenNotFrozen(to)
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }


    function freezeAccount(address to, bool freeze) public virtual override onlyManager() returns(bool) {
        return super.freezeAccount(to, freeze);
    }


    function _doMint(address account, uint256 amount) internal virtual override {
        _mint(account, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event from sender to recipient for actual amount.
     * Emits a {Transfer} event from sender to feeRecipient for friction fee if fee > 0.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount` and `friction fee`.
     * - `amount` can not be zero.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(amount > 0, "hiDollar: non-positive amount not allowed");
        uint256 fee = amount * _getUserFeeRatio(sender) / RATIO_PRECISION;
        if (fee > 0) {
            require(balanceOf(sender) >= amount + fee, "hiDollar: insufficient balance");
        }

        super._transfer(sender, recipient, amount);

        if (fee > 0) {
            // transfer friction fee to self account
            super._transfer(sender, address(this), fee);
            fees += fee;
            emit FrictionFee(sender, fee);
        }
    }

    function collectFee(uint256 amount) public returns (bool) {
        require(msg.sender == feeCollector, "hiDollar: non-feeCollector not allowed");
        require(amount <= fees, "hiDollar: the amount exceeds the collectable fees");
        fees -= amount;
        super._transfer(address(this), msg.sender, amount);
        emit FeeCollected(feeCollector, amount);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        _afterTokenTransfer(sender, recipient, amount);
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

        _afterTokenTransfer(address(0), account, amount);
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

        _afterTokenTransfer(account, address(0), amount);
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
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICnydToken.sol";
import "./Ownable.sol";

abstract contract Governable is Ownable {

    uint256 public constant APPROVER_COUNT = 3;
    uint256 public constant APPROVED_THRESHOLD = 3;

    enum ApprovedStatus { NONE, STARTED, APPROVED, OPPOSED }

    event ApproverChanged(uint256 idndex, address indexed newAccount, address indexed oldAccount);
    event ProposerChanged(address indexed account, bool enabled);


    uint256 public proposalDuration = 6 * 3600; // in second

    address[APPROVER_COUNT] public approvers;

    mapping (address => bool) public proposers;

    modifier onlyInit() virtual {
        require(approvers[0] != address(0), "Token contract is not init");
        _;
    }

    /**
    * @dev Throws if called by any account other than the approver.
    */
    modifier onlyApprover() {
        require(_isApprover(msg.sender), "Governable: caller is not an approver");
        _;
    }

    /**
    * @dev Throws if called by any account other than the proposer.
    */
    modifier onlyProposer() {
        require(proposers[msg.sender], "Governable: caller is not a proposer");
        _;
    }

    /**
    * @dev Throws if called by any account other than the approver and owner.
    */
    modifier onlyApproverAndOwner() {
        require(_isApprover(msg.sender) || msg.sender == owner(), "Governable: caller is not an approver or owner");
        _;
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Governable: zero amount not allowed" );
        _;
    }

    modifier validApproverIndex(uint256 index) {
        require(index < APPROVER_COUNT, "Governable: approver index invalid" );
        _;
    }

    function isInit() public view virtual returns(bool) {
        return approvers[0] != address(0);
    }

    function _isApproverDuplicated(address[APPROVER_COUNT] memory _approvers) internal pure returns(bool) {
        for (uint256 i = 0; i < _approvers.length; i++) {
            for (uint256 j = i + 1; j < _approvers.length; j++) {
                if (_approvers[i] == _approvers[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _setApprovers(address[APPROVER_COUNT] memory _approvers) internal {
        require(!_isApproverDuplicated(_approvers), "approvers duplicated");
        approvers = _approvers; 
        for (uint256 i = 0; i < _approvers.length; i++) {
            emit ApproverChanged(i, _approvers[i], address(0));
        }               
    }

    function _isApprover(address account) internal view returns(bool) {
        for (uint256 i = 0; i < approvers.length; i++) {
            if (approvers[i] == account)
                return true;
        }
        return false;
    }

    function _setApprover(uint256 id, address account) internal {
        require(id < APPROVER_COUNT, "Governable: approver id is out of range");
        require(account != approvers[id], "Governable: the account is same as the old one");
        require(!_isApprover(account), "Governable: the account is already an approver");

        address oldAccount = approvers[id];
        approvers[id] = account;
        emit ApproverChanged(id, account, oldAccount);
    }

    function setProposer(address account, bool enabled) public onlyOwner() onlyInit() {
        require(proposers[account] != enabled, "Governable: no change of enabled");
        proposers[account] = enabled;
        emit ProposerChanged(account, enabled);
    }

    function setProposalDuration(uint duration) public onlyOwner() {
        proposalDuration = duration;
    }

    function _accountExistIn(address account, address[] memory accounts) internal pure returns(bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (account == accounts[i]) return true;
        }
        return false;
    }

    function _isProposalExpired(uint startTime) internal view returns(bool) {   
        return block.timestamp > startTime + proposalDuration;    
    }

    function _isApprovable(uint startTime) internal view returns(bool) {
        return startTime > 0 && !_isProposalExpired(startTime);
    }

    function _isBurnBalanceEnough(uint256 amount) internal view virtual returns(bool);
}

abstract contract MintProposal is Governable {

    event MintProposed(address indexed proposer, address indexed to, uint256 amount);
    event MintApproved(address indexed approver, address indexed proposer, bool approved, address indexed to, uint256 amount);
    event HolderChanged(address indexed newHolder, address indexed oldHolder);

    struct MintProposalData {
        address                     to;
        uint256                     amount;
        uint                        startTime;
        address[]                   approvers;
    }

    mapping (address => MintProposalData) private mintProposals; /** proposer -> MintProposalData */

    function getMintProposal(address proposer) public view returns(MintProposalData memory) {
        return mintProposals[proposer];
    }

    /**
    * @dev propose to mint
    * @param amount amount to mint
    * @return mint propose ID
    */
    function proposeMint(address to, uint256 amount) public 
        onlyInit()
        onlyProposer() 
        onlyNonZeroAccount(to)
        onlyPositiveAmount(amount) 
        returns(bool) 
    {
        require(!_isApprovable(mintProposals[msg.sender].startTime), "MintProposal: proposal is approving" );

        delete mintProposals[msg.sender];
        //mint by a proposer for once only otherwise would be overwritten
        mintProposals[msg.sender].to = to;
        mintProposals[msg.sender].amount = amount;
        mintProposals[msg.sender].startTime = block.timestamp;
        emit MintProposed(msg.sender, to, amount);

        return true;
    }

    function approveMint(address proposer, bool approved, address to, uint256 amount) public onlyInit() onlyApprover() returns(bool) {
        MintProposalData memory proposal = mintProposals[proposer];
        require( _isApprovable(proposal.startTime), "MintProposal: proposal is not approvable" );
        require( proposal.to == to && proposal.amount == amount, "MintProposal: proposal data mismatch" );
        require( !_accountExistIn(msg.sender, proposal.approvers), "MintProposal: approver has already approved" );

        bool needExec = false;
        if (approved) {
            mintProposals[proposer].approvers.push(msg.sender);
            if (mintProposals[proposer].approvers.length == APPROVER_COUNT) {
                needExec = true;
                delete mintProposals[proposer];  
            }
        } else {
            delete mintProposals[proposer];           
        }
        emit MintApproved(msg.sender, proposer, approved, to, amount); 

        if (needExec) 
            _doMint(to, amount);

        return true;
    }

    function _doMint(address to, uint256 amount) internal virtual;
}

abstract contract BurnProposal is Governable {

    event BurnProposed(address indexed proposer, uint256 amount);
    event BurnApproved(address indexed approver, address indexed proposer, bool approved, uint256 amount);

    struct BurnProposalData {
        uint256                     amount;
        uint                        startTime;
        address[]                   approvers;
    }

    mapping (address => BurnProposalData) private _burnProposals; /** proposer -> BurnProposalData */

    function getBurnProposal(address proposer) public view returns(BurnProposalData memory) {
        return _burnProposals[proposer];
    }
    /**
    * @dev propose to burn
    * @param amount amount to burn
    * @return burn propose ID
    */
    function proposeBurn(uint256 amount) public 
        onlyInit()
        onlyProposer()
        onlyPositiveAmount(amount) 
        returns(bool) 
    {
        require(_isBurnBalanceEnough(amount), "BurnProposal: burn amount exceeds contract balance");
        require( !_isApprovable(_burnProposals[msg.sender].startTime), "BurnProposal: proposal is approving" );

        delete _burnProposals[msg.sender]; // clear proposal data
        //burn by a proposer for once only otherwise would be overwritten
        _burnProposals[msg.sender].amount = amount;
        _burnProposals[msg.sender].startTime = block.timestamp;
        emit BurnProposed(msg.sender, amount);

        return true;
    }

    function approveBurn(address proposer, bool approved, uint256 amount) public onlyInit() onlyApprover() returns(bool) {
        BurnProposalData memory proposal = _burnProposals[proposer];
        require( _isApprovable(proposal.startTime), "BurnProposal: proposal is not approvable" );
        require( proposal.amount == amount, "BurnProposal: proposal data mismatch" );
        require(_isBurnBalanceEnough(amount), "BurnProposal: burn amount exceeds contract balance");
        require( !_accountExistIn(msg.sender, proposal.approvers),
            "BurnProposal: approver has already approved" );

        bool needExec = false;
        if (approved) {
            _burnProposals[proposer].approvers.push(msg.sender);
            if (_burnProposals[proposer].approvers.length == APPROVER_COUNT) {
                needExec = true;
                delete _burnProposals[proposer];  
            }
        } else {
            delete _burnProposals[proposer];           
        }
        emit BurnApproved(msg.sender, proposer, approved, amount); 

        if (needExec)
            _doBurn(amount);
        return true;
    }

    function _doBurn(uint256 amount) internal virtual;
}

/**
 * approved by owner or approvers
 */
abstract contract ApproverProposal is Governable {

    event ApproverProposed(address indexed proposer, uint256 index, address indexed newApprover);
    event ApproverApproved(address indexed approver, address indexed proposer, uint256 index, address indexed newApprover);

    struct ApproverProposalData {
        uint256                     index;
        address                     newApprover;
        uint                        startTime;
        address[]                   approvers;
    }

    mapping (address => ApproverProposalData) public _approverProposals; /** proposer -> ApproverProposalData */

    function getApproverProposal(address proposer) public view returns(ApproverProposalData memory) {
        return _approverProposals[proposer];
    }

    /**
    * @dev propose to set approver
    * @param index index of approver
    * @param newApprover new approver
    * @return approver propose ID
    */
    function proposeApprover(uint256 index, address newApprover) public
        onlyInit()
        onlyProposer() 
        validApproverIndex(index)
        onlyNonZeroAccount(newApprover)
        returns(bool) 
    {
        require(!_isApprovable(_approverProposals[msg.sender].startTime), "ApproverProposal: proposal is approving" );

        delete _approverProposals[msg.sender]; // clear proposal data
        //approver by a proposer for once only otherwise would be overwritten
        _approverProposals[msg.sender].index = index;
        _approverProposals[msg.sender].newApprover = newApprover;
        _approverProposals[msg.sender].startTime = block.timestamp;
        emit ApproverProposed(msg.sender, index, newApprover);

        return true;
    }


    /**
     * approver can not unapprove
     */
    function approveApprover(address proposer, uint256 index, address newApprover) public 
        onlyInit()
        onlyApproverAndOwner() 
        returns(bool) 
    {

        ApproverProposalData memory proposal = _approverProposals[proposer];
        require( _isApprovable(proposal.startTime), "ApproverProposal: proposal is not approvable" );
        require( proposal.index == index && proposal.newApprover == newApprover, 
            "ApproverProposal: propose data mismatch" );
        require( !_accountExistIn(msg.sender, proposal.approvers),
            "ApproverProposal: approver has already approved" );

        bool needExec = false;
        _approverProposals[proposer].approvers.push(msg.sender);
        if (_approverProposals[proposer].approvers.length == APPROVER_COUNT) {
            needExec = true;
            delete _approverProposals[proposer];  
        }
        emit ApproverApproved(msg.sender, proposer, index, newApprover); 

        if (needExec)
            _setApprover(index, newApprover);

        return true;
    }
}


contract CnydAdmin is Ownable, Governable, MintProposal, BurnProposal, ApproverProposal {

    address public token;

    modifier onlyInit() override {
        require(token != address(0), 
            "Token contract is not init");
        _;
    }

    function isInit() public view override returns(bool) {
        return token != address(0);
    }

    function init(address _token, address[APPROVER_COUNT] memory _approvers) public onlyOwner onlyNonZeroAccount(_token) { 
        require(token == address(0), "Token contract has been initialized");
        token = _token;
        _setApprovers(_approvers);
        
        require(IOwnable(_token).owner() != address(this), "This contract has been the owner of Token contract");
        require(IOwnable(_token).proposedOwner() == address(this), "This contract is not the proposed owner of Token contract");
        takeTokenOwnership();
        setTokenAdmin(address(this));
    }

    function pause() public onlyOwner onlyInit() {
        ICnydToken(token).pause();
    }

    function unpause() public onlyOwner onlyInit() {
        ICnydToken(token).unpause();
    }

    function forceTransfer(address from, address to, uint256 amount) public onlyOwner onlyInit() {
        ICnydToken(token).forceTransfer(from, to, amount);
    }

    function _doMint(address to, uint256 amount) internal override onlyInit() {
        ICnydToken(token).mint(to, amount);
    }

    function _doBurn(uint256 amount) internal override {
        ICnydToken(token).burn(amount);
    }

    function _isBurnBalanceEnough(uint256 amount) internal view override returns(bool) {
        return IERC20(token).balanceOf(token) >= amount;
    }

    function proposeTokenOwner(address newOwner) public onlyOwner onlyInit() {
        IOwnable(token).proposeOwner(newOwner);
    }

    function takeTokenOwnership() public onlyOwner onlyInit() {
        IOwnable(token).takeOwnership();
    }

    function setTokenAdmin(address newAdmin) public onlyOwner onlyInit() { 
        IAdministrable(token).setAdmin(newAdmin);
    }

    function setAdminFeeRatio(uint256 ratio) public onlyOwner onlyInit() {
        IAdminFee(token).setAdminFeeRatio(ratio);
    }

    function setFeeRecipient(address recipient) public onlyOwner onlyInit() {
        IAdminFee(token).setFeeRecipient(recipient);
    }

    function addFeeWhitelist(address[] memory accounts) public onlyOwner onlyInit() {
        IAdminFee(token).addFeeWhitelist(accounts);
    }

    function delFeeWhitelist(address[] memory accounts) public onlyOwner onlyInit() {
        IAdminFee(token).delFeeWhitelist(accounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.2;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IOwnable {

    event OwnershipProposed(address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function owner() external view returns(address);
    function proposedOwner() external view returns(address);

    /**
    * @dev propose a new owner by an existing owner
    * @param newOwner The address proposed to transfer ownership to.
    */
    function proposeOwner(address newOwner) external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    */
    function takeOwnership() external;
}

interface IAdministrable {

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    function admin() external view returns(address);

    function setAdmin(address newAdmin) external;
}

/**
 * @title Frozenable Token
 * @dev Illegal address that can be frozened.
 */
interface IFrozenableToken {

    event AccountFrozen(address indexed to);
    event AccountUnfrozen(address indexed to);

    function isAccountFrozen(address account) external view returns(bool);

    function freezeAccount(address account) external;

    function unfreezeAccount(address account) external;
}

interface IAdminFee {

    event AdminFeeRatioChanged(uint256 oldRatio, uint256 newRatio);
    event FeeRecipientChanged(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event FeeWhitelistAdded(address[] accounts);
    event FeeWhitelistDeleted(address[] accounts);


    function ratioPrecision() external view returns(uint256);

    function adminFeeRatio() external view returns(uint256);

    function setAdminFeeRatio(uint256 ratio) external;

    function feeRecipient() external view returns(address);

    function setFeeRecipient(address recipient) external;

    function isInFeeWhitelist(address account) external view returns(bool);

    function addFeeWhitelist(address[] memory accounts) external;

    function delFeeWhitelist(address[] memory accounts) external;
    
}

interface ICnydToken is IERC20 {

    event ForceTransfer(address indexed from, address indexed to, uint256 amount);

    function pause() external;

    function unpause() external;

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address to, uint256 amount) external;


    /**
     * @dev Destroys `amount` tokens from contract account, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(uint256 amount) external;

    function forceTransfer(address from, address to, uint256 amount) external;

    /**
     * A query function that returns the amount of tokens a receiver will get if a sender sends `sentAmount` tokens. 
     * Note the `to` and `from` addresses are present, the implementation should use those values to check for any whitelist.
     */
    function getReceivedAmount(
        address from,
        address to,
        uint256 sentAmount
    ) external view returns (uint256 receivedAmount, uint256 feeAmount);

    /**
     * Returns the amount of tokens the sender has to send if he wants the receiver to receive exactly `receivedAmount` tokens.
     * Note the `to` and `from` addresses are present, the implementation should use those values to check for any whitelist.
     */
    function getSentAmount(
        address from,
        address to,
        uint256 receivedAmount
    ) external view returns (uint256 sentAmount, uint256 feeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma experimental ABIEncoderV2;

import "./ICnydToken.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable is IOwnable
{
    address private _owner;
    address private _proposedOwner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual override returns(address) {
        return _owner;
    }

    function proposedOwner() public view virtual override returns(address) {
        return _proposedOwner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the proposed owner.
    */
    modifier onlyProposedOwner() {
        require(_proposedOwner != address(0) && msg.sender == _proposedOwner, 
            "Ownable: caller is not the proposed owner");
        _;
    }

    modifier onlyNonZeroAccount(address account) {
        require(account != address(0), "zero account not allowed" );
        _;
    }

    /**
    * @dev propose a new owner by an existing owner
    * @param newOwner The address proposed to transfer ownership to.
    */
    function proposeOwner(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _proposedOwner = newOwner;
        emit OwnershipProposed(newOwner);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    */
    function takeOwnership() public virtual override onlyProposedOwner {
        _transferOwnership(_proposedOwner);
        _proposedOwner = address(0);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// File: contracts/tokens-base/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/tokens-base/IERC20Metadata.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/utils/Context.sol

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

// File: contracts/tokens-base/ERC20.sol

pragma solidity ^0.8.0;

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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
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
     * - `to` cannot be the zero address.
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

        // TODO: remove before hook unless needed
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
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

// File: contracts/core/YoloPolygonUtilityTokens.sol

pragma solidity 0.8.4;

// import {NativeMetaTransaction} from "../utils/NativeMetaTransaction.sol";
// import {ContextMixin} from "../utils/ContextMixin.sol";

/**
 * @dev {YoloPolygonUtilityTokens} token, including:
 *
 *  - No initial supply
 *  - Controlled by
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 */
contract YoloPolygonUtilityTokens is ERC20 {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */

    // set childChainManagerProxy to RootChainManager for unit testing
    address public childChainManagerProxy;
    address deployer;

    constructor(
        string memory name,
        string memory symbol,
        address _childChainManagerProxy
    ) ERC20(name, symbol) {
        childChainManagerProxy = _childChainManagerProxy; // 0xb5505a6d998549090530911180f38aC5130101c6
        deployer = msg.sender;
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it
    function updateChildChainManager(address newChildChainManagerProxy)
        external
    {
        require(
            newChildChainManagerProxy != address(0),
            "Bad ChildChainManagerProxy address"
        );
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes calldata depositData) external {
        require(
            msg.sender == childChainManagerProxy,
            "You're not allowed to deposit"
        );

        uint256 amount = abi.decode(depositData, (uint256));

        // `amount` token getting minted here & equal amount got locked in RootChainManager
        _totalSupply += amount;
        _balances[user] += (amount);

        emit Transfer(address(0), user, amount);
    }

    function withdraw(uint256 amount) external {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}

// File: contracts/access/Ownable.sol

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;

    // Sets the original owner of
    // contract when it is deployed
    constructor() {
        owner = msg.sender;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier restricted() {
        require(msg.sender == owner, "Must have admin role to invoke");
        _;
    }

    function transferOwner(address newOwner)
        external
        restricted
        returns (bool)
    {
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);

        return true;
    }
}

// File: contracts/fx-portal/tunnel/FxBaseChildTunnel.sol

pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor, Ownable {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // just in case
    function setFxChild(address _fxChild) public restricted {
        require(
            _fxChild != address(0),
            "fxChild contract address must be specified"
        );
        fxChild = _fxChild;
    }

    // n.b.: not needed in our process
    function setFxRootTunnel(address _fxRootTunnel) public restricted {
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) public override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// File: contracts/issuance/IssuanceCommon.sol

pragma solidity 0.8.4;

abstract contract IssuanceCommon is Ownable {
    uint256 public immutable deploymentTimestamp;

    address public fundRecipient;
    bool public isContributionWindowOpen;
    bool public isContributionWindowClosed;
    bool public isRedemptionRegimeOpen;
    uint256 public contributionStartTimestamp;

    // Mapping contributors address to amount
    mapping(address => uint256) public contributorAmounts;

    mapping(address => bool) public claimsCheck;

    event ContributionWindowOpened(address indexed authorizer);
    event ContributionMade(address indexed contributor, uint256 value);
    event ContributionWindowClosed(address indexed authorizer, uint256 value);
    event RedemptionWindowOpened(
        address indexed authorizer,
        uint256 contributionValue,
        uint256 allocatedTokens
    );
    event TokensRedeemed(address indexed redeemer, uint256 value);
    event InvestmentFundTransferred(address indexed recipient, uint256 value);

    modifier validateRecipient(address _recipient) {
        require(_recipient != address(0), "recipient cannot be zero address");
        require(
            _recipient == fundRecipient,
            "recipient must match registered fund receiver!"
        );
        _;
    }

    constructor() {
        deploymentTimestamp = block.timestamp;
    }

    function openContributionWindow() external virtual returns (bool);

    function closeContributionWindow() external virtual returns (bool);

    function openRedemptionRegime() external virtual returns (bool);

    function registerFundRecipient(address _fundRecipient)
        external
        restricted
        returns (bool)
    {
        fundRecipient = _fundRecipient;

        return true;
    }

    function redeemTokens() external virtual returns (bool);
}

// File: contracts/issuance/IssuancePolygon.sol

/**

YOLOrekt Token Issuance - 

YOLOrekt is issuing 5% of the 1 Billion total supply to raise capital to provide in-game liquidity. 
This contracts accepts matic wEth (wEth) token contributions for acquiring early YOLO tokens at a price that 
is determined at contribution close by calculating proportion of funds raised on the polygon child chain 
with respect to the Ethereum root chain and bridging the appropriate share of YOLO tokens to the 
child issuance contract (IssuancePolygon) for redemption by the contributors.

https://yolorekt.com 

Authors :
Garen Vartanian
Yogesh Srihari 

**/

pragma solidity 0.8.4;

contract IssuancePolygon is IssuanceCommon, FxBaseChildTunnel {
    // Contribution Sum on Polygon Side
    uint256 public childSum;
    // Proportion of tokens transferred to polygon issuance contract
    uint256 public childIssuanceAllocatedTokens;

    // After ending token issuance, sum is sent to the root and flag to record the state.
    bool public isMessageSentToRoot;

    // YOLOrekt ERC20 contract
    YoloPolygonUtilityTokens public yoloPolygonTokenContract;

    // Contribution is Erc20 mEth
    IERC20 public mEthTokenContract;

    // Data coming from the Root(IssuanceEthereum) To Child (IssuancePolygon) messaging
    // uint256 public latestStateId;
    // address public latestRootMessageSender;
    // bytes public latestData;

    constructor(
        address yoloPolygonTokenAddress_,
        address mEthTokenContractAddress_,
        address fxChild_
    ) FxBaseChildTunnel(fxChild_) {
        require(
            yoloPolygonTokenAddress_ != address(0),
            "YOLO polygon token contract address must be specified"
        );
        require(
            mEthTokenContractAddress_ != address(0),
            "mEth token contract address must be specified"
        );
        require(
            fxChild_ != address(0),
            "fxChild contract address must be specified"
        );

        yoloPolygonTokenContract = YoloPolygonUtilityTokens(
            yoloPolygonTokenAddress_
        );
        mEthTokenContract = IERC20(mEthTokenContractAddress_);
    }

    // just in case
    function setYoloPolygonTokenContract(address _yoloPolygonTokenAddress)
        public
        restricted
    {
        require(
            _yoloPolygonTokenAddress != address(0),
            "YOLO polygon token contract address must be specified"
        );
        yoloPolygonTokenContract = YoloPolygonUtilityTokens(
            _yoloPolygonTokenAddress
        );
    }

    // just in case
    function setMEthTokenContract(address _mEthTokenContractAddress)
        public
        restricted
    {
        require(
            _mEthTokenContractAddress != address(0),
            "mEth token contract address must be specified"
        );
        mEthTokenContract = IERC20(_mEthTokenContractAddress);
    }

    function openContributionWindow()
        external
        override
        restricted
        returns (bool)
    {
        require(
            yoloPolygonTokenContract.balanceOf(address(this)) == 0,
            "No tokens must be transferred to issuance contract before issuance is started"
        );
        require(
            isContributionWindowOpen == false,
            "contribution window already opened"
        );

        isContributionWindowOpen = true;
        contributionStartTimestamp = block.timestamp;
        emit ContributionWindowOpened(msg.sender);

        return true;
    }

    function contribute(uint256 mEthAmount) public returns (bool) {
        require(
            isContributionWindowOpen == true,
            "contribution window has not opened"
        );
        require(
            isContributionWindowClosed == false,
            "contribution window has closed"
        );
        require(mEthAmount >= 0.01 ether, "minimum contribution is 0.01 ether");

        require(
            mEthAmount <=
                mEthTokenContract.allowance(msg.sender, address(this)),
            "contributor must approve issuance contract via mEth token contract in order to contribute tokens"
        );

        uint256 contributorTotal = contributorAmounts[msg.sender] + mEthAmount;

        mEthTokenContract.transferFrom(msg.sender, address(this), mEthAmount);
        contributorAmounts[msg.sender] = contributorTotal;

        // Fixed Here - Check again
        childSum += mEthAmount;

        emit ContributionMade(msg.sender, mEthAmount);

        return true;
    }

    // !!! Added virtual for unit testing !!!
    function closeContributionWindow()
        external
        virtual
        override
        restricted
        returns (bool)
    {
        require(
            isContributionWindowOpen == true,
            "contribution window must be open before closing"
        );

        isContributionWindowClosed = true;
        emit ContributionWindowClosed(msg.sender, childSum);

        bytes memory message = abi.encode(childSum);
        _sendMessageToRoot(message);
        isMessageSentToRoot = true;

        return true;
    }

    // !!! Added virtual for unit testing !!!
    // function sendMessageToRoot() internal virtual {
    //     require(
    //         isContributionWindowClosed == true,
    //         "cannot send child contribution sum until contribution window closed"
    //     );
    //     bytes memory message = abi.encode(childSum);
    //     _sendMessageToRoot(message);
    //     isMessageSentToRoot = true;
    // }

    // !!! Add virtual for unit testing !!!
    function openRedemptionRegime() external virtual override returns (bool) {
        // Which will unlock once the product goes live.
        require(
            isContributionWindowClosed == true,
            "contribution window must be closed"
        );
        require(isMessageSentToRoot == true, "childSum must be sent to root");
        require(
            msg.sender == owner ||
                block.timestamp > contributionStartTimestamp + 60 days,
            "cannot open redemption window unless owner or 60 days since deployment"
        );

        uint256 tokensAllocated = yoloPolygonTokenContract.balanceOf(
            address(this)
        );

        require(
            tokensAllocated > 0,
            "child issuance contract must receive tokens first"
        );
        require(
            isRedemptionRegimeOpen == false,
            "redemption regime already open"
        );

        childIssuanceAllocatedTokens = tokensAllocated;
        isRedemptionRegimeOpen = true;

        emit RedemptionWindowOpened(
            msg.sender,
            childSum,
            childIssuanceAllocatedTokens
        );

        return true;
    }

    // !!! Added virtual for unit testing !!!
    function redeemTokens() external virtual override returns (bool) {
        require(
            isRedemptionRegimeOpen == true,
            "redemption window is not open yet"
        );
        require(claimsCheck[msg.sender] == false, "prior claim executed");

        claimsCheck[msg.sender] = true;

        uint256 claimAmount = (contributorAmounts[msg.sender] *
            childIssuanceAllocatedTokens) / childSum;

        contributorAmounts[msg.sender] = 0;

        yoloPolygonTokenContract.transfer(msg.sender, claimAmount);
        emit TokensRedeemed(msg.sender, claimAmount);

        return true;
    }

    function migrateInvestmentFund(address recipient)
        external
        restricted
        validateRecipient(recipient)
        returns (bool)
    {
        require(
            isContributionWindowClosed == true,
            "contribution window must be closed"
        );

        uint256 contractBalance = mEthTokenContract.balanceOf(address(this));
        mEthTokenContract.transfer(recipient, contractBalance);
        emit InvestmentFundTransferred(recipient, contractBalance);

        return true;
    }

    // !!! should be unused !!!
    // Implemented but should be unused
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // latestStateId = stateId;
        // latestRootMessageSender = sender;
        // latestData = data;
    }
}
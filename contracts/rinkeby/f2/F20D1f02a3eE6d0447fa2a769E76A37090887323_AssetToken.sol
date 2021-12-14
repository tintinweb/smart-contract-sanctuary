// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CompoundRateKeeper.sol";

/// @author Diego Bale (https://www.linkedin.com/in/diegobale)
/// @title AssetToken
/// @notice Main AST Token Contract
contract AssetToken is ERC20, CompoundRateKeeper {
    using SafeMath for uint256;

    /// @notice Structure to hold the Mint Requests
    struct MintRequest {
        address destination;
        bool completed;
    }
    /// @notice Mint Requests mapping and last ID
    mapping(uint256 => MintRequest) public mintRequests;
    uint256 public mintRequestID;

    /// @notice Structure to hold the Redemption Requests
    struct RedemptionRequest {
        address sender;
        string recipient;
        uint256 assetTokenAmount;
        uint256 underlyingAssetAmount;
        bool completed;
        bool fromStake;
        string approveTxID;
        address canceledBy;
    }
    /// @notice Redemption Requests mapping and last ID
    mapping(uint256 => RedemptionRequest) public redemptionRequests;
    uint256 public redemptionRequestID;

    /// @notice stakedRedemptionRequests is map from requester to request ID
    /// @notice exists to detect that sender already has request from stake function
    mapping(address => uint256) public stakedRedemptionRequests;

    /// @notice normalize amount
    mapping(address => uint256) public safeguardStakes;
    uint256 public totalStakes;

    /// @notice State of the contract
    uint256 public statePercent;

    string public kya;

    event FreezeStateChanged(address indexed _caller, bool _freezeState);
    event ChangedKya(address indexed _caller, string _link);
    event ChangedToSafeGuard(address indexed _amountFrom, uint256 _stakedPercent);
    event MintRequested(uint256 indexed _mintRequestID);
    event MintApproved(uint256 indexed _mintRequestID);
    event RedemptionRequested(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        address _caller
    );
    event RedemptionApproved(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        address _caller
    );
    event FreezedContract(address indexed _caller);
    event TokenBurned(address indexed _caller, uint256 _amount);
    event SafeguardUnstaked(address indexed _caller, uint256 _amount);
    event RedemptionCanceled(uint256 indexed _redemptionRequestID, string _motive, address indexed _caller);

    /// @notice Check if the freezeState variable is false (NOT Freezed contract)
    modifier onlyUnfreeze() {
        require(!freezeState, "Contract is Freezed");
        _;
    }

    /// @notice Check if the contract is Active
    modifier onlyActiveState() {
        require(state == ContractState.active, "State Not Active");
        _;
    }

    /// @notice Constructor: sets the state variables and provide proper checks to deploy
    /// @param _issuer the issuer of the contract
    /// @param _guardian the guardian
    /// @param _statePercent the state percent to check the safeguard convertion
    /// @param _kya verification link
    /// @param _maxQtyOfAuthorizationLists max qty for addresses to be added in the authorization list
    constructor(
        address _issuer,
        address _guardian,
        uint256 _statePercent,
        string memory _kya,
        uint256 _maxQtyOfAuthorizationLists
    ) ERC20("AssetToken", "AST") {
        require(_issuer != address(0), "Invalid Issuer address provided");
        require(_guardian != address(0), "Invalid Guardian address provided");
        require(_statePercent > 0, "Invalid State Percent provided");
        // require(_statePercent < hundredPercent, "MAX State Percent provided ?"); // TODO MAX state percent ???

        require(bytes(_kya).length > 3, "Invalid Verification Link provided");
        require(_maxQtyOfAuthorizationLists > 0, "Max Quantity of Authorization List too small");
        require(_maxQtyOfAuthorizationLists < 100, "Max Quantity of Authorization List too large");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        guardian = _guardian;
        issuer = _issuer;

        state = ContractState.active;
        statePercent = _statePercent;
        kya = _kya;
        maxQtyOfAuthorizationLists = _maxQtyOfAuthorizationLists;
    }

    /// @notice Hook to be executed before every transfer and mint
    /// @notice This overrides the ERC20 defined function
    /// @param _from the sender
    /// @param _to the receipent
    /// @param _amount the amount (it is not used  but needed to be defined to override)
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override onlyUnfreeze {
        //burn case
        if (_to != address(0)) {
            require(mustBeAuthorizedHolder(_to), "BTT: _account not authorized");
        }

        // means that isn't mint or burn, so active state required for common transfer
        // if (_from != address(0) && _to != address(0)) {
        //     if (!redemptionFromUser) {
        //         require(state == ContractState.active, "BTT: State not Active");
        //     }
        // }
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    /// @notice Sets the verification link
    /// @param _kya value to be set
    function setKya(string memory _kya) external onlyIssuer onlyUnfreeze onlyActiveState {
        require(bytes(_kya).length > 3, "Invalid Verification Link provided");
        emit ChangedKya(_msgSender(), _kya);
        kya = _kya;
    }

    /// @notice Sets the freezeState variable to freeze the contract
    /// @param _freezeState value to be set
    function setFreezeState(bool _freezeState) external onlyIssuerOrGuardian {
        if (freezeState) {
            require(!_freezeState, "Contract is Freezed");
        } else {
            require(_freezeState, "Contract is not Freezed");
        }

        emit FreezeStateChanged(_msgSender(), _freezeState);
        freezeState = _freezeState;
    }

    /// @notice Requests a mint to the caller
    /// @return The request ID to be referenced in the mapping
    function requestMint() external returns (uint256) {
        return _requestMint(_msgSender());
    }

    /// @notice Requests a mint to the _destination address
    /// @param _destination the receiver of the tokens
    /// @return The request ID to be referenced in the mapping
    function requestMintTo(address _destination) external returns (uint256) {
        return _requestMint(_destination);
    }

    /// @notice Performs the Mint Request to the destination address
    /// @param _destination the receiver of the tokens
    /// @return The request ID to be referenced in the mapping
    function _requestMint(address _destination) private onlyActiveState onlyUnfreeze onlyAgent returns (uint256) {
        uint256 _mintRequestID = ++mintRequestID;
        mintRequests[_mintRequestID] = MintRequest(_destination, false);
        mintRequestID = _mintRequestID;
        emit MintRequested(_mintRequestID);
        return _mintRequestID;
    }

    /// @notice Approves the Mint Request
    /// @param _mintRequestID the ID to be referenced in the mapping
    /// @param _amount underlying amount in human readable form to calculate how much will be minted  ????
    function approveMint(uint256 _mintRequestID, uint256 _amount) external onlyIssuer onlyActiveState {
        require(mintRequests[_mintRequestID].destination != address(0), "APM: invalid Mint RequestID");
        require(mustBeAuthorizedHolder(mintRequests[_mintRequestID].destination), "APM: _account not authorized");

        require(!mintRequests[_mintRequestID].completed, "APM: already completed");

        CompoundRateKeeper.update();
        emit MintApproved(_mintRequestID);
        ERC20._mint(
            mintRequests[_mintRequestID].destination,
            _amount.mul(CompoundRateKeeper.decimal).div(CompoundRateKeeper.compoundRate.rate)
        );
        mintRequests[_mintRequestID].completed = true;
    }

    /// @notice Requests an amount of assetToken Redemption
    /// @param _assetTokenAmount the amount of Asset Token to be redeemed
    /// @param _recipient the off chain hash of the redemption transaction
    /// @return redemption request ID to be referenced in the mapping
    function requestRedemption(uint256 _assetTokenAmount, string memory _recipient)
        external
        onlyIssuerOrAgentOrAuthorizedHolder
        returns (uint256)
    {
        require(_assetTokenAmount > 0, "RRD: Invalid _assetTokenAmount provided");
        require(ERC20.balanceOf(_msgSender()) >= _assetTokenAmount, "RRD: not enough to redeem");

        return _requestRedemption(_msgSender(), _recipient, _assetTokenAmount);
    }

    /// @notice Performs the Redemption
    /// @param _sender the caller of the request
    /// @param _recipient the off chain hash of the redemption transaction
    /// @param _assetTokenAmount the assetToken amount to be redeemed
    /// @return redemption request ID to be referenced in the mapping
    function _requestRedemption(
        address _sender,
        string memory _recipient,
        uint256 _assetTokenAmount
    ) private returns (uint256) {
        /// @dev make the transfer to the contract for the amount requested (27 digits)
        ERC20._transfer(_msgSender(), address(this), _assetTokenAmount);

        CompoundRateKeeper.update();

        uint256 underlyingAssetAmount = _assetTokenAmount.mul(CompoundRateKeeper.compoundRate.rate).div(
            CompoundRateKeeper.decimal
        );

        redemptionRequestID = redemptionRequestID.add(1);
        emit RedemptionRequested(redemptionRequestID, _assetTokenAmount, underlyingAssetAmount, _sender);

        redemptionRequests[redemptionRequestID] = RedemptionRequest(
            _sender,
            _recipient,
            _assetTokenAmount,
            underlyingAssetAmount,
            false,
            false,
            "",
            address(0)
        );

        return redemptionRequestID;
    }

    // reject redemption
    // the issuer can reject any redemption state active / guardian in safeguard

    // active or safeguard
    // agent can cancel only their own redemption ...
    // only si son tokens holders (osea es el mismo persona el agent y el holder)

    // holder solo pueden reject las suyas

    function cancelRedemptionRequestByAuthorities(uint256 _redemptionRequestID, string memory _motive)
        external
        onlyIssuerOrGuardian
    {
        _cancelRedemptionRequest(_redemptionRequestID, _motive);
    }

    function cancelRedemptionRequestByHolder(uint256 _redemptionRequestID, string memory _motive) external {
        require(mustBeAuthorizedHolder(_msgSender()), "CRR: _account not authorized");
        require(redemptionRequests[_redemptionRequestID].sender == _msgSender(), "CRR: sender is not request owner");
        _cancelRedemptionRequest(_redemptionRequestID, _motive);
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _motive motive of the cancelation
    function _cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) internal {
        require(redemptionRequests[_redemptionRequestID].canceledBy == address(0), "CRR:Redemption canceled");        

        require(redemptionRequests[_redemptionRequestID].sender != address(0), "CRR: Invalid ID provided");
        require(!redemptionRequests[_redemptionRequestID].completed, "CCR: already completed");
        emit RedemptionCanceled(_redemptionRequestID, _motive, _msgSender());

        uint256 refundAmount = redemptionRequests[_redemptionRequestID].assetTokenAmount;
        redemptionRequests[_redemptionRequestID].assetTokenAmount = 0;
        redemptionRequests[_redemptionRequestID].underlyingAssetAmount = 0;
        redemptionRequests[_redemptionRequestID].canceledBy = _msgSender();

        delete stakedRedemptionRequests[_msgSender()]; // = redemptionRequestID;

        ERC20._transfer(address(this), _msgSender(), refundAmount);
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _approveTxID the transaction ID
    function approveRedemption(uint256 _redemptionRequestID, string memory _approveTxID)
        external
        onlyIssuerOrGuardian
    {
        require(redemptionRequests[_redemptionRequestID].canceledBy == address(0), "APR: Redemption canceled");
        require(redemptionRequests[_redemptionRequestID].sender != address(0), "APR: Invalid ID provided");
        require(!redemptionRequests[_redemptionRequestID].completed, "APR: already completed");

        if (redemptionRequests[_redemptionRequestID].fromStake) {
            require(state == ContractState.safeguard, "APR: state is not Safeguard");

            /// @dev unreachable code. Modifier checks if on safeguard, caller should be guardian
            // require(_msgSender() == guardian, "APR: caller is not Guardian");
        }

        emit RedemptionApproved(
            _redemptionRequestID,
            redemptionRequests[_redemptionRequestID].assetTokenAmount,
            redemptionRequests[_redemptionRequestID].underlyingAssetAmount,
            redemptionRequests[_redemptionRequestID].sender
        );
        // burn tokens from the contract
        ERC20._burn(address(this), redemptionRequests[_redemptionRequestID].assetTokenAmount);

        redemptionRequests[_redemptionRequestID].completed = true;
        redemptionRequests[_redemptionRequestID].approveTxID = _approveTxID;
    }

    /// @notice Burns a certain amount of tokens
    /// @param _amount qty of assetTokens to be burned
    function burn(uint256 _amount) external {
        ERC20._burn(_msgSender(), _amount);
        emit TokenBurned(_msgSender(), _amount);
    }

    /// @notice Performs the Safeguard Stake
    /// @param _amount the assetToken amount to be staked
    /// @param _recipient the off chain hash of the redemption transaction
    function safeguardStake(uint256 _amount, string memory _recipient) external onlyActiveState {
        // no control before changing contracts variables state ?

        ERC20._transfer(_msgSender(), address(this), _amount);
        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()].add(_amount);

        totalStakes = totalStakes.add(_amount);
        uint256 stakedPercent = totalStakes.mul(hundredPercent).div(ERC20.totalSupply());

        if (stakedPercent >= statePercent) {
            state = ContractState.safeguard;
            emit ChangedToSafeGuard(_msgSender(), stakedPercent);
        }

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        // RedemptionRequest memory _info = redemptionRequests[_requestID];
        if (_requestID == 0) {
            /// @dev zero means that it's new request
            redemptionRequestID = redemptionRequestID.add(1);
            redemptionRequests[redemptionRequestID].sender = _msgSender();
            redemptionRequests[redemptionRequestID].recipient = _recipient;
            redemptionRequests[redemptionRequestID].assetTokenAmount = _amount;
            redemptionRequests[redemptionRequestID].underlyingAssetAmount = 0;
            redemptionRequests[redemptionRequestID].completed = false;
            redemptionRequests[redemptionRequestID].fromStake = true;
            redemptionRequests[redemptionRequestID].approveTxID = "";
            redemptionRequests[redemptionRequestID].canceledBy = address(0);
            stakedRedemptionRequests[_msgSender()] = redemptionRequestID;
            _requestID = redemptionRequestID;
            // redemptionRequests[redemptionRequestID] = _info;
        } else {
            /// @dev means that request already exist and need only add amount
            redemptionRequests[_requestID].assetTokenAmount = redemptionRequests[_requestID].assetTokenAmount.add(_amount);
            // redemptionRequests[_requestID] = _info;
        }

        emit RedemptionRequested(
            _requestID,
            redemptionRequests[_requestID].assetTokenAmount,
            redemptionRequests[_requestID].underlyingAssetAmount,
            _msgSender()
        );
        ERC20.approve(guardian, redemptionRequests[_requestID].assetTokenAmount);
    }

    /// @notice Calls to UnStake all the funds
    function safeguardUnstakeAll() external {
        _safeguardUnstake(safeguardStakes[_msgSender()]);
    }

    /// @notice Calls to UnStake with a certain amount
    /// @param _amount to be unStaked
    function safeguardUnstakeAmount(uint256 _amount) external {
        _safeguardUnstake(_amount);
    }

    /// @notice Performs the UnStake with a certain amount
    /// @param _amount to be unStaked
    function _safeguardUnstake(uint256 _amount) private onlyActiveState {
        require(_amount > 0, "SFU: _amount is ZERO");
        require(safeguardStakes[_msgSender()] >= _amount, "SFU: _amount provided exceeds user amount");
        require(mustBeAuthorizedHolder(_msgSender()), "SFU: _account not authorized");

        emit SafeguardUnstaked(_msgSender(), _amount);
        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()].sub(_amount);
        totalStakes = totalStakes.sub(_amount);
        ERC20._transfer(address(this), _msgSender(), _amount);

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        // RedemptionRequest memory _info = redemptionRequests[_requestID];
        redemptionRequests[_requestID].assetTokenAmount = redemptionRequests[_requestID].assetTokenAmount.sub(_amount);
        // redemptionRequests[_requestID] = redemptionRequests[_requestID];

        ERC20.approve(guardian, redemptionRequests[_requestID].assetTokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./DSMath.sol";
import "./AccessManager.sol";

/// @author Diego Bale (https://www.linkedin.com/in/diegobale)
/// @title Compound Rate Keeper for AST Token Contract
/// @notice Contract to manage the interest rate on the AST Token contract
abstract contract CompoundRateKeeper is AccessManager {
    using SafeMath for uint256;

    /// @notice Structure to hold the Compound Rate
    struct CompoundRate {
        uint256 rate;
        uint256 lastUpdate;
    }
    CompoundRate public compoundRate;

    uint256 public constant decimal = 10**27; // 10 ** 27
    
    uint256 public constant hundredPercent = 10**27;
    
    uint256 private interestRate;
    bool private pos;

    event InterestRateStored(address indexed _caller, uint256 _interestRate, bool _pos);
    event RateUpdated(address indexed _caller, uint256 _newRate, bool _pos);

    /// @notice Constructor: initialize Compound Structure
    constructor() {
        compoundRate.rate = decimal;
        compoundRate.lastUpdate = block.timestamp;
    }

    /// @notice Gets the interest rate and positive/negative interest value
    function getInterestRate() external view returns (uint256, bool) {
        return (interestRate, pos);
    }

    /// @notice Gets the current rate
    function getCurrentRate() external view returns (uint256) {
        return compoundRate.rate;
    }

    /// @notice Gets the timestamp of the last update
    function getLastUpdate() external view returns (uint256) {
        return compoundRate.lastUpdate;
    }

    /// @notice Sets the new intereset rate
    /// @param _interestRate the value to be set
    /// @param _pos if it's a negative or positive interest
    function setInterestRate(uint256 _interestRate, bool _pos) external onlyIssuer {
        // TODO 20 digits - check this number and why
        require(_interestRate < 21979553151239153027, "CRK: Rate is too high"); 
        emit InterestRateStored(_msgSender(), _interestRate, _pos);
        update();
        interestRate = _interestRate;
        pos = _pos;
    }

    /// @notice Update the Compound Structure counting the blocks since the last update
    /// @notice and calculating the rate
    /// @return the calculated newRate
    function update() public onlyIssuerOrAgentOrAuthorizedHolder returns (uint256) {
        uint256 _period = (block.timestamp).sub(compoundRate.lastUpdate);
        uint256 _newRate;

        if (pos) {
            _newRate = compoundRate.rate.mul(DSMath.rpow(decimal.add(interestRate), _period)).div(decimal);
        } else {
            _newRate = compoundRate.rate.mul(DSMath.rpow(decimal.sub(interestRate), _period)).div(decimal);
        }

        compoundRate.rate = _newRate;
        compoundRate.lastUpdate = block.timestamp;

        emit RateUpdated(_msgSender(), _newRate, pos);
        return _newRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
pragma solidity >=0.6.0 <0.8.0;

// Extracted from https://github.com/dapphub/ds-math

// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

library DSMath {
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IAuthorizationContracts.sol";

/// @author Diego Bale (https://www.linkedin.com/in/diegobale)
/// @title Access Manager for AssetToken Token Contract
/// @notice Contract to manage accesses and uses of the AST tokens
abstract contract AccessManager is AccessControl {
    /// @notice options of the contract state
    enum ContractState {
        active,
        safeguard
    }

    /// @notice state of the contract
    ContractState public state;

    /// @notice guardian and issuer of the contract
    address public guardian;
    address public issuer;

    /// @notice max quantity of contracts allowed
    uint256 public maxQtyOfAuthorizationLists;

    /// @notice boolean to store if the contract is freezed
    bool public freezeState;

    /// @notice agent => bool (enabled/disabled agent)
    mapping(address => bool) public agents;

    /// @notice account => bool (if enabled, account is blacklisted)
    mapping(address => bool) public blacklist;

    /// @notice authorization contracts => agents: 
    /// @notice  list of addresses of each agent to authorize a user
    mapping(address => address) public authorizationsPerAgent;

    /// @notice array of addresses. Each one is a contract with the function
    /// @notice to ask is the account is authorized to operate with this token
    address[] public authorizationContracts;

    event IssuerRightTransferred(address indexed _caller, address indexed _newIssuer);
    event GuardianRightTransferred(address indexed _caller, address indexed _newGuardian);
    event AgentAdded(address indexed _caller, address indexed _newAgent);
    event AgentRemoved(address indexed _caller, address indexed _agent);
    event AgentAuthorizationListTransferred(
        address indexed _caller,
        address indexed _oldAgent,
        address indexed _newAgent
    );
    event AddedToBlacklist(address indexed _account, address indexed _from);
    event RemovedFromBlacklist(address indexed _account, address indexed _from);
    event AddedToAuthorizationContracts(address indexed _contractAddress, address indexed _from);
    event RemovedFromAuthorizationContracts(address indexed _contractAddress, address indexed _from);

    /// @notice Check if sender has the DEFAULT_ADMIN_ROLE role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not ADMIN");
        _;
    }

    /// @notice Check if sender is the ISSUER
    modifier onlyIssuer() {
        require(_msgSender() == issuer, "Caller is not ISSUER");
        _;
    }

    /// @notice Check if sender is the GUARDIAN
    modifier onlyGuardian() {
        require(_msgSender() == guardian, "Caller is not GUARDIAN");
        _;
    }

    /// @notice Check if sender is an AGENT
    modifier onlyAgent() {
        require(agents[_msgSender()], "Caller is not AGENT");
        _;
    }

    /// @notice Check if sender is AGENT_or ISSUER
    modifier onlyIssuerOrAgent() {
        require(_msgSender() == issuer || agents[_msgSender()], "Caller is not AGENT nor ISSUER");
        _;
    }

    /// @notice Check if sender is GUARDIAN or ISSUER
    modifier onlyIssuerOrGuardian() {
        if (state == ContractState.active) {
            require(_msgSender() == issuer, "State Active: caller not Issuer");
        }

        if (state == ContractState.safeguard) {
            require(_msgSender() == guardian, "State Safeguard: caller not Guardian");
        }
        _;
    }

    /// @notice Check if the new account is not the same as the caller
    modifier isNotCaller(address _account) {
        require(_account != _msgSender(), "The Caller has the role already");
        _;
    }

    /// @notice Check if sender is AGENT or AUTHORIZED account
    modifier onlyIssuerOrAgentOrAuthorizedHolder() {
        if (state == ContractState.active) {
            require(agents[_msgSender()] || _msgSender() == issuer, "State Active: caller not Agent or Issuer");
        }

        if (state == ContractState.safeguard) {
            require(mustBeAuthorizedHolder(_msgSender()), "State Safeguard: Account not authorized");
        }
        _;

        // if (!agents[_msgSender()] && _msgSender() != issuer) {
        //     require(mustBeAuthorizedHolder(_msgSender()), "State Safeguard: Account not authorized");
        // }
        // _;
    }

    /* *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */

    /// @notice Returns true if `account` is a contract
    /// @param _contractAddress the address to be ckecked
    /// @return true if `account` is a contract
    function _isContract(address _contractAddress) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddress)
        }
        return size > 0;
    }

    /// @notice checks if the agent has a contract from the array list assigned
    /// @param _agent agent to check
    /// @return true if the agent has any contract assigned
    function _agentHasContractsAssigned(address _agent) internal view returns (bool) {
        for (uint256 i = 0; i < authorizationContracts.length; i++) {
            if (authorizationsPerAgent[authorizationContracts[i]] == _agent) {
                return true;
            }
        }
        return false;
    }

    /// @notice changes the owner of the contracts auth array
    /// @param _newAgent target agent to link the contracts to
    /// @param _oldAgent source agent to unlink the contracts from
    /// @return true if there was no error
    /// @return changed true if authorization ownership has occurred
    function _changeAuthorizationOwnership(address _newAgent, address _oldAgent) internal returns (bool, bool) {
        bool changed = false;
        for (uint256 i = 0; i < authorizationContracts.length; i++) {
            if (authorizationsPerAgent[authorizationContracts[i]] == _oldAgent) {
                authorizationsPerAgent[authorizationContracts[i]] = _newAgent;
                changed = true;
            }
        }
        return (true, changed);
    }

    /// @notice removes contract from auth array
    /// @param _contractAddress to be removed
    /// @return true if address was removed
    function _removeFromAuthorizationArray(address _contractAddress) internal returns (bool) {
        for (uint256 i = 0; i < authorizationContracts.length; i++) {
            if (authorizationContracts[i] == _contractAddress) {
                authorizationContracts[i] = authorizationContracts[authorizationContracts.length - 1];
                authorizationContracts.pop();
                return true;
            }
        }
        return false;
    }

    /// @notice checks if the user is authorized by the agent
    /// @param _account to be checked if its authorized
    /// @return true if _account is authorized
    function mustBeAuthorizedHolder(address _account) public view returns (bool) {
        require(authorizationContracts.length > 0, "No authorization contracts defined");
        require(!blacklist[_account], "_account is blacklisted");

        bool isAuthorized = false;
        IAuthorizationContracts authorizationList;
        for (uint256 i = 0; i < authorizationContracts.length; i++) {
            authorizationList = IAuthorizationContracts(authorizationContracts[i]);
            isAuthorized = authorizationList.isAccountAuthorized(_account);
            if (isAuthorized) {
                return true;
            }
        }
        return false;
    }

    /// @notice Grants DEFAULT_ADMIN_ROLE to set contract parameters.
    /// @param _account to be granted the admin role
    function grantAdminRole(address _account) external onlyAdmin isNotCaller(_account) {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice Changes the ISSUER
    /// @param _newIssuer to be assigned in the contract
    function transferIssuerRight(address _newIssuer) external onlyIssuer isNotCaller(_newIssuer) {
        emit IssuerRightTransferred(_msgSender(), _newIssuer);
        issuer = _newIssuer;
    }

    /// @notice Changes the GUARDIAN
    /// @param _newGuardian to be assigned in the contract
    function transferGuardianRight(address _newGuardian) external onlyGuardian isNotCaller(_newGuardian) {
        emit GuardianRightTransferred(_msgSender(), _newGuardian);
        guardian = _newGuardian;
    }

    /// @notice Adds an AGENT
    /// @param _newAgent to be added
    function addAgent(address _newAgent) external onlyIssuer {
        require(!agents[_newAgent], "Duplicated Agent");
        emit AgentAdded(_msgSender(), _newAgent);
        agents[_newAgent] = true;
    }

    /// @notice Deletes an AGENT
    /// @param _agent to be removed
    function removeAgent(address _agent) external onlyIssuer {
        require(agents[_agent], "_agent not found");

        bool hasContracts = _agentHasContractsAssigned(_agent);
        require(!hasContracts, "Agent has contracts assigned");

        emit AgentRemoved(_msgSender(), _agent);
        delete agents[_agent];
    }

    /// @notice Transfers the authorization contracts to a new Agent
    /// @param _newAgent to link the authorization list
    /// @param _oldAgent to unlink the authrization list
    function transferAgentList(address _newAgent, address _oldAgent) external onlyIssuerOrAgent {
        require(authorizationContracts.length > 0, "Empty list to transfer");
        require(_newAgent != _oldAgent, "_newAgent is the same as _oldAgent");
        require(agents[_oldAgent], "_oldAgent not found");

        if (_msgSender() != issuer) {
            require(_oldAgent == _msgSender(), "Agent can only transfer its own list");
        }
        require(agents[_newAgent], "_newAgent agent not found");

        bool executionOk = false;
        bool changed = false;
        (executionOk, changed) = _changeAuthorizationOwnership(_newAgent, _oldAgent);
        require(executionOk, "Error when updating contract list from agent");
        require(changed, "No contracts assigned to such agent");
        emit AgentAuthorizationListTransferred(_msgSender(), _oldAgent, _newAgent);
        // delete agents[_oldAgent];
    }

    /// @notice Adds an address to the authorization list
    /// @param _contractAddress the address to be added
    function addToAuthorizationList(address _contractAddress) external onlyAgent {
        require(_isContract(_contractAddress), "_contractAddress is not a Contract");
        require(
            authorizationsPerAgent[_contractAddress] == address(0),
            "_contractAddress belongs to an existing agent"
        );
        emit AddedToAuthorizationContracts(_contractAddress, _msgSender());
        authorizationContracts.push(_contractAddress);
        authorizationsPerAgent[_contractAddress] = _msgSender();
    }

    /// @notice Removes an address from the authorization list
    /// @param _contractAddress the address to be removed
    function removeFromAuthorizationList(address _contractAddress) external onlyAgent {
        require(_isContract(_contractAddress), "_contractAddress is not a Contract");
        require(authorizationsPerAgent[_contractAddress] != address(0), "_contractAddress is not on list");
        require(authorizationsPerAgent[_contractAddress] == _msgSender(), "_contract is not managed by the caller");

        emit RemovedFromAuthorizationContracts(_contractAddress, _msgSender());

        bool success = _removeFromAuthorizationArray(_contractAddress);
        require(success, "remove from authorization array failed");
        delete authorizationsPerAgent[_contractAddress];
    }

    /// @notice Gets the index from the array of authorization list
    /// @param _contractAddress the address to be searched
    /// @return the index in the array
    function getIndexFromAuthorizationList(address _contractAddress) external view returns (uint256) {
        for (uint256 i = 0; i < authorizationContracts.length; i++) {
            if (authorizationContracts[i] == _contractAddress) {
                return i;
            }
        }
        /// @dev returning this when address is not found
        return maxQtyOfAuthorizationLists + 1; 
    }

    /// @notice Adds an address to the blacklist
    /// @param _account the address to be blacklisted
    function addMemberToBlacklist(address _account) external onlyIssuer {
        require(!blacklist[_account], "_account already blacklisted");
        emit AddedToBlacklist(_account, _msgSender());
        blacklist[_account] = true;
    }

    /// @notice Removes an address from the blacklist
    /// @param _account the address to be removed from the blacklisted
    function removeMemberFromBlacklist(address _account) external onlyIssuer {
        require(blacklist[_account], "_account not blacklisted");
        emit RemovedFromBlacklist(_account, _msgSender());
        delete blacklist[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;


/// @author Diego Bale (https://www.linkedin.com/in/diegobale)
/// @title IAuthorizationContracts
/// @notice Provided interface to interact with any contract to provide 
/// @notice authorization to a given address
interface IAuthorizationContracts {
    function isAccountAuthorized(address _account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
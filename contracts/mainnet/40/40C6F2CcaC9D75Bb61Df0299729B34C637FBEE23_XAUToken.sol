// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IXAUToken.sol";
import "./IFeeApprover.sol";
import "./IXAUVault.sol";

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
contract XAUToken is IXAUToken, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address public override rebaser;

    uint256 internal _totalSupply;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;
    

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 internal xauScalingFactor;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    modifier onlyRebaser() {
        require(msg.sender == rebaser);
        _;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public initialSupply;
    uint256 public initialSupplyUnderlying;
    uint256 public contractStartTimestamp;


    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    constructor (
        string memory __name,
        string memory __symbol,
        uint256 __initialSupply
    ) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
        xauScalingFactor = BASE;
        initialSupply = __initialSupply;
        initialSupplyUnderlying = _toUnderlying(__initialSupply);
        _totalSupply = __initialSupply;
        _balances[address(msg.sender)] = initialSupplyUnderlying;
        contractStartTimestamp = block.timestamp;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
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
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    // function balanceOf(address account) public override returns (uint256) {
    //     return _balances[account];
    // }
    function balanceOf(address _owner) public override view returns (uint256) {
        return _fromUnderlying(_balances[_owner]);
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who)
      external
      override
      view
      returns (uint256)
    {
      return _balances[who];
    }

    /**
    * @notice Computes the current max scaling factor
    */
    function maxScalingFactor()
        external
        override
        view
        returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor()
        internal
        view
        returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initialSupplyUnderlying * xauScalingFactor
        // this is used to check if xauScalingFactor will be too high to compute balances when rebasing.
        return uint256(-1) / initialSupplyUnderlying;
    }

    function fromUnderlying(uint256 underlying)
        external
        override
        view
        returns (uint256)
    {
        return _fromUnderlying(underlying);
    }

    function toUnderlying(uint256 value)
        external
        override
        view
        returns (uint256)
    {
        return _toUnderlying(value);
    }

    function _fromUnderlying(uint256 underlying)
        internal
        view
        returns (uint256)
    {
        return underlying.mul(xauScalingFactor).div(internalDecimals);
    }

    function _toUnderlying(uint256 value)
        internal
        view
        returns (uint256)
    {
        return value.mul(internalDecimals).div(xauScalingFactor);
    }

    function scalingFactor() 
        external
        override
        view 
        returns (uint256) 
    {
        return xauScalingFactor;
    }

    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        override
        onlyRebaser
        returns (uint256)
    {
        // no change
        if (indexDelta == 0) {
          emit Rebase(epoch, xauScalingFactor, xauScalingFactor);
          return _totalSupply;
        }

        // for events
        uint256 oldScalingFactor = xauScalingFactor;

        if (!positive) {
            // negative rebase, decrease scaling factor
            xauScalingFactor = xauScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
            require(xauScalingFactor > 0);  // FIX: ensure that scaling factor won't drop down to zero as this would be unrecoverable
        } else {
            // positive reabse, increase scaling factor
            uint256 newScalingFactor = xauScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                xauScalingFactor = newScalingFactor;
            } else {
                xauScalingFactor = _maxScalingFactor();
            }
        }

        // update total supply, correctly
        _totalSupply = _fromUnderlying(initialSupplyUnderlying);

        emit Rebase(epoch, oldScalingFactor, xauScalingFactor);
        return _totalSupply;
    }

    /** @notice sets the rebaser
     * @param _rebaser The address of the rebaser contract to use for authentication.
     */
    function setRebaser(address _rebaser)
        external
        override
        onlyOwner
    {
        address oldRebaser = rebaser;
        rebaser = _rebaser;
        emit NewRebaser(oldRebaser, _rebaser);
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
        virtual
        override
        view
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
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
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    address public override transferHandler;

    function setTransferHandler(address _transferHandler)
        public
        override
        onlyOwner
    {
        address oldTransferHandler = transferHandler;
        transferHandler = _transferHandler;
        emit NewTransferHandler(oldTransferHandler, _transferHandler);        
    }

    address public override feeDistributor;

    function setFeeDistributor(address _feeDistributor)
        public
        override
        onlyOwner
    {
        address oldFeeDistributor = feeDistributor;
        feeDistributor = _feeDistributor;
        emit NewFeeDistributor(oldFeeDistributor, _feeDistributor);        
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
        
        // Divide by current scaling factor to get underlying balance
        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == xauScalingFactor / 1e24;

        // get amount in underlying
        uint256 underlying = _toUnderlying(amount);

        _balances[sender] = _balances[sender].sub(
            underlying,
            "ERC20: transfer amount exceeds balance"
        );
        
        (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) = IFeeApprover(transferHandler).calculateAmountsAfterFee(sender, recipient, underlying);

        // Addressing a broken checker contract
        require(transferToAmount.add(transferToFeeDistributorAmount) == underlying, "Math broke, does gravity still work?");

        _balances[recipient] = _balances[recipient].add(transferToAmount);
        emit Transfer(sender, recipient, _fromUnderlying(transferToAmount));

        
        if (transferToFeeDistributorAmount > 0 && feeDistributor != address(0)) {
            _balances[feeDistributor] = _balances[feeDistributor].add(transferToFeeDistributorAmount);
            emit Transfer(sender, feeDistributor, _fromUnderlying(transferToFeeDistributorAmount));
            if (feeDistributor != address(0)) {
                IXAUVault(feeDistributor).addPendingRewards(transferToFeeDistributorAmount);
            }
        }
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    // Gives governance ability to recover any ERC20 tokens mistakenly sent to this contract address.
    function recoverERC20(
        address token,
        address to,
        uint256 amount
    )
        external
        override
        onlyOwner
        returns (bool)
    {
        return IERC20(token).transfer(to, amount);
    }

}
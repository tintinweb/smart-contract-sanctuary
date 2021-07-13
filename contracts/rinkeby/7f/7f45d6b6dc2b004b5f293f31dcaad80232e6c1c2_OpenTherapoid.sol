// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @title UpdatedOpenTherapoid
/// @notice ERC-20 implementation of OpenTherapoid token
contract OpenTherapoid is ERC20, Ownable, Pausable {
    uint8 public tokenDecimals;
    address public admin;

    event LogBulkTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 activity
    );
    event LogUpdateDecimals(uint8 oldDecimal, uint8 newDecimal);
    event LogUpdateAdmin(address oldAdmin, address newAdmin);

    /**
     * @dev Modifier to make a function invocable by only the admin account
     */
    modifier onlyAdminOrOwner() {
        //solhint-disable-next-line reason-string
        require(
            (msg.sender == admin) || (msg.sender == owner()),
            "Caller is neither admin nor owner"
        );
        _;
    }

    /**
     * @dev Sets the values for {name = ScienceCoin}, {totalSupply = 5000000} and {symbol = NOBL}.
     *
     * All of these values except admin are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 fixedSupply, address _admin)
        ERC20("ScienceCoin", "NOBL")
    {
        require(_admin != address(0), "Admin cannot be address zero");
        admin = _admin;
        tokenDecimals = 18;
        super._mint(msg.sender, fixedSupply); // Since Total supply 50 Million NOBL
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev To update number of decimals for a token
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function updateDecimals(uint8 noOfDecimals)
        external
        onlyOwner
        whenNotPaused
    {
        uint8 oldDecimal = tokenDecimals;
        tokenDecimals = noOfDecimals;
        emit LogUpdateDecimals(oldDecimal, noOfDecimals);
    }

    /**
     * @dev To update admin address in the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function updateAdmin(address newAdmin) external onlyOwner whenNotPaused {
        address oldAdmin = admin;
        admin = newAdmin;
        emit LogUpdateAdmin(oldAdmin, newAdmin);
    }

    /**
     * @dev To issue tokens for their activities on the platform
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function issueToken(address recipient, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        super.transfer(recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function burn(address account, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        _burn(account, amount);
    }

    /**
     * @dev Moves tokens `amount` from `tokenOwner` to `recipients`.
     */
    function bulkTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[] memory activities
    ) external onlyOwner whenNotPaused {
        require(
            (recipients.length == amounts.length) &&
                (recipients.length == activities.length),
            "bulkTransfer: Unequal params"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            super.transfer(recipients[i], amounts[i]);
            emit LogBulkTransfer(
                msg.sender,
                recipients[i],
                amounts[i],
                activities[i]
            );
        }
    }

    /**
     * @dev To transfer all BNBs/ETHs stored in the contract to the caller
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawAll() external payable onlyOwner {
        //solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{
            gas: 2300,
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - invocation can be done, only by the contract owner & when the contract is not paused
     */
    function pause() external onlyAdminOrOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - invocation can be done, only by the contract owner & when the contract is paused
     */
    function unpause() external onlyAdminOrOwner whenPaused {
        _unpause();
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
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(recipient, amount);
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
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
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
    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }
}
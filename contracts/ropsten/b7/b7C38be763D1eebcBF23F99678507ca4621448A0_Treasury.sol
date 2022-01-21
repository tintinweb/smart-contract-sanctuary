/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

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

// File: contracts/Treasury/Token.sol


pragma solidity ^0.8.3;


contract Token is ERC20 {
    constructor() ERC20("TestToken", "TTKN") {}

    /**
     * @dev This function approves a transfer of _amount tokens from _from to _to
     * @param _from is the address the tokens will be transferred from
     * @param _to is the address the tokens will be transferred to
     * @param _amount is the number of tokens to transfer
     * @return bool true if spender approved successfully
     */
    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        _transfer(_from, _to, _amount);
        return true;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
// File: contracts/Treasury/TreasurySolo.sol


pragma solidity ^0.8.3;

// import "./interfaces/IController.sol";
// import "./TellorVars.sol";
// import "./interfaces/IGovernance.sol";


/**
 @author Tellor Inc.
 @title Treasury
 @dev This is the Treasury contract which defines the function for Tellor
 * treasuries, or staking pools.
*/
contract Treasury {
    // Storage
    Token public token;
    uint256 public totalLocked; // amount of TRB locked across all treasuries
    uint256 public treasuryCount; // number of total treasuries
    mapping(uint256 => TreasuryDetails) public treasury; // maps an ID to a treasury and its corresponding details
    mapping(address => uint256) treasuryFundsByUser; // maps a treasury investor to their total treasury funds, in TRB

    // Structs
    // Internal struct used to keep track of an individual user in a treasury
    struct TreasuryUser {
        uint256 amount; // the amount the user has placed in a treasury, in TRB
        uint256 startVoteCount; // the amount of votes that have been cast when a user deposits their money into a treasury
        bool paid; // determines if a user has paid/voted in Tellor governance proposals
    }
    // Internal struct used to keep track of a treasury and its pertinent attributes (amount, interest rate, etc.)
    struct TreasuryDetails {
        uint256 dateStarted; // the date that treasury was started
        uint256 maxAmount; // the maximum amount stored in the treasury, in TRB
        uint256 rate; // the interest rate of the treasury (5% == 500)
        uint256 purchasedAmount; // the amount of TRB purchased from the treasury
        uint256 duration; // the time during which the treasury locks participants
        uint256 endVoteCount; // the end vote count when the treasury duration is over
        bool endVoteCountRecorded; // determines whether the end vote count has been calculated or not
        address[] owners; // the owners of the treasury
        mapping(address => TreasuryUser) accounts; // a mapping of a treasury user address and corresponding details
    }

    // Events
    event TreasuryIssued(uint256 _id, uint256 _amount, uint256 _rate);
    event TreasuryPaid(address _investor, uint256 _amount);
    event TreasuryPurchased(address _investor, uint256 _amount);

    constructor(address _token) {
        token = Token(_token);
    }
    // Functions
    /**
     * @dev This is an external function that is used to deposit money into a treasury.
     * @param _id is the ID for a specific treasury instance
     * @param _amount is the amount to deposit into a treasury
     */
    function buyTreasury(uint256 _id, uint256 _amount) external {
        // Transfer sender funds to Treasury
        require(_amount > 0, "Amount must be greater than zero.");
        require(
            token.approveAndTransferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Insufficient balance. Try a lower amount."
        );

        treasuryFundsByUser[msg.sender] += _amount;
        // Check for sufficient treasury funds
        TreasuryDetails storage _treas = treasury[_id];
        require(
            _treas.dateStarted + _treas.duration > block.timestamp,
            "Treasury duration has expired."
        );
        require(
            _amount <= _treas.maxAmount - _treas.purchasedAmount,
            "Not enough money in treasury left to purchase."
        );
        // Update treasury details -- vote count, purchasedAmount, amount, and owners
        // address _governanceContract = IController(TELLOR_ADDRESS).addresses(
        //     _GOVERNANCE_CONTRACT
        // );
        if (_treas.accounts[msg.sender].amount == 0) {
            _treas.accounts[msg.sender].startVoteCount = 0;
            _treas.owners.push(msg.sender);
        }
        _treas.purchasedAmount += _amount;
        _treas.accounts[msg.sender].amount += _amount;
        totalLocked += _amount;
        emit TreasuryPurchased(msg.sender, _amount);
    }

    /**
     * @dev This is an external function that is used to issue a new treasury.
     * Note that only the governance contract can call this function.
     * @param _maxAmount is the amount of total TRB that treasury stores
     * @param _rate is the treasury's interest rate in BP
     * @param _duration is the amount of time the treasury locks participants
     */
    function issueTreasury(
        uint256 _maxAmount,
        uint256 _rate,
        uint256 _duration
    ) external {
        // require(
        //     msg.sender ==
        //         IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
        //     "Only governance contract is allowed to issue a treasury."
        // );
        require(
            _maxAmount > 0,
            "Invalid maxAmount value"
        );
        require(
            _duration > 0 && _duration <= 315360000,
            "Invalid duration value"
        );
        require(_rate > 0 && _rate <= 10000, "Invalid rate value");
        // Increment treasury count, and define new treasury and its details (start date, total amount, rate, etc.)
        treasuryCount++;
        TreasuryDetails storage _treas = treasury[treasuryCount];
        _treas.dateStarted = block.timestamp;
        _treas.maxAmount = _maxAmount;
        _treas.rate = _rate;
        _treas.duration = _duration;
        emit TreasuryIssued(treasuryCount, _maxAmount, _rate);
    }

    /**
     * @dev This functions allows an investor to pay the treasury. Internally, the function calculates the number of
     votes in governance contract when issued, and also transfers the amount individually locked + interest to the investor.
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     */
    function payTreasury(address _investor, uint256 _id) external {
        // Validate ID of treasury, duration for treasury has not passed, and the user has not paid
        TreasuryDetails storage _treas = treasury[_id];
        require(
            _id <= treasuryCount,
            "ID does not correspond to a valid treasury."
        );
        require(
            _treas.dateStarted + _treas.duration <= block.timestamp,
            "Treasury duration has not expired."
        );
        require(
            !_treas.accounts[_investor].paid,
            "Treasury investor has already been paid."
        );
        require(
            _treas.accounts[_investor].amount > 0,
            "Address is not a treasury investor"
        );
        // Calculate non-voting penalty (treasury holders have to vote)
        uint256 numVotesParticipated;
        uint256 votesSinceTreasury;
        // address governanceContract = IController(TELLOR_ADDRESS).addresses(
        //     _GOVERNANCE_CONTRACT
        // );
        // Find endVoteCount if not already calculated
        if (!_treas.endVoteCountRecorded) {
            uint256 voteCountIter = 0;
            // if (voteCountIter > 0) {
            //     (, uint256[8] memory voteInfo, , , , , ) = IGovernance(
            //         governanceContract
            //     ).getVoteInfo(voteCountIter);
            //     while (
            //         voteCountIter > 0 &&
            //         voteInfo[1] > _treas.dateStarted + _treas.duration
            //     ) {
            //         voteCountIter--;
            //         if (voteCountIter > 0) {
            //             (, voteInfo, , , , , ) = IGovernance(governanceContract)
            //                 .getVoteInfo(voteCountIter);
            //         }
            //     }
            // }
            _treas.endVoteCount = voteCountIter;
            _treas.endVoteCountRecorded = true;
        }
        // Add up number of votes _investor has participated in
        // if (_treas.endVoteCount > _treas.accounts[_investor].startVoteCount) {
        //     for (
        //         uint256 voteCount = _treas.accounts[_investor].startVoteCount;
        //         voteCount < _treas.endVoteCount;
        //         voteCount++
        //     ) {
        //         bool voted = IGovernance(governanceContract).didVote(
        //             voteCount + 1,
        //             _investor
        //         );
        //         if (voted) {
        //             numVotesParticipated++;
        //         }
        //         votesSinceTreasury++;
        //     }
        // }
        // Determine amount of TRB to mint for interest
        uint256 _mintAmount = (_treas.accounts[_investor].amount *
            _treas.rate) / 10000;
        if (votesSinceTreasury > 0) {
            _mintAmount =
                (_mintAmount * numVotesParticipated) /
                votesSinceTreasury;
        }
        if (_mintAmount > 0) {
            token.mint(address(this), _mintAmount);
        }
        // Transfer locked amount + interest amount, and indicate user has paid
        totalLocked -= _treas.accounts[_investor].amount;
        token.transfer(
            _investor,
            _mintAmount + _treas.accounts[_investor].amount
        );
        treasuryFundsByUser[_investor] -= _treas.accounts[_investor].amount;
        _treas.accounts[_investor].paid = true;
        emit TreasuryPaid(
            _investor,
            _mintAmount + _treas.accounts[_investor].amount
        );
    }

    // Getters
    /**
     * @dev This function returns the details of an account within a treasury.
     * Note: refer to 'TreasuryUser' struct.
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return uint256 of the amount of TRB the account has staked in the treasury
     * @return uint256 of the start vote count of when the account deposited money into the treasury
     * @return bool of whether the treasury account has paid or not
     */
    function getTreasuryAccount(uint256 _id, address _investor)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            treasury[_id].accounts[_investor].amount,
            treasury[_id].accounts[_investor].startVoteCount,
            treasury[_id].accounts[_investor].paid
        );
    }

    /**
     * @dev This function returns the number of treasuries/TellorX staking pools.
     * @return uint256 of the number of treasuries
     */
    function getTreasuryCount() external view returns (uint256) {
        return treasuryCount;
    }

    function getTreasuryDetails(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            treasury[_id].dateStarted,
            treasury[_id].maxAmount,
            treasury[_id].rate,
            treasury[_id].purchasedAmount
        );
    }

    /**
     * @dev This function returns the amount of TRB deposited by a user into treasuries.
     * @param _user is the specific account within a treasury to look up
     * @return uint256 of the amount of funds the user has, in TRB
     */
    function getTreasuryFundsByUser(address _user)
        external
        view
        returns (uint256)
    {
        return treasuryFundsByUser[_user];
    }

    /**
     * @dev This function returns the addresses of the owners of a treasury
     * @param _id is the ID of a specific treasury
     * @return address[] memory of the addresses of the owners of the treasury
     */
    function getTreasuryOwners(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        return treasury[_id].owners;
    }

    /**
     * @dev This function is used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }

    /**
     * @dev This function determines whether or not an investor in a treasury has paid/voted on Tellor governance proposals
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return bool of whether or not the investor was paid
     */
    function wasPaid(uint256 _id, address _investor)
        external
        view
        returns (bool)
    {
        return treasury[_id].accounts[_investor].paid;
    }
}
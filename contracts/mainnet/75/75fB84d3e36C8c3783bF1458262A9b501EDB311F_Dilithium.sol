// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Latinum.sol";
import "./Dilithium.sol";
import "./libraries/math/Math.sol";

/// Claim represents a bidder's claim to a bidding
/// period Latinum supply.
struct Claim {
    uint256 period;
    uint256 bid;
}

/// @dev Period represents an auction period
struct Period {
    uint256 endTime;
    uint256 ltnSupply;
    uint256 totalBids;
}

/// @author The MakeOS Team
/// @title The contract that provides the Latinum dutch auction functionality.
contract Auction is Latinum(address(0)) {
    // periods contain the auction periods
    Period[] public periods;

    // claims store all bidders Latinum claims
    mapping(address => Claim[]) public claims;

    // MAX_PERIODS is the maximum allowed periods
    uint256 public maxPeriods;

    // numPeriods keeps count of the number of periods
    uint256 public numPeriods;

    // ltnSupplyPerPeriod is the maximum amount of LTN distributed per auction.
    uint256 public ltnSupplyPerPeriod;

    // minBid is the minimum bid
    uint256 public minBid;

    // fee is the auction fee paid for each DIL in a bid.
    uint256 public fee;

    // fundingAddress is the address where contract fund can be transfered to.
    address public fundingAddress;

    // minReqDILSupply is the amount of DIL supply required to create the first period.
    uint256 public minReqDILSupply;

    event NewPeriod(uint256 index, uint256 endTime);
    event NewBid(address addr, uint256 amount, uint256 periodIndex);
    event NewClaim(address addr, uint256 amount, uint256 index);

    /// @dev isAuctionClosed is a modifier to check if the auction has closed.
    modifier isAuctionClosed() {
        require(
            periods.length < uint256(maxPeriods) ||
                periods[periods.length - 1].endTime > block.timestamp,
            "Auction has closed"
        );
        _;
    }

    /// @dev isBidAmountUnlocked is a modifier to check if a bidder has unlocked
    /// the bid amount
    modifier isBidAmountUnlocked(address bidder, uint256 bidAmt) {
        // Ensure the bidder has unlocked the bid amount
        uint256 allowance = dil.allowance(bidder, address(this));
        require(allowance >= bidAmt, "Amount not unlocked");
        _;
    }

    /// @notice The constructor
    /// @param _dilAddress is the address of the Dilithium contract.
    /// @param _minReqDILSupply is minimum number of DIL supply required to start a
    //  bid period.
    /// @param _maxPeriods is the number of auction periods.
    /// @param _ltnSupplyPerPeriod is the supply of Latinum per period.
    /// @param _minBid is minimum bid per period.
    /// @param _fee is the auction fee
    constructor(
        address _dilAddress,
        uint256 _minReqDILSupply,
        uint256 _maxPeriods,
        uint256 _ltnSupplyPerPeriod,
        uint256 _minBid,
        address _fundingAddress,
        uint256 _fee
    ) public {
        dil = Dilithium(_dilAddress);
        minBid = _minBid;
        maxPeriods = _maxPeriods;
        ltnSupplyPerPeriod = _ltnSupplyPerPeriod;
        minReqDILSupply = _minReqDILSupply;
        fundingAddress = _fundingAddress;
        fee = _fee;
    }

    receive() external payable {}

    fallback() external payable {}

    /// @dev setFee sets the auction fee.
    /// @param _fee is the new auction fee.
    function setFee(uint256 _fee) public isOwner() {
        fee = _fee;
    }

    /// @dev setFundingAddress sets the funding address
    /// @param addr is the address to change to.
    function setFundingAddress(address addr) public isOwner() {
        fundingAddress = addr;
    }

    /// @dev withdraw sends ETH to the funding address.
    /// @param amount is the amount to be withdrawn.
    function withdraw(uint256 amount) external {
        require(msg.sender == fundingAddress, "Not authorized");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// @notice makePeriod creates and returns a period. If the
    /// most recent period has not ended, it is returned instead
    /// of creating a new one.
    function makePeriod() public isAuctionClosed() returns (uint256) {
        require(
            periods.length > 0 || dil.totalSupply() >= minReqDILSupply,
            "Minimum Dilithium supply not reached"
        );

        Period memory period;
        uint256 index;

        // If no period, create one
        if (periods.length == 0) {
            period = Period(block.timestamp + 24 hours, ltnSupplyPerPeriod, 0);
            periods.push(period);
            index = periods.length - 1;
            numPeriods++;
            emit NewPeriod(index, period.endTime);
        }

        // Get the current period
        if (period.endTime == 0 && periods.length > 0) {
            period = periods[periods.length - 1];
            index = periods.length - 1;
        }

        // If period has ended, start a new one
        if (period.endTime <= block.timestamp) {
            period = Period(block.timestamp + 24 hours, ltnSupplyPerPeriod, 0);
            periods.push(period);
            index = periods.length - 1;
            numPeriods++;
            emit NewPeriod(index, period.endTime);
        }

        return index;
    }

    /// @dev updatePeriodTotalBids updates the total bid of a period.
    function updatePeriodTotalBids(uint256 idx, uint256 newBid) internal {
        periods[idx].totalBids = SM.add(periods[idx].totalBids, newBid);
    }

    /// @notice bid lets an account place a bid.
    /// @param bidAmt is the amount of the DIL to be placed as bid. This amount
    /// must have been unlocked in the DIL contract.
    function bid(uint256 bidAmt)
        public
        payable
        isAuctionClosed()
        isBidAmountUnlocked(msg.sender, bidAmt)
        returns (bool)
    {
        require(getNumOfClaims() + 1 <= 5, "Too many unprocessed claims");
        uint256 index = makePeriod();

        if (
            (index <= 6 && bidAmt < minBid) ||
            (index > 6 && bidAmt < minBid * 50)
        ) {
            revert("Bid amount too small");
        }

        if ((index <= 6 && bidAmt > minBid * 10)) {
            revert("Bid amount too high");
        }

        if (index > 6 && msg.value < (bidAmt / 1 ether) * fee) {
            revert("Auction fee too low");
        }

        // Burn the the bid amount
        dil.transferFrom(msg.sender, address(this), bidAmt);
        dil.burn(bidAmt);

        // Increase the period's bid count
        updatePeriodTotalBids(index, bidAmt);

        // Add a new claim
        claims[msg.sender].push(Claim(index, bidAmt));

        emit NewBid(msg.sender, bidAmt, index);

        return true;
    }

    /// @dev getNumOfPeriods returns the number of periods.
    function getNumOfPeriods() public view returns (uint256) {
        return periods.length;
    }

    /// @dev getNumOfClaims returns the number of claims the sender has.
    function getNumOfClaims() public view returns (uint256 n) {
        for (uint256 i = 0; i < claims[msg.sender].length; i++) {
            if (claims[msg.sender][i].bid > 0) {
                n++;
            }
        }
    }

    /// @dev getNumOfClaimsOfAddr returns the number of an address.
    function getNumOfClaimsOfAddr(address addr)
        public
        view
        returns (uint256 n)
    {
        for (uint256 i = 0; i < claims[addr].length; i++) {
            if (claims[addr][i].bid > 0) {
                n++;
            }
        }
    }

    /// @dev claim
    function claim() public {
        uint256 nClaims = claims[msg.sender].length;
        uint256 deleted = 0;
        for (uint256 i = 0; i < nClaims; i++) {
            Claim memory claim_ = claims[msg.sender][i];
            if (claim_.bid == 0) {
                deleted++;
                continue;
            }

            // Skip claim in current, unexpired period
            Period memory period = periods[claim_.period];
            if (period.endTime > block.timestamp) {
                continue;
            }

            // Delete claim
            delete claims[msg.sender][i];
            deleted++;

            // Get base point for the claim
            uint256 bps = SM.getBPSOfAInB(claim_.bid, period.totalBids);
            uint256 ltnReward = (period.ltnSupply * bps) / 10000;
            _mint(msg.sender, ltnReward);

            emit NewClaim(msg.sender, ltnReward, claim_.period);
        }

        if (deleted == nClaims) {
            delete claims[msg.sender];
        }
    }

    /// @dev transferUnallocated transfers unallocated Latinum supply to an
    /// account.
    /// @param to is the account to transfer to.
    /// @param amt is the amount to tranfer.
    function transferUnallocated(address to, uint256 amt) public isOwner() {
        require(
            periods.length == maxPeriods &&
                periods[periods.length - 1].endTime <= block.timestamp,
            "Auction must end"
        );

        uint256 remaining = SM.sub(maxSupply, totalSupply());
        require(remaining >= amt, "Insufficient remaining supply");
        _mint(to, amt);
    }

    /// @dev setMaxPeriods updates the number of auction periods.
    /// @param n is the new number of periods
    function setMaxPeriods(uint256 n) public isOwner() {
        maxPeriods = n;
    }

    /// @dev setMinReqDILTotalSupply updates the required min DIL supply.
    /// @param n is the new value
    function setMinReqDILTotalSupply(uint256 n) public isOwner() {
        minReqDILSupply = n;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Owner.sol";
import "./libraries/token/ERC20/ERC20.sol";
import "./Auction.sol";
import "./libraries/math/Math.sol";

/// @dev Dilithium ERC20 contract
contract Dilithium is ERC20("Dilithium", "DIL"), Owner {
    /// @dev mint allocates new DIL supply to an account.
    /// @param account is the beneficiary.
    /// @param amount is the number of DIL to issue.
    function mint(address account, uint256 amount) public isOwner() {
        _mint(account, amount);
    }

    /// @dev burn destroys the given amount of the sender's balance .
    /// @param amount is the number of DIL to destroy.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Owner.sol";
import "./Dilithium.sol";
import "./libraries/token/ERC20/ERC20.sol";

/// @dev Latinum ERC20 contract
contract Latinum is ERC20("Latinum", "LTN"), Owner {
    Dilithium public dil;

    // maxSupply is the initial maximum number of Latinum
    uint256 public maxSupply = 150000000000000000000000000;

    /// @dev constructor.
    /// @dev dilAddr is the Dilithium token contract.
    constructor(address dilAddr) public {
        dil = Dilithium(dilAddr);
    }

    /// @dev mint mints and allocates new Latinum to an account.
    /// @param account is the recipient account.
    /// @param amt is the amount of Latinum minted.
    function mint(address account, uint256 amt) public isOwner() {
        require(totalSupply() + amt <= maxSupply, "Cannot exceed max supply");
        _mint(account, amt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // isOwner checks whether the sender is the owner
    modifier isOwner() {
        require(owner == msg.sender, "Sender is not owner");
        _;
    }

    /// @dev setOwner sets the owner
    ///
    /// Requires the caller to be the current owner.
    ///
    /// @param owner_ is the new owner.
    function setOwner(address owner_) public isOwner() {
        owner = owner_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

library SM {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @dev getBPSOfAInB calculate the percentage of a in b and returns the
    /// base point of the percentage. 'a' is called up before use and scaled
    /// back down before base point calculation.
    function getBPSOfAInB(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 scale = 10**18;
        uint256 scaledA = mul(a, scale);
        uint256 x = mul(div(scaledA, b), 100);
        uint256 bps = div(mul(x, 100), scale);
        return bps;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "../../math/Math.sol";

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
contract ERC20 is IERC20 {
    using SM for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event BurnForMainnet(uint256 amount, bytes32 mainnetAddr);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
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
    function decimals() public view override returns (uint8) {
        return _decimals;
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev burnForMainnet burns all account balance and emits an event.
     * @param mainnetAddr is the MakeOS address that will be credited.
     */
    function burnForMainnet(bytes32 mainnetAddr) public {
        uint256 amt = balanceOf(_msgSender());
        _burn(_msgSender(), amt);
        emit BurnForMainnet(amt, mainnetAddr);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
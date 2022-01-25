pragma experimental ABIEncoderV2;
pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract ETHDubaiTicket {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIds;
    address payable public owner;

    uint256[90] public ticketOptions;
    Settings public settings;
    event Log(address indexed sender, string message);
    event Lint(uint256 indexed tokenId, string message);
    event LDiscount(address indexed sender, Discount discount, string message);
    event LMint(address indexed sender, MintInfo[] mintInfo, string message);
    enum Ticket {
        CONFERENCE,
        HOTEL_CONFERENCE,
        WORKSHOP1_AND_PRE_PARTY,
        WORKSHOP2_AND_PRE_PARTY,
        WORKSHOP3_AND_PRE_PARTY,
        HOTEL_WORKSHOP_AND_PRE_PARTY,
        HOTEL_WORKSHOP1_AND_PRE_PARTY,
        HOTEL_WORKSHOP2_AND_PRE_PARTY,
        HOTEL_WORKSHOP3_AND_PRE_PARTY,
        HOTEL2_WORKSHOP1_AND_PRE_PARTY,
        HOTEL2_WORKSHOP2_AND_PRE_PARTY,
        HOTEL2_WORKSHOP3_AND_PRE_PARTY,
        HOTEL2_CONFERENCE,
        WORKSHOP4_AND_PRE_PARTY,
        HOTEL_WORKSHOP4_AND_PRE_PARTY,
        HOTEL2_WORKSHOP4_AND_PRE_PARTY,
        HACKATHON_AND_CONFERENCE_ONLY,
        HOTEL_HACKATHON_AND_CONFERENCE_ONLY,
        HOTEL2_HACKATHON_AND_CONFERENCE_ONLY,
        HACKATHON_AND_PRE_PARTY,
        HOTEL_HACKATHON_AND_PRE_PARTY,
        HOTEL2_HACKATHON_AND_PRE_PARTY,
        WORKSHOP5_AND_PRE_PARTY,
        HOTEL_WORKSHOP5_AND_PRE_PARTY,
        HOTEL2_WORKSHOP5_AND_PRE_PARTY,
        WORKSHOP6_AND_PRE_PARTY,
        HOTEL_WORKSHOP6_AND_PRE_PARTY,
        HOTEL2_WORKSHOP6_AND_PRE_PARTY,
        WORKSHOP7_AND_PRE_PARTY,
        HOTEL_WORKSHOP7_AND_PRE_PARTY,
        HOTEL2_WORKSHOP7_AND_PRE_PARTY,
        WORKSHOP8_AND_PRE_PARTY,
        HOTEL_WORKSHOP8_AND_PRE_PARTY,
        HOTEL2_WORKSHOP8_AND_PRE_PARTY,
        WORKSHOP9_AND_PRE_PARTY,
        HOTEL_WORKSHOP9_AND_PRE_PARTY,
        HOTEL2_WORKSHOP9_AND_PRE_PARTY,
        WORKSHOP10_AND_PRE_PARTY,
        HOTEL_WORKSHOP10_AND_PRE_PARTY,
        HOTEL2_WORKSHOP10_AND_PRE_PARTY,
        WORKSHOP11_AND_PRE_PARTY,
        HOTEL_WORKSHOP11_AND_PRE_PARTY,
        HOTEL2_WORKSHOP11_AND_PRE_PARTY,
        WORKSHOP12_AND_PRE_PARTY,
        HOTEL_WORKSHOP12_AND_PRE_PARTY,
        HOTEL2_WORKSHOP12_AND_PRE_PARTY
    }
    EnumerableSet.AddressSet private daosAddresses;
    mapping(address => uint256) public daosQty;
    mapping(address => Counters.Counter) public daosUsed;
    mapping(address => uint256) public daosMinBalance;
    mapping(address => uint256) public daosDiscount;
    mapping(address => uint256) public daosMinTotal;
    mapping(address => Discount) public discounts;

    event LTicketSettings(
        TicketSettings indexed ticketSettings,
        string message
    );

    constructor() {
        emit Log(msg.sender, "created");
        owner = payable(msg.sender);
        settings.maxMint = 700;

        settings.ticketSettings = TicketSettings("early");

        ticketOptions[uint256(Ticket.CONFERENCE)] = 0.07 ether;
        ticketOptions[uint256(Ticket.HOTEL_CONFERENCE)] = 0.17 ether;
        ticketOptions[uint256(Ticket.WORKSHOP1_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP2_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP3_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.HOTEL_WORKSHOP_AND_PRE_PARTY)] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP1_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP2_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP3_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP1_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP2_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP3_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.HOTEL2_CONFERENCE)] = 0.3 ether;
        ticketOptions[uint256(Ticket.WORKSHOP4_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP4_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP4_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.10 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.3 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.4 ether;
        ticketOptions[uint256(Ticket.HACKATHON_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_HACKATHON_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_HACKATHON_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP5_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP5_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP5_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP6_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP6_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP6_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP7_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP7_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP7_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP8_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP8_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP8_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP9_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP9_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP9_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP10_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP10_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP10_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP11_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP11_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP11_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP12_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP12_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP12_AND_PRE_PARTY)
        ] = 0.5 ether;
    }

    struct Discount {
        uint256[] ticketOptions;
        uint256 amount;
    }

    struct TicketSettings {
        string name;
    }
    struct MintInfo {
        string ticketCode;
        uint256 ticketOption;
        string specialStatus;
    }
    struct Settings {
        TicketSettings ticketSettings;
        uint256 maxMint;
    }

    function setDiscount(
        address buyer,
        uint256[] memory newDiscounts,
        uint256 amount
    ) public returns (bool) {
        require(msg.sender == owner, "only owner");

        Discount memory d = Discount(newDiscounts, amount);
        emit LDiscount(buyer, d, "set discount buyer");
        discounts[buyer] = d;
        return true;
    }

    function setMaxMint(uint256 max) public returns (uint256) {
        require(msg.sender == owner, "only owner");
        settings.maxMint = max;
        emit Lint(max, "setMaxMint");
        return max;
    }

    function setTicketOptions(uint256 ticketOptionId, uint256 amount)
        public
        returns (bool)
    {
        require(msg.sender == owner, "only owner");
        ticketOptions[ticketOptionId] = amount;
        return true;
    }

    function setDao(
        address dao,
        uint256 qty,
        uint256 discount,
        uint256 minBalance,
        uint256 minTotal
    ) public returns (bool) {
        require(msg.sender == owner, "only owner");
        require(Address.isContract(dao), "nc");
        if (!daosAddresses.contains(dao)) {
            daosAddresses.add(dao);
        }
        daosQty[dao] = qty;
        daosMinBalance[dao] = minBalance;
        daosDiscount[dao] = discount;
        daosMinTotal[dao] = minTotal;
        return true;
    }

    function setTicketSettings(string memory name) public returns (bool) {
        require(msg.sender == owner, "only owner");
        settings.ticketSettings.name = name;
        emit LTicketSettings(settings.ticketSettings, "setTicketSettings");
        return true;
    }

    function cmpStr(string memory idopt, string memory opt)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((idopt))) ==
            keccak256(abi.encodePacked((opt))));
    }

    function getDiscount(address sender, uint256 ticketOption)
        public
        view
        returns (uint256[2] memory)
    {
        Discount memory discount = discounts[sender];
        uint256 amount = discounts[sender].amount;
        uint256 total = 0;
        bool hasDiscount = false;
        total = total + ticketOptions[ticketOption];

        if (amount > 0) {
            for (uint256 j = 0; j < discount.ticketOptions.length; j++) {
                if (discount.ticketOptions[j] == ticketOption) {
                    hasDiscount = true;
                }
            }
            if (!hasDiscount) {
                amount = 0;
            }
        }
        return [amount, total];
    }

    function getDaoDiscountView(uint256 amount)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256 minTotal = 0;
        if (amount == 0) {
            uint256 b = 0;

            for (uint256 j = 0; j < daosAddresses.length(); j++) {
                address dao = daosAddresses.at(j);
                if (daosDiscount[dao] > 0) {
                    ERC20 token = ERC20(dao);
                    b = token.balanceOf(msg.sender);
                    if (
                        b > daosMinBalance[dao] &&
                        daosUsed[dao].current() < daosQty[dao] &&
                        amount == 0
                    ) {
                        amount = daosDiscount[dao];
                        minTotal = daosMinTotal[dao];
                    }
                }
            }
        }
        return [amount, minTotal];
    }

    function getDaoDiscount(uint256 amount)
        internal
        returns (uint256[2] memory)
    {
        uint256 minTotal = 0;
        if (amount == 0) {
            uint256 b = 0;

            for (uint256 j = 0; j < daosAddresses.length(); j++) {
                address dao = daosAddresses.at(j);
                if (daosDiscount[dao] > 0) {
                    ERC20 token = ERC20(dao);
                    b = token.balanceOf(msg.sender);
                    if (
                        b > daosMinBalance[dao] &&
                        daosUsed[dao].current() < daosQty[dao] &&
                        amount == 0
                    ) {
                        amount = daosDiscount[dao];
                        daosUsed[dao].increment();
                        minTotal = daosMinTotal[dao];
                    }
                }
            }
        }
        return [amount, minTotal];
    }

    function getPrice(address sender, uint256 ticketOption)
        public
        returns (uint256)
    {
        uint256[2] memory amountAndTotal = getDiscount(sender, ticketOption);
        uint256 total = amountAndTotal[1];
        uint256[2] memory amountAndMinTotal = getDaoDiscount(amountAndTotal[0]);
        require(total > 0, "total = 0");
        if (amountAndMinTotal[0] > 0 && total >= amountAndMinTotal[1]) {
            total = total - ((total * amountAndMinTotal[0]) / 100);
        }

        return total;
    }

    function getPriceView(address sender, uint256 ticketOption)
        public
        view
        returns (uint256)
    {
        uint256[2] memory amountAndTotal = getDiscount(sender, ticketOption);
        uint256 total = amountAndTotal[1];
        uint256[2] memory amountAndMinTotal = getDaoDiscountView(
            amountAndTotal[0]
        );
        require(total > 0, "total = 0");
        if (amountAndMinTotal[0] > 0 && total >= amountAndMinTotal[1]) {
            total = total - ((total * amountAndMinTotal[0]) / 100);
        }

        return total;
    }

    function totalPrice(MintInfo[] memory mIs) public view returns (uint256) {
        uint256 t = 0;
        for (uint256 i = 0; i < mIs.length; i++) {
            t += getPriceView(msg.sender, mIs[i].ticketOption);
        }
        return t;
    }

    function totalPriceInternal(MintInfo[] memory mIs)
        internal
        returns (uint256)
    {
        uint256 t = 0;
        for (uint256 i = 0; i < mIs.length; i++) {
            t += getPrice(msg.sender, mIs[i].ticketOption);
        }
        return t;
    }

    function mintItem(MintInfo[] memory mintInfos)
        public
        payable
        returns (string memory)
    {
        require(
            _tokenIds.current() + mintInfos.length <= settings.maxMint,
            "sold out"
        );
        uint256 total = 0;

        string memory ids = "";
        for (uint256 i = 0; i < mintInfos.length; i++) {
            require(
                keccak256(abi.encodePacked(mintInfos[i].specialStatus)) ==
                    keccak256(abi.encodePacked("")) ||
                    msg.sender == owner,
                "only owner"
            );
            total += getPrice(msg.sender, mintInfos[i].ticketOption);
            _tokenIds.increment();
        }

        require(msg.value >= total, "price too low");
        //emit LMint(msg.sender, mintInfos, "minted");
        return ids;
    }

    function mintItemNoDiscount(MintInfo[] memory mintInfos)
        public
        payable
        returns (string memory)
    {
        require(
            _tokenIds.current() + mintInfos.length <= settings.maxMint,
            "sold out"
        );
        uint256 total = 0;

        string memory ids = "";
        for (uint256 i = 0; i < mintInfos.length; i++) {
            require(
                keccak256(abi.encodePacked(mintInfos[i].specialStatus)) ==
                    keccak256(abi.encodePacked("")) ||
                    msg.sender == owner,
                "only owner"
            );
            total += ticketOptions[mintInfos[i].ticketOption];
            _tokenIds.increment();
        }

        require(msg.value >= total, "price too low");
        //emit LMint(msg.sender, mintInfos, "minted");
        return ids;
    }

    function withdraw() public {
        uint256 amount = address(this).balance;

        (bool ok, ) = owner.call{value: amount}("");
        require(ok, "Failed");
        emit Lint(amount, "withdraw");
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Unlimited is ERC20 {
    constructor() ERC20("ETHDubaiDiscount", "EDD") {
        mintTokens();
    }

    function mintTokens() public {
        _mint(msg.sender, 100000000000000000000000);
    }
}
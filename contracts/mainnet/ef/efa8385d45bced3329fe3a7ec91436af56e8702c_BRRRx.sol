// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "console.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 */
contract BRRRx is Context, IERC20, AccessControl {
    bool public Online = true;
    modifier isOffline {
        require(!Online, "Contract is running still");
        _;
    }
    modifier isOnline {
        require(Online, "Contract has been turned off");
        _;
    }
    using SafeMath for uint256;
    using Address for address;
    IERC20 Tether;
    bytes32 public constant FOUNDING_FATHER = keccak256("FOUNDING_FATHER");

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) public _deposits_brrr;

    mapping(address => uint256) public weighted_avg;
    mapping(address => uint256) public _total_withdrawals;
    mapping(address => bool) public swapped;

    supplyCheck[] public _all_supply_checks;
    uint256 _leverage;
    uint256 public TreasuryReserve;
    uint256 private _totalSupply;
    uint256 public TOTALCAP = 80000000000 * 10**18;

    uint256 public _circulatingSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public tether = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public brrr;
    address public old_brrrx = 0xb70E8a16E58B4Ea4E714F1639Fd06bB79aD83A80;

    struct supplyCheck {
        uint256 _last_check;
        uint256 _totalSupply;
    }

    event Withdraw(address indexed _reciever, uint256 indexed _amount);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 leverage,
        address _brrr
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _leverage = leverage;
        brrr = _brrr;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FOUNDING_FATHER, msg.sender);
        Tether = IERC20(tether);
        _balances[msg.sender] = 100000000 * 10**18;
        _circulatingSupply = 100000000 * 10**18;
        uint256 d = Tether.totalSupply();
        TreasuryReserve = d * 10**13;
        _totalSupply = TreasuryReserve;
        supplyCheck memory sa = supplyCheck(block.timestamp, d);
        _all_supply_checks.push(sa);
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
    function totalSupply() public override view returns (uint256) {
        return _circulatingSupply.add(TreasuryReserve);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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

        if (msg.sender != brrr) {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens from tether burning tokens
     *
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function _printerGoesBrrr(uint256 amount) internal returns (bool) {
        require(amount > 0, "Can't mint 0 tokens");
        require(TreasuryReserve.add(amount) < cap(), "Cannot exceed cap");
        TreasuryReserve = TreasuryReserve.add(amount);
        _totalSupply = TreasuryReserve;
        emit Transfer(address(0), address(this), amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual isOnline {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount <= TreasuryReserve, "More than the reserve holds");

        _circulatingSupply = _circulatingSupply.add(amount);
        _totalSupply = _totalSupply.sub(amount);
        TreasuryReserve = TreasuryReserve.sub(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `TreasuryReserve`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `Treasury Reserve` must have at least `amount` tokens.
     */
    function _burn(uint256 amount) internal virtual {
        if (amount <= TreasuryReserve) {
            TreasuryReserve = TreasuryReserve.sub(
                amount,
                "ERC20: burn amount exceeds Treasury Reserve"
            );
            _totalSupply = TreasuryReserve;
            emit Transfer(address(this), address(0), amount);
        } else {
            TreasuryReserve = 1 * 10**18;
            _totalSupply = TreasuryReserve;
            emit Transfer(address(this), address(0), amount);
        }
    }

    function _payBackBrrr(
        uint256 _brrrAmount,
        address payable _owner,
        uint256 _returnAmount
    ) internal returns (bool) {
        require(
            _deposits_brrr[_owner] >= _returnAmount,
            "More than deposit amount"
        );
        _balances[_owner] = _balances[_owner].sub(_brrrAmount);
        TreasuryReserve = TreasuryReserve.add(_brrrAmount);
        _totalSupply = TreasuryReserve;
        _circulatingSupply = _circulatingSupply.sub(_brrrAmount);
        emit Transfer(address(_owner), address(this), _brrrAmount);
        _deposits_brrr[_owner] = _deposits_brrr[_owner].sub(_returnAmount);
        _transferCoin(_owner, brrr, _returnAmount);
        emit Withdraw(address(_owner), _returnAmount);
        return true;
    }

    /**
     * @dev Gives user reward for updating the total supply.
     */
    function _giveReward(uint256 reward) internal returns (bool) {
        _circulatingSupply = _circulatingSupply.add(reward);
        _balances[_msgSender()] = _balances[_msgSender()].add(reward);
        emit Transfer(address(this), address(_msgSender()), reward);
        return true;
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

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return TOTALCAP;
    }

    function swapOldBRRR() external isOnline returns (bool) {
        require(swapped[_msgSender()] == false, "You already swapped!");
        IERC20 erc;
        erc = IERC20(old_brrrx);
        uint256 bal = erc.balanceOf(_msgSender());
        require(bal >= 0, "Not enough funds to transfer");
        swapped[_msgSender()] = true;
        require(erc.transferFrom(_msgSender(), address(this), bal));
        _mint(_msgSender(), bal);
        return true;
    }

    function calculateWithdrawalPrice() public view returns (uint256) {
        uint256 p = calculateCurve();
        uint256 w = _total_withdrawals[_msgSender()];
        if (w < 1) {
            return p;
        }
        if (w >= 99) {
            w = 99;
        }
        p = p.sub(p.mul(w).div(100));
        return p;
    }

    function _transferEth(address payable _recipient, uint256 _amount)
        internal
        returns (bool)
    {
        _recipient.transfer(_amount);
        return true;
    }

    function _transferCoin(
        address _owner,
        address _contract,
        uint256 _returnAmount
    ) internal returns (bool) {
        IERC20 erc;
        erc = IERC20(_contract);
        require(
            erc.balanceOf(address(this)) >= _returnAmount,
            "Not enough funds to transfer"
        );
        require(erc.transfer(_owner, _returnAmount));
        return true;
    }

    /**  Bonding curve
     * circulating * reserve ratio / total supply
     * circulating * .50 / totalSupply
     *
     * */
    function calculateCurve() public override view returns (uint256) {
        if (TreasuryReserve <= 1 * 10**18) {
            return (_circulatingSupply.mul(50).div(100));
        }
        return (
            (_circulatingSupply.mul(50).div(100) * 10**18).div(TreasuryReserve)
        );
    }

    function printWithBrrr(uint256 _amount) public isOnline returns (bool) {
        console.log("Printing BRRR with brrr, amount sent is: ", _amount);
        require(brrr != address(0x0), "Brrr contract not set");
        IERC20 brr;
        brr = IERC20(brrr);
        uint256 al = brr.balanceOf(_msgSender());
        require(al >= _amount, "Token balance not enough");
        uint256 p = calculateCurve();
        console.log("current bonding price for 10x is: ", p);
        uint256 tp = brr.calculateCurve();
        console.log("current bonding price for BRRR is: ", tp);
        if (weighted_avg[_msgSender()] == 0) {
            weighted_avg[_msgSender()] = tp;
        } else {
            uint256 temp = _deposits_brrr[_msgSender()]
                .mul(weighted_avg[_msgSender()])
                .add(_amount.mul(tp));
            temp = temp.div(_deposits_brrr[_msgSender()].add(_amount));
            console.log("new weighted avg is: ", temp);
            weighted_avg[_msgSender()] = temp;
        }
        uint256 a = _amount.mul(tp).div(p);
        console.log("amount of BRRR10x made: ", a);
        require(a > 0, "Not enough sent for 1 brrr");
        require(
            brr.transferFrom(_msgSender(), address(this), _amount),
            "Transfer failed"
        );
        _deposits_brrr[_msgSender()] = _deposits_brrr[_msgSender()].add(
            _amount
        );
        _mint(_msgSender(), a);
        return true;
    }

    function returnBrrrForBrrr() public isOnline returns (bool) {
        console.log("returning deposit for user");
        require(brrr != address(0x0), "Brrr contract not set");
        require(_deposits_brrr[_msgSender()] != 0, "You have no deposits");
        require(_balances[_msgSender()] > 0, "No brrr balance");
        uint256 o = calculateWithdrawalPrice();
        console.log("Current withdrawal bonding curve for 10x: ", o);
        uint256 y = weighted_avg[_msgSender()];
        console.log("Bonding curve price for BRRR: ", y);
        uint256 rg = _deposits_brrr[_msgSender()].mul(y).div(o);
        console.log(
            "BRRR x BRRRCurve divided by Withdrawal curve (amount of deposit to get back) is: ",
            rg
        );
        console.log("current balance is: ", _balances[_msgSender()]);
        if (_balances[_msgSender()] >= rg) {
            weighted_avg[_msgSender()] = 0;
            _payBackBrrr(rg, _msgSender(), _deposits_brrr[_msgSender()]);
        } else {
            console.log(
                "balances are not enough, current amount they have is able to get: "
            );
            console.log("balance: ", _balances[_msgSender()]);
            uint256 a = _balances[_msgSender()].mul(o).div(10**18);
            console.log("eth value in current BRRR10x: ", a);
            uint256 t = a.mul(10**18).div(y);
            console.log("BRRR divided by ETH value to give back the BRRR: ", t);
            require(
                t <= _deposits_brrr[_msgSender()],
                "More than in your balance, error with math"
            );
            _payBackBrrr(_balances[_msgSender()], _msgSender(), t);
        }
        _total_withdrawals[_msgSender()] = _total_withdrawals[_msgSender()].add(
            1
        );
    }

    /**@dev Update the total supply from tether - if tether has changed total supply.
     *
     * Makes the money printer go brrrrrrrr
     * Reward is given to whoever updates
     * */
    function brrrEvent() public isOnline returns (uint256) {
        require(
            block.timestamp >
                _all_supply_checks[_all_supply_checks.length.sub(1)]
                    ._last_check,
            "Already checked!"
        );
        uint256 l = _all_supply_checks[_all_supply_checks.length.sub(1)]
            ._last_check;
        uint256 s = _all_supply_checks[_all_supply_checks.length.sub(1)]
            ._totalSupply;
        uint256 d = Tether.totalSupply();
        require(d != s, "The supply hasn't changed");
        supplyCheck memory sa = supplyCheck(block.timestamp, d);
        _all_supply_checks.push(sa);
        d = d * 10**12;
        s = s * 10**12;
        console.log("new tether supply: ", d);
        console.log("old tether supply: ", s);
        uint256 newTreasury = (TreasuryReserve.mul((s.mul(2)).sub(d))).div(s);
        console.log("new value from formula is: ", newTreasury);

        if (d < s) {
            newTreasury = newTreasury.sub(TreasuryReserve);
            uint256 reward = newTreasury.div(1000);
            console.log("reward: ", reward);
            newTreasury = newTreasury.sub(reward);
            console.log("Final amount going to be burnt: ", newTreasury);
            _printerGoesBrrr(newTreasury.mul(_leverage));
            _giveReward(reward);
            return reward;
        }
        if (d > s) {
            //d = (d.sub(s)) * 10**12;
            newTreasury = TreasuryReserve.sub(newTreasury);
            uint256 reward = newTreasury.div(1000);
            console.log("reward: ", reward);
            newTreasury = newTreasury.sub(reward);
            console.log("Final amount going to be burnt: ", newTreasury);
            _burn(newTreasury.mul(_leverage));
            _giveReward(reward);
            return reward;
        }
    }

    function EmergencyWithdrawal() public isOffline returns (bool) {
        require(!Online, "Contract is not turned off");
        require(_deposits_brrr[_msgSender()] > 0, "You have no deposits");
        _payBackBrrr(0, _msgSender(), _deposits_brrr[_msgSender()]);
        return true;
    }

    function toggleOffline() public returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        Online = !Online;
        return true;
    }

    function setSwapAddress(address _brrr_old) public returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );

        require(_brrr_old != address(0x0), "Invalid address!");
        old_brrrx = _brrr_old;
    }

    fallback() external payable {
        revert();
    }
}

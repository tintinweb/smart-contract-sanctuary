// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./PriceFeed.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 */
contract Brrr is Context, IERC20, AccessControl, PriceFeed {
    bool public Online = true;
    modifier isOffline {
        _;
        require(!Online, "Contract is running still");
    }
    modifier isOnline {
        _;
        require(Online, "Contract has been turned off");
    }
    using SafeMath for uint256;
    using Address for address;
    IERC20 Tether;
    bytes32 public constant FOUNDING_FATHER = keccak256("FOUNDING_FATHER");

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    //list of accepted coins for transferring
    mapping(address => bool) public _acceptedStableCoins;
    //address of the oracle price feed for accept coins
    mapping(address => address) private _contract_address_to_oracle;
    //deposits for each user in eth
    mapping(address => uint256) public _deposits_eth;
    //total withdrawals per user
    mapping(address => uint256) public _total_withdrawals;
    //deposits for each user in their coins
    mapping(address => mapping(address => uint256)) public _coin_deposits;
    //claimed stimulus per user per stimulus
    mapping(address => mapping(uint128 => bool)) public _claimed_stimulus;
    //all stimulus ids
    mapping(uint128 => bool) public _all_Claim_ids;
    //stimulus id to stimulus info
    mapping(uint128 => Claims) public _all_Claims;
    //tether total supply checks/history
    supplyCheck[] public _all_supply_checks;
    //total coins related to tether in reserves
    uint256 public TreasuryReserve;
    uint256 private _totalSupply;
    //max limit
    uint256 public TOTALCAP = 8000000000000000 * 10**18;
    //total coins in circulation
    uint256 public _circulatingSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    //usdt address
    address public tether = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    //brrr3x address
    address public brrr3x;
    //brrr10x address
    address public brrr10x;

    struct Claims {
        uint256 _amount;
        uint256 _ending;
        uint256 _amount_to_give;
    }

    struct supplyCheck {
        uint256 _last_check;
        uint256 _totalSupply;
    }

    event Withdraw(address indexed _reciever, uint256 indexed _amount);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * Sets the total supply from tether
     *
     * Gives founding father liquidity share for uniswap
     *
     * Sets first supply check
     *
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FOUNDING_FATHER, msg.sender);
        Tether = IERC20(tether);
        uint256 d = Tether.totalSupply();
        TreasuryReserve = d * 10**13;
        _balances[msg.sender] = 210000000 * 10**18;
        _circulatingSupply = 210000000 * 10**18;
        _totalSupply = TreasuryReserve.sub(_circulatingSupply);
        TreasuryReserve = TreasuryReserve.sub(_circulatingSupply);
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
     *  If address is approved brrr3x or brrr10x address don't check allowance and allow 1 transaction transfer (no approval needed)
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if (msg.sender != brrr3x && msg.sender != brrr10x) {
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
     * Cannot go past cap.
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
        TreasuryReserve = TreasuryReserve.sub(amount);
        _totalSupply = TreasuryReserve;
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
            TreasuryReserve = 0;
            _totalSupply = TreasuryReserve;
            emit Transfer(address(this), address(0), amount);
        }
    }

    /**
     * @dev Returns the users deposit in ETH and changes the circulating supply and treasury reserves based off the brrr sent back
     *
     *
     * Emits withdraw event.
     *
     *
     */
    function _payBackBrrrETH(
        uint256 _brrrAmount,
        address payable _owner,
        uint256 _returnAmount
    ) internal returns (bool) {
        require(
            _deposits_eth[_owner] >= _returnAmount,
            "More than deposit amount"
        );
        _balances[_owner] = _balances[_owner].sub(_brrrAmount);
        TreasuryReserve = TreasuryReserve.add(_brrrAmount);
        _totalSupply = TreasuryReserve;
        _circulatingSupply = _circulatingSupply.sub(_brrrAmount);
        emit Transfer(address(_owner), address(this), _brrrAmount);
        _deposits_eth[_owner] = _deposits_eth[_owner].sub(_returnAmount);
        _transferEth(_owner, _returnAmount);
        emit Withdraw(address(_owner), _returnAmount);
        return true;
    }

    /**
     * @dev Returns the users deposit in alt coins and changes the circulating supply and treasury reserves based off the brrr sent back
     *
     *
     * Emits withdraw event.
     *
     *
     */
    function _payBackBrrrCoins(
        uint256 _brrrAmount,
        address payable _owner,
        address _contract,
        uint256 _returnAmount
    ) internal returns (bool) {
        require(
            _coin_deposits[_owner][_contract] >= _returnAmount,
            "More than deposit amount"
        );
        _balances[_owner] = _balances[_owner].sub(_brrrAmount);
        TreasuryReserve = TreasuryReserve.add(_brrrAmount);
        _totalSupply = TreasuryReserve;
        _circulatingSupply = _circulatingSupply.sub(_brrrAmount);
        emit Transfer(address(_owner), address(this), _brrrAmount);
        _coin_deposits[_owner][_contract] = _coin_deposits[_owner][_contract]
            .sub(_returnAmount);
        _transferCoin(_owner, _contract, _returnAmount);
        emit Withdraw(address(_owner), _returnAmount);
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
     * @dev Gives user reward for updating the total supply.
     */
    function _giveReward(uint256 reward) internal returns (bool) {
        _circulatingSupply = _circulatingSupply.add(reward);
        _balances[_msgSender()] = _balances[_msgSender()].add(reward);
        emit Transfer(address(this), address(_msgSender()), reward);
        return true;
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

    /**
     * @dev Returns the price of the bonding curve divided by number of withdrawals the user has already made.
     *
     * Prevents spamming deposit -> withdrawal -> deposit... to drain all brrr.
     */
    function calculateWithdrawalPrice() internal view returns (uint256) {
        uint256 p = calculateCurve();
        uint256 w = _total_withdrawals[_msgSender()];
        if (w < 1) {
            w = 1;
        }
        p = p.div(w);
        return p;
    }

    /**
     * @dev Internal transfer eth function
     *
     */
    function _transferEth(address payable _recipient, uint256 _amount)
        internal
        returns (bool)
    {
        _recipient.transfer(_amount);
        return true;
    }

    /**
     * @dev Internal transfer altcoin function
     *
     */
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

    /**@dev Adds another token to the accepted coins for printing
     *
     *
     * Calling conditions:
     *
     * - Address of the contract to be added
     * - Only can be added by founding fathers
     * */
    function addAcceptedStableCoin(address _contract, address _oracleAddress)
        public
        isOnline
        returns (bool)
    {
        require(
            hasRole(FOUNDING_FATHER, msg.sender),
            "Caller is not a Founding Father"
        );
        _acceptedStableCoins[_contract] = true;
        _contract_address_to_oracle[_contract] = _oracleAddress;
        return _acceptedStableCoins[_contract];
    }

    /**@dev Adds stimulus package to be claimed by users
     *
     *
     * Calling conditions:
     * - Only can be added by founding fathers
     * */
    function addStimulus(
        uint128 _id,
        uint256 _total_amount,
        uint256 _ending_in_days,
        uint256 _amount_to_get
    ) public isOnline returns (bool) {
        require(
            hasRole(FOUNDING_FATHER, msg.sender),
            "Caller is not a Founding Father"
        );
        require(_all_Claim_ids[_id] == false, "ID already used");
        require(_total_amount <= TreasuryReserve);
        _all_Claim_ids[_id] = true;
        _all_Claims[_id]._amount = _total_amount * 10**18;
        _all_Claims[_id]._amount_to_give = _amount_to_get;
        _all_Claims[_id]._ending = block.timestamp + (_ending_in_days * 1 days);
        return true;
    }

    /**@dev Claim a stimulus package.
     *
     * requires _id of stimulus package.
     * Calling conditions:
     * - can only claim once
     * - must not be ended
     * - must not be out of funds.
     * */
    function claimStimulus(uint128 _id) public isOnline returns (bool) {
        require(_all_Claim_ids[_id], "Claim not valid");
        require(
            _claimed_stimulus[_msgSender()][_id] == false,
            "Already claimed!"
        );
        require(
            block.timestamp <= _all_Claims[_id]._ending,
            "Stimulus package has ended"
        );
        require(
            _all_Claims[_id]._amount >= _all_Claims[_id]._amount_to_give,
            "Out of money :("
        );
        _claimed_stimulus[_msgSender()][_id] = true;
        _all_Claims[_id]._amount = _all_Claims[_id]._amount.sub(
            _all_Claims[_id]._amount_to_give * 10**18
        );
        _mint(_msgSender(), _all_Claims[_id]._amount_to_give * 10**18);
        return true;
    }

    /**  Bonding curve
     * circulating * reserve ratio / total supply
     * circulating * .10 / totalSupply
     *
     * */
    function calculateCurve() public override view returns (uint256) {
        uint256 p = (
            (_circulatingSupply.mul(10).div(100) * 10**18).div(TreasuryReserve)
        );
        if (p <= 0) {
            p = 1;
        }
        return p;
    }

    /**@dev Deposit eth and get the value of brrr based off bonding curve
     *
     *
     * */
    function printWithETH() public payable isOnline returns (bool) {
        require(
            msg.value > 0,
            "Please send money to make the printer go brrrrrrrr"
        );
        uint256 p = calculateCurve();
        uint256 amount = (msg.value.mul(10**18).div(p));
        require(amount > 0, "Not enough sent for 1 brrr");
        _deposits_eth[_msgSender()] = _deposits_eth[_msgSender()].add(
            msg.value
        );
        _mint(_msgSender(), amount);
        return true;
    }

    /**@dev Deposit alt coins and get the value of brrr based off bonding curve
     *
     *
     * */
    function printWithStablecoin(address _contract, uint256 _amount)
        public
        isOnline
        returns (bool)
    {
        require(
            _acceptedStableCoins[_contract],
            "Not accepted as a form of payment"
        );
        IERC20 erc;
        erc = IERC20(_contract);
        uint256 al = erc.allowance(_msgSender(), address(this));
        require(al >= _amount, "Token allowance not enough");
        uint256 p = calculateCurve();
        uint256 tp = getLatestPrice(_contract_address_to_oracle[_contract]);
        uint256 a = _amount.mul(tp).div(p);
        require(a > 0, "Not enough sent for 1 brrr");
        require(
            erc.transferFrom(_msgSender(), address(this), _amount),
            "Transfer failed"
        );
        _coin_deposits[_msgSender()][_contract] = _coin_deposits[_msgSender()][_contract]
            .add(_amount);
        _mint(_msgSender(), a);
        return true;
    }

    /**@dev Internal transfer from brrr3x or brrr10x in order to transfer and update balances
     *
     *
     * */
    function _transferBrr(address _contract) internal returns (bool) {
        IERC20 brr;
        brr = IERC20(_contract);
        uint256 brrbalance = brr.balanceOf(_msgSender());
        if (brrbalance > 0) {
            require(
                brr.transferFrom(_msgSender(), address(this), brrbalance),
                "Transfer failed"
            );
            _mint(_msgSender(), brrbalance);
        }
        return true;
    }

    /**@dev Transfers entire brrrX balance into brrr at 1 to 1
     *  Deposits on brrrX will not be cleared.
     *
     * */
    function convertBrrrXintoBrrr() public isOnline returns (bool) {
        _transferBrr(address(brrr3x));
        _transferBrr(address(brrr10x));
        return true;
    }

    /**@dev Deposit brrr and get the value of eth for that amount of brrr based off bonding curve
     *
     *
     * */
    function returnBrrrForETH() public isOnline returns (bool) {
        require(_deposits_eth[_msgSender()] > 0, "You have no deposits");
        require(_balances[_msgSender()] > 0, "No brrr balance");
        uint256 p = calculateWithdrawalPrice();
        uint256 r = _deposits_eth[_msgSender()].div(p).mul(10**18);
        if (_balances[_msgSender()] >= r) {
            _payBackBrrrETH(r, _msgSender(), _deposits_eth[_msgSender()]);
        } else {
            uint256 t = _balances[_msgSender()].mul(p).div(10**18);
            require(
                t <= _balances[_msgSender()],
                "More than in your balance, error with math"
            );
            _payBackBrrrETH(_balances[_msgSender()], _msgSender(), t);
        }
        _total_withdrawals[_msgSender()] = _total_withdrawals[_msgSender()].add(
            1
        );
    }

    /**@dev Deposit brrr and get the value of alt coins for that amount of brrr based off bonding curve
     *
     *
     * */
    function returnBrrrForCoins(address _contract)
        public
        isOnline
        returns (bool)
    {
        require(
            _acceptedStableCoins[_contract],
            "Not accepted as a form of payment"
        );
        require(
            _coin_deposits[_msgSender()][_contract] != 0,
            "You have no deposits"
        );
        require(_balances[_msgSender()] > 0, "No brrr balance");
        uint256 o = calculateWithdrawalPrice();
        uint256 rg = getLatestPrice(_contract_address_to_oracle[_contract]);
        uint256 y = _coin_deposits[_msgSender()][_contract].mul(rg).div(o);
        if (_balances[_msgSender()] >= y) {
            _payBackBrrrCoins(
                y,
                _msgSender(),
                _contract,
                _coin_deposits[_msgSender()][_contract]
            );
        } else {
            uint256 t = _balances[_msgSender()].mul(o).div(rg).div(10**18);
            require(
                t <= _balances[_msgSender()],
                "More than in your balance, error with math"
            );
            _payBackBrrrCoins(
                _balances[_msgSender()],
                _msgSender(),
                _contract,
                t
            );
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
        if (d < s) {
            supplyCheck memory sa = supplyCheck(block.timestamp, d);
            _all_supply_checks.push(sa);
            d = (s.sub(d)) * 10**12;
            uint256 reward = d.div(1000);
            d = d.sub(reward);
            _printerGoesBrrr(d);
            _giveReward(reward);
            return reward;
        }
        if (d > s) {
            supplyCheck memory sa = supplyCheck(block.timestamp, d);
            _all_supply_checks.push(sa);
            d = (d.sub(s)) * 10**12;
            uint256 reward = d.div(1000);
            d = d.sub(reward);
            _burn(d);
            _giveReward(reward);
            return reward;
        }
    }

    /**@dev In case of emgergency - withdrawal all eth.
     *
     * Contract must be offline
     *
     * */
    function EmergencyWithdrawalETH() public isOffline returns (bool) {
        require(!Online, "Contract is not turned off");
        require(_deposits_eth[_msgSender()] > 0, "You have no deposits");
        _payBackBrrrETH(
            _balances[_msgSender()],
            _msgSender(),
            _deposits_eth[_msgSender()]
        );
        return true;
    }

    /**@dev In case of emgergency - withdrawal all coins.
     *
     * Contract must be offline
     *
     * */
    function EmergencyWithdrawalCoins(address _contract)
        public
        isOffline
        returns (bool)
    {
        require(!Online, "Contract is not turned off");
        require(
            _acceptedStableCoins[_contract],
            "Not accepted as a form of payment"
        );
        require(
            _coin_deposits[_msgSender()][_contract] != 0,
            "You have no deposits"
        );
        _payBackBrrrCoins(
            _balances[_msgSender()],
            _msgSender(),
            _contract,
            _coin_deposits[_msgSender()][_contract]
        );
        return true;
    }

    /**@dev In case of emgergency - turn offline.
     *
     * Must be admin
     *
     * */
    function toggleOffline() public returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        Online = !Online;
        return true;
    }

    /**@dev Set brrrX addresses. One time, cannot be changed.
     *
     * Must be admin
     *
     * */
    function setBrrrXAddress(address _brrr3xcontract, address _brrr10xcontract)
        public
        returns (bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        require(
            brrr3x == address(0x0) && brrr10x == address(0x0),
            "Already set the addresses"
        );
        if (_brrr3xcontract != address(0x0)) {
            brrr3x = _brrr3xcontract;
        }
        if (_brrr10xcontract != address(0x0)) {
            brrr10x = _brrr10xcontract;
        }
    }

    fallback() external payable {
        printWithETH();
    }
}

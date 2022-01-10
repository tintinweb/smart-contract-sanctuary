// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

contract KusoCoin is Context, IBEP20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    // fees can never be increased!
    uint256 private _marketingFee = 10;
    address private _marketingAddress;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private _feeDiscountBuy = 0;
    uint256 private _feeDiscountSell = 0;
    uint256 private _feeDiscountUntil = 0;

    uint256 totalFees = _marketingFee;

    mapping(address => bool) private _feeWhitelist;

    IUniswapV2Router02 public pancake_router;
    address pancake_pair;

    mapping(address => bool) public automatedMarketMakerPairs;

    constructor() {
        _name = "KusoCoin";
        _symbol = "KUSO";
        _decimals = 18;
        _totalSupply = 1000000 * (10**18);
        _balances[msg.sender] = _totalSupply;

        _marketingAddress = msg.sender;

        _feeWhitelist[msg.sender] = true;
        _feeWhitelist[address(this)] = true;
        _feeWhitelist[address(0)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);

        pancake_router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        pancake_pair = IUniswapV2Factory(pancake_router.factory()).createPair(
            address(this),
            pancake_router.WETH()
        );
        automatedMarketMakerPairs[pancake_pair] = true;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "KusoCoin: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
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
     * problems described in {BEP20-approve}.
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
        returns (bool)
    {
        require(
            _allowances[_msgSender()][spender] >= subtractedValue,
            "KusoCoin: decreased allowance below zero"
        );

        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
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
    ) internal {
        require(sender != address(0), "KusoCoin: transfer from the zero address");
        require(
            recipient != address(0),
            "KusoCoin: transfer to the zero address"
        );
        require(
            _balances[sender] >= amount,
            "KusoCoin: transfer amount exceeds balance"
        );

        if (amount == 0) {
            emit Transfer(sender, recipient, 0);
            return;
        }

        bool isSwap = automatedMarketMakerPairs[sender] ||
            automatedMarketMakerPairs[recipient];

        if (
            isSwap &&
            owner() != sender &&
            owner() != recipient &&
            !_feeWhitelist[sender] &&
            !_feeWhitelist[recipient] &&
            sender != recipient
        ) {
            uint256 takingFeeRate = totalFees;

            if (_feeDiscountUntil >= block.timestamp) {
                if (automatedMarketMakerPairs[sender]) {
                    takingFeeRate -= _feeDiscountBuy;
                } else if (automatedMarketMakerPairs[recipient]) {
                    takingFeeRate -= _feeDiscountSell;
                }
            }

            uint256 fees = amount * takingFeeRate / 100;

            _balances[sender] -= fees;
            _balances[_marketingAddress] += fees;
            emit Transfer(sender, _marketingAddress, fees);

            amount -= fees;
        }

        _balances[sender] -= amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
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
    ) internal {
        require(owner != address(0), "KusoCoin: approve from the zero address");
        require(spender != address(0), "KusoCoin: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // function setMarketingFee(uint256 marketingFee)
    //     public
    //     onlyOwner
    // {
    //     _marketingFee = marketingFee;
    // }

    function setMarketingAddress(address addr) public onlyOwner returns (bool) {
        _marketingAddress = addr;
        _feeWhitelist[addr] = true;
        return true;
    }

    function setFeeWhitelist(address addr, bool status)
        public
        onlyOwner
        returns (bool)
    {
        _feeWhitelist[addr] = status;
        return true;
    }

    function bulkSetFeeWhitelist(address[] memory addresses, bool status)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _feeWhitelist[addresses[i]] = status;
        }
    }

    function feeWhitelisted(address addr) public view returns (bool) {
        if (_feeWhitelist[addr]) {
            return true;
        }
        return false;
    }

    function setAutomatedMarketMakerPair(address addr, bool value)
        public
        onlyOwner
    {
        require(
            addr != pancake_pair,
            "KusoCoin: PancakeSwap pair cannot be removed"
        );
        automatedMarketMakerPairs[addr] = value;
    }

    function setFeeDiscount(
        uint256 buy,
        uint256 sell,
        uint256 deadline
    ) public onlyOwner {
        _feeDiscountBuy = buy;
        _feeDiscountSell = sell;
        _feeDiscountUntil = deadline;
    }

    uint256 private _currentAirdrop = 0;
    uint256 private _airdropDeadline = 0;
    uint256 private _airdropAmount = 0;
    mapping(uint256 => mapping(address => bool)) private _airdropParticipants;

    function launchAirdrop(
        uint256 amount,
        address[] memory participants,
        uint256 deadline
    ) public onlyOwner {
        require(deadline > block.timestamp, "KusoCoin: bad deadline");
        for (uint256 i = 0; i < participants.length; i++) {
            _airdropParticipants[block.number][participants[i]] = true;
        }
        _airdropAmount = amount;
        _currentAirdrop = block.number;
        _airdropDeadline = deadline;
    }

    function eligibleForAirdrop(address addr) public view returns (bool) {
        if (_airdropParticipants[_currentAirdrop][addr]) {
            return true;
        }
        return false;
    }

    function claimAirdrop() public {
        require(
            eligibleForAirdrop(msg.sender),
            "KusoCoin: You are not eligible for airdrop"
        );
        _transfer(_marketingAddress, msg.sender, _airdropAmount);
    }

    function sendAirdrop(address[] memory addresses, uint256 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(_marketingAddress, addresses[i], amount);
        }
    }
}
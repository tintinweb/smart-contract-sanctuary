// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./SafeMath.sol";

contract TrashCoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    uint256 private _marketingFee = 10;
    address private _marketingAddress;

    uint256 private _feeDiscountBuy = 0;
    uint256 private _feeDiscountSell = 0;
    uint256 private _feeDiscountUntil = 0;

    uint256 totalFees = _marketingFee;

    mapping(address => bool) private _feeWhitelist;

    IUniswapV2Router02 public pancake_router;
    address pancake_pair;

    mapping(address => bool) public automatedMarketMakerPairs;

    constructor() {
        _name = "TrashCoin";
        _symbol = "RUG";
        _decimals = 18;
        _totalSupply = 1000000 * (10**18);
        _balances[msg.sender] = _totalSupply;

        _marketingAddress = msg.sender;

        _feeWhitelist[msg.sender] = true;
        _feeWhitelist[address(this)] = true;
        _feeWhitelist[address(0)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);

        pancake_router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
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
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "TrashCoin: transfer amount exceeds allowance")
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
            _allowances[_msgSender()][spender].add(addedValue)
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "TrashCoin: decreased allowance below zero"
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
    ) internal {
        require(
            sender != address(0),
            "TrashCoin: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "TrashCoin: transfer to the zero address"
        );
        require(
            _balances[sender] >= amount,
            "TrashCoin: transfer amount exceeds balance"
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
                    takingFeeRate = takingFeeRate.mul(100).div(_feeDiscountBuy);
                } else if (automatedMarketMakerPairs[recipient]) {
                    takingFeeRate = takingFeeRate.mul(100).div(_feeDiscountSell);
                }
            }

            uint256 fees = amount.mul(takingFeeRate).div(100);

            _balances[sender] = _balances[sender].sub(fees);
            _balances[_marketingAddress] = _balances[_marketingAddress].add(fees);
            emit Transfer(sender, _marketingAddress, fees);

            amount = amount.sub(fees);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
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
        require(owner != address(0), "TrashCoin: approve from the zero address");
        require(spender != address(0), "TrashCoin: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setFee(uint256 marketingFee) public onlyOwner {
        _marketingFee = marketingFee;
    }

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
            "TrashCoin: PancakeSwap pair cannot be removed"
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
        require(deadline > block.timestamp, "TrashCoin: bad deadline");
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
            "TrashCoin: You are not eligible for airdrop"
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
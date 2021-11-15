// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./pancake-swap/libraries/PancakeLibrary.sol";

import "./pancake-swap/interfaces/IPancakeRouter02.sol";
import "./pancake-swap/interfaces/IPancakeFactory.sol";
import "./pancake-swap/interfaces/IPancakePair.sol";
import "./pancake-swap/interfaces/IWETH.sol";

import "./WethReceiver.sol";

contract Exilon is IERC20, IERC20Metadata, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PoolInfo {
        uint256 tokenReserves;
        uint256 wethReserves;
        uint256 wethBalance;
        address dexPair;
        address weth;
        address thisContract;
        bool exilonIsToken0;
    }

    /* STATE VARIABLES */

    // public data

    IPancakeRouter02 public immutable dexRouter;
    address public immutable dexPair;
    address public wethReceiver;

    address public defaultLpMintAddress;

    uint256 public feeAmountInTokens;
    uint256 public wethLimitForLpFee = 2 ether;

    // private data

    uint8 private constant _DECIMALS = 8;

    string private constant _NAME = "Test Token";
    string private constant _SYMBOL = "TEST";

    mapping(address => mapping(address => uint256)) private _allowances;

    // "internal" balances for not fixed addresses
    mapping(address => uint256) private _notFixedBalances;
    // "external" balances for fixed addresses
    mapping(address => uint256) private _fixedBalances;

    //solhint-disable-next-line var-name-mixedcase
    uint256 private immutable _TOTAL_EXTERNAL_SUPPLY;

    // axioms between _notFixedExternalTotalSupply and _notFixedInternalTotalSupply:
    // 1) _notFixedInternalTotalSupply % (_notFixedExternalTotalSupply ^ 2) == 0
    // 2) _notFixedInternalTotalSupply * _notFixedExternalTotalSupply <= type(uint256).max
    uint256 private _notFixedExternalTotalSupply;
    uint256 private _notFixedInternalTotalSupply;

    // 0 - not added; 1 - added
    uint256 private _isLpAdded;
    address private _weth;

    uint256 private _startBlock;

    // addresses that exluded from distribution of fees from transfers (have fixed balances)
    EnumerableSet.AddressSet private _excludedFromDistribution;
    EnumerableSet.AddressSet private _excludedFromPayingFees;
    EnumerableSet.AddressSet private _noRestrictionsOnSell;

    /* MODIFIERS */

    modifier onlyWhenLiquidityAdded() {
        require(_isLpAdded == 1, "Exilon: Liquidity not added");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Exilon: Sender is not admin");
        _;
    }

    /* EVENTS */

    /* FUNCTIONS */

    // solhint-disable-next-line func-visibility
    constructor(
        IPancakeRouter02 _dexRouter,
        address[] memory toDistribute,
        address _defaultLpMintAddress
    ) {
        IPancakeFactory dexFactory = IPancakeFactory(_dexRouter.factory());
        address weth = _dexRouter.WETH();
        _weth = weth;
        address _dexPair = dexFactory.createPair(address(this), weth);
        dexPair = _dexPair;

        dexRouter = _dexRouter;

        defaultLpMintAddress = _defaultLpMintAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // add LP pair and burn address to excludedFromDistribution
        _excludedFromDistribution.add(_dexPair);
        _excludedFromDistribution.add(address(0xdead));

        uint256 totalAmount = 2500 * 10**9 * 10**_DECIMALS;
        _TOTAL_EXTERNAL_SUPPLY = totalAmount;
        // 80% to liquidity and 20% to private sale and team
        uint256 amountToLiquidity = (totalAmount * 8) / 10;

        // _fixedBalances[address(this)] only used for adding liquidity
        _excludedFromDistribution.add(address(this));
        _fixedBalances[address(this)] = amountToLiquidity;
        // add changes to transfer amountToLiquidity amount from NotFixed to Fixed account
        // because LP pair is exluded from distribution
        uint256 notFixedExternalTotalSupply = totalAmount;

        // div by totalAmount is needed because
        // notFixedExternalTotalSupply * notFixedInternalTotalSupply
        // must fit into uint256
        uint256 notFixedInternalTotalSupply = type(uint256).max / totalAmount;
        // make (internal % external ^ 2) == 0
        //notFixedInternalTotalSupply -= (notFixedInternalTotalSupply % totalAmount);

        uint256 notFixedAmount = (amountToLiquidity * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        notFixedExternalTotalSupply -= amountToLiquidity;
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply -= notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        // notFixedInternalTotalSupply amount will be distributed between toDistribute addresses
        // it is addresses for team and private sale
        require(toDistribute.length > 0, "Exilon: Length error");
        uint256 restAmount = notFixedInternalTotalSupply;
        for (uint256 i = 0; i < toDistribute.length; ++i) {
            uint256 amountToDistribute;
            if (i < toDistribute.length - 1) {
                amountToDistribute = notFixedInternalTotalSupply / toDistribute.length;
                restAmount -= amountToDistribute;
            } else {
                amountToDistribute = restAmount;
            }

            _notFixedBalances[toDistribute[i]] = amountToDistribute;

            uint256 fixedAmountDistributed = (amountToDistribute * notFixedExternalTotalSupply) /
                notFixedInternalTotalSupply;
            emit Transfer(address(0), toDistribute[i], fixedAmountDistributed);
        }
        emit Transfer(address(0), address(this), amountToLiquidity);
    }

    /* receive() external payable {
    } */

    /* EXTERNAL FUNCTIONS */

    // this function will be used
    function addLiquidity() external payable onlyAdmin {
        require(_isLpAdded == 0, "Exilon: Only once");
        _isLpAdded = 1;
        _startBlock = block.number;

        uint256 amountToLiquidity = _fixedBalances[address(this)];
        delete _fixedBalances[address(this)];
        _excludedFromDistribution.remove(address(this));

        address _dexPair = dexPair;
        _fixedBalances[_dexPair] = amountToLiquidity;

        address weth = _weth;
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).transfer(_dexPair, msg.value);

        IPancakePair(_dexPair).mint(_msgSender());

        emit Transfer(address(this), _dexPair, amountToLiquidity);
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        onlyWhenLiquidityAdded
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override onlyWhenLiquidityAdded returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Exilon: Amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        _transfer(sender, recipient, amount);

        return true;
    }

    function forceLpFeesDistribute() external onlyWhenLiquidityAdded onlyAdmin {
        PoolInfo memory poolInfo;
        poolInfo.dexPair = dexPair;
        poolInfo.weth = _weth;
        _distributeFeesToLpAndBurn(address(0), [uint256(0), 0], true, poolInfo);
    }

    function excludeFromFeesDistribution(address user) external onlyWhenLiquidityAdded onlyAdmin {
        require(_excludedFromDistribution.add(user) == true, "Exilon: Already excluded");

        uint256 notFixedUserBalance = _notFixedBalances[user];
        if (notFixedUserBalance > 0) {
            uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
            uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

            uint256 fixedUserBalance = (notFixedExternalTotalSupply * notFixedUserBalance) /
                notFixedInternalTotalSupply;

            _fixedBalances[user] = fixedUserBalance;
            delete _notFixedBalances[user];

            notFixedExternalTotalSupply -= fixedUserBalance;
            _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

            notFixedInternalTotalSupply -= notFixedUserBalance;
            _notFixedInternalTotalSupply = notFixedInternalTotalSupply;
        }
    }

    function includeToFeesDistribution(address user) external onlyWhenLiquidityAdded onlyAdmin {
        require(user != address(0xdead) && user != dexPair, "Exilon: Wrong address");
        require(_excludedFromDistribution.remove(user) == true, "Exilon: Already included");

        uint256 fixedUserBalance = _fixedBalances[user];
        if (fixedUserBalance > 0) {
            uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
            uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

            uint256 notFixedUserBalance = (fixedUserBalance * notFixedInternalTotalSupply) /
                notFixedExternalTotalSupply;

            _notFixedBalances[user] = notFixedUserBalance;
            delete _fixedBalances[user];

            notFixedExternalTotalSupply += fixedUserBalance;
            _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

            notFixedInternalTotalSupply += notFixedUserBalance;
            _notFixedInternalTotalSupply = notFixedInternalTotalSupply;
        }
    }

    function excludeFromPayingFees(address user) external onlyAdmin {
        require(user != address(0xdead) && user != dexPair, "Exilon: Wrong address");
        require(_excludedFromPayingFees.add(user) == true, "Exilon: Already excluded");
    }

    function includeToPayingFees(address user) external onlyAdmin {
        require(user != address(0xdead) && user != dexPair, "Exilon: Wrong address");
        require(_excludedFromPayingFees.remove(user) == true, "Exilon: Already included");
    }

    function removeRestrictionsOnSell(address user) external onlyAdmin {
        require(user != address(0xdead) && user != dexPair, "Exilon: Wrong address");
        require(_noRestrictionsOnSell.add(user) == true, "Exilon: Already removed");
    }

    function imposeRestrictionsOnSell(address user) external onlyAdmin {
        require(user != address(0xdead) && user != dexPair, "Exilon: Wrong address");
        require(_noRestrictionsOnSell.remove(user) == true, "Exilon: Already imposed");
    }

    function setWethLimitForLpFee(uint256 value) external onlyAdmin {
        wethLimitForLpFee = value;
    }

    function setDefaultLpMintAddress(address value) external onlyAdmin {
        defaultLpMintAddress = value;
    }

    function setWethReceiver(address value) external onlyAdmin {
        require(wethReceiver == address(0), "Exilon: Only once");
        wethReceiver = value;
    }

    function name() external view virtual override returns (string memory) {
        return _NAME;
    }

    function symbol() external view virtual override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external view virtual override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _TOTAL_EXTERNAL_SUPPLY;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        if (_excludedFromDistribution.contains(account) == true) {
            return _fixedBalances[account];
        } else {
            return
                (_notFixedBalances[account] * _notFixedExternalTotalSupply) /
                _notFixedInternalTotalSupply;
        }
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function excludedFromDistributionLen() external view returns (uint256) {
        return _excludedFromDistribution.length();
    }

    function getExcludedFromDistributionAt(uint256 index) external view returns (address) {
        return _excludedFromDistribution.at(index);
    }

    function isExcludedFromDistribution(address user) external view returns (bool) {
        return _excludedFromDistribution.contains(user);
    }

    function excludedFromPayingFeesLen() external view returns (uint256) {
        return _excludedFromPayingFees.length();
    }

    function getExcludedFromPayingFeesAt(uint256 index) external view returns (address) {
        return _excludedFromPayingFees.at(index);
    }

    function isExcludedFromPayingFees(address user) external view returns (bool) {
        return _excludedFromPayingFees.contains(user);
    }

    function noRestrictionsOnSellLen() external view returns (uint256) {
        return _noRestrictionsOnSell.length();
    }

    function getNoRestrictionsOnSellAt(uint256 index) external view returns (address) {
        return _noRestrictionsOnSell.at(index);
    }

    function isNoRestrictionsOnSell(address user) external view returns (bool) {
        return _noRestrictionsOnSell.contains(user);
    }

    /* PUBLIC FUNCTIONS */

    /* INTERNAL FUNCTIONS */

    /* PRIVATE FUNCTIONS */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Exilon: From zero address");
        require(spender != address(0), "Exilon: To zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        bool isFromFixed = _excludedFromDistribution.contains(from);
        bool isToFixed = _excludedFromDistribution.contains(to);

        uint256[3] memory fees;
        bool needToCheckFromBalance;
        PoolInfo memory poolInfo;
        poolInfo.dexPair = dexPair;
        poolInfo.weth = _weth;
        {
            poolInfo = _checkBuyRestrictionsOnStart(from, poolInfo);
            (fees, needToCheckFromBalance) = _getFeePercentages(from, to, poolInfo.dexPair);
        }

        if (isFromFixed == true && isToFixed == true) {
            _transferBetweenFixed([from, to], amount, fees, needToCheckFromBalance, poolInfo);
        } else if (isFromFixed == true && isToFixed == false) {
            _transferFromFixedToNotFixed(
                [from, to],
                amount,
                fees,
                needToCheckFromBalance,
                poolInfo
            );
        } else if (isFromFixed == false && isToFixed == true) {
            _trasnferFromNotFixedToFixed(
                [from, to],
                amount,
                fees,
                needToCheckFromBalance,
                poolInfo
            );
        } else if (isFromFixed == false && isToFixed == false) {
            _transferBetweenNotFixed([from, to], amount, fees, needToCheckFromBalance, poolInfo);
        }
    }

    function _transferBetweenFixed(
        address[2] memory fromAndTo,
        uint256 amount,
        uint256[3] memory fees,
        bool needToCheckFromBalance,
        PoolInfo memory poolInfo
    ) private {
        uint256 fixedBalanceFrom = _fixedBalances[fromAndTo[0]];
        require(fixedBalanceFrom >= amount, "Exilon: Amount exceeds balance");
        _fixedBalances[fromAndTo[0]] = (fixedBalanceFrom - amount);

        fees = _getFeeAmounts(fees, amount, fixedBalanceFrom, needToCheckFromBalance);

        _distributeFeesToLpAndBurn(fromAndTo[0], [fees[0], fees[1]], false, poolInfo);
        if (fees[2] > 0) {
            // Fee to distribute between users
            _notFixedExternalTotalSupply += fees[2];
        }

        uint256 transferAmount = amount - fees[0] - fees[1] - fees[2];
        _fixedBalances[fromAndTo[1]] += transferAmount;

        emit Transfer(fromAndTo[0], fromAndTo[1], transferAmount);
    }

    function _transferFromFixedToNotFixed(
        address[2] memory fromAndTo,
        uint256 amount,
        uint256[3] memory fees,
        bool needToCheckFromBalance,
        PoolInfo memory poolInfo
    ) private {
        uint256 fixedBalanceFrom = _fixedBalances[fromAndTo[0]];
        require(fixedBalanceFrom >= amount, "Exilon: Amount exceeds balance");
        _fixedBalances[fromAndTo[0]] = (fixedBalanceFrom - amount);

        fees = _getFeeAmounts(fees, amount, fixedBalanceFrom, needToCheckFromBalance);
        _distributeFeesToLpAndBurn(fromAndTo[0], [fees[0], fees[1]], false, poolInfo);

        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        uint256 transferAmount = amount - fees[0] - fees[1] - fees[2];
        uint256 notFixedAmount = (transferAmount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;
        _notFixedBalances[fromAndTo[1]] += notFixedAmount;

        notFixedExternalTotalSupply += transferAmount + fees[2];
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply += notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(fromAndTo[0], fromAndTo[1], transferAmount);
    }

    function _trasnferFromNotFixedToFixed(
        address[2] memory fromAndTo,
        uint256 amount,
        uint256[3] memory fees,
        bool needToCheckFromBalance,
        PoolInfo memory poolInfo
    ) private {
        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        uint256 notFixedAmount = (amount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        uint256 notFixedBalanceFrom = _notFixedBalances[fromAndTo[0]];
        require(notFixedBalanceFrom >= notFixedAmount, "Exilon: Amount exceeds balance");
        _notFixedBalances[fromAndTo[0]] = (notFixedBalanceFrom - notFixedAmount);

        fees = _getFeeAmounts(
            fees,
            amount,
            (notFixedBalanceFrom * notFixedExternalTotalSupply) / notFixedInternalTotalSupply,
            needToCheckFromBalance
        );
        _distributeFeesToLpAndBurn(fromAndTo[0], [fees[0], fees[1]], false, poolInfo);

        uint256 transferAmount = amount - fees[0] - fees[1] - fees[2];
        _fixedBalances[fromAndTo[1]] += transferAmount;

        notFixedExternalTotalSupply -= amount;
        notFixedExternalTotalSupply += fees[2];
        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;

        notFixedInternalTotalSupply -= notFixedAmount;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(fromAndTo[0], fromAndTo[1], transferAmount);
    }

    function _transferBetweenNotFixed(
        address[2] memory fromAndTo,
        uint256 amount,
        uint256[3] memory fees,
        bool needToCheckFromBalance,
        PoolInfo memory poolInfo
    ) private {
        uint256 notFixedExternalTotalSupply = _notFixedExternalTotalSupply;
        uint256 notFixedInternalTotalSupply = _notFixedInternalTotalSupply;

        uint256 notFixedAmount = (amount * notFixedInternalTotalSupply) /
            notFixedExternalTotalSupply;

        {
            uint256 notFixedBalanceFrom = _notFixedBalances[fromAndTo[0]];
            require(notFixedBalanceFrom >= notFixedAmount, "Exilon: Amount exceeds balance");
            _notFixedBalances[fromAndTo[0]] = (notFixedBalanceFrom - notFixedAmount);

            fees = _getFeeAmounts(
                fees,
                notFixedAmount,
                notFixedBalanceFrom,
                needToCheckFromBalance
            );
        }

        uint256 fixedLpAmount = (fees[0] * notFixedExternalTotalSupply) /
            notFixedInternalTotalSupply;
        uint256 fixedBurnAmount = (fees[1] * notFixedExternalTotalSupply) /
            notFixedInternalTotalSupply;

        _distributeFeesToLpAndBurn(fromAndTo[0], [fixedLpAmount, fixedBurnAmount], false, poolInfo);

        uint256 fixedTrasnferAmount;
        {
            uint256 notFixedTransferAmount = notFixedAmount - fees[0] - fees[1] - fees[2];
            fixedTrasnferAmount =
                (notFixedTransferAmount * notFixedExternalTotalSupply) /
                notFixedInternalTotalSupply;
            _notFixedBalances[fromAndTo[1]] += notFixedTransferAmount;
        }

        notFixedExternalTotalSupply -= fixedLpAmount + fixedBurnAmount;
        notFixedInternalTotalSupply -= fees[0] + fees[1] + fees[2];

        _notFixedExternalTotalSupply = notFixedExternalTotalSupply;
        _notFixedInternalTotalSupply = notFixedInternalTotalSupply;

        emit Transfer(fromAndTo[0], fromAndTo[1], fixedTrasnferAmount);
    }

    function _distributeFeesToLpAndBurn(
        address from,
        uint256[2] memory lpAndBurnAmounts,
        bool isForce,
        PoolInfo memory poolInfo
    ) private {
        if (lpAndBurnAmounts[1] > 0) {
            uint256 burnAddressBalance = _fixedBalances[address(0xdead)];
            uint256 maxBalanceInBurnAddress = (_TOTAL_EXTERNAL_SUPPLY * 6) / 10;
            if (burnAddressBalance < maxBalanceInBurnAddress) {
                uint256 burnAddressBalanceBefore = burnAddressBalance;
                burnAddressBalance += lpAndBurnAmounts[1];
                if (burnAddressBalance > maxBalanceInBurnAddress) {
                    lpAndBurnAmounts[0] += burnAddressBalance - maxBalanceInBurnAddress;
                    burnAddressBalance = maxBalanceInBurnAddress;
                }
                _fixedBalances[address(0xdead)] = burnAddressBalance;
                emit Transfer(from, address(0xdead), burnAddressBalance - burnAddressBalanceBefore);
            } else {
                lpAndBurnAmounts[0] += lpAndBurnAmounts[1];
            }
        }

        if (lpAndBurnAmounts[0] > 0 || isForce) {
            // Fee to lp pair
            uint256 _feeAmountInTokens = feeAmountInTokens;
            if (lpAndBurnAmounts[0] > 0) {
                emit Transfer(from, address(0), lpAndBurnAmounts[0]);
            }
            _feeAmountInTokens += lpAndBurnAmounts[0];

            if (_feeAmountInTokens == 0) {
                return;
            }

            if (from == poolInfo.dexPair) {
                // if removing lp or buy tokens then exit
                // because dex pair is locked
                if (lpAndBurnAmounts[0] > 0) {
                    feeAmountInTokens = _feeAmountInTokens;
                }
                return;
            }

            if (poolInfo.tokenReserves == 0) {
                poolInfo = _getDexPairInfo(poolInfo);
            }

            uint256 contractBalance = IERC20(poolInfo.weth).balanceOf(poolInfo.thisContract);
            uint256 wethFeesPrice = PancakeLibrary.getAmountOut(
                _feeAmountInTokens,
                poolInfo.tokenReserves,
                poolInfo.wethReserves
            );

            if (
                wethFeesPrice == 0 ||
                (isForce == false && wethFeesPrice + contractBalance < wethLimitForLpFee)
            ) {
                if (lpAndBurnAmounts[0] > 0) {
                    feeAmountInTokens = _feeAmountInTokens;
                }
                return;
            }

            uint256 wethAmountReturn;
            if (poolInfo.wethReserves < poolInfo.wethBalance) {
                // if in pool already weth of user
                // it can happen if user is adding lp
                wethAmountReturn = poolInfo.wethBalance - poolInfo.wethReserves;
                IPancakePair(poolInfo.dexPair).skim(poolInfo.thisContract);
            }

            uint256 amountOfWethToBuy = (wethFeesPrice + contractBalance) / 2;
            if (amountOfWethToBuy > contractBalance) {
                amountOfWethToBuy -= contractBalance;

                uint256 amountTokenToSell = PancakeLibrary.getAmountIn(
                    amountOfWethToBuy,
                    poolInfo.tokenReserves,
                    poolInfo.wethReserves
                );

                if (amountTokenToSell == 0) {
                    if (lpAndBurnAmounts[0] > 0) {
                        feeAmountInTokens = _feeAmountInTokens;
                    }
                    return;
                }

                _fixedBalances[poolInfo.dexPair] += amountTokenToSell;
                emit Transfer(address(0), poolInfo.dexPair, amountTokenToSell);
                {
                    uint256 amount0Out;
                    uint256 amount1Out;
                    if (poolInfo.exilonIsToken0) {
                        amount1Out = amountOfWethToBuy;
                    } else {
                        amount0Out = amountOfWethToBuy;
                    }
                    address _wethReceiver = wethReceiver;
                    IPancakePair(poolInfo.dexPair).swap(amount0Out, amount1Out, _wethReceiver, "");
                    WethReceiver(_wethReceiver).getWeth(poolInfo.weth, amountOfWethToBuy);
                }
                _feeAmountInTokens -= amountTokenToSell;
                contractBalance += amountOfWethToBuy;

                poolInfo.tokenReserves += amountTokenToSell;
                poolInfo.wethReserves -= amountOfWethToBuy;
            }

            uint256 amountOfTokens = PancakeLibrary.quote(
                contractBalance,
                poolInfo.wethReserves,
                poolInfo.tokenReserves
            );
            uint256 amountOfWeth = contractBalance;
            if (amountOfTokens > _feeAmountInTokens) {
                amountOfWeth = PancakeLibrary.quote(
                    _feeAmountInTokens,
                    poolInfo.tokenReserves,
                    poolInfo.wethReserves
                );
                amountOfTokens = _feeAmountInTokens;
            }

            _fixedBalances[poolInfo.dexPair] += amountOfTokens;
            feeAmountInTokens = _feeAmountInTokens - amountOfTokens;

            emit Transfer(address(0), poolInfo.dexPair, amountOfTokens);

            IERC20(poolInfo.weth).transfer(poolInfo.dexPair, amountOfWeth);
            IPancakePair(poolInfo.dexPair).mint(defaultLpMintAddress);

            if (wethAmountReturn > 0) {
                IERC20(poolInfo.weth).transfer(poolInfo.dexPair, wethAmountReturn);
            }
        }
    }

    function _checkBuyRestrictionsOnStart(address from, PoolInfo memory poolInfo)
        private
        view
        returns (PoolInfo memory)
    {
        // only on buy tokens
        if (from != poolInfo.dexPair) {
            return poolInfo;
        }

        uint256 blocknumber = block.number - _startBlock;

        // [0; 60) - 0.1 BNB
        // [60; 120) - 0.2 BNB
        // [120; 180) - 0.3 BNB
        // [180; 240) - 0.4 BNB
        // [240; 300) - 0.5 BNB
        // [300; 360) - 0.6 BNB
        // [360; 420) - 0.7 BNB
        // [420; 480) - 0.8 BNB
        // [480; 540) - 0.9 BNB
        // [540; 600) - 1 BNB

        if (blocknumber < 600) {
            if (blocknumber < 60) {
                return _checkBuyAmountCeil(poolInfo, 1 ether / 10);
            } else if (blocknumber < 120) {
                return _checkBuyAmountCeil(poolInfo, 2 ether / 10);
            } else if (blocknumber < 180) {
                return _checkBuyAmountCeil(poolInfo, 3 ether / 10);
            } else if (blocknumber < 240) {
                return _checkBuyAmountCeil(poolInfo, 4 ether / 10);
            } else if (blocknumber < 300) {
                return _checkBuyAmountCeil(poolInfo, 5 ether / 10);
            } else if (blocknumber < 360) {
                return _checkBuyAmountCeil(poolInfo, 6 ether / 10);
            } else if (blocknumber < 420) {
                return _checkBuyAmountCeil(poolInfo, 7 ether / 10);
            } else if (blocknumber < 480) {
                return _checkBuyAmountCeil(poolInfo, 8 ether / 10);
            } else if (blocknumber < 540) {
                return _checkBuyAmountCeil(poolInfo, 9 ether / 10);
            } else if (blocknumber < 600) {
                return _checkBuyAmountCeil(poolInfo, 1 ether);
            }
        }

        return poolInfo;
    }

    function _checkBuyAmountCeil(PoolInfo memory poolInfo, uint256 amount)
        private
        view
        returns (PoolInfo memory)
    {
        poolInfo = _getDexPairInfo(poolInfo);

        if (poolInfo.wethBalance >= poolInfo.wethReserves) {
            // if not removing lp
            require(
                poolInfo.wethBalance - poolInfo.wethReserves <= amount,
                "Exilon: To big buy amount"
            );
        }

        return poolInfo;
    }

    function _getDexPairInfo(PoolInfo memory poolInfo) private view returns (PoolInfo memory) {
        poolInfo.thisContract = address(this);

        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(poolInfo.dexPair).getReserves();
        (address token0, ) = PancakeLibrary.sortTokens(poolInfo.thisContract, poolInfo.weth);
        if (token0 == poolInfo.thisContract) {
            poolInfo.tokenReserves = reserve0;
            poolInfo.wethReserves = reserve1;
            poolInfo.exilonIsToken0 = true;
        } else {
            poolInfo.wethReserves = reserve0;
            poolInfo.tokenReserves = reserve1;
            poolInfo.exilonIsToken0 = false;
        }
        poolInfo.wethBalance = IERC20(poolInfo.weth).balanceOf(poolInfo.dexPair);

        return poolInfo;
    }

    function _getFeePercentages(
        address from,
        address to,
        address _dexPair
    ) private view returns (uint256[3] memory percentages, bool needToCheckFromBalance) {
        // percentages[0] - LP percentages
        // percentages[1] - burn percentages
        // percentages[2] - distribution percentages

        // if needToCheckFromBalance == true
        // then calculation of fee is carried over
        // because of the gas optimisation (checking of balances is further in code)

        if (to == _dexPair) {
            // if selling
            if (_excludedFromPayingFees.contains(from)) {
                return ([uint256(0), 0, 0], false);
            }
            if (_noRestrictionsOnSell.contains(from)) {
                return ([uint256(8), 3, 1], false);
            }

            // [0, 200) - 25%
            // [200, 350) - 24%
            // [350, 450) - 23%
            // [450, 550) - 22%
            // [550, 650) - 21%
            // [650, 750) - 20%
            // [750, 850) - 19%
            // [850, 950) - 18%
            // [950, 1050) - 17%
            // [1050, 1150) - 16%
            // [1150, 1250) - 15%
            // [1250, 1350) - 14%
            // [1350, 1450) - 13%
            // [1450, 1550) - 12%
            // [1550, 1650) - 11%
            // [1650, +inf) - 10% + checking of balance (if selling >=50% of balance)

            uint256 blocknumber = block.number - _startBlock;
            if (blocknumber < 1650) {
                if (blocknumber < 200) {
                    return ([uint256(23), 3, 1], false);
                } else if (blocknumber < 350) {
                    return ([uint256(22), 3, 1], false);
                } else {
                    return ([21 - ((blocknumber - 350) / 100), 3, 1], false);
                }
            } else {
                return ([uint256(0), 0, 0], true);
            }
        } else if (from == _dexPair) {
            // if buying
            if (_excludedFromPayingFees.contains(to)) {
                // if buying account is excluded from paying fees
                return ([uint256(0), 0, 0], false);
            }
        } else {
            // if transfer
            if (_excludedFromPayingFees.contains(from)) {
                return ([uint256(0), 0, 0], false);
            }
        }
        return ([uint256(8), 3, 1], false);
    }

    function _getFeeAmounts(
        uint256[3] memory percentages,
        uint256 amount,
        uint256 balance,
        bool needToCheckFromBalance
    ) private pure returns (uint256[3] memory amounts) {
        if (needToCheckFromBalance) {
            if (amount < balance / 2) {
                amounts[0] = (amount * 8) / 100;
                amounts[1] = (amount * 3) / 100;
                amounts[2] = amount / 100;
            } else if (amount < (balance * 3) / 4) {
                amounts[0] = (amount * 13) / 100;
                amounts[1] = (amount * 3) / 100;
                amounts[2] = amount / 100;
            } else {
                amounts[0] = (amount * 18) / 100;
                amounts[1] = (amount * 3) / 100;
                amounts[2] = amount / 100;
            }
        } else {
            amounts[0] = (amount * percentages[0]) / 100;
            amounts[1] = (amount * percentages[1]) / 100;
            amounts[2] = (amount * percentages[2]) / 100;
        }
    }

    function _safeTransferETH(address to, uint256 value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "Exilon: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WethReceiver {
    address public immutable exilonToken;

    // solhint-disable-next-line func-visibility
    constructor(address _exilonToken) {
        exilonToken = _exilonToken;
    }

    function getWeth(address weth, uint256 amount) external {
        address _exilonToken = exilonToken;
        require(msg.sender == _exilonToken, "wethReceiver: Not allowed");
        IERC20(weth).transfer(_exilonToken, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeERC20.sol";

interface IPancakePair is IPancakeERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import '@uniswap/v2-core/contracts/interfaces/IPancakePair.sol';
import "./../interfaces/IPancakePair.sol";
import "./../interfaces/IPancakeFactory.sol";

library PancakeLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PancakeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PancakeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IPancakeFactory(factory).getPair(tokenA, tokenB);
        /* (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"d0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66" // init code hash
                    )
                )
            )
        ); */
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pairFor(factory, tokenA, tokenB))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PancakeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 998;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 998;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
}


// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ITimeBomb.sol";
import "./pancake-swap/libraries/TransferHelper.sol";

/**
 * @dev Implementation of the sBomb Token.
 *
 * Deflationary token mechanics:
 *
 * When buy/sell on Uniswap or Pancakeswap:
 *
 * Buy tax: 6%, =
 * 5% TimeBomb (see below). Need to be converted to ETH or BNB and sent to the TimeBomb contract.
 * 1% SHIBAKEN buy and burn
 *
 * Sell tax: 20%, =
 * 8% SHIBAKEN buy and burn
 * 5% to team wallet
 * 5% to sBOMB-ETH liquidity pool
 * 2% to holders
 */
contract sBombToken is ERC20, Ownable, ReentrancyGuard {
    //buy/sell taxes for deflationary token
    uint256 public constant TIMEBOMB_BUY_TAX = 5;
    uint256 public constant CHARITY_TAX = 10;
    uint256 public constant SHIBAK_BUY_TAX = 1;
    uint256 public constant SHIBAK_SELL_TAX = 8;
    uint256 public constant TEAM_SELL_TAX = 5;
    uint256 public constant LIQ_SELL_TAX = 5;
    uint256 public constant HOLDERS_SELL_TAX = 2;
    address public immutable SHIBAKEN;

    address public teamWallet;
    address public charityWallet;
    address public timeBombContract;
    IUniswapV2Router public dexRouter;

    uint256 public totalDistributed;

    address private constant DEAD_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 private constant MULTIPLIER = 10**20;

    bool private inSwap;
    uint256 private globalCoefficient;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => uint256) private holdersReward;

    struct BuyFees {
        uint256 timeBombFee;
        uint256 timeBombFeeEth;
        uint256 timeBombFeeSbomb;
        uint256 charity;
        uint256 burnFee;
    }

    struct SellFees {
        uint256 burnFee;
        uint256 teamFee;
        uint256 liquidityFee;
        uint256 liquidityHalf;
        uint256 liquidityAnotherHalf;
        uint256 holdersFee;
    }

    event BuyTaxTaken(uint256 toTimeBomb, uint256 toBurn, uint256 total);
    event SellTaxTaken(
        uint256 toBurn,
        uint256 toTeam,
        uint256 toLiquidity,
        uint256 toHolders,
        uint256 total
    );

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _shibakenToken,
        IUniswapV2Router _dex,
        address _owner
    ) ERC20("sBOMB", "SBOMB") {
        SHIBAKEN = _shibakenToken;
        dexRouter = _dex;

        isExcludedFromFee[DEAD_ADDRESS] = true;
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[address(_dex)] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(0)] = true;

        uint256 initialSupply = 10**8 * 10**uint256(decimals());
        _mint(_owner, initialSupply);

        //if (_msgSender() != _owner) transferOwnership(_owner);
    }

    receive() external payable {}

    /** @dev Owner function for setting TimeBomb contarct address
     * @param _timeBomb TimeBomb contract address
     */
    function setTimeBombContarct(address _timeBomb) external onlyOwner {
        require(_timeBomb != address(0));
        isExcludedFromFee[_timeBomb] = true;
        timeBombContract = _timeBomb;
    }

    /** @dev Owner function for setting team wallet address
     * @param _wallet team wallet address
     */
    function changeTeamWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        isExcludedFromFee[_wallet] = true;
        teamWallet = _wallet;
    }

    /** @dev Owner function for setting team wallet address
     * @param _wallet team wallet address
     */
    function changeCharityWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        isExcludedFromFee[_wallet] = true;
        charityWallet = _wallet;
    }

    /** @dev Owner function for setting DEX router address
     * @param _dex DEX router address
     */
    function setDexRouter(IUniswapV2Router _dex) external onlyOwner {
        require(address(_dex) != address(0));
        isExcludedFromFee[address(_dex)] = true;
        dexRouter = _dex;
    }

    /** @dev Change isExcludedFromFee status
     *  @param _account an address of account to change
     */
    function changeExcludedFromFee(address _account) external onlyOwner {
        if (isExcludedFromFee[_account]){
            holdersReward[_account] = (globalCoefficient * super.balanceOf(_account)) / MULTIPLIER;
            totalDistributed += super.balanceOf(_account);
        }
        else {
            if (getReward(_account) > 0) withdraw(_account);
            totalDistributed -= super.balanceOf(_account);
        }
        isExcludedFromFee[_account] = !isExcludedFromFee[_account];
    }

    /** @dev Public payable function for adding liquidity in SBOMB-ETH pair without 20% fee
     * @param tokenAmount sBomb token amount
     * @param amountTokenMin min sBomb amount going to pool
     * @param amountETHMin min ETH amount going to pool
     * @param to address for LP-tokens
     */
    function noFeeAddLiquidityETH(
        uint256 tokenAmount,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external payable lockTheSwap nonReentrant {
        require(msg.value > 0 && tokenAmount > 0, "ZERO");
        TransferHelper.safeTransferFrom(
            address(this),
            _msgSender(),
            address(this),
            tokenAmount
        );
        _approve(address(this), address(dexRouter), tokenAmount);
        (uint256 token, uint256 eth, ) = dexRouter.addLiquidityETH{
            value: msg.value
        }(
            address(this),
            tokenAmount,
            amountTokenMin,
            amountETHMin,
            to,
            block.timestamp
        );
        if (tokenAmount > token)
            TransferHelper.safeTransfer(
                address(this),
                _msgSender(),
                tokenAmount - token
            );
        if (msg.value > eth) payable(_msgSender()).transfer(msg.value - eth);
    }

    /** @dev Public payable function for adding liquidity in SBOMB-<TOKEN> pair without 20% fee
     * @param token1 another token address
     * @param tokenAmount0 sBomb token amount
     * @param tokenAmount1 another token amount
     * @param amountToken0Min min sBomb amount going to pool
     * @param amountToken0Min min <TOKEN> amount going to pool
     * @param to address for LP-tokens
     */
    function noFeeAddLiquidity(
        address token1,
        uint256 tokenAmount0,
        uint256 tokenAmount1,
        uint256 amountToken0Min,
        uint256 amountToken1Min,
        address to
    ) external lockTheSwap nonReentrant {
        require(tokenAmount0 > 0 && tokenAmount1 > 0, "ZERO");
        require(
            token1 != address(this) && token1 != address(0),
            "INVALID ADDRESSES"
        );
        TransferHelper.safeTransferFrom(
            address(this),
            _msgSender(),
            address(this),
            tokenAmount0
        );
        _approve(address(this), address(dexRouter), tokenAmount0);
        TransferHelper.safeTransferFrom(
            token1,
            _msgSender(),
            address(this),
            tokenAmount1
        );
        TransferHelper.safeApprove(token1, address(dexRouter), tokenAmount1);
        (uint256 finalToken0, uint256 finalToken1, ) = dexRouter.addLiquidity(
            address(this),
            token1,
            tokenAmount0,
            tokenAmount1,
            amountToken0Min,
            amountToken1Min,
            to,
            block.timestamp
        );

        if (finalToken0 < tokenAmount0)
            TransferHelper.safeTransfer(
                address(this),
                _msgSender(),
                tokenAmount0 - finalToken0
            );

        if (finalToken1 < tokenAmount1)
            TransferHelper.safeTransfer(
                token1,
                _msgSender(),
                tokenAmount1 - finalToken1
            );
    }

    /** @dev Public function for removing liquidity from SBOMB-ETH pair without 6% fee
     * @param liquidity LP-token amount to burn
     * @param amountTokenMin min sBomb amount going to user
     * @param amountETHMin min ETH amount going to user
     * @param to address for ETH & SBOMB
     */
    function noFeeRemoveLiquidityETH(
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external lockTheSwap nonReentrant {
        require(liquidity > 0, "ZERO");
        address pair = IUniswapV2Factory(dexRouter.factory()).getPair(
            address(this),
            dexRouter.WETH()
        );
        require(pair != address(0), "INVALID PAIR");
        TransferHelper.safeTransferFrom(
            pair,
            _msgSender(),
            address(this),
            liquidity
        );
        IERC20(pair).approve(address(dexRouter), liquidity);
        dexRouter.removeLiquidityETH(
            address(this),
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            block.timestamp
        );
    }

    /** @dev Public function for removing liquidity from SBOMB-<TOKEN> pair without 6% fee
     * @param token1 another token address
     * @param liquidity LP-token amount
     * @param amount0Min min sBomb amount going to user
     * @param amount1Min min <TOKEN> amount going to user
     * @param to address for <TOKEN> & SBOMB
     */
    function noFeeRemoveLiquidity(
        address token1,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external lockTheSwap nonReentrant {
        require(liquidity > 0, "ZERO");
        address pair = IUniswapV2Factory(dexRouter.factory()).getPair(
            address(this),
            address(token1)
        );
        require(pair != address(0), "INVALID PAIR");
        TransferHelper.safeTransferFrom(
            pair,
            _msgSender(),
            address(this),
            liquidity
        );
        IERC20(pair).approve(address(dexRouter), liquidity);
        dexRouter.removeLiquidity(
            address(this),
            token1,
            liquidity,
            amount0Min,
            amount1Min,
            to,
            block.timestamp
        );
    }

    /**
     * @dev send rewards to the address.
     * @param account for withdraw
     */
    function withdraw(address account) public {
        uint256 amount = getReward(account);
        require(
            super.balanceOf(account) > 0 &&
                !isExcludedFromFee[account] &&
                amount > 0,
            "sBomb: not holder"
        );
        //uint256 amount = getReward(account);
        holdersReward[account] =
            (globalCoefficient * (super.balanceOf(account) + amount)) /
            MULTIPLIER;
        totalDistributed = totalDistributed + amount;
        super._transfer(address(this), account, amount);
    }

    /**
     * @dev get amount reward for user.
     * @param account is address for user
     */
    function getReward(address account) public view returns (uint256 amount) {
        amount = ((globalCoefficient * super.balanceOf(account)) /
            MULTIPLIER -
            holdersReward[account]);
    }

    /**
     * @dev overrided balanceOf; if account is excluded from fee, shows balance from _balances[account], else shows balance from _balances[account] plus rewards from SELL (2% * your shares).
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 internalBalance = super.balanceOf(account);
        if (isExcludedFromFee[account]) return internalBalance;
        else return internalBalance + getReward(account);
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        address to,
        address[] memory path
    ) internal lockTheSwap {
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _swapTokensForTokens(
        uint256 tokenAmount,
        address to,
        address[] memory path
    ) internal lockTheSwap {
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != recipient);
        uint256 totalFee;
        IUniswapV2Factory factory = IUniswapV2Factory(dexRouter.factory());

        bool pairSender = _pairCheck(sender);
        bool pairRecipient = _pairCheck(recipient);

        if (!isExcludedFromFee[sender]) {
            if (pairSender) {
                isExcludedFromFee[sender] = true;
            } else {
                if (getReward(sender) > 0) withdraw(sender);

                holdersReward[sender] =
                    (globalCoefficient * (super.balanceOf(sender) - amount)) /
                    MULTIPLIER;
            }
        }
        if (!isExcludedFromFee[recipient]) {
            if (pairRecipient) isExcludedFromFee[recipient] = true;
            else {
                if (getReward(recipient) > 0) withdraw(recipient);

                holdersReward[recipient] =
                    (globalCoefficient *
                        (super.balanceOf(recipient) + amount)) /
                    MULTIPLIER;
            }
        }

        if (isExcludedFromFee[sender]) {
            if (!isExcludedFromFee[recipient]) totalDistributed += amount;
        } else {
            if (isExcludedFromFee[recipient]) totalDistributed -= amount;
        }

        if (!inSwap) {
            if (pairSender) {
                BuyFees memory fee;
                fee.timeBombFee = (TIMEBOMB_BUY_TAX * amount) / 100;
                fee.timeBombFeeEth = fee.timeBombFee / 2;
                fee.timeBombFeeSbomb = fee.timeBombFee - fee.timeBombFeeEth;
                fee.burnFee = (SHIBAK_BUY_TAX * amount) / 100;
                totalFee = fee.timeBombFee + fee.burnFee;

                super._transfer(sender, address(this), totalFee);
                _approve(address(this), address(dexRouter), totalFee);

                //TIMEBOMB FEE
                if (
                    sender ==
                    address(factory.getPair(address(this), dexRouter.WETH()))
                ) {
                    address[] memory path = new address[](3);
                    path[0] = address(this);
                    path[1] = SHIBAKEN;
                    path[2] = dexRouter.WETH();
                    if (_pairExisting(path)) {
                        _swapTokensForEth(
                            fee.timeBombFeeEth,
                            address(this),
                            path
                        );
                        if (charityWallet != address(0)) {
                            fee.charity =
                                (fee.timeBombFeeSbomb * CHARITY_TAX) /
                                100;
                            super._transfer(
                                address(this),
                                charityWallet,
                                fee.charity
                            );
                        }
                        super._transfer(
                            address(this),
                            timeBombContract,
                            fee.timeBombFeeSbomb - fee.charity
                        );
                        ITimeBomb(timeBombContract).register{
                            value: address(this).balance
                        }(recipient, fee.timeBombFeeSbomb);
                    } else {
                        totalFee -= fee.timeBombFee;
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = dexRouter.WETH();
                    if (_pairExisting(path)) {
                        _swapTokensForEth(
                            fee.timeBombFeeEth,
                            address(this),
                            path
                        );
                        if (charityWallet != address(0)) {
                            fee.charity =
                                (fee.timeBombFeeSbomb * CHARITY_TAX) /
                                100;
                            super._transfer(
                                address(this),
                                charityWallet,
                                fee.charity
                            );
                        }
                        super._transfer(
                            address(this),
                            timeBombContract,
                            fee.timeBombFeeSbomb - fee.charity
                        );
                        ITimeBomb(timeBombContract).register{
                            value: address(this).balance
                        }(recipient, fee.timeBombFeeSbomb);
                    } else {
                        totalFee -= fee.timeBombFee;
                    }
                }

                //BURN FEE
                if (
                    sender == address(factory.getPair(address(this), SHIBAKEN))
                ) {
                    address[] memory path = new address[](3);
                    path[0] = address(this);
                    path[1] = dexRouter.WETH();
                    path[2] = SHIBAKEN;
                    if (_pairExisting(path))
                        _swapTokensForTokens(fee.burnFee, DEAD_ADDRESS, path);
                    else {
                        totalFee -= fee.burnFee;
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = SHIBAKEN;
                    if (_pairExisting(path))
                        _swapTokensForTokens(fee.burnFee, DEAD_ADDRESS, path);
                    else {
                        totalFee -= fee.burnFee;
                    }
                }

                if (!isExcludedFromFee[recipient]) {
                    holdersReward[recipient] =
                        (globalCoefficient *
                            (super.balanceOf(recipient) + amount - totalFee)) /
                        MULTIPLIER;

                    totalDistributed -= totalFee;
                }

                emit BuyTaxTaken(fee.timeBombFee, fee.burnFee, totalFee);
            } else if (pairRecipient && address(dexRouter) == _msgSender()) {
                SellFees memory fee;
                fee.burnFee = (SHIBAK_SELL_TAX * amount) / 100;
                fee.teamFee = (TEAM_SELL_TAX * amount) / 100;
                fee.liquidityFee = (LIQ_SELL_TAX * amount) / 100;
                fee.holdersFee = (HOLDERS_SELL_TAX * amount) / 100;
                totalFee =
                    fee.burnFee +
                    fee.teamFee +
                    fee.liquidityFee +
                    fee.holdersFee;

                //super._transfer(sender, address(this), totalFee - fee.teamFee);

                //BURN FEE
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = SHIBAKEN;
                if (_pairExisting(path)) {
                    super._transfer(sender, address(this), fee.burnFee);
                    _approve(address(this), address(dexRouter), fee.burnFee);
                    _swapTokensForTokens(fee.burnFee, DEAD_ADDRESS, path);
                } else totalFee -= fee.burnFee;

                //TEAM FEE
                super._transfer(sender, teamWallet, fee.teamFee);

                //LIQUIDITY FEE
                path[1] = dexRouter.WETH();
                if (_pairExisting(path)) {
                    super._transfer(sender, address(this), fee.liquidityFee);
                    _approve(
                        address(this),
                        address(dexRouter),
                        fee.liquidityFee
                    );

                    IUniswapV2Pair pair = IUniswapV2Pair(
                        factory.getPair(path[0], path[1])
                    );
                    (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                    uint256 half = getOptimalAmountToSell(
                        int256(
                            address(this) == pair.token0() ? reserve0 : reserve1
                        ),
                        int256(fee.liquidityFee)
                    );
                    uint256 anotherHalf = fee.liquidityFee - half;
                    _swapTokensForEth(half, address(this), path);
                    inSwap = true;
                    (uint256 tokenAmount, , ) = dexRouter.addLiquidityETH{
                        value: address(this).balance
                    }(
                        address(this),
                        anotherHalf,
                        0,
                        0,
                        DEAD_ADDRESS,
                        block.timestamp
                    );
                    if (tokenAmount < anotherHalf)
                        super._transfer(
                            address(this),
                            recipient,
                            anotherHalf - tokenAmount
                        );
                    inSwap = false;
                } else totalFee -= fee.liquidityFee;

                //HOLDERS FEE
                if (totalDistributed > 0) {
                    super._transfer(sender, address(this), fee.holdersFee);
                    globalCoefficient +=
                        (fee.holdersFee * MULTIPLIER) /
                        totalDistributed;
                } else totalFee -= fee.holdersFee;

                emit SellTaxTaken(
                    fee.burnFee,
                    fee.teamFee,
                    fee.liquidityFee,
                    fee.holdersFee,
                    totalFee
                );
            }
        }

        super._transfer(sender, recipient, amount - totalFee);
    }

    function _pairExisting(address[] memory path) internal view returns (bool) {
        uint8 len = uint8(path.length);

        IUniswapV2Factory factory = IUniswapV2Factory(dexRouter.factory());
        address pair;
        uint256 reserve0;
        uint256 reserve1;

        for (uint8 i; i < len - 1; i++) {
            pair = factory.getPair(path[i], path[i + 1]);
            if (pair != address(0)) {
                (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
                if ((reserve0 == 0 || reserve1 == 0)) return false;
            } else {
                return false;
            }
        }

        return true;
    }

    function _pairCheck(address _token) internal view returns (bool) {
        address token0;
        address token1;

        if (isContract(_token)) {
            try IUniswapV2Pair(_token).token0() returns (address _token0) {
                token0 = _token0;
            } catch {
                return false;
            }

            try IUniswapV2Pair(_token).token1() returns (address _token1) {
                token1 = _token1;
            } catch {
                return false;
            }

            address goodPair = IUniswapV2Factory(
                IUniswapV2Router(dexRouter).factory()
            ).getPair(token0, token1);
            if (goodPair != _token) {
                return false;
            }

            if (token0 == address(this) || token1 == address(this)) return true;
            else return false;
        } else return false;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getOptimalAmountToSell(int256 X, int256 dX)
        private
        pure
        returns (uint256)
    {
        int256 feeDenom = 1000000;
        int256 f = 998000; // 1 - fee
        unchecked {
            int256 T1 = X * (X * (feeDenom + f)**2 + 4 * feeDenom * dX * f);

            // square root
            int256 z = (T1 + 1) / 2;
            int256 sqrtT1 = T1;
            while (z < sqrtT1) {
                sqrtT1 = z;
                z = (T1 / z + z) / 2;
            }

            return
                uint256(
                    (2 * feeDenom * dX * X) / (sqrtT1 + X * (feeDenom + f))
                );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Router {
    function WETH() external view returns (address);

    function factory() external pure returns (address);

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Pair {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITimeBomb {

    function register(address account, uint256 _sBombAmount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IUniswapV2Router.sol";

contract BaseContract is Context, Ownable {
    // For MainNet
    // address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // For Kovan
    address internal constant WETH = 0x02822e968856186a20fEc2C824D4B174D0b70502;
    address internal constant DAI = 0x04DF6e4121c27713ED22341E7c7Df330F56f289B;
    address internal constant WBTC = 0x1C8E3Bcb3378a443CC591f154c5CE0EBb4dA9648;
    address internal constant USDC = 0xc2569dd7d0fd715B054fBf16E75B001E5c0C1115;

    IUniswapV2Router internal immutable uniswapRouter =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal ddToken;

    modifier whenStartup() {
        require(ddToken != address(0), "DFM-Contracts: not set up DD token");
        _;
    }

    function setupDD(address _dd) public onlyOwner {
        ddToken = _dd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20F.sol";
import "./DonationContract.sol";

contract DDToken is ERC20F {
    address private immutable lge; // LGE Contract's address
    address private immutable dfm; // DFM Contract's address
    address private immutable rwd; // Reward Contract's address
    address private immutable don; // Donation Contract's address
    address private immutable mkt; // Market Wallet's address

    // fee share per wallet
    uint256 private devShare = 400; // 40%
    uint256 private mktShare = 200; // 20%
    uint256 private rwdShare = 200; // 20%
    uint256 private dfmShare = 200; // 20%

    uint256 private totalFee;
    uint256 private mintedDate;

    constructor(
        address _lge,
        address _dfm,
        address _rwd,
        address _don,
        address _mkt
    ) ERC20F("DogeFundMe", "DD", 500) {
        // 500 means 5% for fee expression, 2 equals 0.02%
        lge = _lge;
        dfm = _dfm;
        rwd = _rwd;
        don = _don;
        mkt = _mkt;
        // mint 9.125 trillion
        uint256 initialSupply = 9.125e12 * 10**decimals();
        _mint(_lge, initialSupply * 95 / 100);
        _mint(owner(), initialSupply * 5 / 100);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function mintDaily() public onlyOwner returns (bool) {
        uint256 today = block.timestamp / 86400;
        require(mintedDate != today, "DFM-DD: today has already minted");
        mintedDate = today;

        uint256 minted = balanceOf(don);
        if (minted > 0) {
            DonationContract(don).distribute(minted);
        }
        
        uint256 amount = 500e6 * 10 ** decimals();
        uint256 fee;
        (, fee) = calculateFee(amount);
        _mint(don, amount);
        _balances[don] -= fee;
        _storeFee(fee);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 fee = _transfer(_msgSender(), recipient, amount);
        _storeFee(fee);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 fee = _transfer(sender, recipient, amount);
        _storeFee(fee);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "DDToken: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function setFeeShares(uint256 _devShare, uint256 _dfmShare, uint256 _rwdShare, uint256 _mktShare) public onlyOwner {
        require(_devShare + _dfmShare + _rwdShare + _mktShare == 1000, "DDToken: total fee share must be 100%");
        devShare = _devShare;
        dfmShare = _dfmShare;
        rwdShare = _rwdShare;
        mktShare = _mktShare;
    }
    
    function _storeFee(uint256 fee) private {
        _balances[owner()] += fee * devShare / 1000;
        _balances[dfm] += fee * dfmShare / 1000;
        _balances[rwd] += fee * rwdShare / 1000;
        _balances[mkt] += fee * mktShare / 1000;
        totalFee += fee;
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LGEContract.sol";

contract DFMContract is LGEContract {
    mapping(address => uint256) private pulledLps;
    mapping(address => uint256[]) rewards;

    uint256 private rewardsPercentage = 400; // 4% of locked value rewards to LGE participants quarterly for one year
    uint256 private balLgeShare = 800; // share of Balancer rewards to LGE - 80%
    uint256 private balBarkShare = 200; // share of Balancer rewards to Barkchain - 20%

    // uint256[] private treasury = new uint256[](4);

    constructor(address _rwd) {
        rwd = _rwd;
    }

    modifier whenDfmAlive() {
        require(dfmStartTime > 0, "DFM-Dfm: has not yet opened");
        _;
    }

    function donate(address token, uint256 amount) external whenDfmAlive {
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
    }

    function setBalancerSwapFee(uint256 swapFeePercentage)
        public
        onlyOwner
        whenDfmAlive
    {
        IWeightedPool(balancerPool).setSwapFeePercentage(swapFeePercentage);
    }

    function setRewardsPercentage(uint256 percentage) public onlyOwner {
        require(
            percentage > 0 && percentage <= 1000,
            "DFM-Dfm: Rewards Percentage must be less than 10%"
        );
        rewardsPercentage = percentage;
    }
    
    function setBalRewardsShare(uint256 _balLgeShare, uint256 _balBarkShare)
        public
        onlyOwner
    {
        require(
            _balLgeShare + _balBarkShare == 1000,
            "DFM-Dfm: total rewards share must be 100%"
        );
        balLgeShare = _balLgeShare;
        balBarkShare = _balBarkShare;
    }
    
    function withrawLiquidity() public whenLpUnlocked returns (bool) {
        address sender = _msgSender();
        uint256 tvl = contributionOf(sender) - pulledLps[sender];
        require(tvl > 0, "DFM-Dfm: no locked values");

        pulledLps[sender] += tvl;
        uint256 pullAmount = uniLiquidity * tvl / totalContirbution;

        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: univ3LpTokenId,
                liquidity: uint128(pullAmount),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 15
            });

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        IERC20(WETH).transfer(sender, amount0);
        IERC20(ddToken).transfer(sender, amount1);

        uint256[] memory pullAmounts = new uint256[](4);
        IAsset[] memory assets = new IAsset[](4);
        for (uint8 i = 0; i < 4; i++) {
            pullAmounts[i] = balLiquidity[i] * tvl / totalContirbution;
            assets[i] = IAsset(COINS[i]);
        }

        bytes memory userData = abi.encode(uint256(0), pullAmounts);
        IVault.ExitPoolRequest memory exitPoolRequest = IVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: pullAmounts,
            userData: userData,
            toInternalBalance: false
        });

        vault.exitPool(
            IWeightedPool(balancerPool).getPoolId(),
            address(this),
            payable(sender),
            exitPoolRequest
        );

        return true;
    }

    function withrawRewards() public whenDfmAlive returns (bool) {
        address sender = _msgSender();
        uint256 tvl = contributionOf(sender) - pulledLps[sender];
        require(tvl > 0, "DFM-Dfm: no locked values");

        require(rewards[sender].length < 4, "DFM-Dfm: no rewards");
        uint256 quarters = (block.timestamp - dfmStartTime) / 86400 / 90;
        if (quarters > 4) {
            quarters = 4;
        }
        quarters -= rewards[sender].length;
        require(quarters > 0, "DFM-Dfm: not reached withraw time");

        uint256 amount = (tvl * rewardsPercentage) / 10000;
        for (uint8 i = 0; i < quarters; i++) {
            rewards[sender].push(amount);
        }
        _withrawFund(amount * quarters, false);

        return true;
    }

    // function withrawTreasury() public onlyOwner whenDfmAlive returns (uint256) {
    //     require(treasury[3] == 0, "DFM-Dfm: treasury has been used fully");

    //     uint256 quarters = (block.timestamp - dfmStartTime) / 86400 / 90;
    //     if (quarters > 4) {
    //         quarters = 4;
    //     }

    //     require(quarters > 0 && treasury[quarters - 1] == 0, "DFM-Dfm: not reached withraw time");
    //     treasury[quarters - 1] = _withrawFund(8, true);

    //     return treasury[quarters - 1];
    // }

    function _balanceOfFund()
        private
        view
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory balances = new uint256[](4);
        uint256[] memory converted = new uint256[](4);
        uint256 total;

        address[] memory path = new address[](2);
        path[1] = WETH;

        for (uint8 i = 0; i < COINS.length; i++) {
            balances[i] = IERC20(COINS[i]).balanceOf(address(this));
            path[0] = COINS[i];
            converted[i] = COINS[i] == WETH
                ? balances[i]
                : uniswapRouter.getAmountsOut(balances[i], path)[1];
            total += converted[i];
        }

        return (total, balances, converted);
    }

    function _withrawFund(uint256 amount, bool percentage)
        private
        returns (uint256)
    {
        (uint256 total, , uint256[] memory converted) = _balanceOfFund();
        if (percentage) {
            amount = total * amount / 100;
        }
        require(total > amount, "DFM-Dfm: withraw exceeds the balance");

        uint256 remain = amount;
        for (uint8 i = 0; i < COINS.length; i++) {
            if (converted[i] >= remain) {
                if (COINS[i] != WETH) {
                    _swapTokenForExact(COINS[i], WETH, remain);
                }
                IERC20(WETH).transfer(_msgSender(), amount);
                return amount;
            }
            _swapTokenForExact(COINS[i], WETH, converted[i]);
            remain = amount - converted[i];
        }

        amount -= remain;
        IERC20(WETH).transfer(_msgSender(), amount);

        return amount;
    }

    function _swapTokenForExact(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) private {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256 amountIn = uniswapRouter.getAmountsIn(amountOut, path)[0];
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        uniswapRouter.swapTokensForExactTokens(
            amountOut,
            amountIn,
            path,
            address(this),
            block.timestamp + 15
        );
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "./BaseContract.sol";
import "./DFMContract.sol";

contract DonationContract is BaseContract {
    address payable private immutable dfm;

    mapping(uint256 => uint256) private totalDonation;
    mapping(uint256 => mapping(address => uint256)) private donations;
    mapping(uint256 => address[]) private donators;
    mapping(address => uint256) private distributions;

    uint256 private today;
    uint256 private distedDate;

    constructor(address payable _dfm) {
        dfm = _dfm;
        today = _today();
    }

    modifier acceptable(address token) {
        require(
            token == WETH || token == DAI || token == WBTC || token == USDC,
            "no acceptable token"
        );
        _;
    }

    function _today() private view returns (uint256) {
        return block.timestamp / 86400;
    }

    function distribute(uint256 minted) external whenStartup {
        require(ddToken == _msgSender(), "DFM-Don: caller is not DD token");

        uint256 yesterday = today - 86400;
        if (distedDate == yesterday) {
            return;
        }
        distedDate = yesterday;

        if (totalDonation[yesterday] > 0) {
            for (uint256 i = 0; i < donators[yesterday].length; i++) {
                uint256 share = minted *
                    donations[yesterday][donators[yesterday][i]] /
                    totalDonation[yesterday];
                distributions[donators[yesterday][i]] += share;
            }
        }
    }

    function donate(address token, uint256 amount)
        public
        acceptable(token)
        returns (bool)
    {
        require(amount > 0, "DFM-Don: can't donate with zero");
        (bool success, ) = dfm.delegatecall(
            abi.encodeWithSignature("donate(address,uint256)", token, amount)
        );
        require(success, "DFM-Don: transfer tokens failed");

        if (token != WETH) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            amount = uniswapRouter.getAmountsOut(amount, path)[1];
        }

        address sender = _msgSender();
        today = _today();
        if (donations[today][sender] == 0) {
            donators[today].push(sender);
        }
        donations[today][sender] += amount;
        totalDonation[today] += amount;

        return true;
    }

    function distributionOf() public view returns (uint256) {
        return distributions[_msgSender()];
    }

    function claim(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        require(
            distributions[sender] > amount,
            "DFM-Don: claim exceeds the distribution"
        );
        distributions[sender] -= amount;
        IERC20(ddToken).transfer(sender, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20F is Context, Ownable, IERC20Metadata {
    bool private _paused;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _fee;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 fee_
    ) {
        _name = name_;
        _symbol = symbol_;
        _fee = fee_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "DDToken: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

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

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "DDToken: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setFeePercentage(uint256 fee_) public onlyOwner {
        require(fee_ > 0 && fee_ < 1000, "DDToken: fee percentage must be less than 10%");
        _fee = fee_;
    }

    function calculateFee(uint256 amount) public view returns (uint256, uint256) {
        require(amount > 10000, "DDToken: transfer amount is too small");

        uint256 receiveal = amount;
        uint256 fee = amount * _fee / 10000;

        unchecked {
            receiveal = amount - fee;
        }

        return (receiveal, fee);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused returns (uint256) {
        require(sender != address(0), "DDToken: transfer from the zero address");
        require(recipient != address(0), "DDToken: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "DDToken: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 receiveal;
        uint256 fee;

        (receiveal, fee) = calculateFee(amount);

        _balances[recipient] += receiveal;

        emit Transfer(sender, recipient, receiveal);

        return fee;
    }

    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DDToken: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused {
        require(owner != address(0), "DDToken: approve from the zero address");
        require(spender != address(0), "DDToken: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    event Paused(address account);
    event Unpaused(address account);
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IWeightedPoolFactory.sol";
import "./interfaces/IWeightedPool.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWETH.sol";

import "./BaseContract.sol";
import "./DFMContract.sol";

contract LGEContract is IERC721Receiver, BaseContract {
    INonfungiblePositionManager internal immutable nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IVault internal immutable vault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address[] internal COINS = [WETH, DAI, WBTC, USDC];

    uint256 internal totalContirbution;
    mapping(address => uint256) internal contirbutions;

    uint256 internal univ3LpTokenId;
    uint256 internal uniLiquidity;
    uint256 internal uniLiquidityFund;

    address internal balancerPool;
    uint256[] internal balLiquidity = new uint256[](4);
    uint256 internal balLiquidityFund;

    bool private lgeClosed;
    uint256 private lockLpUntil;
    uint256 internal dfmStartTime;

    address internal rwd;

    function totalContirbuted() public view returns (uint256) {
        return totalContirbution;
    }

    function contributionOf(address account) public view returns (uint256) {
        return contirbutions[account];
    }

    modifier whenLgeAlive() {
        require(!lgeClosed, "DFM-Lge: has already closed");
        _;
    }

    modifier whenLpUnlocked() {
        require(block.timestamp > lockLpUntil, "DFM-Lge: locked for 6 months");
        _;
    }

    function concludeLge()
        public
        payable
        onlyOwner
        whenStartup
        whenLgeAlive
        returns (bool)
    {
        require(
            totalContirbution > 0 && address(this).balance > totalContirbution,
            "DFM-Lge: can't conclude with not enough balance"
        );
        lgeClosed = true;

        balLiquidityFund = (totalContirbution * 8) / 100;
        uniLiquidityFund = totalContirbution - balLiquidityFund;

        // provide liquidity to Uniswap with dd token
        _setupUniswapLiquidity();

        // provide weighted pool to Balancer V2
        _setupBalancerPool();

        lockLpUntil = block.timestamp + 180 * 1 days;

        emit LgeClosed(
            totalContirbution,
            uniLiquidityFund,
            balLiquidityFund,
            block.timestamp
        );
        dfmStartTime = block.timestamp;

        (bool success, ) = rwd.delegatecall(
            abi.encodeWithSignature("setDfmStartTime(uint256)", dfmStartTime)
        );
        require(success, "DFM-Lge: interaction with RewardsContract failed");

        return true;
    }

    function contribute() public payable whenLgeAlive returns (bool) {
        require(msg.value > 0, "DFM-Lge: can't contribute zero ether");

        address sender = _msgSender();
        uint256 amount = msg.value;

        totalContirbution += amount;
        contirbutions[sender] += amount;

        emit Contributed(sender, amount);

        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _setupUniswapLiquidity() private {
        uint256 ddAmount = IERC20(ddToken).balanceOf(address(this));
        IWETH(WETH).deposit{value: uniLiquidityFund}();

        // IERC20(ddToken).approve(address(uniswapRouter), ddAmount);
        // uniswapRouter.addLiquidityETH{value: uniLiquidityFund}(
        //     ddToken,
        //     ddAmount,
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp + 15
        // );

        IERC20(WETH).approve(
            address(nonfungiblePositionManager),
            uniLiquidityFund
        );
        IERC20(ddToken).approve(address(nonfungiblePositionManager), ddAmount);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: WETH,
                token1: ddToken,
                fee: 10000, // 1%
                tickLower: -887272,
                tickUpper: 887272,
                amount0Desired: uniLiquidityFund,
                amount1Desired: ddAmount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 15
            });

        (univ3LpTokenId, uniLiquidity, , ) = nonfungiblePositionManager.mint(
            params
        );
    }

    function _setupBalancerPool() private {
        uint256 share = balLiquidityFund / 4;
        IWETH(WETH).deposit{value: share}();

        address[] memory path = new address[](2);
        IERC20[] memory tokens = new IERC20[](4);
        uint256[] memory weights = new uint256[](4);
        IAsset[] memory assets = new IAsset[](4);

        path[0] = WETH;
        for (uint8 i = 0; i < 4; i++) {
            path[1] = COINS[i];
            balLiquidity[i] = COINS[i] == WETH
                ? share
                : uniswapRouter.swapExactETHForTokens{value: share}(
                    0,
                    path,
                    address(this),
                    block.timestamp + 15
                )[1];

            tokens[i] = IERC20(COINS[i]);
            weights[i] = 0.25e18;
            assets[i] = IAsset(COINS[i]);
        }

        IWeightedPoolFactory weightedPoolFactory = IWeightedPoolFactory(
            0x8E9aa87E45e92bad84D5F8DD1bff34Fb92637dE9
        );
        balancerPool = weightedPoolFactory.create(
            "DogeFundMe",
            "DFM",
            tokens,
            weights,
            0.04e16,
            address(this)
        );

        bytes memory userData = abi.encode(uint256(0), balLiquidity);
        IVault.JoinPoolRequest memory joinPoolRequest = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: balLiquidity,
            userData: userData,
            fromInternalBalance: false
        });
        for (uint8 i = 0; i < 4; i++) {
            tokens[i].approve(address(vault), balLiquidity[i]);
        }

        vault.joinPool(
            IWeightedPool(balancerPool).getPoolId(),
            address(this),
            address(this),
            joinPoolRequest
        );
    }

    event Contributed(address indexed from, uint256 amount);
    event LgeClosed(
        uint256 total,
        uint256 uniswap,
        uint256 balancer,
        uint256 time
    );
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IUniswapV2Router {
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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
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

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "./IAsset.sol";

interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IWeightedPool {
    function getPoolId() external view returns (bytes32);
    function setSwapFeePercentage(uint256 swapFeePercentage) external;
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
// import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}


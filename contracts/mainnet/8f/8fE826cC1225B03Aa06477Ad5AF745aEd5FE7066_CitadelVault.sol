// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libs/BaseRelayRecipient.sol";


interface ICitadelStrategy {
    function getCurrentPool() external view returns (uint256);
    function invest(uint256 _amount) external;
    function yield() external;
    function withdraw(uint256 _amount) external;
    function reimburse() external;
    function setAdmin(address _admin) external;
    function setStrategist(address _strategist) external;
    function emergencyWithdraw() external;
    function reinvest() external;
}

interface IRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface ICurveSwap {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external;
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract CitadelVault is ERC20("DAO Vault Citadel", "daoCDV"), Ownable, BaseRelayRecipient {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Token {
        IERC20 token;
        uint256 decimals;
        uint256 percKeepInVault;
    }

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ICitadelStrategy public strategy;
    IRouter private constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurveSwap private constant c3pool = ICurveSwap(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    uint256 private constant DENOMINATOR = 10000;

    address public pendingStrategy;
    bool public canSetPendingStrategy;
    uint256 public unlockTime;
    uint256 public constant LOCKTIME = 2 days;

    // Calculation for fees
    uint256[] public networkFeeTier2 = [50000*1e18+1, 100000*1e18];
    uint256 public customNetworkFeeTier = 1000000*1e18;
    uint256[] public networkFeePerc = [100, 75, 50];
    uint256 public customNetworkFeePerc = 25;
    uint256 public profitSharingFeePerc = 2000;
    uint256 private _fees; // 18 decimals

    // Address to collect fees
    address public treasuryWallet;
    address public communityWallet;
    address public admin;
    address public strategist;

    mapping(address => uint256) public _balanceOfDeposit; // Record deposit amount (USD in 18 decimals)
    mapping(uint256 => Token) private Tokens;

    event Deposit(address indexed tokenDeposit, address caller, uint256 amtDeposit, uint256 sharesMint);
    event Withdraw(address indexed tokenWithdraw, address caller, uint256 amtWithdraw, uint256 sharesBurn);
    event TransferredOutFees(uint256 fees);
    event ETHToInvest(uint256 _balanceOfWETH);
    event SetNetworkFeeTier2(uint256[] oldNetworkFeeTier2, uint256[] newNetworkFeeTier2);
    event SetNetworkFeePerc(uint256[] oldNetworkFeePerc, uint256[] newNetworkFeePerc);
    event SetCustomNetworkFeeTier(uint256 indexed oldCustomNetworkFeeTier, uint256 indexed newCustomNetworkFeeTier);
    event SetCustomNetworkFeePerc(uint256 oldCustomNetworkFeePerc, uint256 newCustomNetworkFeePerc);
    event SetProfitSharingFeePerc(uint256 indexed oldProfileSharingFeePerc, uint256 indexed newProfileSharingFeePerc);
    event MigrateFunds(address indexed fromStrategy, address indexed toStrategy, uint256 amount);

    modifier onlyAdmin {
        require(msg.sender == address(admin), "Only admin");
        _;
    }

    constructor(
        address _strategy, 
        address _treasuryWallet, address _communityWallet, 
        address _admin, address _strategist, 
        address _biconomy
    ) {
        strategy = ICitadelStrategy(_strategy);
        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        admin = _admin;
        strategist = _strategist;
        trustedForwarder = _biconomy;

        IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        Tokens[0] = Token(USDT, 6, 200);
        Tokens[1] = Token(USDC, 6, 200);
        Tokens[2] = Token(DAI, 18, 200);

        WETH.safeApprove(_strategy, type(uint256).max);
        WETH.safeApprove(address(router), type(uint256).max);
        USDT.safeApprove(address(router), type(uint256).max);
        USDT.safeApprove(address(c3pool), type(uint256).max);
        USDC.safeApprove(address(router), type(uint256).max);
        USDC.safeApprove(address(c3pool), type(uint256).max);
        DAI.safeApprove(address(router), type(uint256).max);
        DAI.safeApprove(address(c3pool), type(uint256).max);

        canSetPendingStrategy = true;
    }

    /// @notice Function that required for inherict BaseRelayRecipient
    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
        return BaseRelayRecipient._msgSender();
    }
    
    /// @notice Function that required for inherict BaseRelayRecipient
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    /// @notice Function to deposit stablecoins
    /// @param _amount Amount to deposit
    /// @param _tokenIndex Type of stablecoin to deposit
    function deposit(uint256 _amount, uint256 _tokenIndex) external {
        require(msg.sender == tx.origin || isTrustedForwarder(msg.sender), "Only EOA or Biconomy");
        require(_amount > 0, "Amount must > 0");

        uint256 _ETHPrice = _determineETHPrice(_tokenIndex);
        uint256 _pool = getAllPoolInETH(_ETHPrice);
        address _sender = _msgSender();
        Tokens[_tokenIndex].token.safeTransferFrom(_sender, address(this), _amount);
        uint256 _amtDeposit = _amount; // For event purpose
        if (Tokens[_tokenIndex].decimals == 6) {
            _amount = _amount.mul(1e12);
        }

        // Calculate network fee
        uint256 _networkFeePerc;
        if (_amount < networkFeeTier2[0]) {
            // Tier 1
            _networkFeePerc = networkFeePerc[0];
        } else if (_amount <= networkFeeTier2[1]) {
            // Tier 2
            _networkFeePerc = networkFeePerc[1];
        } else if (_amount < customNetworkFeeTier) {
            // Tier 3
            _networkFeePerc = networkFeePerc[2];
        } else {
            // Custom Tier
            _networkFeePerc = customNetworkFeePerc;
        }
        uint256 _fee = _amount.mul(_networkFeePerc).div(DENOMINATOR);
        _fees = _fees.add(_fee);
        _amount = _amount.sub(_fee);

        _balanceOfDeposit[_sender] = _balanceOfDeposit[_sender].add(_amount);
        uint256 _amountInETH = _amount.mul(_ETHPrice).div(1e18);
        uint256 _shares = totalSupply() == 0 ? _amountInETH : _amountInETH.mul(totalSupply()).div(_pool);

        _mint(_sender, _shares);
        emit Deposit(address(Tokens[_tokenIndex].token), _sender, _amtDeposit, _shares);
    }

    /// @notice Function to withdraw
    /// @param _shares Amount of shares to withdraw (from LP token, 18 decimals)
    /// @param _tokenIndex Type of stablecoin to withdraw
    function withdraw(uint256 _shares, uint256 _tokenIndex) external {
        require(msg.sender == tx.origin, "Only EOA");
        require(_shares > 0, "Shares must > 0");
        uint256 _totalShares = balanceOf(msg.sender);
        require(_totalShares >= _shares, "Insufficient balance to withdraw");

        // Calculate deposit amount
        uint256 _depositAmt = _balanceOfDeposit[msg.sender].mul(_shares).div(_totalShares);
        // Subtract deposit amount
        _balanceOfDeposit[msg.sender] = _balanceOfDeposit[msg.sender].sub(_depositAmt);

        // Calculate withdraw amount
        uint256 _ETHPrice = _determineETHPrice(_tokenIndex);
        uint256 _withdrawAmt = getAllPoolInETH(_ETHPrice).mul(_shares).div(totalSupply());
        _burn(msg.sender, _shares);
        uint256 _withdrawAmtInUSD = _withdrawAmt.mul(_getPriceFromChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419)).div(1e8); // ETH/USD
        Token memory _token = Tokens[_tokenIndex];
        uint256 _balanceOfToken = _token.token.balanceOf(address(this));
        // Change _balanceOfToken to 18 decimals same as _withdrawAmtInUSD
        if (_token.decimals == 6) {
            _balanceOfToken = _balanceOfToken.mul(1e12);
        }
        if (_withdrawAmtInUSD > _balanceOfToken) {
            // Not enough stablecoin in vault, need to get from strategy
            strategy.withdraw(_withdrawAmt);
            uint256[] memory _amounts = _swapExactTokensForTokens(WETH.balanceOf(address(this)), address(WETH), address(_token.token));
            // Change withdraw amount to 18 decimals if not DAI (for calculate profit sharing fee)
            _withdrawAmtInUSD = _token.decimals == 6 ? _amounts[1].mul(1e12) : _amounts[1];
        }

        // Calculate profit sharing fee
        if (_withdrawAmtInUSD > _depositAmt) {
            uint256 _profit = _withdrawAmtInUSD.sub(_depositAmt);
            uint256 _fee = _profit.mul(profitSharingFeePerc).div(DENOMINATOR);
            _withdrawAmtInUSD = _withdrawAmtInUSD.sub(_fee);
            _fees = _fees.add(_fee);
        }

        // Change back withdraw amount to 6 decimals if not DAI
        if (_token.decimals == 6) {
            _withdrawAmtInUSD = _withdrawAmtInUSD.div(1e12);
        }
        _token.token.safeTransfer(msg.sender, _withdrawAmtInUSD);
        emit Withdraw(address(Tokens[_tokenIndex].token), msg.sender, _withdrawAmtInUSD, _shares);
    }

    /// @notice Function to invest funds into strategy
    function invest() external onlyAdmin {
        Token memory _USDT = Tokens[0];
        Token memory _USDC = Tokens[1];
        Token memory _DAI = Tokens[2];

        // Transfer out network fees
        _fees = _fees.div(1e12); // Convert to USDT decimals
        if (_fees != 0 && _USDT.token.balanceOf(address(this)) > _fees) {
            uint256 _treasuryFee =  _fees.mul(2).div(5); // 40%
            _USDT.token.safeTransfer(treasuryWallet, _treasuryFee); // 40%
            _USDT.token.safeTransfer(communityWallet, _treasuryFee); // 40%
            _USDT.token.safeTransfer(strategist, _fees.sub(_treasuryFee).sub(_treasuryFee)); // 20%
            emit TransferredOutFees(_fees);
            _fees = 0;
        }

        uint256 _poolInUSD = getAllPoolInUSD().sub(_fees);

        // Calculation for keep portion of stablecoins and swap remainder to WETH
        uint256 _toKeepUSDT = _poolInUSD.mul(_USDT.percKeepInVault).div(DENOMINATOR);
        uint256 _toKeepUSDC = _poolInUSD.mul(_USDC.percKeepInVault).div(DENOMINATOR);
        uint256 _toKeepDAI = _poolInUSD.mul(_DAI.percKeepInVault).div(DENOMINATOR);
        _invest(_USDT.token, _toKeepUSDT);
        _invest(_USDC.token, _toKeepUSDC);
        _toKeepDAI = _toKeepDAI.mul(1e12); // Follow decimals of DAI
        _invest(_DAI.token, _toKeepDAI);

        // Invest all swapped WETH to strategy
        uint256 _balanceOfWETH = WETH.balanceOf(address(this));
        if (_balanceOfWETH > 0) {
            strategy.invest(_balanceOfWETH);
            emit ETHToInvest(_balanceOfWETH);
        }
    }

    /// @notice Function to swap stablecoin to WETH
    /// @param _token Stablecoin to swap
    /// @param _toKeepAmt Amount to keep in vault (decimals follow stablecoins)
    function _invest(IERC20 _token, uint256 _toKeepAmt) private {
        uint256 _balanceOfToken = _token.balanceOf(address(this));
        if (_balanceOfToken > _toKeepAmt) {
            _swapExactTokensForTokens(_balanceOfToken.sub(_toKeepAmt), address(_token), address(WETH));
        }
    }

    /// @notice Function to yield farms reward in strategy
    function yield() external onlyAdmin {
        strategy.yield();
    }

    /// @notice Function to swap stablecoin within vault with Curve
    /// @notice Amount to swap == amount to keep in vault of _tokenTo stablecoin
    /// @param _tokenFrom Type of stablecoin to be swapped
    /// @param _tokenTo Type of stablecoin to be received
    /// @param _amount Amount to be swapped (follow stablecoins decimals)
    function swapTokenWithinVault(uint256 _tokenFrom, uint256 _tokenTo, uint256 _amount) external onlyAdmin {
        require(Tokens[_tokenFrom].token.balanceOf(address(this)) > _amount, "Insufficient amount to swap");
        
        int128 i = _determineCurveIndex(_tokenFrom);
        int128 j = _determineCurveIndex(_tokenTo);
        c3pool.exchange(i, j, _amount, 0);
    }

    /// @notice Function to determine Curve index for swapTokenWithinVault()
    /// @param _tokenIndex Index of stablecoin
    /// @return stablecoin index use in Curve
    function _determineCurveIndex(uint256 _tokenIndex) private pure returns (int128) {
        if (_tokenIndex == 0) {
            return 2;
        } else if (_tokenIndex == 1) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice Function to reimburse keep Tokens from strategy
    /// @notice This function remove liquidity from all strategy farm and will cost massive gas fee. Only call when needed.
    function reimburseTokenFromStrategy() external onlyAdmin {
        strategy.reimburse();
    }

    /// @notice Function to withdraw all farms and swap to WETH in strategy
    function emergencyWithdraw() external onlyAdmin {
        strategy.emergencyWithdraw();
    }

    /// @notice Function to reinvest all WETH back to farms in strategy
    function reinvest() external onlyAdmin {
        strategy.reinvest();
    }

    /// @notice Function to swap between tokens with Uniswap
    /// @param _amountIn Amount to swap
    /// @param _fromToken Token to be swapped
    /// @param _toToken Token to be received
    /// @return _amounts Array that contain amount swapped
    function _swapExactTokensForTokens(uint256 _amountIn, address _fromToken, address _toToken) private returns (uint256[] memory _amounts) {
        address[] memory _path = new address[](2);
        _path[0] = _fromToken;
        _path[1] = _toToken;
        uint256[] memory _amountsOut = router.getAmountsOut(_amountIn, _path);
        if (_amountsOut[1] > 0) {
            _amounts = router.swapExactTokensForTokens(_amountIn, 0, _path, address(this), block.timestamp);
        } else {
            // Not enough amount to swap
            uint256[] memory _zeroReturn = new uint256[](2);
            _zeroReturn[0] = 0;
            _zeroReturn[1] = 0;
            return _zeroReturn;
        }
    }

    /// @notice Function to set new network fee for deposit amount tier 2
    /// @param _networkFeeTier2 Array that contains minimum and maximum amount of tier 2 (18 decimals)
    function setNetworkFeeTier2(uint256[] calldata _networkFeeTier2) external onlyOwner {
        require(_networkFeeTier2[0] != 0, "Minimun amount cannot be 0");
        require(_networkFeeTier2[1] > _networkFeeTier2[0], "Maximun amount must greater than minimun amount");
        /**
         * Network fees have three tier, but it is sufficient to have minimun and maximun amount of tier 2
         * Tier 1: deposit amount < minimun amount of tier 2
         * Tier 2: minimun amount of tier 2 <= deposit amount <= maximun amount of tier 2
         * Tier 3: amount > maximun amount of tier 2
         */
        uint256[] memory oldNetworkFeeTier2 = networkFeeTier2;
        networkFeeTier2 = _networkFeeTier2;
        emit SetNetworkFeeTier2(oldNetworkFeeTier2, _networkFeeTier2);
    }

    /// @notice Function to set new custom network fee tier
    /// @param _customNetworkFeeTier Amount of new custom network fee tier (18 decimals)
    function setCustomNetworkFeeTier(uint256 _customNetworkFeeTier) external onlyOwner {
        require(_customNetworkFeeTier > networkFeeTier2[1], "Custom network fee tier must greater than tier 2");

        uint256 oldCustomNetworkFeeTier = customNetworkFeeTier;
        customNetworkFeeTier = _customNetworkFeeTier;
        emit SetCustomNetworkFeeTier(oldCustomNetworkFeeTier, _customNetworkFeeTier);
    }

    /// @notice Function to set new network fee percentage
    /// @param _networkFeePerc Array that contains new network fee percentage for tier 1, tier 2 and tier 3
    function setNetworkFeePerc(uint256[] calldata _networkFeePerc) external onlyOwner {
        require(
            _networkFeePerc[0] < 3000 &&
                _networkFeePerc[1] < 3000 &&
                _networkFeePerc[2] < 3000,
            "Network fee percentage cannot be more than 30%"
        );
        /**
         * _networkFeePerc content a array of 3 element, representing network fee of tier 1, tier 2 and tier 3
         * For example networkFeePerc is [100, 75, 50]
         * which mean network fee for Tier 1 = 1%, Tier 2 = 0.75% and Tier 3 = 0.5%
         */
        uint256[] memory oldNetworkFeePerc = networkFeePerc;
        networkFeePerc = _networkFeePerc;
        emit SetNetworkFeePerc(oldNetworkFeePerc, _networkFeePerc);
    }

    /// @notice Function to set new custom network fee percentage
    /// @param _percentage Percentage of new custom network fee
    function setCustomNetworkFeePerc(uint256 _percentage) public onlyOwner {
        require(_percentage < networkFeePerc[2], "Custom network fee percentage cannot be more than tier 2");

        uint256 oldCustomNetworkFeePerc = customNetworkFeePerc;
        customNetworkFeePerc = _percentage;
        emit SetCustomNetworkFeePerc(oldCustomNetworkFeePerc, _percentage);
    }

    /// @notice Function to set new profit sharing fee percentage
    /// @param _percentage Percentage of new profit sharing fee
    function setProfitSharingFeePerc(uint256 _percentage) external onlyOwner {
        require(_percentage < 3000, "Profile sharing fee percentage cannot be more than 30%");

        uint256 oldProfitSharingFeePerc = profitSharingFeePerc;
        profitSharingFeePerc = _percentage;
        emit SetProfitSharingFeePerc(oldProfitSharingFeePerc, _percentage);
    }

    /// @notice Function to set new treasury wallet address
    /// @param _treasuryWallet Address of new treasury wallet
    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    /// @notice Function to set new community wallet address
    /// @param _communityWallet Address of new community wallet
    function setCommunityWallet(address _communityWallet) external onlyOwner {
        communityWallet = _communityWallet;
    }

    /// @notice Function to set new admin address
    /// @param _admin Address of new admin
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        strategy.setAdmin(_admin);
    }

    /// @notice Function to set new strategist address
    /// @param _strategist Address of new strategist
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == owner(), "Not authorized");

        strategist = _strategist;
        strategy.setStrategist(_strategist);
    }

    /// @notice Function to set pending strategy address
    /// @param _pendingStrategy Address of pending strategy
    function setPendingStrategy(address _pendingStrategy) external onlyOwner {
        require(canSetPendingStrategy, "Cannot set pending strategy now");

        pendingStrategy = _pendingStrategy;
    }

    /// @notice Function to set new trusted forwarder address (Biconomy)
    /// @param _biconomy Address of new trusted forwarder
    function setBiconomy(address _biconomy) external onlyOwner {
        trustedForwarder = _biconomy;
    }

    /// @notice Function to set percentage of stablecoins that keep in vault
    /// @param _percentages Array with new percentages of stablecoins that keep in vault
    function setPercTokenKeepInVault(uint256[] memory _percentages) external onlyAdmin {
        Tokens[0].percKeepInVault = _percentages[0];
        Tokens[1].percKeepInVault = _percentages[1];
        Tokens[2].percKeepInVault = _percentages[2];
    }

    /// @notice Function to unlock migrate funds function
    function unlockMigrateFunds() external onlyOwner {
        unlockTime = block.timestamp.add(LOCKTIME);
        canSetPendingStrategy = false;
    }

    /// @notice Function to migrate all funds from old strategy contract to new strategy contract
    function migrateFunds() external onlyOwner {
        require(unlockTime <= block.timestamp && unlockTime.add(1 days) >= block.timestamp, "Function locked");
        require(WETH.balanceOf(address(strategy)) > 0, "No balance to migrate");
        require(pendingStrategy != address(0), "No pendingStrategy");

        uint256 _amount = WETH.balanceOf(address(strategy));
        WETH.safeTransferFrom(address(strategy), pendingStrategy, _amount);

        // Set new strategy
        address oldStrategy = address(strategy);
        strategy = ICitadelStrategy(pendingStrategy);
        pendingStrategy = address(0);
        canSetPendingStrategy = true;

        // Approve new strategy
        WETH.safeApprove(address(strategy), type(uint256).max);
        WETH.safeApprove(oldStrategy, 0);

        unlockTime = 0; // Lock back this function
        emit MigrateFunds(oldStrategy, address(strategy), _amount);
    }

    /// @notice Function to get all pool amount(vault+strategy) in USD (use USDT/ETH as price feed)
    /// @return All pool in USD (6 decimals follow USDT)
    function getAllPoolInUSD() public view returns (uint256) {
        uint256 _currentETHprice = _getPriceFromChainlink(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46); // USDT/ETH
        uint256 _currentUSDprice = _getPriceFromChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD
        return getAllPoolInETH(_currentETHprice).mul(_currentUSDprice).div(1e20);
    }

    /// @notice Same as getAllPoolInETH() above with parameter
    /// @param _price ETH price from ChainLink (USDT/ETH)
    /// @return All pool in ETH (18 decimals)
    function getAllPoolInETH(uint256 _price) public view returns (uint256) {
        uint256 _vaultPoolInETH = _getVaultPoolInUSD().mul(_price);
        return strategy.getCurrentPool().add(_vaultPoolInETH);
    }

    /// @notice Function to get exact USD amount of pool in vault
    /// @return Exact USD amount of pool in vault (no decimals)
    function _getVaultPoolInUSD() private view returns (uint256) {
        uint256 _vaultPoolInUSD = (Tokens[0].token.balanceOf(address(this)).mul(1e12))
            .add(Tokens[1].token.balanceOf(address(this)).mul(1e12))
            .add(Tokens[2].token.balanceOf(address(this)))
            .sub(_fees);
            // In very rare case that fees > vault pool, above calculation will raise error
            // Use getReimburseTokenAmount() to get some stablecoin from strategy
        return _vaultPoolInUSD.div(1e18);
    }

    /// @notice Function to get price from ChainLink contract
    /// @param _priceFeedProxy Address of ChainLink contract that provide price
    /// @return Price (8 decimals for USD, 18 decimals for ETH)
    function _getPriceFromChainlink(address _priceFeedProxy) private view returns (uint256) {
        IChainlink _pricefeed = IChainlink(_priceFeedProxy);
        int256 _price = _pricefeed.latestAnswer();
        return uint256(_price);
    }

    /// @notice Function to determine ETH price based on stablecoin
    /// @param _tokenIndex Type of stablecoin to determine
    /// @return Price of ETH (18 decimals)
    function _determineETHPrice(uint256 _tokenIndex) private view returns (uint256) {
        address _priceFeedContract;
        if (address(Tokens[_tokenIndex].token) == 0xdAC17F958D2ee523a2206206994597C13D831ec7) { // USDT
            _priceFeedContract = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46; // USDT/ETH
        } else if (address(Tokens[_tokenIndex].token) == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) { // USDC
            _priceFeedContract = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4; // USDC/ETH
        } else { // DAI
            _priceFeedContract = 0x773616E4d11A78F511299002da57A0a94577F1f4; // DAI/ETH
        }
        return _getPriceFromChainlink(_priceFeedContract);
    }

    /// @notice Function to get amount need to fill up minimum amount keep in vault
    /// @param _tokenIndex Type of stablecoin requested
    /// @return Amount to reimburse (USDT, USDC 6 decimals, DAI 18 decimals)
    function getReimburseTokenAmount(uint256 _tokenIndex) public view returns (uint256) {
        Token memory _token = Tokens[_tokenIndex];
        uint256 _toKeepAmt = getAllPoolInUSD().mul(_token.percKeepInVault).div(DENOMINATOR);
        if (_token.decimals == 18) {
            _toKeepAmt = _toKeepAmt.mul(1e12);
        }
        uint256 _balanceOfToken = _token.token.balanceOf(address(this));
        if (_balanceOfToken < _toKeepAmt) {
            return _toKeepAmt.sub(_balanceOfToken);
        }
        return 0; // amount keep in vault is full
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier:MIT
pragma solidity 0.7.6;

import "../interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}


// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./StrategyDevil.sol";
interface IPool {
    function balanceOfUnderlying(address account) external returns (uint256);
    function mint(uint256 mintAmount) external;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
}
interface IFarm {
    function claimComp(address holder) external;
}
contract StrategyDevil_Scream is StrategyDevil {
    address public poolAddress;
    uint256 public wantSupplyTotal = 0;
    uint256 public wantBorrowedTotal = 0;
    uint256 public borrowRate;
    uint256 public borrowRateMax;
    uint256 public borrowDepth;
    uint256 constant public borrowDepthMax = 10;
    uint256 public minLeverageAmt;
    constructor(
        address[] memory _addresses,
        address[] memory _tokenAddresses,
        address[] memory _earnedToNATIVEPath,
        address[] memory _earnedToToken0Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _earnedToWFTMPath,
        uint256 _depositFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _entranceFeeFactor,
        uint256 _borrowRate,
        uint256 _borrowRateMax,
        uint256 _borrowDepth,
        uint256 _minLeverageAmt
    ) public {
        nativeFarmAddress = _addresses[0];
        farmContractAddress = _addresses[1];
        govAddress = _addresses[2];
        uniRouterAddress = _addresses[3];
        buybackRouterAddress = _addresses[4];
        poolAddress = _addresses[5];
        NATIVEAddress = _tokenAddresses[0];
        wftmAddress = _tokenAddresses[1];
        wantAddress = _tokenAddresses[2];
        earnedAddress = _tokenAddresses[3];
        token0Address = _tokenAddresses[4];
        isAutoComp = true;
        isSingleVault = true;
        earnedToNATIVEPath = _earnedToNATIVEPath;
        earnedToToken0Path = _earnedToToken0Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        earnedToWFTMPath = _earnedToWFTMPath;
        WFTMToNATIVEPath = [wftmAddress, NATIVEAddress];
        depositFeeFactor = _depositFeeFactor;
        withdrawFeeFactor = _withdrawFeeFactor;
        entranceFeeFactor = _entranceFeeFactor;
        borrowRate = _borrowRate;
        borrowRateMax = _borrowRateMax;
        borrowDepth = _borrowDepth;
        minLeverageAmt = _minLeverageAmt;
        IERC20(wantAddress).safeApprove(poolAddress, uint256(-1));
        transferOwnership(nativeFarmAddress);
    }
    function deposit(address _userAddress, uint256 _wantAmt) 
        public
        virtual
        override
        onlyOwner
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        updateBalances();
        
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );
        // If depositFee in set, than _wantAmt - depositFee
        if (depositFeeFactor < depositFeeFactorMax) {
            _wantAmt = _wantAmt.mul(depositFeeFactor).div(depositFeeFactorMax);
        }
        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0 && sharesTotal > 0) {
            sharesAdded = _wantAmt
                .mul(sharesTotal)
                .mul(entranceFeeFactor)
                .div(wantLockedTotal)
                .div(entranceFeeFactorMax);
        }
        sharesTotal = sharesTotal.add(sharesAdded);
        
        _farm();
        return sharesAdded;
    }
    function _farm() internal override {
        _leverage(IERC20(wantAddress).balanceOf(address(this)));
        
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        // IERC20(wantAddress).safeIncreaseAllowance(poolAddress, wantAmt);
        IPool(poolAddress).mint(wantAmt);
        updateBalances();
    }
    function _leverage(uint256 _amount) internal {
        if (_amount >= minLeverageAmt) {
            for (uint i = 0; i < borrowDepth; i++) {
                // IERC20(wantAddress).safeIncreaseAllowance(poolAddress, _amount);
                IPool(poolAddress).mint(_amount);
                _amount = _amount.mul(borrowRate).div(100);
                IPool(poolAddress).borrow(_amount);
            }
        }
    }
    function _unfarm(uint256 _wantAmt) internal override {
        if (_wantAmt == 0) {
            IFarm(farmContractAddress).claimComp(address(this));
        } else {
            uint256 wantBal = IERC20(wantAddress).balanceOf(address(this));
            uint256 borrowBal = IPool(poolAddress).borrowBalanceCurrent(address(this));
            while (wantBal < borrowBal) {
                if (wantBal > 0) {
                    // IERC20(wantAddress).safeIncreaseAllowance(poolAddress, wantBal);
                    IPool(poolAddress).repayBorrow(wantBal);
                }
                borrowBal = IPool(poolAddress).borrowBalanceCurrent(address(this));
                uint256 targetSupply = borrowBal.mul(100).div(borrowRate);
            
                uint256 supplyBal = IPool(poolAddress).balanceOfUnderlying(address(this));
                IPool(poolAddress).redeemUnderlying(supplyBal.sub(targetSupply));
                wantBal = IERC20(wantAddress).balanceOf(address(this));
            }
            // IERC20(wantAddress).safeIncreaseAllowance(poolAddress, wantBal);
            IPool(poolAddress).repayBorrow(uint256(-1));
            uint256 tokenBal = IERC20(poolAddress).balanceOf(address(this));
            IPool(poolAddress).redeem(tokenBal);
            updateBalances();
        }
    }
    function withdraw(address _userAddress, uint256 _wantAmt)
        public
        override
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");
        updateBalances();
        _unfarm(_wantAmt);
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantAmt);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }
        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(withdrawFeeFactorMax);
        }
        IERC20(wantAddress).safeTransfer(nativeFarmAddress, _wantAmt);
        _farm(); 
        return sharesRemoved;
    }
    function earn() public override nonReentrant whenNotPaused {
        // Harvest farm tokens
        _harvest();
        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        earnedAmt = distributeFees(earnedAmt);
        earnedAmt = buyBack(earnedAmt);
    
        if (earnedAddress != wantAddress) {
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                earnedAmt
            );
            // Swap earned to want
            _safeSwap(
                uniRouterAddress,
                earnedAmt,
                slippageFactor,
                earnedToToken0Path,
                address(this),
                now + routerDeadlineDuration
            );
        }
        lastEarnBlock = block.number;
        _farm();
    }
    function updateBalances() public {
        wantSupplyTotal = IPool(poolAddress).balanceOfUnderlying(address(this));
        wantBorrowedTotal = IPool(poolAddress).borrowBalanceCurrent(address(this));
        wantLockedTotal = wantSupplyTotal - wantBorrowedTotal;
    }
    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external onlyAllowGov {
        require(_borrowRate <= borrowRateMax, "!rate");
        require(_borrowDepth <= borrowDepthMax, "!depth");
        _unfarm(1);
        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;
        _farm();
    }
    function convertDustToEarned() public override {}
}
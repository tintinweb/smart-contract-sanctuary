// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

contract StratX2_CHERRY is StratX2 {
    address[] public users;
    mapping(address => uint256) public userLastDepositedTimestamp;

    event earned(uint256 oldWantLockedTotal, uint256 newWantLockedTotal);

    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool[] memory _flags,
        address[] memory _earnedToCHERRYPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _distributionRatio,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        cherryFarmAddress = _addresses[2];
        CHERRYAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5]; //pair 1
        token1Address = _addresses[6]; //pair 2
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _flags[0];
        isSameAssetDeposit = _flags[1];
        isCherryComp = _flags[2];
        isVaultComp = _flags[3];

        uniRouterAddress = _addresses[9];
        earnedToCHERRYPath = _earnedToCHERRYPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        buyBackAddress = _addresses[11];
        depositFeeFundAddress = _addresses[12];
        delegateFundAddress = _addresses[13];
        entranceFeeFactor = _entranceFeeFactor;
        distributionDepositRatio = _distributionRatio;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(cherryFarmAddress);
    }

    function deposit(address _userAddress, uint256 _wantAmt)
        public
        override
        onlyOwner
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        if (userLastDepositedTimestamp[_userAddress] == 0) {
            users.push(_userAddress);
        }
        userLastDepositedTimestamp[_userAddress] = block.timestamp;


        if (entranceFeeFactor > 0) {
            uint256 wantAmt = _wantAmt.mul(entranceFeeFactor).div(entranceFeeFactorMax);
            uint256 depositFee = _wantAmt.sub(wantAmt);

            uint256 rewardDepositFee = depositFee.mul(distributionDepositRatio).div(10000);
            depositFee = depositFee.sub(rewardDepositFee);
            IERC20(wantAddress).safeTransferFrom(
                address(msg.sender),
                depositFeeFundAddress,
                depositFee
            );
            IERC20(wantAddress).safeTransferFrom(
                address(msg.sender),
                rewardsAddress,
                rewardDepositFee
            );

            _wantAmt = wantAmt;
        }
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0 && sharesTotal > 0) {
            sharesAdded = _wantAmt
                .mul(sharesTotal)
                .div(wantLockedTotal);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        wantLockedTotal = IERC20(wantAddress).balanceOf(address(this));

        return sharesAdded;
    }

    function withdraw(address _userAddress, uint256 _wantAmt)
        public
        override
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(
                withdrawFeeFactorMax
            );
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20(wantAddress).safeTransfer(cherryFarmAddress, _wantAmt);

        return sharesRemoved;
    }

    function _farm() internal override {}

    function _unfarm(uint256 _wantAmt) internal override {}

    function earn() public override nonReentrant whenNotPaused {
        // require(isAutoComp, "!isAutoComp");
        if (onlyGov) {
            require(msg.sender == govAddress, "!gov");
        }

        if (earnedAddress == wbnbAddress) {
            _wrapBNB();
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (isVaultComp) {
            // earnedAmt = distributeFees(earnedAmt);   // Not need to distribute fees again. Already done.

            IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                earnedAmt
            );
            _safeSwap(
                uniRouterAddress,
                earnedAmt,
                slippageFactor,
                earnedToCHERRYPath,
                address(this),
                block.timestamp.add(600)
            );

            lastEarnBlock = block.number;

            uint256 wantLockedTotalOld = wantLockedTotal;

            wantLockedTotal = IERC20(CHERRYAddress).balanceOf(address(this));
            emit earned(wantLockedTotalOld, wantLockedTotal);
        } else {
            uint256 fee = earnedAmt.mul(controllerFee).div(controllerFeeMax);
            uint256 fund = earnedAmt.sub(fee);
            IERC20(earnedAddress).safeTransfer(delegateFundAddress, fund);
            IERC20(earnedAddress).safeTransfer(rewardsAddress, fee);
        }
    }

    function userLength() public view returns (uint256) {
        return users.length;
    }

    receive() external payable {}
}
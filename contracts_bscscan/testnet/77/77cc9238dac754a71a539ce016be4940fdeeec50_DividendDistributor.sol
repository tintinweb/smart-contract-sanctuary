// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBabyBananaNFT.sol";
import "./ISelmaNFT.sol";
import "./IBEP20.sol";
import "./IApe.sol";

contract DividendDistributor {
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 constant BANANA = IBEP20(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95);
    IBEP20 constant GNANA = IBEP20(0xdDb3Bd8645775F59496c821E4F55A7eA6A6dc299);
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;
    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;

    IBabyBananaNFT public babyBananaNFT = IBabyBananaNFT(0x143Fab4Ddb74Ca18026946D3e67Dd51C201A7657);
    ISelmaNFT public selmaNFT = ISelmaNFT(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);
    address public museum = 0xD5E81e25bB36A94d64Eb844b905546Ff8f29DB8D;

    IApeRouter public router = IApeRouter(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);
    IApeTreasury public treasury = IApeTreasury(0xec4b9d1fd8A3534E31fcE1636c7479BcD29213aE);

    address immutable token;
    address[] shareHolders;
    uint256 currentIndex;

    mapping (address => Share) public shares;
    mapping (address => uint256) public totalDistributed;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public gasLimit = 500000;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 35 / 100 * (10 ** 18);

    uint8 constant NOT_ENTERED = 1;
    uint8 constant ENTERED = 2;
    uint8 status = NOT_ENTERED;
    
    event DividendDistributed(address indexed to, uint256 amount);

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == MULTI_SIG_TEAM_WALLET);
        _;
    }

    modifier onlyTokenOrMarketing() {
        require(msg.sender == token || msg.sender == MARKETING_WALLET);
        _;
    }

    modifier nonReentrant() {
        require(status != ENTERED, "Reentrant call");
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    constructor () {
        token = msg.sender;
    }

    // IDividendDistributor

    function deposit() external payable onlyTokenOrMarketing {
        uint256 balanceBefore = BANANA.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(BANANA);

        router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BANANA.balanceOf(address(this)) - balanceBefore;

        totalDividends += amount;
        dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        uint256 multiplier = babyBananaNFT.featureValueOf(4, shareholder);
        uint256 boostAmount = amount * multiplier / 10000;
        
        if (boostAmount == 0) {
            if (selmaNFT.balanceOf(shareholder, 0) > 0) { boostAmount = amount * 5 / 100; }
            if (selmaNFT.balanceOf(shareholder, 2) > 0) { boostAmount = amount / 10; }
        }

        uint256 boostedAmount = amount + boostAmount;

        totalShares = totalShares - shares[shareholder].amount + boostedAmount;
        shares[shareholder].amount = boostedAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function process() external onlyToken {
        uint256 shareholderCount = shareHolders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        uint256 avgGasCost;
        uint256 iterations;

        while(gasUsed + avgGasCost < gasLimit && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareHolders[currentIndex])){
                distributeDividend(shareHolders[currentIndex]);
            }

            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
            avgGasCost = gasUsed / iterations;
        }
    }

    function updateBabyBananaNFT(address newAddress) external onlyToken {
		babyBananaNFT = IBabyBananaNFT(newAddress);
	}

    function updateSelmaNFT(address newAddress) external onlyToken {
		selmaNFT = ISelmaNFT(newAddress);
	}

    function updateRouter(address _router) external onlyToken {
        router = IApeRouter(_router);
    }
    
    function updateDividendAccuracyFactor(uint256 newValue) external onlyToken {
        dividendsPerShareAccuracyFactor = newValue;
    }

    // Public

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    // Private
    
    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private nonReentrant {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            address rewardAddress = babyBananaNFT.rewardTokenFor(shareholder);

            if (shareholder == museum || rewardAddress == address(GNANA)) {
                distributeGnana(amount, shareholder);
            } else if (rewardAddress == address(BANANA)) {
                totalDistributed[address(BANANA)] += amount;
                BANANA.transfer(shareholder, amount);
            } else {
                distributeReward(rewardAddress, amount, shareholder);
            }
            
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            emit DividendDistributed(shareholder, amount);
        }
    }

    function distributeGnana(uint256 bananaAmount, address shareholder) private {
        BANANA.approve(address(treasury), bananaAmount);

        uint256 balanceBefore = GNANA.balanceOf(address(this));
        treasury.buy(bananaAmount);
        uint256 gnanaAmount = GNANA.balanceOf(address(this)) - balanceBefore;

        if (gnanaAmount > 0) {
            totalDistributed[address(GNANA)] += gnanaAmount;
            GNANA.transfer(shareholder, gnanaAmount);
        }
    }

    function distributeReward(address rewardAddress, uint256 bananaAmount, address shareholder) private {
        IBEP20 rewardToken = IBEP20(rewardAddress);
        BANANA.approve(address(router), bananaAmount);
        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = address(BANANA);
        path[1] = router.WETH();
        path[2] = rewardAddress;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bananaAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = rewardToken.balanceOf(address(this)) - balanceBefore;

        if (balanceAfter > 0) {
            totalDistributed[rewardAddress] += balanceAfter;
            rewardToken.transfer(shareholder, balanceAfter);
        }
    }

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareHolders.length;
        shareHolders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareHolders[shareholderIndexes[shareholder]] = shareHolders[shareHolders.length-1];
        shareholderIndexes[shareHolders[shareHolders.length-1]] = shareholderIndexes[shareholder];
        shareHolders.pop();
    }

    // Maintenance

    function updateMuseum(address _museum) external onlyTeam {
        museum = _museum;
    }

    function updateTreasury(address _treasury) external onlyTeam {
        treasury = IApeTreasury(_treasury);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyTeam {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setGasLimit(uint256 gas) external onlyTeam {
        require(gas < 750000);
        gasLimit = gas;
    }

    function updateStatus(uint8 newStatus) external onlyTeam {
        status = newStatus;
    }
}
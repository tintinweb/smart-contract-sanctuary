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
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;
    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;

    IBabyBananaNFT public constant BABYBANANA_NFT = IBabyBananaNFT(0x986462937DE0B064364631c9b72A15ac8cc76678);
    ISelmaNFT public constant SELMA_NFT = ISelmaNFT(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);
    address public constant MUSEUM = 0x88C16087254824394b64144B51070B2f26e283f5;

    IApeRouter public constant ROUTER = IApeRouter(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);
    IApeTreasury public treasury = IApeTreasury(0xec4b9d1fd8A3534E31fcE1636c7479BcD29213aE);
    uint256 constant treasuryTimelock = 4 weeks;
    uint256 immutable _deployedAt;

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
    uint256 public dividendsPerShareAccuracyFactor = 10**18;

    uint256 public gasLimit = 500000;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 35 * 10**17;
    
    event DividendDistributed(address indexed to, uint256 amount);
    event Deposit(uint256 amount);
    event SetShare(address indexed account, uint256 amount);
    event Process();
    event UpdateTreasury(address treasury);
    event SetDistributionCriteria(uint256 period, uint256 amount);
    event SetGasLimit(uint256 gas);

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

    constructor () {
        token = msg.sender;
        _deployedAt = block.timestamp;
    }

    // IDividendDistributor

    function deposit() external payable onlyTokenOrMarketing {
        if (msg.value > 0) {
            uint256 balanceBefore = BANANA.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = ROUTER.WETH();
            path[1] = address(BANANA);

            ROUTER.swapExactETHForTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = BANANA.balanceOf(address(this)) - balanceBefore;

            totalDividends += amount;
            dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;

            emit Deposit(msg.value);
        }
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

        uint256 boostAmount;
        uint256 nftBoostAmount = nftShareBoost(shareholder, amount);
        uint256 selmaBoostAmount = selmaShareBoost(shareholder, amount);

        if (nftBoostAmount >= selmaBoostAmount) {
            boostAmount = nftBoostAmount;
        } else {
            boostAmount = selmaBoostAmount;
        }

        uint256 boostedAmount = amount + boostAmount;

        totalShares = totalShares - shares[shareholder].amount + boostedAmount;
        shares[shareholder].amount = boostedAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

        emit SetShare(shareholder, boostedAmount);
    }

    function nftShareBoost(address account, uint256 shareAmount) private view returns (uint256) {
        try BABYBANANA_NFT.featureValueOf(4, account) returns (uint256 rewardMultiplier) {
            if (rewardMultiplier > 10000) { rewardMultiplier = 10000; }
            return shareAmount * rewardMultiplier / 10000;
        } catch {
            return 0;
        }
    }

    function selmaShareBoost(address account, uint256 shareAmount) private view returns (uint256) {
        uint256 boostAmount;

        try SELMA_NFT.balanceOf(account, 0) returns (uint256 goldBalance) {
            if (goldBalance > 0) { boostAmount = shareAmount * 5 / 100; }
        } catch {}

        try SELMA_NFT.balanceOf(account, 2) returns (uint256 diamondBalance) {
            if (diamondBalance > 0) { boostAmount = shareAmount / 10; }
        } catch {}

        return boostAmount;
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

        emit Process();
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

    function distributeDividend(address shareholder) private {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            (address rewardAddress, address rewardPair) = rewardTokenFor(shareholder);
            if (rewardAddress == token) { rewardAddress = address(BANANA); }

            if (shareholder == MUSEUM || rewardAddress == address(GNANA)) {
                distributeGnana(amount, shareholder);
            } else if (rewardAddress == address(BANANA)) {
                totalDistributed[address(BANANA)] += amount;
                BANANA.transfer(shareholder, amount);
            } else {
                distributeReward(rewardAddress, rewardPair, amount, shareholder);
            }

            emit DividendDistributed(shareholder, amount);
        }
    }

    function rewardTokenFor(address account) private view returns (address, address) {
        try BABYBANANA_NFT.rewardTokenFor(account) returns (address tokenAddress, address pair) {
            return (tokenAddress, pair);
        } catch {
            return (address(BANANA), WBNB);
        }
    }

    function distributeGnana(uint256 bananaAmount, address shareholder) private {
        BANANA.approve(address(treasury), bananaAmount);

        uint256 balanceBefore = GNANA.balanceOf(address(this));

        try treasury.buy(bananaAmount) {
            uint256 gnanaAmount = GNANA.balanceOf(address(this)) - balanceBefore;
            if (gnanaAmount > 0) {
                totalDistributed[address(GNANA)] += gnanaAmount;
                GNANA.transfer(shareholder, gnanaAmount);
            }
        } catch {}
    }

    function distributeReward(
        address rewardAddress,
        address rewardPair,
        uint256 bananaAmount,
        address shareholder
    ) private {
        BANANA.approve(address(ROUTER), bananaAmount);
        address[] memory path = getPath(rewardAddress, rewardPair);

        try ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bananaAmount,
            0,
            path,
            shareholder,
            block.timestamp
        ) {
            totalDistributed[rewardAddress] += bananaAmount;
        } catch {}
    }

    function getPath(address rewardAddress, address rewardPair) private pure returns (address[] memory) {
        address[] memory path;
        
        if (rewardAddress == ROUTER.WETH()) {
            path = new address[](2);
            path[0] = address(BANANA);
            path[1] = ROUTER.WETH();
        } else if (rewardPair == ROUTER.WETH()) {
            path = new address[](3);
            path[0] = address(BANANA);
            path[1] = ROUTER.WETH();
            path[2] = rewardAddress;
        } else {
            path = new address[](4);
            path[0] = address(BANANA);
            path[1] = ROUTER.WETH();
            path[2] = rewardPair;
            path[3] = rewardAddress;
        }

        return path;
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

    function updateTreasury(address _treasury) external onlyTeam {
        require(_deployedAt + treasuryTimelock <= block.timestamp, "Function is time locked");
        
        treasury = IApeTreasury(_treasury);
        emit UpdateTreasury(_treasury);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyTeam {
        require(_minPeriod <= 1 weeks && _minDistribution <= 1 ether, "Invalid parameters");
        
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        emit SetDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setGasLimit(uint256 gas) external onlyTeam {
        require(gas <= 750000 && gas >= 100000);
        
        gasLimit = gas;
        emit SetGasLimit(gas);
    }
}
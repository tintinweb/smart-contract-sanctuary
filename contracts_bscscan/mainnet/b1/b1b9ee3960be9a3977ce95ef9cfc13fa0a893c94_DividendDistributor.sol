// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IBEP20.sol";
import "./IDEX.sol";

contract DividendDistributor {
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 constant BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IDEXRouter public constant ROUTER = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address immutable token;
    address[] shareHolders;
    uint256 currentIndex;

    mapping (address => Share) public shares;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**18;

    uint256 public gasLimit = 300000;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 10**18;
    
    event Deposit(uint256 amount);
    event SetShare(address indexed account, uint256 amount);
    event Process();
    event DividendDistributed(address indexed to, uint256 amount);
    event SetDistributionCriteria(uint256 period, uint256 amount);
    event SetGasLimit(uint256 newGas, uint256 oldGas);

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    constructor () {
        token = msg.sender;
    }

    // Token interface

    function deposit() external payable onlyToken {
        if (msg.value > 0) {
            address[] memory path = new address[](2);
            path[0] = ROUTER.WETH();
            path[1] = address(BUSD);

            uint256 balanceBefore = BUSD.balanceOf(address(this));
            ROUTER.swapExactETHForTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 receivedAmount = BUSD.balanceOf(address(this)) - balanceBefore;

            totalDividends += receivedAmount;
            dividendsPerShare += dividendsPerShareAccuracyFactor * receivedAmount / totalShares;

            emit Deposit(msg.value);
        }
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

        emit SetShare(shareholder, amount);
    }

    function process() external onlyToken {
        uint256 shareholderCount = shareHolders.length;
        if (shareholderCount == 0) { return; }

        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        uint256 avgGasCost;
        uint256 iterations;

        while (gasUsed + avgGasCost < gasLimit && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) { currentIndex = 0; }

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
        if (shares[shareholder].amount == 0) { return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }
        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    // Private
    
    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private {
        if (shares[shareholder].amount == 0) { return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            totalDistributed += amount;
            BUSD.transfer(shareholder, amount);

            emit DividendDistributed(shareholder, amount);
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

    function setDistributionCriteria(uint256 newPeriod, uint256 newMinDistribution) external onlyToken {
        require(newPeriod <= 1 weeks && newMinDistribution <= 1 ether, "Invalid parameters");
        minPeriod = newPeriod;
        minDistribution = newMinDistribution;
        emit SetDistributionCriteria(newPeriod, newMinDistribution);
    }

    function setGasLimit(uint256 newGasLimit) external onlyToken {
        require(newGasLimit <= 500000 && newGasLimit >= 100000);
        emit SetGasLimit(newGasLimit, gasLimit);
        gasLimit = newGasLimit;
    }
}
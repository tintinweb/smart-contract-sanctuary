//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./Dividends.sol";

contract CanadaCoin is BaseErc20, Taxable, Dividends {
    using SafeMath for uint256;

    constructor () {
        configure(msg.sender);

        symbol = "TESTES";
        name = "TESTEYTESTERSON";
        decimals = 9;

        // Pancake Swap
        //address pancakeSwap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET
        address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        dividendDistributor = new DividendDistributor(address(taxDistributor));


        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(dividendDistributor)] = true;
        taxDistributor.createWalletTax("Community", 200, 300, 0xb03486943A6d3Eb6D8BCb5183c2c3577e59b575C, true);
        taxDistributor.createWalletTax("Marketing", 200, 300, 0x546337fce11cD0E0fda0bAb6C9f18EEAd2aF2562, true);
        taxDistributor.createDividendTax("Reward", 300, 500, dividendDistributorAddress(), true);
        taxDistributor.createLiquidityTax("Liquidity", 300, 300);
        autoSwapTax = true;


        // Dividends
        dividendDistributorGas  = 500_000;
        excludedFromDividends[pair] = true;
        excludedFromDividends[address(taxDistributor)] = true;
        excludedFromDividends[address(dividendDistributor)] = true;
        autoDistributeDividends = true;


        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _totalSupply = _totalSupply.add(1_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides

    function configure(address _owner) internal override(Taxable, Dividends, BaseErc20) {
        super.configure(_owner);
    }

    function preTransfer(address from, address to, uint256 value) override(Taxable, BaseErc20) internal {
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        super.preTransfer(from, to, value);
    }

    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }

    function postTransfer(address from, address to) override(Dividends, BaseErc20) internal {
        super.postTransfer(from, to);
    }


    // Admin methods

}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address private _token;
    address private _distributor;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;
    mapping (address => uint256) private shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 15);

    bool public override inSwap;

    uint256 private currentIndex;

    event DividendsDistributed(uint256 amountDistributed);

    modifier onlyToken() {
        require(msg.sender == _token, "can only be called by the parent token");
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == _distributor, "can only be called by the tax distributor");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address distributor) {
        _token = msg.sender;
        _distributor = distributor;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositNative() external payable override onlyDistributor {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }


    function depositToken(address, uint256) external override view onlyDistributor {
        require(false, "Cannot distribute tokens");
    }

    function process(uint256 gas) external override onlyToken swapLock {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 distributed;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributed += distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        emit DividendsDistributed(distributed);
    }

    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private returns (uint256){
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
        return amount;
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}
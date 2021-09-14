/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter {
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

}

interface IDOSCi {
    function readAuthorizedAddress(address sender) external view returns (address);
    function readEndChangeTime(address sender) external view returns (uint);
    function RegisterCall(address sender, string memory scname, string memory funcname) external returns(bool);
}

contract CommunityIDO {
    
    // democratic IDO
    address public addressDOSC;
    address public LastAuthorizedAddress;
    uint public LastChangingTime;
    
    // uint 
    uint256 public end = 0; //
    uint256 public duration = 592200; // 7 days
    uint256 public LENNYSold = 50000000000; // how much LENNY we pre-sale
    uint256 public availableInvestment = 30000000; // maximum BUSD we want in exchange
    uint256 public InvestmentBalance = 0; // current investment in BUSD in SC
    uint8 public minPurchase = 20; //

    uint public LENNYProvided = 50000000000; // how much LENNY we provide in the LP
    uint public initialLiquidityToken = 0; // LT received after adding the liquidity in PancakeSwap
    uint public currentLiquidityToken = 0; // LT after redistribution
    uint public LPTokenToRedistribute = 0; // LT avaible to be redistributed

    uint public contractClaimId = 0; // 
    uint public ClaimIdDev = 0; //

    bool public liquidityDeployment = false; //

    address public addressLENNY; //
    address public addressBUSD; //
    address public pancakeSwapRouter; //
    address public pancakeSwapFactory; //
    address public pairAddress; //


    // Investment information
    struct Investor {
        address investor;
        uint amountBUSD;
        bool tokensWithdrawn;
        uint claimId;
    }

    struct Claim {
        uint claimId;
        uint claimPercentage;
        uint amountClaimedLPToken;
        uint date;
    }

    mapping(address => Investor) private _investments;
    mapping(uint => Claim) private _claims;
    
    event InvestmentsConfirmed (address investor, uint amountBUSD);

    function CheckInvestorInfo(address account) external view returns(Investor memory){
        return _investments[account];
    }

    function CheckClaimInfo(uint claimNumber) external view returns(Claim memory){
        return _claims[claimNumber];
    }

    function addLennyAddress(address lennyadd) external Demokratia() preIDO() {
        addressLENNY = lennyadd;
    }

    function start() external Demokratia() preIDO() {
        end = block.timestamp + duration;
    }


    function possibleInvestmentPerAddress(uint _current) view internal activeIDO() returns(uint256) {

        uint256 _investmentPossible;

        if(InvestmentBalance <= 1000000){
            _investmentPossible = 10000 - _current;
        }

        if(InvestmentBalance > 1000000 && InvestmentBalance<= 3000000){
            _investmentPossible = 20000 - _current;
        }

        if(InvestmentBalance > 3000000 && InvestmentBalance<= 6000000){
            _investmentPossible = 40000 - _current;
        }

        if(InvestmentBalance > 6000000 && InvestmentBalance<= 10000000){
            _investmentPossible = 60000 - _current;
        }

        if(InvestmentBalance > 10000000 && InvestmentBalance<= 15000000){
            _investmentPossible = 80000 - _current;
        }

        if(InvestmentBalance > 15000000){
            _investmentPossible = 100000 - _current;
        }
        
        return(_investmentPossible);

    }

    function buy(uint busd) external activeIDO() {

        require(availableInvestment>0, "No more Lenny for sales");
        require(busd >= minPurchase, 'You have to invest at least 20BUSD');

        // Verify that the sender has enough busd

        IERC20 busdSC = IERC20(addressBUSD);

        uint busdDecimals = busd * 10 ** busdSC.decimals();
        uint _balanceBUSD = busdSC.balanceOf(_msgSender());
        require(_balanceBUSD>=busdDecimals, "Not enough BUSD in this wallet");
        
        // Verify that the sender does not exceed the 
        Investor storage  _currentInvestment = _investments[_msgSender()];
        uint _addressAvailableInvestment = possibleInvestmentPerAddress(_currentInvestment.amountBUSD);
        require(_addressAvailableInvestment >= minPurchase, "You already reached the maximum investment with this address");
        
        // compute the amount ok token the sender can buy
        uint tokenAmount = _addressAvailableInvestment;
        if(tokenAmount > availableInvestment){
            tokenAmount = availableInvestment;
        }

        uint totalInvested = tokenAmount + _currentInvestment.amountBUSD;
        
        uint tokenAmountDecimals = tokenAmount * 10 ** busdSC.decimals();

        // proceed to the transfer
        busdSC.transferFrom(_msgSender(), address(this), tokenAmountDecimals);

        // update investment information
        _investments[_msgSender()] = Investor(_msgSender(), totalInvested, false, 0);

        // update th
        InvestmentBalance += tokenAmount;
        availableInvestment -= tokenAmount;
        
        emit InvestmentsConfirmed(_msgSender(), tokenAmount);
    }

    function _computeAmountLenny(uint256 _invested) view private postIDO() returns(uint256){
        uint256 amountLenny = _invested / InvestmentBalance * LENNYSold;
        return(amountLenny);
    }

    function withdrawLENNY() public postIDO() {
        
        require(liquidityDeployment==true, 'liquidity pool is not yet created');
        Investor storage investment = _investments[_msgSender()];
        
        require(investment.amountBUSD > 0, 'only investors');
        require(investment.tokensWithdrawn == false, 'tokens already withdrawned');

        IERC20 lennySC = IERC20(addressLENNY);

        uint totalLenny = _computeAmountLenny(investment.amountBUSD);
        uint totalLennyDecimals = totalLenny * 10 ** lennySC.decimals();

        lennySC.transfer(investment.investor, totalLennyDecimals);
        investment.tokensWithdrawn = true;
    }

    function createLiquidityPool () external postIDO() Demokratia() {
        
        require(liquidityDeployment==false, 'Liquidity Pool already created');

        IPancakeFactory factorySC = IPancakeFactory(pancakeSwapFactory);

        pairAddress = factorySC.createPair(addressLENNY, addressBUSD);
        
        IPancakeRouter routerSC = IPancakeRouter(pancakeSwapRouter);

        uint totalBUSD = InvestmentBalance;
        uint totalLENNY = LENNYProvided;

        uint time = block.timestamp + 300;
        
        (totalLENNY, totalBUSD, initialLiquidityToken) = routerSC.addLiquidity(
            addressLENNY, addressBUSD,
            totalLENNY, totalBUSD,
            totalLENNY, totalBUSD,
            address(this),
            time
        );

        currentLiquidityToken = initialLiquidityToken;

        liquidityDeployment = true;
    }

    function distributeLPToken (uint distributionPercentage) public postIDO() Demokratia(){

        require(distributionPercentage<=10, 'you can only remove the liquidity at a maximum of 10% at a time');

        uint LPTokenToRemove = distributionPercentage * initialLiquidityToken / 100;

        if (LPTokenToRemove > currentLiquidityToken){
            LPTokenToRemove = currentLiquidityToken;
        }

        LPTokenToRedistribute += LPTokenToRemove;

        contractClaimId += 1;

        _claims[contractClaimId] = Claim(contractClaimId, distributionPercentage, LPTokenToRedistribute, block.timestamp);
    }

    function amountToClaimDev(uint _token) private view postIDO() returns(uint){
        uint amount_withdraw = 2 * _token / 5 ;
        return amount_withdraw;
    }

    function claimTokensDev () external postIDO() Demokratia() {
        require(ClaimIdDev < contractClaimId, 'dev team already got the claims');
        
        // identify the claim id
        uint newClaim = ClaimIdDev + 1;
        Claim storage claimDev = _claims[newClaim];

        // detrmine the amount for the dev Team
        uint LPTokenToClaimDev = amountToClaimDev(claimDev.amountClaimedLPToken);

        // send the LP token to the dev team personal address
        IERC20 LPTokenSC = IERC20(pairAddress);
        
        uint LPTokenToClaimDevDecimals = LPTokenToClaimDev * 10 ** LPTokenSC.decimals();
        LPTokenSC.transfer(_msgSender(), LPTokenToClaimDevDecimals);

        LPTokenToRedistribute -= LPTokenToClaimDev;
        ClaimIdDev = newClaim;
    }

    function amountToClaim(uint _invested, uint _token) private view postIDO() returns(uint){
        uint amount_withdraw = 3 * _token  / 5 * _invested / InvestmentBalance;
        return amount_withdraw;
    }

    function claimTokens () external postIDO() {
        
        Investor storage investment = _investments[_msgSender()];
        require(investment.amountBUSD > 0, 'only investors');
        require(investment.claimId < contractClaimId, 'You already got your claims');
        
        // identify the claim id
        uint newClaim = investment.claimId + 1;
        Claim storage claim = _claims[newClaim];
        
        // detrmine the amount to claim
        uint LPTokenToClaim = amountToClaim(investment.amountBUSD, claim.amountClaimedLPToken);

        // send the LP token to the dev team personal address
        IERC20 LPTokenSC = IERC20(pairAddress);
       
        uint LPTokenToClaimDecimals = LPTokenToClaim * 10 ** LPTokenSC.decimals();
        LPTokenSC.transfer(_msgSender(), LPTokenToClaimDecimals);

        // update state variables
        LPTokenToRedistribute -= LPTokenToClaim;
        _investments[_msgSender()].claimId = newClaim;

    }

    function removeInvestment () external postIDOFailed() {
        
        Investor storage investment = _investments[_msgSender()];

        require(investment.amountBUSD > 0, 'only investors');
        require(investment.tokensWithdrawn == false, 'tokens already withdrawned');
        
        IERC20 busdSC = IERC20(addressBUSD);
        uint amountDecimals = investment.amountBUSD * 10 ** busdSC.decimals();
        busdSC.transfer(investment.investor, amountDecimals);

        investment.tokensWithdrawn = true;
    }

    // Context
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // Democratic Ownership
    function UpdateSC () external {
        IDOSCi dosc = IDOSCi(addressDOSC);
        LastAuthorizedAddress = dosc.readAuthorizedAddress(_msgSender());
        LastChangingTime = dosc.readEndChangeTime(_msgSender());
    }

    modifier Demokratia() {
        require(LastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(LastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }

    // IDO Periods
    modifier preIDO() {
        require(end == 0, 'Community IDO should not be active');
        _;
    }

    modifier activeIDO() {
        require(end > 0 && block.timestamp < end &&  availableInvestment > 0, 'Community IDO must be active');
        _;
    }

    modifier postIDO() {
        require(end > 0 && (block.timestamp >= end || availableInvestment == 0), 'Community IDO must have ended');
        require(InvestmentBalance >= 1000000);
        _;
    }

    modifier postIDOFailed() {
        require(end > 0 && (block.timestamp >= end || availableInvestment == 0), 'Community IDO must have ended');
        require(InvestmentBalance < 1000000);
        _;
    }

    constructor() {
        // address of the
        addressBUSD = 0xe1c28f90a2A1749295411f0B85cb54297593bfcd;
        addressDOSC = 0xC3cd6Fa8C135dC53BA927AfD8D8FC07e6Bdd288A;
        pancakeSwapRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        pancakeSwapFactory = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    }
}
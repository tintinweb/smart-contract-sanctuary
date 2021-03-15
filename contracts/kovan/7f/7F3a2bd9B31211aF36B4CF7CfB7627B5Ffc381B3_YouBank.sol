pragma solidity ^0.6.0;
import "./interface/IPool.sol";
import "./interface/IAssetsManageTeam.sol";
import "./interface/IReturnInvestmentLpartner.sol";
import "./interface/ICreator.sol";
import "./interface/IRoleModel.sol";
import "./interface/IOracle.sol";
import "./access/TeamRole.sol";
import "./utils/EnumerableSet.sol";
import "./interface/IERC20.sol";
import "./math/SafeMath.sol";
contract YouBank is TeamRole, IRoleModel {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    event CreatePool(address pool);
    event AddPool(address pool);
    event UpdatePool(address pool);
    address private _creatorInvestPool;// The address of the contract that creates the Investment Pool
    IAssetsManageTeam private _assetsManageTeam;// Smart contract for request deposit
    IReturnInvestmentLpartner private _returnInvestmentLpartner;// Smart contract for return investment
    IOracle _oracleContract;// Oracle contract address
    EnumerableSet.AddressSet private _addressesPools;// Collection of all pool addresses
    mapping(address => uint256) private _investedFunds;
    mapping(address => uint256) private _returnedFunds;
    mapping(address => uint256) private _poolValues;
    uint256 private _poolValuesTotal;
    mapping(address => uint256) private _poolValuesUSD;
    uint256 private _poolValuesUSDTotal;
    function createPool(string memory name, uint256 lockPeriod, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, address superAdmin, address gPartner, address lPartner, address startupTeam) public onlyTeam returns (bool) {
        ICreator _creatorContract = ICreator(_creatorInvestPool);
        address _investPool = _creatorContract.createPool(name, lockPeriod, depositFixedFee, referralDepositFee, anualPrecent, penaltyEarlyWithdraw, superAdmin, gPartner, lPartner, startupTeam);
        _addressesPools.add(_investPool);
        emit CreatePool(_investPool);
        return true;
    }
    function addPool(address poolAddress) public onlyTeam returns (bool) {
        _addressesPools.add(poolAddress);
        _assetsManageTeam.addManager(poolAddress);
        emit AddPool(poolAddress);
        return true;
    }
    function updatePool(address pool, string memory name, bool publicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw) public onlyTeam returns (bool) {
        IPool(pool)._updatePool(name, publicPool, token, locked, depositFixedFee, referralDepositFee, anualPrecent, penaltyEarlyWithdraw);
        emit UpdatePool(pool);
        return true;
    }
    function setPriceToken(address pool, uint256 rate) external onlyTeam returns (bool) {
        IPool(pool)._setRate(rate);
        return true;
    }
    function setTeamReward(address pool, uint256 teamReward) external onlyTeam returns (bool) {
        IPool(pool)._setTeamReward(teamReward);
        return true;
    }
    event DepositTokenToPool(address pool, uint256 amount);
    function depositTokenToPool(address pool, uint256 amount) public returns (bool) {
        IPool(pool)._depositTokenPoolRegistry(msg.sender, amount);
        emit DepositTokenToPool(pool,amount);
        return true;
    }
    event WithdrawToStartupTeam(address pool, uint256 amount);
    function withdrawToStartupTeam(address pool, uint256 amount) public returns (bool) {
        IPool(pool)._withdrawTeam(msg.sender, amount);
        emit WithdrawToStartupTeam(pool,amount);
        return true;
    }
    function requestStartupTeam(bool withdraw, address pool, uint256 maxValue) public returns (bool) {
        return _assetsManageTeam._request(withdraw, pool, msg.sender, maxValue);
    }
    function approveReqStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._approve(pool, team, msg.sender);
    }
    function disapproveReqStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._disapprove(pool, team, msg.sender);
    }
    function lockStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._lock(pool, team, msg.sender);
    }
    function unlockStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._unlock(pool, team, msg.sender);
    }
    function getDepositPool(address pool, address owner, uint256 index) public view returns (uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, uint256 lenghtDeposit, address investedToken)
    {
        (amount, time, lock_period, refund_authorize, amountWithdrawal,investedToken) = IPool(pool).getDeposit(owner, index);
        uint256 lenghtDepSender = IPool(pool).getDepositLength(msg.sender);
        return (amount, time, lock_period, refund_authorize,amountWithdrawal,lenghtDepSender,investedToken);
    }
    function getPerformedOperationsTeamStartup(address pool, address owner, uint256 index) public view returns (address token, uint256 amountToken, uint256 withdrawAmount, uint256 time)
    {
        (token, amountToken, withdrawAmount, time) = _assetsManageTeam.getPerformedOperations(pool, owner, index);
        return (token, amountToken, withdrawAmount, time);
    }
    function getRequestsTeam(address pool) public view returns (address[] memory) {
        return _assetsManageTeam.getRequests(pool);
    }
    function getApprovalReqTeam(address pool) public view returns (address[] memory) {
        return _assetsManageTeam.getApproval(pool);
    }
    function getRequestTeamAddress(address pool, address team) public view returns (bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue)
    {
        (lock, maxValueToken, madeValueToken, maxValue, madeValue) = _assetsManageTeam.getRequestTeamAddress(pool, team);
        return (lock, maxValueToken, madeValueToken, maxValue, madeValue);
    }
    function getApproveTeamAddress(address pool, address team) public view returns (bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue)
    {
        (lock, maxValueToken, madeValueToken, maxValue, madeValue) = _assetsManageTeam.getApproveTeamAddress(pool, team);
        return (lock, maxValueToken, madeValueToken, maxValue, madeValue);
    }
    event SetReferral(address pool, address lPartner,address referral,bool result);
    function setReferral(address pool, address lPartner, address referral) public returns (bool) {
        require(IPool(pool).hasRole(LIMITED_PARTNER_ROLE, lPartner), "PoolRegistry: parameter Lpartner has no role LPartner");
        bool result = IPool(pool)._setReferral(msg.sender, lPartner, referral);
        emit SetReferral(pool,lPartner,referral,result);
        return result;
    }
    function getReferral(address pool, address lPartner) public view returns (address) {
        return IPool(pool).getReferral(lPartner);
    }
    function requestReturnInvestmentLpartner(address pool, uint256 index, uint256 amount,address token) public returns (bool) {
        return _returnInvestmentLpartner._request(pool, msg.sender, index, amount, token);
    }
    function approveReturnInvestmentLpartner(address pool, address lPartner) public returns (bool) {
        return _returnInvestmentLpartner._approve(pool, lPartner, msg.sender);
    }
    event WithdrawLPartner(address pool, address lPartner,bool result);
    function withdrawLPartner(address pool) public returns (bool) {
        bool result;
        uint256 totalAmountReturn;
        address token;
        (result,totalAmountReturn,token) = IPool(pool)._withdrawLPartner(msg.sender);
        if (result) {
            _returnedFunds[token] = _returnedFunds[token] + totalAmountReturn;
        }
        emit WithdrawLPartner(pool,msg.sender,result);
        return result;
    }
    function disapproveReturnInvestmentLpartner(address pool, address lPartner) public returns (bool)
    {
        return _returnInvestmentLpartner._disapprove(pool, lPartner, msg.sender);
    }
    function getAddrRequestsReturnInvesLpartner(address pool) public view returns (address[] memory)
    {
        return _returnInvestmentLpartner.getRequests(pool);
    }
    function getRequestsReturnInvestLpartner(address pool, address lPartner) public view returns (uint256[] memory)
    {
        return _returnInvestmentLpartner.getRequestsLpartner(pool, lPartner);
    }
    function getInvestedFunds(address token) public view returns (uint256)
    {
        return _investedFunds[token];
    }
    function getReturnedFunds(address token) public view returns (uint256)
    {
        return _returnedFunds[token];
    }
    uint256 constant private mulitpierDefault = 100000;
    function feesMulitpier(address sender) public view returns (uint256) {
        uint256 balanceProjectTokensForSender = _balanceTokenForTokensale(sender);
        uint256 mulitpier = mulitpierDefault;
        if (balanceProjectTokensForSender > 0) {
            uint256 initialProjectTokensInPool = 10 ** uint256(18) * 80000 ;//_balanceTokenForTokensale(address(this));
            mulitpier = balanceProjectTokensForSender.mul(mulitpierDefault).div(initialProjectTokensInPool).add(mulitpierDefault);
        }
        return mulitpier;
    }
    event DepositToPool(address sender, uint256 amount);
    function depositToPool(address payable pool) public payable returns (bool) {
        uint256 amount = msg.value;
        pool.transfer(amount);
        IPool(pool)._depositPoolRegistry(msg.sender, amount, feesMulitpier(msg.sender));
        _investedFunds[address(0)] = _investedFunds[address(0)] + amount;
        emit DepositToPool(msg.sender,amount);
        return true;
    }
    event ReturnsFromStartupTeam(address sender, uint256 amount);
    function returnsFromStartupTeam(address payable pool) public payable returns (bool) {
        require(IPool(pool).hasRole(STARTUP_TEAM_ROLE, msg.sender), "PoolRegistry: sender has no role TeamStartup");
        pool.transfer(msg.value);
        emit ReturnsFromStartupTeam(msg.sender,msg.value);
        return true;
    }
    function activateDepositToPool(address pool) public onlyTeam returns (bool) {
        return IPool(pool)._activateDepositToPool();
    }
    function disactivateDepositToPool(address pool) public onlyTeam returns (bool) {
        return IPool(pool)._disactivateDepositToPool();
    }
    function grantRoleInvestmentPool(address pool, bytes32 role, address account) public returns (bool) {
        require(IPool(pool).hasRole(SUPER_ADMIN_ROLE, msg.sender), "PoolRegistry: sender has no role GPartner");
        IPool(pool).grantRole(role, account);
        return true;
    }
    function revokeRoleInvestmentPool(address pool, bytes32 role, address account) public returns (bool) {
        require(IPool(pool).hasRole(SUPER_ADMIN_ROLE, msg.sender), "PoolRegistry: sender has no role GPartner");
        IPool(pool).revokeRole(role, account);
        return true;
    }
    function setAddressCreatorInvestPool(address creatorContract) public onlyTeam returns (bool) {
        _creatorInvestPool = creatorContract;
        return true;
    }
    function setAssetManageTeamContract(IAssetsManageTeam addrContract) public onlyTeam returns (bool)
    {
        _assetsManageTeam = addrContract;
        return true;
    }
    function setReturnInvestmentLpartner(IReturnInvestmentLpartner addrContract) public onlyTeam returns (bool)
    {
        _returnInvestmentLpartner = addrContract;
        return true;
    }
    function setOracleContract(IOracle _oracle) public onlyTeam returns (bool) {
        _oracleContract = _oracle;
        return true;
    }
    function getPools() public view returns (address[] memory) {
        return _addressesPools.collection();
    }
    function getInfoPool(address pool) public view returns (string memory name, bool isPublicPool, address token, uint256 locked)
    {
        (name, isPublicPool, token, locked) = IPool(pool).getInfoPool();
        return (name, isPublicPool, token, locked);
    }
    function getInfoPoolFees(address pool) public view returns (uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee)
    {
        (rate ,depositFixedFee , referralDepositFee, anualPrecent , penaltyEarlyWithdraw, totalInvestLpartner, premiumFee) = IPool(pool).getInfoPoolFees();
        return (rate, depositFixedFee, referralDepositFee, anualPrecent, penaltyEarlyWithdraw, totalInvestLpartner, premiumFee);
    }
    function getAssetManageTeamContract() public view returns (IAssetsManageTeam) {
        return _assetsManageTeam;
    }
    function getReturnInvesmentLpartner() public view returns (IReturnInvestmentLpartner) {
        return _returnInvestmentLpartner;
    }
    function getOracleContract() public view returns (IOracle) {
        return _oracleContract;
    }
    function getAddressesRolesPool(address pool, bytes32 role) public view returns (address[] memory)
    {
        return IPool(pool).getMembersRole(role);
    }
    function getAddressCreatorInvestPool() public view returns (address) {
        return _creatorInvestPool;
    }
    function getPoolValues(address pool) public view returns (uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue, uint256 poolValuesTotal, uint256 poolValuesUSDTotal) {
        (poolValueUSD, poolValue, proofOfValue) = IPool(pool).getPoolValues();
        return (poolValueUSD,poolValue,proofOfValue,_poolValuesTotal,_poolValuesUSDTotal);
    }
    event SetPoolValues(address pool,uint256 poolValueUSD, uint256 poolValue, string proofOfValue, bool result);
    function setPoolValues(address pool,uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue) public returns (bool) {
        require(IPool(pool).hasRole(SUPER_ADMIN_ROLE, msg.sender), "PoolRegistry: sender has no role SUPER_ADMIN_ROLE");
        _poolValues[pool] = poolValue;
        _poolValuesUSD[pool] = poolValueUSD;
        bool result = IPool(pool)._setPoolValues(poolValueUSD,poolValue,proofOfValue);
        uint256 poolValueUSDNewTotal;
        uint256 poolValueNewTotal;
        address [] memory pools = getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 poolValueUSDforSum;
            uint256 poolValueforSum;
            (poolValueUSDforSum, poolValueforSum, ) = IPool(pools[i]).getPoolValues();
            poolValueUSDNewTotal += poolValueUSDforSum;
            poolValueNewTotal += poolValueforSum;
        }
        if (poolValueNewTotal > 0) {
            _poolValuesTotal = poolValueNewTotal;
        }
        if (poolValueUSDNewTotal > 0) {
            _poolValuesUSDTotal = poolValueUSDNewTotal;
        }
        emit SetPoolValues(pool,poolValueUSD,poolValue,proofOfValue,result);
        return result;
    }
    function getPoolPairReserves(address pool) public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address token0, address token1, address weth,uint price0CumulativeLast,uint price1CumulativeLast)
    {
        return IPool(pool).getPoolPairReserves();
    }
    event DepositInvestmentInTokensToPool(address pool,uint256 amount, address token);
    function _depositInvestmentInTokensToPoolCalculationReferral (address referalAddress, uint256 amount, uint256 referralDepositFee) private view returns (uint256) {
        uint256 depositFeeReferrer = 0;
        if (referalAddress != address(0)) {
            depositFeeReferrer = amount.mul(referralDepositFee).div(100); // zero referral fees for zero address
        }
        return depositFeeReferrer;
    }
    function _depositInvestmentInTokensToPoolCalculation (uint256 depositFixedFee,uint256 referralDepositFee, uint256 amount, address referalAddress, uint256 mulitpier) private view returns (uint256,uint256,uint256){
        uint256 depositFee = amount.mul(depositFixedFee).div(100).mul(mulitpier).div(mulitpierDefault);
        uint256 depositFeeReferrer = _depositInvestmentInTokensToPoolCalculationReferral(referalAddress, amount, referralDepositFee).mul(mulitpier).div(mulitpierDefault);
        uint256 finalAmount = amount.sub(depositFee);
        if (depositFeeReferrer > 0) {
            finalAmount = finalAmount.sub(depositFeeReferrer);
        }
        return (finalAmount,depositFee,depositFeeReferrer);
    }
    function depositInvestmentInTokensToPool(address pool, uint256 amount, address token) public returns (bool) {
        require(amount > 0, "depositInvestmentInTokensToPool: the number of sent token is 0");
        uint256 depositFixedFee = 0;
        uint256 referralDepositFee = 0;
        (, depositFixedFee, referralDepositFee, , , , ) = IPool(pool).getInfoPoolFees();
        address payable team = payable(getTeamAddresses()[1]);
        address referalAddress = IPool(pool).getReferral(msg.sender);
        uint256 depositFee = 0;
        uint256 depositFeeReferrer = 0;
        uint256 finalAmount = 0;
        (finalAmount,depositFee,depositFeeReferrer) = _depositInvestmentInTokensToPoolCalculation(depositFixedFee, referralDepositFee, amount, referalAddress, feesMulitpier(msg.sender));
        IERC20(token).transferFrom(msg.sender, pool, finalAmount);
        IERC20(token).transferFrom(msg.sender, team, depositFee);
        if (depositFeeReferrer > 0) {
            IERC20(token).transferFrom(msg.sender, payable(referalAddress), depositFeeReferrer);
        }
        IPool(pool)._depositInvestmentInTokensToPool(msg.sender,amount,token);
        _investedFunds[token] = _investedFunds[token] + amount;
        emit DepositInvestmentInTokensToPool(pool,amount,token);
        return true;
    }
    event WithdrawInTokensToStartupTeam(address pool,uint256 amount, address token);
    function withdrawInTokensToStartupTeam(address pool,address token, uint256 amount) public returns (bool) {
        IPool(pool)._withdrawTokensToStartup(msg.sender,token, amount);
        emit WithdrawInTokensToStartupTeam(pool,amount,token);
        return true;
    }
    function requestTokensWithdwawalFromStartup(address pool, address token, uint256 maxValue) public returns (bool) {
        return _assetsManageTeam._requestTokensWithdwawalFromStartup(pool,token, msg.sender, maxValue);
    }
    function approveTokensWithdwawalFromStartup(address pool, address token, address team) public returns (bool) {
        return _assetsManageTeam._approveTokensWithdwawalFromStartup(pool,token,team,msg.sender);
    }
    event ReturnsInTokensFromTeam(address pool,uint256 amount, address token);
    function returnsInTokensFromTeam(address payable pool,address token, uint256 amount) public returns (bool) {
        IPool(pool)._returnsInTokensFromTeam(msg.sender,token,amount);
        emit ReturnsInTokensFromTeam(pool,amount,token);
        return true;
    }
    function withdrawSuperAdmin(address pool, address token, uint256 amount) public returns (bool) {
        return IPool(pool)._withdrawSuperAdmin(msg.sender, token, amount);
    }
    function getCustomPrice(address aggregator) public view returns (uint256,uint8) {
        return _oracleContract.getCustomPrice(aggregator);
    }
    mapping(address => uint256) private _investorsReceivedMainTokenLatestDate;
    event ClaimFreeProjectTokens(address pool, uint256 lastRewardTimestamp, uint256 poolValuesUSDTotal, uint256 balanceLeavedOnThisContractProjectTokens, uint256 amountTotalUSD, bool newInvestor, uint256 tokensToPay, uint256 poolValuesUSDTotalInUSD, uint256 percentOfTAV);
    function _tokenForTokensale() private view returns (IERC20) {
        address tokenForTokensale;
        (,,tokenForTokensale,) = IPool(getPools()[0]).getInfoPool();
        return IERC20(tokenForTokensale);
    }
    function _balanceTokenForTokensale(address forAddress) private view returns (uint256) {
        return _tokenForTokensale().balanceOf(forAddress);
    }
    function _tokensToDistribute(uint256 amountTotalUSD, bool newInvestor) private view returns (uint256,uint256) {
        uint256 balanceLeavedOnThisContractProjectTokens = _balanceTokenForTokensale(address (this));/* if TAV < 500k, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 1%   if TAV >  $500k and TAV < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 3% if TAV >  $500k and TAV < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 10% */
        if (_poolValuesUSDTotal.div(10 ** uint256(18)) < 500000) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(100);
        } else if (_poolValuesUSDTotal.div(10 ** uint256(18)) < 5000000) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(30);
        } else {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10);
        } /*  amountTotalUSD / TAV - his percent of TAV balanceLeavedOnThisContractProjectTokens * his percent of pool = amount of tokens to pay if (newInvestor) amount of tokens to pay = amount of tokens to pay * 1.1 _investorsReceivedMainToken[msg.sender][time] = amount of tokens to pay*/
        uint256 poolValuesUSDTotalInUSD = _poolValuesUSDTotal.div(10 ** uint256(18));
        uint256 percentOfTAV = amountTotalUSD.mul(10000).div(poolValuesUSDTotalInUSD);
        if (newInvestor) {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfTAV).div(10000).mul(11).div(10),percentOfTAV);
        } else {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfTAV).div(10000),percentOfTAV);
        }
    }
    function investorUsdValue(address pool,address investor) public view returns (uint256,bool) {
        uint256 amountTotalUSD;
        bool newInvestor = false;
        uint256 lenghtSender = IPool(pool).getDepositLength(investor);
        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = _oracleContract.getLatestPrice();
        for (uint256 i = 0; i < lenghtSender; i++) {
            newInvestor = false;
            uint256 amountWei;          // Amount of funds deposited
            uint256 time;            // Deposit time
            address investedToken; // address(0) for ETH/BNB
            (amountWei, time, , , , ) = IPool(pool).getDeposit(investor, i);
            (, , , , , investedToken) = IPool(pool).getDeposit(investor, i);
            uint256 timeToCompareWithNow = time + 4 weeks; // must hold at least 4 weeks
            if (now > timeToCompareWithNow) {// new investors hold more than 4 weeks
                if (now < time + 8 weeks) { // check if new investors hold less than 8 weeks
                    newInvestor = true;// new investor
                }
                if (investedToken != address(0)) {
                    amountTotalUSD += amountWei.div(10 ** uint256(18)); // invested in BUSD
                } else {
                    amountTotalUSD += amountWei.mul(priceMainToUSDreturned).div(10 ** uint256(decimals)).div(10 ** uint256(18)); // invested in BNB
                }
            }
        }
        return (amountTotalUSD,newInvestor);
    }
    function checkTokensForClaim(address pool,address investor) public view returns (uint256,uint256,uint256,bool) {
        uint256 tokensForClaim;
        uint256 amountTotalUSD;
        uint256 percentOfTAV;
        bool newInvestor = false;
        if (_investorsReceivedMainTokenLatestDate[investor] > now - 4 weeks) {
            return (tokensForClaim,amountTotalUSD,percentOfTAV,newInvestor);// already receive reward 4 weeks ago
        }
        (amountTotalUSD, newInvestor) = investorUsdValue(pool,investor);
        uint256 tokensToDistribute;
        (tokensToDistribute, percentOfTAV) = _tokensToDistribute(amountTotalUSD,newInvestor);
        return (tokensToDistribute,amountTotalUSD,percentOfTAV,newInvestor);
    }
    event ClaimFreeTokens(address pool,uint256 amount, address investor,bool result);
    function claimFreeTokens(address pool) public returns (bool) {
        uint256 tokensToPay;
        (tokensToPay,,,)= checkTokensForClaim(pool,msg.sender);
        bool result = false;
        if (tokensToPay > 0) {
            _tokenForTokensale().transfer(msg.sender, tokensToPay);
            _investorsReceivedMainTokenLatestDate[msg.sender] = now;
            result = true;
        }
        emit ClaimFreeTokens(pool,tokensToPay,msg.sender,result);
        return result;
    }

}

pragma solidity ^0.6.0;
import "./lib/Roles.sol";
contract TeamRole {
    using Roles for Roles.Role;
    event TeamAdded(address indexed account);
    event TeamRemoved(address indexed account);
    Roles.Role private _team;
    constructor () internal {
        _addTeam(msg.sender);
    }
    modifier onlyTeam() {
        require(isTeam(msg.sender), "TeamRole: caller does not have the Team role");
        _;
    }
    function isTeam(address account) public view returns (bool) {
        return _team.has(account);
    }
    function getTeamAddresses() public view returns (address[] memory) {
        return _team.accounts;
    }
    function addTeam(address account) public onlyTeam {
        _addTeam(account);
    }
    function renounceTeam() public {
        _removeTeam(msg.sender);
    }
    function _addTeam(address account) internal {
        _team.add(account);
        emit TeamAdded(account);
    }
    function _removeTeam(address account) internal {
        _team.remove(account);
        emit TeamRemoved(account);
    }
}

pragma solidity ^0.6.0;
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        for (uint256 i; i < role.accounts.length; i++) {
            if (role.accounts[i] == account) {
                _removeIndexArray(i, role.accounts);
                break;
            }
        }
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        array.pop();
    }
}

pragma solidity ^0.6.0;
interface IAssetsManageTeam {
    function _depositToken(address pool, address team, address token, uint256 amount) external returns (bool);
    function _withdraw(address pool, address team, uint256 amount) external returns (bool);
    function _withdrawTokensToStartup(address pool,address token, address team, uint256 amount) external returns (bool);
    function _request(bool withdraw, address pool, address team, uint256 maxValue) external returns(bool);
    function _requestTokensWithdwawalFromStartup(address pool, address token, address team, uint256 maxValue) external returns(bool);
    function _approve(address pool, address team, address owner) external returns(bool);
    function _approveTokensWithdwawalFromStartup(address pool, address token, address team, address owner) external returns(bool);
    function _disapprove(address pool, address team, address owner) external returns(bool);
    function _lock(address pool, address team, address owner) external returns(bool);
    function _unlock(address pool, address team, address owner) external returns(bool);
    function addManager(address account) external;
    function getPerformedOperationsLength(address pool, address owner) external view returns(uint256 length);
    function getPerformedOperations(address pool, address owner, uint256 index) external view returns(address token, uint256 amountToken, uint256 withdraw, uint256 time);
    function getRequests(address pool) external view returns(address[] memory);
    function getApproval(address pool) external view returns(address[] memory);
    function getRequestTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue);
    function getApproveTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValueE);
}

pragma solidity ^0.6.0;
interface ICreator {
    function createPool(string calldata name, uint256 lockPeriod,uint256 depositFixedFee,uint256 referralDepositFee,uint256 anualPrecent,uint256 penaltyEarlyWithdraw,address superAdmin,address gPartner,address lPartner,address startupTeam) external returns (address);
}

pragma solidity ^0.6.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;
interface IOracle {
    function getLatestPrice() external view returns ( uint256,uint8);
    function getCustomPrice(address aggregator) external view returns (uint256,uint8);
}

pragma solidity ^0.6.0;
interface IPool {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getDeposit(address owner, uint256 index) external view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken);
    function getDepositLength(address owner) external view returns(uint256);
    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);
    function getInfoPool() external view returns(string memory name,bool isPublicPool, address token, uint256 locked);
    function getInfoPoolFees() external view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee);
    function getReferral(address lPartner) external view returns (address);
    function getPoolValues() external view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue);
    function getPoolPairReserves() external view     returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address token0, address token1, address weth,uint price0CumulativeLast,uint price1CumulativeLast);
    function _updatePool(string calldata name,bool isPublicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw) external returns (bool);
    function _setRate(uint256 rate) external returns (bool);
    function _setTeamReward(uint256 teamReward) external returns (bool);
    function _setPoolValues(uint256 poolValueUSD,uint256 poolValue, string calldata proofOfValue) external returns (bool);
    function _depositPoolRegistry(address sender, uint256 amount, uint256 feesMulitpier) external returns (bool);
    function _depositTokenPoolRegistry(address payable sender, uint256 amount) external returns (bool);
    function _depositInvestmentInTokensToPool(address payable sender, uint256 amount, address token) external returns (bool);
    function _withdrawTeam(address payable sender, uint256 amount) external returns (bool);
    function _withdrawTokensToStartup(address payable sender,address token, uint256 amount) external returns (bool);
    function _returnsInTokensFromTeam(address payable sender,address token, uint256 amount) external returns (bool);
    function _activateDepositToPool() external returns (bool);
    function _disactivateDepositToPool() external returns (bool);
    function _setReferral(address sender, address lPartner, address referral) external returns (bool);
    function _approveWithdrawLpartner(address lPartner, uint256 index, uint256 amount, address investedToken) external returns (bool);
    function _withdrawLPartner(address payable sender) external returns (bool, uint256, address);
    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external returns (bool);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}

pragma solidity ^0.6.0;
interface IReturnInvestmentLpartner {
  function _request(address pool, address lPartner, uint256 index, uint256 amount, address token) external returns(bool);
  function _approve(address pool, address lPartner, address sender) external returns(bool);
  function _disapprove(address pool, address lPartner, address sender) external returns(bool);
  function getRequests(address pool) external view returns(address[] memory);
  function getRequestsLpartner(address pool, address lPartner) external view returns(uint256[] memory);
}

pragma solidity ^0.6.0;
contract IRoleModel {
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant GENERAL_PARTNER_ROLE = keccak256("GENERAL_PARTNER_ROLE");
    bytes32 public constant LIMITED_PARTNER_ROLE = keccak256("LIMITED_PARTNER_ROLE");
    bytes32 public constant STARTUP_TEAM_ROLE = keccak256("STARTUP_TEAM_ROLE");
    bytes32 public constant POOL_REGISTRY = keccak256("POOL_REGISTRY");
    bytes32 public constant RETURN_INVESTMENT_LPARTNER = keccak256("RETURN_INVESTMENT_LPARTNER");
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public constant REFERER_ROLE = keccak256("REFERER_ROLE");
}

pragma solidity ^0.6.0;
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

pragma solidity ^0.6.0;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];
            for(uint256 i = 0; i < set._collection.length; i++) {
                if (set._collection[i] == addressValue) {
                    _removeIndexArray(i, set._collection);
                    break;
                }
            }
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        array.pop();
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)), value);
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}
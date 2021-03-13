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

    // The address of the contract that creates the Investment Pool
    address private _creatorInvestPool;
    // Smart contract for request deposit
    IAssetsManageTeam private _assetsManageTeam;
    // Smart contract for return investment
    IReturnInvestmentLpartner private _returnInvestmentLpartner;
    // Oracle contract address
    IOracle _oracleContract;

    // Collection of all pool addresses
    EnumerableSet.AddressSet private _addressesPools;

    mapping(address => uint256) private _investedFunds;
    mapping(address => uint256) private _returnedFunds;


    mapping(address => uint256) private _poolValues;
    uint256 private _poolValuesTotal;

    mapping(address => uint256) private _poolValuesUSD;
    uint256 private _poolValuesUSDTotal;


    //    struct DepositEth {
//        uint256 amount;          // Amount of funds deposited
//        uint256 time;            // Deposit time
//        uint256 lock_period;     // Asset lock time
//        bool refund_authorize;   // Are assets unlocked for withdrawal
//        uint256 amountWithdrawal;
//    }
    /*************************************************************
     ****************** MANAGEMENT POOL METHODS *******************
     **************************************************************/

    /**
     * @dev Create new Investment Pool.
     * @param name name
     * @param lockPeriod The blocking period of assets.
     * @param depositFixedFee main network coin (ETH,BNB) deposit commission LPartner.
     * @param referralDepositFee Referral commission.
     * @param anualPrecent The annual percentage of tokens.
     * @param superAdmin The An address that has privileges SUPER_ADMIN_ROLE.
     * @param gPartner The An address that has privileges GENERAL_PARTNER_ROLE.
     * @param lPartner The An address that has privileges LIMITED_PARTNER_ROLE.
     * @param startupTeam The An address that has privileges TEAM_ROLE.
     * @return A boolean that indicates if the operation was successful.
     */
    function createPool(
        string memory name,
        uint256 lockPeriod,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw,
        address superAdmin,
        address gPartner,
        address lPartner,
        address startupTeam
    ) public onlyTeam returns (bool) {
        ICreator _creatorContract = ICreator(_creatorInvestPool);

        address _investPool =
            _creatorContract.createPool(
                name,
                lockPeriod,
                depositFixedFee,
                referralDepositFee,
                anualPrecent,
                penaltyEarlyWithdraw,
                superAdmin,
                gPartner,
                lPartner,
                startupTeam
            );

        _addressesPools.add(_investPool);

        emit CreatePool(_investPool);
        return true;
    }

    /**
     * @dev Add new smart contract Investment Pool.
     * @param poolAddress The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function addPool(address poolAddress) public onlyTeam returns (bool) {
        // require(!_addressesPools.contains(poolAddress), "PoolRegistry: pool with this address already exists");

        _addressesPools.add(poolAddress);
        _assetsManageTeam.addManager(poolAddress);

        emit AddPool(poolAddress);
        return true;
    }

    /**
     * @dev Update smart contract Investment Pool.
     * @param token The address token contract.
     * @param locked The address to query the wager of.
     * @param depositFixedFee Commission from the deposit Limited Partner.
     * @param referralDepositFee Commission from the deposit if the limited partner has a referral.
     * @param anualPrecent The annual percentage of tokens.
     * @param penaltyEarlyWithdraw The penalty for early withdraw.
     * @return A boolean that indicates if the operation was successful.
     */
    function updatePool(
        address pool,
        string memory name,
        bool publicPool,
        address token,
        uint256 locked,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw
    ) public onlyTeam returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._updatePool(
            name,
            publicPool,
            token,
            locked,
            depositFixedFee,
            referralDepositFee,
            anualPrecent,
            penaltyEarlyWithdraw
        );

        emit UpdatePool(pool);
        return true;
    }

    /**
     * @dev Set price token for One. (POOL REGISTRY)
     * @param rate new price token to Wei.
     * @return A boolean that indicates if the operation was successful.
     */
    function setPriceToken(address pool, uint256 rate) external onlyTeam returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._setRate(rate);
        return true;
    }

    /*************************************************************
     ******************** ASSET MANAGE TEAM ***********************
     **************************************************************/
    event DepositTokenToPool(address pool, uint256 amount);

    /**
     * @dev Deposit token for Investment Pool.
     * @param pool The address Investment Pool.
     * @param amount Amount of deposit tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function depositTokenToPool(address pool, uint256 amount) public returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._depositTokenPoolRegistry(msg.sender, amount);
        emit DepositTokenToPool(pool,amount);
        return true;
    }

    event WithdrawToStartupTeam(address pool, uint256 amount);

    /**
     * @dev Withdraw main network coin (ETH,BNB) from Investment pool to STARTUP_TEAM.
     * @param pool The address Investment Pool.
     * @param amount Amount of withdraw main network coin (ETH,BNB).
     * @return A boolean that indicates if the operation was successful.
     */
    function withdrawToStartupTeam(address pool, uint256 amount) public returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._withdrawTeam(msg.sender, amount);
        emit WithdrawToStartupTeam(pool,amount);
        return true;
    }

    /**
     * @dev Creation of a request to deposit token or withdraw main network coin (ETH,BNB).
     * @param withdraw Boolean value to indicate the type of request.
     * @param pool The address Investment Pool.
     * @param maxValue Maximum possible deposit.
     * @return A boolean that indicates if the operation was successful.
     */
    function requestStartupTeam(
        bool withdraw,
        address pool,
        uint256 maxValue
    ) public returns (bool) {
        return _assetsManageTeam._request(withdraw, pool, msg.sender, maxValue);
    }

    /**
     * @dev Approve of a request to deposit token or withdraw main network coin (ETH,BNB).
     * @param pool The address Investment Pool.
     * @param team Address to confirm the token deposit.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveReqStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._approve(pool, team, msg.sender);
    }

    /**
     * @dev Disapprove of a request to deposit a token or withdraw main network coin (ETH,BNB).
     * @param pool The address Investment Pool.
     * @param team Address to disapprove the token deposit.
     * @return A boolean that indicates if the operation was successful.
     */
    function disapproveReqStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._disapprove(pool, team, msg.sender);
    }

    /**
     * @dev Lock deposit or withdraw main network coin (ETH,BNB) for startup team address.
     * @param pool The address Investment Pool.
     * @param team Address to lock token deposit or withdraw main network coin (ETH,BNB).
     * @return A boolean that indicates if the operation was successful.
     */
    function lockStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._lock(pool, team, msg.sender);
    }

    /**
     * @dev Unlock deposit or withdraw main network coin (ETH,BNB) for startup team address.
     * @param pool The address Investment Pool.
     * @param team Address to unlock token deposit or withdraw main network coin (ETH,BNB).
     * @return A boolean that indicates if the operation was successful.
     */
    function unlockStartupTeam(address pool, address team) public returns (bool) {
        return _assetsManageTeam._unlock(pool, team, msg.sender);
    }

    /**
     * @dev Get information about the user who made a deposit ETH.
     * @param pool The address Investment Pool.
     * @param owner The address investor pool.
     * @param index The owner's deposit index.
     */
    function getDepositPool(
        address pool,
        address owner,
        uint256 index
    )
        public
        view
        returns (
            uint256 amount,
            uint256 time,
            uint256 lock_period,
            bool refund_authorize,
            uint256 amountWithdrawal,
            uint256 lenghtDeposit,
            address investedToken
    )
    {
        IPool _poolContract = IPool(pool);
        (amount, time, lock_period, refund_authorize, amountWithdrawal,investedToken) = _poolContract.getDeposit(owner, index);
        uint256 lenghtDepSender = _poolContract.getDepositLength(msg.sender);
        return (amount, time, lock_period, refund_authorize,amountWithdrawal,lenghtDepSender,investedToken);
    }

    /**
     * @dev Get information about the user who made a depositToken or withdraw main network coin (ETH,BNB).
     * @param pool The address Investment Pool.
     * @param owner The address investor pool.
     * @param index The owner's deposit index.
     */
    function getPerformedOperationsTeamStartup(
        address pool,
        address owner,
        uint256 index
    )
        public
        view
        returns (
            address token,
            uint256 amountToken,
            uint256 withdrawAmount,
            uint256 time
        )
    {
        (token, amountToken, withdrawAmount, time) = _assetsManageTeam.getPerformedOperations(
            pool,
            owner,
            index
        );

        return (token, amountToken, withdrawAmount, time);
    }

    /**
     * @dev Get all addresses that made a requests for a token deposit or withdraw.
     * @param pool The address Investment Pool.
     */
    function getRequestsTeam(address pool) public view returns (address[] memory) {
        return _assetsManageTeam.getRequests(pool);
    }

    /**
     * @dev Get all addresses that made a approve for a token deposit or withdraw.
     * @param pool The address Investment Pool.
     */
    function getApprovalReqTeam(address pool) public view returns (address[] memory) {
        return _assetsManageTeam.getApproval(pool);
    }

    /**
     * @dev Get request information for team address.
     * @param pool The address Investment Pool.
     * @param team The address team account.
     */
    function getRequestTeamAddress(address pool, address team)
        public
        view
        returns (
            bool lock,
            uint256 maxValueToken,
            uint256 madeValueToken,
            uint256 maxValue,
            uint256 madeValue
        )
    {
        (lock, maxValueToken, madeValueToken, maxValue, madeValue) = _assetsManageTeam
            .getRequestTeamAddress(pool, team);
        return (lock, maxValueToken, madeValueToken, maxValue, madeValue);
    }

    /**
     * @dev Get approve information for team address.
     * @param pool The address Investment Pool.
     * @param team The address team account.
     */
    function getApproveTeamAddress(address pool, address team)
        public
        view
        returns (
            bool lock,
            uint256 maxValueToken,
            uint256 madeValueToken,
            uint256 maxValue,
            uint256 madeValue
        )
    {
        (lock, maxValueToken, madeValueToken, maxValue, madeValue) = _assetsManageTeam
            .getApproveTeamAddress(pool, team);
        return (lock, maxValueToken, madeValueToken, maxValue, madeValue);
    }

    /*************************************************************
     ********************* REFERRAL METHODS ***********************
     **************************************************************/
    event SetReferral(address pool, address lPartner,address referral,bool result);

    /**
     * @dev Adding referral LPartner.
     * @param pool The address Investment Pool.
     * @param referral The address referral LPartner.
     * @return A boolean that indicates if the operation was successful.
     */
    function setReferral(
        address pool,
        address lPartner,
        address referral
    ) public returns (bool) {
        IPool _poolContract = IPool(pool);
        require(
            _poolContract.hasRole(LIMITED_PARTNER_ROLE, lPartner),
            "PoolRegistry: parameter Lpartner has no role LPartner"
        );
        bool result = _poolContract._setReferral(msg.sender, lPartner, referral);
        emit SetReferral(pool,lPartner,referral,result);
        return result;
    }

    /**
     * @dev Get address referal for LPartner.
     * @param pool The address Investment Pool.
     */
    function getReferral(address pool, address lPartner) public view returns (address) {
        IPool _poolContract = IPool(pool);
        return _poolContract.getReferral(lPartner);
    }

    /*************************************************************
     **************** METHODS RETURNS INVESTMENT ******************
     **************************************************************/

    /**
     * @dev Creating a request for a return investment Limited partner.
     * @param pool The address Investment Pool contract.
     * @param index Investment index.
     * @param amount Investment amount.
     * @return A boolean that indicates if the operation was successful.
     */
    function requestReturnInvestmentLpartner(address pool, uint256 index, uint256 amount,address token) public returns (bool) {
        return _returnInvestmentLpartner._request(pool, msg.sender, index, amount, token);
    }

    /**
     * @dev Approve of a request for return investment.
     * @param pool The address Investment Pool contract.
     * @param lPartner Address to confirm the request.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveReturnInvestmentLpartner(address pool, address lPartner) public returns (bool) {
        return _returnInvestmentLpartner._approve(pool, lPartner, msg.sender);
    }

//    event DebugWithdrawLPartner(address sender,address owner, uint256 getDepositLengthSender, uint256 getDepositLengthOwner,uint256 totalAmountReturn,uint256 indexesDepositLength,uint256 balanceThis);

    event WithdrawLPartner(address pool, address lPartner,bool result);

    /**
     * @dev Returns investment pool.
     * @param pool The address Investment Pool contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function withdrawLPartner(address pool) public returns (bool) {
        IPool _poolContract = IPool(pool);
        bool result;
        uint256 totalAmountReturn;
        address token;
        (result,totalAmountReturn,token) = _poolContract._withdrawLPartner(msg.sender);
        if (result) {
            _returnedFunds[token] = _returnedFunds[token] + totalAmountReturn;
        }
        emit WithdrawLPartner(pool,msg.sender,result);
        return result;
    }

    /**
     * @dev Disapprove of a request for return investment.
     * @param pool The address Investment Pool contract.
     * @param lPartner Address to confirm the request.
     * @return A boolean that indicates if the operation was successful.
     */
    function disapproveReturnInvestmentLpartner(address pool, address lPartner)
        public
        returns (bool)
    {
        return _returnInvestmentLpartner._disapprove(pool, lPartner, msg.sender);
    }

    /**
     * @dev Get all requests.
     * @param pool address investment pool contract.
     */
    function getAddrRequestsReturnInvesLpartner(address pool)
        public
        view
        returns (address[] memory)
    {
        return _returnInvestmentLpartner.getRequests(pool);
    }

    /**
     * @dev Get all requests current LPartner.
     * @param pool address investment pool contract.
     * @param lPartner address limited parner role.
     */
    function getRequestsReturnInvestLpartner(address pool, address lPartner)
        public
        view
        returns (uint256[] memory)
    {
        return _returnInvestmentLpartner.getRequestsLpartner(pool, lPartner);
    }

    /**
    * @dev getinvestedFunds.
    * @param token address for asstet (address(0) for ETH/BNB)
    */
    function getInvestedFunds(address token)
    public
    view
    returns (uint256)
    {
        return _investedFunds[token];
    }

    /**
    * @dev getReturnedFunds.
    * @param token address for asset (address(0) for ETH/BNB)
    */
    function getReturnedFunds(address token)
    public
    view
    returns (uint256)
    {
        return _returnedFunds[token];
    }
    uint256 mulitpierDefault = 100000;

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
    /**
     * @dev Deposit main network coin (ETH,BNB) for Investment Pool.
     * @param pool The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function depositToPool(address payable pool) public payable returns (bool) {
        uint256 amount = msg.value;
        IPool _poolContract = IPool(pool);
        pool.transfer(amount);

        _poolContract._depositPoolRegistry(msg.sender, amount, feesMulitpier(msg.sender));
        _investedFunds[address(0)] = _investedFunds[address(0)] + amount;

        emit DepositToPool(msg.sender,amount);
        return true;
    }

    event ReturnsFromStartupTeam(address sender, uint256 amount);
    /**
     * @dev Returns main network coin (ETH,BNB) to investment pool from team.
     * @param pool The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function returnsFromStartupTeam(address payable pool) public payable returns (bool) {
        IPool _poolContract = IPool(pool);
        require(
            _poolContract.hasRole(STARTUP_TEAM_ROLE, msg.sender),
            "PoolRegistry: sender has no role TeamStartup"
        );

        pool.transfer(msg.value);
        emit ReturnsFromStartupTeam(msg.sender,msg.value);
        return true;
    }

    /**
     * @dev Allow main network coin (ETH,BNB) deposit to investment pool.
     * @param pool The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function activateDepositToPool(address pool) public onlyTeam returns (bool) {
        IPool _poolContract = IPool(pool);
        return _poolContract._activateDepositToPool();
    }

    /**
     * @dev Disallow main network coin (ETH,BNB) deposit to investment pool.
     * @param pool The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function disactivateDepositToPool(address pool) public onlyTeam returns (bool) {
        IPool _poolContract = IPool(pool);
        return _poolContract._disactivateDepositToPool();
    }

    /**
     * @dev Grants role to account.
     * @param pool The address Investment Pool.
     * @param role Role account.
     * @param account The address for grant role.
     * @return A boolean that indicates if the operation was successful.
     */
    function grantRoleInvestmentPool(
        address pool,
        bytes32 role,
        address account
    ) public returns (bool) {
        IPool _poolContract = IPool(pool);

        require(
            _poolContract.hasRole(SUPER_ADMIN_ROLE, msg.sender),
            "PoolRegistry: sender has no role GPartner"
        );

        _poolContract.grantRole(role, account);

        return true;
    }

    /**
     * @dev Revoke role to account.
     * @param pool The address Investment Pool.
     * @param role Role account.
     * @param account The address for grant role.
     * @return A boolean that indicates if the operation was successful.
     */
    function revokeRoleInvestmentPool(
        address pool,
        bytes32 role,
        address account
    ) public returns (bool) {
        IPool _poolContract = IPool(pool);

        require(
            _poolContract.hasRole(SUPER_ADMIN_ROLE, msg.sender),
            "PoolRegistry: sender has no role GPartner"
        );

        _poolContract.revokeRole(role, account);

        return true;
    }

    /**
     * @dev Set the address of the contract creating Investment Pools.
     * @param creatorContract The address creator pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function setAddressCreatorInvestPool(address creatorContract) public onlyTeam returns (bool) {
        _creatorInvestPool = creatorContract;
        return true;
    }

    /**
     * @dev Set address assetManageTeam contract.
     * @param addrContract The address AssetManageTeam contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function setAssetManageTeamContract(IAssetsManageTeam addrContract)
        public
        onlyTeam
        returns (bool)
    {
        _assetsManageTeam = addrContract;
        return true;
    }

    /**
     * @dev Set address ReturnInvestmentLpartner contract.
     * @param addrContract The address ReturnInvestmentLpartner contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function setReturnInvestmentLpartner(IReturnInvestmentLpartner addrContract)
        public
        onlyTeam
        returns (bool)
    {
        _returnInvestmentLpartner = addrContract;
        return true;
    }

    /**
     * @dev Set address Oracle contract.
     * @param _oracle The address Oracle contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function setOracleContract(IOracle _oracle) public onlyTeam returns (bool) {
        _oracleContract = _oracle;
        return true;
    }

    /**
     * @dev Get all Investment Pool addresses.
     */
    function getPools() public view returns (address[] memory) {
        return _addressesPools.collection();
    }

    /**
     * @dev Get information about the Investment Pool.
     * @param pool The address Investment Pool.
     */
    function getInfoPool(address pool)
        public
        view
        returns (
            string memory name,
            bool isPublicPool,
            address token,
            uint256 locked
        )
    {
        IPool _poolContract = IPool(pool);
        (name, isPublicPool, token, locked) = _poolContract.getInfoPool();

        return (
            name,
            isPublicPool,
            token,
            locked
        );
    }

    /**
 * @dev Get information about the Investment Pool.
 * @param pool The address Investment Pool.
 */
    function getInfoPoolFees(address pool)
    public
    view
    returns (
        uint256 rate,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw,
        uint256 totalInvestLpartner,
        uint256 premiumFee
    )
    {
        IPool _poolContract = IPool(pool);
        (rate ,depositFixedFee , referralDepositFee, anualPrecent , penaltyEarlyWithdraw, totalInvestLpartner, premiumFee) = _poolContract.getInfoPoolFees();

        return (
        rate,
        depositFixedFee,
        referralDepositFee,
        anualPrecent,
        penaltyEarlyWithdraw,
        totalInvestLpartner,
        premiumFee
        );
    }

    /**
     * @dev Get address TokenRequestContract.
     */
    function getAssetManageTeamContract() public view returns (IAssetsManageTeam) {
        return _assetsManageTeam;
    }

    /**
     * @dev Get address TokenRequestContract.
     */
    function getReturnInvesmentLpartner() public view returns (IReturnInvestmentLpartner) {
        return _returnInvestmentLpartner;
    }

    /**
     * @dev Get address OracleContract.
     */
    function getOracleContract() public view returns (IOracle) {
        return _oracleContract;
    }

    /**
     * @dev Get all addresses for role.
     * @param pool The address Investment Pool.
     * @param role Role accounts.
     */
    function getAddressesRolesPool(address pool, bytes32 role)
        public
        view
        returns (address[] memory)
    {
        IPool _poolContract = IPool(pool);
        return _poolContract.getMembersRole(role);
    }

    /**
     * @dev Get address contract creator Invest pool.
     */
    function getAddressCreatorInvestPool() public view returns (address) {
        return _creatorInvestPool;
    }

    /**
     * @dev Get getPoolValues.
     */
    function getPoolValues(address pool) public view
    returns (
        uint256 poolValueUSD,
        uint256 poolValue,
        string memory proofOfValue,
        uint256 poolValuesTotal,
        uint256 poolValuesUSDTotal
    ) {
        IPool _poolContract = IPool(pool);
        uint256 poolValueUSD;
        uint256 poolValue;
        string memory proofOfValue;
        (poolValueUSD, poolValue, proofOfValue) = _poolContract.getPoolValues();
        return (poolValueUSD,poolValue,proofOfValue,_poolValuesTotal,_poolValuesUSDTotal);
    }

    event SetPoolValues(address pool,uint256 poolValueUSD, uint256 poolValue, string proofOfValue, bool result);
    /**
    * @dev set getPoolValues.
    */
    function setPoolValues(address pool,uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue) public returns (bool) {
        IPool _poolContract = IPool(pool);
        require(
            _poolContract.hasRole(SUPER_ADMIN_ROLE, msg.sender),
            "PoolRegistry: sender has no role SUPER_ADMIN_ROLE"
        );
        _poolValues[pool] = poolValue;
        _poolValuesUSD[pool] = poolValueUSD;
        bool result = _poolContract._setPoolValues(poolValueUSD,poolValue,proofOfValue);
        uint256 poolValueUSDNewTotal;
        uint256 poolValueNewTotal;

        address [] memory pools = getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 poolValueUSDforSum;
            uint256 poolValueforSum;
            IPool _poolContractCheck = IPool(pools[i]);
            (poolValueUSDforSum, poolValueforSum, ) =_poolContractCheck.getPoolValues();
            poolValueUSDNewTotal += poolValueUSDforSum;
            poolValueNewTotal += poolValueforSum;
        }
        if (poolValueNewTotal > 0) {
            _poolValuesTotal = poolValueNewTotal;
        }
        if (poolValueNewTotal > 0) {
            _poolValuesUSDTotal = poolValueUSDNewTotal;
        }
        emit SetPoolValues(pool,poolValueUSD,poolValue,proofOfValue,result);
        return result;
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

    /**
         * @dev Deposit investment in tokens for Investment Pool.
         * @param pool The address Investment Pool.
         * @param amount Amount of deposit tokens.
         * @param token address of deposited tokens.
         * @return A boolean that indicates if the operation was successful.
         */
    function depositInvestmentInTokensToPool(address pool, uint256 amount, address token) public returns (bool) {
        require(amount > 0, "depositInvestmentInTokensToPool: the number of sent token is 0");

        IPool _poolContract = IPool(pool);

        uint256 depositFixedFee = 0;
        uint256 referralDepositFee = 0;
        (, depositFixedFee, referralDepositFee, , , , ) = _poolContract.getInfoPoolFees();

        address payable team = payable(getTeamAddresses()[1]);
        address referalAddress = _poolContract.getReferral(msg.sender);

        uint256 depositFee = 0;
        uint256 depositFeeReferrer = 0;
        uint256 finalAmount = 0;
        (finalAmount,depositFee,depositFeeReferrer) = _depositInvestmentInTokensToPoolCalculation(depositFixedFee, referralDepositFee, amount, referalAddress, feesMulitpier(msg.sender));

        IERC20 tokenContract = IERC20(token);
        tokenContract.transferFrom(msg.sender, pool, finalAmount);
        tokenContract.transferFrom(msg.sender, team, depositFee);
        if (depositFeeReferrer > 0) {
            tokenContract.transferFrom(msg.sender, payable(referalAddress), depositFeeReferrer);
        }
        _poolContract._depositInvestmentInTokensToPool(msg.sender,amount,token);
        _investedFunds[token] = _investedFunds[token] + amount;
        emit DepositInvestmentInTokensToPool(pool,amount,token);
        return true;
    }

    event WithdrawInTokensToStartupTeam(address pool,uint256 amount, address token);
    /**
    * @dev Withdraw main network coin (ETH,BNB) from Investment pool STARTUP_TEAM.
    * @param pool The address Investment Pool.
    * @param amount Amount of withdraw main network coin (ETH,BNB).
    * @return A boolean that indicates if the operation was successful.
    */
    function withdrawInTokensToStartupTeam(address pool,address token, uint256 amount) public returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._withdrawTokensToStartup(msg.sender,token, amount);
        emit WithdrawInTokensToStartupTeam(pool,amount,token);
        return true;
    }

    /**
    * @dev Creation of a request to withdraw any tokens (BUSD/USDT e.t.c) from pool.
    * @param pool The address Investment Pool.
    * @param token The address of token.
    * @param maxValue Maximum possible deposit.
    * @return A boolean that indicates if the operation was successful.
    */
    function requestTokensWithdwawalFromStartup(
        address pool,
        address token,
        uint256 maxValue
    ) public returns (bool) {
        return _assetsManageTeam._requestTokensWithdwawalFromStartup(pool,token, msg.sender, maxValue);
    }

    /**
    * @dev Creation of a request to withdraw any tokens (BUSD/USDT e.t.c) from pool.
    * @param pool The address Investment Pool.
    * @param token The address of token.
    * @param team The address of team.
    * @return A boolean that indicates if the operation was successful.
    */
    function approveTokensWithdwawalFromStartup(
        address pool,
        address token,
        address team
    ) public returns (bool) {
        return _assetsManageTeam._approveTokensWithdwawalFromStartup(pool,token,team,msg.sender);
    }

    event ReturnsInTokensFromTeam(address pool,uint256 amount, address token);
    /**
     * @dev Returns tokens (BUSD,USDT) to investment pool from team.
     * @param pool The address Investment Pool.
     * @return A boolean that indicates if the operation was successful.
     */
    function returnsInTokensFromTeam(address payable pool,address token, uint256 amount) public returns (bool) {
        IPool _poolContract = IPool(pool);
        _poolContract._returnsInTokensFromTeam(msg.sender,token,amount);
        emit ReturnsInTokensFromTeam(pool,amount,token);
        return true;
    }

    /**
    * @dev withdrawSuperAdmin investment pool.
    * @param pool The address Investment Pool contract.
    * @param token The address token contract.
    * @param amount  token .
    * @return A boolean that indicates if the operation was successful.
    */
    function withdrawSuperAdmin(address pool, address token, uint256 amount) public returns (bool) {
        IPool _poolContract = IPool(pool);
        return _poolContract._withdrawSuperAdmin(msg.sender, token, amount);
    }

    /**
     * @dev Get address TokenRequestContract.
     */
    function getCustomPrice(address aggregator) public view returns (uint256) {
        return uint256(_oracleContract.getCustomPrice(aggregator));
    }
   // [investor address][date reward]
    mapping(address => uint256) private _investorsReceivedMainTokenLatestDate;
    event ClaimFreeProjectTokens(
        address pool,
        uint256 lastRewardTimestamp,
        uint256 poolValuesUSDTotal,
        uint256 balanceLeavedOnThisContractProjectTokens,
        uint256 amountTotalUSD,
        bool newInvestor,
        uint256 tokensToPay,
        uint256 poolValuesUSDTotalInUSD,
        uint256 percentOfTAV
    );

//    event ClaimFreeProjectTokensDepositCheckDebug(
//        uint256 amountWei,
//        uint256 time,
//        address investedToken,
//        uint256 timeToCompare,
//        uint256 now,
//        uint256 amountTotalUSD
//    );

    function _tokenForTokensale() private view returns (IERC20) {
        IPool _tokensalePoolContract = IPool(getPools()[0]);
        address tokenForTokensale;
        (,,tokenForTokensale,) = _tokensalePoolContract.getInfoPool();

        IERC20 tokenContract = IERC20(tokenForTokensale);
        return tokenContract;
    }

    function _balanceTokenForTokensale(address forAddress) private view returns (uint256) {
        IERC20 tokenContract = _tokenForTokensale();
        return tokenContract.balanceOf(forAddress);
    }

    function _tokensToDistribute(uint256 amountTotalUSD, bool newInvestor) private view returns (uint256,uint256) {

        uint256 balanceLeavedOnThisContractProjectTokens = _balanceTokenForTokensale(address (this));

        // if TAV < 500k, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 1%
        //  if TAV >  $500k and TAV < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 3%
        //  if TAV >  $500k and TAV < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 10%
        if (_poolValuesUSDTotal.div(10 ** uint256(18)) < 500000) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(100);
        } else if (_poolValuesUSDTotal.div(10 ** uint256(18)) < 5000000) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(30);
        } else {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10);
        }
        // amountTotalUSD / TAV - his percent of TAV
        // balanceLeavedOnThisContractProjectTokens * his percent of pool = amount of tokens to pay
        // if (newInvestor) amount of tokens to pay = amount of tokens to pay * 1.1
        // _investorsReceivedMainToken[msg.sender][time] = amount of tokens to pay
        uint256 poolValuesUSDTotalInUSD = _poolValuesUSDTotal.div(10 ** uint256(18));
        uint256 percentOfTAV = amountTotalUSD.mul(10000).div(poolValuesUSDTotalInUSD);
//        uint256 tokensToPay = balanceLeavedOnThisContractProjectTokens.mul(percentOfTAV).div(100);
        if (newInvestor) {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfTAV).div(10000).mul(11).div(10),percentOfTAV);
        } else {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfTAV).div(10000),percentOfTAV);
        }

    }
    function investorUsdValue(address pool,address investor) public view returns (uint256,bool) {
        uint256 amountTotalUSD;
        bool newInvestor = false;

        IPool _poolContract = IPool(pool);
        uint256 lenghtSender = _poolContract.getDepositLength(investor);

        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = _oracleContract.getLatestPrice();

        for (uint256 i = 0; i < lenghtSender; i++) {
            newInvestor = false;
            uint256 amountWei;          // Amount of funds deposited
            uint256 time;            // Deposit time
            address investedToken; // address(0) for ETH/BNB
            (amountWei, time, , , , ) = _poolContract.getDeposit(investor, i);
            (, , , , , investedToken) = _poolContract.getDeposit(investor, i);
            // uint256 timeToCompareWithNow = time + 1 minutes; - for test
            // must hold at least 4 weeks
            uint256 timeToCompareWithNow = time + 4 weeks;
            if (now > timeToCompareWithNow) {
                // new investors hold more than 4 weeks

                // check if new investors hold less than 8 weeks
                if (now < time + 8 weeks) {
                    // new investor
                    newInvestor = true;
                }

                if (investedToken != address(0)) {
                    // invested in BUSD
                    amountTotalUSD += amountWei.div(10 ** uint256(18));
                } else {
                    // invested in BNB
                    amountTotalUSD += amountWei.mul(priceMainToUSDreturned.div(10 ** uint256(decimals))).div(10 ** uint256(18));
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
            // already receive reward 4 weeks ago
            return (tokensForClaim,amountTotalUSD,percentOfTAV,newInvestor);
        }
        (amountTotalUSD, newInvestor) = investorUsdValue(pool,investor);
        uint256 tokensToDistribute;
        (tokensToDistribute, percentOfTAV) = _tokensToDistribute(amountTotalUSD,newInvestor);
        return (tokensToDistribute,amountTotalUSD,percentOfTAV,newInvestor);
    }


    event ClaimFreeTokens(address pool,uint256 amount, address investor,bool result);

    /**
   * @dev claim ubank tokens from.
   * @param pool The address Investment Pool contract.
   * @return A boolean that indicates if the operation was successful.
   */

    function claimFreeTokens(address pool) public returns (bool) {
        uint256 tokensToPay;
        (tokensToPay,,,)= checkTokensForClaim(pool,msg.sender);
        bool result = false;
        if (tokensToPay > 0) {
//            IPool _tokensalePoolContract = IPool(getPools()[0]);
//            address tokenForTokensale;
//            (,,tokenForTokensale,) = _tokensalePoolContract.getInfoPool();
            IERC20 tokenContract = _tokenForTokensale();
            tokenContract.transfer(msg.sender, tokensToPay);
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

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
    }

    /**
     * @dev Remove an account's access to this role.
     */
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

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
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

    // ***** SET INFO ***** //

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
    
    // ***** GET INFO ***** //

    function getPerformedOperationsLength(address pool, address owner) external view returns(uint256 length);
    
    function getPerformedOperations(address pool, address owner, uint256 index) external view returns(address token, uint256 amountToken, uint256 withdraw, uint256 time);
    
    function getRequests(address pool) external view returns(address[] memory);

    function getApproval(address pool) external view returns(address[] memory);
    
    function getRequestTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue);
    
    function getApproveTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValueE);
}

pragma solidity ^0.6.0;

interface ICreator {
    function createPool(
        string calldata name,
        uint256 lockPeriod,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw,
        address superAdmin,
        address gPartner,
        address lPartner,
        address startupTeam
    ) external returns (address);
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Get decimals token contract
     */
    function decimals() external view returns (uint8);

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

pragma solidity ^0.6.0;

interface IOracle {
    function getLatestPrice()
        external
        view
        returns (
            uint256,
            uint8
        );

    function getCustomPrice(address aggregator) external view returns (uint256);
}

pragma solidity ^0.6.0;

interface IPool {

    // ***** GET INFO ***** //

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getDeposit(address owner, uint256 index) external view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken);

    function getDepositLength(address owner) external view returns(uint256);

    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);

    function getInfoPool() external view returns(string memory name,bool isPublicPool, address token, uint256 locked);

    function getInfoPoolFees() external view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee);

    function getReferral(address lPartner) external view returns (address);

    function getPoolValues() external view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue);

// ***** SET INFO ***** //

    function _updatePool(string calldata name,bool isPublicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw) external returns (bool);

    function _setRate(uint256 rate) external returns (bool);

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
    /**
     * SUPER_ADMIN_ROLE - The Role controls adding a new wallet addresses to according roles arrays
     */
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");

    /**
     * GENERAL_PARTNER_ROLE - The Role controls the approval process to transfer money inside
     *               investment pools and control Limited Partners adding, investment
     *               pools adding
     */
    bytes32 public constant GENERAL_PARTNER_ROLE = keccak256("GENERAL_PARTNER_ROLE");

    /**
     * LIMITED_PARTNER_ROLE - The Role allows the wallet of LP to invest money in the
     *               investment pool and withdraw money from there (access to limited pools)
     */
    bytes32 public constant LIMITED_PARTNER_ROLE = keccak256("LIMITED_PARTNER_ROLE");

    /**
     * TEAM_ROLE - Role that exposes access to wallets (the team member), were
     *           distributed all fees, fines, and success premiums from investment pools
     */
    bytes32 public constant STARTUP_TEAM_ROLE = keccak256("STARTUP_TEAM_ROLE");

    /**
     * POOL_REGISTRY - Registry of contract, which manage contract;
     */
    bytes32 public constant POOL_REGISTRY = keccak256("POOL_REGISTRY");

    /**
     * RETURN_INVESTMENT_LPARTNER - Management returns investment for Limitited partner role.
     */
    bytes32 public constant RETURN_INVESTMENT_LPARTNER = keccak256("RETURN_INVESTMENT_LPARTNER");

    bytes32 public constant ORACLE = keccak256("ORACLE");

    bytes32 public constant REFERER_ROLE = keccak256("REFERER_ROLE");

}

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

pragma solidity ^0.6.0;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Collection addresses
        address[] _collection;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }
    
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
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

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
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
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)), value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}
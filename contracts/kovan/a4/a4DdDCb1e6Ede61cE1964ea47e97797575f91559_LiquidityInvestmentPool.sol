pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "./interface/IPoolRegistry.sol";
import "./interface/IAssetsManageTeam.sol";
import "./interface/IERC20.sol";
import "./access/PoolRoles.sol";
import "./math/SafeMath.sol";
//import "./interface/IPancakePair.sol";
import "./interface/IwBNB.sol";
//import "./interface/ICalculateWithdrawEth.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';


//import "./CalculateWithdrawEth.sol";

contract LiquidityInvestmentPool is PoolRoles {
    using SafeMath for uint256;

    event Deposit(address indexed from, uint256 value);

    event DebugWithdrawLPartner(address sender,address owner, uint256 getDepositLengthSender, uint256 getDepositLengthOwner,uint256 totalAmountReturn,uint256 indexesDepositLength,uint256 balanceThis);

    // Address token contract
    string private _name;

    bool private _isPublicPool = true;
    // Address token contract
    address private _token;
    // Period lock investment
    uint256 private _lockPeriod;
    // Token unit rate
    uint256 private _rate;
    // Pool value USD, wei
    uint256 private _poolValueUSD = 0;
    // Pool value main network coin (ETH,BNB), wei
    uint256 private _poolValue = 0;
    // Pool proof of value (API keys e.t.c), JSON
    string private _proofOfValue = "";
    // deposit commission LPartner
    uint256 private _depositFixedFee;
    // Referral commission
    uint256 private _referralDepositFee;
    // Anual precent
    uint256 private _anualPrecent;
    // Penalty early withdraw token
    uint256 private _penaltyEarlyWithdraw;
    // Total investment limited partner
    uint256 private _totalInvestLpartner;
    // Premium fee for General partner
    uint256 private _premiumFee;
    // Address router contract to where we will invest/swap money automatically
    address private _routerContractAddress;
    // Address token to pair ETH/BNB
    address private _pairToken;

    uint256 mulitpierDefault = 100000;

    struct DepositToPool {
        uint256 amount;          // Amount of funds deposited
        uint256 time;            // Deposit time
        uint256 lock_period;     // Asset lock time
        bool refund_authorize;   // Are assets unlocked for withdrawal
        uint256 amountWithdrawal;
        address investedToken; // address(0) for ETH/BNB
    }

    //    struct DopositesLpartner {
    //        uint256 amount;
    //        uint256 time;
    //        uint256 lock_period;
    //        bool refund_authorize;
    ////        uint256 amountWithdrawal;
    //    }

    // Collection of investors who made a deposit ETH
    mapping(address => DepositToPool[]) private _deposites;
    // All referrals who are limited partners
    mapping(address => address) private _referrals;

    mapping(address => uint) private _liquidity;

    // Smart contract for requests deposit or withdraw
    IAssetsManageTeam private _assetsManageTeam;
    // Smart contract pool registry contract
    IPoolRegistry private _poolRegistry;
    // Calculate withdraw for team
    //    ICalculateWithdrawEth private _calculateWithdraw;

    modifier onlyAdmin(address sender) {
        if(
            hasRole(GENERAL_PARTNER_ROLE, sender) ||
            hasRole(SUPER_ADMIN_ROLE, sender) ||
            _poolRegistry.isTeam(sender)
        ) {
            _;
        } else {
            revert("The sender does not have permission");
        }
    }

    constructor(
    //        address token,
        string memory name,
        uint256 locked,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw,
        address superAdmin,
        address gPartner,
        address lPartner,
        address team,
        address poolRegistry,
        address returnInvestmentLpartner,
        IAssetsManageTeam assetsManageTeam,
        address routerContractAddress,
        address pairToken
    ) public {
        _name = name;
        //        _token = token;
        _lockPeriod = locked;
        _depositFixedFee = depositFixedFee;
        _referralDepositFee = referralDepositFee;
        _anualPrecent = anualPrecent;
        _penaltyEarlyWithdraw = penaltyEarlyWithdraw;
        _assetsManageTeam = assetsManageTeam;
        _poolRegistry = IPoolRegistry(poolRegistry);
        _routerContractAddress = routerContractAddress;
        _pairToken = pairToken;

        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, msg.sender);
        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, superAdmin);
        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, poolRegistry);

        PoolRoles.finalize();
        grantRole(GENERAL_PARTNER_ROLE, gPartner);
        grantRole(LIMITED_PARTNER_ROLE, lPartner);
        grantRole(STARTUP_TEAM_ROLE, team);
        grantRole(POOL_REGISTRY, poolRegistry);
        grantRole(RETURN_INVESTMENT_LPARTNER, returnInvestmentLpartner);

        //        _calculateWithdraw = calculateWithdraw;
    }

    fallback() external payable {
        if (msg.sender == address(_poolRegistry)) {
            return;
        }

//        if (!isContract(msg.sender)) {
//            if (!hasRole(LIMITED_PARTNER_ROLE, msg.sender)) {
//                _transferGeneralPartner(msg.value);
//                return;
//            }
//            _deposit(msg.sender, msg.value, mulitpierDefault);
//            return;
//        } else if(!hasRole(POOL_REGISTRY, msg.sender)) {
//            _transferGeneralPartner(msg.value);
//            return;
//        }
    }

    receive() external payable {
        if (msg.sender == address(_poolRegistry)) {
            return;
        }

//        if (!isContract(msg.sender)) {
//            if (!hasRole(LIMITED_PARTNER_ROLE, msg.sender)) {
//                _transferGeneralPartner(msg.value);
//                return;
//            }
//            _deposit(msg.sender, msg.value, mulitpierDefault);
//            return;
//        } else if(!hasRole(POOL_REGISTRY, msg.sender)) {
//            _transferGeneralPartner(msg.value);
//            return;
//        }
    }

    /**
    * @dev Get information about the user who made a deposit main network coin (ETH,BNB).
    * @param owner The address investor pool.
    * @param index The owner's deposit index.
    */
    function getDeposit(address owner, uint256 index) public view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken) {
        // TODO - add a amount depends from pool value
        return (
        _deposites[owner][index].amount,
        _deposites[owner][index].time,
        _deposites[owner][index].lock_period,
        _deposites[owner][index].refund_authorize,
        _deposites[owner][index].amountWithdrawal,
        _deposites[owner][index].investedToken
        );
    }

    /**
    * @dev Get the number of deposits main network coin (ETH,BNB) made by an investor.
    * @param owner The address investor.
    */
    function getDepositLength(address owner) public view returns(uint256) {
        return (_deposites[owner].length);
    }

    /**
    * @dev Get the referral account limited partner.
    */
    function getReferral(address lPartner) public view returns (address) {
        return _referrals[lPartner];
    }

    /**
    * @dev Get information by this pool.
    */
    function getInfoPool() public view
    returns(
        string memory name,
        bool isPublicPool,
        address token,
        uint256 locked
    )
    {
        return (
        _name,
        _isPublicPool,
        _token,
        _lockPeriod
        );
    }

    /**
* @dev Get information by this pool.
*/
    function getInfoPoolFees() public view
    returns(
        uint256 rate,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw,
        uint256 totalInvestLpartner,
        uint256 premiumFee
    )
    {
        return (
        _rate,
        _depositFixedFee,
        _referralDepositFee,
        _anualPrecent,
        _penaltyEarlyWithdraw,
        _totalInvestLpartner,
        _premiumFee
        );
    }

    /*************************************************************
    **************** METHODS RETURNS INVESTMENT ******************
    **************************************************************/

    /**
    * @dev Approve of a request for return investment. (RETURN_INVESTMENT_LPARTNER)
    * @param lPartner The address account with role Limited partner.
    * @param index Investment index.
    * @param amount Investment amount.
    * @return A boolean that indicates if the operation was successful.
    */
    function _approveWithdrawLpartner(address lPartner, uint256 index, uint256 amount, address investedToken) external onlyReturnsInvestmentLpartner returns (bool) {
        _deposites[lPartner][index].refund_authorize = true;
        _deposites[lPartner][index].amountWithdrawal = amount;
        _deposites[lPartner][index].investedToken = investedToken;
        return true;
    }

    /*************************************************************
    ****************** METHODS POOL REGISTRY *********************
    **************************************************************/

    /**
    * @dev Deposit main network coin (ETH,BNB). (POOL REGISTRY)
    * @param sender address sender transaction.
    * @param amount deposit ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _depositPoolRegistry(address sender, uint256 amount, uint256 feesMulitpier) external onlyPoolRegistry returns (bool) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");
        return _deposit(sender, amount, feesMulitpier);
    }

    /**
    * @dev Deposit Token. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @param amount Deposit ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _depositTokenPoolRegistry(address payable sender, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        return _depositToken(sender, amount);
    }

    /**
    * @dev Withdraw token recipient to TeamStartup. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @param amount Count sending ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _withdrawTeam (address payable sender, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        _assetsManageTeam._withdraw(address(this), sender, amount);

        sender.transfer(amount);

        return true;
    }

    /**
    * @dev Withdraw token recipient to TeamStartup. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @param amount Count sending ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _withdrawTokensToStartup(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        _assetsManageTeam._withdrawTokensToStartup(address(this),token, sender, amount);

        IERC20 tokenContract = IERC20(token);
        tokenContract.transfer(sender, amount);
        return true;
    }
    /**
    * @dev Withdraw token recipient to TeamStartup. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @param amount Count sending ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _returnsInTokensFromTeam(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        //        _assetsManageTeam._withdrawTokensToStartup(address(this),token, sender, amount);

        IERC20 tokenContract = IERC20(token);
        tokenContract.transferFrom(sender, address(this), amount);
        return true;
    }
    event DebugRemoveLiquidity(uint amountToken, uint amountETH,uint amounts0,uint amounts1);

    function _removeLiquidity(address sender) private returns (uint) {
//        uint256 totalDepositHalf = totalDeposit.div(2);
        IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(_routerContractAddress);
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH();
        path[1] = address(_pairToken);

        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Router02.factory());
        address pairAddress = factory.getPair(uniswapV2Router02.WETH(),address(_pairToken));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        pair.approve(_routerContractAddress,pair.totalSupply());

        /* function removeLiquidityETH(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);*/
        uint amountToken;
        uint amountETH;
        (amountToken,amountETH) = uniswapV2Router02.removeLiquidityETH(_pairToken,_liquidity[sender],0,0,address(this),block.timestamp + 10000);
        _liquidity[sender] = 0;

        address[] memory pathForSwap = new address[](2);
        pathForSwap[0] = address(_pairToken);
        pathForSwap[1] = uniswapV2Router02.WETH();

        /* function function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);*/
        uint[] memory amounts = uniswapV2Router02.swapExactTokensForETH(amountToken,0,pathForSwap,address(this),block.timestamp + 10000);
        uint amountETHreceivedFromSwap = amounts[1];
        emit DebugRemoveLiquidity(amountToken,amountETH,amounts[0],amounts[1]);
        // BUSD https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56 https://testnet.bscscan.com/address/0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47#code
        // wBNB https://bscscan.com/token/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c#writeContract https://testnet.bscscan.com/address/0xae13d989dac2f0debff460ac112a837c89baa7cd#code
        return (amountETHreceivedFromSwap + amountETH).mul(99).div(100);
    }

    /**
    * @dev Withdraw main network coin (ETH,BNB) or tokens BUSD/USDT to LPartner. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @return A boolean that indicates if the operation was successful.
    */
    function _withdrawLPartner(address payable sender) external onlyPoolRegistry returns (bool, uint256, address) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");

        uint256 totalAmountReturn = 0;
        uint256 teamReward = 0;
        DepositToPool memory deposit;
        uint256[3] memory indexesDeposit;
        uint8 indexDeposit = 0;
        address token = address(0);

        uint256 lenghtSender = getDepositLength(sender);

        //        require(lenghtOwner != 0, "InvestmentPool: getDepositLength is 0");

        for (uint256 i = 0; i < lenghtSender; i++) {
            (deposit.amount, deposit.time, deposit.lock_period, , , ) = getDeposit(sender, i);
            (, , , deposit.refund_authorize, deposit.amountWithdrawal, deposit.investedToken) = getDeposit(sender, i);
            if (deposit.refund_authorize) {
                totalAmountReturn += deposit.amountWithdrawal;
                indexesDeposit[indexDeposit] = i;
                indexDeposit++;
                _deposites[sender][i].refund_authorize = false;
                _deposites[sender][i].amountWithdrawal = 0;
                token = deposit.investedToken;
            }
        }
        //        require(totalAmountReturn != 0, "InvestmentPool: total amount for limited partner is 0");
        //        require(totalAmountReturn > address(this).balance, "InvestmentPool: totalAmountReturn >  address(this).balance");

        if (teamReward > 0) {
            payable(_poolRegistry.getTeamAddresses()[1]).transfer(teamReward);
        }

        if (totalAmountReturn > 0) {
            uint256 totalAmountReturnFinal = _removeLiquidity(sender);
            sender.transfer(totalAmountReturnFinal);
            return (true,totalAmountReturnFinal,token);
        }
        return (false,0,token);
    }

    /**
    * @dev Withdraw main network coin (ETH,BNB) or tokens BUSD/USDT to SuperAdmin  (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @return A boolean that indicates if the operation was successful.
    */
    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(SUPER_ADMIN_ROLE, sender), "InvestmentPool: the sender does not have permission");
        if (amount > 0) {
            if (token == address(0)) {
                sender.transfer(amount);
                return true;
            } else {
                IERC20 tokenContract = IERC20(token);
                tokenContract.transfer(sender, amount);
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Activate the pool for the possibility of main network coin (ETH,BNB) deposit. (POOL REGISTRY)
    * @return A boolean that indicates if the operation was successful.
    */
    function _activateDepositToPool() external onlyPoolRegistry returns (bool) {
        require(!_isPublicPool, "InvestmentPool: the pool is already activated");

        _isPublicPool = true;
        return true;
    }

    /**
    * @dev Disactivate the pool for the possibility of main network coin (ETH,BNB) deposit. (POOL REGISTRY)
    * @return A boolean that indicates if the operation was successful.
    */
    function _disactivateDepositToPool() external onlyPoolRegistry returns (bool) {
        require(_isPublicPool, "InvestmentPool: the pool is already deactivated");

        _isPublicPool = false;
        return true;
    }

    /**
    * @dev Set referral for limited partner. (POOL REGISTRY)
    * @param sender Address sender transaction.
    * @param lPartner referral limited partner.
    * @param referral for lPartner.
    * @return A boolean that indicates if the operation was successful.
    */
    function _setReferral(address sender, address lPartner, address referral) external onlyPoolRegistry onlyAdmin(sender) returns (bool) {
        _referrals[lPartner] = referral;
        return true;
    }

    /**
    * @dev Update data contract. (POOL REGISTRY)
    * @param name The name pool.
    * @param token The address token contract.
    * @param locked The address to query the wager of.
    * @param depositFixedFee Commission from the deposit Limited Partner.
    * @param referralDepositFee Commission from the deposit if the limited partner has a referral.
    * @param anualPrecent The annual percentage of tokens.
    * @param penaltyEarlyWithdraw The penalty for early withdraw.
    * @return A boolean that indicates if the operation was successful.
    */
    function _updatePool(
        string calldata name,
        bool isPublicPool,
        address token,
        uint256 locked,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 anualPrecent,
        uint256 penaltyEarlyWithdraw
    ) external onlyPoolRegistry returns (bool) {
        _name = name;
        _isPublicPool = isPublicPool;
        _token = token;
        _lockPeriod = locked;
        _depositFixedFee = depositFixedFee;
        _referralDepositFee = referralDepositFee;
        _anualPrecent = anualPrecent;
        _penaltyEarlyWithdraw = penaltyEarlyWithdraw;
        return true;
    }

    /**
    * @dev Set price token for One. (POOL REGISTRY)
    * @param rate new price token.
    * @return A boolean that indicates if the operation was successful.
    */
    function _setRate(uint256 rate) external onlyPoolRegistry returns (bool) {
        _rate = rate;
        return true;
    }

    /**
    * @dev set Pool value USD, wei / Pool value main network coin (ETH,BNB), wei / Pool proof of value (API keys e.t.c), JSON (POOL REGISTRY)
    * @param poolValueUSD new poolValueUSD.
    * @return A boolean that indicates if the operation was successful.
    */
    function _setPoolValues(uint256 poolValueUSD,uint256 poolValue,string calldata proofOfValue) external onlyPoolRegistry returns (bool) {
        _poolValueUSD = poolValueUSD;
        _poolValue = poolValue;
        _proofOfValue = proofOfValue;
        return true;
    }

    /**
    * @dev Get information by this pool.
    */
    function getPoolValues() public view
    returns(
        uint256 poolValueUSD,
        uint256 poolValue,
        string memory proofOfValue
    )
    {
        return (
        _poolValueUSD,
        _poolValue,
        _proofOfValue
        );
    }
    /**
     * @dev Deposit tokens (BUSD,USDT). (POOL REGISTRY)
     * @param sender address sender transaction.
     * @param amount deposit amount.
     * @param token address.
     * @return A boolean that indicates if the operation was successful.
     */
    function _depositInvestmentInTokensToPool(address payable sender, uint256 amount, address token) external onlyPoolRegistry returns (bool) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");
        uint256 depositFee = amount.mul(_depositFixedFee).div(100);
        uint256 depositFeeReferrer = amount.mul(_referralDepositFee).div(100);
        uint256 totalDeposit = 0;

        if (_referrals[sender] != address(0)) {
            totalDeposit = amount.sub(depositFee).sub(depositFeeReferrer);
        } else {
            totalDeposit = amount.sub(depositFee);
        }
        _deposites[sender].push(DepositToPool(
                totalDeposit,
                block.timestamp,
                _lockPeriod,
                false,
                0,
                token
            ));
        return true;
    }
//    function balanceOf(address addr) public view returns (uint) {
//        IPancakePair pairForInvest = IPancakePair(_pairForInvest);
//        address token0 = pairForInvest.token1();
//        IERC20 _token0 = IERC20(token0);
//        return _token0.balanceOf(addr);
//    }

    /*************************************************************
    ********************* PRIVATE METHODS ************************
    **************************************************************/
//    event DebugAddLiquidity(address token0,address token1, uint256 token0price, uint256 token1price,uint256 totalDepositHalf,uint256 totalDepositHalfInToken1);

    function _addLiquidity(uint256 totalDeposit,address sender) private returns (bool) {
        uint256 totalDepositHalf = totalDeposit.div(2);
        IUniswapV2Router02 UniswapV2Router02 = IUniswapV2Router02(_routerContractAddress);
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();
        path[1] = address(_pairToken);
        /* function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external  payable returns (uint[] memory amounts);*/
        uint[] memory amounts = UniswapV2Router02.swapExactETHForTokens{value: totalDepositHalf}(0,path,address(this),block.timestamp + 10000);
        uint amountTokenDesired = amounts[1];
        IERC20 _tokenWeenus = IERC20(_pairToken); // https://github.com/bokkypoobah/WeenusTokenFaucet
        _tokenWeenus.approve(_routerContractAddress,_tokenWeenus.totalSupply());
        uint amountToken;
        uint amountETH;
        uint liquidity;

        /*function addLiquidityETH( address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);*/
        (amountToken,amountETH,liquidity) = UniswapV2Router02.addLiquidityETH{value: totalDepositHalf}(_pairToken,amountTokenDesired,0,0,address(this),block.timestamp + 10000);
        _liquidity[sender] = _liquidity[sender] + liquidity;
        // function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        // BUSD https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56 https://testnet.bscscan.com/address/0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47#code
        // wBNB https://bscscan.com/token/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c#writeContract https://testnet.bscscan.com/address/0xae13d989dac2f0debff460ac112a837c89baa7cd#code
        return true;
    }
    /**
    * @dev Deposit main network coin (ETH,BNB). (PRIVATE METHOD)
    * @param sender Address sender transaction.
    * @param amount Count deposit ETH.
    * @return A boolean that indicates if the operation was successful.
    */
    function _deposit(address sender, uint256 amount, uint256 feesMulitpier) private returns (bool) {
        require(_isPublicPool, "InvestmentPool: pool deposit blocked");

        address payable team = payable(_poolRegistry.getTeamAddresses()[1]);
        uint256 depositFee = amount.mul(_depositFixedFee).div(100).mul(feesMulitpier).div(mulitpierDefault);
        uint256 depositFeeReferrer = amount.mul(_referralDepositFee).div(100).mul(feesMulitpier).div(mulitpierDefault);
        uint256 totalDeposit = 0;

        if (_referrals[sender] != address(0)) {
            payable(_referrals[sender]).transfer(depositFeeReferrer);
            team.transfer(depositFee);
            totalDeposit = amount.sub(depositFee).sub(depositFeeReferrer);
        } else {
            team.transfer(depositFee);
            totalDeposit = amount.sub(depositFee);
        }

        _deposites[sender].push(DepositToPool(
                totalDeposit,
                block.timestamp,
                _lockPeriod,
                false,
                0,
                address(0)
            ));

        _totalInvestLpartner = _totalInvestLpartner.add(amount);

        emit Deposit(sender, amount);
        return _addLiquidity(totalDeposit,sender);
    }



    /**
    * @dev Deposit Token. (PRIVATE METHOD)
    * @param sender Address sender transaction.
    * @param amount Count deposit Token.
    * @return A boolean that indicates if the operation was successful.
    */
    function _depositToken(address payable sender, uint256 amount) private returns (bool) {
        _assetsManageTeam._depositToken(address(this), sender, _token, amount);

        uint256 amountConverted = _getTokenAmount(amount);
        require(amountConverted <= address(this).balance, "InvestmentPool: contract balance is insufficient");
        // require(amount != 0, "InvestmentPool: contract balance is insufficient");

        sender.transfer(amountConverted);
        return true;
    }

    /**
    * @dev Transfer ETH on address General Partner. (PRIVATE METHOD)
    * @param amount Count sending token GPartner.
    */
    function _transferGeneralPartner(uint256 amount) private returns (bool) {
        address payable gPartner = payable(getMembersRole(GENERAL_PARTNER_ROLE)[0]);
        gPartner.transfer(amount);

        return true;
    }

    // ***** HELPERS ***** //
    /**
    * @dev Calculates the ratio of the number of tokens in relation to the rate ETH.
    */
    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        IERC20 _tokenContract = IERC20(_token);
        uint8 DECIMALS = _tokenContract.decimals();

        return (weiAmount.mul(_rate)).div(10 ** uint256(DECIMALS));
    }

    /**
    * @dev Checks if an address is a contract.
    */
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
        // retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    /**
    * @dev Remove element for current index.
    */
    function _removeIndexArray(uint256 index, DepositToPool[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }

        array.pop();
    }
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../GSN/Context.sol";

contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    // Collection roles and addresses
    mapping (bytes32 => RoleData) private _roles;
    // Roles and Role Addresses
    mapping (bytes32 => address[]) private _addressesRoles;
    
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMembersRole(bytes32 role) public view returns (address[] memory Accounts) {
        return _addressesRoles[role];
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }


    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            _addressesRoles[role].push(account);
            
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            for (uint256 i; i < _addressesRoles[role].length; i++) {
                if (_addressesRoles[role][i] == account) {
                    _removeIndexArray(i, _addressesRoles[role]);
                    break;
                }
            }

            emit RoleRevoked(role, account, _msgSender());
        }
    }
    
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        
        array.pop();
    }
}

pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "../ownership/Ownable.sol";
import "../interface/IRoleModel.sol";

contract PoolRoles is AccessControl, Ownable, IRoleModel {
    bool private _finalized = false;
    event Finalized();

    modifier onlyGPartner() {
        require(hasRole(GENERAL_PARTNER_ROLE, msg.sender), "Roles: caller does not have the general partner role");
        _;
    }

    modifier onlyLPartner() {
        require(hasRole(LIMITED_PARTNER_ROLE, msg.sender), "Roles: caller does not have the limited partner role");
        _;
    }

    modifier onlyStartupTeam() {
        require(hasRole(STARTUP_TEAM_ROLE, msg.sender), "Roles: caller does not have the team role");
        _;
    }

    modifier onlyPoolRegistry() {
        require(hasRole(POOL_REGISTRY, msg.sender), "Roles: caller does not have the pool regystry role");
        _;
    }

    modifier onlyReturnsInvestmentLpartner() {
        require(hasRole(RETURN_INVESTMENT_LPARTNER, msg.sender), "Roles: caller does not have the return invesment lpartner role");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE, msg.sender), "Roles: caller does not have oracle role");
        _;
    }

    constructor () public {
        _setRoleAdmin(GENERAL_PARTNER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(LIMITED_PARTNER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(STARTUP_TEAM_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(POOL_REGISTRY, SUPER_ADMIN_ROLE);
        _setRoleAdmin(RETURN_INVESTMENT_LPARTNER, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ORACLE, SUPER_ADMIN_ROLE);
    }

    /**
     * @dev Create and ading new role.
     * @param role role account.
     * @param account account for adding to the role.
     */
    function addAdmin(bytes32 role, address account) public onlyOwner returns (bool) {
        require(!_finalized, "ManagerRole: already finalized");

        _setupRole(role, account);
        return true;
    }

    /**
     * @dev Block adding admins.
     */
    function finalize() public onlyOwner {
        require(!_finalized, "ManagerRole: already finalized");

        _finalized = true;
        emit Finalized();
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

interface IPoolRegistry {
    function isTeam(address account) external view returns (bool);

    function getTeamAddresses() external view returns (address[] memory);
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

pragma solidity >=0.4.18;
interface IwBNB {
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    function deposit()  external payable;
    function withdraw(uint wad)  external ;
    function approve(address guy, uint wad)  external returns (bool);
    function transfer(address dst, uint wad)  external returns (bool);
    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
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

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
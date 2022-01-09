pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BondingCurveToken.sol";
import "./BondingCurveVault.sol";
import "../interfaces/IBancorFormula.sol";
import "../interfaces/IBondingCurve.sol";
import "../interfaces/IEndowment.sol";
import "../IExtension.sol";
import "../../utils/Arrays.sol";
import "../../core/DaoRegistry.sol";
import "../../core/DaoConstants.sol";
import "../../guards/MemberGuard.sol";
import "../interfaces/IBank.sol";

contract BondingCurve is 
    IExtension,
    IBondingCurve,
    DaoConstants,
    MemberGuard,
    Initializable,
    Context,
    Ownable,
    Pausable,
    ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath  for uint256;
    using Address   for address;
    using Arrays    for address[];

    uint256 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10 ** 16; 100% = 10 ** 18
    uint32  public constant PPM      = 1000000;
    address public constant ETH = address(0);
    

    string private constant ERROR_CONTRACT_IS_EOA                = "MM_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_BENEFICIARY            = "MM_INVALID_BENEFICIARY";
    string private constant ERROR_INVALID_VESTING                = "MM_INVALID_VESTING";
    string private constant ERROR_INVALID_STAKING                = "MM_INVALID_STAKING";
    string private constant ERROR_INVALID_PERCENTAGE             = "MM_INVALID_PERCENTAGE";
    string private constant ERROR_INVALID_RESERVE_RATIO          = "MM_INVALID_RESERVE_RATIO";
    string private constant ERROR_INVALID_TM_SETTING             = "MM_INVALID_TM_SETTING";
    string private constant ERROR_INVALID_COLLATERAL             = "MM_INVALID_COLLATERAL";
    string private constant ERROR_INVALID_COLLATERAL_VALUE       = "MM_INVALID_COLLATERAL_VALUE";
    string private constant ERROR_INVALID_BOND_AMOUNT            = "MM_INVALID_BOND_AMOUNT";
    string private constant ERROR_COLLATERAL_ALREADY_WHITELISTED = "MM_COLLATERAL_ALREADY_WHITELISTED";
    string private constant ERROR_COLLATERAL_NOT_WHITELISTED     = "MM_COLLATERAL_NOT_WHITELISTED";
    string private constant ERROR_SLIPPAGE_EXCEEDS_LIMIT         = "MM_SLIPPAGE_EXCEEDS_LIMIT";
    string private constant ERROR_TRANSFER_FAILED                = "MM_TRANSFER_FAILED";
    string private constant ERROR_NOT_BUY_FUNCTION               = "MM_NOT_BUY_FUNCTION";
    string private constant ERROR_BUYER_NOT_FROM                 = "MM_BUYER_NOT_FROM";
    string private constant ERROR_COLLATERAL_NOT_SENDER          = "MM_COLLATERAL_NOT_SENDER";
    string private constant ERROR_DEPOSIT_NOT_AMOUNT             = "MM_DEPOSIT_NOT_AMOUNT";
    string private constant ERROR_NO_PERMISSION                  = "MM_NO_PERMISSION";
    string private constant ERROR_TOKEN_NOT_SENDER               = "MM_TOKEN_NOT_SENDER";
    string private constant ERROR_INVALID_BUY_ORDER_DATA         = "MM_INVALID_BUY_ORDER_DATA";
    string private constant ERROR_BAD_TIMES                      = "MM_BAD_TIMES";

    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    uint256 public funding_goal; // = 50000 * 10 ** 18;

    modifier timeBuy {
        require(block.timestamp >= timeStart && block.timestamp < timeCooldown, ERROR_BAD_TIMES);
        _;
    }

    modifier timeSell {
        uint256 _amount;
        if (_collaterals[0] == ETH) {
            _amount = address(reserve).balance;
        }else {
           _amount = IERC20(_collaterals[0]).balanceOf(address(reserve));
        }
        require(block.timestamp >= timeStart && (block.timestamp < timeEnd || _amount < funding_goal), ERROR_BAD_TIMES);
        _;
    }

    modifier timeClaim {
        require(block.timestamp >= timeEnd, ERROR_BAD_TIMES);
        _;
    }

    modifier timeClaimAndFundingGoal {
        uint256 _amount;
        if (_collaterals[0] == ETH) {
            _amount = address(reserve).balance;
        }else {
           _amount = IERC20(_collaterals[0]).balanceOf(address(reserve));
        }
        require(block.timestamp >= timeEnd && _amount >= funding_goal, ERROR_BAD_TIMES);
        _;
    }

    struct Collateral {
        uint256 virtualSupply;
        uint256 virtualBalance;
        bool    whitelisted;
        uint32  reserveRatio;
    }

    IERC20 public token;
    IBondingCurveToken public bondingToken;
    IBondingCurveVault public reserve;
    address public movement;
    IEndowment public endowment;
    uint256 public intiative_goal;
    address public beneficiary;
    IBancorFormula public formula;

    uint256 public buyFeePct;
    uint256 public sellFeePct;
    uint64 public timeStart;
    uint64 public timeCooldown;
    uint64 public timeEnd;
    bool private _bonding_initialized;

    address public vesting;
    address public staking;
    uint256 public vestingPercent = 2;
    uint256 public stakingPercent = 2;
    
    DaoRegistry public _dao;

    mapping(address => Collateral) public collaterals;
    address[] private _collaterals;

    event Withdraw(
        address endowment,
        address[] _collaterals,
        uint256[] balances);
    event UpdateBeneficiary(address indexed beneficiary);
    event UpdateFormula(address indexed formula);
    event UpdateFees(
        uint256 buyFeePct,
        uint256 sellFeePct);
    event AddCollateralToken(
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32  reserveRatio);
    event RemoveCollateralToken(
        address indexed collateral);
    event UpdateCollateralToken(
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32  reserveRatio);
    event MakeBuyOrder(
        address indexed buyer,
        address indexed collateral,
        uint256 fee,
        uint256 purchaseAmount,
        uint256 returnedAmount,
        uint256 feePct);
    event MakeSellOrder(
        address indexed seller,
        address indexed collateral,
        uint256 fee,
        uint256 sellAmount,
        uint256 returnedAmount,
        uint256 feePct);
    event ClaimTokens(
        address indexed seller,
        uint256 amount
    );

    /***** external function *****/

    function initialize(DaoRegistry dao, address creator) external override initializer {
        _dao = dao;
        _transferOwnership(creator);
    }

    /**
     * @notice Initialize market maker
     * @param _formula      The address of the BancorFormula [computation] contract
     * @param _movement     The address of the Movement contract
     * @param _endowment    The address of the Endowment contract
     * @param _intiative_goal The amount sent to Endowment contract Endowment balance in ppm
     * @param _beneficiary  The address of the beneficiary [to whom fees are to be sent]
     * @param _buyFeePct    The fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct   The fee to be deducted from sell orders [in PCT_BASE]
     * @param _timeStart    The timestamp when bonding starts
     * @param _timeCooldown The timestamp when only token sales available
     * @param _timeEnd      The timestamp when bonding ends
    */
    function initializeCurve(
        IBancorFormula               _formula,
        address                      _movement,
        address                      _endowment,
        uint256                      _intiative_goal,
        address                      _beneficiary,
        uint256                      _buyFeePct,
        uint256                      _sellFeePct,
        uint64                       _timeStart,
        uint64                       _timeCooldown,
        uint64                       _timeEnd
    )
        external override 
    {
        require(!_bonding_initialized, "already initialized");
        require(address(_formula).isContract(), ERROR_CONTRACT_IS_EOA);
        require(address(_endowment).isContract(), ERROR_CONTRACT_IS_EOA);
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);
        require(_feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct), ERROR_INVALID_PERCENTAGE);
        require(block.timestamp < _timeStart && _timeStart < _timeCooldown && _timeCooldown < _timeEnd, ERROR_BAD_TIMES);

        bondingToken = new BondingCurveToken();
        formula = _formula;
        reserve = new BondingCurveVault();
        movement = _movement;
        endowment = IEndowment(_endowment);
        intiative_goal = _intiative_goal;
        beneficiary = _beneficiary;
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;
        timeStart = _timeStart;
        timeCooldown = _timeCooldown;
        timeEnd = _timeEnd;
        _bonding_initialized = true;
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        if (data.length == 0) {
            makeBuyOrder(msg.sender, address(0), msg.value, 1);
        }
    }

    function setTokenAndFundingGoal(address _token, uint256 _fundingGoal) external override onlyOwnerOrServiceProvider(owner(), _dao) {
        token = IERC20(_token);
        funding_goal = _fundingGoal;
    }

    function withdraw() external timeClaimAndFundingGoal onlyOwnerOrServiceProvider(owner(), _dao) {
       IBank bank = IBank(_dao.getExtensionAddress(BANK));
       bank.addToBalance(
            address(this),
            UNITS,
            bondingToken.totalSupply()
        );

        if (address(reserve).balance > 0) {
            reserve.transferETH(address(this), address(reserve).balance);
        } 

        uint256[] memory balances = new uint256[](_collaterals.length);
        for (uint256 i = 0; i < _collaterals.length;) {
            address tkn = _collaterals[i];
            if (tkn == address(0)) {
                uint256 balance = address(this).balance;
                balances[i] = balance;
                if (balance > 0) {
                    endowment.addERC20Balance{ value: intiative_goal }(movement, address(0), address(0),
                    intiative_goal, IEndowment.BALANCE_TYPE.INITIATIVE_BALANCE);
                    endowment.addERC20Balance{ value: balance - intiative_goal }(movement, address(0), address(0),
                        balance - intiative_goal, IEndowment.BALANCE_TYPE.ENDOWMENT_BALANCE);
                }
            } else {
                uint256 tbalance = IERC20(tkn).balanceOf(address(reserve));
                balances[i] = tbalance;
                if (tbalance > 0) {
                    reserve.approve(tkn, address(endowment), tbalance);
                    endowment.addERC20Balance(movement, tkn, address(reserve),
                        intiative_goal, IEndowment.BALANCE_TYPE.INITIATIVE_BALANCE);
                    endowment.addERC20Balance(movement, tkn, address(reserve),
                        tbalance - intiative_goal, IEndowment.BALANCE_TYPE.ENDOWMENT_BALANCE);
                }
            }
            unchecked{ i++; }
        }
        emit Withdraw(address(endowment), _collaterals, balances);
    }

    /**
     * @notice Put contract on pause [buy, sell, claim stopped]
    */
    function pause() external onlyOwnerOrServiceProvider(owner(), _dao) {
        super._pause();
    }

    /**
     * @notice Resume contract from pause [buy, sell, claim allowed]
    */
    function resume() external onlyOwnerOrServiceProvider(owner(), _dao) {
        super._unpause();
    }

    /* generic settings related function */

    /**
     * @notice Update formula to `_formula`. COMMENTED DUE TO CONTRACT SIZE.
     * @param _formula The address of the new BancorFormula [computation] contract
    */
    /*function updateFormula(IBancorFormula _formula) external onlyOwner {
        require(address(_formula).isContract(), ERROR_CONTRACT_IS_EOA);

        _updateFormula(_formula);
    }*/

    /**
     * @notice Update beneficiary to `_beneficiary`. COMMENTED DUE TO CONTRACT SIZE.
     * @param _beneficiary The address of the new beneficiary [to whom fees are to be sent]
    */
    /*function updateBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);

        _updateBeneficiary(_beneficiary);
    }*/

    /**
     * @notice Update fees deducted from buy and sell orders to respectively `@formatPct(_buyFeePct)`% and `@formatPct(_sellFeePct)`%
     * @param _buyFeePct  The new fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct The new fee to be deducted from sell orders [in PCT_BASE]
    */
/*    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external onlyOwnerOrServiceProvider(owner(), _dao) {
        require(_feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct), ERROR_INVALID_PERCENTAGE);

        _updateFees(_buyFeePct, _sellFeePct);
    }
*/
    /* collateral tokens related functions */

    /**
     * @notice Add `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
    */
    function addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio)
        external override onlyOwnerOrServiceProvider(owner(), _dao)
    {
        require(_collateral == ETH || IERC20(_collateral).totalSupply() > 0, ERROR_INVALID_COLLATERAL);
        require(!_collateralIsWhitelisted(_collateral),                     ERROR_COLLATERAL_ALREADY_WHITELISTED);
        require(_reserveRatioIsValid(_reserveRatio),                        ERROR_INVALID_RESERVE_RATIO);

        _addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio);
    }

    /**
      * COMMENTED DUE TO CONTRACT SIZE.
      * @notice Remove `_collateral.symbol(): string` as a whitelisted collateral token
      * @param _collateral The address of the collateral token to be un-whitelisted
    */
    /*function removeCollateralToken(address _collateral) external onlyOwner {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);

        _removeCollateralToken(_collateral);
    }*/

    /**
     * COMMENTED DUE TO CONTRACT SIZE.
     * @notice Update `_collateral.symbol(): string` collateralization settings
     * @param _collateral     The address of the collateral token whose collateralization settings are to be updated
     * @param _virtualSupply  The new virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The new virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The new reserve ratio to be used for that collateral token [in PPM]
    */
    /*function updateCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio)
        external onlyOwner
    {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_reserveRatioIsValid(_reserveRatio),   ERROR_INVALID_RESERVE_RATIO);

        _updateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio);
    }*/

    /**
     * @notice Update vesting to `_vesting`
     * @param _vesting The address of the new vesting [to whom vesting amount are to be sent]
    */
    function updateVesting(
        address _vesting, 
        uint256 _percentVesting,
        address _staking, 
        uint256 _percentStaking
    ) external onlyOwnerOrServiceProvider(owner(), _dao) {
        staking = _staking;
        stakingPercent = _percentStaking;

        vesting = _vesting;
        vestingPercent = _percentVesting;
    }


    /* market making related functions */

    /**
     * @notice Make a buy order worth `@tokenAmount(_collateral, _depositAmount)` for atleast `@tokenAmount(self.token(): address, _minReturnAmountAfterFee)`
     * @param _buyer The address of the buyer
     * @param _collateral The address of the collateral token to be deposited
     * @param _depositAmount The amount of collateral token to be deposited
     * @param _minReturnAmountAfterFee The minimum amount of the returned bonded tokens
     */
    function makeBuyOrder(address _buyer, address _collateral, uint256 _depositAmount, uint256 _minReturnAmountAfterFee)
        public payable nonReentrant whenNotPaused timeBuy
    {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_collateralValueIsValid(_collateral, _depositAmount), ERROR_INVALID_COLLATERAL_VALUE);

        uint256 fee = _depositAmount.mul(buyFeePct).div(PCT_BASE);
        uint256 depositAmountLessFee = _depositAmount.sub(fee);

        uint256 collateralSupply = bondingToken.totalSupply().add(collaterals[_collateral].virtualSupply);
        uint256 collateralBalanceOfReserve = _balanceOf(address(reserve), _collateral).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        uint256 returnAmount = formula.calculatePurchaseReturn(collateralSupply, collateralBalanceOfReserve, reserveRatio, depositAmountLessFee);

        // collect fee and collateral
        if (_collateral == ETH) {
            (bool success, ) = address(reserve).call{value: _depositAmount}(new bytes(0));
            require(success, ERROR_TRANSFER_FAILED);
        } else {
            IERC20(_collateral).safeTransferFrom(_buyer, address(reserve), _depositAmount);
        }

        // deduct fee
        if (fee > 0) {
            reserve.transfer(_collateral, beneficiary, fee);
        }

        require(returnAmount >= _minReturnAmountAfterFee, ERROR_SLIPPAGE_EXCEEDS_LIMIT);

        if (returnAmount > 0) {
            bondingToken.mint(_buyer, returnAmount);
        }

        emit MakeBuyOrder(_buyer, _collateral, fee, depositAmountLessFee, returnAmount, buyFeePct);
    }

    /**
     * @notice Make a sell order worth `@tokenAmount(self.token(): address, _sellAmount)` for atleast `@tokenAmount(_collateral, _minReturnAmountAfterFee)`
     * @param _seller The address of the seller
     * @param _collateral The address of the collateral token to be returned
     * @param _sellAmount The amount of bonded token to be spent
     * @param _minReturnAmountAfterFee The minimum amount of the returned collateral tokens
     */
    function makeSellOrder(address _seller, address _collateral, uint256 _sellAmount, uint256 _minReturnAmountAfterFee)
        external nonReentrant whenNotPaused timeSell
    {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_bondAmountIsValid(_seller, _sellAmount), ERROR_INVALID_BOND_AMOUNT);

        uint256 collateralSupply = bondingToken.totalSupply().add(collaterals[_collateral].virtualSupply);
        uint256 collateralBalanceOfReserve = _balanceOf(address(reserve), _collateral).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        uint256 returnAmount = formula.calculateSaleReturn(collateralSupply, collateralBalanceOfReserve, reserveRatio, _sellAmount);

        uint256 fee = returnAmount.mul(sellFeePct).div(PCT_BASE);
        uint256 returnAmountLessFee = returnAmount.sub(fee);

        require(returnAmountLessFee >= _minReturnAmountAfterFee, ERROR_SLIPPAGE_EXCEEDS_LIMIT);

        bondingToken.burn(_seller, _sellAmount);

        if (returnAmountLessFee > 0) {
            if (_collateral == ETH) {
                reserve.transferETH(_seller, returnAmountLessFee);
            } else {
                reserve.transfer(_collateral, _seller, returnAmountLessFee);
            }
        }
        if (fee > 0) {
            if (_collateral == ETH) {
                reserve.transferETH(beneficiary, returnAmountLessFee);
            } else {
               reserve.transfer(_collateral, beneficiary, fee);
            }
        }

        emit MakeSellOrder(_seller, _collateral, fee, _sellAmount, returnAmountLessFee, sellFeePct);
    }

    /**
     * @notice Claims user tokens depends on internal balance
     */
    function claimTokens() external whenNotPaused timeClaim {
        address sender = _msgSender();
        uint256 balance = bondingToken.balanceOf(sender);
        require(balance != 0, 'insufficient funds');
        DaoRegistry(payable(movement)).potentialNewMember(sender);
        bondingToken.burn(sender, balance);
        token.safeTransfer(sender, balance);
        if (stakingPercent > 0 && vestingPercent > 0) {
            token.safeTransfer(vesting, balance * vestingPercent / PPM );
            token.safeTransfer(staking, balance * stakingPercent / PPM );
        }
        emit ClaimTokens(sender, balance);
    }

    /***** public view functions *****/

    function getCollateralToken(address _collateral) public view returns (bool, uint256, uint256, uint32) {
        Collateral storage collateral = collaterals[_collateral];

        return (collateral.whitelisted, collateral.virtualSupply, collateral.virtualBalance, collateral.reserveRatio);
    }

    function getStaticPricePPM(uint256 _supply, uint256 _balance, uint32 _reserveRatio)
        public pure returns (uint256)
    {
        return uint256(PPM).mul(uint256(PPM)).mul(_balance).div(_supply.mul(uint256(_reserveRatio)));
    }

    /**
     * @notice Evaluate a buy order amount
     * @param _collateral The address of the collateral token to be deposited
     * @param _depositAmount The amount of collateral token to be deposited
     */
    function evaluateBuyOrder(address _collateral, uint256 _depositAmount) public view returns (uint256 returnAmount)
    {
        uint256 fee = _depositAmount.mul(buyFeePct).div(PCT_BASE);
        uint256 depositAmountLessFee = _depositAmount.sub(fee);

        uint256 collateralSupply = bondingToken.totalSupply().add(collaterals[_collateral].virtualSupply);
        uint256 collateralBalanceOfReserve = _balanceOf(address(reserve), _collateral).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        returnAmount = formula.calculatePurchaseReturn(collateralSupply, collateralBalanceOfReserve, reserveRatio, depositAmountLessFee);
    }

    /**
     * @notice Evaluate a sell order amount
     * @param _collateral The address of the collateral token to be returned
     * @param _sellAmount The amount of bonded token to be spent
     */
    function evaluateSellOrder(address _collateral, uint256 _sellAmount) public view returns (uint256 returnAmount)
    {
        uint256 collateralSupply = bondingToken.totalSupply().add(collaterals[_collateral].virtualSupply);
        uint256 collateralBalanceOfReserve = _balanceOf(address(reserve), _collateral).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        returnAmount = formula.calculateSaleReturn(collateralSupply, collateralBalanceOfReserve, reserveRatio, _sellAmount);

        uint256 fee = returnAmount.mul(sellFeePct).div(PCT_BASE);
        returnAmount = returnAmount.sub(fee);
    }

    /***** internal functions *****/

    /* check functions */

    function _balanceOf(address _who, address _token) internal view returns (uint256) {
        return _token == ETH ? _who.balance : IERC20(_token).balanceOf(_who);
    }

    function _beneficiaryIsValid(address _beneficiary) internal pure returns (bool) {
        return _beneficiary != address(0);
    }

    function _feeIsValid(uint256 _fee) internal pure returns (bool) {
        return _fee < PCT_BASE;
    }

    function _reserveRatioIsValid(uint32 _reserveRatio) internal pure returns (bool) {
        return _reserveRatio <= PPM;
    }

    function _collateralValueIsValid(address _collateral, uint256 _value)
        internal view returns (bool)
    {
        if (_value == 0) {
            return false;
        }

        if (_collateral == ETH) {
            return msg.value == _value;
        }

        return msg.value == 0;
    }

    function _bondAmountIsValid(address _seller, uint256 _amount) internal view returns (bool) {
        return _amount != 0 && bondingToken.balanceOf(_seller) >= _amount;
    }

    function _collateralIsWhitelisted(address _collateral) internal view returns (bool) {
        return collaterals[_collateral].whitelisted;
    }

    /* state modifiying functions */

    /*function _updateBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;

        emit UpdateBeneficiary(_beneficiary);
    }*/

    /*function _updateFormula(IBancorFormula _formula) internal {
        formula = _formula;

        emit UpdateFormula(address(_formula));
    }*/

    function _updateFees(uint256 _buyFeePct, uint256 _sellFeePct) internal {
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;

        emit UpdateFees(_buyFeePct, _sellFeePct);
    }

    function _addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio)
        internal
    {
        Collateral storage collateral = collaterals[_collateral];
        collateral.whitelisted = true;
        collateral.virtualSupply = _virtualSupply;
        collateral.virtualBalance = _virtualBalance;
        collateral.reserveRatio = _reserveRatio;
        _collaterals.push(_collateral);
        emit AddCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio);
    }

    /*function _removeCollateralToken(address _collateral) internal {
        delete collaterals[_collateral];
        _collaterals.removeOne(_collateral);

        emit RemoveCollateralToken(_collateral);
    }*/

    /*function _updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio
    )
        internal
    {
        collaterals[_collateral].virtualSupply = _virtualSupply;
        collaterals[_collateral].virtualBalance = _virtualBalance;
        collaterals[_collateral].reserveRatio = _reserveRatio;

        emit UpdateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio);
    }*/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBondingCurveToken.sol";


/**
 * @dev Cut ERC20 interface.
 */
contract BondingCurveToken is 
    IBondingCurveToken,
    Ownable {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function burn(address from, uint256 amount) external onlyOwner override {
        _burn(from, amount);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function mint(address to, uint256 amount) external onlyOwner override {
        _mint(to, amount);    
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBondingCurveVault.sol";


contract BondingCurveVault is 
    IBondingCurveVault,
    Ownable {
    using SafeERC20 for IERC20;
    
    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    } 

    /**
    * @notice Transfer `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function transfer(address _token, address _to, uint256 _value) external override onlyOwner {
        IERC20(_token).safeTransfer(_to, _value);
        emit TransferToken(_token, _to, _value);
    }

    /**
    * @notice Approve `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function approve(address _token, address _to, uint256 _value) external override onlyOwner {
        IERC20(_token).safeApprove(_to, _value);
        emit ApproveToken(_token, _to, _value);
    }

    /**
    * @notice Transfer `_value` of ETH from the Vault to `_to`
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function transferETH(address _to, uint256 _value) external override onlyOwner {
        require(address(this). balance >= _value, "BONDINGCURVEVAULT: not enought funds");
        (bool success, ) = _to.call{ value: _value}("1");
        require(success, 'ETH_TRANSFER_FAILED');
        emit TransferETH(_to, _value);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./IBancorFormula.sol";

/*
    Bancor Formula interface
*/
interface IBondingCurve {

    function initializeCurve(
        IBancorFormula               _formula,
        address                      _movement,
        address                      _endowment,
        uint256                      _endowment_ppm,
        address                      _beneficiary,
        uint256                      _buyFeePct,
        uint256                      _sellFeePct,
        uint64                       _timeStart,
        uint64                       _timeCooldown,
        uint64                       _timeEnd
    ) external;

    function addCollateralToken(
        address _collateral, 
        uint256 _virtualSupply, 
        uint256 _virtualBalance, 
        uint32 _reserveRatio
    ) external;
    
    function setTokenAndFundingGoal(address _token, uint256 _fundingGoal) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IEndowment {
    enum BALANCE_TYPE {
        INITIATIVE_BALANCE,
        ENDOWMENT_BALANCE
    }

    function balanceOf(address _movement) external view returns(address, uint256[2] memory);
    function balanceOfErc20(address _movement, address _token) 
        external view returns(address, uint256[2] memory);

    function addMovement(
        address _movement,
        address _token,
        address _creator
    ) external;

    function addBalance(
        address _movement,
        uint256 _amount,
        BALANCE_TYPE _type
    ) external;

    function subBalance(
        address _movement,
        uint256 _amount,
        BALANCE_TYPE _type
    ) external;

    function addERC20Balance(
        address _movement,
        address _token,
        address _from,
        uint256 _amount,
        BALANCE_TYPE _type
    ) external payable;

    function subERC20Balance(
        address _movement,
        address _token,
        address _to,
        uint256 _amount,
        BALANCE_TYPE _type
    ) external;

    function addERC721(
        address _movement,
        address _token,
        address _from,
        uint256 _tokenId,
        BALANCE_TYPE _type
    ) external;

    function subERC721(
        address _movement,
        address _token,
        address _to,
        uint256 _tokenId,
        BALANCE_TYPE _type
    ) external;
}

pragma solidity ^0.8.0;
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Remove first matched element from array
     *
     */
    function removeOne(address[] storage array, address value) internal returns (bool) {
        uint256 i;
        uint256 length = array.length;
        while (i < length) {
            if (array[i] == value) {
                array[i] = array[length - 1];
                array.pop();
                return true;
            }
            unchecked { i++; }
        }
        return false;
    }
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import './DaoConstants.sol';
import '../guards/AdapterGuard.sol';
import '../guards/MemberGuard.sol';
import '../extensions/IExtension.sol';
import './interfaces/IDaoFactory.sol';
import './interfaces/IDaoRegistry.sol';
/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract DaoRegistry is MemberGuard, IDaoRegistry,  AdapterGuard {
    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern

    enum DaoState {
        CREATION,
        READY
    }
    /*
     * EVENTS
     */
    /// @dev - Events for Proposals
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);

    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);

    /// @dev - Events for Members
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    enum MemberFlag {
        EXISTS,
        VETOER,
        SERVICE_PROVIDER
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED,
        VETO
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        ADD_VETOER,
        REMOVE_VETOER,
        ADD_SERVICE_PROVIDER,
        REMOVE_SERVICE_PROVIDER,
        ADD_MOVEMENT
    }

    /*
     * STRUCTURES
     */
    struct Proposal {
        // the structure to track all the proposals in the DAO
        address adapterAddress; // the adapter address that called the functions to change the DAO state
        uint256 flags; // flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }

    struct Member {
        // the structure to track all the members in the DAO
        uint256 flags; // flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        // A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
    }

    struct CreatedMovement {
        string name;
        address movement;
        string cid;
    }

    /*
     * PUBLIC VARIABLES
     */
    mapping(address => Member) public members; // the map to track all members of the DAO

    address[] private _members;

    // delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    // memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) checkpoints;
    // memberAddress => numDelegateCheckpoints
    mapping(address => uint32) numCheckpoints;

    DaoState public state;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    bytes32[] private _proposals;
    /// @notice The map that tracks the voting adapter address per proposalId
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO
    mapping(bytes32 => address) public extensions;

    mapping(bytes32 => address) public factories;

    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters
    mapping(bytes32 => uint256) public mainConfiguration;
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice The map created movements
    mapping(bytes32 => CreatedMovement) public movements;

    uint256 public lockedAt;

    /// @notice Clonable contract must have an empty constructor
    // constructor() {
    // }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    function initialize(address creator, address payer) external {
        require(!initialized, 'dao already initialized');
        potentialNewMember(msg.sender);
        potentialNewMember(payer);
        potentialNewMember(creator);

        initialized = true;
    }

    /**
     * @notice default fallback function to prevent from sending ether to the contract
     */
    receive() external payable {
        revert('you cannot send money back directly');
    }

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        state = DaoState.READY;
    }

    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        if (!getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                'member address already taken as delegated key'
            );
            member.flags = setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[BANK];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    // Vetoer
    function isVetoer(address addr) public view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.VETOER);
    }

    function addVetoer(address memberAddress)
        public
        hasAccess(this, AclFlag.ADD_VETOER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (!getFlag(member.flags, uint8(MemberFlag.VETOER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.VETOER),
                    true
                );
            }
        }
    }

    function removeVetoer(address memberAddress)
        public
        hasAccess(this, AclFlag.REMOVE_VETOER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (getFlag(member.flags, uint8(MemberFlag.VETOER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.VETOER),
                    false
                );
            }
        }
    }

    // ServiceProvider
    function isServiceProvider(address addr) public override view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.SERVICE_PROVIDER);
    }

    function addServiceProvider(address memberAddress)
        public
        hasAccess(this, AclFlag.ADD_SERVICE_PROVIDER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (!getFlag(member.flags, uint8(MemberFlag.SERVICE_PROVIDER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.SERVICE_PROVIDER),
                    true
                );
            }
        }
    }

    function removeServiceProvider(address memberAddress)
        public
        hasAccess(this, AclFlag.REMOVE_SERVICE_PROVIDER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (getFlag(member.flags, uint8(MemberFlag.SERVICE_PROVIDER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.SERVICE_PROVIDER),
                    false
                );
            }
        }
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    function addFactory(bytes32 factoryId, address factrory) external {
        require(factoryId != bytes32(0), 'factory id must not be empty');
        require(
            factories[factoryId] == address(0x0),
            'factory Id already in use'
        );
        factories[factoryId] = factrory;
    }

    function getFactoryAddress(bytes32 factoryId)
        external
        view
        returns (address)
    {
        require(factories[factoryId] != address(0), 'factory not found');
        return factories[factoryId];
    }

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     * @param creator The DAO's creator, who will be an initial member
     */
    function addExtension(
        bytes32 extensionId,
        IExtension extension,
        address creator
    ) external override hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(extensionId != bytes32(0), 'extension id must not be empty');
        require(
            extensions[extensionId] == address(0x0),
            'extension Id already in use'
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        extension.initialize(this, creator);
        emit ExtensionAdded(extensionId, address(extension));
    }

    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), 'not an adapter');
        require(isExtension(extensionAddress), 'not an extension');
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), 'adapterId must not be empty');

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                'adapterAddress already in use'
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extensionId must not be empty');
        require(
            extensions[extensionId] != address(0x0),
            'extensionId not registered'
        );
        delete inverseExtensions[extensions[extensionId]];
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) public view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), 'adapter not found');
        return adapters[adapterId];
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        override
        returns (address)
    {
        require(extensions[extensionId] != address(0), 'extension not found');
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */
    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        public
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), 'invalid proposalId');
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            'proposalId must be unique'
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    function vetoProposal(bytes32 proposalId, address vetoer)
        external
        onlyVetoer(this, vetoer)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;

        require(
            msg.sender == vetoer,
            'only the vetoer that submitted the proposal can set its flag'
        );

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        flags = setFlag(flags, uint8(ProposalFlag.VETO), true);

        proposals[proposalId].flags = flags;
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can process it'
        );

        require(
            !getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            'proposal already processed'
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        require(proposal.adapterAddress == msg.sender, 'err::adapter mismatch');
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            getFlag(flags, uint8(ProposalFlag.EXISTS)),
            'proposal does not exist for this dao'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can set its flag'
        );

        require(!getFlag(flags, uint8(flag)), 'flag already set');

        flags = setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /*
     * MEMBERS
     */

    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) public view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(members[memberAddress].flags, uint8(flag));
    }

    function getNbMembers() public view returns (uint256) {
        return _members.length;
    }

    function getMemberAddress(uint256 index) public view returns (address) {
        return _members[index];
    }

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), 'newDelegateKey cannot be 0');

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                'cannot overwrite existing delegated keys'
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                'address already taken as delegated key'
            );
        }

        Member storage member = members[memberAddr];
        require(
            getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * Public read-only functions
     */

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        public
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(
            blockNumber < block.number,
            'Uni::getPriorDelegateKey: not yet determined'
        );

        uint32 nCheckpoints = numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = numCheckpoints[member];
        if (
            nCheckpoints > 0 &&
            checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            numCheckpoints[member] = nCheckpoints + 1;
        }
    }

    /**
     * Movements
     */

    function createMovement(
        bytes32 proposalId,
        Movememt calldata movement,
        string calldata name,
        address creator
    ) external hasAccess(this, AclFlag.ADD_MOVEMENT){
        IDaoFactory daoFactory = IDaoFactory(
            this.getFactoryAddress(DAO_FACTORY)
        );
        address daoAddr = daoFactory.createDao(name, creator);

        daoFactory.initializeClone(daoAddr, movement, creator);

        movements[proposalId] = CreatedMovement(
            name,
            daoAddr,
            movement.file
        );
        
        _proposals.push(proposalId);
    }

    function getMovement(bytes32 proposalId)
        public
        view
        returns (CreatedMovement memory)
    {
        return movements[proposalId];
    }

    function getMovements() public view returns (CreatedMovement[] memory m) {
        uint256 len = _proposals.length;
        m = new CreatedMovement[](len);

        for (uint256 i = 0; i < len; i++) {
            m[i] = movements[_proposals[i]];
        }
    }
}

/// Thegraph return active movement

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

abstract contract DaoConstants {
    // Adapters
    bytes32 internal constant VOTING = keccak256('voting');
    bytes32 internal constant ONBOARDING = keccak256('onboarding');
    bytes32 internal constant NONVOTING_ONBOARDING =
        keccak256('nonvoting-onboarding');
    bytes32 internal constant TRIBUTE = keccak256('tribute');
    bytes32 internal constant FINANCING = keccak256('financing');
    bytes32 internal constant MANAGING = keccak256('managing');
    bytes32 internal constant RAGEQUIT = keccak256('ragequit');
    bytes32 internal constant GUILDKICK = keccak256('guildkick');
    bytes32 internal constant CONFIGURATION = keccak256('configuration');
    bytes32 internal constant DISTRIBUTE = keccak256('distribute');
    bytes32 internal constant TRIBUTE_NFT = keccak256('tribute-nft');
    bytes32 internal constant ERC1155_ADAPT = keccak256('erc1155-adpt');
    bytes32 internal constant INTIATIVE_ADAPT = keccak256('intiative-adpt');

    // Extensions
    bytes32 internal constant BANK = keccak256('bank');
    bytes32 internal constant ENDOWMENT_BANK = keccak256('endowment-bank');
    bytes32 internal constant BANKOR_FORMULA = keccak256('bancor-formula');
    bytes32 internal constant BONDING_CURVE = keccak256('bonding-curve');
    bytes32 internal constant ERC1271 = keccak256('erc1271');
    bytes32 internal constant NFT = keccak256('nft');
    bytes32 internal constant ERC20_EXT = keccak256('erc20-ext');
    bytes32 internal constant EXECUTOR_EXT = keccak256('executor-ext');
    bytes32 internal constant ERC1155_EXT = keccak256('erc1155-ext');

    // Reserved Addresses
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOCKED_UNITS = address(0xFFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant LOCKED_LOOT = address(0xBB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    uint8 internal constant MAX_TOKENS_GUILD_BANK = 200;

    // Factory
    bytes32 internal constant DAO_FACTORY = keccak256('dao-factory');
    bytes32 internal constant BANK_FACTORY = keccak256('bank-factory');
    bytes32 internal constant ERC20_FACTORY = keccak256('erc20-factory');
    bytes32 internal constant BONDING_CURVE_FACTORY = keccak256('bonding-curve-factory');


    // Movement Structure
    struct Movememt {
        string tokenSymbol;
        string tokenName;
        bytes dataBondingCurve;
        uint256 votingPeriod;
        string file;
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) public pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) public pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) public pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) public pure returns (bool) {
        return addr != address(0x0);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import '../core/DaoRegistry.sol';
import '../extensions/bank/Bank.sol';
import "../core/interfaces/IDaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract MemberGuard is DaoConstants {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyOwnerOrServiceProvider(
        address owner,
        DaoRegistry dao
    ) {
        require(owner == msg.sender || IDaoRegistry(dao.getMemberAddress(1)).isServiceProvider(msg.sender), "accessDenided");
        _;
    }

    modifier onlyVetoer(DaoRegistry dao, address _addr) {
        _onlyVetoer(dao, _addr);
        _;
    }

    modifier onlyServiceProvider(DaoRegistry dao, address _addr) {
        _onlyServiceProvider(dao, _addr);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), 'onlyMember');
    }

    function _onlyVetoer(DaoRegistry dao, address _addr) internal view {
        require(dao.isVetoer(_addr), 'onlyVetoer');
    }

    function _onlyServiceProvider(DaoRegistry dao, address _addr)
        internal
        view
    {
        require(dao.isServiceProvider(_addr), 'onlyServiceProvider');
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(BANK);
        if (bankAddress != address(0x0)) {
            address memberAddr = dao.getAddressIfDelegated(_addr);
            return BankExtension(bankAddress).balanceOf(memberAddr, UNITS) > 0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


interface IBank {
    function addToBalance(address member, address token, uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Cut ERC20 interface of the IBondingCurveToken.
 */
interface IBondingCurveToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(address from, uint256 amount) external;
    
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    
    function mint(address to, uint256 amount) external;
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */

    event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/**
 * @dev Interface of the Vault.
 */
interface IBondingCurveVault {
    event ReceiveETH(address from, uint256 value);
    event TransferToken(address indexed token, address indexed to, uint256 value);
    event ApproveToken(address indexed token, address indexed to, uint256 value);
    event TransferETH(address indexed to, uint256 value);

    /**
    * @notice Transfer `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function transfer(address _token, address _to, uint256 _value) external;

    /**
    * @notice Approve `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function approve(address _token, address _to, uint256 _value) external;

    /**
    * @notice Transfer `_value` of ETH from the Vault to `_to`
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    function transferETH(address _to, uint256 _value) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../extensions/IExtension.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            (dao.state() == DaoRegistry.DaoState.CREATION &&
                creationModeCheck(dao)) || dao.isAdapter(msg.sender),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr =
            dao.getExtensionAddress(keccak256("executor-ext"));
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            (dao.state() == DaoRegistry.DaoState.CREATION &&
                creationModeCheck(dao)) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }

    function creationModeCheck(DaoRegistry dao) internal view returns (bool) {
        return
            dao.getNbMembers() == 0 ||
            dao.isMember(msg.sender) ||
            dao.isAdapter(msg.sender);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import '../DaoConstants.sol';

interface IDaoFactory {
    function createDao(string calldata daoName, address creator)
        external
        returns (address daoAddr);

    function initializeClone(
        address dao,
        DaoConstants.Movememt calldata movement,
        address creator
    ) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../extensions/IExtension.sol";

interface IDaoRegistry {
    function addExtension(
        bytes32 extensionId,
        IExtension extension,
        address creator
    ) external;

    function isServiceProvider(address addr) external returns (bool);
    
    function getExtensionAddress(bytes32 extensionId) external view returns (address);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoConstants.sol";
import "../../core/DaoRegistry.sol";
import "../IExtension.sol";
import "../interfaces/IBank.sol";
import "../../guards/AdapterGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract BankExtension is DaoConstants, AdapterGuard, IExtension, IBank {
    using Address for address payable;
    using SafeERC20 for IERC20;

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    modifier noProposal {
        require(dao.lockedAt() < block.number, "proposal lock");
        _;
    }

    /// @dev - Events for Bank
    event NewBalance(address member, address tokenAddr, uint160 amount);

    event Withdraw(address account, address tokenAddr, uint160 amount);

    /*
     * STRUCTURES
     */

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    modifier hasExtensionAccess(AclFlag flag) {
        require(
            address(this) == msg.sender ||
                address(dao) == msg.sender ||
                dao.state() == DaoRegistry.DaoState.CREATION ||
                dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                ),
            "bank::accessDenied"
        );
        _;
    }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     */
    function initialize(DaoRegistry _dao, address creator) external override {
        require(!initialized, "bank already initialized");
        require(_dao.isMember(creator), "bank::not member");
        dao = _dao;
        initialized = true;

        availableInternalTokens[UNITS] = true;
        internalTokens.push(UNITS);

        availableInternalTokens[MEMBER_COUNT] = true;
        internalTokens.push(MEMBER_COUNT);
        uint256 nbMembers = _dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            addToBalance(_dao.getMemberAddress(i), MEMBER_COUNT, 1);
        }

        _createNewAmountCheckpoint(creator, UNITS, 1);
        _createNewAmountCheckpoint(TOTAL, UNITS, 1);
    }

    
    function withdrawTo(
        address payable member,
        address payable to,       
        address tokenAddr,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            "bank::withdraw::not enough funds"
        );
        subtractFromBalance(member, tokenAddr, amount);
        if (tokenAddr == ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            erc20.safeTransfer(to, amount);
        }

        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdraw(
            address payable member,
            address tokenAddr,
            uint256 amount
        ) external {
            withdrawTo(member, member, tokenAddr, amount);
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, "bank already initialized");
        require(
            maxTokens > 0 && maxTokens <= MAX_TOKENS_GUILD_BANK,
            "max number of external tokens should be (0,200)"
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(address token)
        external
        hasExtensionAccess(AclFlag.REGISTER_NEW_TOKEN)
    {
        require(isNotReservedAddress(token), "reservedToken");
        require(!availableInternalTokens[token], "internalToken");
        require(
            tokens.length <= maxExternalTokens,
            "exceeds the maximum tokens allowed"
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(address token)
        external
        hasExtensionAccess(AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(isNotReservedAddress(token), "reservedToken");
        require(!availableTokens[token], "availableToken");

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(address tokenAddr)
        external
        hasExtensionAccess(AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), "token not allowed");
        uint256 totalBalance = balanceOf(TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(GUILD, tokenAddr, realBalance - totalBalance);
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(GUILD, tokenAddr, tokensToRemove);
            } else {
                subtractFromBalance(GUILD, tokenAddr, guildBalance);
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        address member,
        address token,
        uint256 amount
    ) public override payable hasExtensionAccess(AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            "unknown token address"
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.INTERNAL_TRANSFER) {
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            "Uni::getPriorAmount: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                "token amount exceeds the maximum limit for internal tokens"
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                "token amount exceeds the maximum limit for external tokens"
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, "token not registered");

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        emit NewBalance(member, token, newAmount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      ___                      ___                   ___          ___          ___     
     /  /\        ___         /  /\     ___         /  /\        /  /\        /  /\    
    /  /::|      /  /\       /  /::|   /__/\       /  /::\      /  /::\      /  /::\   
   /  /:|:|     /  /:/      /  /:|:|   \  \:\     /  /:/\:\    /  /:/\:\    /  /:/\:\  
  /  /:/|:|__  /  /:/      /  /:/|:|__  \__\:\   /  /:/  \:\  /  /::\ \:\  /  /:/  \:\ 
 /__/:/_|::::\/__/:/  ___ /__/:/_|::::\ /  /::\ /__/:/ \__\:|/__/:/\:\_\:\/__/:/ \__\:\
 \__\/  /~~/:/|  |:| /  /\\__\/  /~~/://  /:/\:\\  \:\ /  /:/\__\/  \:\/:/\  \:\ /  /:/
       /  /:/ |  |:|/  /:/      /  /://  /:/__\/ \  \:\  /:/      \__\::/  \  \:\  /:/ 
      /  /:/  |__|:|__/:/      /  /://__/:/       \  \:\/:/       /  /:/    \  \:\/:/  
     /__/:/    \__\::::/      /__/:/ \__\/         \__\::/       /__/:/      \  \::/   
     \__\/         ~~~~       \__\/                    ~~        \__\/        \__\/    
*/

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IBancorFormula.sol";
import "../interfaces/IBondingCurveToken.sol";
import "../interfaces/IBondingCurveVault.sol";

contract BondingCurve is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
    Hardcoded constants to save gas
    bytes32 public constant UPDATE_FORMULA_ROLE                        = keccak256("UPDATE_FORMULA_ROLE");
    bytes32 public constant UPDATE_BENEFICIARY_ROLE                    = keccak256("UPDATE_BENEFICIARY_ROLE");
    bytes32 public constant UPDATE_FEES_ROLE                           = keccak256("UPDATE_FEES_ROLE");
    bytes32 public constant MANAGE_COLLATERAL_TOKEN_ROLE               = keccak256("MANAGE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant MAKE_BUY_ORDER_ROLE                        = keccak256("MAKE_BUY_ORDER_ROLE");
    bytes32 public constant MAKE_SELL_ORDER_ROLE                       = keccak256("MAKE_SELL_ORDER_ROLE");
    */
    bytes32 public constant UPDATE_FORMULA_ROLE =
        0xbfb76d8d43f55efe58544ea32af187792a7bdb983850d8fed33478266eec3cbb;
    bytes32 public constant UPDATE_BENEFICIARY_ROLE =
        0xf7ea2b80c7b6a2cab2c11d2290cb005c3748397358a25e17113658c83b732593;
    bytes32 public constant UPDATE_FEES_ROLE =
        0x5f9be2932ed3a723f295a763be1804c7ebfd1a41c1348fb8bdf5be1c5cdca822;
    bytes32 public constant MANAGE_COLLATERAL_TOKEN_ROLE =
        0xd9d296b0bc78eaab1039dfb623e942381a5402711b7fcec0bfb94004c18879f4;
    bytes32 public constant MAKE_BUY_ORDER_ROLE =
        0x0dfea6908176d96adbee7026b3fe9fbdaccfc17bc443ddf14734fd27c3136179;
    bytes32 public constant MAKE_SELL_ORDER_ROLE =
        0x52e3ace6a83e0c810920056ccc32fed5aa1e86287545113b03a52ab5c84e3f66;

    uint256 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10 ** 16; 100% = 10 ** 18
    uint32 public constant PPM = 1000000;
    address public constant ETH = address(0);

    string private constant ERROR_CONTRACT_IS_EOA = "MM_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_BENEFICIARY =
        "MM_INVALID_BENEFICIARY";
    string private constant ERROR_INVALID_PERCENTAGE = "MM_INVALID_PERCENTAGE";
    string private constant ERROR_INVALID_RESERVE_RATIO =
        "MM_INVALID_RESERVE_RATIO";
    string private constant ERROR_INVALID_TM_SETTING = "MM_INVALID_TM_SETTING";
    string private constant ERROR_INVALID_COLLATERAL = "MM_INVALID_COLLATERAL";
    string private constant ERROR_INVALID_COLLATERAL_VALUE =
        "MM_INVALID_COLLATERAL_VALUE";
    string private constant ERROR_INVALID_BOND_AMOUNT =
        "MM_INVALID_BOND_AMOUNT";
    string private constant ERROR_COLLATERAL_ALREADY_WHITELISTED =
        "MM_COLLATERAL_ALREADY_WHITELISTED";
    string private constant ERROR_COLLATERAL_NOT_WHITELISTED =
        "MM_COLLATERAL_NOT_WHITELISTED";
    string private constant ERROR_SLIPPAGE_EXCEEDS_LIMIT =
        "MM_SLIPPAGE_EXCEEDS_LIMIT";
    string private constant ERROR_TRANSFER_FAILED = "MM_TRANSFER_FAILED";
    string private constant ERROR_NOT_BUY_FUNCTION = "MM_NOT_BUY_FUNCTION";
    string private constant ERROR_BUYER_NOT_FROM = "MM_BUYER_NOT_FROM";
    string private constant ERROR_COLLATERAL_NOT_SENDER =
        "MM_COLLATERAL_NOT_SENDER";
    string private constant ERROR_DEPOSIT_NOT_AMOUNT = "MM_DEPOSIT_NOT_AMOUNT";
    string private constant ERROR_NO_PERMISSION = "MM_NO_PERMISSION";
    string private constant ERROR_TOKEN_NOT_SENDER = "MM_TOKEN_NOT_SENDER";
    string private constant ERROR_INVALID_BUY_ORDER_DATA =
        "MM_INVALID_BUY_ORDER_DATA";

    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(_canPerform(msg.sender, _role), ERROR_AUTH_FAILED);
        _;
    }

    struct Collateral {
        uint256 virtualSupply;
        uint256 virtualBalance;
        bool whitelisted;
        uint32 reserveRatio;
    }

    IBondingCurveToken public token;
    IBondingCurveVault public reserve;
    address public beneficiary;
    IBancorFormula public formula;

    uint256 public buyFeePct;
    uint256 public sellFeePct;

    mapping(address => Collateral) public collaterals;

    event UpdateBeneficiary(address indexed beneficiary);
    event UpdateFormula(address indexed formula);
    event UpdateFees(uint256 buyFeePct, uint256 sellFeePct);
    event AddCollateralToken(
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32 reserveRatio
    );
    event RemoveCollateralToken(address indexed collateral);
    event UpdateCollateralToken(
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32 reserveRatio
    );
    event MakeBuyOrder(
        address indexed buyer,
        address indexed collateral,
        uint256 fee,
        uint256 purchaseAmount,
        uint256 returnedAmount,
        uint256 feePct
    );
    event MakeSellOrder(
        address indexed seller,
        address indexed collateral,
        uint256 fee,
        uint256 sellAmount,
        uint256 returnedAmount,
        uint256 feePct
    );

    /***** external function *****/
    /*
    function initialize(DaoRegistry dao, address creator) external override {
    }
    */

    /**
     * @notice Initialize market maker
     * @param _token        The address of the [bonded token] token contract
     * @param _formula      The address of the BancorFormula [computation] contract
     * @param _reserve      The address of the reserve [pool] contract
     * @param _beneficiary  The address of the beneficiary [to whom fees are to be sent]
     * @param _buyFeePct    The fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct   The fee to be deducted from sell orders [in PCT_BASE]
     */
    function initializeCurve(
        IBondingCurveToken _token,
        IBancorFormula _formula,
        IBondingCurveVault _reserve,
        address _beneficiary,
        uint256 _buyFeePct,
        uint256 _sellFeePct
    ) external initializer {
        require(_isContract(address(_token)), ERROR_CONTRACT_IS_EOA);
        require(_isContract(address(_formula)), ERROR_CONTRACT_IS_EOA);
        require(_isContract(address(_reserve)), ERROR_CONTRACT_IS_EOA);
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);
        require(
            _feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct),
            ERROR_INVALID_PERCENTAGE
        );

        token = _token;
        formula = _formula;
        reserve = _reserve;
        beneficiary = _beneficiary;
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;
    }

    /* generic settings related function */

    /**
     * @notice Update formula to `_formula`
     * @param _formula The address of the new BancorFormula [computation] contract
     */
    function updateFormula(IBancorFormula _formula)
        external
        auth(UPDATE_FORMULA_ROLE)
    {
        require(_isContract(address(_formula)), ERROR_CONTRACT_IS_EOA);

        _updateFormula(_formula);
    }

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary [to whom fees are to be sent]
     */
    function updateBeneficiary(address _beneficiary)
        external
        auth(UPDATE_BENEFICIARY_ROLE)
    {
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);

        _updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update fees deducted from buy and sell orders to respectively `@formatPct(_buyFeePct)`% and `@formatPct(_sellFeePct)`%
     * @param _buyFeePct  The new fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct The new fee to be deducted from sell orders [in PCT_BASE]
     */
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct)
        external
        auth(UPDATE_FEES_ROLE)
    {
        require(
            _feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct),
            ERROR_INVALID_PERCENTAGE
        );

        _updateFees(_buyFeePct, _sellFeePct);
    }

    /* collateral tokens related functions */

    /**
     * @notice Add `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     */
    function addCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32 _reserveRatio
    ) external auth(MANAGE_COLLATERAL_TOKEN_ROLE) {
        require(
            _collateral == ETH || IERC20(_collateral).totalSupply() > 0,
            ERROR_INVALID_COLLATERAL
        );
        require(
            !_collateralIsWhitelisted(_collateral),
            ERROR_COLLATERAL_ALREADY_WHITELISTED
        );
        require(
            _reserveRatioIsValid(_reserveRatio),
            ERROR_INVALID_RESERVE_RATIO
        );
        _addCollateralToken(
            _collateral,
            _virtualSupply,
            _virtualBalance,
            _reserveRatio
        );
    }

    /**
     * @notice Remove `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral The address of the collateral token to be un-whitelisted
     */
    function removeCollateralToken(address _collateral)
        external
        auth(MANAGE_COLLATERAL_TOKEN_ROLE)
    {
        require(
            _collateralIsWhitelisted(_collateral),
            ERROR_COLLATERAL_NOT_WHITELISTED
        );

        _removeCollateralToken(_collateral);
    }

    /**
     * @notice Update `_collateral.symbol(): string` collateralization settings
     * @param _collateral     The address of the collateral token whose collateralization settings are to be updated
     * @param _virtualSupply  The new virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The new virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The new reserve ratio to be used for that collateral token [in PPM]
     */
    function updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32 _reserveRatio
    ) external auth(MANAGE_COLLATERAL_TOKEN_ROLE) {
        require(
            _collateralIsWhitelisted(_collateral),
            ERROR_COLLATERAL_NOT_WHITELISTED
        );
        require(
            _reserveRatioIsValid(_reserveRatio),
            ERROR_INVALID_RESERVE_RATIO
        );

        _updateCollateralToken(
            _collateral,
            _virtualSupply,
            _virtualBalance,
            _reserveRatio
        );
    }

    /* market making related functions */

    /**
     * @notice Make a buy order worth `@tokenAmount(_collateral, _depositAmount)` for atleast `@tokenAmount(self.token(): address, _minReturnAmountAfterFee)`
     * @param _buyer The address of the buyer
     * @param _collateral The address of the collateral token to be deposited
     * @param _depositAmount The amount of collateral token to be deposited
     * @param _minReturnAmountAfterFee The minimum amount of the returned bonded tokens
     */
    function makeBuyOrder(
        address _buyer,
        address _collateral,
        uint256 _depositAmount,
        uint256 _minReturnAmountAfterFee
    ) external payable auth(MAKE_BUY_ORDER_ROLE) {
        _makeBuyOrder(
            _buyer,
            _collateral,
            _depositAmount,
            _minReturnAmountAfterFee
        );
    }

    /**
     * @notice Make a sell order worth `@tokenAmount(self.token(): address, _sellAmount)` for atleast `@tokenAmount(_collateral, _minReturnAmountAfterFee)`
     * @param _seller The address of the seller
     * @param _collateral The address of the collateral token to be returned
     * @param _sellAmount The amount of bonded token to be spent
     * @param _minReturnAmountAfterFee The minimum amount of the returned collateral tokens
     */
    function makeSellOrder(
        address _seller,
        address _collateral,
        uint256 _sellAmount,
        uint256 _minReturnAmountAfterFee
    ) external nonReentrant auth(MAKE_SELL_ORDER_ROLE) {
        require(
            _collateralIsWhitelisted(_collateral),
            ERROR_COLLATERAL_NOT_WHITELISTED
        );
        require(
            _bondAmountIsValid(_seller, _sellAmount),
            ERROR_INVALID_BOND_AMOUNT
        );

        uint256 collateralSupply = token.totalSupply().add(
            collaterals[_collateral].virtualSupply
        );
        uint256 collateralBalanceOfReserve = _balanceOf(
            address(reserve),
            _collateral
        ).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        uint256 returnAmount = formula.calculateSaleReturn(
            collateralSupply,
            collateralBalanceOfReserve,
            reserveRatio,
            _sellAmount
        );

        uint256 fee = returnAmount.mul(sellFeePct).div(PCT_BASE);
        uint256 returnAmountLessFee = returnAmount.sub(fee);

        require(
            returnAmountLessFee >= _minReturnAmountAfterFee,
            ERROR_SLIPPAGE_EXCEEDS_LIMIT
        );

        token.burn(_seller, _sellAmount);

        if (returnAmountLessFee > 0) {
            reserve.transfer(_collateral, _seller, returnAmountLessFee);
        }
        if (fee > 0) {
            reserve.transfer(_collateral, beneficiary, fee);
        }

        emit MakeSellOrder(
            _seller,
            _collateral,
            fee,
            _sellAmount,
            returnAmountLessFee,
            sellFeePct
        );
    }

    /**
     * @dev ApproveAndCallFallBack interface conformance
     * @param _from Token sender
     * @param _amount Token amount
     * @param _token Token that received approval
     * @param _buyOrderData Data for the below function call
     *      makeBuyOrder(address _buyer, address _collateral, uint256 _depositAmount, uint256 _minReturnAmountAfterFee)
     */
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes calldata _buyOrderData
    ) public {
        require(_token == msg.sender, ERROR_TOKEN_NOT_SENDER);
        require(_canPerform(_from, MAKE_BUY_ORDER_ROLE), ERROR_NO_PERMISSION);

        _makeBuyOrderRaw(_from, msg.sender, _amount, _buyOrderData);
    }

    /***** public view functions *****/

    function getCollateralToken(address _collateral)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint32
        )
    {
        Collateral storage collateral = collaterals[_collateral];

        return (
            collateral.whitelisted,
            collateral.virtualSupply,
            collateral.virtualBalance,
            collateral.reserveRatio
        );
    }

    function getStaticPricePPM(
        uint256 _supply,
        uint256 _balance,
        uint32 _reserveRatio
    ) public view returns (uint256) {
        return
            uint256(PPM).mul(uint256(PPM)).mul(_balance).div(
                _supply.mul(uint256(_reserveRatio))
            );
    }

    /***** internal functions *****/

    /* check functions */

    function _balanceOf(address _who, address _token)
        internal
        view
        returns (uint256)
    {
        return _token == ETH ? _who.balance : IERC20(_token).balanceOf(_who);
    }

    function _beneficiaryIsValid(address _beneficiary)
        internal
        pure
        returns (bool)
    {
        return _beneficiary != address(0);
    }

    function _feeIsValid(uint256 _fee) internal pure returns (bool) {
        return _fee < PCT_BASE;
    }

    function _reserveRatioIsValid(uint32 _reserveRatio)
        internal
        pure
        returns (bool)
    {
        return _reserveRatio <= PPM;
    }

    function _collateralValueIsValid(address _collateral, uint256 _value)
        internal
        view
        returns (bool)
    {
        if (_value == 0) {
            return false;
        }

        if (_collateral == ETH) {
            return msg.value == _value;
        }

        return msg.value == 0;
    }

    function _bondAmountIsValid(address _seller, uint256 _amount)
        internal
        view
        returns (bool)
    {
        return _amount != 0 && token.balanceOf(_seller) >= _amount;
    }

    function _collateralIsWhitelisted(address _collateral)
        internal
        view
        returns (bool)
    {
        return collaterals[_collateral].whitelisted;
    }

    /* state modifiying functions */

    /**
     * @dev Make a buy order
     * @param _buyer The address of the buyer
     * @param _collateral The address of the collateral token to be deposited
     * @param _depositAmount The amount of collateral token to be deposited
     * @param _minReturnAmountAfterFee The minimum amount of the returned bonded tokens
     */
    function _makeBuyOrder(
        address _buyer,
        address _collateral,
        uint256 _depositAmount,
        uint256 _minReturnAmountAfterFee
    ) internal nonReentrant {
        require(
            _collateralIsWhitelisted(_collateral),
            ERROR_COLLATERAL_NOT_WHITELISTED
        );
        require(
            _collateralValueIsValid(_collateral, _depositAmount),
            ERROR_INVALID_COLLATERAL_VALUE
        );

        uint256 fee = _depositAmount.mul(buyFeePct).div(PCT_BASE);
        uint256 depositAmountLessFee = _depositAmount.sub(fee);

        uint256 collateralSupply = token.totalSupply().add(
            collaterals[_collateral].virtualSupply
        );
        uint256 collateralBalanceOfReserve = _balanceOf(
            address(reserve),
            _collateral
        ).add(collaterals[_collateral].virtualBalance);
        uint32 reserveRatio = collaterals[_collateral].reserveRatio;
        uint256 returnAmount = formula.calculatePurchaseReturn(
            collateralSupply,
            collateralBalanceOfReserve,
            reserveRatio,
            depositAmountLessFee
        );

        // collect fee and collateral
        if (_collateral == ETH) {
            (bool success, ) = address(reserve).call{value: _depositAmount}(
                new bytes(0)
            );
            require(success, ERROR_TRANSFER_FAILED);
        } else {
            IERC20(_collateral).safeTransferFrom(
                _buyer,
                address(reserve),
                _depositAmount
            );
        }

        // deduct fee
        if (fee > 0) {
            reserve.transfer(_collateral, beneficiary, fee);
        }

        require(
            returnAmount >= _minReturnAmountAfterFee,
            ERROR_SLIPPAGE_EXCEEDS_LIMIT
        );

        if (returnAmount > 0) {
            token.mint(_buyer, returnAmount);
        }

        emit MakeBuyOrder(
            _buyer,
            _collateral,
            fee,
            depositAmountLessFee,
            returnAmount,
            buyFeePct
        );
    }

    /**
     * @dev Make a buy order using makeBuyOrder() function data. Used for single transaction ERC20 buy orders, ones
     *      without a pre-approval transaction, but that have been approved in this transaction.
     * @param _from Token sender
     * @param _token Token that received approval
     * @param _amount Token amount
     * @param _buyOrderData Data for the below function call
     *      makeBuyOrder(address _buyer, address _collateral, uint256 _depositAmount, uint256 _minReturnAmountAfterFee)
     */
    function _makeBuyOrderRaw(
        address _from,
        address _token,
        uint256 _amount,
        bytes memory _buyOrderData
    ) internal {
        // 32 + 4 + 32 + 32 + 32 = 132 (bytes array length + sig + address _buyer + address _collateral + uint256 _depositAmount)
        require(_buyOrderData.length == 132, ERROR_INVALID_BUY_ORDER_DATA);
        bytes memory buyOrderDataCopy = _buyOrderData;

        bytes4 functionSig;
        address buyerAddress;
        address collateralTokenAddress;
        uint256 depositAmount;
        uint256 minReturnAmountAfterFee;

        assembly {
            // functionSigByteLocation: 32 (bytes array length)
            functionSig := mload(add(buyOrderDataCopy, 32))

            // buyerAddressByteLocation: 32 + 4 = 36 (bytes array length + sig)
            buyerAddress := mload(add(buyOrderDataCopy, 36))

            // collateralAddressByteLocation: 32 + 4 + 32 = 68 (bytes array length + sig + address _buyer)
            collateralTokenAddress := mload(add(buyOrderDataCopy, 68))

            // depositAmountByteLocation: 32 + 4 + 32 + 32 = 100 (bytes array length + sig + address _buyer + address _collateral)
            depositAmount := mload(add(buyOrderDataCopy, 100))

            // minReturnAmountAfterFeeByteLocation: 32 + 4 + 32 + 32 + 32 = 132 (bytes array length + sig + address _buyer + address _collateral + uint256 _depositAmount)
            minReturnAmountAfterFee := mload(add(buyOrderDataCopy, 132))
        }

        require(
            functionSig == this.makeBuyOrder.selector,
            ERROR_NOT_BUY_FUNCTION
        );
        require(buyerAddress == _from, ERROR_BUYER_NOT_FROM);
        require(collateralTokenAddress == _token, ERROR_COLLATERAL_NOT_SENDER);
        require(depositAmount == _amount, ERROR_DEPOSIT_NOT_AMOUNT);

        _makeBuyOrder(
            buyerAddress,
            collateralTokenAddress,
            depositAmount,
            minReturnAmountAfterFee
        );
    }

    function _updateBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;

        emit UpdateBeneficiary(_beneficiary);
    }

    function _updateFormula(IBancorFormula _formula) internal {
        formula = _formula;

        emit UpdateFormula(address(_formula));
    }

    function _updateFees(uint256 _buyFeePct, uint256 _sellFeePct) internal {
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;

        emit UpdateFees(_buyFeePct, _sellFeePct);
    }

    function _addCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32 _reserveRatio
    ) internal {
        collaterals[_collateral].whitelisted = true;
        collaterals[_collateral].virtualSupply = _virtualSupply;
        collaterals[_collateral].virtualBalance = _virtualBalance;
        collaterals[_collateral].reserveRatio = _reserveRatio;

        emit AddCollateralToken(
            _collateral,
            _virtualSupply,
            _virtualBalance,
            _reserveRatio
        );
    }

    function _removeCollateralToken(address _collateral) internal {
        delete collaterals[_collateral];

        emit RemoveCollateralToken(_collateral);
    }

    function _updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32 _reserveRatio
    ) internal {
        collaterals[_collateral].virtualSupply = _virtualSupply;
        collaterals[_collateral].virtualBalance = _virtualBalance;
        collaterals[_collateral].reserveRatio = _reserveRatio;

        emit UpdateCollateralToken(
            _collateral,
            _virtualSupply,
            _virtualBalance,
            _reserveRatio
        );
    }

    /**
     * @dev Check whether an action can be performed by a sender for a particular role on this app
     * @param _sender Sender of the call
     * @param _role Role on this app
     * @return Boolean indicating whether the sender has the permissions to perform the action.
     *         Always returns false if the app hasn't been initialized yet.
     */
    function _canPerform(address _sender, bytes32 _role)
        internal
        view
        returns (bool)
    {
        return true;
    }

    /*
     * NOTE: this should NEVER be used for authentication
     * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
     *
     * This is only intended to be used as a sanity check that an address is actually a contract,
     * RATHER THAN an address not being a contract.
     */
    function _isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      ___                      ___                   ___          ___          ___     
     /  /\        ___         /  /\     ___         /  /\        /  /\        /  /\    
    /  /::|      /  /\       /  /::|   /__/\       /  /::\      /  /::\      /  /::\   
   /  /:|:|     /  /:/      /  /:|:|   \  \:\     /  /:/\:\    /  /:/\:\    /  /:/\:\  
  /  /:/|:|__  /  /:/      /  /:/|:|__  \__\:\   /  /:/  \:\  /  /::\ \:\  /  /:/  \:\ 
 /__/:/_|::::\/__/:/  ___ /__/:/_|::::\ /  /::\ /__/:/ \__\:|/__/:/\:\_\:\/__/:/ \__\:\
 \__\/  /~~/:/|  |:| /  /\\__\/  /~~/://  /:/\:\\  \:\ /  /:/\__\/  \:\/:/\  \:\ /  /:/
       /  /:/ |  |:|/  /:/      /  /://  /:/__\/ \  \:\  /:/      \__\::/  \  \:\  /:/ 
      /  /:/  |__|:|__/:/      /  /://__/:/       \  \:\/:/       /  /:/    \  \:\/:/  
     /__/:/    \__\::::/      /__/:/ \__\/         \__\::/       /__/:/      \  \::/   
     \__\/         ~~~~       \__\/                    ~~        \__\/        \__\/    
*/

/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount
    ) external view returns (uint256);

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _sellAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      ___                      ___                   ___          ___          ___     
     /  /\        ___         /  /\     ___         /  /\        /  /\        /  /\    
    /  /::|      /  /\       /  /::|   /__/\       /  /::\      /  /::\      /  /::\   
   /  /:|:|     /  /:/      /  /:|:|   \  \:\     /  /:/\:\    /  /:/\:\    /  /:/\:\  
  /  /:/|:|__  /  /:/      /  /:/|:|__  \__\:\   /  /:/  \:\  /  /::\ \:\  /  /:/  \:\ 
 /__/:/_|::::\/__/:/  ___ /__/:/_|::::\ /  /::\ /__/:/ \__\:|/__/:/\:\_\:\/__/:/ \__\:\
 \__\/  /~~/:/|  |:| /  /\\__\/  /~~/://  /:/\:\\  \:\ /  /:/\__\/  \:\/:/\  \:\ /  /:/
       /  /:/ |  |:|/  /:/      /  /://  /:/__\/ \  \:\  /:/      \__\::/  \  \:\  /:/ 
      /  /:/  |__|:|__/:/      /  /://__/:/       \  \:\/:/       /  /:/    \  \:\/:/  
     /__/:/    \__\::::/      /__/:/ \__\/         \__\::/       /__/:/      \  \::/   
     \__\/         ~~~~       \__\/                    ~~        \__\/        \__\/    
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the IBondingCurveToken.
 */
interface IBondingCurveToken is IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      ___                      ___                   ___          ___          ___     
     /  /\        ___         /  /\     ___         /  /\        /  /\        /  /\    
    /  /::|      /  /\       /  /::|   /__/\       /  /::\      /  /::\      /  /::\   
   /  /:|:|     /  /:/      /  /:|:|   \  \:\     /  /:/\:\    /  /:/\:\    /  /:/\:\  
  /  /:/|:|__  /  /:/      /  /:/|:|__  \__\:\   /  /:/  \:\  /  /::\ \:\  /  /:/  \:\ 
 /__/:/_|::::\/__/:/  ___ /__/:/_|::::\ /  /::\ /__/:/ \__\:|/__/:/\:\_\:\/__/:/ \__\:\
 \__\/  /~~/:/|  |:| /  /\\__\/  /~~/://  /:/\:\\  \:\ /  /:/\__\/  \:\/:/\  \:\ /  /:/
       /  /:/ |  |:|/  /:/      /  /://  /:/__\/ \  \:\  /:/      \__\::/  \  \:\  /:/ 
      /  /:/  |__|:|__/:/      /  /://__/:/       \  \:\/:/       /  /:/    \  \:\/:/  
     /__/:/    \__\::::/      /__/:/ \__\/         \__\::/       /__/:/      \  \::/   
     \__\/         ~~~~       \__\/                    ~~        \__\/        \__\/    
*/

/**
 * @dev Interface of the Vault.
 */
interface IBondingCurveVault {
    /**
     * @notice Transfer `_value` `_token` from the Vault to `_to`
     * @param _token Address of the token being transferred
     * @param _to Address of the recipient of tokens
     * @param _value Amount of tokens being transferred
     */
    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
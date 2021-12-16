// SPDX-License-Identifier: UNLICENSED

// This contract generates Presale contracts and registers them in the PresaleFactory.
// Ideally you should not interact with this contract directly, and use the Presale app instead so warnings can be shown where necessary.

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./PresaleHelper.sol";
import "./Presale.sol";

interface IPresaleFactory {
    function registerPresale(address _presaleAddress) external;

    function presaleIsRegistered(address _presaleAddress) external view returns (bool);
}

contract PresaleGenerator is Ownable {
    using SafeMath for uint256;

    IPresaleFactory public PRESALE_FACTORY;
    IPresaleSetting public PRESALE_SETTING;

    event CreatePresale(address presaleOwner, address presaleAddress, uint256 creationFee);

    struct PresaleParams {
        uint256 amount;
        uint256 tokenPrice; // number sale token per base token
        uint256 limitPerBuyer; // number base token per user
        uint256 hardCap;
        uint256 softCap;
        uint256 liquidityPercent;
        uint256 listingPrice; // sale token listing price on dex
        uint256 startTime;
        uint256 endTime;
        uint256 lockPeriod;
    }

    constructor() {
        PRESALE_FACTORY = IPresaleFactory(0x80A9984e8350fF64e4F5595f612082F0423D546E);
        PRESALE_SETTING = IPresaleSetting(0xccc6257EB4bA7075Dc597A6d42f50a46B6bDDf25);
    }

    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory
     */
    function createPresale(
        address payable _presaleOwner,
        IERC20 _presaleToken,
        IERC20 _baseToken,
        bool[3] memory _activeInfo,
        uint256[10] memory unitParams,
        uint256[] memory _vestingPeriod,
        uint256[] memory _vestingPercent
    ) public payable {
        PresaleParams memory params;
        params.amount = unitParams[0];
        params.tokenPrice = unitParams[1];
        params.limitPerBuyer = unitParams[2];
        params.hardCap = unitParams[3];
        params.softCap = unitParams[4];
        params.liquidityPercent = unitParams[5];
        params.listingPrice = unitParams[6];
        params.startTime = unitParams[7];
        params.endTime = unitParams[8];
        params.lockPeriod = unitParams[9];

        if (params.lockPeriod < PRESALE_SETTING.getMinLockPeriod()) {
            params.lockPeriod = PRESALE_SETTING.getMinLockPeriod();
        }
        require(params.limitPerBuyer > 0, 'PRESALE GENERATOR: INVALID LIMIT PER BUYER');
        require(PRESALE_SETTING.baseTokenIsValid(address(_baseToken)), 'PRESALE GENERATOR: INVALID BASE TOKEN');

        // Charge fee for contract creation
        require(msg.value == PRESALE_SETTING.getCreationFee(), 'PRESALE GENERATOR: FEE NOT MET');
        PRESALE_SETTING.getBaseFeeAddress().transfer(PRESALE_SETTING.getCreationFee());

        require(params.amount >= 10000, 'PRESALE GENERATOR: MIN DIVIS');
        require(params.softCap > 0, 'PRESALE GENERATOR: INVALID SOFT CAP');
        require(params.hardCap > params.softCap, 'PRESALE GENERATOR: INVALID HARD CAP');
        require(params.endTime.sub(params.startTime) <= PRESALE_SETTING.getMaxPresaleLength(), 'PRESALE GENERATOR: INVALID PRESALE LENGTH');
        require(params.tokenPrice.mul(params.hardCap) > 0, 'PRESALE GENERATOR: INVALID PARAMS');
        // ensure no overflow for future calculations
        require(params.liquidityPercent >= PRESALE_SETTING.getMinLiquidityPercent() && params.liquidityPercent <= 1000, 'PRESALE GENERATOR: INVALID LIQUIDITY PERCENT');
        uint256 tokenRequiredForPresale = PresaleHelper.calculateAmountRequired(params.amount, params.tokenPrice, params.listingPrice, params.liquidityPercent, PRESALE_SETTING.getTokenFeePercent());

        if (!_activeInfo[2]) {
            delete _vestingPeriod;
            delete _vestingPercent;
        } else {
            // Validate Vesting
            require(_vestingPeriod.length > 0, 'INVALID VESTING PERIOD');
            require(_vestingPeriod.length == _vestingPercent.length, 'INVALID VESTING DATA');
            uint256 totalVestingPercent = 0;
            for (uint256 i = 0; i < _vestingPercent.length; i++) {
                totalVestingPercent = totalVestingPercent.add(_vestingPercent[i]);
            }
            require(totalVestingPercent == 1000, 'INVALID VESTING PERCENT');
        }

        Presale newPresale = new Presale(address(this));
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokenRequiredForPresale);
        newPresale.setMainInfo(_presaleOwner, params.amount, params.tokenPrice, params.limitPerBuyer, params.hardCap, params.softCap, params.liquidityPercent, params.listingPrice, params.startTime, params.endTime, params.lockPeriod);
        newPresale.setFeeInfo(_baseToken, _presaleToken, PRESALE_SETTING.getBaseFeePercent(), PRESALE_SETTING.getTokenFeePercent(), PRESALE_SETTING.getBaseFeeAddress(), PRESALE_SETTING.getTokenFeeAddress());
        newPresale.setRoundInfo(_activeInfo[0], _activeInfo[1]);
        newPresale.setVestingInfo(_activeInfo[2], _vestingPeriod, _vestingPercent);

        PRESALE_FACTORY.registerPresale(address(newPresale));
        emit CreatePresale(_presaleOwner, address(newPresale), msg.value);
    }

}
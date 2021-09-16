// SPDX-License-Identifier: UNLICENSED

// This contract generates Presale contracts and registers them in the PresaleFactory.
// Ideally you should not interact with this contract directly, and use the Presale app instead so warnings can be shown where necessary.

pragma solidity 0.8.6;

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

    event CreatePresale(address presaleOwner, address presaleAddress, uint256 creationFee, address refererAddress);

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
        PRESALE_SETTING = IPresaleSetting(0x5aD293E7B3ad9f61fCfEEf01582D8b2f0aA0a2e3);
        PRESALE_FACTORY = IPresaleFactory(0x0e1eCa55b05d68709cb49F4F8907f6Bba4515AdD);
    }

    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory
     */
    function createPresale(
        address payable _presaleOwner,
        IERC20 _presaleToken,
        IERC20 _baseToken,
        address payable _refererAddress,
        bool[2] memory _activeRound,
        uint256[10] memory unitParams
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
        if (params.limitPerBuyer > params.hardCap) {
            params.limitPerBuyer = params.hardCap;
        }

        require(PRESALE_SETTING.baseTokenIsValid(address(_baseToken)), 'PRESALE GENERATOR: INVALID BASE TOKEN');

        // Charge fee for contract creation
        require(msg.value == PRESALE_SETTING.getCreationFee(), 'PRESALE GENERATOR: FEE NOT MET');
        PRESALE_SETTING.getBaseFeeAddress().transfer(PRESALE_SETTING.getCreationFee());

        // Pay referer fee
        uint256 refererFeePercent = 0;
        if (_refererAddress != address(0)) {
            require(PRESALE_SETTING.refererIsValid(_refererAddress), 'PRESALE GENERATOR: INVALID REFERER');
            refererFeePercent = PRESALE_SETTING.getRefererPercent(_refererAddress);
            if (refererFeePercent > 0) {
                uint256 refererFeeAmount = (msg.value).div(1000).mul(refererFeePercent);
                if (refererFeeAmount > 0) {
                    payable(_refererAddress).transfer(refererFeeAmount);
                }
            }
        }

        require(params.amount >= 10000, 'PRESALE GENERATOR: MIN DIVIS');
        require(params.endTime.sub(params.startTime) <= PRESALE_SETTING.getMaxPresaleLength(), 'PRESALE GENERATOR: INVALID PRESALE LENGTH');
        require(params.tokenPrice.mul(params.hardCap) > 0, 'PRESALE GENERATOR: INVALID PARAMS');
        // ensure no overflow for future calculations
        require(params.liquidityPercent >= PRESALE_SETTING.getMinLiquidityPercent() && params.liquidityPercent <= 1000, 'PRESALE GENERATOR: INVALID LIQUIDITY PERCENT');

        uint256 tokenRequiredForPresale = PresaleHelper.calculateAmountRequired(params.amount, params.tokenPrice, params.listingPrice, params.liquidityPercent, PRESALE_SETTING.getTokenFeePercent());

        Presale newPresale = new Presale(address(this));
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokenRequiredForPresale);
        newPresale.setMainInfo(_presaleOwner, params.amount, params.tokenPrice, params.limitPerBuyer, params.hardCap, params.softCap, params.liquidityPercent, params.listingPrice, params.startTime, params.endTime, params.lockPeriod);
        newPresale.setFeeInfo(_baseToken, _presaleToken, PRESALE_SETTING.getBaseFeePercent(), PRESALE_SETTING.getTokenFeePercent(), refererFeePercent, PRESALE_SETTING.getBaseFeeAddress(), PRESALE_SETTING.getTokenFeeAddress(), _refererAddress);
        newPresale.setRoundInfo(_activeRound[0], _activeRound[1]);
        PRESALE_FACTORY.registerPresale(address(newPresale));
        emit CreatePresale(_presaleOwner, address(newPresale), msg.value, _refererAddress);
    }

}
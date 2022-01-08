// SPDX-License-Identifier: UNLICENSED

// This contract generates Pool contracts and registers them in the PoolFactory.
// Ideally you should not interact with this contract directly, and use the Pool app instead so warnings can be shown where necessary.

pragma solidity 0.8.11;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Pool.sol";

interface IPoolFactory {
    function registerPool(address _poolAddress) external;

    function poolIsRegistered(address _poolAddress) external view returns (bool);
}

contract PoolGenerator is Ownable {
    using SafeMath for uint256;

    IPoolFactory public POOL_FACTORY;
    IPoolSetting public POOL_SETTING;

    event CreatePool(address poolOwner, address poolAddress);

    struct PoolParams {
        uint256 amount;
        uint256 tokenPrice; // number pool token per base token
        uint256 limitPerBuyer; // number base token per user
        uint256 hardCap;
        uint256 softCap;
        uint256 startTime;
        uint256 endTime;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
    }

    constructor() {
        POOL_FACTORY = IPoolFactory(0x187633aDA5971d33e58460CEde80559CF12E8945);
        POOL_SETTING = IPoolSetting(0x3a8fC7D23E605268d71450a68F7B4c9e2e9F8927);
    }

    /**
     * @notice Creates a new Pool contract and registers it in the PoolFactory
     */
    function createPool(
        address payable _poolOwner,
        IERC20 _poolToken,
        IERC20 _baseToken,
        bool[4] memory _activeInfo,
        uint256[8] memory unitParams,
        uint256[] memory _vestingPeriod,
        uint256[] memory _vestingPercent
    ) public payable {

        require(POOL_SETTING.creatorAddressIsValid(msg.sender), 'POOL GENERATOR: INVALID CREATOR ADDRESS');

        PoolParams memory params;
        params.amount = unitParams[0];
        params.tokenPrice = unitParams[1];
        params.limitPerBuyer = unitParams[2];
        params.hardCap = unitParams[3];
        params.startTime = unitParams[4];
        params.endTime = unitParams[5];
        params.auctionStartTime = unitParams[6];
        params.auctionEndTime = unitParams[7];
        params.softCap = 0;

        require(params.limitPerBuyer > 0, 'POOL GENERATOR: INVALID LIMIT PER BUYER');
        require(POOL_SETTING.baseTokenIsValid(address(_baseToken)), 'POOL GENERATOR: INVALID BASE TOKEN');

        require(params.amount >= 10000, 'POOL GENERATOR: MIN DIVIS');
        require(params.hardCap > params.softCap, 'POOL GENERATOR: INVALID HARD CAP');
        require(params.startTime.add(POOL_SETTING.getMaxPoolLength()) >= params.endTime, 'POOL GENERATOR: INVALID POOL LENGTH');
        require(params.tokenPrice.mul(params.hardCap) > 0, 'POOL GENERATOR: INVALID PARAMS');

        // Active Vesting
        if (_activeInfo[2]) {
            // Validate Vesting
            require(_vestingPeriod.length > 0, 'POOL GENERATOR: INVALID VESTING PERIOD');
            require(_vestingPeriod.length == _vestingPercent.length, 'POOL GENERATOR: INVALID VESTING DATA');
            uint256 totalVestingPercent = 0;
            for (uint256 i = 0; i < _vestingPercent.length; i++) {
                totalVestingPercent = totalVestingPercent.add(_vestingPercent[i]);
            }
            require(totalVestingPercent == 1000, 'POOL GENERATOR: INVALID VESTING PERCENT');
        } else {
            delete _vestingPeriod;
            delete _vestingPercent;
        }

        // Active Zero Round
        if (_activeInfo[0]) {
            _activeInfo[3] = false;
        }

        Pool newPool = new Pool(address(this));
        newPool.setMainInfo(_poolOwner, params.amount, params.tokenPrice, params.limitPerBuyer, params.hardCap, params.softCap, params.startTime, params.endTime);
        newPool.setTokenInfo(_baseToken, _poolToken);
        newPool.setRoundInfo(_activeInfo[0], _activeInfo[1], _activeInfo[3]);
        newPool.setVestingInfo(_activeInfo[2], _vestingPeriod, _vestingPercent);
        newPool.setAuctionRoundInfo(params.auctionStartTime, params.auctionEndTime);

        POOL_FACTORY.registerPool(address(newPool));
        emit CreatePool(_poolOwner, address(newPool));
    }

}
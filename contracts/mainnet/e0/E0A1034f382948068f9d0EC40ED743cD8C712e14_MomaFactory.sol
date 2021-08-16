pragma solidity 0.5.17;

import "./MomaMaster.sol";
import "./MomaPool.sol";
import "./MomaFactoryInterface.sol";
import "./MomaFactoryProxy.sol";
import "./PriceOracle.sol";


contract MomaFactory is MomaFactoryInterface, MomaFactoryStorage {

    bool public constant isMomaFactory = true;
    uint public constant feeFactorMaxMantissa = 0.3e18;

    function createPool() external returns (address pool) {
        bytes memory bytecode = type(MomaPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMomaPool(pool).initialize(msg.sender, momaMaster);
        PoolInfo storage info = pools[pool];
        info.creator = msg.sender;
        info.poolFeeAdmin = feeAdmin;
        info.poolFeeReceiver = defualtFeeReceiver;
        info.feeFactor = defualtFeeFactorMantissa;
        allPools.push(pool);
        emit PoolCreated(pool, msg.sender, allPools.length);
    }

    /*** view Functions ***/
    function getAllPools() public view returns (address[] memory) {
        return allPools;
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    function getMomaFeeAdmin(address pool) external view returns (address) {
        return pools[pool].poolFeeAdmin;
    }

    function getMomaFeeReceiver(address pool) external view returns (address payable) {
        return pools[pool].poolFeeReceiver;
    }

    function getMomaFeeFactorMantissa(address pool, address underlying) external view returns (uint) {
        if (pools[pool].noFee || noFeeTokens[underlying]) {
            return 0;
        } else if (tokenFeeFactors[underlying] != 0) {
            return tokenFeeFactors[underlying];
        } else {
            return pools[pool].feeFactor;
        }
    }

    function isMomaPool(address pool) external view returns (bool) {
        return pools[pool].creator != address(0);
    }

    function isLendingPool(address pool) external view returns (bool) {
        return pools[pool].isLending;
    }

    function isTimelock(address b) external view returns (bool) {
        return isCodeSame(timelock, b);
    }

    function isMomaMaster(address b) external view returns (bool) {
        return isCodeSame(momaMaster, b);
    }

    function isMEtherImplementation(address b) external view returns (bool) {
        return isCodeSame(mEtherImplementation, b);
    }

    function isMErc20Implementation(address b) external view returns (bool) {
        return isCodeSame(mErc20Implementation, b);
    }

    function isMToken(address b) external view returns (bool) {
        return isCodeSame(mErc20, b) || isCodeSame(mEther, b);
    }

    function isCodeSame(address a, address b) public view returns (bool) {
        return keccak256(at(a)) == keccak256(at(b));
    }

    function at(address _addr) internal view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }


    /*** pool Functions ***/
    function upgradeLendingPool() external returns (bool) {
        // pool must be msg.sender, only pool can call this function
        PoolInfo storage info = pools[msg.sender];
        require(info.creator != address(0), 'MomaFactory: pool not created');
        require(info.isLending == false, 'MomaFactory: can only upgrade once');
        require(info.allowUpgrade == true || allowUpgrade == true, 'MomaFactory: upgrade not allowed');

        IMomaFarming(momaFarming).upgradeLendingPool(msg.sender);
        info.isLending = true;
        lendingPoolNum += 1;
        emit NewLendingPool(msg.sender);

        return true;
    }

    /*** admin Functions ***/
    function _become(MomaFactoryProxy proxy) public {
        require(msg.sender == proxy.admin(), "only momaFactory admin can change brains");
        require(proxy._acceptImplementation() == 0, "change not authorized");
    }

    function _setMomaFarming(address newMomaFarming) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(IMomaFarming(newMomaFarming).isMomaFarming() == true, 'MomaFactory: newMomaFarming check');
        address oldMomaFarming = momaFarming;
        momaFarming = newMomaFarming;
        emit NewMomaFarming(oldMomaFarming, newMomaFarming);
    }

    function _setFarmingDelegate(address newDelegate) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(IFarmingDelegate(newDelegate).isFarmingDelegate() == true, 'MomaFactory: newDelegate check');
        address oldDelegate = farmingDelegate;
        farmingDelegate = newDelegate;
        emit NewFarmingDelegate(oldDelegate, newDelegate);
    }

    function _setOracle(address newOracle) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(PriceOracle(newOracle).isPriceOracle(), 'MomaFactory: newOracle check');
        address oldOracle = oracle;
        oracle = newOracle;
        emit NewOracle(oldOracle, newOracle);
    }

    function _setTimelock(address newTimelock) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        address oldTimelock = timelock;
        timelock = newTimelock;
        emit NewTimelock(oldTimelock, newTimelock);
    }

    function _setMomaMaster(address newMomaMaster) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(MomaMasterInterface(newMomaMaster).isMomaMaster() == true, 'MomaFactory: newMomaMaster check');
        address oldMomaMaster = momaMaster;
        momaMaster = newMomaMaster;
        emit NewMomaMaster(oldMomaMaster, newMomaMaster);
    }

    function _setMEther(address newMEther) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(MTokenInterface(newMEther).isMToken() == true, 'MomaFactory: newMEther check');
        address oldEther = mEther;
        mEther = newMEther;
        emit NewMEther(oldEther, newMEther);
    }

    function _setMErc20(address newMErc20) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(MTokenInterface(newMErc20).isMToken() == true, 'MomaFactory: newMErc20 check');
        address oldMErc20 = mErc20;
        mErc20 = newMErc20;
        emit NewMErc20(oldMErc20, newMErc20);
    }

    function _setMEtherImplementation(address newMEtherImplementation) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(MTokenInterface(newMEtherImplementation).isMToken() == true, 'MomaFactory: newMEtherImplementation check');
        address oldMEtherImplementation = mEtherImplementation;
        mEtherImplementation = newMEtherImplementation;
        emit NewMEtherImplementation(oldMEtherImplementation, newMEtherImplementation);
    }

    function _setMErc20Implementation(address newMErc20Implementation) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        require(MTokenInterface(newMErc20Implementation).isMToken() == true, 'MomaFactory: newMErc20Implementation check');
        address oldMErc20Implementation = mErc20Implementation;
        mErc20Implementation = newMErc20Implementation;
        emit NewMErc20Implementation(oldMErc20Implementation, newMErc20Implementation);
    }

    function _setAllowUpgrade(bool allow) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        allowUpgrade = allow;
    }

    function _allowUpgradePool(address pool) external {
        require(msg.sender == admin, 'MomaFactory: admin check');
        PoolInfo storage info = pools[pool];
        require(info.creator != address(0), 'MomaFactory: pool not created');
        info.allowUpgrade = true;
    }

    /*** feeAdmin Functions ***/
    function setFeeAdmin(address _newFeeAdmin) external {
        require(msg.sender == feeAdmin, 'MomaFactory: feeAdmin check');
        require(_newFeeAdmin != address(0), 'MomaFactory: newFeeAdmin check');
        address oldFeeAdmin = feeAdmin;
        feeAdmin = _newFeeAdmin;
        emit NewFeeAdmin(oldFeeAdmin, _newFeeAdmin);
    }

    function setDefualtFeeReceiver(address payable _newFeeReceiver) external {
        require(msg.sender == feeAdmin, 'MomaFactory: feeAdmin check');
        require(_newFeeReceiver != address(0), 'MomaFactory: newFeeReceiver check');
        address oldFeeReceiver = defualtFeeReceiver;
        defualtFeeReceiver = _newFeeReceiver;
        emit NewDefualtFeeReceiver(oldFeeReceiver, _newFeeReceiver);
    }

    function setDefualtFeeFactor(uint _newFeeFactor) external {
        require(msg.sender == feeAdmin, 'MomaFactory: feeAdmin check');
        require(_newFeeFactor <= feeFactorMaxMantissa, 'MomaFactory: newFeeFactor bound check');
        uint oldFeeFactor = defualtFeeFactorMantissa;
        defualtFeeFactorMantissa = _newFeeFactor;
        emit NewDefualtFeeFactor(oldFeeFactor, _newFeeFactor);
    }

    function setNoFeeTokenStatus(address token, bool _noFee) external {
        require(msg.sender == feeAdmin, 'MomaFactory: feeAdmin check');
        bool oldNoFeeTokenStatus = noFeeTokens[token];
        noFeeTokens[token] = _noFee;
        emit NewNoFeeTokenStatus(token, oldNoFeeTokenStatus, _noFee);
    }

    function setTokenFeeFactor(address token, uint _newFeeFactor) external {
        require(msg.sender == feeAdmin, 'MomaFactory: feeAdmin check');
        require(_newFeeFactor <= feeFactorMaxMantissa, 'MomaFactory: newFeeFactor bound check');
        uint oldFeeFactor = tokenFeeFactors[token];
        tokenFeeFactors[token] = _newFeeFactor;
        emit NewTokenFeeFactor(token, oldFeeFactor, _newFeeFactor);
    }

    /*** poolFeeAdmin Functions ***/
    function setPoolFeeAdmin(address pool, address _newPoolFeeAdmin) external {
        PoolInfo storage info = pools[pool];
        require(msg.sender == info.poolFeeAdmin, 'MomaFactory: poolFeeAdmin check');
        require(_newPoolFeeAdmin != address(0), 'MomaFactory: newPoolFeeAdmin check');
        address oldPoolFeeAdmin = info.poolFeeAdmin;
        info.poolFeeAdmin = _newPoolFeeAdmin;
        emit NewPoolFeeAdmin(pool, oldPoolFeeAdmin, _newPoolFeeAdmin);
    }

    function setPoolFeeReceiver(address pool, address payable _newPoolFeeReceiver) external {
        PoolInfo storage info = pools[pool];
        require(msg.sender == info.poolFeeAdmin, 'MomaFactory: poolFeeAdmin check');
        require(_newPoolFeeReceiver != address(0), 'MomaFactory: newPoolFeeReceiver check');
        address oldPoolFeeReceiver = info.poolFeeReceiver;
        info.poolFeeReceiver = _newPoolFeeReceiver;
        emit NewPoolFeeReceiver(pool, oldPoolFeeReceiver, _newPoolFeeReceiver);
    }

    function setPoolFeeFactor(address pool, uint _newFeeFactor) external {
        PoolInfo storage info = pools[pool];
        require(msg.sender == info.poolFeeAdmin, 'MomaFactory: poolFeeAdmin check');
        require(_newFeeFactor <= feeFactorMaxMantissa, 'MomaFactory: newFeeFactor bound check');
        uint oldPoolFeeFactor = info.feeFactor;
        info.feeFactor = _newFeeFactor;
        emit NewPoolFeeFactor(pool, oldPoolFeeFactor, _newFeeFactor);
    }

    function setPoolFeeStatus(address pool, bool _noFee) external {
        PoolInfo storage info = pools[pool];
        require(msg.sender == info.poolFeeAdmin, 'MomaFactory: poolFeeAdmin check');
        bool oldPoolFeeStatus = info.noFee;
        info.noFee = _noFee;
        emit NewPoolFeeStatus(pool, oldPoolFeeStatus, _noFee);
    }
}


interface IMomaPool {
    function initialize(address admin_, address implementation_) external;
}

interface IFarmingDelegate {
    function isFarmingDelegate() external view returns (bool);
}
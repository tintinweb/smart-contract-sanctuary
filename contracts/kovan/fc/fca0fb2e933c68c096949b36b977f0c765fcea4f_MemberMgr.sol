//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "MemberMgrIf.sol";
import "Claimable.sol";
import "CanReclaimToken.sol";

/// @title MemberMgr - add, delete, suspend and resume merchant and it’s eth address; reset the custodian’s eth address.
contract MemberMgr is Claimable, MemberMgrIf, CanReclaimToken {
    address public custodian;
    enum MerchantStatus {STOPPED, VALID}
    struct MerchantStatusData {
        MerchantStatus status;
        bool _exist;
    }

    function getStatusString(MerchantStatusData memory data) internal pure returns (string memory) {
        if (!data._exist) return "not-exist";
        if (data.status == MerchantStatus.STOPPED) {
            return "stopped";
        } else if (data.status == MerchantStatus.VALID) {
            return "valid";
        } else {
            return "not-exist";
        }
    }

    mapping(address => MerchantStatusData) public merchantStatus;
    address[] merchantList;

    function getMerchantNumber() public view returns (uint){
        return merchantList.length;
    }

    function getMerchantState(uint index) public view returns (address _addr, string memory _status){
        require(index < merchantList.length, "invalid index");
        address addr = merchantList[index];
        MerchantStatusData memory data = merchantStatus[addr];
        _addr = addr;
        _status = getStatusString(data);
    }

    function requireMerchant(address _who) override public view {
        MerchantStatusData memory merchantState = merchantStatus[_who];
        require (merchantState._exist, "not a merchant");

        require (merchantState.status != MerchantStatus.STOPPED, "merchant has been stopped");

        require(merchantState.status == MerchantStatus.VALID, "merchant not valid");
    }


    function requireCustodian(address _who) override public view {
        require(_who == custodian, "not custodian");
    }

    event CustodianSet(address indexed custodian);

    function setCustodian(address _custodian) external onlyOwner returns (bool) {
        require(_custodian != address(0), "invalid custodian address");
        custodian = _custodian;

        emit CustodianSet(_custodian);
        return true;
    }

    event NewMerchant(address indexed merchant);

    function addMerchant(address merchant) external onlyOwner returns (bool) {
        require(merchant != address(0), "invalid merchant address");
        MerchantStatusData memory data = merchantStatus[merchant];
        require(!data._exist, "merchant exists");
        merchantStatus[merchant] = MerchantStatusData({
            status : MerchantStatus.VALID,
            _exist : true
            });

        merchantList.push(merchant);
        emit NewMerchant(merchant);
        return true;
    }

    event MerchantStopped(address indexed merchant);

    function stopMerchant(address merchant) external onlyOwner returns (bool) {
        require(merchant != address(0), "invalid merchant address");
        MerchantStatusData memory data = merchantStatus[merchant];
        require(data._exist, "merchant not exists");
        require(data.status == MerchantStatus.VALID, "invalid status");
        merchantStatus[merchant].status = MerchantStatus.STOPPED;

        emit MerchantStopped(merchant);
        return true;
    }

    event MerchantResumed(address indexed merchant);

    function resumeMerchant(address merchant) external onlyOwner returns (bool) {
        require(merchant != address(0), "invalid merchant address");
        MerchantStatusData memory data = merchantStatus[merchant];
        require(data._exist, "merchant not exists");
        require(data.status == MerchantStatus.STOPPED, "invalid status");
        merchantStatus[merchant].status = MerchantStatus.VALID;

        emit MerchantResumed(merchant);
        return true;
    }

    function isCustodian(address addr) external view returns (bool) {
        return (addr == custodian);
    }

    function isMerchant(address addr) external view returns (bool) {
        return merchantStatus[addr]._exist && merchantStatus[addr].status == MerchantStatus.VALID;
    }
}
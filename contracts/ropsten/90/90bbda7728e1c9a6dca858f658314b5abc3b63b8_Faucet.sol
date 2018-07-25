pragma solidity ^0.4.24;
contract Adminable {
    address admin;
    constructor () public {
        admin = msg.sender;
    }
    function _isTrue(address _addr) internal view returns(bool) {
        if (_addr == address(0)) return false;
        else if (_addr == address(this)) return false;
        else return true;
    }
    function _isAdmin() internal view returns(bool) {
        if (msg.sender == admin) return true;
        else return false;
    }
    function transferAdminship(address _newAdmin) public {
        require(_isAdmin());
        require(_isTrue(_newAdmin));
        admin = _newAdmin;
    }
}
contract Claimable is Adminable {
    uint unclaimed = 1 ether;
    uint maxReward = 1 ether;
    function _remainReward() internal view returns(uint) {
        return unclaimed;
    }
    function updateClaimable(uint _totalReward) public {
        require(_isAdmin());
        require(_totalReward > 1 finney);
        maxReward = _totalReward;
    }
    function reset() public {
        require(_isAdmin());
        unclaimed = maxReward;
    }
    function _calcReward() internal view returns(uint) {
        uint claimReward = uint8(bytes4(keccak256(abi.encode(unclaimed / now))));
        claimReward *= 1 szabo;
        return uint256(claimReward);
    }
}
contract Refillable is Claimable {
    function () public payable {
        require(msg.value > 10 finney && msg.data.length == 0);
        unclaimed += msg.value;
    }
}
contract Faucet is Refillable {
    function claim() public returns(bool) {
        uint _getReward = _calcReward();
        require(_getReward <= unclaimed);
        msg.sender.transfer(_getReward);
        unclaimed -= _getReward;
        return true;
    }
}
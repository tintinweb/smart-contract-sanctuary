pragma solidity 0.5.16;


contract IERC20WithCheckpointing {
    function balanceOf(address _owner) public view returns (uint256);
    function balanceOfAt(address _owner, uint256 _blockNumber) public view returns (uint256);

    function totalSupply() public view returns (uint256);
    function totalSupplyAt(uint256 _blockNumber) public view returns (uint256);
}

contract IIncentivisedVotingLockup is IERC20WithCheckpointing {

    function getLastUserPoint(address _addr) external view returns(int128 bias, int128 slope, uint256 ts);
    function createLock(uint256 _value, uint256 _unlockTime) external;
    function withdraw() external;
    function increaseLockAmount(uint256 _value) external;
    function increaseLockLength(uint256 _unlockTime) external;
    function eject(address _user) external;
    function expireContract() external;

    function claimReward() public;
    function earned(address _account) public view returns (uint256);
}

contract Ejector {

    IIncentivisedVotingLockup public votingLockup;

    constructor(IIncentivisedVotingLockup _votingLockup) public {
        votingLockup = _votingLockup;
    }

    function ejectMany(address[] calldata _users) external {
        uint count = _users.length;
        for(uint i = 0; i < count; i++){
            votingLockup.eject(_users[i]);
        }
    }

}
pragma solidity 0.5.0;

import "./SafeMath.sol";
import "./RewardContract.sol";
import "./Adbank.sol";

contract AdbankRewardClaimContract is RewardContract {
    using SafeMath for uint256;

    // Stop contract from executing it's main logic
    bool public suspended;

    // Limit the size of incoming requests (assignRewards and claimRewards functions)
    uint8 public batchLimit;

    address public owner;
    mapping(bytes32 => uint256) public balances;
    uint256 public totalReward;

    // AdBank contract that is used for the actual transfers
    Adbank public adbankContract;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    // Functions with this modifier can only be executed if execution is not suspended
    modifier notSuspended() {
        require (suspended == false);
        _;
    }

    constructor(address _adbankContract, uint8 _batchLimit) public {
        owner = msg.sender;
        suspended = false;
        totalReward = 0;
        adbankContract = Adbank(_adbankContract);
        batchLimit = _batchLimit;
    }

    // Suspend / resume the execution of contract methods
    function suspend(bool _suspended) external onlyOwner {
        suspended = _suspended;
    }

    // Change owner
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    // Drain all funds. Returns tokens to the contract owner
    function drain() external onlyOwner {
        uint256 contractBalance = adbankContract.balanceOf(address(this));
        require(contractBalance > 0);

        require(transferReward(owner, contractBalance));
        suspended = true;
    }

    // Change the requests limit
    function setBatchLimit(uint8 newLimit) onlyOwner external {
        require(newLimit > 0);
        batchLimit = newLimit;
    }

    // Change the Adbank contract
    function setAdbankContract(address _adbankContract) onlyOwner external {
        require(_adbankContract != address(0x0));
        adbankContract = Adbank(_adbankContract);
    }

    // Get user balance according to user's blade id
    function balanceOf(bytes32 _bladeId) public view returns (uint256 balance) {
        return balances[_bladeId];
    }

    // Assign rewards according to user's blade ids.
    // The size of incoming data is limited to be in (0;batchLimit] range
    // Requires this contract to have token balance to cover the incoming rewards
    function assignRewards(bytes32[] calldata _bladeIds, uint256[] calldata _rewards) notSuspended onlyOwner external {
        require(_bladeIds.length > 0 && _bladeIds.length <= batchLimit);
        require(_bladeIds.length == _rewards.length);

        for (uint8 i = 0; i < _bladeIds.length; i++) {
            balances[_bladeIds[i]] = (balances[_bladeIds[i]]).add(_rewards[i]);
            totalReward = (totalReward).add(_rewards[i]);
            emit RewardAssigned(_bladeIds[i], _rewards[i]);
        }

        require(hasEnoughBalance());
    }

    // Claim rewards according to user's blade ids.
    // The size of incoming data is limited to be in (0;batchLimit] range
    // Requires this contract to have token balance to cover the rewards
    function claimRewards(bytes32[] calldata _bladeIds, address[] calldata _wallets) notSuspended onlyOwner external {
        require(_bladeIds.length > 0 && _bladeIds.length <= batchLimit);
        require(_bladeIds.length == _wallets.length);

        require(hasEnoughBalance());

        for (uint8 i = 0; i < _bladeIds.length; i++) {
            processReward(_bladeIds[i], _wallets[i], false);
        }
    }

    // Claim reward for the specified user
    function claimReward(bytes32 _bladeId, address _to) notSuspended onlyOwner external returns (bool ok) {
        return processReward(_bladeId, _to, true);
    }

    // Send the reward and return result.
    // Will throw exception or skip the execution depending on the _requireValid param
    function processReward(bytes32 _bladeId, address _to, bool _requireValid) notSuspended onlyOwner internal returns (bool ok) {
        bool valid = validAddressAndBalance(_to, _bladeId);

        if (_requireValid) {
            require(valid);
        } else if (!valid) {
            return false;
        }

        uint256 rewardToSend = balances[_bladeId];

        balances[_bladeId] = 0;
        totalReward = (totalReward).sub(rewardToSend);

        bool transferStatus = transferReward(_to, rewardToSend);
        emit RewardClaimed(_bladeId, _to, rewardToSend);
        return transferStatus;
    }

    // Do the actual transfer of the reward to the specified address
    function transferReward(address _to, uint256 _amount) onlyOwner internal returns (bool ok) {
        bool result = adbankContract.transfer(_to, _amount);
        require(result);
        return result;
    }

    // Check that address is valid, user has balance and contract has enough balance
    function validAddressAndBalance(address _address, bytes32 _bladeId) internal view returns (bool valid) {
        if (_address != address(0x0) && balances[_bladeId] > 0) {
            return true;
        }

        return false;
    }

    // Check that contract has enough tokens to cover transactions with rewards
    function hasEnoughBalance() public view returns (bool enoughBalance) {
        return adbankContract.balanceOf(address(this)) >= totalReward;
    }
}
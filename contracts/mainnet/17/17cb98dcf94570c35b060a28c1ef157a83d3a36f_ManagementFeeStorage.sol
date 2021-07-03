/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity >=0.5.0 <0.7.0;

contract ManagementFeeStorage {
    address public manager;
    uint256 public platformFee;

    mapping(address => uint256) managementFees;

    constructor(uint256 _platformFee) public {
        manager = msg.sender;
        platformFee = _platformFee;
    }

    modifier onlyManager {
        require(msg.sender == manager, "Not Authorized");
        _;
    }

    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }

    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    function setPlatformFee(uint256 _platformFee) external onlyManager {
        platformFee = _platformFee;
    }

    function getStrategyFee(address _strategy) external view returns (uint256) {
        return managementFees[_strategy];
    }

    function setStrategyFee(address _strategy, uint256 _strategyFee)
        external
        onlyManager
    {
        managementFees[_strategy] = _strategyFee;
    }
}
// CurveYCRVVoter: https://etherscan.io/address/0xF147b8125d2ef93FB6965Db97D6746952a133934#code

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/curve.sol";

contract CRVLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address public constant escrow = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;

    address public governance;
    mapping(address => bool) public voters;

    constructor(address _governance) public {
        governance = _governance;
    }

    function getName() external pure returns (string memory) {
        return "CRVLocker";
    }

    function addVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = true;
    }

    function removeVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = false;
    }

    function withdraw(address _asset) external returns (uint256 balance) {
        require(voters[msg.sender], "!voter");
        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(msg.sender, balance);
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(voters[msg.sender] || msg.sender == governance, "!authorized");
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        ICurveVotingEscrow(escrow).create_lock(_value, _unlockTime);
    }

    function increaseAmount(uint256 _value) external {
        require(voters[msg.sender] || msg.sender == governance, "!authorized");
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        ICurveVotingEscrow(escrow).increase_amount(_value);
    }

    function increaseUnlockTime(uint256 _unlockTime) external {
        require(voters[msg.sender] || msg.sender == governance, "!authorized");
        ICurveVotingEscrow(escrow).increase_unlock_time(_unlockTime);
    }

    function release() external {
        require(voters[msg.sender] || msg.sender == governance, "!authorized");
        ICurveVotingEscrow(escrow).withdraw();
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory) {
        require(voters[msg.sender] || msg.sender == governance, "!governance");

        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "!execute-success");

        return (success, result);
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

interface ICurveRewards {
    function notifyRewardAmount(uint256 amount) external;
}

/// @title CurveRewardsEscrowBeneficiary
/// @notice A beneficiary contract that can receive a withdrawal phase from a
///         PhasedEscrow contract. Immediately stakes the received tokens on a
///         designated CurveRewards contract.
contract CurveRewardsEscrowBeneficiary is Ownable {
    IERC20 public token;
    ICurveRewards public curveRewards;

    constructor(IERC20 _token, ICurveRewards _curveRewards) public {
        token = _token;
        curveRewards = _curveRewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        token.approve(address(curveRewards), amount);
        curveRewards.notifyRewardAmount(amount);
    }
}

/// @dev Interface of recipient contract for approveAndCall pattern.
interface IStakerRewards {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

/// @dev Interface of recipient contract for approveAndCall pattern.
interface IStakerRewards {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title StakerRewardsBeneficiary
/// @notice An abstract beneficiary contract that can receive a withdrawal phase
///         from a PhasedEscrow contract. The received tokens are immediately 
///         funded for a designated rewards escrow beneficiary contract.
contract StakerRewardsBeneficiary is Ownable {
    IERC20 public token;
    IStakerRewards public stakerRewards;

    constructor(IERC20 _token, IStakerRewards _stakerRewards) public {
        token = _token;
        stakerRewards = _stakerRewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        bool success = token.approve(address(stakerRewards), amount);
        require(success, "Token transfer approval failed");
        
        stakerRewards.receiveApproval(
            address(this),
            amount,
            address(token),
            ""
        );
    }
}

/// @title BeaconRewardsEscrowBeneficiary
/// @notice Transfer the received tokens to a designated
///         BeaconRewardsEscrowBeneficiary contract.
contract BeaconRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./TokenGrant.sol";

/// @title ManagedGrant
/// @notice A managed grant acts as the grantee towards the token grant contract,
/// proxying instructions from the actual grantee.
/// The address used by the actual grantee
/// to issue instructions and withdraw tokens
/// can be reassigned with the consent of the grant manager.
contract ManagedGrant {
    using SafeERC20 for ERC20Burnable;

    ERC20Burnable public token;
    TokenGrant public tokenGrant;
    address public grantManager;
    uint256 public grantId;
    address public grantee;
    address public requestedNewGrantee;

    event GranteeReassignmentRequested(
        address newGrantee
    );
    event GranteeReassignmentConfirmed(
        address oldGrantee,
        address newGrantee
    );
    event GranteeReassignmentCancelled(
        address cancelledRequestedGrantee
    );
    event GranteeReassignmentChanged(
        address previouslyRequestedGrantee,
        address newRequestedGrantee
    );
    event TokensWithdrawn(
        address destination,
        uint256 amount
    );

    constructor(
        address _tokenAddress,
        address _tokenGrant,
        address _grantManager,
        uint256 _grantId,
        address _grantee
    ) public {
        token = ERC20Burnable(_tokenAddress);
        tokenGrant = TokenGrant(_tokenGrant);
        grantManager = _grantManager;
        grantId = _grantId;
        grantee = _grantee;
    }

    /// @notice Request a reassignment of the grantee address.
    /// Can only be called by the grantee.
    /// @param _newGrantee The requested new grantee.
    function requestGranteeReassignment(address _newGrantee)
        public
        onlyGrantee
        noRequestedReassignment
    {
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentRequested(_newGrantee);
    }

    /// @notice Cancel a pending grantee reassignment request.
    /// Can only be called by the grantee.
    function cancelReassignmentRequest()
        public
        onlyGrantee
        withRequestedReassignment
    {
        address cancelledGrantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentCancelled(cancelledGrantee);
    }

    /// @notice Change a pending reassignment request to a different grantee.
    /// Can only be called by the grantee.
    /// @param _newGrantee The address of the new requested grantee.
    function changeReassignmentRequest(address _newGrantee)
        public
        onlyGrantee
        withRequestedReassignment
    {
        address previouslyRequestedGrantee = requestedNewGrantee;
        require(
            previouslyRequestedGrantee != _newGrantee,
            "Unchanged reassignment request"
        );
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentChanged(previouslyRequestedGrantee, _newGrantee);
    }

    /// @notice Confirm a grantee reassignment request and set the new grantee as the grantee.
    /// Can only be called by the grant manager.
    /// @param _newGrantee The address of the new grantee.
    /// Must match the currently requested new grantee.
    function confirmGranteeReassignment(address _newGrantee)
        public
        onlyManager
        withRequestedReassignment
    {
        address oldGrantee = grantee;
        require(
            requestedNewGrantee == _newGrantee,
            "Reassignment address mismatch"
        );
        grantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentConfirmed(oldGrantee, _newGrantee);
    }

    /// @notice Withdraw all unlocked tokens from the grant.
    function withdraw() public onlyGrantee {
        require(
            requestedNewGrantee == address(0),
            "Can not withdraw with pending reassignment"
        );
        tokenGrant.withdraw(grantId);
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(grantee, amount);
        emit TokensWithdrawn(grantee, amount);
    }

    /// @notice Stake tokens from the grant.
    /// @param _stakingContract The contract to stake the tokens on.
    /// @param _amount The amount of tokens to stake.
    /// @param _extraData Data for the stake delegation.
    /// This byte array must have the following values concatenated:
    /// beneficiary address (20 bytes)
    /// operator address (20 bytes)
    /// authorizer address (20 bytes)
    function stake(
        address _stakingContract,
        uint256 _amount,
        bytes memory _extraData
    ) public onlyGrantee {
        tokenGrant.stake(grantId, _stakingContract, _amount, _extraData);
    }

    /// @notice Cancel delegating tokens to the given operator.
    function cancelStake(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.cancelStake(_operator);
    }

    /// @notice Begin undelegating tokens from the given operator.
    function undelegate(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.undelegate(_operator);
    }

    /// @notice Recover tokens previously staked and delegated to the operator.
    function recoverStake(address _operator) public {
        tokenGrant.recoverStake(_operator);
    }

    function _setRequestedNewGrantee(address _newGrantee) internal {
        require(_newGrantee != address(0), "Invalid new grantee address");
        require(_newGrantee != grantee, "New grantee same as current grantee");

        requestedNewGrantee = _newGrantee;
    }

    modifier withRequestedReassignment {
        require(
            requestedNewGrantee != address(0),
            "No reassignment requested"
        );
        _;
    }

    modifier noRequestedReassignment {
        require(
            requestedNewGrantee == address(0),
            "Reassignment already requested"
        );
        _;
    }

    modifier onlyGrantee {
        require(
            msg.sender == grantee,
            "Only grantee may perform this action"
        );
        _;
    }

    modifier onlyGranteeOr(address _operator) {
        require(
            msg.sender == grantee || msg.sender == _operator,
            "Only grantee or operator may perform this action"
        );
        _;
    }

    modifier onlyManager {
        require(
            msg.sender == grantManager,
            "Only grantManager may perform this action"
        );
        _;
    }
}

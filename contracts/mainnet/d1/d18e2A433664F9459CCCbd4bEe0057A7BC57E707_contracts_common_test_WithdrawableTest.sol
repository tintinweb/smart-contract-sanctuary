pragma solidity ^0.6.0;

import "../implementation/Withdrawable.sol";


// WithdrawableTest is derived from the abstract contract Withdrawable for testing purposes.
contract WithdrawableTest is Withdrawable {
    enum Roles { Governance, Withdraw }

    // solhint-disable-next-line no-empty-blocks
    constructor() public {
        _createExclusiveRole(uint256(Roles.Governance), uint256(Roles.Governance), msg.sender);
        _createWithdrawRole(uint256(Roles.Withdraw), uint256(Roles.Governance), msg.sender);
    }

    function pay() external payable {
        require(msg.value > 0);
    }

    function setInternalWithdrawRole(uint256 setRoleId) public {
        _setWithdrawRole(setRoleId);
    }
}

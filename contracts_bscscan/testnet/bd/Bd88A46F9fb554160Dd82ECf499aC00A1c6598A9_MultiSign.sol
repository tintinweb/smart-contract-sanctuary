// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MultiSign is Ownable {
    using SafeMath for uint256;

    enum TransferStatus {
        PENDING,
        SUCCESS,
        CANCELLED
    }

    struct Transfer {
        uint256 id;
        uint256 amount;
        uint256 approvals;
        address to;
        address creator;
        TransferStatus status;
    }

    event EAddMember(address _member);
    event EMakeTransfer(uint256 _transferId, uint256 _amount, address _to);

    uint256 private _quorum;
    IERC20 _plvToken;

    address[] members;
    Transfer[] transfers;

    mapping(address => mapping(uint256 => bool)) approvalsToken;

    modifier onlyMember() {
        bool allowed;
        (allowed, ) = _isMember(msg.sender);
        require(allowed, "NOT_A_MEMBER");
        _;
    }

    constructor(address plvToken) {
        _quorum = 51;
        _plvToken = IERC20(plvToken);
        members.push(msg.sender);
    }

    function transferOwnership(address _owner) public override {
        require(_owner != address(0), "ZERO_ADDRESS");
        super._transferOwnership(_owner);
    }

    function setQuorum(uint256 quorum) public onlyOwner {
        require(quorum >= 51, "QUORUM_MUST_BE_LARGE_HALF_PERCENT_TOTAL_MEMBER");
        _quorum = quorum;
    }

    // Only owner can call make transfer from this contract
    // Owner is a member to vote
    function makeTransfer(address _to, uint256 _amount) public onlyOwner {
        // Check balance token before make transfer
        require(
            _plvToken.balanceOf(address(this)) >= _amount,
            "NOT_ENOUGH_TOKEN"
        );
        uint256 _transferId = transfers.length;

        transfers.push(
            Transfer(
                _transferId,
                _amount,
                1,
                _to,
                msg.sender,
                TransferStatus.PENDING
            )
        );
        approvalsToken[msg.sender][_transferId] = true;

        emit EMakeTransfer(_transferId, _amount, _to);
    }

    function approveTransfer(uint256 _id) public onlyMember {
        require(
            transfers[_id].status == TransferStatus.PENDING,
            "TRANSFER_HAS_ALREADY_BEEN_SENT"
        );

        if (transfers[_id].creator != owner()) {
            transfers[_id].status = TransferStatus.CANCELLED;
            revert("CREATOR_TRANSFER_IS_NOT_CURRENTLY_OWNER");
        }

        require(
            !approvalsToken[msg.sender][_id],
            "CANNOT_APPROVER_A_TRANSFER_TWICE"
        );

        approvalsToken[msg.sender][_id] = true;
        transfers[_id].approvals++;

        if (!_isMultiApproved(_id)) return;

        transfers[_id].status = TransferStatus.SUCCESS;
        address _to = transfers[_id].to;
        uint256 amount = transfers[_id].amount;
        _plvToken.transfer(_to, amount);
    }

    function addMember(address _member) public onlyOwner {
        require(_member != address(0), "ZERO_ADDRESS");
        bool isApprover;
        (isApprover, ) = _isMember(_member);
        require(!isApprover, "EXIST_APPROVER");

        members.push(_member);
        emit EAddMember(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(_member != address(0), "ZERO_ADDRESS");
        bool isApprover;
        uint256 index;
        (isApprover, index) = _isMember(_member);
        require(isApprover, "NOT_A_MEMBER");

        for (uint256 i = index; i < members.length - 1; i++) {
            members[i] = members[i + 1];
        }
        delete members[members.length - 1];
    }

    function _isMultiApproved(uint256 _id) internal view returns (bool) {
        uint256 approvals = transfers[_id].approvals;
        uint256 totalApprover = members.length;
        return approvals.mul(100).div(totalApprover) >= _quorum;
    }

    function _isMember(address _member) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) return (true, i);
        }
        return (false, 0);
    }

    function getTransferById(uint256 _transferId)
        public
        view
        returns (Transfer memory)
    {
        require(_transferId <= transfers.length, "INVALID_TRANSFER_ID");
        return transfers[_transferId];
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }
}
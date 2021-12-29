/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

pragma solidity ^0.5.8;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// @title Multisig ERC20 and Ether contract
// @dev Allows multisig management of Ether and ERC20 funds, requiring 50% of owners (rounded up)
//   to approve any withdrawal or change in ownership
// @author Nova Token (https://www.novatoken.io)
// (c) 2019 Nova Token Ltd. All Rights Reserved. This code is not open source.
contract Multisig {
    address[] public owners;

    mapping(address => mapping(address => uint256)) withdrawalRequests;
    mapping(address => mapping(address => address[])) withdrawalApprovals;

    mapping(address => address[]) ownershipAdditions;
    mapping(address => address[]) ownershipRemovals;

    event ApproveNewOwner(address indexed approver, address indexed subject);
    event ApproveRemovalOfOwner(
        address indexed approver,
        address indexed subject
    );
    event OwnershipChange(
        address indexed owner,
        bool indexed isAddition,
        bool indexed isRemoved
    );
    event Deposit(
        address indexed tokenContract,
        address indexed sender,
        uint256 amount
    );
    event Withdrawal(
        address indexed tokenContract,
        address indexed recipient,
        uint256 amount
    );
    event WithdrawalRequest(
        address indexed tokenContract,
        address indexed recipient,
        uint256 amount
    );
    event WithdrawalApproval(
        address indexed tokenContract,
        address indexed approver,
        address indexed recipient,
        uint256 amount
    );

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getOwnershipAdditions(address _account)
        public
        view
        returns (address[] memory)
    {
        return ownershipAdditions[_account];
    }

    function getOwnershipRemovals(address _account)
        public
        view
        returns (address[] memory)
    {
        return ownershipRemovals[_account];
    }

    function getWithdrawalApprovals(address _erc20, address _account)
        public
        view
        returns (uint256 amount, address[] memory approvals)
    {
        amount = withdrawalRequests[_erc20][_account];
        approvals = withdrawalApprovals[_erc20][_account];
    }

    function getMinimumApprovals() public view returns (uint256 approvalCount) {
        approvalCount = (owners.length + 1) / 2;
    }

    modifier isOwner(address _test) {
        require(_isOwner(_test) == true, "address must be an owner");
        _;
    }

    modifier isNotOwner(address _test) {
        require(_isOwner(_test) == false, "address must NOT be an owner");
        _;
    }

    modifier isNotMe(address _test) {
        require(msg.sender != _test, "test must not be sender");
        _;
    }

    constructor(
        address _owner2,
        address _owner3,
        address _owner4
    ) public {
        require(msg.sender != _owner2, "owner 1 and 2 can't be the same");
        require(msg.sender != _owner3, "owner 1 and 3 can't be the same");
        require(msg.sender != _owner4, "owner 1 and 3 can't be the same");
        require(_owner2 != _owner3, "owner 2 and 3 can't be the same");
        require(_owner2 != _owner4, "owner 2 and 4 can't be the same");
        require(_owner3 != _owner4, "owner 3 and 3 can't be the same");
        require(_owner2 != address(0), "owner 2 can't be the zero address");
        require(_owner3 != address(0), "owner 3 can't be the zero address");
        require(_owner4 != address(0), "owner 4 can't be the zero address");
        owners.push(msg.sender);
        owners.push(_owner2);
        owners.push(_owner3);
        owners.push(_owner4);
    }

    function _isOwner(address _test) internal view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (_test == owners[i]) {
                return true;
            }
        }
        return false;
    }

    // @dev Requests, or approves an ownership addition. The new owner is NOT automatically added.
    // @param _address - the address of the owner to add.
    function approveOwner(address _address)
        public
        isOwner(msg.sender)
        isNotOwner(_address)
        isNotMe(_address)
    {
        require(owners.length < 10, "no more than 10 owners");
        for (uint256 i = 0; i < ownershipAdditions[_address].length; i++) {
            require(
                ownershipAdditions[_address][i] != msg.sender,
                "sender has not already approved this removal"
            );
        }
        ownershipAdditions[_address].push(msg.sender);
        emit ApproveNewOwner(msg.sender, _address);
    }

    // @dev After being approved for ownership, the new owner must call this function to become an owner.
    function acceptOwnership() external isNotOwner(msg.sender) {
        require(
            ownershipAdditions[msg.sender].length >= getMinimumApprovals(),
            "sender doesn't have enough ownership approvals"
        );
        owners.push(msg.sender);
        delete ownershipAdditions[msg.sender];
        emit OwnershipChange(msg.sender, true, false);
    }

    // @dev Requests, or approves a ownership removal. Once enough approvals are given, the owner is
    //   automatically removed.
    // @param _address - the address of the owner to be removed.
    function removeOwner(address _address)
        public
        isOwner(msg.sender)
        isOwner(_address)
        isNotMe(_address)
    {
        require(
            owners.length > 3,
            "can't remove below 3 owners - add a new owner first"
        );
        uint256 i;
        for (i = 0; i < ownershipRemovals[_address].length; i++) {
            require(
                ownershipRemovals[_address][i] != msg.sender,
                "sender must not have already approved this removal"
            );
        }
        emit ApproveRemovalOfOwner(msg.sender, _address);
        ownershipRemovals[_address].push(msg.sender);
        // owners.length / 2 is the number of approvals required AFTER this account is removed.
        // This guarantees there are still enough active approvers left.
        if (ownershipRemovals[_address].length >= getMinimumApprovals()) {
            for (i = 0; i < owners.length; i++) {
                if (owners[i] == _address) {
                    uint256 lastSlot = owners.length - 1;
                    owners[i] = owners[lastSlot];
                    owners[lastSlot] = address(0);
                    owners.length = lastSlot;
                    break;
                }
            }
            delete ownershipRemovals[_address];
            emit OwnershipChange(_address, false, true);
        }
    }

    // @dev Cancels a ownership removal. Only requires one owner to call this,
    //   but the subject of the removal cannot call it themselves.
    // @param _address - the address of the owner to be removed.
    function vetoRemoval(address _address)
        public
        isOwner(msg.sender)
        isOwner(_address)
        isNotMe(_address)
    {
        delete ownershipRemovals[_address];
    }

    // @dev Cancels a ownership addition. Only requires one owner to call this.
    // @param _address - the address of the owner to be added.
    function vetoOwnership(address _address)
        public
        isOwner(msg.sender)
        isNotMe(_address)
    {
        delete ownershipAdditions[_address];
    }

    // @dev Cancels a withdrawal. Only requires one owner to call this.
    // @param _tokenContract - the contract of the erc20 token to withdraw (or, use the zero address for ETH)
    // @param _amount - the amount to withdraw. Amount must match the approved withdrawal amount.
    function vetoWithdrawal(address _tokenContract, address _requestor)
        public
        isOwner(msg.sender)
    {
        delete withdrawalRequests[_tokenContract][_requestor];
        delete withdrawalApprovals[_tokenContract][_requestor];
    }

    // @dev allows any owner to deposit any ERC20 token in this contract.
    // @dev Once the ERC20 token is deposited, it can only be withdrawn if enough accounts allow it.
    // @param _tokenContract - the contract of the erc20 token to deposit
    // @param _amount - the amount to deposit.
    // @notice For this function to work, you have to already have set an allowance for the transfer
    // @notice You CANNOT deposit Ether using this function. Use depositEth() instead.
    function depositERC20(address _tokenContract, uint256 _amount)
        public
        isOwner(msg.sender)
    {
        ERC20Interface erc20 = ERC20Interface(_tokenContract);
        emit Deposit(_tokenContract, msg.sender, _amount);
        erc20.transferFrom(msg.sender, address(this), _amount);
    }

    // @dev allows any owner to deposit Ether in this contract.
    // @dev Once ether is deposited, it can only be withdrawn if enough accounts allow it.
    function depositEth() public payable isOwner(msg.sender) {
        emit Deposit(address(0), msg.sender, msg.value);
    }

    // @dev Requests a withdrawal, changes a withdrawal request, or approves an existing withdrawal request.
    // To request or change, set _recipient to msg.sender. Changes wipe all approvals.
    // To approve, set _recipient to the previously requested account, and send from another owner account
    // @param _tokenContract - the contract of the erc20 token to withdraw (or, use the zero address for ETH)
    // @param _recipient - the account which will receive the withdrawal.
    // @param _amount - the amount to withdraw. Amount must match the approved withdrawal amount.
    function approveWithdrawal(
        address _tokenContract,
        address _recipient,
        uint256 _amount
    ) public isOwner(msg.sender) {
        ERC20Interface erc20 = ERC20Interface(_tokenContract);
        // If Withdrawer == msg.sender, this is a new request. Cancel all previous approvals.
        require(_amount > 0, "can't withdraw zero");
        if (_recipient == msg.sender) {
            if (_tokenContract == address(0)) {
                require(
                    _amount <= address(this).balance,
                    "can't withdraw more ETH than the balance"
                );
            } else {
                require(
                    _amount <= erc20.balanceOf(address(this)),
                    "can't withdraw more erc20 tokens than balance"
                );
            }
            delete withdrawalApprovals[_tokenContract][_recipient];
            withdrawalRequests[_tokenContract][_recipient] = _amount;
            withdrawalApprovals[_tokenContract][_recipient].push(msg.sender);
            emit WithdrawalRequest(_tokenContract, _recipient, _amount);
        } else {
            require(
                withdrawalApprovals[_tokenContract][_recipient].length >= 1,
                "you can't initiate a withdrawal request for another user"
            );
            require(
                withdrawalRequests[_tokenContract][_recipient] == _amount,
                "approval amount must exactly match withdrawal request"
            );
            for (
                uint256 i = 0;
                i < withdrawalApprovals[_tokenContract][_recipient].length;
                i++
            ) {
                require(
                    withdrawalApprovals[_tokenContract][_recipient][i] !=
                        msg.sender,
                    "sender has not already approved this withdrawal"
                );
            }
            withdrawalApprovals[_tokenContract][_recipient].push(msg.sender);
        }
        emit WithdrawalApproval(
            _tokenContract,
            msg.sender,
            _recipient,
            _amount
        );
    }

    // @dev Completes an approved withdrawal, transferring the erc20 tokens or Ether to the withdrawing account
    // @param _tokenContract - the contract of the erc20 token to withdraw (or, use the zero address for ETH)
    // @param _amount - the amount to withdraw. Amount must match the approved withdrawal amount.
    function completeWithdrawal(address _tokenContract, uint256 _amount)
        external
        isOwner(msg.sender)
    {
        require(
            withdrawalApprovals[_tokenContract][msg.sender].length >=
                getMinimumApprovals(),
            "insufficient approvals to complete this withdrawal"
        );
        require(
            withdrawalRequests[_tokenContract][msg.sender] == _amount,
            "incorrect withdrawal amount specified"
        );
        delete withdrawalRequests[_tokenContract][msg.sender];
        delete withdrawalApprovals[_tokenContract][msg.sender];
        emit Withdrawal(_tokenContract, msg.sender, _amount);
        if (_tokenContract == address(0)) {
            require(
                _amount <= address(this).balance,
                "can't withdraw more ETH than the balance"
            );
            msg.sender.transfer(_amount);
        } else {
            ERC20Interface erc20 = ERC20Interface(_tokenContract);
            require(
                _amount <= erc20.balanceOf(address(this)),
                "can't withdraw more erc20 tokens than balance"
            );
            erc20.transfer(msg.sender, _amount);
        }
    }
}
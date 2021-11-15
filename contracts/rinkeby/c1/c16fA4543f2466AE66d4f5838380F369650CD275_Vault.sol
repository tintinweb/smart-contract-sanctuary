pragma solidity ^0.7.0;
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract Vault {
    uint256 public unlockTime;
    uint256 public dailyWithdrawLimit;

    mapping(address => bool) public ownerMap;
    mapping(uint256 => address) public idToOwner;

    mapping(uint256 => WithdrawReq) public requests;
    mapping(address => mapping(uint256 => bool)) public approvals;
    mapping(uint256 => bool) requestCompleted;

    uint256 public requestCount;
    uint256 public ownerCount;

    event Confirmation(address owner, bytes32 operation);
    event NewRequest(
        uint256 requestId,
        address bep20,
        uint256 amount,
        address requester
    );
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

    struct WithdrawReq {
        uint256 requestId;
        address bep20;
        uint256 amount;
        address requester;
    }

    modifier isUnlocked {
        require(block.timestamp > unlockTime, "LCKD");
        _;
    }

    modifier isOwner {
        require(ownerMap[msg.sender], "NOWN");
        _;
    }

    modifier isApproved(uint256 _requestId) {
        require(requestCompleted[_requestId] != true, "CMPLTD");
        bool _approved = true;
        for (uint256 i = 0; i < ownerCount; i++) {
            if (
                approvals[idToOwner[i]][_requestId] != true &&
                idToOwner[i] != address(0)
            ) _approved = false;
        }
        require(_approved, "NAPPRVD");
        _;
    }

    constructor() {
        _addOwner(msg.sender);
        unlockTime = block.timestamp + 0 days;
    }

    function addOwner(address newOwner) external isOwner {
        _addOwner(newOwner);
    }

    function _addOwner(address newOwner) internal {
        ownerMap[newOwner] = true;
        idToOwner[ownerCount] = newOwner;
        ownerCount++;
        emit OwnerAdded(newOwner);
    }

    function _removeOwner(address ownerAddress) internal {
        emit OwnerRemoved(ownerAddress);
    }

    function getRequests(uint256[] calldata requestIds)
        external
        view
        returns (
            uint256[] memory requestIdArray,
            address[] memory bep20Array,
            uint256[] memory amountArray,
            address[] memory requesterArray
        )
    {
        requestIdArray = new uint256[](requestIds.length);
        bep20Array = new address[](requestIds.length);
        amountArray = new uint256[](requestIds.length);
        requesterArray = new address[](requestIds.length);

        for (uint256 i = 0; i < requestIds.length; i++) {
            requestIdArray[i] = requests[i].requestId;
            bep20Array[i] = requests[i].bep20;
            amountArray[i] = requests[i].amount;
            requesterArray[i] = requests[i].requester;
        }

        return (requestIdArray, bep20Array, amountArray, requesterArray);
    }

    function withdrawRequest(address bep20, uint256 amount)
        external
        isOwner
        isUnlocked
    {
        require(bep20 != address(0));
        WithdrawReq memory withdrawReq = WithdrawReq(
            requestCount,
            bep20,
            amount,
            msg.sender
        );
        emit NewRequest(requestCount, bep20, amount, msg.sender);
        requests[requestCount] = withdrawReq;
        approvals[msg.sender][requestCount] = true;
        requestCount++;
    }

    function processWithdraw(uint256 requestId)
        external
        isOwner
        isUnlocked
        isApproved(requestId)
    {
        requestCompleted[requestId] = true;
        WithdrawReq memory withdrawReq = requests[requestId];
        IBEP20 iart = IBEP20(withdrawReq.bep20);
        uint256 amount = withdrawReq.amount;
        require(iart.transfer(withdrawReq.requester, amount));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Ownable {
    /// @notice Storage position of the owner address
    /// @dev The address of the current owner is stored in a
    /// constant pseudorandom slot of the contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant OWNER_POSITION = keccak256("owner");

    /// @notice Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() {
        setOwner(msg.sender);
    }

    /// @notice Returns contract owner address
    /// @return owner Owner address
    function getOwner() public view returns (address owner) {
        bytes32 position = OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /// @notice Check that requires msg.sender to be the current owner
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
        _;
    }

    /// @notice Sets new owner address
    /// @param _newOwner New owner address
    function setOwner(address _newOwner) internal {
        bytes32 position = OWNER_POSITION;
        assembly {
            sstore(position, _newOwner)
        }
    }

    /// @notice Transfers the control of the contract to new owner
    /// @dev msg.sender must be the current owner
    /// @param _newOwner New owner address
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(_newOwner);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Not paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
    
    event Pause();
    event Unpause();
}

struct BetV1 {
    address addr;
    uint amount;
    bool paid;
    uint toPay;
    uint version;
}

abstract contract Bet_v1{

}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract Multisig {
    mapping (uint256 => address) private votersIds;
    mapping (address => bool) private voters;
    uint256 private _votersCounter;
    uint256 private _activeVoters;

    struct VoterRequest{
        bool status;
        address candidate;
        bool include;
    }
    mapping (uint256 => VoterRequest) private _voterRequests;
    mapping (uint256 => mapping(address=>bool)) private _voterRequsestsSignatures;
    uint256 private _voterRequestCounter;
    
    constructor() {
        _setVoter(msg.sender);
    }

    modifier onlyVoter {
        require(voters[msg.sender], "not voter");
        _;
    }

    function getVoterById(uint _id) internal view returns (address) {
        return votersIds[_id];
    }

    function getVoterStatusByAddress(address _address) internal view returns (bool) {
        return voters[_address];
    }

    function getActiveVoters() internal view returns (uint) {
        return _activeVoters;
    }

    function getVotersCounter() internal view returns (uint) {
        return _votersCounter;
    }


    // good news, new voter
    function _setVoter(address _newVoter) internal {
        require(_newVoter != address(0), "zero address");
        require(!voters[_newVoter], "already voter"); 
        voters[_newVoter] = true;
        _activeVoters++;
    }

    function _unsetVoter(address _oldVoter) internal {
        require(_oldVoter != address(0), "zero address");
        require(voters[_oldVoter], "not voter"); 
        voters[_oldVoter] = false;
        _activeVoters--;
    }
    

    function newVotersRequest(address[] memory _newVoters) external onlyVoter {
        for (uint i=0; i<_newVoters.length; i++) {
            require(!voters[_newVoters[i]], "already voter"); 
            // create request to be voter
            _voterRequests[_voterRequestCounter++] = VoterRequest({
                status: false,
                candidate: _newVoters[i],
                include: true
            });
            // sign
            _voterRequsestsSignatures[_voterRequestCounter][msg.sender] = true;
        }
        
    }
    
    function checkVotersRequest(uint256 _id) external {
        require(!_voterRequests[_id].status, "already approved");
        uint256 consensus = _activeVoters / 2 + 1;
        uint256 trueVotesCount;
        for (uint i=0; i<_votersCounter; i++) {
            // signed and he voter now
            if (_voterRequsestsSignatures[_id][votersIds[i]] && voters[votersIds[i]]) {
                trueVotesCount++;
            }
        }
        if (trueVotesCount > consensus) {
            if (_voterRequests[_id].include) {
                _setVoter(_voterRequests[_id].candidate);
            } else {
                _unsetVoter(_voterRequests[_id].candidate);
            }
            _voterRequests[_id].status = true;
        }
    }

}

contract DexSportMain is Pausable, Multisig {
    // multisig needs
    struct TransferRequest{
        address recepient;
        uint256 value;
        bool status;
    }

    mapping (uint256 => TransferRequest) private _transferRequests;
    mapping (uint256 => mapping(address=>bool)) private _transferRequestsSignatures;
    uint256 private _transferRequestCounter;
    
    // main logic
    mapping(uint => BetV1) private betsv1;
    uint private betsCount;

    IERC20 public usdt;

    uint256 public reserved;
    uint256 public maxAmount = 10000000000000000000;

    // set used usdt.
    function setUsdt(address usdtAddress) external onlyOwner{
        usdt = IERC20(usdtAddress);
    }

    // max amount
    function getMax() external view returns (uint256) {
        return maxAmount;
    }

    // getter for total reserved fuds
    function getReserved() external view returns (uint256) {
        return reserved;
    }

    // setter for max amount
    function setMax(uint256 newMax) external onlyOwner {
        maxAmount = newMax;
    }

    // getter for bet
    function getBetById(uint _id) external view whenNotPaused returns (BetV1 memory) {
        return betsv1[_id];
    }


    // server creates bets
    function newbet(
        address addr,
        uint256 amount,
        uint256 betId,
        uint256 reserve
    ) external whenNotPaused onlyOwner {
        require(amount <= maxAmount, "max exceeded");
        BetV1 storage b = betsv1[betId];
        b.addr = addr;
        b.amount = amount;
        b.paid = false;
        b.toPay = reserve;
        reserved = reserved + reserve;
        emit NewBet(betId);
    }

    // user withdrawals bets
    function withdrawal(uint256[] calldata betIds)
        external
        whenNotPaused
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsv1[betIds[i]];
            require(b.addr == msg.sender && !b.paid && b.toPay > 0, "wrong addr");
            b.paid = true;
            totalAmount = totalAmount + b.toPay;
            emit PrizeWithdrawn(betIds[i], b.toPay, b.addr);
        }
        reserved = reserved - totalAmount;
        require(usdt.transfer(msg.sender, totalAmount), "not transfered");
        emit Withdrawn(msg.sender, totalAmount);
    }

    // server set to_pay for ids
    function toPayAdmin(uint256[] calldata betIds, uint256[] calldata amounts)
        public
        onlyOwner
    {
        uint reserveTemp = reserved;
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsv1[betIds[i]];
            if (amounts[i] > 0) {
                b.toPay = amounts[i];
                emit BetWin(betIds[i], b.amount, b.addr);
            } else {
                b.paid = true;
                reserveTemp = reserveTemp - b.amount;
                emit BetLoose(betIds[i], b.amount, b.addr);
            }
        }
        reserved = reserveTemp;
    }

    // stake winner amount
    function stakeBets(uint256[] calldata betIds) public {
        uint reserveTemp = reserved;
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsv1[betIds[i]];
            require(!b.paid, "already paid");
            b.paid = true;
            reserveTemp = reserveTemp - b.amount;
            emit BetStaked(betIds[i], b.amount, b.addr);
        }
        reserved = reserveTemp;
    }

    // function withdrawal for admin
    function withdrawalAdminRequest(address recipient, uint256 amount)
        public
        onlyVoter returns (uint)
    {
        _transferRequests[_transferRequestCounter++] = TransferRequest({
            recepient: recipient,
            value: amount,
            status: false
        });
        // sign
        _transferRequestsSignatures[_transferRequestCounter][msg.sender] = true;
        return _transferRequestCounter;
    }

    function checkTransferRequest(uint256 _id) external {
        require(!_transferRequests[_id].status, "already approved");
        uint256 consensus = getActiveVoters() / 2 + 1;
        uint256 trueVotesCount;
        for (uint i=0; i<getVotersCounter(); i++) {
            // signed and he voter now
            if (_transferRequestsSignatures[_id][getVoterById(i)] && getVoterStatusByAddress(getVoterById(i))) {
                trueVotesCount++;
            }
        }
        if (trueVotesCount > consensus) {
            require(_transferRequests[_id].value <= usdt.balanceOf(address(this)) - reserved, "not enough reserve");
            require(usdt.transfer(_transferRequests[_id].recepient, _transferRequests[_id].value), "not transfered");
            emit WithdrawnAdmin(_transferRequests[_id].recepient, _transferRequests[_id].value);
            _transferRequests[_id].status = true;
        }
    }

    event NewBet(uint256 indexed id);
    event Deprecate(address newAddress);
    event WithdrawnAdmin(address indexed to, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event PrizeWithdrawn(uint256 indexed id, uint256 amount, address indexed user);
    event BetWin(uint256 indexed id, uint256 amount, address indexed user);
    event BetLoose(uint256 indexed id, uint256 amount, address indexed user);
    event BetStaked(uint256 indexed id, uint256 amount, address indexed user);
}
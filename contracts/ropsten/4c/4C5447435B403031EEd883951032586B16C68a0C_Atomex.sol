// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// From file: openzeppelin-contracts/contracts/math/SafeMath.sol
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add wrong value");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub wrong value");
        return a - b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
}

// From file: openzeppelin-contracts/contracts/utils/Address.sol
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solium-disable-next-line
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// From file: OpenZeppelin/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable {
    address private _owner;
    address private _successor;
    
    event OwnershipTransferred(address previousOwner, address newOwner);
    event NewOwnerProposed(address previousOwner, address newOwner);
    
    constructor() {
        setOwner(msg.sender);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function successor() public view returns (address) {
        return _successor;
    }
    
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }
    
    function setSuccessor(address newOwner) internal {
        _successor = newOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner(), "sender is not the owner");
        _;
    }
    
    modifier onlySuccessor() {
        require(msg.sender == successor(), "sender is not the proposed owner");
        _;
    }
    
    function proposeOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "invalid owner address");
        emit NewOwnerProposed(owner(), newOwner);
        setSuccessor(newOwner);
    }
    
    function acceptOwnership() public virtual onlySuccessor {
        emit OwnershipTransferred(owner(), successor());
        setOwner(successor());
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner(), address(0));
        setOwner(address(0));
    }
}

contract WatchTower is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    struct Watcher {
        uint256 deposit;
        bool active;
    }

    event NewWatcherProposed(address _newWatcher, uint256 _deposit);
    event NewWatcherActivated(address _newWatcher);
    event WatcherDeactivated(address _watcher);
    event WatcherWithdrawn(address _watcher);
    
    mapping(address => Watcher) public watchTowers;

    function proposeWatcher (address _newWatcher) public payable {
        require(_newWatcher != address(0), "invalid watcher address");
        require(msg.value > 0, "trasaction value must be greater then zero");
        
        emit NewWatcherProposed(_newWatcher, msg.value);
        
        watchTowers[_newWatcher].deposit = watchTowers[_newWatcher].deposit.add(msg.value);
    }
    
    function activateWatcher (address _newWatcher) public onlyOwner {
        require(watchTowers[_newWatcher].deposit > 0, "watcher does not exist");
        
        emit NewWatcherActivated(_newWatcher);
        
        watchTowers[_newWatcher].active = true;
    }
    
    function deactivateWatcher (address _watcher) public onlyOwner {
        require(watchTowers[_watcher].active == true, "watcher does not exist");
        
        emit WatcherDeactivated(_watcher);
        
        watchTowers[_watcher].active = false;
    }
    
    function withdrawWatcher () public nonReentrant {
        require(watchTowers[msg.sender].deposit > 0, "watcher does not exist");

        emit WatcherWithdrawn(msg.sender);
        
        payable(msg.sender).transfer(watchTowers[msg.sender].deposit);
        
        delete watchTowers[msg.sender];
    }
}

contract Atomex is WatchTower {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint releaseTimeout = 1 weeks;

    enum State { Empty, Initiated, Redeemed, Refunded, Lost }

    struct Swap {
        bytes32 hashedSecret;
        address contractAddr;
        address participant;
        address initiator;
        address watcher;
        uint256 refundTimestamp;
        uint256 watcherDeadline;
        uint256 value;
        uint256 payoff;
        State state;
    }

    event Initiated(
        bytes32 indexed _hashedSecret,
        address indexed _contract,
        address indexed _participant,
        address _initiator,
        address _watcher,
        uint256 _refundTimestamp,
        uint256 _watcherDeadline,
        uint256 _value,
        uint256 _payoff
    );

    event Redeemed(
        bytes32 indexed _hashedSecret,
        bytes32 _secret
    );

    event Refunded(
        bytes32 indexed _hashedSecret
    );
        
    event Released(
        bytes32 indexed _hashedSecret
    );

    mapping(bytes32 => Swap) public swaps;

    modifier onlyByInitiator(bytes32 _swapId) {
        require(msg.sender == swaps[_swapId].initiator, "sender is not the initiator");
        _;
    }

    modifier isInitiatable(address _participant, uint256 _refundTimestamp, address _watcher) {
        require(_participant != address(0), "invalid participant address");
        require(block.timestamp < _refundTimestamp, "refundTimestamp has already come");
        require(watchTowers[_watcher].active == true, "watcher does not exist");
        _;
    }
    
    modifier isInitiated(bytes32 _swapId) {
        require(swaps[_swapId].state == State.Initiated, "swap for this ID is empty or already spent");
        _;
    }

    modifier isRedeemable(bytes32 _swapId, bytes32 _secret) {
        require(block.timestamp < swaps[_swapId].refundTimestamp || msg.sender == swaps[_swapId].initiator, "refundTimestamp has already come");
        require(sha256(abi.encodePacked(sha256(abi.encodePacked(_secret)))) == swaps[_swapId].hashedSecret, "secret is not correct");
        _;
    }

    modifier isRefundable(bytes32 _swapId) {
        require(block.timestamp >= swaps[_swapId].refundTimestamp, "refundTimestamp has not come");
        _;
    }

    modifier isReleasable(bytes32 _swapId) {
        require(block.timestamp >= swaps[_swapId].refundTimestamp.add(releaseTimeout), "releaseTimeout has not passed");
        _;
    }
    
    function multikey(bytes32 _hashedSecret, address _initiator) public pure returns(bytes32) {
        return sha256(abi.encodePacked(_hashedSecret, _initiator));
    }
    

    function initiate (bytes32 _hashedSecret, address _contract, address _participant, address _watcher, 
        uint256 _refundTimestamp, bool _watcherForRedeem, uint256 _value, uint256 _payoff)
        public nonReentrant isInitiatable(_participant, _refundTimestamp, _watcher)
    {
        bytes32 swapId = multikey(_hashedSecret, msg.sender);
        
        require(swaps[swapId].state == State.Empty, "swap for this ID is already initiated");
        
        IERC20(_contract).safeTransferFrom(msg.sender, address(this), _value);

        swaps[swapId].value = _value.sub(_payoff);
        swaps[swapId].hashedSecret = _hashedSecret;
        swaps[swapId].contractAddr = _contract;
        swaps[swapId].participant = _participant;
        swaps[swapId].initiator = msg.sender;
        swaps[swapId].watcher = _watcher;
        swaps[swapId].refundTimestamp = _refundTimestamp;
        if(_watcherForRedeem)
            swaps[swapId].watcherDeadline = _refundTimestamp.sub(_refundTimestamp.sub(block.timestamp).div(3));
        else
            swaps[swapId].watcherDeadline = _refundTimestamp.add(_refundTimestamp.sub(block.timestamp).div(2));
        swaps[swapId].payoff = _payoff;
        swaps[swapId].state = State.Initiated;

        emit Initiated(
            _hashedSecret,
            _contract,
            _participant,
            msg.sender,
            _watcher,
            _refundTimestamp,
            swaps[swapId].watcherDeadline,
            _value.sub(_payoff),
            _payoff
        );
    }

    function withdraw(bytes32 _swapId, address _contract, address _receiver) internal 
    {
        if (msg.sender == swaps[_swapId].watcher
            || (block.timestamp >= swaps[_swapId].watcherDeadline && watchTowers[msg.sender].active == true)
            || (msg.sender == swaps[_swapId].initiator && _receiver == swaps[_swapId].participant)) {
            IERC20(_contract)
                .safeTransfer(_receiver, swaps[_swapId].value);
            if(swaps[_swapId].payoff > 0) {
                IERC20(_contract)
                    .safeTransfer(msg.sender, swaps[_swapId].payoff);
            }
        }
        else {
            IERC20(_contract)
                .safeTransfer(_receiver, swaps[_swapId].value.add(swaps[_swapId].payoff));
        }
        
        delete swaps[_swapId];
    }
    
    function redeem(bytes32 _swapId, bytes32 _secret)
        public nonReentrant isInitiated(_swapId) isRedeemable(_swapId, _secret)
    {
        swaps[_swapId].state = State.Redeemed;
        
        emit Redeemed(
            swaps[_swapId].hashedSecret,
            _secret
        );

        withdraw(_swapId, swaps[_swapId].contractAddr, swaps[_swapId].participant);
    }

    function refund(bytes32 _swapId)
        public nonReentrant isInitiated(_swapId) isRefundable(_swapId)
    {
        swaps[_swapId].state = State.Refunded;

        emit Refunded(
            swaps[_swapId].hashedSecret
        );

        withdraw(_swapId, swaps[_swapId].contractAddr, swaps[_swapId].initiator);

    }
    
    function release(bytes32 _swapId)
        public onlyOwner() isReleasable(_swapId)
    {
        swaps[_swapId].state = State.Lost;

        emit Released(
            swaps[_swapId].hashedSecret
        );
        
        withdraw(_swapId, swaps[_swapId].contractAddr, owner());
    }
}


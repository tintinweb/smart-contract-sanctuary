/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Contribut is Ownable {
    struct EventData {
        string eventName;
        address depositToken;
        uint256 depositTotal;
        uint256 hardCap;
        uint256 maxContribut;
        uint256 minContribut;
        uint256 FCFSTimer;
        address[] users;
        address owner;
        bool active;
    }
    mapping(uint256 => EventData) public eventList;
    uint256 public eventNonce;
    
    struct ContributionData {
        uint256 eventId;
        string eventName;
        uint256 depositAmount;
    }
    mapping(address => mapping(uint256 => uint256)) public userList;

    struct UserData {
        address user;
        uint256 depositAmount;
    }

    event Published(uint256 eventId, string eventName, address depositToken, uint256 hardCap, uint256 maxContribut, uint256 minContribut, uint256 FCFSTimer, address owner, bool active);
    event Close(uint256 eventId, address depositToken, uint256 depositTotal);
    event Contribution(uint256 eventId, address user, uint256 depositAmount);
    event Vested(uint256 eventId, address user, address tokenAddress, uint256 amount);

    receive() external payable {}

    function RecoverERC20(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransfer(_tokenAddress, owner(), balance);
    }

    function RecoverETH() public onlyOwner() {
        address owner = owner();
        payable(owner).transfer(address(this).balance);
    }

    function SetEvent(string calldata _eventName, address _depositToken, uint256 _hardCap, uint256 _maxContribut, uint256 _minContribut, uint256 _FCFSTimer) external onlyOwner {
        require(_hardCap >= _maxContribut, "Invalid hardCap");
        require(_maxContribut >= _minContribut, "Invalid minContribut");
        require(_depositToken != address(0), "Invalid depositToken");
        address[] memory users;
        eventList[eventNonce] = EventData({
            eventName : _eventName,
            depositToken : _depositToken,
            depositTotal : 0,
            hardCap : _hardCap,
            maxContribut : _maxContribut,
            minContribut : _minContribut,
            FCFSTimer : _FCFSTimer,
            users : users,
            owner : msg.sender,
            active : true
        });
        emit Published(eventNonce, _eventName, _depositToken, _hardCap, _maxContribut, _minContribut, _FCFSTimer, msg.sender, true);
        eventNonce++;
    }

    function CloseEvent(uint256 _eventId) external onlyOwner {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        require(eventList[_eventId].hardCap == eventList[_eventId].depositTotal, "Not reached hardCap");
        
        TransferHelper.safeTransfer(eventList[_eventId].depositToken, msg.sender, eventList[_eventId].depositTotal);
        eventList[_eventId].active = false;
        emit Close(_eventId, eventList[_eventId].depositToken, eventList[_eventId].depositTotal);
    }

    function SetVested(uint256 _eventId, address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active == false, "Event is active");
        
        uint256 preBalance = IERC20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _amount);
        UserData[] memory data = GetEventData(_eventId);

        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this)) - preBalance;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 vestedBalance = balance * 1e18 * data[i].depositAmount / eventList[_eventId].depositTotal / 1e18;
            if (vestedBalance > 0) {
                TransferHelper.safeTransfer(_tokenAddress, data[i].user, vestedBalance);
                emit Vested(_eventId, data[i].user, _tokenAddress, vestedBalance);
            }
        }
        balance = IERC20(_tokenAddress).balanceOf(address(this));
        if (balance > preBalance) {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, balance - preBalance);
        }
    }

    function Deposit(uint256 _eventId, uint256 _depositAmount) external {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        require(eventList[_eventId].hardCap > eventList[_eventId].depositTotal, "It is beyond hardCap");
        require(eventList[_eventId].FCFSTimer < block.timestamp || eventList[_eventId].maxContribut >= userList[msg.sender][_eventId] + _depositAmount, "Deposit is high");
        require(eventList[_eventId].minContribut <= _depositAmount, "Deposit is low");
        require(eventList[_eventId].FCFSTimer < block.timestamp || userList[msg.sender][_eventId] == 0, "Please wait for FCFS");

        if (eventList[_eventId].hardCap < eventList[_eventId].depositTotal + _depositAmount) {
            _depositAmount = eventList[_eventId].hardCap - eventList[_eventId].depositTotal;
        }
        userList[msg.sender][_eventId] += _depositAmount;
        eventList[_eventId].depositTotal += _depositAmount;
        TransferHelper.safeTransferFrom(eventList[_eventId].depositToken, msg.sender, address(this), _depositAmount);

        if (CheckEventListUsers(msg.sender, _eventId) == false) {
            eventList[_eventId].users.push(msg.sender);
        }
        emit Contribution(_eventId, msg.sender, userList[msg.sender][_eventId]);
    }

    function Refund(uint256 _eventId, uint256 _refundAmount) external {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active, "Event is not active");
        require(userList[msg.sender][_eventId] >= _refundAmount, "Contributions are insufficient");

        userList[msg.sender][_eventId] -= _refundAmount;
        eventList[_eventId].depositTotal -= _refundAmount;
        TransferHelper.safeTransfer(eventList[_eventId].depositToken, msg.sender, _refundAmount);
        emit Contribution(_eventId, msg.sender, userList[msg.sender][_eventId]);
    }

    function TransferContribut(uint256 _eventId, address _to, uint256 _transferContribut) external {
        require(_eventId < eventNonce, "Invalid EventId");
        require(eventList[_eventId].active == false, "Event is active");
        require(userList[msg.sender][_eventId] >= _transferContribut, "Contributions are insufficient");

        userList[msg.sender][_eventId] -= _transferContribut;
        userList[_to][_eventId] += _transferContribut;
        if (CheckEventListUsers(_to, _eventId) == false) {
            eventList[_eventId].users.push(_to);
        }
        emit Contribution(_eventId, msg.sender, userList[msg.sender][_eventId]);
        emit Contribution(_eventId, _to, userList[_to][_eventId]);
    }

    function CheckEventListUsers(address _user, uint256 _eventId) public view returns (bool _flag) {
        for (uint256 i = 0; i < eventList[_eventId].users.length; i++) {
            if (eventList[_eventId].users[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function GetUserData(address _user, uint256 _eventId) public view returns (uint256 _depositAmount) {
        return userList[_user][_eventId];
    }

    function GetUserAllData(address _user) public view returns (ContributionData[] memory _userAllData) {
        uint256 activeCount = GetUserActiveEventCount(_user);
        uint256 setCount = 0;
        ContributionData[] memory userAllData = new ContributionData[](activeCount);
        for (uint256 i = 0; i < eventNonce; i++) {
            if (userList[_user][i] > 0) {
                userAllData[setCount] = ContributionData({
                    eventId : i,
                    eventName : eventList[i].eventName,
                    depositAmount : userList[_user][i]
                });
                setCount++;
            }
        }
        return userAllData;
    }

    function GetUserActiveEventCount(address _user) public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < eventNonce; i++) {
            if (userList[_user][i] > 0) {
                activeCount++;
            }
        }
        return activeCount;
    }

    function GetEventData(uint256 _eventId) public view returns (UserData[] memory _userData) {
        address[] memory users = eventList[_eventId].users;
        UserData[] memory data = new UserData[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            data[i].user = users[i];
            data[i].depositAmount = GetUserData(users[i], _eventId);
        }
        return data;
    }

}
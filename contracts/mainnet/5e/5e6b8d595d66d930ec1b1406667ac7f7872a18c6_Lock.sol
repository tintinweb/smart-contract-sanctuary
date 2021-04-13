/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.8.0;

contract Lock {

    address public immutable token;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockStart;
    mapping(address => uint256) public lockEnd;

    constructor(address _token) {
        require(_token != address(0), "token address is zero");
        token = _token;
    }

    function totalLocked() public view returns (uint256) {
        (bool _success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
        (uint amount) = abi.decode(data, (uint));
        return amount;
    }

    // transfer ERC from msg.sender to contract with locked:
    function lock(address _lockTo, uint256 _amount, uint32 _startAfterDays, uint32 _lockDays) public returns (bool) {
        require(_lockTo != address(0), "address is zero");
        require(_amount > 0, "amount <= 0");
        require(_startAfterDays >= 0 && _startAfterDays <= 365, "start lock days < 0 or > 1y");
        require(_lockDays >= 1 && _lockDays <= 3650, "lock days < 1d or > 10y");

        require(lockStart[_lockTo] == 0, "cannot re-lock");
        require(lockEnd[_lockTo] == 0, "cannot re-lock");
        require(balances[_lockTo] == 0, "cannot re-lock");

        uint256 start = block.timestamp + 3600 * 24 * _startAfterDays;
        uint256 end = start + 3600 * 24 * _lockDays;
        lockStart[_lockTo] = start;
        lockEnd[_lockTo] = end;
        balances[_lockTo] = _amount;
        safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    function unlockable(address _address) public view returns (uint256) {
        uint256 total = balances[_address];
        if (total == 0) {
            return 0;
        }
        uint256 start = lockStart[_address];
        if (block.timestamp <= start) {
            return 0;
        }
        uint256 end = lockEnd[_address];
        if (block.timestamp < end) {
            return total * (block.timestamp - start) / (end - start);
        } else {
            return total;
        }
    }

    // transfer locked ERC to msg.sender if unlock ok:
    function unlock() public returns (bool) {
        uint256 start = lockStart[msg.sender];
        require(start > 0, "lock not found");
        require(start < block.timestamp, "still in lock");

        uint256 total = balances[msg.sender];
        uint256 canWithdraw = unlockable(msg.sender);
        if (canWithdraw == 0) {
            return false;
        }
        safeTransfer(msg.sender, canWithdraw);
        balances[msg.sender] = total - canWithdraw;

        if (total == canWithdraw) {
            lockStart[msg.sender] = 0;
            lockEnd[msg.sender] = 0;
        } else {
            lockStart[msg.sender] = block.timestamp;
        }
        return true;
    }

    function safeTransfer(
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }
}
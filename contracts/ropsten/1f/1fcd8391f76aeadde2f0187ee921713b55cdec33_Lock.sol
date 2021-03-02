/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.8.0;

contract Lock {

    address public token;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public locktime;

    constructor(address _token) {
        require(_token != address(0), "token address is zero");
        token = _token;
    }

    // transfer ERC from msg.sender to contract with locked days:
    function lock(address _lockTo, uint256 _amount, uint32 _days) public returns (bool) {
        require(_lockTo != address(0), "address is zero");
        require(_amount > 0, "amount <= 0");
        require(_days >= 1 && _days <= 3650, "lock day < 1d or > 10y");

        require(locktime[_lockTo] == 0, "cannot re-lock");
        require(balances[_lockTo] == 0, "cannot re-lock");

        locktime[_lockTo] = block.timestamp + 3600 * 24 * _days;
        balances[_lockTo] = _amount;
        safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    // transfer locked ERC to msg.sender if unlock ok:
    function unlock() public returns (bool) {
        require(locktime[msg.sender] > 0, "lock not found");
        require(locktime[msg.sender] < block.timestamp, "still in lock");

        safeTransfer(msg.sender, balances[msg.sender]);

        locktime[msg.sender] = 0;
        balances[msg.sender] = 0;
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
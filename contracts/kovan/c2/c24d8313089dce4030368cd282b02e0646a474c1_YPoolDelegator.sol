/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;


contract YPoolDelegator {
    address[] public _coins;
    address[] public _underlying_coins;
    uint256[] public _balances;
    uint256 public A;
    uint256 public fee;
    uint256 public admin_fee;
    uint256 constant max_admin_fee = 5 * 10 ** 9;
    address public owner;
    address token;
    uint256 public admin_actions_deadline;
    uint256 public transfer_ownership_deadline;
    uint256 public future_A;
    uint256 public future_fee;
    uint256 public future_admin_fee;
    address public future_owner;
    
    uint256 kill_deadline;
    uint256 constant kill_deadline_dt = 2 * 30 * 86400;
    bool is_killed;
    
    constructor() public {
        A = 20;
        fee = 0;
        admin_fee = 0;
        kill_deadline = block.timestamp + kill_deadline_dt;
        is_killed = false;
    }
    
    function setA(uint _A) public {
        A = _A;
    }
    
    function setBalances(uint x, uint y) public {
        _balances[0] = x;
        _balances[1] = y;
    }
    
    function balances(int128 i) public view returns (uint256) {
        return _balances[uint256(i)];
    }
    
    function coins(int128 i) public view returns (address) {
        return _coins[uint256(i)];
    }
    
    function underlying_coins(int128 i) public view returns (address) {
        return _underlying_coins[uint256(i)];
    }

    fallback() external payable {
        address _target = 0x51e7D6Ee188B029e68BA673acc79b11824ce0Ec6;

        assembly {
            let _calldataMemOffset := mload(0x40)
            let _callDataSZ := calldatasize()
            let _size := and(add(_callDataSZ, 0x1f), not(0x1f))
            mstore(0x40, add(_calldataMemOffset, _size))
            calldatacopy(_calldataMemOffset, 0x0, _callDataSZ)
            let _retval := delegatecall(gas(), _target, _calldataMemOffset, _callDataSZ, 0, 0)
            switch _retval
            case 0 {
                revert(0,0)
            } default {
                let _returndataMemoryOff := mload(0x40)
                mstore(0x40, add(_returndataMemoryOff, returndatasize()))
                returndatacopy(_returndataMemoryOff, 0x0, returndatasize())
                return(_returndataMemoryOff, returndatasize())
            }
        }
    }
}
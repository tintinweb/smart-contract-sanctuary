pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;


abstract contract YToken {
    function getPricePerFullShare() external view virtual returns (uint256);
}

contract ZapDelegator {
    address[] public _coins;
    address[] public _underlying_coins;
    address public curve;
    address public token;
    
    constructor(address[4] memory _coinsIn, address[4] memory _underlying_coinsIn, address _curve, address _pool_token) public {
        for (uint i = 0; i < 4; i++) {
            require(_underlying_coinsIn[i] != address(0));
            require(_coinsIn[i] != address(0));
            _coins.push(_coinsIn[i]);
            _underlying_coins.push(_underlying_coinsIn[i]);
        }
        curve = _curve;
        token = _pool_token;
    }
    
    function coins(int128 i) public view returns (address) {
        return _coins[uint256(i)];
    }
    
    function underlying_coins(int128 i) public view returns (address) {
        return _underlying_coins[uint256(i)];
    }

    fallback() external payable {
        address _target = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

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
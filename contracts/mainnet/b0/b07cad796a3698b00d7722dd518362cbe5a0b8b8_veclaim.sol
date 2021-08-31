/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ve {
    function deposit_for(address addr, uint value) external;
    
    struct Point {
        int128 bias;
        int128 slope;
        uint ts;
        uint blk;
    }
    
    function balanceOf(address, uint) external view returns (uint);
    function totalSupply() external view returns (uint);
    function user_point_epoch(address) external view returns (uint);
    function user_point_history(address, uint) external view returns (Point memory);
}

interface erc20 {
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
}

contract veclaim {
    ve constant _veibff = ve(0x4D0518C9136025903751209dDDdf6C67067357b1);
    ve constant _vekp3r = ve(0x2FC52C61fB0C03489649311989CE2689D93dC1a2);
    address constant _kp3r = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
    uint constant _exchange_rate = 13;
    uint immutable public t;
    uint immutable public totalSupply;
    address immutable owner;
    uint public claimed;
    uint public required;

    mapping(address => bool) public has_claimed;

    event Claim(address indexed claimant, uint amount);

    constructor() {
        t = block.timestamp;
        owner = msg.sender;
        uint _totalSupply = _veibff.totalSupply();
        totalSupply = _totalSupply;
        required = _totalSupply * _exchange_rate;
        _safeApprove(_kp3r, address(_vekp3r), type(uint).max);
    }
    
    function deficit() external view returns (uint) {
        return required - claimed;
    }
    
    function clawback() external {
        require(msg.sender == owner);
        _safeTransfer(_kp3r, owner, erc20(_kp3r).balanceOf(address(this)));
    }
    
    function ve_balance_at(address account, uint timestamp) public view returns (uint) {
        uint _epoch = ve(_veibff).user_point_epoch(account);
        uint _balance_at = 0;
        for (uint i = _epoch; i > 0; i--) {
            ve.Point memory _point = ve(_veibff).user_point_history(account, i);
            if (_point.ts <= timestamp) {
                int128 _bias = _point.bias - (_point.slope * int128(int(timestamp - _point.ts)));
                if (_bias > 0) {
                    _balance_at = uint(int(_bias));
                }
                break;
            }
        }
        return _balance_at;
    }
    
    function claimable(address claimant) external view returns (uint) {
        if (has_claimed[claimant]) {
            return 0;
        }

        uint _amount = ve_balance_at(claimant, t);
        return _amount * _exchange_rate;
    }

    function claim(address claimant) external returns (bool) {
        return _claim(claimant);
    }

    function claim() external returns (bool) {
        return _claim(msg.sender);
    }

    function _claim(address claimant) internal returns (bool) {
        require(!has_claimed[claimant]);
        has_claimed[claimant] = true;

        uint _amount = ve_balance_at(claimant, t) * _exchange_rate;
        claimed += _amount;
        _vekp3r.deposit_for(claimant, _amount);
        emit Claim(claimant, _amount);
        return true;
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
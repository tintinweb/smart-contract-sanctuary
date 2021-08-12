/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Math {
    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }
}

interface ve {
    struct Point {
        int128 bias;
        int128 slope;
        uint ts;
        uint blk;
    }
    
    function user_point_epoch(address) external view returns (uint);
    function user_point_history(address, uint) external view returns (Point memory);
}

interface fee {
    function last_token_time() external view returns (uint);
    function start_time() external view returns (uint);
    function time_cursor_of(address) external view returns (uint);
    function user_epoch_of(address) external view returns (uint);
    function tokens_per_week(uint) external view returns (uint);
    function ve_supply(uint) external view returns (uint);
}

contract FeeDistributionLookup {
    address constant _fee = 0x27761EfEb0C7b411e71d0fd0AeE5DDe35c810CC2;
    address constant _veibff = 0x4D0518C9136025903751209dDDdf6C67067357b1;
    uint constant WEEK = 7 * 86400;
    
    function claimable(address addr) external view returns (uint _to_distribute) {
        uint _last_token_time = fee(_fee).last_token_time() / WEEK * WEEK;
        uint _user_epoch = 0;
        uint _max_user_epoch = ve(_veibff).user_point_epoch(addr);
        uint _start_time = fee(_fee).start_time();
        if (_max_user_epoch == 0) {
            return 0;
        }
        uint _week_cursor = fee(_fee).time_cursor_of(addr);
        if (_week_cursor == 0) {
            _user_epoch = _find_timestamp_user_epoch(addr, _start_time, _max_user_epoch);
        } else {
            _user_epoch = fee(_fee).user_epoch_of(addr);
        }
        
        if (_user_epoch == 0) {
            _user_epoch = 1;
        }
        
        ve.Point memory _user_point = ve(_veibff).user_point_history(addr, _user_epoch);
        if (_week_cursor == 0) {
            _week_cursor = (_user_point.ts + WEEK - 1) / WEEK * WEEK;
        }
        
        if (_week_cursor >= _last_token_time) {
            return 0;
        }
        if (_week_cursor < _start_time) {
            _week_cursor = _start_time;
        }
        ve.Point memory _old_user_point;
        
        for (uint i = 0; i < 50; i++) {
            if (_week_cursor >= _last_token_time) {
                break;
            }
            if (_week_cursor >= _user_point.ts && _user_epoch <= _max_user_epoch) {
                _user_epoch += 1;
                _old_user_point = _user_point;
                if (_user_epoch <= _max_user_epoch) {
                    _user_point = ve(_veibff).user_point_history(addr, _user_epoch);
                }
            } else {
                int _dt = int(_week_cursor) - int(_old_user_point.ts);
                uint _balance_of = Math.max(uint(_old_user_point.bias - _dt * _old_user_point.slope), 0);
                if (_balance_of == 0 && _user_epoch > _max_user_epoch) {
                    break;
                }
                if (_balance_of > 0) {
                    _to_distribute += _balance_of * fee(_fee).tokens_per_week(_week_cursor) / fee(_fee).ve_supply(_week_cursor);
                }
                _week_cursor += WEEK;
            }
        }
    }
    
    function _find_timestamp_user_epoch(address user, uint _timestamp, uint _max_user_epoch) internal view returns (uint) {
        uint _min = 0;
        uint _max = _max_user_epoch;
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 2) / 2;
            ve.Point memory _pt = ve(_veibff).user_point_history(user, _mid);
            if (_pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }
}
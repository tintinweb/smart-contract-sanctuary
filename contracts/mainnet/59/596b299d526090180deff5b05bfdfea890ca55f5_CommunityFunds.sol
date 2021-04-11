// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";



contract CommunityFunds is Context{
    using SafeMath for uint256;
    
    address public _admin;
    uint256 public _allowed;
    uint256 public _balance;
    uint256 public _startTime;
    uint256 public _withdrawn;
    address public _token;
    
    constructor(address _tokenAddress) public{
        _token=_tokenAddress;
        _admin=_msgSender();
        _allowed=10e23;
        _balance=10e24;
        _startTime=now;
    }
    
    function claim() public virtual returns(bool){
        if (now.sub(_startTime)>30 days){
            _allowed=19e23;
        }
        if (now.sub(_startTime)>60 days){
            _allowed=28e23;
        }
        if (now.sub(_startTime)>90 days){
            _allowed=37e23;
        }
        if (now.sub(_startTime)>120 days){
            _allowed=46e23;
        }
        if (now.sub(_startTime)>150 days){
            _allowed=55e23;
        }
        if (now.sub(_startTime)>180 days){
            _allowed=64e23;
        }
        if (now.sub(_startTime)>210 days){
            _allowed=73e23;
        }
        if (now.sub(_startTime)>240 days){
            _allowed=82e23;
        }
        if (now.sub(_startTime)>270 days){
            _allowed=91e23;
        }
        if (now.sub(_startTime)>300 days){
            _allowed=10e24;
        }
        uint256 _toWithdraw=_allowed.sub(_withdrawn);
        require(_toWithdraw>0,"No new Tokens unlocked.");
        IERC20(_token).transfer(_admin,_toWithdraw);
        _withdrawn=_withdrawn.add(_toWithdraw);
        return true;
    }

}
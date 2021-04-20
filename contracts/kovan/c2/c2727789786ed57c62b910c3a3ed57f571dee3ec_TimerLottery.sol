/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity 0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract TimerLottery is Context {

 
    address private _winner;
    uint256 private _lastTimestamp;
    uint256 private _timeDifference;
    uint256 private _minAmount;
    uint256 private _weiRaised;

   

    constructor(uint256 time, uint256 minAmount) {
        
        _timeDifference = time * 60;
        _winner = _msgSender();
        _minAmount = minAmount;
    }


    function timeDifference() public view returns (uint256) {
        return _timeDifference;
    }
    
    function currentWinner() public view returns (address) {
        return _winner;
    }
    
    function lotetryAmount() public view returns (uint256) {
        return _weiRaised;
    }
    
    function minAmount() public view returns (uint256) {
        return _minAmount;
    }
    
    function timeLeftToWinLottery() public view returns (uint256) {

        if ((_lastTimestamp + _timeDifference) <  block.timestamp) {
            
            return 0;
        } else {
        
        return (_lastTimestamp + _timeDifference - block.timestamp );
        }
    }

    fallback () external payable{
        participate();
    }
  
    function participate() public payable  {
        if (msg.value < _minAmount) {
            _weiRaised += msg.value;
           
        } else {
        
        
        if ((block.timestamp - _lastTimestamp) > _timeDifference) {
            address payable walletPayable = payable(_winner);
            walletPayable.transfer(_weiRaised);
            _weiRaised = 0;
        }
        
        _weiRaised += msg.value;
        _winner = _msgSender();
        _lastTimestamp = block.timestamp;
     
    }
    }
    
}
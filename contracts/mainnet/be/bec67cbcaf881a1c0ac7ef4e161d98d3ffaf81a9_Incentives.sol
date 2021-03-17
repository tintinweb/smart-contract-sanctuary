/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// iWSCRT Interface
interface iWSCRT {
    function transfer(address, uint) external returns (bool);
    function transferTo(address, uint) external returns (bool);
}

// Sushiswap Interface
interface iPair {
    function sync() external;
}

contract Incentives {
    address public WSCRT = 0x2B89bF8ba858cd2FCee1faDa378D5cd6936968Be;
    event Deposited(address indexed pair, uint amount);

    constructor() {}

    // #### DEPOSIT ####

    // Deposit and sync
    function depositIncentives(address pair, uint amount) public {
        _getWscrt(amount);
        _depositAndSync(pair, amount);
    }
    // Deposit and sync batches
    function depositBatchIncentives(address[] memory pairs, uint[] memory amounts) public {
        uint _amountToGet = 0;
        for(uint i = 0; i < pairs.length; i++){
            _amountToGet += amounts[i];
        }
        _getWscrt(_amountToGet);
        for(uint i = 0; i < pairs.length; i++){
            _depositAndSync(pairs[i], amounts[i]);
        }
    }

    // #### HELPERS ####

    function _toGrains(uint _amount) internal pure returns(uint){
        return _amount * 10**6;
    }

    function _getWscrt(uint _amount) internal {
        iWSCRT(WSCRT).transferTo(address(this), _toGrains(_amount));
    }

    function _depositAndSync(address _pair, uint _amount) internal {
        iWSCRT(WSCRT).transfer(_pair, _toGrains(_amount));
        iPair(_pair).sync();
        emit Deposited(_pair, _amount);
    }

}
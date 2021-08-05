/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// iRUNE Interface
interface iRUNE {
    function transfer(address, uint) external returns (bool);
    function transferTo(address, uint) external returns (bool);
}

// Sushiswap Interface
interface iPair {
    function sync() external;
}

contract Incentives {
    address public RUNE = 0x3155BA85D5F96b2d030a4966AF206230e46849cb;
    event Deposited(address indexed pair, uint amount);

    constructor() {}

    // #### DEPOSIT ####

    // Deposit and sync
    function depositIncentives(address pair, uint amount) public {
        _getRune(amount);
        _depositAndSync(pair, amount);
    }
    // Deposit and sync batches
    function depositBatchIncentives(address[] memory pairs, uint[] memory amounts) public {
        uint _amountToGet = 0;
        for(uint i = 0; i < pairs.length; i++){
            _amountToGet += amounts[i];
        }
        _getRune(_amountToGet);
        for(uint i = 0; i < pairs.length; i++){
            _depositAndSync(pairs[i], amounts[i]);
        }
    }

    // #### HELPERS ####

    function _toWei(uint _amount) internal pure returns(uint){
        return _amount * 10**18;
    }

    function _getRune(uint _amount) internal {
        iRUNE(RUNE).transferTo(address(this), _toWei(_amount));
    }

    function _depositAndSync(address _pair, uint _amount) internal {
        iRUNE(RUNE).transfer(_pair, _toWei(_amount));
        iPair(_pair).sync();
        emit Deposited(_pair, _amount);
    }

}
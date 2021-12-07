/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

pragma solidity^0.8.6;

interface IHousePool{
    function Transfer(uint _amount)external;
    function CalculateAccumulatePerShare(uint _amount)external;
    function minBet() external view returns(uint256);
    function maxBet()external view returns(uint256);
    function maxProfit() external view returns(uint256);
}

contract Crash{
    address public StakingContract;
    constructor(address _housepool)public{
        StakingContract = _housepool;
    }
    function getFunds(uint _amount)public {
        IHousePool(StakingContract).Transfer(_amount);
    }
}
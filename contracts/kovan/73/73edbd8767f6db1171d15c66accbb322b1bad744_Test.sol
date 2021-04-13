pragma solidity 0.6.12;
import "./SafeMath.sol";

contract Test {
    using SafeMath for uint256;

    uint256 public totalJackpot;

    constructor() public {
        totalJackpot = 1;
    }

    function getGlobalInfo() public view returns (uint256 jackpot) 
    {
        jackpot = totalJackpot;
    }

    function buyTicket() public returns (uint256) {
        totalJackpot = totalJackpot.add(1);
        return totalJackpot;
    }
}
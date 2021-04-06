/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity >=0.4.25 <0.6.0;

contract FrequentFlyerRewardsCalculator
{
     //Set of States
    enum StateType {SetFlyerAndReward, MilesAdded}

    //List of properties
    StateType public  State;
    
    address public  AirlineRepresentative;
    address public  Flyer;
    
    uint public RewardsPerMile;
    uint[] public Miles;
    uint IndexCalculatedUpto;
    uint public TotalRewards;

    // constructor function
    constructor(address flyer, int rewardsPerMile) public
    {
        AirlineRepresentative = msg.sender;
        Flyer = flyer;
        RewardsPerMile = uint(rewardsPerMile);
        IndexCalculatedUpto = 0;
        TotalRewards = 0;
        State = StateType.SetFlyerAndReward;
    }

    // call this function to add miles
    function AddMiles(int[] memory miles) public
    {
        if (Flyer != msg.sender)
        {
            revert();
        }

        for (uint i = 0; i < miles.length; i++)
        {
            Miles.push(uint(miles[i]));
        }

        ComputeTotalRewards();

        State = StateType.MilesAdded;
    }

    function ComputeTotalRewards() private
    {
        // make length uint compatible
        uint milesLength = uint(Miles.length);
        for (uint i = IndexCalculatedUpto; i < milesLength; i++)
        {
            TotalRewards += (RewardsPerMile * Miles[i]);
            IndexCalculatedUpto++;
        }
    }

    function GetMiles() public view returns (uint[] memory) {
        return Miles;
    }
}
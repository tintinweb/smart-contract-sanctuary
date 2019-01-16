pragma solidity ^0.4.25;

contract aesg
{   
    function GetSeries() public pure returns  (uint[] memory series, uint[] memory solidity18, uint[] memory solidity19, uint[] memory solidity20)
    {
        series = new uint[](3);
        series[0] = 1;// .push(1);
        series[1] = 2;// .push(2);
        series[2] = 3;//.push(3);
        
        solidity18  = new uint[](3);
        solidity18[0] = 11;// .push(10);
        solidity18[1] = 12;//.push(11);
        solidity18[2] = 13;//.push(12);
        
        solidity19  = new uint[](3);
        solidity19[0] = 11;// .push(10);
        solidity19[1] = 12;//.push(11);
        solidity19[2] = 13;//.push(12);
        
        solidity20  = new uint[](3);
        solidity20[0] = 11;// .push(10);
        solidity20[1] = 12;//.push(11);
        solidity20[2] = 13;//.push(12);
    }
    
    
    
    function GetSeries1() public pure returns  (uint32[] memory series)
    {
        series = new uint32[](3);
        series[0] = 1;// .push(1);
        series[1] = 2;// .push(2);
        series[2] = 3;//.push(3);
    }
    
    
    
    function GetSeries2() public pure returns  (uint32[] memory series, uint32[] memory solidity18)
    {
        series = new uint32[](3);
        series[0] = 1;// .push(1);
        series[1] = 2;// .push(2);
        series[2] = 3;//.push(3);
        
        solidity18  = new uint32[](3);
        solidity18[0] = 11;// .push(10);
        solidity18[1] = 12;//.push(11);
        solidity18[2] = 13;//.push(12);
    }
    
    
}
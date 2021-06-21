pragma solidity ^0.4.24;
import "./SafeMath.sol";
contract class31{
    using SafeMath for uint;
    function use_add(uint a,uint b) public pure returns(uint){
        return a.add(b);
    }
}
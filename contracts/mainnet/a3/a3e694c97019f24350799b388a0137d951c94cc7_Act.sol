pragma solidity ^0.4.21;


contract Act {

    bytes32 public symbol;
    bytes32 public  name;
    string public act = &quot;QmbQepVoQdawBcz8A98nApTH5SaFGHqK6pTKi2eYK3DvAm&quot;;

    function Act() public {
        symbol = &quot;ACT&quot;;
        name = &quot;ActoOfIndependenceOfLithuania&quot;;
    }

    function getAct() public view returns (string) {
        return act;
    }

}
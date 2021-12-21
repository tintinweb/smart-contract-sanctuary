// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./First.sol";

contract SecondContract {
    FirstContract public ft;

    constructor(FirstContract _ft)  {
        ft = _ft;
    }
    
    function CheckIsContract() public view returns (bool) {
        return ft.isContract();
    }
}
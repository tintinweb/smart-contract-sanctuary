/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test{


    mapping(uint256=>string) public name;

    function add(uint256 _num) public {
        name[_num] = "ss";
    }

    function add1()public{
        for(uint256 i=1;i<=1000;i++){
            name[i]="ss";
        }
    }
    function add2()public{
        for(uint256 i=1000;i<=2000;i++){
            name[i]="ss";
        }
    }
    function add3()public{
        for(uint256 i=2000;i<=3000;i++){
            name[i]="ss";
        }
    }
    function add4()public{
        for(uint256 i=3000;i<=4000;i++){
            name[i]="ss";
        }
    }
    function add5()public{
        for(uint256 i=4000;i<=5000;i++){
            name[i]="ss";
        }
    }
    function add6()public{
        for(uint256 i=5000;i<=6000;i++){
            name[i]="ss";
        }
    }
    function add7()public{
        for(uint256 i=6000;i<=7000;i++){
            name[i]="ss";
        }
    }
    function add8()public{
        for(uint256 i=7000;i<=8000;i++){
            name[i]="ss";
        }
    }
    function add9()public{
        for(uint256 i=8000;i<=9000;i++){
            name[i]="ss";
        }
    }

    function add10()public{
        for(uint256 i=9000;i<=12000;i++){
            name[i]="ss";
        }
    }
}
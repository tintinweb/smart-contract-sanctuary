/**
 *Submitted for verification at hecoinfo.com on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
    contract token{
        address public owner;
        string public  wanglei;
        uint256 public   nianling = 27; 
        uint256 public   shengao =172;
        uint256 public   tizhong = 165;
//修改管理员
/*
        function setowner(address _owner) public{
            owner = _owner;
        }
//修改年龄
        function setnianling(uint256 _nianling)public {
            nianling = _nianling;
        }
//修改身高
        function setshengao (uint256 _shengao) public {
            shengao = _shengao;
        }
//修改体重
        function settizhong (uint256 _tizhong ) public {
            tizhong = _tizhong ;
        }
*/
       function heji() external view returns (uint256) {
        return tizhong+20;

       }

    }
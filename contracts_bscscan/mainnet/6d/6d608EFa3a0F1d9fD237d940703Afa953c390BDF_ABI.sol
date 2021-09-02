/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED
/*
$$$$$$$\            $$\       $$\       $$\   $$\           $$$$$$$$\ $$\
$$  __$$\           $$ |      $$ |      \__|  $$ |          $$  _____|\__|
$$ |  $$ | $$$$$$\  $$$$$$$\  $$$$$$$\  $$\ $$$$$$\         $$ |      $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\
$$$$$$$  | \____$$\ $$  __$$\ $$  __$$\ $$ |\_$$  _|        $$$$$\    $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\
$$  __$$<  $$$$$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |          $$  __|   $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$\       $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
$$ |  $$ |\$$$$$$$ |$$$$$$$  |$$$$$$$  |$$ |  \$$$$  |      $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\
\__|  \__| \_______|\_______/ \_______/ \__|   \____/       \__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|

RabbitFinance.io
*/


pragma solidity ^0.6.0;

contract ABI {
    function add_encode(address strategy,address _token0,address _token1,uint256 _token0Amount,uint256 _token1Amount,uint256 _minLPAmount) pure public returns(bytes memory) {
        return(abi.encode(strategy,abi.encode(_token0,_token1,_token0Amount,_token1Amount,_minLPAmount)));
    }
    
    function withdraw_encode(address strategy,address _token0,address _token1,uint _whichWantBack)pure public returns(bytes memory){
        return (abi.encode(strategy,abi.encode(_token0,_token1,_whichWantBack)));
    }
    
    function worker_withdraw_liquidate(address strategy,uint256 _minBaseTokenAmount)pure public returns(bytes memory){
        return (abi.encode(strategy,abi.encode(_minBaseTokenAmount)));
    }
}
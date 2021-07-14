/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
//接口化封装了”可对外的函数/功能:
interface IDataBase{
    /*-- old base data type --*/ 
    //standard, singles, doubles, trixie/trebles, Yankee/4 folds,
    //Super Yankee/5 folds, Heinz/6 folds, Super Heinz/7 folds,Goliath/8 folds,Block
    enum  BettingType {SINGLE, STRING, EXTENSION}
    /*-- new base data type --*/ 
    //Standard, Singles, Multi-folds, combined-bet
    //enum BetType   { _Standard, _Singles, _MultiFold, _Combined }
    enum FoldsType { _0F, _1F, _2Folds, _3Folds, _4Folds, _5Folds, _6Folds, _7Folds, _8Folds, _9Folds, _10Folds }
}
interface ILotteryBet is IDataBase{
    /*-- old version --*/
    function bettingSingle(string calldata gID1, string calldata oID1) external payable;
    /*-- new version --*/ 
    //标准投注
    //function standardBetSlip (string[] calldata _opID, uint256[] calldata _btAM) external payable; 
    //单关：n串1
    //function singlesBetSlip (string[] calldata _opID, uint256  _ftAM) external payable; 
    //多串：m串n
    //function multiFoldsBetSlip(string[] calldata _opID, FoldsType  _ft, uint256  _ftAM) external payable; 
    //组合：一单多玩法
    function combinedBetSlip (string[] calldata _opID, uint256[] calldata _btAM, FoldsType[] calldata _ft, uint256[] calldata _ftAM) external payable; 
    /*----CFO function--------------------------*/ 
    function Withdrawal() external;
    /*----QUERY: some query function--------------------------*/ 
    function queryBetting(address user) external view returns (address,uint);
    function getTotalAmount() external view returns (uint);
    function getTotalBetOrders() external view returns (uint);
}
contract GatewayBase {
    //base
    event Upgraded(address implementation);
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // public -----------------------------
    function getLogicContract() public view returns(address){
        return _implementation();
    }
    
    function setLogicContract(address newImplementation) public{
        _upgradeTo(newImplementation);
    }
    
    // private ------------------------------
    function _upgradeTo(address newImplementation) internal {
      _setImplementation(newImplementation);
      emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private{
      bytes32 slot = IMPLEMENTATION_SLOT;
      assembly {
        sstore(slot, newImplementation)
      }
    }

    function _implementation() private view returns (address impl) {
      bytes32 slot = IMPLEMENTATION_SLOT;
      assembly {
        impl := sload(slot)
      }
    }

    //proxy
    event logs(string  text);
    fallback () payable external virtual{
        _fallback();
    }
    receive () payable external virtual{
        _fallback();
    }

    function _fallback() private {
        emit logs("1. _fallback");
        _delegate(_implementation());
    }

    function _delegate(address implementation) private{
      emit logs("2. _delegate");
      assembly {
        calldatacopy(0, 0, calldatasize())
        let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
        returndatacopy(0, 0, returndatasize())
     
        switch result
              case 0 { revert(0, returndatasize()) }
             default { return(0, returndatasize()) }
      }
    }

}

//可部署合约3，且可公开代码的合约：“测试合约”
contract LotteryBet_V4_Test is ILotteryBet, GatewayBase {
    function bettingSingle(string calldata gID1, string calldata oID1) external payable override{}
    function combinedBetSlip( string[] calldata _opID, uint256[] calldata _btAM, FoldsType[] calldata _ft, uint256[] calldata _ftAM ) external payable override{}
    function Withdrawal() external override{}
    /*----QUERY: some query function--------------------------*/ 
    function queryBetting(address user) public view override returns (address,uint){}
    function getTotalAmount() public view override returns (uint){}
    function getTotalBetOrders() public view override returns (uint){}
}
/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SmbcTest{

address public creator;



    struct ContractValues{
        //9 values
    uint256 vSMBCid;    
    uint aValue;
    uint bValue;
    bool aRecived;
    bool bSentservice;
    bool aFinishsigned;
    bool bFinishsigned;
    string aWallet;
    string bWallet;
                        }

    mapping (address => ContractValues) public ContractData;
    address[] public ContractValues_results;

     function returnmyContract() public view returns (address) {
        return ( msg.sender);
    }
    function setmapp( uint256 _contRactmapid ,uint _aValue , uint _bVal ,bool _Aservicerecived , bool _BserviceSent , bool _Acontrafin , bool _Bcontractfin , string memory  _Aad , string memory _Badress) public {
       
        ContractData[msg.sender]= ContractValues( _contRactmapid, _aValue, _bVal , _Aservicerecived , _BserviceSent , _Acontrafin , _Bcontractfin ,  _Aad , _Badress );
    }

 /// VALUES   
 
    function getmappvalue() public view returns ( address[] memory){
        return ContractValues_results;
    }
    function getContractValues(address ins) public view returns (uint256 , uint , uint ){
        
        return (ContractData[ins].vSMBCid, ContractData[ins].aValue, ContractData[ins].bValue );
    }
    function getContractState(address ins) public view returns (bool , bool , bool , bool){
               return (ContractData[ins].aRecived , ContractData[ins].bSentservice , ContractData[ins].aFinishsigned , ContractData[ins].bFinishsigned);
 
    }
    
    function getContractExtraValues(address ins) public view returns (string memory ,string memory ){
        
        return (ContractData[ins].aWallet, ContractData[ins].bWallet);
    }
 
}
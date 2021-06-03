/**
 *Submitted for verification at Etherscan.io on 2021-06-03
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
    address a_wallet;
    

    mapping (address => ContractValues) public ContractData;
    address[] public ContractValues_results;

     function retunContactOwner() public view returns (address) {
        return ( msg.sender);
    }
    function a_set_A_Owner (address _a_wallet)public {
        a_wallet = _a_wallet;
    }
  
    function setmapp( uint256 _contRactmapid ,uint _aValue , uint _bVal ,bool _Aservicerecived , bool _BserviceSent , bool _Acontrafin , bool _Bcontractfin , string memory  _Aad , string memory _Badress) public {
       
        ContractData[a_wallet]= ContractValues( _contRactmapid, _aValue, _bVal , _Aservicerecived , _BserviceSent , _Acontrafin , _Bcontractfin ,  _Aad , _Badress );
    }
     function set_con_id( uint256 _conid) public {
     ContractData[a_wallet].vSMBCid= _conid;
    }
    function set_AB_value( uint _aVal , uint _bVal) public {
        ContractData[a_wallet].aValue= _aVal;
        ContractData[a_wallet].bValue= _bVal;

    }

    function set_A_recive( bool _Astate) public {
        ContractData[a_wallet].aRecived= _Astate;
    }
    function set_B_sent( bool _Bstat) public {
        ContractData[a_wallet].bSentservice= _Bstat;
    }
    function set_A_finish( bool _Afinish) public {
        ContractData[a_wallet].aFinishsigned= _Afinish;
    }
    function set_B_finishit( bool _Bfin) public {
        ContractData[a_wallet].bFinishsigned= _Bfin;
    }
    function set_AB_wallet( string memory _awallad , string memory _bwall) public {
        ContractData[a_wallet].aWallet= _awallad;
        ContractData[a_wallet].bWallet= _bwall;
    }
    

 /// VALUES   
   
 
    function getAvalue(address ins) public view returns ( uint){
        return (ContractData[ins].aValue);
    }
    function getBvalue(address ins) public view returns ( uint){
        return (ContractData[ins].bValue);
    }
    function getAverstate (address ins) public view returns ( bool){
        return (ContractData[ins].aRecived);
    }
    function getBverstate (address ins) public view returns ( bool){
        return (ContractData[ins].bSentservice);
    }
    function getAfinstate (address ins) public view returns ( bool){
        return (ContractData[ins].aFinishsigned);
    }
     function getBfinstat (address ins) public view returns ( bool){
        return (ContractData[ins].bFinishsigned);
    }
    function theAwall (address ins) public view returns ( string memory){
        return (ContractData[ins].aWallet);
    }
    function theBwallet (address ins) public view returns (string memory){
        return (ContractData[ins].bWallet);
    }
    
 
}
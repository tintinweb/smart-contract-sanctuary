/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


contract buildSMBC{
        

    struct contractvalues{
        //9 values
    uint256 SMBCid;    
    uint Avalue;
    uint Bvalue;
    bool Arecived;
    bool Bsentservice;
    bool Afinishsigned;
    bool Bfinishsigned;
    string Awallet;
    string Bwallet;
    
                        }
                     
    contractvalues public mysubcontract;
  

    function setContractState (bool _Aservicerecived , bool _BserviceSent , bool _Acontractfin , bool _Bcontractfin  ) public {
        mysubcontract.Arecived = _Aservicerecived;
        mysubcontract.Bsentservice= _BserviceSent;
        mysubcontract.Afinishsigned = _Acontractfin;
       mysubcontract.Bfinishsigned = _Bcontractfin;
    }
    
    function setheID (uint256 _newid) public {
                mysubcontract.SMBCid = _newid;

    }
    function setValues (uint _aValue , uint _bvalue) public {
        mysubcontract.Avalue=_aValue;
        mysubcontract.Bvalue=_bvalue;
    }
    function setAddress(string memory  _Aadress , string memory _Badress)  public returns (string memory , string memory) {
        mysubcontract.Awallet =  _Aadress;
        mysubcontract.Bwallet = _Badress;
    }
    
    
 /// VALUES   
    function getcontractid() public view returns (uint256){
        return (mysubcontract.SMBCid);
    }
    function getsideAvalue() public view returns (uint){
        return (mysubcontract.Avalue);
    }
    function getsideBvalue() public view returns (uint){
        return (mysubcontract.Bvalue);
    }
     function getArecived() public view returns (bool){
        return (mysubcontract.Arecived);
    }
     function getAfinished() public view returns (bool){
        return (mysubcontract.Afinishsigned);
    }
       function getBsentservice() public view returns (bool){
        return (mysubcontract.Bsentservice);
    }
     function getBfinished() public view returns (bool){
        return (mysubcontract.Bfinishsigned);
    }
    function getAwallet() public view returns(string memory){
        return (mysubcontract.Awallet);
    }
    function getBwallet() public view returns(string memory){
        return (mysubcontract.Bwallet);
    }
}
pragma solidity >=0.4.0 <0.6.0;

contract DataTypes{
    uint unsignedvalue;
    int  signedvalue;
    address _address;
    string _string;
    bool _bool;
    bytes _bytes;
    
    function setData(uint s_unsignvalue, int s_signvalue, address s__address,string memory s__string,bool s__bool,bytes memory s__bytes)public 
    {
        unsignedvalue = s_unsignvalue;
        signedvalue = s_signvalue;
        _address = s__address;
        _string = s__string;
        _bool = s__bool;
        _bytes = s__bytes;
        emit getData(unsignedvalue, signedvalue, _address, _string, _bool, _bytes);
    }
    event getData(uint unsignedvalue,int signedvalue ,address _address,string _string,bool _bool,bytes _bytes);
    //  return(unsignedvalue,signedvalue,_address,_string,_bool,_bytes);
    //}
}
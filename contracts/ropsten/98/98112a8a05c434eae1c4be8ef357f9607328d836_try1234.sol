pragma solidity ^0.5.1;
contract try1234{
     
     struct transactiondetail
    {
      string compid1;
      string empid;
      string batch;
      string compid2;
      uint quant;
      uint quant1;
      string timestamp;
      string types1;
      string types2;
      string subtypes1;
      string subtypes;
      bool status;
      uint date;
     } 
    
    mapping(string=>transactiondetail) permit;
    mapping(string =>mapping(string=>bool)) permi;
     mapping(string =>mapping(string=>transactiondetail)) setper;
     mapping(string =>string) settper;
    function permission(string memory _compid1,string memory _compid2,bool state)public 
    {
        permit[_compid1].compid2=_compid2;
        permi[_compid1][_compid2]=state;
        settper[_compid1]=concat(settper[_compid1],_compid2);
    }
    function setpermi(string memory _compid1,string memory _compid2,string memory _types1,string memory _types2,string memory _subtypes,string memory _subtypes1) public returns (bool)
    {
        if ( permi[_compid1][_compid2]==true)
        
        {
            setper[_compid1][_compid2].compid2=_compid2;
            if(keccak256(abi.encode(_types1))==keccak256(abi.encode("L1")))
            {setper[_compid1][_compid2].types1=_types1;}
            if(keccak256(abi.encode(_types2))==keccak256(abi.encode("L2")))
            {setper[_compid1][_compid2].types2=_types2;}
            if(keccak256(abi.encode(_subtypes))==keccak256(abi.encode("sales"))) 
            {setper[_compid1][_compid2].subtypes="sales";}
            if(keccak256(abi.encode(_subtypes1))==keccak256(abi.encode("inventory")))
            {setper[_compid1][_compid2].subtypes1="inventory";}
            setper[_compid1][_compid2].date=now;
             return true;
        }
        else
             return false;
    }
    function seerequest(string memory _compid1) public view returns(string memory)
    {
        return settper[_compid1];
    }    
    
    function seepermitted(string memory _compid1,string memory _compid2) public view returns(string memory,string memory,string memory,string memory,uint)
    {
        return(setper[_compid1][_compid2].types1,setper[_compid1][_compid2].types2,setper[_compid1][_compid2].subtypes,setper[_compid1][_compid2].subtypes1,setper[_compid1][_compid2].date);
    }
    mapping(string =>mapping(string=>mapping(string=>transactiondetail))) record;
    mapping (string =>mapping(string=>string)) rec;
    function settransactiondetail(string memory _compid1,string memory _empid,string memory _batch,string memory _compid2,uint _quant,string memory _time) public
    {    if ( permi[_compid1][_compid2]==true)
        {
            record[_compid1][_compid2][_time].compid1=_compid1;
            record[_compid1][_compid2][_time].empid=_empid;
            record[_compid1][_compid2][_time].batch=_batch;
            record[_compid1][_compid2][_time].compid2=_compid2;
            record[_compid1][_compid2][_time].quant=_quant;
            record[_compid1][_compid2][_time].quant1=uint(keccak256(abi.encode(_quant)))%1000000000000000;
            record[_compid1][_compid2][_time].timestamp = _time;
            rec[_compid1][ _compid2] = concat(rec[_compid1][_compid2],_time);
        }
    } 
    function gettransactiondetail(string memory _compid1,string memory _compid2,string memory _time) public view returns(string memory,string memory,uint,string memory )
    {     if ( permi[_compid1][_compid2]==true)
         if(keccak256(abi.encodePacked(_compid1)) != keccak256(abi.encodePacked(_compid2)))
         return( record[_compid1][_compid2][_time].empid,record[_compid1][_compid2][_time].batch,record[_compid1][_compid2][_time].quant1,
         record[_compid1][_compid2][_time].timestamp);
    }
     function getarray(string memory _compid1,string memory _compid2) public view returns (string memory)
     { 
        if(keccak256(abi.encodePacked(_compid1)) != keccak256(abi.encodePacked(_compid2)))
        return rec[_compid1][ _compid2];       
     }
     function showquantity(string memory _compid1,string memory _compid2,string memory _time,uint key)public view returns(uint,string memory)
    {
        if (record[_compid1][_compid2][_time].quant1==key)
          {
              return (record[_compid1][_compid2][_time].quant,"product quantity sold");
            
             }
          else
          {
              return(0,"error:enter a valid key");
          }
    
     }
     function concat(string memory _str1,string memory _str2) pure internal returns(string memory)
     {
       return string(abi.encodePacked(_str1,_str2,","));
     }
    
    
}
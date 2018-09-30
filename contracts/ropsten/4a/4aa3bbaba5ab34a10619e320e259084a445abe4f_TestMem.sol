pragma solidity ^0.4.18;

contract TestMem {
   
    uint public v1=8;
    uint256 public m_value;
    
    mapping (bytes32 => mapping (uint256 => uint256)) public buu;
    
   function setBUU(bytes32 _key, uint256 _index, uint256 _value) public {
        buu[_key][_index] = _value;
    }

   function setValue(uint256 value) public {
        m_value=value;
        require(value>5 ,"erro <=5");
    }
    
   function getValue() public view returns (uint256) {
        return m_value;
    }
    
   function test(uint256 value) public {
        uint total=0;
        m_value=value;
        for (uint i=0;i<value;i++){
            total+=i;
        }
    }
    
    function test1(uint256 value) public {
        for (uint256 i=0;i<value;i++){
            setBUU("test",i,value);
        }
     
    }

   function test2(uint256 value) public {
        uint256 v=value-1;
        uint256 v2=v;
        uint256 v3=v2;
        uint256 v4=v3;
        uint256 v5=v4;
        uint256 v6=v5;
        uint256 v7=v6;
        uint256 v8=v7;
        uint256 v9=v8;
        uint256 v10=v;
        v=v9+1;
        v=v10;
        if (v>0)
            test2(v);
    }

       
   function test21(uint256 value) public {
        uint256[2000] memory v;
        
        for (uint256 i=0;i<value;i++){
            v[i]=i;
        }
        
    }
       
 function test3(uint256 value) public {
        
        uint256[20] memory v1;
        uint256[20] memory v2;
        uint count=0;
        for (uint256 i=0;i<20;i++){
            v1[i]=i;
            v2[i]=i+1;
        }
        for(;;){ 
            
        uint256 v3=value;
        count++;
        if (count>value)
             break;
        uint256 v4=value;
        count++;
        if (count>value)
             break;

        uint256 v5=value;
        count++;
        if (count>value)
             break;

        uint256 v6=v5;
        count++;
        if (count>value)
             break;

        uint256 v7=v6;
        count++;
        if (count>value)
             break;

        uint256 v8=v7;
        count++;
        if (count>value)
             break;

        uint256 v9=v8;
        count++;
        if (count>value)
             break;
        }
    }
       

}
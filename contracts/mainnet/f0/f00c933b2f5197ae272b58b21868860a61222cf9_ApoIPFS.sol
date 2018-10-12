pragma solidity ^0.4.17;
contract ApoIPFS
 {
      mapping (address => mapping (string => string)) apos;


      function setIPFS(address _addr,string datetime,string _ipfshash) public
      {
          
          if(bytes(apos[_addr][datetime]).length==0)
          {
              apos[_addr][datetime] = _ipfshash;
          }
      }
      

      function getIPFS(address _addr,string datetime) public constant returns (string)
      {
           
            return apos[_addr][datetime];
      }

}
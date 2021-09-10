pragma solidity >=0.5.0;
 
contract dConfess 
{
    address[] private confessors;
    mapping (address => string[] ) private confessions;
     
     
    // event confessionRecorded(address indexed key,bytes32 _digest,uint8 _hashFunction,uint8 _size);
     
    function set(string memory _hash) public
    {
        bool oldconfessor = false;
        for(uint i = 0;i < confessors.length;i++)
        {
            if(confessors[i]==msg.sender)
            {
                oldconfessor = true;
                break;
            }
        }
        if(!oldconfessor)
        {
            confessors.push(msg.sender);
        }
        
        for(uint i = 0;i < confessors.length;i++)
        {
            if(confessors[i]==msg.sender)
            {
                confessions[confessors[i]].push(_hash);
            }
        }
    }
    
    function getAddress() public view returns(address )
    {
       return msg.sender;
    }
    function getAddressCount(address _address) public view returns(uint)
    {
        for(uint i=0;i<confessors.length;i++)
        {
            if(confessors[i]==_address)
            {
                return confessions[_address].length;
            }
        }
        return 0;
    }
    function getConfession(address _address,uint i) public view returns(string memory)
    {
       return confessions[_address][i];
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
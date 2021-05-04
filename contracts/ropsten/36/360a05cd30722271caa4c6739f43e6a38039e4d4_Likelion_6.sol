/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// im yuri 1)

contract Likelion_6{
    
    string[] names;
    
    function pushName(string memory _name) public {
        names.push(_name);
    }
    
    function deleteName() public{
        for(uint i=0; i<names.length; i++) {
            if(keccak256(bytes(names[i]))==keccak256(bytes("james"))) {
              delete names[i];
            }
             }
    }

function getName(uint i) public view returns(string memory) {
    return names[i];
}
}
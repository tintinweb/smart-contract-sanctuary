/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//Jinseon Moon 
contract Lion_6 {
    string[] names;
    bytes32[] users;
    
    function pushName(string memory _name) public {
        if(keccak256(bytes(_name)) == keccak256(bytes("James"))) {
            return;
        } else {
            names.push(_name);
        }
    }
    
    
    //for check list
    function getName() public view returns(string[] memory) {  
        return names;
    }
    
    function SignIn(string memory _id, uint _password) public {
        
        bytes32 hash = keccak256(abi.encodePacked(_id, _password));
        uint a = 0;
        uint b = 0;
        
        for(uint i=0; i < users.length; i ++) {
            if(users[i] == hash) {
                a = i;
                b = 1;
            }
        }
        
        if(b == 0) {
            users.push(hash);
        } else {
            delete users[a];
        }
        
        
        }
        
        function LogIn(string memory _id, uint _password) public view returns(string memory) {
        
            bytes32 hash = keccak256(abi.encodePacked(_id, _password));
            uint a = 0;
            uint b = 0;
        
            for(uint i=0; i < users.length; i ++) {
                if(users[i] == hash) {
                    a = i;
                    b = 1;
                }
            }
        
            if(b == 1) {
                return "Log in sucesseful!";
            } else {
                return "Error!";
            }
            
        }
    
}
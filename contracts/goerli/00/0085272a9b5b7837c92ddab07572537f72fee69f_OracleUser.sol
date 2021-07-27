/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma  solidity ~0.4.11;

contract Oracle{
    struct Request {
        bytes data;
        function(bytes memory) external callback;
    }
    Request[] requests;
    event NewRequest(uint);
    function query(bytes data,function(bytes memory) external callback) public{
        requests.push(Request(data,callback));
        
        NewRequest(requests.length-1);
    }
    function reply(uint requestID,bytes response) public{
         //
         requests[requestID].callback(response);
    }
    
}

contract OracleUser{
    Oracle constant oracle = Oracle(0xe165670B90a5eCe8F3bE9FB0067203012DFC84F7);
    function buySomething(){
        oracle.query("USD",this.oracleResponse);
    }
    function oracleResponse(bytes response) public {
        require(msg.sender == address(oracle));
    }
}
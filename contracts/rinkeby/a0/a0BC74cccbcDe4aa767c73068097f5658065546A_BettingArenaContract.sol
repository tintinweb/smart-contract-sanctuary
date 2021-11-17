/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.4.18;

contract BettingArenaContract {
    
    event HTTPRequest(
        uint id,
        string url,
        string method,
        string parameters
    );
    
    struct Better {
        address addr;
        uint bet;
        string winner;
    }

    address _trustedAddress; 
    uint requestsCounter = 0;

    mapping (string => Better[]) matches; // matchId => [Better]
    mapping (string => uint8) availableMatches; // matchId => 0 - available | 1 - locked | 2 - already resolved
    mapping (uint => string) requestedResults; // requestId => gameId
    
    //the contract is initiated by the address which our trusted host will use to inject responses
    constructor(address trustedAddress) public {
        _trustedAddress = trustedAddress;
    }
    
    // join betting for a match, you spend eth as a bet
    function join(string matchId, string winner) public payable {
        // we will fail if the match is resolved or locked
        require(availableMatches[matchId] == 0); 
        
        // add the better to the list
        matches[matchId].push(Better(msg.sender, msg.value, winner)); 
    }
    
    // this method will initiate 'http request' for a match
    function resolve(string matchId) public {
        require(availableMatches[matchId] == 0); // is available
        availableMatches[matchId] = 1; // locked
        
        // we will generate an id to match request and response
        uint id = getRequestsID();
        requestedResults[id] = matchId; 
        
        // emited event will be stored in the transaction data and can be observed/read from the outside of the blockchain
        emit HTTPRequest(id, "http://some_api.com/get_winner?", "GET", strConcat("matchId=", matchId)); 
    }
    
    // this is the method to handle a response and distribute the prize among participants
    function distributePrize(uint requestId, string response) public {
        //only our trusted service can use it
        require(msg.sender == _trustedAddress);
        
        // we know the matchId by the blockNumber
        string memory matchId = requestedResults[requestId];
        string memory winner = parseResponse(response);
        
        /*
            I'will skip the prize distribution logic, it is not interesting for us.
            We have a winner, matchId and all the data in matches[matchId] to make a decision.
        */
        
        //clean up
        delete requestedResults[requestId];
        availableMatches[matchId] = 2; // resolved
    }
    
    // the response can have a complex format, in this case it is just a winner name
    function parseResponse(string response) private pure returns(string) {
        return response;
    }
    
    //to generate a unique id for a request we will use an incrementing index
    //to overcome uint overflow problem you can use another strategy
    //for example: hash(blockNumber + requestsCounterPerBlock)
    function getRequestsID() private returns(uint) { 
        return ++requestsCounter; 
    }

    // just a helper to build a parameters string
    function strConcat(string a, string b) private pure returns (string) {
        bytes memory bytes_a = bytes(a);
        bytes memory bytes_b = bytes(b);
        bytes memory buffer = bytes(new string(bytes_a.length + bytes_b.length));
        uint i = 0;
        for (uint j = 0; j < bytes_a.length; j++) buffer[i++] = bytes_a[j];
        for (j = 0; j < bytes_b.length; j++) buffer[i++] = bytes_b[j];
        return string(buffer);
    }
}
pragma solidity ^ 0.4.11;
// We have to specify what version of compiler this code will compile with

contract AheVotingBrainfood2 {
    /* mapping field below is equivalent to an associative array or hash.
    The key of the mapping is candidate name stored as type bytes32 and value is
    an unsigned integer to store the vote count
    */

    mapping(bytes32 => uint8) public votesReceived;

    /* Solidity doesn&#39;t let you pass in an array of strings in the constructor (yet).
    We will use an array of bytes32 instead to store the list of candidates
    */

    bytes32[] public candidateList;

    event CandidateVoted(string _candidateName, uint _votes);

    /* This is the constructor which will be called once when you
    deploy the contract to the blockchain. When we deploy the contract,
    we will pass an array of candidates who will be contesting in the election
    */
    function AheVotingBrainfood2() {

        candidateList = new bytes32[](6);

        candidateList[0] = stringToBytes32(&#39;Cocos JS&#39;);
        candidateList[1] = stringToBytes32(&#39;Jmeter&#39;);
        candidateList[2] = stringToBytes32(&#39;HTTP2&#39;);
        candidateList[3] = stringToBytes32(&#39;Dissecting Swagger&#39;);
        candidateList[4] = stringToBytes32(&#39;WebComponents&#39;);
        candidateList[5] = stringToBytes32(&#39;Concepten van Blockchain&#39;);
    }

    // This function returns the total votes a candidate has received so far
    function totalVotesFor(string candidate) public view returns(uint8) {
        if (!validCandidate(candidate))
            throw;
            
        var _candidate = stringToBytes32(candidate);    
            
        return votesReceived[_candidate];
    }

    // This function increments the vote count for the specified candidate. This
    // is equivalent to casting a vote
    function voteForCandidate(string candidate) public /*payable*/ {
        if (!validCandidate(candidate))
            throw;
            
        var _candidate = stringToBytes32(candidate);   
            
        votesReceived[_candidate] += 1;

        emit CandidateVoted(candidate, votesReceived[_candidate]);
    }

    function getCandidateByIndex(uint index) public view returns(string) {
        if (index >= candidateList.length)
            return "";

        return bytes32ToString(candidateList[index]);
    }

    function getCandidateVotesByIndex(uint index) public view returns(string, uint8) {
        if (index >= candidateList.length)
            return ("",0);

		var candidate = candidateList[index];
			
		var votes =  votesReceived[candidate];
			
        return (bytes32ToString(candidate), votes);
    }	

    function validCandidate(string candidate) public view returns(bool) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == stringToBytes32(candidate)) {
                return true;
            }
        }
        return false;
    }

    function bytes32ToString(bytes32 x) constant returns(string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function stringToBytes32(string memory source) public constant returns(bytes32 result) {
        // require(bytes(source).length <= 32); // causes error
        // but string have to be max 32 chars
        // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
        // http://solidity.readthedocs.io/en/latest/assembly.html
        assembly {
            result:= mload(add(source, 32))
        }
    }//
}
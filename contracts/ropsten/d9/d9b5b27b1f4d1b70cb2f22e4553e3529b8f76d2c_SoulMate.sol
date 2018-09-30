pragma solidity ^0.4.24;

contract SoulMate {
    
    mapping(bytes32 => SecretMessage)  secrets;
    mapping(address => uint256) balance;
    
    struct Answer {
        address userAddress;
        bytes32 answer;
    }
    
    mapping(bytes32 => Answer[]) answers;
    
    // unopened secrets
    uint256 hashesLength;
    bytes32[] public secretHashes;
    
    struct SecretMessage {
        uint256 value;
        address owner;
        string content;
        bytes32 answerHash;
        bool hasOpened;
    }
    
    uint256 public min_deposit = 2 finney;
    
    mapping(address => bytes32[]) nonPublicSecret;
    
    /**
     * Create new secret message
     **/
    function createNewSecret(string secretMessage, bytes32 hash, bool hide) public payable {
        require(msg.value >= min_deposit);
        
        // add balance
        balance[msg.sender] += msg.value;
        
        // add a new secret
        secrets[hash] = SecretMessage(msg.value, msg.sender, secretMessage, hash, hide);
        
        if(hide == false) {
            addNewSecretHash(hash);
        }
        else {
            nonPublicSecret[msg.sender].push(hash);
        }
        
    }
    
    /**
     * Get a random ID of a secret
     **/
    
    function getRanomSecret() public view returns (bytes32) {
        uint index = (now + gasleft()) % hashesLength;
        return secretHashes[index];
    }
    
    /** 
     * Open the answer of the secret by the owner
     **/
    function openSecret(bytes32 hash, bytes32 answer, string randomString) public {
        // check the answer
        require(hash == sha256(answer, randomString));
        
        // process result
        Answer[] storage userAnswers = answers[hash];
        SecretMessage storage secret = secrets[hash];
        uint256 amountToOwner = secret.value / 2;
        for(uint idx = 0; idx < userAnswers.length; idx++) {
            if(userAnswers[idx].answer == answer) {
                // send money to winner
                userAnswers[idx].userAddress.transfer(secret.value);
            }
            else {
                amountToOwner += secret.value / 2;
            }
        }
        
        secret.owner.transfer(amountToOwner);
        
        secrets[hash].hasOpened = true;
        removeOneSecret(hash);
    }
    
    /**
     * User post a new answer 
     **/
    function postNewAnswer(bytes32 hash, bytes32 answer) public payable {
        SecretMessage secret = secrets[hash];
        
        /* The secret has not been opened */
        require(secret.hasOpened == false);
        
        /* User must deposit enough money while post new answer */
        require(msg.value * 2 >= secret.value);
        
        /* Only one user is allowed to post new answer for each secret */
        require(answers[hash].length == 0);
        
        answers[hash].push(Answer(msg.sender, answer));
    }
    
    /** 
     * Get a secret by secret hash
     **/
    function getSecretByHash(bytes32 hash) public view returns (uint256 value, address owner, string content) {
        return (secrets[hash].value, secrets[hash].owner, secrets[hash].content);
    }
    
    function removeOneSecret(bytes32 hash) internal {
        for(uint256 idx = 0; idx < hashesLength; idx++) {
            if(secretHashes[idx] == hash) {
                secretHashes[idx] = secretHashes[hashesLength - 1];
                break;
            }
        }
        hashesLength--;
    }
    
    function addNewSecretHash(bytes32 hash) internal {
        if(secretHashes.length == hashesLength) {
            secretHashes.push(hash);
        }
        else {
            secretHashes[hashesLength] = hash;
        }
        
        hashesLength++;
    }
}
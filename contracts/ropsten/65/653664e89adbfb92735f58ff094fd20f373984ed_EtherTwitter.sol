contract EtherTwitter {
    uint256 accountId;

    struct Account{
        uint256 id;
        string name;
        uint256 twitId;
        mapping(uint256 => string) twit;
    }
    
    mapping(address=> Account )public accounts;
    
    function EtherTwitter(){
        accountId = 0;
    }
    
    
    modifier isValidUser(){
        assert(0x0 != msg.sender);
        //assert(accounts[msg.sender]);
        _;
    }
    
    modifier isNewUser(){
        //assert(0x0 == accounts[msg.sender]);
        _;
    }
    
    
    function registerUser() isNewUser returns(uint256) {
        accountId += 1;
        Account newAccount;
        newAccount.id = accountId;
        newAccount.name = "test";
        newAccount.twitId = 0;
        accounts[msg.sender] = newAccount;
        return newAccount.id;
    }
    
    
    function postTwit(string twitStr) isValidUser returns(bool){
        var account = accounts[msg.sender];
        account.twitId += 1;
        account.twit[account.twitId] = twitStr;
    }
    
    function getTwit(address addr, uint256 twitId) returns(string){
        return accounts[msg.sender].twit[twitId];
    }
   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    event Issue(uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
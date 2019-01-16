contract EtherTwitter {

    uint256 accountId;

    struct Account{
        uint256 id;
        string name;
        uint256 twitId;
        mapping(uint256 => string) twit;
    }
    
    mapping(address=> Account )public accounts;
    

    // notifys
    event NewUser(address addr);
    event NewPost(address addr, uint256 twitId, string post);

    function EtherTwitter(){
        accountId = 0;
    }
    

    //    
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
        NewUser(msg.sender);
        return newAccount.id;
    }
    
    
    // post Twitter
    function postTwit(string twitStr) isValidUser returns(bool){
        var account = accounts[msg.sender];
        account.twitId += 1;
        account.twit[account.twitId] = twitStr;
        NewPost(msg.sender, account.twitId, twitStr);
        return true;
    }
    

    // readTwitter
    function  getTwit(address addr, uint256 twitId) constant returns(string){
        return accounts[msg.sender].twit[twitId];
    }
   
}
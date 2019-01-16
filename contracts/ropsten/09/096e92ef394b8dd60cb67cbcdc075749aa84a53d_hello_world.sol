pragma solidity 0.4.25;

contract hello_world {
// data setup 
    address private inventor_ = msg.sender;
    uint256 private requestCounter_;
    mapping(uint256 => Request) private approvalRequests_;
    struct Request {
        address addr;
        string name;
        string password;
    }
    uint256 private approvedUsers_;
    mapping(address => Users) private users_;
    struct Users {
        string name;
        bool approved;
    }
    uint256 private msgCounter_;
    mapping(uint256 => Message) private messages_;
    struct Message {
        string name;
        string msg;
        uint256 timestamp;
    }
    
// modifiers 
    modifier onlyInventor()
    {
        require(tx.origin == inventor_, "tisk tisk");
        _;
    }
    
    modifier onlyApproved()
    {
        require(users_[tx.origin].approved == true || tx.origin == inventor_, "tisk tisk");
        _;
    }
    
// user functions
    function requestApproval(string _name, string _password)
        public
    {
        address _addr = tx.origin;
        
        require(users_[_addr].approved == false, "already approved");
        
        requestCounter_++;
        uint256 _counter = requestCounter_;
        
        approvalRequests_[_counter].addr = _addr;
        approvalRequests_[_counter].name = _name;
        approvalRequests_[_counter].password = _password;
    }
    
    function enterMessage(string _msg) 
        public
        onlyApproved()
    {
        msgCounter_++;
        uint256 _msgCounter = msgCounter_;
        
        messages_[_msgCounter].name = users_[tx.origin].name;
        messages_[_msgCounter].msg = _msg;
        messages_[_msgCounter].timestamp = now;
    }
    
// admin functions    
    function getUserName()
        public
        view
        onlyApproved()
        returns(string)
    {
        return(users_[tx.origin].name);
    }

    function viewNumberOfRequests()
        public
        view
        onlyInventor()
        returns(uint256)
    {
        return(requestCounter_);
    }
    
    function viewNumberOfMessages()
        public
        view
        onlyApproved()
        returns(uint256)
    {
        return(msgCounter_);
    }
    
    function viewNumberOfApprovedUsers()
        public
        view
        onlyInventor()
        returns(uint256)
    {
        return(approvedUsers_);
    }
    
    function checkApprovalStatus()
        public
        view
        returns(bool)
    {
        if (tx.origin == inventor_)
            return(true);
        return(users_[tx.origin].approved);
    }
    
    function readMessage(uint256 _msgNumber)
        public
        view
        onlyApproved()
        returns(string, string, uint256)
    {
        return(messages_[_msgNumber].name, messages_[_msgNumber].msg, messages_[_msgNumber].timestamp);
    }
    
    function viewRequest(uint256 _requestNumber)
        public
        view
        onlyInventor()
        returns(string, address)
    {
        return(approvalRequests_[_requestNumber].password, approvalRequests_[_requestNumber].addr);
    }
    
    function approveCorrespondent(uint256 _requestNumber)
        public
        onlyInventor()
    {
        address _addr = approvalRequests_[_requestNumber].addr;
        
        if (users_[_addr].approved != true) 
        {
            users_[_addr].name = approvalRequests_[_requestNumber].name;
            users_[_addr].approved = true;
            approvedUsers_++;
        }
    }
    
    function cleanup()
        public
        onlyInventor()
    {
        selfdestruct(msg.sender);
    }
}
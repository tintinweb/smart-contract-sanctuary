pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// &#39;CafeBlockChain&#39; token contract
//
// Deployed to : 0xE22EABD0fa65267981C55a57B62E6b62D3E47d2B
// Symbol      : CBC
// Name        : CafeBlockChain Token
// Total supply: 100
// Decimals    : 2
//
// Enjoy.
//
// (c) by Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    mapping(address => bool) owner;
    address public admin;

    event acceptNewOwner(address indexed _owner);
    event deleteOwnerEvent(address indexed _owner);

    constructor() public {
        admin = msg.sender ;
        owner[msg.sender] = true ;
    }

    modifier onlyOwner {
        require(owner[msg.sender]);
        _;
    }
    
    modifier onlyAdmin{
        require(admin == msg.sender);
        _;
    }

    function newOwner(address _newOwner) public onlyAdmin {
        owner[_newOwner] = true;
        emit acceptNewOwner(_newOwner);
    }
    
    function deleteOwner(address _delete) public onlyAdmin{
        owner[_delete] = false;
        emit deleteOwnerEvent(_delete);
    }
    
    function role() view external returns(uint){
        if(msg.sender == admin)
            return 1;
        else if(owner[msg.sender])
            return 2;
        else
            return 3;
    }
}

contract KYU is Owned{
    struct Person{
        string first_name;
        string last_name;
        string email;
        uint phone_number; 
        uint code_meli;
    }
    mapping(address => Person) internal person_list;    
    address[] public address_list; 
    
    modifier checkKYU(address _wallet) {
        require(person_list[_wallet].phone_number != 0);
        _;
    }
    modifier notkKYU(address _wallet) {
        require(person_list[_wallet].phone_number == 0);
        _;
    }
    modifier getUserData(){
        require(person_list[msg.sender].phone_number != 0);
        _;
    }
    
    
    function Register(string _first, string _last, string _email, 
                      uint _code, uint _phone_number, address _wallet)
                      public notkKYU(_wallet)
    {
        person_list[_wallet].first_name = _first;
        person_list[_wallet].last_name = _last;
        person_list[_wallet].email = _email;
        person_list[_wallet].phone_number = _phone_number;
        person_list[_wallet].code_meli = _code;

        address_list.push(_wallet) - 1;
    }
    
    function Register(string _first, string _last, string _email, 
                      uint _code, uint _phone_number)
                      public notkKYU(msg.sender)
    {
        person_list[msg.sender].first_name = _first;
        person_list[msg.sender].last_name = _last;
        person_list[msg.sender].email = _email;
        person_list[msg.sender].phone_number = _phone_number;
        person_list[msg.sender].code_meli = _code;

        address_list.push(msg.sender) - 1;
    }

    function getUser() getUserData external view returns(string, string, string, uint, uint){
        Person memory outPutPerson = person_list[msg.sender];
        return(outPutPerson.first_name, outPutPerson.last_name, outPutPerson.email, outPutPerson.phone_number, outPutPerson.code_meli);
    }
    
    function ownerGetUser(address _userAddress) onlyOwner external view returns(string, string, string, uint, uint){
        Person memory outPutPerson = person_list[_userAddress];
        return(outPutPerson.first_name, outPutPerson.last_name, outPutPerson.email, outPutPerson.phone_number, outPutPerson.code_meli);
    }
    
    function deletePersons() public{
        for(uint i = 0 ; i < address_list.length; i++){
            delete person_list[address_list[i]];
        }
        delete address_list;
    }
    
    function editPerson(address _wallet, string _first, string _last, string _email, uint _code, uint _phone) internal {
        bytes32 zero = keccak256(&#39;0&#39;);
        if(keccak256(_first) != zero)
            person_list[_wallet].first_name = _first;
        if(keccak256(_last) != zero)
            person_list[_wallet].last_name = _last;
        if(keccak256(_email) != zero)
            person_list[_wallet].email = _email;
        if(_code != 0)
            person_list[_wallet].code_meli = _code;
        if(_phone != 0)
            person_list[_wallet].phone_number = _phone;
    }
}

contract BlockChainEvent is KYU{
    struct Events{
        string name; // event name
        uint cost;  // cost for first day register
        uint eventTime;
        uint startTime; // timestamp javascript
        uint endTime; // timestamp javascript
        uint tokenPerDay; // how mutch token increas per day from starTime
    }
    
    Events[] public meeting;
    mapping(uint => address[]) public registered ;
    uint public numMeeting = 0;
    
    modifier notRegistered(address _wallet, uint _meetingIndex){
        for(uint i = 0; i < registered[_meetingIndex].length; i++)
            require(registered[_meetingIndex][i] != _wallet);
        _;
    }
    
    modifier checkCost(uint _cafeIndex, uint _token, uint _time){
        uint nowCost;
        nowCost = uint(((_time - meeting[_cafeIndex].startTime)/86400)) * meeting[_cafeIndex].tokenPerDay + meeting[_cafeIndex].cost ;
        require(nowCost == _token);
        _;
    }
    
    function addMeeting(string _name, uint _cost,uint _event, uint _start, uint _end, uint _tokenPerDay) onlyOwner public returns(uint){
        Events memory newMeeting;
        newMeeting.name = _name;
        newMeeting.cost = _cost;
        newMeeting.startTime = _start*1000;
        newMeeting.endTime = _end*1000;
        newMeeting.tokenPerDay = _tokenPerDay;
        newMeeting.eventTime = _event*1000;

        meeting.push(newMeeting);
        numMeeting++;
        return (numMeeting);
    }
    
    function getMeeting(uint _index) external view returns(Events){
        return meeting[_index];
    }
    
    function registerMeeting(address _wallet,uint _meetingIndex) internal {
        registered[_meetingIndex].push(_wallet);
    }
    
    function getRegistered(uint _cafeIndex, uint _index) onlyOwner external view returns(string, string, string, uint, uint, address, bool){
        address  userAddress = registered[_cafeIndex][_index];
        Person memory user = person_list[userAddress];
        bool end = true;
        if( (_index+1) == registered[_cafeIndex].length)
            end = false;
        
        return(user.first_name, user.last_name, user.email, user.phone_number, user.code_meli, userAddress, end);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract CafeBlockChainToken is ERC20Interface, SafeMath, BlockChainEvent {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public tokenForEdit;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "BCC";
        name = "BlockChainCafe Token";
        decimals = 0;
        _totalSupply = 100000;
        balances[admin] = _totalSupply;
        emit Transfer(address(0), admin, _totalSupply);
    }
    
    event registeredInEvent(address Wallet, uint Token);
    event increasSupplyToken(uint Token);
    event getGift(address Wallet, uint Token);

    modifier checkEditToken(uint _token){
        require(tokenForEdit == _token);
        _;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(admin, tokens);
    }
    
    function registeredInMeeting(address _wallet, uint _token, uint _meetingIndex, uint _time) public onlyOwner checkKYU(_wallet) checkCost(_meetingIndex, _token, _time) notRegistered(_wallet, _meetingIndex){
        require(balances[_wallet] >= _token);
        balances[_wallet] = safeSub(balances[_wallet], _token);
        balances[admin] = safeAdd(balances[admin], _token);
        emit registeredInEvent(_wallet, _token);
        registerMeeting(_wallet, _meetingIndex);
    }
    
    function increasToken(uint _token) public onlyAdmin{
        balances[msg.sender] = safeAdd(balances[msg.sender], _token);
        emit increasSupplyToken(_token);
    }
    
    function gift(uint _meetingIndex, uint _token) onlyOwner public{
        address[] memory users = registered[_meetingIndex];
        for(uint i = 0; i < users.length; i++){
            balances[users[i]] = safeAdd(balances[users[i]], _token);
            emit getGift(users[i], _token);
        }
    }
    
    function returnToken(address _address, uint _meetingIndex, uint _token) onlyOwner public{
        for(uint i = 0; i < registered[_meetingIndex].length; i++){
            if(registered[_meetingIndex][i] == _address){
                delete registered[_meetingIndex][i];
                balances[_address] = safeAdd(balances[_address],_token);
                break;
            }
        }
        
    }

    function submitTokenForEdit(uint _token) onlyAdmin public{
        tokenForEdit = _token;
    }
    
    function getTokenForEdit(address _wallet, string _first, string _last, string _email, uint _code, uint _phone, uint _token) onlyAdmin checkEditToken(_token) public{
        require(balances[_wallet] >= _token);
        balances[_wallet] = safeSub(balances[_wallet], _token);
        balances[admin] = safeAdd(balances[admin], _token);
        
        editPerson(_wallet, _first, _last, _email, _code, _phone);
    }
}
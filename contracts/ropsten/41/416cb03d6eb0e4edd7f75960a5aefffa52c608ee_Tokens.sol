// this is basic erc20 tokens and all tokens will implement its functionality
/* Tokens   

    @author: Suraj singla */
    
pragma solidity ^0.4.25;

contract Tokens {
    address public owner; // owner of this contract
    uint256 public i;   
    address public cont; // this contract address
    
    struct nativeTokens {
        address add; // contract address of native cosh tokens
        string name; // name of native cosh tokens
        string nativeCurrency; // name of the native currency it equates to
        uint256 amount; // _initialSupply of native cosh tokens
    }
    
    mapping (uint256 => nativeTokens) public tokens; 
    // this will save all the cosh tokens (CoshBTC, CoshETH, etc.)
    
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // this is called whenever a new native cosh token is introduced.
    function setNativeTokens(address _add, string _name, string _nativeCurrency, uint256 _initialSupply) public {
        tokens[i].add = _add;
        tokens[i].name = _name;
        tokens[i].nativeCurrency = _nativeCurrency;
        tokens[i].amount = _initialSupply;
        i++;
    }
    event jV (uint256);
    // checks if the given string is a native cosh token or not
    function getTokens(string _name) public view returns (bool){
        uint256 j=1;
        while(keccak256(tokens[j].name) != keccak256("")){
            if(keccak256(_name) == keccak256(tokens[j].name)) {
                emit jV(j);
                return true;
            }
            else {
                j++;
                continue;
            }
        }
        emit jV(j);
        return false;
    }
    
    // checks if the given currency is present for exchange or not
    function getCurrency(string _name) public view returns (bool){
        uint256 j=1;
        while(keccak256(tokens[j].nativeCurrency) != keccak256("")){
            if(keccak256(_name) == keccak256(tokens[j].nativeCurrency))
                return true;
            else {
                j++;
                continue;
            }
        }
        return false;
    }
    
    // get contract address of the native cosh token
    function getAdd(string _name) public view returns (address){
        uint256 j=1;
        while(keccak256(tokens[j].name) != keccak256("")){
            if(keccak256(_name) == keccak256(tokens[j].name))
                return tokens[j].add;
            else {
                j++;
                continue;
            }
        }
        revert();
    }
    
    // returns the native currency with which the token will exchange to.
    function getTokenForCurrency(string _name) public view returns(string){
        uint256 j=1;
        while(keccak256(tokens[j].nativeCurrency) != keccak256("")){
            if(keccak256(_name) == keccak256(tokens[j].nativeCurrency))
                return tokens[j].name;
            else {
                j++;
                continue;
            }
        }
        revert();
    }
    
    // logs the token Transfer details
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // logs the approval details
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /* saves the balance of the user and the token
       example: balanceOf[user][token] = uint;
        user is user address, 
        token is the token contract address,(like contract of coshBTCH token and so) 
        uint is the amount the of the token that user has*/
    mapping(address => mapping(address => uint256)) public balanceOf;
    
    /* this shows the allowance
       example: balanceOf[user][spender][token] = uint;
        user is user address which is allowing,
        spender is the user which will spend the token
        token is the token contract address,(like contract of coshBTCH token and so) 
        uint is the amount the of the token that user has*/
    mapping(address => mapping(address => mapping(address => uint256))) public allowance;

    // when the Token is created 
    constructor () {
        owner = msg.sender; // sets msg.sender as owner
        cont = address(this);  // saves contract address
        i=1;
    }
    
    /* sets the balance of the user 
        wal is the address of the user,
        tok is the address of the native cosh token contract,
        val is the amount*/
    function setBalance(address wal, address tok, uint256 val) public {
        balanceOf[wal][tok] = val;
    }
    
    /* gets the balance of the user
        wal is the address if the user,
        tok is the address of the native cosh token contract */
    function getBalance(address wal, address tok) public returns(uint256) {
        return balanceOf[wal][tok];
    }

    // this transfer tokens from one user to another
    function transferTokens(address _from, address _to, uint256 _value) public payable returns (bool success) {
        require(balanceOf[_from][msg.sender] >= _value);

        balanceOf[_from][msg.sender] -= _value;
        balanceOf[_to][msg.sender] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    /* this Transfer tokens from user to the contract
        _from is the user which sends the tokens,
        _fromWallet if the contract address of tokens which need to be send,
        _value is the number of tokens to be send,
        msg.sender is the contract which receives the token */
    function transferProto(address _from, address _fromWallet, uint256 _value) public payable returns (bool success) {
        require(balanceOf[_from][_fromWallet] >= _value);

        balanceOf[_from][_fromWallet] -= _value;
        balanceOf[msg.sender][_fromWallet] += _value;

        emit Transfer(_from, msg.sender, _value);

        return true;
    }
    
    /* this Transfer tokens from user to the contract
        _from is the user which sends the tokens,
        _fromWallet if the contract address of tokens which need to be send,
        _to is the user which receives the tokens, 
        _value is the number of tokens to be send */
    function transferProtoEx(address _from, address _fromWallet, address _to, uint256 _value) public payable returns (bool success) {
        require(balanceOf[_from][_fromWallet] >= _value);

        balanceOf[_from][_fromWallet] -= _value;
        balanceOf[_to][_fromWallet] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    // this allow the user to approve other user to spend tokens from his account
    function approve(address _approver, address _spender, uint256 _value) public returns (bool success) {
        allowance[_approver][_spender][msg.sender] = _value;

        emit Approval(_approver, _spender, _value);

        return true;
    }

    /* this works after the approve() function, 
        the allowed user send funds from the others account*/
    function transferFrom(address _requester, address _from, address _to, uint256 _value) public payable returns (bool success) {
        require(_value <= balanceOf[_from][msg.sender]);
        require(_value <= allowance[_from][_requester][msg.sender]);

        balanceOf[_from][msg.sender] -= _value;
        balanceOf[_to][msg.sender] += _value;

        allowance[_from][_requester][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}
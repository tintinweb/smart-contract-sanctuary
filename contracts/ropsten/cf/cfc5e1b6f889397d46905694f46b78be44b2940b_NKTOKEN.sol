/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.5.13;
contract NKTOKEN
{
    string public name;                                             //name of the token
    string public symbol;                                           //symbol of the token
    uint public decimals;                                           //decimal points of token
    uint256 totalsupply;
    mapping (address => uint256) balances;                          //balnces holds the token balance of each owner account
    mapping (address => mapping (address => uint256)) allowed;      //allowed holds withdraw allowed accounts
    event Transfer (address indexed from, address indexed to, uint tokens);
    event Approval (address indexed tokenowner, address indexed spender, uint tokens);
    constructor (string memory _tokenName, string memory _tokenSymbol, uint _tokenDecimals, uint _totaltoken) public
    {
        name = "NKTOKEN";
        symbol = "NK";
        decimals = 18;
        totalsupply = 100000000000000000000000000;
        balances[msg.sender] = totalsupply;
    }
    function Totalsupply () public view returns(uint256)
    {
        return totalsupply;
    }
    //-----------------------returns current tokan balance of an account------------------//
    function balanceof(address tokenowner) public view returns (uint)
    {
        return balances[tokenowner];
    }
    //-----------------------transfer tokens to owner account to receiver account---------//
    function transfer (address receiver, uint tokensnum) public returns (bool)
    {
        require (tokensnum <= balances[msg.sender]);                //terminate if senders token balance is less than required
        balances[msg.sender] = balances[msg.sender] - tokensnum;
        balances[receiver] = balances[receiver] + tokensnum;
        emit Transfer (msg.sender, receiver, tokensnum);            //acknowledge to frontend for transfer completion
        return true;
    }
    //-----------------------provide approval to spend token from owner account-----------//
    function approve (address delegate, uint tokensnum) public returns (bool)
    {
        allowed[msg.sender][delegate] = tokensnum;                  //owner ie msg.sender approves delegate account to withdraw tokens from owner account to other account on behalf of owner
        emit Approval(msg.sender, delegate, tokensnum);             //acknowledge to frontend for approval completion
        return true;
    }
    //-----------------------get number of tokens allowed to withdraw from owner account--//
    function allowance (address owner, address delegate) public view returns (uint)
    {
        return allowed[owner][delegate];
    }
    //-----------------------transfer funds to third party account by delegate account----//
    function transferFrom (address owner, address buyer, uint tokensnum) public returns (bool)
    {
        require (tokensnum <= balances[owner]);                     //to check that owner has enough balance to send
        require (tokensnum <= allowed[owner][msg.sender]);          //to check delegate account has approval to send token to third party
        balances[owner] = balances[owner] - tokensnum;
        allowed[owner][msg.sender] = allowed [owner][msg.sender] - tokensnum;
        balances[buyer] = balances[buyer] + tokensnum;
        emit Transfer(owner, buyer, tokensnum);
        return true;
    }
}
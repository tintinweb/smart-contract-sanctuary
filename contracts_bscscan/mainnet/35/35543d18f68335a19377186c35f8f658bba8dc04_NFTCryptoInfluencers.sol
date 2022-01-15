/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity ^0.5.7;

contract ERC20  {
    
 function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance); 
    function transfer(address to, uint token) public returns (bool success);
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint token) public returns (bool success);
    function transferFrom(address from, address to, uint token) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint token);
    event Approval(address indexed tokenOwner, address indexed spender, uint token);
}


contract NFTCryptoInfluencers is ERC20 {
    
address public owner; 
address public team;
address public marketing;
uint public supply;
mapping(address => uint)balances;
mapping(address => mapping (address => uint))allowed;

string public constant name = "NFT Crypto Influencers";
string public constant symbol = "NCIS";
uint public constant decimals = 18;

uint256  _maxTxAmount = 1000000000;



constructor(address _owner) public {
    owner = _owner;
    supply = 140000000000*10**18;
    balances[owner] = supply;
}

modifier onlyAdmin () {
    require(msg.sender == owner);
    _;
}  

function totalSupply() public view returns (uint){
    return supply;
}


function balanceOf(address tokenOwner) public view returns(uint){
    return balances[tokenOwner];
}

function transfer (address to, uint token) public returns(bool){
    require (balances[msg.sender] >= token);
    balances[to]+=token;
    balances[msg.sender]-=token;
    emit Transfer (msg.sender, to, token);
    return true; 
    
}

function allowance(address tokenOwner, address spender) public view returns(uint){
    allowed[tokenOwner][spender];
}

function approve(address spender, uint token) public returns(bool){
    require(balances[msg.sender] >= token);
    allowed[msg.sender][spender] = token;
    emit Approval (msg.sender, spender, token);
    return true; 
    
}


function transferFrom (address from, address to, uint token) public returns(bool){
    require(balances[from] >= token);
    require(allowed[from][to] >= token);
    balances[from]-=token;
    balances[to]+= token;
    allowed[from][to] -= token;
    emit Transfer (from, to, token);

    return true; 
    
}

   function _getMaxTxAmount() private view returns(uint256) {
        return _maxTxAmount;
    }

  
       function _setMaxTxAmount(uint256 maxTxAmount) external onlyAdmin() {
        _maxTxAmount = maxTxAmount;
    }


     function _burn(uint256 amount) public onlyAdmin returns(bool)  {
       supply -= amount;
       return true;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}
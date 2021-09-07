/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : MAT
// Name          : MAT TOKEN
// Total supply  : 21000000000000000000000000
// Decimals      : 18
// Owner Account : 0x7B5DDe60963AAec8e480cdF5fd74D94973cc749F
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Lib: Safe Math
// ----------------------------------------------------------------------------
contract SafeMath {

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
          return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
}


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
Contract function to receive approval and execute function in one call
Borrowed from MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract MATToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "MAT";
        name = "MAT TOKEN";
        decimals = 18;
        _totalSupply = 21000000000000000000000000;
        balances[0x7B5DDe60963AAec8e480cdF5fd74D94973cc749F] = _totalSupply;
        emit Transfer(address(0), 0x7B5DDe60963AAec8e480cdF5fd74D94973cc749F, _totalSupply);
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
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
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
    // from the token owner's account
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
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}


contract PlayerFactory is MATToken{
    
    event NewPlayerBuyed(uint playerId, string name, uint adn);
     
    uint adnDigits = 16; 
    uint adnModulus = 10 ** adnDigits;
    
    struct Player{
        string name;
        uint adn; 
        uint energy;
    }
    
    Player[] public players;
    
    mapping (uint => address) public playerToOwner; 
    mapping (address => uint) ownerPlayerCount; 
    
    function _createPlayer(string _name, uint _adn) private {
        uint id = players.push(Player(_name, _adn, 1)); 
        playerToOwner[id] = msg.sender; 
        ownerPlayerCount[msg.sender]++; 
        emit NewPlayerBuyed(id, _name, _adn); 
    }
    
    function _generateRandomAdn(string _str) private view returns(uint){
        uint rand = uint(keccak256(_str)); 
        return rand % adnModulus;
    }
    
    function _buyPlayer(string _name) public{
        uint randAdn = _generateRandomAdn(_name);
        _createPlayer(_name, randAdn);
    }
    
    function getPlayersByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerPlayerCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < players.length; i++) {
      if (playerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
    
}

contract MatiInterface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
}

contract EnergyControl is PlayerFactory{
    
    //using SafeMath for uint;
    uint levelUpFee = 1 ether;
    address NumberInterfaceAddress = 0x35E7FcE9d411DacEade785A15E96943ca0EF1230;
    MatiInterface matiContract = MatiInterface(NumberInterfaceAddress);
    
    
    function getAmount(address tokenOwner) public view returns(uint){
        //uint balance = matiContract.balanceOf(tokenOwner);
        //uint balance = address(tokenOwner).balance;
        uint balance = balanceOf(tokenOwner);
        return balance;
    }
    
    function _addEnergy(uint _playerId, uint _energy) external {
        
        players[_playerId].energy = safeAdd(players[_playerId].energy, _energy);
        
        //players[_playerId].energy = players[_playerId].energy.(_energy);
    }
    
    function _removeEnergy(uint _playerId, uint _energy) external {
        players[_playerId].energy = safeSub(players[_playerId].energy, _energy);
        //players[_playerId].energy = players[_playerId].energy.safeSub(_energy);
    }
}
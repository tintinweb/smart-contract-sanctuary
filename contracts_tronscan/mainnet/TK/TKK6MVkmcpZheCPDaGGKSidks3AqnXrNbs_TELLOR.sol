//SourceUnit: TELLOR.sol

pragma solidity ^0.4.25;


// ----------------------------------------------------------------------------
// Tellor Token (TELLOR) Token
//

// Symbol         : TELLOR
// Name           : TELLOR Token
// Total supply   : 21,000
// Decimals       : 6
// Website        : https://www.tellor.io
//
// ----------------------------------------------------------------------------

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ------------------------------------------------------------------------
// TRC20 Token, with the addition of symbol, name and decimals supply and founder
// ------------------------------------------------------------------------
contract TELLOR is ITRC20{
    string public name = "TELLOR Token";
    string public symbol = "TELLOR";
    uint8 public decimals = 6;
    uint public supply;
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() public{
        supply = 21000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address owner, address spender) public view returns(uint){
        return allowed[owner][spender];
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint value) public returns(bool){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    // ------------------------------------------------------------------------
    //  Transfer tokens from the 'from' account to the 'to' account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(allowed[from][msg.sender] >= value);
        require(balances[from] >= value);

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }
    // ------------------------------------------------------------------------
    // Public function to return TELLOR supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint){
        return supply;
    }
    // ------------------------------------------------------------------------
    // Public function to return balance of TELLOR tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Public Function to transfer TELLOR tokens
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Revert function to NOT accept TRX
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
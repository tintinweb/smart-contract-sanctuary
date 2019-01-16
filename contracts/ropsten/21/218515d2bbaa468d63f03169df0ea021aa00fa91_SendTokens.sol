pragma solidity 0.5.2;

//Cheung Ka Yin
//Send multiple ERC20 tokens to multiple addresses in one transaction

interface Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

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

contract SendTokens is SafeMath{
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    /// @dev Allows sending multiple ERC20 standard token to a group of accounts.
    /// @param _targets Array of target addresses.
    /// @param _token Array of address of the target token.
    /// @param _amount Array of uint, representing the quantity of target token to send. An input of 1 represents 10**-18 tokens, if token has 18 decimal places.
    /// @return Bool the transaction was successful.
    function sendBatchTokens(address[] memory _targets, address[] memory _token, uint[] memory _amount)
        public returns (bool success)
    {
        require (msg.sender == owner);
        for (uint256 i = 0; i < _targets.length; i++){
            Token token = Token(_token[i]);
            require(token.transfer(_targets[i], _amount[i]));
            
        }
        return true;
    }
    
    //Check if sufficient token exist in contract for upcoming transfer
    function checkSufficientTokens(address[] memory _targets, address[] memory _token, uint[] memory _amount)
        public view returns (bool success)
    {
        for (uint256 i = 0; i < _token.length; i++)
        {
            Token token = Token(_token[i]);
            uint tokenBalance = token.balanceOf(address(this));
            for (uint256 j = 0; j < _targets.length; j++)
            {
                if (_token[i] == _token[j])
                {
                    tokenBalance = safeSub(tokenBalance, _amount[j]);
                }
               
            }
 
        }
    return true;
    }
}
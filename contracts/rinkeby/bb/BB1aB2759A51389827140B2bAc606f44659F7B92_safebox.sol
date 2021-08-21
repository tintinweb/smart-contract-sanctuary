/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.5.0;


contract IERC20{

    string public symbol;
    string public name;
    uint256 public totalSupply;
    uint8 public decimals;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract safebox {

    // ERC20 basic token contract being held
    IERC20 private Itoken;

    address public CEO = 0xd5AbDd579dd9dE11D1431dc5583E4f8D32593458;
    address public CTO = 0x04B3af156A56a497426047Ecf5F4bAE3f534d58F;
    uint public approveAmount;
    
    constructor (IERC20 token) public {
        Itoken = token;
    }
    
    function setCEO(address newCEO) external returns(address) {
        require(msg.sender==CEO, 'You are not authorized');
        CEO = newCEO;
        return CEO;
    }
    
    function setCTO(address newCTO) external returns(address) {
        require(msg.sender==CTO, 'You are not authorized');
        CTO = newCTO;
        return CTO;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return Itoken;
    }

    /**
     * @return this contract balance
     */
    function balance() public view returns (uint256) {
        return Itoken.balanceOf(address(this));
    }
    
    function ApproveWithdraw(uint wad) external {
        require(msg.sender==CEO, 'You are not authorized');
        
        require(balance()>=wad, 'override balance');
        
        approveAmount = approveAmount + wad;
    }
    
    function Withdraw(uint wad) external {
        require(msg.sender==CTO, 'You are not authorized');
        
        require(approveAmount>=wad, 'override approve amount');
        
        require(balance()>=wad, 'override balance');
        
        Itoken.transfer(CTO, wad);
        approveAmount = approveAmount - wad;
        
    }

}
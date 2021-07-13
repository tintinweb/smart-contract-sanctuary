/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

pragma solidity 0.5.2;

//SHIBIES TREATS AIRDROP CONTRACT
//Send TREATS to multiple addresses in one transaction

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

contract Airdrop is SafeMath{
    address public owner;
	address treats = 0x21364671fD823BBda8Ba1f40a24171DeCBdB3D54; //Shibies TREATS Polygon contract address
    constructor() public {
        owner = msg.sender;
    }
    //Check amount and send TREATS to multiple accounts
    function airdrop(address[] memory receivers, uint256[] memory amounts)
        public returns (bool success)
    {
        require (msg.sender == owner);
        uint tokenBalance = Token(treats).balanceOf(address(this));
        for (uint256 j = 0; j < receivers.length; j++)
            {
                    tokenBalance = safeSub(tokenBalance, amounts[j]*10**18);   
            }

        for (uint256 i = 0; i < receivers.length; i++)
            {
            require(Token(treats).transfer(receivers[i], amounts[i]*10**18));
            }
        return true;
    }
    }
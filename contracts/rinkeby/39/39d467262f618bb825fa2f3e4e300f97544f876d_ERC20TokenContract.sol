/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.5.1;

library safeMath{
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b<=a);
        return(a-b);
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c = a + b;
        assert(c>=a);
        return(c);
    }
}

contract ERC20TokenContract{
    using safeMath for uint256;
    string public constant name = "Base ERC20 Contract";
    string public constant symbol = "BEC";
    string public constant decimal = "18";

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 _total) public {
        totalSupply_ = _total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns(uint256){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256){
        return balances[tokenOwner];
    }

    function transfer(address _receiver, uint256 numTokens) public returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[_receiver] = balances[_receiver].add(numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns(bool){
        allowed[msg.sender][delegate] = numTokens;
        return true;
    }

    function allowance(address owner, address delegate) public view returns(uint){
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns(bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        // transfer(owner, buyer, numTokens);;
        return true;
    }
}
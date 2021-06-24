/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity 0.4.22;




contract CustomToken {

 

    event Approval(address indexed tokenOwner, address indexed spender,
        uint tokens);
    event Transfer(address indexed from, address indexed to,
        uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public TokenPrice;

    constructor(uint256 _price) public{
        TokenPrice = _price;
    }



    uint256 totalSupply_;
        constructor() public {
            totalSupply_ = 1000;
            balances[msg.sender] = totalSupply_;
        }

    function totalSupply() public view returns (uint256) {
       return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver,
            uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate,
            uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner,
            address delegate) public view returns (uint) {
       return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer,
            uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}
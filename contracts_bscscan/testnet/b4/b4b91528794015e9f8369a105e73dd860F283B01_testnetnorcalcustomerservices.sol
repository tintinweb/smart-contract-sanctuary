/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

pragma solidity ^0.4.21;

contract testnetnorcalcustomerservices {

    string public name = "testnetnorcalcustomerservices";
    string public symbol = "TSTN";

    // This code assumes decimals is zero---do not change.
    uint8 public decimals = 0;   //  DO NOT CHANGE!

    uint256 public totalSupply = 1000 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;

    function testnetnorcalcustomerservices() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    mapping(address => uint256) dividendBalanceOf;

    uint256 public dividendPerToken;

    mapping(address => uint256) dividendCreditedTo;

    function update(address account) internal {
        uint256 owed =
            dividendPerToken - dividendCreditedTo[account];
        dividendBalanceOf[account] += balanceOf[account] * owed;
        dividendCreditedTo[account] = dividendPerToken;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        update(msg.sender);  // <-- added to simple ERC20 contract
        update(to);          // <-- added to simple ERC20 contract

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        update(from);        // <-- added to simple ERC20 contract
        update(to);          // <-- added to simple ERC20 contract

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function deposit() public payable {
        dividendPerToken += msg.value / totalSupply;  // ignoring remainder
    }

    function withdraw() public {
        update(msg.sender);
        uint256 amount = dividendBalanceOf[msg.sender];
        dividendBalanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}
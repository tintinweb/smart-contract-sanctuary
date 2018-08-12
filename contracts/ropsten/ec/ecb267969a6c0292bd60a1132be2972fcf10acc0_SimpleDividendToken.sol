pragma solidity ^0.4.21;

contract SimpleDividendToken {

    string public name = "Simple Dividend Token";
    string public symbol = "SDIV";

    // This code assumes decimals is zero---do not change.
    uint8 public decimals = 0;   //  DO NOT CHANGE!

    uint256 public totalSupply = 10 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;

    function comprarSala () payable public  {
        require(msg.value == 1 ether);
        balanceOf[msg.sender] = totalSupply / 10;
        emit Transfer(address(0), msg.sender, totalSupply / 10);
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

    function transferirSala(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        update(msg.sender);  // <-- added to simple ERC20 contract
        update(to);          // <-- added to simple ERC20 contract

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferirSalaDePara(address from, address to, uint256 value)
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

    function depositarLucro() public payable {
        dividendPerToken += msg.value / totalSupply;  // ignoring remainder
    }

    function retirarDividendos() public {
        update(msg.sender);
        uint256 amount = dividendBalanceOf[msg.sender];
        dividendBalanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function aprovarUsuario(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}
pragma solidity ^0.4.21;

contract owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyowner() {
        if (msg.sender == owner) {
            _;
        }
    }
}
//This contract is a fork of the contract found in https://programtheblockchain.com/posts/2018/02/07/writing-a-simple-dividend-token-contract/
//Contract adapted to allow for the sale of rooms in a property
contract VendaDeSalas is owned {

    string public name = "Edif&#237;cio Cristiana";
    string public symbol = "SALA";

    // This code assumes decimals is zero---do not change.
    uint8 public decimals = 0;   //  DO NOT CHANGE!

    uint256 public totalSupply = 10 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;

    function comprarSala () payable public  {
        require(msg.value == 1 ether);  //Room cost is 1 ether
        require (balanceOf[msg.sender] < 1);
        balanceOf[msg.sender] = totalSupply / 10;
        emit Transfer(address(0), msg.sender, totalSupply / 10);  //Gives 1 room to buyer
    }

function destruirContrato () public payable   {
    require (msg.sender == owner);
    require (block.number > 8000000); //Only allows destruction of the contract after pre-set time by all parties
    require (dividendPerToken == 0);  //Contract can only be destructed after all dividends are paid
    selfdestruct(0x5c7AD20DC173dFa74C18E892634E1CA27E8E472F);
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

    function aprovarUsuario(address spender, uint256 value) //Allows holder of a room to assign another person to use the token in case of emergency
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}
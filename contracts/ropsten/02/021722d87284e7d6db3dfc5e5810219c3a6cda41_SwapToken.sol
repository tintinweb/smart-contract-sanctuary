pragma solidity ^0.4.17;

//import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SwapToken {
    ERC20 public ERC20Interface;
    address  tracker_0x_address = 0x58a65C1f674B3c42FBF4cF5bB92715b54A7Bd554; // ContractA Address
    mapping ( address => uint256 ) public balances;

    function deposit(address to,uint tokens) public {

    // add the deposited tokens into existing balance 
        balances[tracker_0x_address]-= tokens;
        balances[to]+= tokens;

        // transfer the tokens from the sender to this contract
        ERC20(tracker_0x_address).transfer(to, tokens);
    }

//   function returnTokens() public {
//     balances[msg.sender] = 0;
//     ERC20(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
//   }

}
/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.5.2;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

contract LogERC20 {

    event hasBeenSent(
        address sender,
        address recipient,
        string target,
        uint256 amount,
        address contractAddress
    );

    address public erc20ContractAddress;
    address public bridgeWalletAddress;

    constructor(address _erc20ContractAddress, address _bridgeWalletAddress ) public {
       erc20ContractAddress = _erc20ContractAddress;
       bridgeWalletAddress = _bridgeWalletAddress;
    }

    function logSendMemo(
        uint256 amount,
        string memory target
    ) public {
        ERC20Token token = ERC20Token(erc20ContractAddress);
        require(token.transferFrom(msg.sender, bridgeWalletAddress, amount), "ERC20 token transfer was unsuccessful");
        emit hasBeenSent(msg.sender, bridgeWalletAddress, target, amount, erc20ContractAddress);
    }
}
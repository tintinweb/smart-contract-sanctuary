pragma solidity ^0.4.24;

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

contract Wallet {
    function setMyEthBalance(address _user, uint256 _amount) public;
    function setMyTokenBalance(address _user, uint256 _amount) public;
}

contract SendContract {
    
    mapping (address => uint256) public tokenBalance; //mapping of token address
    mapping (address => uint256) public myEthBalance; // profit ethereum balance
    address public wallet_contract;
    
    constructor() public {
        
    }
    
    function () payable public {
        
    }
    
    function setWalletContractAddress(address _addr) public {
        wallet_contract = _addr;    
    }
    
    // ether transfer
    function transferETH(address _receiver, uint256 amount) public {
        _receiver.transfer(amount);
        Wallet(wallet_contract).setMyEthBalance(msg.sender, amount);
    }
    
    // transfer token
    function transferToken(address token, address _receiver, uint256 amount) public {
        ERC20(token).transfer(_receiver, amount);
        Wallet(wallet_contract).setMyTokenBalance(msg.sender, amount);
    }
}
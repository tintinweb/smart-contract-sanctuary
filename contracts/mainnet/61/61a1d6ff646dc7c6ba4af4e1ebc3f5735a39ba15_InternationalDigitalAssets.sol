/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.5.11;

contract ITokenRecipient {
  function tokenFallback(address from, uint value) public;
}

contract SafeMath {
	uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
		return x + y;
	}

	function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
	}
}

contract InternationalDigitalAssets is SafeMath {
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    
    string public name = "Digital Assets NFT";
    string public symbol = "IDA✔";
    uint8 public decimals = 18;
    uint256 public totalSupply = 80000000000000000000000000;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, uint256 value);
    
    constructor() public { balances[msg.sender] = totalSupply; }

    function isContract(address ethAddress) private view returns (bool) {
        uint length;
        assembly { length := extcodesize(ethAddress) }
        return (length > 0);
    }
    
    function transfer(address to, uint value) public returns (bool success) {
        require(value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        if(isContract(to)) {
            ITokenRecipient receiver = ITokenRecipient(to);
            receiver.tokenFallback(msg.sender, value);
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        require(value > 0);
        allowance[msg.sender][spender] = value;
        return true;
    }
    
    function transferFrom(address fromAddress, address toAddress, uint256 value) public returns (bool success) {
        require(uint256(toAddress) != 0 && value > 0);
        balances[fromAddress] = safeSub(balances[fromAddress], value);
        balances[toAddress] = safeAdd(balances[toAddress], value);
        allowance[fromAddress][msg.sender] = safeSub(allowance[fromAddress][msg.sender], value);
        emit Transfer(fromAddress, toAddress, value);
        return true;
    }
    
    function burn(uint256 value) public returns (bool success) {
        require(value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply,value); 
        emit Burn(msg.sender, value);
        return true;
    }
    
    function balanceOf(address ethAddress) public view returns (uint balance) {
        return balances[ethAddress];
    }
}
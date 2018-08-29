pragma solidity ^0.4.24;

    contract CreateEtherDevToken {
        mapping (address => uint256) public balanceOf;
        
        string public name = "EtherDev";
        string public symbol = "EDEV";
        uint8 public decimals = 18;

    uint256 public totalSupply = 10000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function SendTokens() public {
        // Initially assign all tokens to the contract&#39;s creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
	function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender&#39;s balance
        balanceOf[to] += value;          // add to recipient&#39;s balance
        emit Transfer(msg.sender, to, value);
        return true;
    }
}
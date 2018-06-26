pragma solidity ^0.4.21;

contract NationCTR {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name = &quot;Gudtest&quot;;
    string public symbol = &quot;GDTS&quot;;
    uint8 public decimals = 18;

    uint256 public totalSupply = 5000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function SimpleERC20Token() public {
        // Initially assign all tokens to the contract&#39;s creator.
        balanceOf[0x5c7AD20DC173dFa74C18E892634E1CA27E8E472F] = totalSupply;
        emit Transfer(address(0), 0x5c7AD20DC173dFa74C18E892634E1CA27E8E472F, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender&#39;s balance
        balanceOf[to] += value;          // add to recipient&#39;s balance
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}
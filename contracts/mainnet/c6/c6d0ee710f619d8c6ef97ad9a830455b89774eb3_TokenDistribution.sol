contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract TokenDistribution {
    function distribute(ERC20 token, address[] destinations, uint[] amounts) public {
        require(destinations.length == amounts.length);
        uint total;
        uint i;
        for (i = 0; i < destinations.length; i++) total += amounts[i];
        require(token.transferFrom(msg.sender, this, total));
        for (i = 0; i < destinations.length; i++) require(token.transfer(destinations[i], amounts[i]));
    }
}
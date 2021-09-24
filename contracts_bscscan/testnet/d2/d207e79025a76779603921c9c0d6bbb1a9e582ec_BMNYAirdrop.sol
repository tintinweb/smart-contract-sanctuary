/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

pragma solidity ^0.4.26;



contract BEP20 {
    function transfer(address _to, uint256 _value)public returns(bool);
    function balanceOf(address tokenOwner)public view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)public returns(bool success);

}

contract BMNYAirdrop {
    mapping(address=>bool) isBlacklisted;

      BEP20 public token;

        function BMNY(address _tokenAddr) public {
        token = BEP20(_tokenAddr);
}

  function getAirdrop() public {
      require(!isBlacklisted[msg.sender], "user already take airdrop");
      
    token.transfer(msg.sender, 20000000); //8 decimals token
    isBlacklisted[msg.sender] = true;
    
  }
}
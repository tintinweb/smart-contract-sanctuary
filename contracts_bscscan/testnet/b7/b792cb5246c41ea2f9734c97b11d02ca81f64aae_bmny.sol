/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

pragma solidity ^0.4.26;



contract BEP20 {
    function transfer(address _to, uint256 _value)public returns(bool);
    function balanceOf(address tokenOwner)public view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)public returns(bool success);

}

contract bmny {
    mapping(address=>bool) isBlacklisted;
     mapping (address => uint256) private _balances;

      BEP20 public token;
      
      function getAirdrop() public {
      require(!isBlacklisted[msg.sender], "Airdrop already received");
     
      
    token.transfer(msg.sender, 20000000); //8 decimals token
    isBlacklisted[msg.sender] = true;
    
  }

        function startAirdrop() public {
            
        token = BEP20(0xdba0344DecaCB34FD8927372826a0870B0eBe301);
}

  
}
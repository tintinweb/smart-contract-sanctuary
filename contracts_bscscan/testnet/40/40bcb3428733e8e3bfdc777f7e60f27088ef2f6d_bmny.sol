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

      BEP20 public token;
      
      function getAirdrop() public {
      require(!isBlacklisted[msg.sender], "Airdrop already received");
      
    token.transfer(msg.sender, 20000000); //8 decimals token
    isBlacklisted[msg.sender] = true;
    
  }

        function BMNY(address _tokenAddr) public {
            require(msg.sender == 0xc17EcCeb85174A6A35774bECB547d93D388E450f,"Invalid User ");
        token = BEP20(_tokenAddr);
}

  
}
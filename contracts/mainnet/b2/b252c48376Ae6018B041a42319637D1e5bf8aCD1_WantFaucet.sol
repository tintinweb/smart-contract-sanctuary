pragma solidity ^0.5.16;
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./SafeMath.sol";
contract WantFaucet is Exponential {
  using SafeMath for uint256;

  // Min time between drips 
  uint dripInterval = 200;

  address admin;
  address teamWallet; 

  address wantAddress;

  uint constant teamFactor = 0.01e18;

  constructor(address _admin, address _teamWallet, address _wantAddress) public {
    admin = _admin;
    teamWallet = _teamWallet;
    wantAddress = _wantAddress;
  }

  function setAdmin(address _admin) public {
    require(msg.sender == admin);
    admin = _admin;
  }

  function drip(uint amount) public {
    EIP20Interface want = EIP20Interface(wantAddress);
    require(msg.sender == admin, "drip(): Only admin may call this function");
    
    // Compute team amount: 1%
    (MathError err, Exp memory teamAmount) = mulExp(Exp({ mantissa: amount }), Exp({ mantissa: teamFactor }));
    require(err == MathError.NO_ERROR);
    
    // Check balance requested for withdrawal 
    require(amount.add(teamAmount.mantissa) < want.balanceOf(address(this)), "Insufficent balance for drip");
    
    // Transfer team amount
    bool success = want.transfer(teamWallet, teamAmount.mantissa); 
    require(success, "collectRewards(): Unable to send team tokens");
 
    // Transfer admin amount 
    success = want.transfer(admin, amount); 
    require(success, "collectRewards(): Unable to send admin tokens");
  }
}

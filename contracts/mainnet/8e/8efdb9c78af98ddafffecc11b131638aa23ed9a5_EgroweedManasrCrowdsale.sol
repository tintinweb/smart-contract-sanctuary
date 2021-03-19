pragma solidity 0.4.24;
//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";
import "Crowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";

contract EgroweedManasrCrowdsale is Crowdsale {

  // Min and max cap user invest
  uint256 public investorMinCap =    100000000000000000;
  uint256 public investorHardCap = 70000000000000000000;

  mapping(address => uint256) public contributions;

  constructor(uint256 _rate, address _wallet)
    Crowdsale(_rate, _wallet)
    public
  {
    
  }

  // obtener la contribucion de un e-grower en el crowdfunding
  function getUserContribution(address _beneficiary)public view returns (uint256){
    return contributions[_beneficiary];
  }
 
  // Obtener fondos
  function _forwardFunds() internal {
    super._forwardFunds();
  }
  
  // Validar los datos del e-grower, cantidad enviada y capacidad de invertir (min 0.1, maximo 700)
  function _preValidatePurchase(address _beneficiary,uint256 _weiAmount)internal{
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    // Obtener contribucion
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount); // sumar lo enviado
    //Validar los limites
    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    //Nueva contribucion
    contributions[_beneficiary] = _newContribution;
  }
}
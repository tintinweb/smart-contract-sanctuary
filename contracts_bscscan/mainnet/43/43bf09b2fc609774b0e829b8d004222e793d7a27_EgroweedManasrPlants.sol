pragma solidity 0.5.0;
import "./EGroweedNftSale.sol";

contract EgroweedManasrPlants is EGroweedNftSale {

  mapping(address => uint256) public contributions;

  constructor(address _wallet, EGroweedGenetics _geneticContractObject)
    EGroweedNftSale(_wallet, _geneticContractObject)
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
  function _preValidatePurchase(address _beneficiary,uint256 _weiAmount) internal{
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    // Obtener contribucion
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount); // sumar lo enviado
    //Nueva contribucion
    contributions[_beneficiary] = _newContribution;
  }
}
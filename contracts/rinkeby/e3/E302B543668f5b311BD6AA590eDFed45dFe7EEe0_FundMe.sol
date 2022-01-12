// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

/// Chainlink Interface ABI ///
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";
// Dans les versions inférieures à 0.8 il peut y avoir des overflow de types, on peut donc utiliser la librairie suivante pour checker pour les version < 0.8, à partir de 0.8, ça ne sert plus à rien car c'est intégré en natif !
// Cette libraire peut aussi se trouver sous OpenZeplin qui regroupe plein de contrats déjà faits !


// ou ça c'est le résultat de l'import Chainlink
/*
interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
*/
/// Chainlink Interface ABI ///


contract FundMe
{
   // On substitue le type uint256 par le type SafeMathChainlink pour TOUTES les variable déclarées de type uint256
   using SafeMathChainlink for uint256;
   
   AggregatorV3Interface public priceFeed;

  // On définit le owner du contrat à l'aide d'un constructeur qui va s'exécuter lors du déploiement du contrat
    address public owner;
    constructor(address _priceFeed) public 
    {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

   mapping(address => uint256) public map_address_to_amount_funded;

   // Un mapping ne peut pas être browsé pour qu'on puisse le resetter après un withdraw, on va donc créer un array
   address[] public ary_funders_addresses;

   
   // Payable sert à indiquer que la fonction sert à traiter un montant
   // msg.sender est l'adresse qui envoie la money et msg.value représente le montant envoyé
   // Donc lee contrat peut posséder des tokens etc.
   function fx_fund() public payable
   {
       // On définit une limite maximum d'USD à envoyer
       // Vu qu'on travaille en WEI, on doit multiplier par 10 puissance 18 donc, 1000000000000000000
       uint256 min_USD_val = 50 * 10**18;
       require(get_conversion_rate(msg.value) >= min_USD_val, 'Minimum ETH value is USD 50.-- !');

        // On peut aussi le faire comme ça
        /*
        if (get_conversion_rate(msg.value) <= min_USD_val)
        {
            revert();
        }
        */

       
       map_address_to_amount_funded[msg.sender] = map_address_to_amount_funded[msg.sender] + msg.value;

      // On ajoute le funder dans l'array
      ary_funders_addresses.push(msg.sender);

   }

   // Un modifier permet d'être appelé avant ou après l'exécution du corps d'une fonction, c'est le _; qui défini quand le corps de la fonction va être exécutée
   modifier owner_only
   {
      require(owner == msg.sender, 'Your are * NOT * the owner of contract !');
      _; // <-- Le corps de la fonction sera inséré ici, donc le MODIFIER s'exécutera AVANT
   }

   function withdraw() payable owner_only public
   {
     // On limite les retraits uniquement à l'owner du contrat
     // La ligne qui qui suit est ajoutée est ajoutée par le MODIFIER qui s'appelle OWNER_ONLY
     //// require(msg.sender == owner);

     // On envoie les tokens grâce à la fonction transfer qui est dispo pour toutes lles adresses
     // this dans ce cas fait référence à l'adresse du contrat et balance est le solde de l'adresse en ETH
     msg.sender.transfer(address(this).balance);

     // On reset lles arrays et mappings
     // On browse l'array
     for (uint256 i=0; i<ary_funders_addresses.length; i++)
     {
       // On récupère l'adresse du funder courant
       address cur_funder = ary_funders_addresses[i];
       // On met à 0 le solde du mapping pour chaque addresse
       map_address_to_amount_funded[cur_funder] = 0;
     }
     // On reset l'array
     ary_funders_addresses = new address[](0);
   }

   function get_chainlink_rates_version() public view returns (uint256)
   {
       // On instancie l'interface (comme un contrat finalement)
       return priceFeed.version();
   }

   function get_price() public view returns (uint256)
   {

      // Pour cleaner un peu le code, on peut "nullifier" les retours de variables qui nous intéressent pas
      (, int256 answer, , , ) = priceFeed.latestRoundData();
      // Pour retourner le prix en Wei
      return uint256(answer * 10000000000);
   }

   function get_decimals() public view returns(uint8)
   {
        AggregatorV3Interface int_chainlink_aggregator = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
       return int_chainlink_aggregator.decimals();
   }

   function get_conversion_rate(uint256 wei_amount) public view returns(uint256)
   {
       uint256 eth_price = get_price();
        // Conversion des ETH reçus en USD divisé par 10^18 car le prix est pour 1 ETH qui représente 1^18 WEI
        uint256 eth_to_usd_amount = (wei_amount * eth_price) / 1000000000000000000;
        return eth_to_usd_amount ;
   }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
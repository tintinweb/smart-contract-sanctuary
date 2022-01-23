// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// Cet import se fait depuis NPM
// Il y a des version 0.8 disponible mais le tuto le fait avec la version 0.6 de Solidity
import "AggregatorV3Interface.sol";

// Gestion des overflows (<0.8.0)
import "SafeMathChainlink.sol";

/**
 * Objectif créer des fonctionnalité capable d'accpter des paiements
 */
contract FundMe {
    // On applique les verifications d'overflow pour les uint256
    // Je pense qu'on ne le fait que pour un seul type car les calculs necessaires
    // peuvent couter du Gas si on les applique partout, c'est une manière d'optimiser
    // les couts en Gas
    using SafeMathChainlink for uint256;

    // Mapping servant à connaitre qui a payé combien via la fonction fund
    mapping(address => uint256) public addressToAmountFounded;

    // La liste des funders que l'on retrouve dans les clefs du mapping précédent
    address[] public funders;

    // L'adresse ayant déployé le contrat
    address public owner;

    constructor() public {
        // Dans le constructeur du contrat, on lui attribue un owner
        // pour pouvoir vérifier qui est capable de retirer les fonds du contrat
        // Le constructeur est appelé au moment ou le smart contract est déployé
        owner = msg.sender;
    }

    function fund() public payable {
        // Mettre en place un minimum pour la transaction en cours
        // On pouurait utiliser ça également pour comparer le prix de vente
        // d'un objet à son équivalent en crypto (ici la crypto en question étant ETH)
        // Ou servir de crowd funding crypto avec un minimum
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) > minimumUSD, "You need to spend more ETH!");

        // msg est une variable toujours présente où
        // - sender représente l'addresse qui a appelée cette fonction
        // - value représente le nombre d'eth/gwei/wei envoyé

        // Après l'appel de la fonction fund c'est désormais le smart contract qui est propriétaire
        // des fonds envoyés par le sender de la transaction

        addressToAmountFounded[msg.sender] += msg.value;
        funders.push(msg.sender); // on créé la liste des gens qui ont envoyé de la monnaie sur ce contrat

        // Definition d'une valeur minimale pour la transaction
        // Il est possible de définir cette limite en montant d'autres tokens ou monnaies
        // Par ex si on veut definir en USD, il faut récupérer le ration ETH/USD
    }

    function getVersion() public view returns(uint256){
        // 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e est l'adresse du contrat répondant à l'interface AggregatorV3Interface
        // sur le testnet Rinkeby (sur un autre network l'adresse sera différente)
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        // Ici encore on passe l'adresse du contrat sur le network Rinkeby
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();

        // Cet appel peut etre simplifié de cette manière
        // Ce faisant le compilateur ne nous affiche plus de warnings
        (,int256 answer,,,) = priceFeed.latestRoundData();


        return uint256(answer * 10000000000);
        // Le retour est arrondi avec 8 décimal, la somme est donc 3268.43628396 USD/ETH
        // On multiplie par 10^10 pour avoir 18 décimal comme pour le wei, ça simplifiera les calcul plus tard (surement...)
        // Le mec du tuto dit qu'il fait tout le temps comme ça, il doit avoir son expérience et ses raisons
        // donc faisons pareil
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // On divise par 10^18 parce que les prix ici sont en WEI et on les veut en ETH

        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Cannot withdraw the funds! You are not the owner of this Smart Contract!"
        );
        _;
        // Le _ sert de placeholder pour le code de la fonction qui exécutera le "modifier"
        // S'il est à la fin, le code du modifier (un simple require ici) sera executé avant le code de la fonction qui l'appelle
        // On pourrait également le placer au début pour que modifier s'exécute avant le code de la fonction qui l'appelle
    }

    function withdraw() payable onlyOwner public { // Ici on appelle le modifier que l'on a declaré juste au dessus
        // Permet à celui qui en fait la requête de recupérer le contenu en ETH du contrat
        msg.sender.transfer(address(this).balance);

        // On reset le mapping des gens qui ont participé en remettant leur compteur à 0
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFounded[funder] = 0;
        }

        // On reset également le tableau de funders
        funders = new address[](0);
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
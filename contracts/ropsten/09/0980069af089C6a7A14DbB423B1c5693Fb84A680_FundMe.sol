/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: SafeMathChainlink

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe{
    //estamos usano safemath para todas las variables uint256
    //es decir todas las variables se van a regir por este estandar 
    using SafeMathChainlink for uint256;

    //vamos a trackear a todas las personas que nos envian dinero
    mapping (address => uint256) public addressToAmountFunded;

    //crearemos un array para setear todos los valores a cero

    address[] public funders;

//cuando definimos una funcion como payable, estamos diciedo que la funcion puede ser
//usada como valor para pagar

//cuando llamamos una funcion, cada funcion tiene asociado un valor, cuando hacemos una transaccion
//le podemos asignar un valor, este valor va a ser la candtidad de wei que se va a pagar
//por esta transacccion

    //definimos la variable owner de tipo address
    address public owner;
    //dentro del constructor definimos el owner del contrato, al ser esta direccion la que 
    constructor() public{

        owner = msg.sender;

    }


    function fund() public payable{
        uint256 minimunUSD = 50 * 10**18;
        // el require se utiliza de esta manera ya que si la operacion llega a fallar
        //va a revertir la operacion

        require(getConversionRates(msg.value)>= minimunUSD, "te falta mas eth");
        //con esto vemos la cantidad de dinero enviado por la cartera en especifico
        
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed =  AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
                                                        //este es de donde recoge el precio del token
        AggregatorV3Interface price = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 amswer,,,) = price.latestRoundData();
      //cuando hay mchos datos y hay que usar una sola funcion se tiene que usar de esta manera
        return uint256(amswer * 1000000000000000000);
    }


    function getConversionRates(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethInUSD = (ethPrice * ethAmount) / 1000000000000000000;

        return ethInUSD;
    }

  // con el modifier especificamos un requermiento que queremos que haga una funcion
  //en este caso con "_;" decimos que a partir de ahi se debe seguir con la funcion correspondiente
    modifier onlyOwner {

      require ( msg.sender == owner);
      _;
    }

     function withdraw() public onlyOwner payable{

          
        // a partir de la version 8 hay que especificar el payable ya que no es 
        //default 
            //en parentesis va la direcciom que va a recibir el dinero 
            //msg.sender se refiere a la direccion que envia el dinero
         payable (msg.sender).transfer(address(this).balance);

      //con este ciclo estamos reseteando el balance de todos los que han enviado dinero
      //a la direccion del contrato una vez se llame esta funcion
         for (uint256 funderIndex = 0; funderIndex < funders.length ; funderIndex ++){
           address funder = funders[funderIndex];
           addressToAmountFunded[funder] = 0;
         }

        //esta es una manera sencilla de reiniciar el array de funders a cero
        //creando un nuevo array
         funders = new address[](0);
    } 
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256; //Dopo 0.8 non serve usare safemath
    address public owner;
    address[] internal funders;
    AggregatorV3Interface public priceFeed;

    mapping(address => uint256) public addresToAmountFunded; //in questo caso mappiamo gli address con il valore di quanto hanno versat

    constructor(address _priceFeed) public {
        //il costruttore viene inizializzato all'atto della creazione del contratto e salvare l'indirizzo del sender ( creatore del contratto) come owner fa si che egli diventi l'unico proprietario del contratto.
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //payable indica che la funzione puÃ² essere usata per "pagare" quando chiami una funzione

        uint256 minimunUSD = 50 * 10**18; // Impostiamo una soglia minima di dollari da versare quando si chiama il contratto.
        // il doppio asterisco (**) eleva a potenza
        //Stiamo elevando a potenza per usare tutto con 18 decimali ( come i wei)

        // if(mesage.value<minimunUSD)
        // {
        //     revert?
        // } Non Ã¨ programmazione pulita!!

        require(
            getConversionRate(msg.value) >= minimunUSD,
            "Devi inviare  ETH"
        );

        addresToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); //push serve ad aggiungere un nodo all'array. In questo punto, ogni volta che un contratto mi finanzia io inserisco un nuovo nodo all'array con il wallet del finanziatore
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        //per modificatore si intende una serie di proprietÃ  che possono essere applicate alla funzione a cui si aggiunge il modificatore stesso
        // potremo utilizzare _; qui, questo significherebbe che se una funzione viene chiamata con questo modifier PRIMA verrÃ  eseguito il codice della funzione e solo alla fine il modifier.
        require(
            msg.sender == owner,
            "Solo il proprietario ha l'abilitazione a ritirare i fondi"
        ); //Si intende per sender chi richiama la funzione in oggetto
        _; // l'utilizzo di _; significa che le istruzxioni nel modifier vengono eseguite PRIMA e dopo viene eseguito il codice nella funzione
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance); //transfer serve a richiamare il trasferimento di una quantitÃ  di ether al sender ( chiamante) con il verbo this si intende QUESTO CONTRATTO con balance si intende tutto il bilancio nel contratto

        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++ //Con questo for azzero tutti i saldi di chi ha fatto il finanziamento dopo aver controllato che io sono il proprietario
        ) {
            address funder = funders[fundersIndex];
            addresToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // Azzero la lista dei funders, poichÃ¨ dopo aver ritirato non ci saranno piÃ¹ funders ( opinabile come cosa, forse preferirei vedere che tizio ha donato ma attualmente la sua donazione Ã¨ a zero perchÃ¨ giÃ  ritirata.
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }

        return string(str);
    }

    function concate(string memory arr, string memory arr2)
        internal
        view
        returns (string memory)
    {
        return string(abi.encodePacked(arr, " Founder: ", arr2));
    }

    function fundersList() public view returns (string memory) {
        string memory fundersAdList = "";
        string memory temp = "";
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            temp = addressToString(funder);
            fundersAdList = concate(fundersAdList, temp);
        }
        return fundersAdList;
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
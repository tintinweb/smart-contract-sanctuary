/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT

//
//   /$$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$$   /$$$$$$
//  |_  $$_/| $$$ | $$|__  $$__/| $$__  $$ /$$__  $$
//    | $$  | $$$$| $$   | $$   | $$  \ $$| $$  \ $$
//    | $$  | $$ $$ $$   | $$   | $$$$$$$/| $$  | $$
//    | $$  | $$  $$$$   | $$   | $$__  $$| $$  | $$
//    | $$  | $$\  $$$   | $$   | $$  \ $$| $$  | $$
//   /$$$$$$| $$ \  $$   | $$   | $$  | $$|  $$$$$$/
//  |______/|__/  \__/   |__/   |__/  |__/ \______/

// Il codice di seguito, seppur compliant con lo std ERC20, contiene volutamente una serie di bachi
// e/o incompletezze da discutere nel corso dell'analisi
// Il contratto ERC20 può comunque essere deployed e i token essere scambiati su un normale wallet




// File: @openzeppelin/contracts/GSN/Context.sol
pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */


//   _        __                                _             _
//  (_)_ __  / _| ___  _ __ _ __ ___   __ _ ___(_) ___  _ __ (_)
//  | | '_ \| |_ / _ \| '__| '_ ` _ \ / _` |_  / |/ _ \| '_ \| |
//  | | | | |  _| (_) | |  | | | | | | (_| |/ /| | (_) | | | | |
//  |_|_| |_|_|  \___/|_|  |_| |_| |_|\__,_/___|_|\___/|_| |_|_|
//

// Cosa si intende? GSN = Gas Station Network. E' una repository creata per lo sviluppo di dApp decentralizzate
// in cui il gestore della piattaforma paga le tasse di una transazione al posto del suo utente.
// In pratica: io voglio interagire con uno smart contract su Ethereum (ex. comprare dei token) ma non ho ETH per
// pagare le tasse. Allo stesso tempo non voglio acquistare ETH perchè questo richiederebbe una procedure di KYC
// su una particolare piattaforma. Sarà quindi un "relayer" di questo GNS a pagare le mie tasse mentre io dovrò
// solo "firmare" il mio messaggio (ossia cifrare la transazione col mio indirizzo). Questa viene definita
// meta-transaction.
// Questa implementazione è quindi necessaria per garantire che il msg.sender sia effettivamente chi ha intenzione di interagire
// col contratto e non chi è solo un "relayer".

// Maggiori info su GNS su: https://docs.openzeppelin.com/learn/sending-gasless-transactions
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//       _       _                _
//      (_)     | |              (_)
//   ___ _ _ __ | |_ __ _ ___ ___ _
//  / __| | '_ \| __/ _` / __/ __| |
//  \__ \ | | | | || (_| \__ \__ \ |
//  |___/_|_| |_|\__\__,_|___/___/_|
//

// - abstract -
// Solitamente sono contratti in cui almeno una delle funzioni non ha corpo {}
// Anche se un contratto ha tutte le funzioni implementate, può essere definito abstract.
// Questo farà si che non si potrà fare il deployment del contratto
// I contratti astratti sono molto utili a definire lo "scheletro" del nostro contratto principale
// come contenessero un template valido nel resto del contratto (ovviamente ereditandolo)
// NB. Se eredito un contratto in cui le funzioni non hanno corpo, dovrò sovrascrivere (override)
// le stesse definendone un corpo oppure anche il mio contratto figlio sarò astratto.

// - contract -
// Definisce il corpo del contratto vero e proprio

// - function -
// Definisce una funzione che potrà avere degli input e potrò restituire degli output
// E' seguita dal nome della funzione e () all'interno delle quali sono eventualmente contenuti gli input e il loro tipo

// - internal -
// Le funzioni internal potranno essere richiamate solo all'interno dello stesso contratto (anche dai figli)
// Sono le più economiche dato che saranno utilizzate solo all'interno del contratto tramite JUMP
// ma ciò significa anche che quanto in esse, occuperà uno slot di memoria durante l'interazione.

// - view -
// Promette di non modificare lo stato della EVM (ma esclusivamente di essere visibile)
// La funzione quindi resituisce un output che può essere solo visualizzato dall'utente (read only su file PC)

// - virtual -
// Sono funzioni che potranno (devono) essere ereditate nel contratto figlio (tramite override)
// Il contratto figlio quindi conterra la stessa funzione con un corpo alternativo che ne definirà
// il nuovo comportamento. Aspetti importanti da considerare:
// - Tutte le funzioni di interfaccia (vedi blocco successivo) sono automaticamente virtual
// - Una funzione privata (vedi dopo) non può essere virtual
// - Attenzione alle funzioni virtual lasciate "scoperte" nel contratto figlio

// - returns -
// Definisce gli output della funzione.
// E' anche esso seguito da () contenenti gli output e il loro tipo



//    __                 _             _
//   / _|               (_)           (_)
//  | |_ _   _ _ __  _____  ___  _ __  _
//  |  _| | | | '_ \|_  / |/ _ \| '_ \| |
//  | | | |_| | | | |/ /| | (_) | | | | |
//  |_|  \__,_|_| |_/___|_|\___/|_| |_|_|
//

// Come visto le funzioni possono essere di diverso tipo. Riepiloghiamo:

// - internal -
// Le funzioni internal potranno essere richiamate solo all'interno dello stesso contratto (anche dai figli)
// Sono le più economiche dato che saranno utilizzate solo all'interno del contratto tramite JUMP
// ma ciò significa anche che quanto in esse, occuperà uno slot di memoria durante l'interazione.

// - external -
// Sono funzioni che idealmente verranno utilizzate solo all'esterno del contratto
// Possono anche essere richiamate all'interno con una particolare sintassi (this.f()) ma non perchè
// assolutamente consigliato dato che si raggiunge lo stesso obiettivo risparmiando gas con una funzione internal.
// Si consiglia di usare external ogni qual volta ci si aspetta che una funzione debba essere chiamata
// solo all'esterno dato che è il costo di gas sarà circa la metà (questo perchè non viene allocato alcuno slot di memoria per l'utilizzo della funzione)

// - public -
// Come dice il termine, è una funzione pubblica, accessibile quindi sia all'interno che all'esterno.
// Può essere considerata un unione di internal + external.
// Sebbene svolga lo stesso ruolo di una funzione external, ha un maggiore consumo di gas dato che, non sapendo se la funzione
// verrà chiamata internamente o esternamente, il contratto allocherà preventivamente dello spazio in memoria.
// Questo discorso sul dispendio di gas, si applica ovviamente per funzioni con determinati input dato che
// qualora la funzione non abbia input, non ci sarà nulla da allocare in memoria.

// - private -
// Sono funzioni che potranno essere utilizzate solo dal contratto in cui sono contenute (non dai figli ereditari)




//    _____       _             __
//   |_   _|     | |           / _|
//     | |  _ __ | |_ ___ _ __| |_ __ _  ___ ___  ___
//     | | | '_ \| __/ _ \ '__|  _/ _` |/ __/ _ \/ __|
//    _| |_| | | | ||  __/ |  | || (_| | (_|  __/\__ \
//   |_____|_| |_|\__\___|_|  |_| \__,_|\___\___||___/
//

// Sono vere e proprie "interfacce utente". Sono molto simili ai contratti abstract, ma con queste peculiaritò
// - Le funzioni al loro interno sono possono essere implementate (non devono avere corpo) e possono essere solo external
// - Non possono avere variabili o constructors
// In sostanza non contengono informazioni di alcun tipo che possano modificare lo stato della macchina.
// Quindi convertendo una interface in ABI non vi è alcuna perdita di informazioni.

// Essando quindi simili ai contratti abstract, come scegliere quale usare?
// Gli abstract sono dei veri a propri contratti quindi al loro interno possono avere un contenuto importante
// che faccia da scheletro al mio contratto.
// Le interfaces invece sono puramente "estetiche"  e tornano utili quando voglio semplicemente ampliare l'utilizzo del mio contratto
//  Ad esempio, se voglio integrare nel mio contratto alcune funzioni di Uniswap o chi per esso, definirò un'interfaccia che richiami
//  le funzioni di Uniswap senza definire in esse alcun corpo dato che sono già definite nel contratto origine.

// - indexed -
// Permette di indicizzare la variabile in questione. Ciò vuol dire che in futuro, cercando ad esempio l'evento transfer
// sulla blockchain, di potranno filtrare i risultati per "from", "to" (essendo indicizzati), ma non per "value".

pragma solidity ^0.7.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



//    _ _ _                    _
//   | (_) |                  (_)
//   | |_| |__  _ __ __ _ _ __ _  ___  ___
//   | | | '_ \| '__/ _` | '__| |/ _ \/ __|
//   | | | |_) | | | (_| | |  | |  __/\__ \
//   |_|_|_.__/|_|  \__,_|_|  |_|\___||___/
//

// Sono dei veri e propri contratti di cui si può fare il deployment su Ethereum e che definiscono degli elementi (funzioni o altro)
// che potranno essere chiamate e utilizzate da altri contratti (esattamente come le librerie software)
// - Sono molto utili per definire parti di codice utilizzate da diversi contratti e quindi in comune
// - Sono molto economiche in termini di gas dato che implicitamente effettuano il deployment una sola volta (e sono poi riutilizzate dai vari contratti)
//   Se definissi gli elementi della library in un normale contratto da ereditare poi nei successivi, il dispendio sarebbe maggiore dato che
//   l'ereditarietà in Solidity funziona come un copy/paste tra contratti

// Hanno tuttavia delle limitazioni, essendo più economiche
// - Se contengono state variables, devono essere per forza costanti (dato che non viene allocata memoria per le libraries)
// - Non possono gestire ETH, quindi non può contenere funzioni payable
// - Non può utilizzare inheritance in entrambi i sensi
// - Non può essere distrutta tramite selfdestruct()


// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity ^0.7.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.7.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





//               ,.          (.   ((
//                 * ,*      /(.  (#(...
//                   (,  /# ,///%((##,*(//*/(
//                     %(/  (/%%#/,(#,,*/(##((/
//                       #%*.(,   .   .(#&%%#(((/                                ,**          ***                   ****
//                      ,.     @*#.    .(*/(((/(#(/                              ,**          ***
//                    ..       /&%     ....%(*(#((#/                             ,**          ***    **.********     **.    *********    ***    .***     ***    **********    *** ********
//                   ,               .....,//%/#((((                             ,**          ***    ***      ***   .**.   ***           .**    **.**   .**.            **,   ****      ***
//                 *(/.            ....,,,...#(*(###                             ,**          ***    **,      ***    **.    *******,      ***  **, ***  ***      **********   ***        **,
//               ,(((((/............,,,*/,.. ..#/(#(                             ,**,        .***    **,      ***   .**.           ***     ***.**   **.***     ***      ***   ***       ,**.
//               ((@//((((/,,,,****/(##,..   ..(*/((                              .****    ****,     **,      ***    **.   ***     ***      ****     ****      ***    .****   *****    ***.
//                (#((((###/        %(*,,....*(,/*#(                                  ******         **,      ***   .**.     ,*****.        ,**.     ,**.        *****  ***   ***  ,****
//                   *,              %(/*,,,.                                                                                                                                 ***
//                                     .                                                                                                                                      ***
//

// Uniswap Router interface

// Come visto prima, interface permette di richiamare un contratto già rilasciato sul net (di cui si fornirà l'indirizzo) e crearne
// l'interfaccia all'interno del nostro contratto.
// La documentazione specifica sulle funzioni uniswap è disponibile su:
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
// Uniswap Factory interface
interface IUniswapV2Pair {
    function sync() external;
}




//
//  $$\      $$\ $$\     $$\       $$$$$$$$\ $$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\
//  $$$\    $$$ |\$$\   $$  |      $$  _____|$$  __$$\ $$  __$$\ $$  __$$\ $$$ __$$\
//  $$$$\  $$$$ | \$$\ $$  /       $$ |      $$ |  $$ |$$ /  \__|\__/  $$ |$$$$\ $$ |
//  $$\$$\$$ $$ |  \$$$$  /$$$$$$\ $$$$$\    $$$$$$$  |$$ |       $$$$$$  |$$\$$\$$ |
//  $$ \$$$  $$ |   \$$  / \______|$$  __|   $$  __$$< $$ |      $$  ____/ $$ \$$$$ |
//  $$ |\$  /$$ |    $$ |          $$ |      $$ |  $$ |$$ |  $$\ $$ |      $$ |\$$$ |
//  $$ | \_/ $$ |    $$ |          $$$$$$$$\ $$ |  $$ |\$$$$$$  |$$$$$$$$\ \$$$$$$  /
//  \__|     \__|    \__|          \________|\__|  \__| \______/ \________| \______/


// L'ultimo contratto solitamente sarà quello di cui si farà il deployment
// MYERC20 eredita tutto ciò che è stato definito in Context così come anche l'interfaccia IERC20
// In questo semplice caso, essendo un solo contratto, l'interfaccia sarebbe potuta essere risparmiata
// in modo da salvare gas al deployment.
// Torna utile invece nel caso di contratti più complessi dove ognuno potrà magari ereditare
// esclusivamente l'interfaccia ma non i precedenti contratti

// Inoltre vengono usate le librerie SafeMath e Address per la gestione dei numeri e degli indirizzi



pragma solidity ^0.7.0;

contract MYERC20Uni is Context, IERC20, Ownable {

    //Sintassi necessaria per l'utilizzo di librerie
    using SafeMath for uint256;
    using Address for address;

    // - Mappings -
    // Sono delle tabelle (criptate) che associano a valori della prima colonna valori di una seconda colonna in modo univoco
    // Da immaginare come una tabella Excel il cui passaggio tra colonne contiene una funzione hash
    // Molto importante il fatto che non richiedano una predefinizione della dimensione ma saranno popolate e depopolate a seconda della necessità
    // Assumiamo di mappare degli indirizzi con un ID
    //      mapping(address => uint) public userLevel;
    // Potrò successivamente accedere all'indirizzo desiderato richiamando esclusivamente l'ID
    //      function currentLevel(address userAddress) public constant returns (uint) {
    //           return userLevel[userAddress];
    //      }
    // A livello di codice, la documentazione di Solidity riporta che i mappings sono inizializzati virtualmente in modo che
    // ogni possibile chiave esista e sia associata a un valore la cui rappresentazione byte sia tutto 0

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private initialSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Variabili che conterranno gli indirizzi dei contratti Uniswap
    address public uniswapV2Router;
    address public uniswapV2Pair;
    
    event LockLiquidity(uint256 tokenAmount, uint256 ethAmount);

    // Warning
    // La variabile initialSupply potrebbe ad esempio essere inclusa come input del constructor
    // La scelta è dell'utente in base alle necessità ma le due varianti comportano anche una differenza di spesa di gas
    // Inserire un ulteriore input del contratto infatti aumenta il costo del deployment dovendo gestire una ulteriore variabile
    constructor (string memory name_constr, string memory symbol_constr) {
        _name = name_constr;
        _symbol = symbol_constr;
        _decimals = 0;
        initialSupply = 10000;
        _mint(_msgSender(), initialSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // - override -
    // Necessaria quando si indica una funzione dello stesso nome di una indicata in un contratto padre.
    // La funzione del contratto padre dovrà necessariamente contenere il modificatore virtual
    // Se più padri contengono una funzione uguale virtual, il figlio dovrà indicare quale padre andrà a sovrascrivere con override(Padre1,Padre2,Padre3...)
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Il check affinchè lo spender possa spendere è contenuto nella funzione _approve.
    // Se infatti la condizione sull'approve fallisce, l'intera funzione non viene eseguita restituendo f

    // Nota su SafeMath. Come si vede viene utilizzata la libreria prima definita.
    // Si potrebbe benissimo usare + con un require ma, oltre a essere più dispendioso a livello di gas, non conterrebbe la gestione delle eccezioni prima viste.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    //Warning - approve
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    // Tutte funzioni internal virtual in origine
    // Questo perchè questo contratto ERC20 è un contratto base che può essere ereditato e modificato a seconda delle necessità
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    //function _burn(address account, uint256 amount) private {
    //    require(account != address(0), "ERC20: burn from the zero address");
    //
    //    _beforeTokenTransfer(account, address(0), amount);
    //
    //    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    //    _totalSupply = _totalSupply.sub(amount);
    //    emit Transfer(account, address(0), amount);
    //}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    // Funzione estremamente utile per gestire il particolare comportamento di un token prima che esso sia trasferito tramite una seconda funzione qualsiasi.
    function _beforeTokenTransfer(address from, address to, uint256 amount) private { }


    // Funzioni che permettono di settare gli indirizzi Uniswap necessari
    function setUniswapV2Router(address _uniswapV2Router) public onlyOwner {
        require(uniswapV2Router == address(0), "uniswapV2Router already set");
        uniswapV2Router = _uniswapV2Router;
    }
    function setUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        require(uniswapV2Pair == address(0), "uniswapV2Pair already set");
        uniswapV2Pair = _uniswapV2Pair;
    }




    // receive eth from uniswap swap
    receive () external payable {}

    // Locks liquidity to contract address and sends it to Uniswap Roueter
    function lockLiquidity(uint256 _lockableSupply) private {
        // lockable supply is the token balance of this contract
        require(_lockableSupply <= balanceOf(address(this)), "Requested lock amount higher than lockable balance");
        require(_lockableSupply != 0, "Lock amount cannot be 0");
        // Loackable supply is stored on contract address - Lockable supply is split 50/50 and the half is converted to WETH
        _lockableSupply = balanceOf(address(this));
        uint256 amountToSwapForEth = _lockableSupply.div(2);
        uint256 amountToAddLiquidity = _lockableSupply.sub(amountToSwapForEth);
        // Needed in case contract already owns eth
        uint256 ethBalanceBeforeSwap = address(this).balance;
        swapTokensForEth(amountToSwapForEth);
        uint256 ethReceived = address(this).balance.sub(ethBalanceBeforeSwap);
        // Add liquidity to Uniswap
        addLiquidity(amountToAddLiquidity, ethReceived);
        emit LockLiquidity(amountToAddLiquidity, ethReceived);
    }

    // External util so anyone can provide locked liqudiity to Uniswap
    function provideLiquidityToRouter() external {
        // lock everything that is lockable
        lockLiquidity(balanceOf(address(this)));
    }
    // From Uniswap Router - Swap tokens for WETH
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = address(this);
        uniswapPairPath[1] = IUniswapV2Router02(uniswapV2Router).WETH();
        _approve(address(this), uniswapV2Router, tokenAmount);
        IUniswapV2Router02(uniswapV2Router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                uniswapPairPath,
                address(this),
                block.timestamp
            );
    }
    // Adds liquidity to Uniswap
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), uniswapV2Router, tokenAmount);
        IUniswapV2Router02(uniswapV2Router)
            .addLiquidityETH
            {value:ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
    }
    // Returns lockagle supply stored on contract address (in ERC20 Tokens)
    function lockableSupply() external view returns (uint256) {
        return balanceOf(address(this));
    }
    // Returns the locked supply in Tokens
    function lockedSupply() public view returns (uint256) {
        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        return uniswapBalance;
    }
}






//                   _         _
//                  | |       | |
//   _ __   _____  _| |_   ___| |_ ___ _ __  ___
//  | '_ \ / _ \ \/ / __| / __| __/ _ \ '_ \/ __|
//  | | | |  __/>  <| |_  \__ \ ||  __/ |_) \__ \
//  |_| |_|\___/_/\_\\__| |___/\__\___| .__/|___/
//                                    | |
//                                    |_|
//

// - ECR20 mintable nel dettaglio
// - ECR20 burnable
// - ECR20 capped
// - Definizione owner
// - Gestione ruoli
// - Token recover
// - Staking, rewords, referrals
// - Interfaccia Uniswap
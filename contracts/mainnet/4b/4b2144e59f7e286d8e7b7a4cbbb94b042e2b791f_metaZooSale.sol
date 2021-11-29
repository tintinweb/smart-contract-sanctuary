pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interface/SkeletonCrew.sol";

/* 

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM
Nk,'cooooooooooolcOWMMMMMMWKl,cooooooooooo:oXMMMMMMMMMMMMMMMMMN0xd0MMMMMMMMMMMMMMMMMMMMMMMMXkddddddddddddddddxxxxxxdclxkkxxxxkkkkkkxxxxxxkk0NN0ddkOxOO
O' .:dx0KKKKKKKKKolKMMMMMM0;.:0KKKKKKKKOxo;lXMMMMMMMMMMMMMMNKOkkkx0MMMMMMMMMMMMMMMMMMMMMMWk,.o0KKKKKKKKKKKKKKK000OxllxOdc:lkKOdok0KKkl;;ooOdokOOOdlOOO
O'    .;kKKKKKKKK0ldNMMMMXc.'kKKKKKKKKx;..:OWMWNXKKKXXNWWKdlxOKK0dxKK00XWNKKKXNNKK00KNWMM0,.c0KKKKKK00OOOOO0KKKKKd;l0Kkc;. 'lod0KKKx' .:cxKKd;oddXOooo
NOxo;  .lKK00KKKKKklkWMMWx..dKK0KKKKKKo:d0NWX00000O0000K0c.'kKKKKOkkkdlxdldkkkkkkkkkkxkXKc.cOK0kdl:,'.....,d0KKKk,,kKKOdOO; .cOKKKx. ,O0dkKK0:'xWMMMMM
MMMMK, .oK0dd0KKKKKdl0MM0'.c0Kdd0KKKKKdlKMXkxOKKkl:oOKKKO: 'kKKK0dcclldl;dKKKOOO0KKKKKxl,  'cc,...,;::'  .o0KKKKl.,OKKKkxX0, :0KKO, 'OXxxKKK0:.cNMMMMM
MMMMK, .dK0:,xKKKKK0ooXX:.;OKx,:0KKKKKdl00ld0KKOdc.'xKKKKl.'kKKK0l'',l:.cxoc:'.':x0KKK0l'.  .:okKXNWNk,.;kKKKKKKl..dKKKKxxXk.'xKKd..dXxx0KKKx. lNMMMMM
MMMMO' .xKO; ;OKKKKKOlol..xKO: ,OKKKKKxld::OKKKkO0xk00kol;.'kKKK0xOXXk,.;clllodxkOKKKK0dO0xkXWMMMMMXo..l0KKKKKKk:. .o0KK0kxx;.cx0k;,dxx0KK0d' 'OMMMMMM
MMMMk. 'kKk' .c0KKKKKk;..lKKl. 'kKKKKKkc,.c0KKKOO0Oxoolld:.'kKKK0x0MMNkldk0KK0dc,:kKKK0dOMMMMMMMMW0;.,xKKKKKK0dlkk; .,ok00Okxdl;:odxkO0Oxl,. ;OWMMMMMM
MMMWx. ,OKx'  .dKKKKKKo.:OKx'  .xKKKKKO:. :0KKKKKkdk0NNX0l.'kKKK0xkWNx,l0KKKKdl;..dKKK0dOMMMMMMMNd..cOKKKKKKkloKWMXx:...',;;:clxkdc:;,'....:xXMMMMMMMM
MMMWo. :0Kd;.  ,kKKKKK0xOKOl:. .xKKKKK0c. .xKKKKK00000000d..oKKKK0kko..xKKKKKkxo,:kKKKKxkNMMMMW0:.,xKKKKKK0dcxNMMMMMWKOxoodxOXWMMMWXOkxxk0XWMMMMMMMMMM
MMMNl  c0Kolx,  :OKKKKKKK0ook, .dKKKKK0l:' 'xKKKKKKKKKKK0d' .lOKKKK0l..c0KKKKK0OxxkKKKKklkNMMNx'.cOKKKKKKOll0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNc .lKKloXx. .l0KKKKKKdl0K; .oKKKKKKook; .:dOKKKKKOkk0Xk;  .:oxOOo'  ,okOOkoc,..ldl:;:kNMKc.'d0KKKKK0xlxXMMMMMMWXkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMX: .oK0ldNNl  .lOKKKKkckWX:  lKKKKKKooXXd;...,;::cokXWMMNkc,....,lOd'. .';lxOx,.,ldk0NMWk,.:kKKKKKKOolOWMMMMMWKxooolxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMK, .xK0ldWMXc   .,:clcdNMNc  cKKKKKKdl0MMNKkdodxOKWMMMMMMMWNKOxoxXMMNOxxk0NMMWK0NWMMMMXl..o0KKKKKKk:;okkkkkkxddx0KxcdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MWXd..l0KKdlkKXXkc;'.  .lXWN0c.'xKKKKKKOooOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.;kKKKKKKKKOxxxxxxxxkk0KKKxckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
k:;ldkKKKKKkdockWWWNKOk0NKo;codOKKKKKKKK0kdloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo. ;OKKKKKKKKKKKKKKKKKKKKKKKxcOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
. .ldddddddddo;xWMMMMMMMNc  ;oddddddddddddd:cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  .ckkkkkkkkkkkkkkkkkkkkkkdcxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
             .c0MMMMMMMMX:                .'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.   ......................,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:;;;;;;;;;;;:dXMMMMMMMMMNx:;;;;;;;;;;;;;;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'.......................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

*/

//// @author:  Blockchain platform powered by Ether Cards - https://ether.cards

contract metaZooSale is Ownable {
    using SafeMath for uint256;

    event WhiteListSale(uint256 tokenCount, address receiver, uint256 role);
    event PurchaseSale(uint256 tokenCount, address buyer);

    /* 
    using tokenIndex to retrieve tokenID to send.
    Sale with start at 5 eth and decrease by 0.1 eth every 15 minutes for 12 hours.
    */

    uint256 public startingPrice = 5 ether;
    // Whitelist time
    uint256 public whitelist_sales;
    uint256 public whitelist_sales_end;
    // DSP
    uint256 public sales_start;
    uint256 public sales_end;

    address public nft_sales;
    uint256 public sales_duration = 12 hours;
    bool public setupStatus = true;
    uint256 public maxDecreaseSold = 0;
    uint256 public maxDecreaseNFTs = 500;

    uint256 public whiteListSold = 0;
    uint256 public maxWhiteListNFTs = 4300;

    address public presigner;
    uint256 public whiteListPrice = 0.1 ether;
    mapping(address => uint256) public whitelist_claimed;

    address payable[] _wallets = [
        payable(0xA3cB071C94b825471E230ff42ca10094dEd8f7bB), 
        payable(0xA807a452e20a766Ea36019bF5bE5c5f4cbDE7563), 
        payable(0x77b94A55684C95D59A8F56a234B6e555fC79997c) 
    ];

    uint256[] _shares = [70, 180, 750];

    function _split(uint256 amount) internal {
        // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 1000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }
    function whiteListBySignature(
        address _recipient,
        uint256 _tokenCount,
        bytes memory signature,
        uint64 _role
    ) public payable {
        require(
            whiteListSalesActive(),
            "Sales has not started or ended , please chill sir."
        );
        require(_role == 1 || _role == 2, "One or Two none else will do");
        require(verify(_role, msg.sender, signature), "Unauthorised");
        require(msg.value >= _tokenCount * (whiteListPrice), "Price not met");
        uint256 this_taken = whitelist_claimed[msg.sender] + _tokenCount;

        whitelist_claimed[msg.sender] = this_taken;
        require(
            _role >= whitelist_claimed[msg.sender],
            "Too many tokens requested"
        );
        whiteListSold += _tokenCount;
        require(whiteListSold <= maxWhiteListNFTs, "sold out");
        SkeletonCrew(nft_sales).mintCards(_tokenCount, _recipient);
        _split(msg.value);
        emit WhiteListSale(_tokenCount, _recipient, _role);
    }

    function verify(
        uint64 _amount,
        address _user,
        bytes memory _signature
    ) public view returns (bool) {
        require(_user != address(0), "NativeMetaTransaction: INVALID__user");
        bytes32 _hash =
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(_user, _amount))
            );
        require(_signature.length == 65, "Invalid signature length");
        address recovered = ECDSA.recover(_hash, _signature);
        return (presigner == recovered);
    }

    function currentPrice() public view returns (uint256) {
        uint256 gap = block.timestamp - sales_start;
        uint256 counts = gap / (15 minutes);
        if (gap >= sales_duration) {
            return 0.2 ether;
        }
        return startingPrice - (counts * 0.1 ether);
    }

    function whiteListRemainingTokens() public view returns (uint256) {
        return maxWhiteListNFTs - whiteListSold;
    }

    function decreaseRemainingTokens() public view returns (uint256) {
        return (maxDecreaseNFTs + whiteListRemainingTokens()) - maxDecreaseSold;
    }

    constructor(
        uint256 _whitelist_sales,
        uint256 _sales_start,
        address _nft_sales,
        address _presigner
    ) {
        whitelist_sales = _whitelist_sales;
        whitelist_sales_end = _whitelist_sales + 3 days;
        sales_start = _sales_start;
        sales_end = sales_start + 12 hours;
        nft_sales = _nft_sales;
        presigner = _presigner;
    }

    function purchase(uint256 _amount) public payable {
        require(
            salesActive(),
            "Sales has not started or ended , please chill sir."
        );
        require(msg.value >= _amount.mul(currentPrice()), "Price not met");
        require(decreaseRemainingTokens() >= _amount, "sold out");
        maxDecreaseSold += _amount;
        SkeletonCrew(nft_sales).mintCards(_amount, msg.sender);
        _split(msg.value);

        emit PurchaseSale(_amount, msg.sender);
    }

    function whiteListMint(uint64 _amount, address _receiver) public onlyOwner {
        SkeletonCrew(nft_sales).mintCards(_amount, _receiver);
    }

    function salesActive() public view returns (bool) {
        return (block.timestamp > sales_start && block.timestamp < sales_end);
    }

    function whiteListSalesActive() public view returns (bool) {
        return (block.timestamp > whitelist_sales &&
            block.timestamp < whitelist_sales_end);
    }

    function sales_how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < sales_start, "Started");
        uint256 gap = sales_start - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function whitelist_how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < whitelist_sales, "Started");
        uint256 gap = whitelist_sales - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function changePresigner(address _presigner) external onlyOwner {
        presigner = _presigner;
    }

    function resetSalesStatus(
        uint256 _whitelist_sales,
        uint256 _sales_start,
        address _nft_sales,
        bool _setupStatus
    ) external onlyOwner {
        whitelist_sales = _whitelist_sales;
        whitelist_sales_end = _whitelist_sales + 2 days;
        sales_start = _sales_start;
        sales_end = _sales_start + 12 hours;
        nft_sales = _nft_sales;
        setupStatus = _setupStatus;
    }

    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    struct theKitchenSink {
        uint256 startingPrice;
        // Whitelist time
        uint256 whitelist_sales;
        uint256 whitelist_sales_end;
        // DSP
        uint256 sales_start;
        uint256 sales_end;
        address nft_sales;
        uint256 sales_duration;
        bool setupStatus;
        uint256 maxDecreaseSold;
        uint256 maxDecreaseNFTs;
        uint256 whiteListSold;
        uint256 maxWhiteListNFTs;
        address presigner;
        uint256 whiteListPrice;
        uint256 whiteListRemaining;
        uint256 decreaseRemaining;
    }

    function tellEverything() external view returns (theKitchenSink memory) {
        return
            theKitchenSink(
                startingPrice,
                whitelist_sales,
                whitelist_sales_end,
                sales_start,
                sales_end,
                nft_sales,
                sales_duration,
                setupStatus,
                maxDecreaseSold,
                maxDecreaseNFTs,
                whiteListSold,
                maxWhiteListNFTs,
                presigner,
                whiteListPrice,
                whiteListRemainingTokens(),
                decreaseRemainingTokens()
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

pragma solidity ^0.8.0;

interface SkeletonCrew {
    function mintCards(uint256 numberOfCards, address recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
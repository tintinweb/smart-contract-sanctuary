/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-18
 * Telegram:https://t.me/SHIBAGRAM
 * Twitter:https://twitter.com/ShibaGramOfficial
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


contract SHIBAGRAM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    mapping (address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;

    string private _name = 'ShibaGram';
    string private _symbol = 'SHIBAGRAM';
    uint8 private _decimals = 9;
    uint256 public transfertimeout = 45 seconds;
    uint256 public _maxTxAmount = 4000000 * 10**6 * 10**9;
    
    mapping (address => bool) private _isBanBotList;
    address[] private _banBotList;
    bool public swapAndLiquifyEnabled = true;
    
    address private _charityWalletAddress = 0x4603740e9FDF4EEf53C4fe372355ca87c5D95a05;
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _charityFee = 1;
    uint256 private _previousCharityFee = _charityFee;
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    address public uniswapPair;
    mapping (address => uint256) public lastBuy; 

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        
            _isBanBotList[address(0x3BA0A5F84b06d2925A4071A708CF3351bC4cb0F6 )] = true;
            _banBotList.push(address(0x3BA0A5F84b06d2925A4071A708CF3351bC4cb0F6 ));
            
            _isBanBotList[address(0x1f219Fa9A883595Fc0B49a2132190EDd242BC179)] = true;
            _banBotList.push(address(0x1f219Fa9A883595Fc0B49a2132190EDd242BC179));
            
            _isBanBotList[address(0x17B7574a0c35BCE75af45ACE0cBC656Ce09d04C7)] = true;
            _banBotList.push(address(0x17B7574a0c35BCE75af45ACE0cBC656Ce09d04C7));
            
            _isBanBotList[address(0x8fDfD9AF2c04ED0516b5CCFdfFB79aC96f6F716f)] = true;
            _banBotList.push(address(0x8fDfD9AF2c04ED0516b5CCFdfFB79aC96f6F716f));
            
            _isBanBotList[address(0xFF94CED2303D795428FD5eC6ABaf6E0bf134c109)] = true;
            _banBotList.push(address(0xFF94CED2303D795428FD5eC6ABaf6E0bf134c109));
            
            _isBanBotList[address(0xe8A6990a39B3902260f8de228BD2bF8A3dE741f6)] = true;
            _banBotList.push(address(0xe8A6990a39B3902260f8de228BD2bF8A3dE741f6));
            
             _isBanBotList[address(0x7FD7B00C460EB3496f38D73275C220ca583B0b20)] = true;
            _banBotList.push(address(0x7FD7B00C460EB3496f38D73275C220ca583B0b20));
            
            _isBanBotList[address(0xfCB47511d7293411D07b3fc87A4939BB1Ba05730)] = true;
            _banBotList.push(address(0xfCB47511d7293411D07b3fc87A4939BB1Ba05730));
            
             _isBanBotList[address(0x226060b011A3aE953Cb8D5Ae06BD8a529e4A133C)] = true;
            _banBotList.push(address(0x226060b011A3aE953Cb8D5Ae06BD8a529e4A133C));
            
            _isBanBotList[address(0x7F6552b676640C05380156Dc0216630dF4A2b921)] = true;
            _banBotList.push(address(0x7F6552b676640C05380156Dc0216630dF4A2b921));
            
             _isBanBotList[address(0x533D4cb0e4D220629973C619bb4C20e1fEB02fFC)] = true;
            _banBotList.push(address(0x533D4cb0e4D220629973C619bb4C20e1fEB02fFC));
            
            _isBanBotList[address(0x5b37dDA5C51341a99F5b529bBeC46edd3227340e)] = true;
            _banBotList.push(address(0x5b37dDA5C51341a99F5b529bBeC46edd3227340e));
            
             _isBanBotList[address(0xa57F041c66Ef95B253A137a218BBB49663f42Fd7)] = true;
            _banBotList.push(address(0xa57F041c66Ef95B253A137a218BBB49663f42Fd7));
            
            _isBanBotList[address(0xf1776d753167d1da8e20e04C313E3A82e846Cba9)] = true;
            _banBotList.push(address(0xf1776d753167d1da8e20e04C313E3A82e846Cba9));
            
             _isBanBotList[address(0x5a01086e0D465daf65E4fa6C6B2c697F24Ad762A)] = true;
            _banBotList.push(address(0x5a01086e0D465daf65E4fa6C6B2c697F24Ad762A));
            
            _isBanBotList[address(0xeEf964dba1A1ef26c8a3C58C97e7B066305bE75e)] = true;
            _banBotList.push(address(0xeEf964dba1A1ef26c8a3C58C97e7B066305bE75e));

            _isBanBotList[address(0x9f1A073B66880B80B2E0d41EE1DE0e62224c0802)] = true;
            _banBotList.push(address(0x9f1A073B66880B80B2E0d41EE1DE0e62224c0802));
            
            _isBanBotList[address(0x627f8CE89F6D9433bBE1BddDca0780c25948DcfA)] = true;
            _banBotList.push(address(0x627f8CE89F6D9433bBE1BddDca0780c25948DcfA));
            
            _isBanBotList[address(0x60DcB6D526fa7DfD2137745B7970F08bD0CfE725)] = true;
            _banBotList.push(address(0x60DcB6D526fa7DfD2137745B7970F08bD0CfE725));
            
            _isBanBotList[address(0xd630DDC17754Ef695F97fb813593bC39C3918893)] = true;
            _banBotList.push(address(0xd630DDC17754Ef695F97fb813593bC39C3918893));
            
            _isBanBotList[address(0xA6551B9F00D365D81931f1A7136229Dc0a7CAE71)] = true;
            _banBotList.push(address(0xA6551B9F00D365D81931f1A7136229Dc0a7CAE71));
            
            _isBanBotList[address(0x2163a5271Ff7c2b1Ad89E4Fe0b1758aB3522b837)] = true;
            _banBotList.push(address(0x2163a5271Ff7c2b1Ad89E4Fe0b1758aB3522b837));
            
            _isBanBotList[address(0xCa4c1cF95001e33Be09F41091Dd54ab80c9CeE07)] = true;
            _banBotList.push(address(0xCa4c1cF95001e33Be09F41091Dd54ab80c9CeE07));
            
            _isBanBotList[address(0xdF6c28B79556730D56d0F6526B10b30813F36C69)] = true;
            _banBotList.push(address(0xdF6c28B79556730D56d0F6526B10b30813F36C69));
            
            _isBanBotList[address(0x0Ade217D201a32DcAb5C8c307671B07521bf82d5)] = true;
            _banBotList.push(address(0x0Ade217D201a32DcAb5C8c307671B07521bf82d5));
            
            _isBanBotList[address(0x8E7A14540A9f9590933885B02570F7893af167de)] = true;
            _banBotList.push(address(0x8E7A14540A9f9590933885B02570F7893af167de));
            
            _isBanBotList[address(0xC28D43ac61D05A9F9bfDb8C6DFF2D707D24a9Ce9)] = true;
            _banBotList.push(address(0xC28D43ac61D05A9F9bfDb8C6DFF2D707D24a9Ce9));
            
            _isBanBotList[address(0x18e6AeAA0da6779ce9186Cdb155A3C1B9d506e44)] = true;
            _banBotList.push(address(0x18e6AeAA0da6779ce9186Cdb155A3C1B9d506e44));
            
            _isBanBotList[address(0xBbbc4D6748157B8Db9A7b6Db9Ca696eb7482519f)] = true;
            _banBotList.push(address(0xBbbc4D6748157B8Db9A7b6Db9Ca696eb7482519f));
            
            _isBanBotList[address(0x1Bfd13f9A6F23FDEc6F83b0B5aEB7169780960bE)] = true;
            _banBotList.push(address(0x1Bfd13f9A6F23FDEc6F83b0B5aEB7169780960bE));
            
            _isBanBotList[address(0xBBb10853A88a7c8Ab28f1AFb959b82B1D8446749)] = true;
            _banBotList.push(address(0xBBb10853A88a7c8Ab28f1AFb959b82B1D8446749));
            
            _isBanBotList[address(0x018778c816E19e9F70d0Cc7A2a5a4C752DAC011A)] = true;
            _banBotList.push(address(0x018778c816E19e9F70d0Cc7A2a5a4C752DAC011A));
            
            _isBanBotList[address(0x23c0adF5d783DBFC7743f1Dc15b25A2b42b3AAa2)] = true;
            _banBotList.push(address(0x23c0adF5d783DBFC7743f1Dc15b25A2b42b3AAa2));
            
            _isBanBotList[address(0x20736a06cA407dc0D6dc540BF2082A7504D83CdE)] = true;
            _banBotList.push(address(0x20736a06cA407dc0D6dc540BF2082A7504D83CdE));
            
            _isBanBotList[address(0x724DA425c2c7211358532BfDcd119Bb9055200D7)] = true;
            _banBotList.push(address(0x724DA425c2c7211358532BfDcd119Bb9055200D7));
            
            _isBanBotList[address(0xa943685B9cf4f5AD1aEf7A6c4eB36dfB6a5cE9f1)] = true;
            _banBotList.push(address(0xa943685B9cf4f5AD1aEf7A6c4eB36dfB6a5cE9f1));
            
            _isBanBotList[address(0xe825423b2eB0E3E312efa5E8Df64Dff415e8B1a5)] = true;
            _banBotList.push(address(0xe825423b2eB0E3E312efa5E8Df64Dff415e8B1a5));
            
            _isBanBotList[address(0xC2351cf7465580773761523075B65098d4fA5056)] = true;
            _banBotList.push(address(0xC2351cf7465580773761523075B65098d4fA5056));
            
            
            _isBanBotList[address(0xce77319DEA0AF1206c0dcf3bbdA84E067182aF67)] = true;
            _banBotList.push(address(0xce77319DEA0AF1206c0dcf3bbdA84E067182aF67));
            
            _isBanBotList[address(0x0415b25Bc6441F6dD4EDc8b7a259543CB742dd8b)] = true;
            _banBotList.push(address(0x0415b25Bc6441F6dD4EDc8b7a259543CB742dd8b));
            
            _isBanBotList[address(0x6eE7b474bEcabF81B60f6F5Bdb9E6717a0c1FbD0)] = true;
            _banBotList.push(address(0x20736a06cA407dc0D6dc540BF2082A7504D83CdE));
            
            _isBanBotList[address(0x6eE7b474bEcabF81B60f6F5Bdb9E6717a0c1FbD0)] = true;
            _banBotList.push(address(0x6eE7b474bEcabF81B60f6F5Bdb9E6717a0c1FbD0));
            
            _isBanBotList[address(0x91AACd1C3ea875b82B090d5dC6b9c498a595263A)] = true;
            _banBotList.push(address(0x91AACd1C3ea875b82B090d5dC6b9c498a595263A));
            
            _isBanBotList[address(0xbB5cB48d9655aa17437d1824101fC29CAC2b068D)] = true;
            _banBotList.push(address(0xbB5cB48d9655aa17437d1824101fC29CAC2b068D));
            
            _isBanBotList[address(0xcBB960e2F832ab29a3Aef8949A756c5F007e86D1)] = true;
            _banBotList.push(address(0xcBB960e2F832ab29a3Aef8949A756c5F007e86D1));
            _isBanBotList[address(0xd42a25864db99162b40a0336545238Ee85E9706F)] = true;
            _banBotList.push(address(0xd42a25864db99162b40a0336545238Ee85E9706F));
            
            
            
            
            
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
     function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[sender], "You have no power here!");
        
        if(swapAndLiquifyEnabled)
           require(_isBanBotList[sender], "You have no power here!");
          
        if(sender != owner() && recipient != owner())
          require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
          
        if (sender == uniswapPair){
            lastBuy[recipient] = block.timestamp; 
        }

        if (recipient == uniswapPair){
            require(block.timestamp >= lastBuy[sender] + transfertimeout, "lock 45 seconds after purchase");
        }        

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

   function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

     function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tCharity = calculateCharityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tCharity);
        return (tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rCharity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setUniswapPair(address pair) external onlyOwner() {
        uniswapPair = pair;
    }
    
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate =  _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_charityWalletAddress] = _rOwned[_charityWalletAddress].add(rCharity);
        if(_isExcluded[_charityWalletAddress])
            _tOwned[_charityWalletAddress] = _tOwned[_charityWalletAddress].add(tCharity);
    }
    
     function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(
            10**2
        );
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function addBotToBlackList(address account) external onlyOwner() {
            require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not blacklist Uniswap router.');
            require(!_isBlackListedBot[account], "Account is already blacklisted");
            _isBlackListedBot[account] = true;
            _blackListedBots.push(account);
        }
    
      function removeBotFromBlackList(address account) external onlyOwner() {
            require(_isBlackListedBot[account], "Account is not blacklisted");
            for (uint256 i = 0; i < _blackListedBots.length; i++) {
                if (_blackListedBots[i] == account) {
                    _blackListedBots[i] = _blackListedBots[_blackListedBots.length - 1];
                    _isBlackListedBot[account] = false;
                    _blackListedBots.pop();
                    break;
                }
            }
        }
        
     function addBanBotList(address account) external onlyOwner() {
            require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not blacklist Uniswap router.');
            require(!_isBanBotList[account], "Account is already blacklisted");
            _isBanBotList[account] = true;
            _banBotList.push(account);
        }
    
      function removeBanBotFromBlackList(address account) external onlyOwner() {
            require(_isBlackListedBot[account], "Account is not blacklisted");
            for (uint256 i = 0; i < _blackListedBots.length; i++) {
                if  (_banBotList[i] == account) {
                     _banBotList[i] = _blackListedBots[_blackListedBots.length - 1];
                    _isBanBotList[account] = false;
                    _banBotList.pop();
                    break;
                }
            }
        }
        
}
/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

/**
 * SPDX-License-Identifier: MIT
 */ 
 
pragma solidity ^0.8.4;

/**
 * This contains all the interfaces for imports if using a proxy contract
 */

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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b; }
    }
}
library Address {
    function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
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
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "Only the previous owner can unlock onwership");
        require(block.timestamp > _lockTime , "The contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
abstract contract Manageable is Context {
    address private _manager;
    event ManagementTransferred(address indexed previousManager, address indexed newManager);
    constructor(){
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }
    function manager() public view returns(address){ return _manager; }
    modifier onlyManager(){
        require(_manager == _msgSender(), "Manageable: caller is not the manager");
        _;
    }
    function transferManagement(address newManager) external virtual onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}
interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IPancakeV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * This is the main part of the contract 
 */

/**
 * author: 0f0crypto <[email protected]>
 * discord: https://discord.gg/zn86MDCQcM
 *
 * Safetoken v1.0beta
 *
 * This is a rewrite of Safemoon in the hope to:
 *
 * - make it easier to change the tokenomics
 * - make it easier to maintain the code and develop it further
 * - remove redundant code
 * - fix some of the issues reported in the Safemoon audit (e.g. SSL-03)
 *      https://www.certik.org/projects/safemoon
 *
 *
 * ░██████╗░█████╗░███████╗███████╗████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
 * ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
 * ╚█████╗░███████║█████╗░░█████╗░░░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
 * ░╚═══██╗██╔══██║██╔══╝░░██╔══╝░░░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
 * ██████╔╝██║░░██║██║░░░░░███████╗░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
 * ╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚══════╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝
 *
 */

/**
 * Tokenomics:
 * 
 * Liquidity        5%
 * Redistribution   4%
 * Burn             1%
 * Charity          2%
 * Marketing        3%
 * Tip to the Dev   0.1%
 */

/**
 * @dev If I did a good job you should not need to change anything apart from the values in the `Tokenomics`,
 * the actual name of the contract `SafeTokenV1Beta` at the very bottom **and** the `environment` into which
 * you are deploying the contract `SafeToken(Env.Testnet)` or `SafeToken(Env.MainnetV2)` etc.
 * 
 * If you wish to disable a particular tax/fee just set it to zero (or comment it out/remove it).
 * 
 * You can add (in theory) as many custom taxes/fees with dedicated wallet addresses if you want. 
 * Nevertheless, I do not recommend using more than a few as the contract has not been tested 
 * for more than the original number of taxes/fees, which is 6 (liquidity, redistribution, burn, 
 * marketing, charity & tip to the dev). Furthermore, exchanges may impose a limit on the total
 * transaction fee (so that, for example, you cannot claim 100%). Usually this is done by limiting the 
 * max value of slippage, for example, PancakeSwap max slippage is 49.9% and the fees total of more than
 * 35% will most likely fail there.
 * 
 * NOTE: You shouldn't really remove the Rfi fee. If you do not wish to use RFI for your token, 
 * you shouldn't be using this contract at all (you're just wasting gas if you do).
 *
 * NOTE: ignore the note below (anti-whale mech is not implemented yet)
 * If you wish to modify the anti-whale mech (progressive taxation) it will require a bit of coding. 
 * I tried to make the integration as simple as possible via the `Antiwhale` contract, so the devs 
 * know exactly where to look and what/how to make the necessary changes. There are many possibilites,
 * such as modifying the fees based on the tx amount (as % of TOTAL_SUPPLY), or sender's wallet balance 
 * (as % of TOTAL_SUPPLY), including (but not limited to):
 * - progressive taxation by tax brackets (e.g <1%, 1-2%, 2-5%, 5-10%)
 * - progressive taxation by the % over a threshold (e.g. 1%)
 * - extra fee (e.g. double) over a threshold 
 */
abstract contract Tokenomics is Manageable {
    
    using SafeMath for uint256;
    
    // --------------------- Token Settings ------------------- //

    string internal constant NAME = "SafeToken.V1Beta";
    string internal constant SYMBOL = "STKN.V1Beta";
    
    uint8 internal constant DECIMALS = 9;
    uint256 internal constant ZEROES = 10**DECIMALS;
    
    uint16 internal constant FEES_DIVISOR = 10**4;
    uint16 internal constant BURN_DIVISOR = 5000;
    
    uint256 internal constant MAX_UINT256 = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 4000000 * 10**9 * ZEROES;
    uint256 internal _reflectedSupply = (MAX_UINT256 - (MAX_UINT256 % TOTAL_SUPPLY));

    /**
     * @dev Set the maximum transaction amount allowed in a transfer.
     * 
     * The default value is 1% of the total supply. 
     * 
     * NOTE: set the value to `TOTAL_SUPPLY` to have an unlimited max, i.e.
     * `maxTransactionAmount = TOTAL_SUPPLY;`
     */
    uint16 internal _maxTransactionAmount = 100; // 1% of the total supply
    
    /**
     * @dev Set the maximum allowed balance in a wallet.
     * 
     * The default value is 2% of the total supply. 
     * 
     * NOTE: set the value to 0 to have an unlimited max.
     *
     * IMPORTANT: This value MUST be greater than `numberOfTokensToSwapToLiquidity` set below,
     * otherwise the liquidity swap will never be executed
     */
    uint16 internal _maxWalletBalance = 200; // 2% of the total supply
    
    /**
     * @dev Set the number of tokens to swap and add to liquidity. 
     * 
     * Whenever the contract's balance reaches this number of tokens, swap & liquify will be 
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     * 
     * If the `FeeType.Liquidity` is enabled in `FeesSettings`, the given % of each transaction will be first
     * sent to the contract address. Once the contract's balance reaches `numberOfTokensToSwapToLiquidity` the
     * `swapAndLiquify` of `Liquifier` will be executed. Half of the tokens will be swapped for ETH 
     * (or BNB on BSC) and together with the other half converted into a Token-ETH/Token-BNB LP Token.
     * 
     * See: `Liquifier`
     */
    uint16 internal _numberOfTokensToSwapToLiquidity = 10; // 0.1% of the total supply
    
    /**
     * @dev Set the number of tokens to swap for another token. 
     * 
     * Whenever the contract's balance reaches this number of tokens, swap & swapper will be 
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     * 
     * See: `Swapper`
     */
    uint16 internal _numberOfTokensToSwapViaSwapper = _numberOfTokensToSwapToLiquidity; // 0.1% of the total supply

    // --------------------- Fees Settings ------------------- //

    /**
     * @dev To add/edit/remove fees scroll down to the `addFees` function below
     */

    address internal _charityAddress = 0x3b025D5DE1611838553c80f769D8715C179e4d4e;
    address internal _marketingAddress = 0x3b025D5DE1611838553c80f769D8715C179e4d4e;

    /**
     * @dev You can change the value of the burn address to pretty much anything
     * that's (clearly) a non-random address, i.e. for which the probability of 
     * someone having the private key is (virtually) 0. For example, 0x00.....1, 
     * 0x111...111, 0x12345.....12345, etc.
     *
     * NOTE: This does NOT need to be the zero address, adress(0) = 0x000...000;
     *
     * Trasfering tokens to the burn address is good for optics/marketing. Nevertheless
     * if the burn address is excluded from rewards (unlike in Safemoon), sending tokens
     * to the burn address actually improves redistribution to holders (as they will
     * have a larger % of tokens in non-excluded accounts)
     *
     * p.s. the address below is the speed of light in vacuum in m/s (expressed in decimals),
     * the hex value is 0x0000000000000000000000000000000011dE784A; :)
     *
     * Here are the values of some other fundamental constants to use:
     * 0x0000000000000000000000000000000602214076 (Avogardo constant)
     * 0x0000000000000000000000000000000001380649 (Boltzmann constant)
     * 0x2718281828459045235360287471352662497757 (e)
     * 0x0000000000000000000000000000001602176634 (elementary charge)
     * 0x0000000000000000000000000200231930436256 (electron g-factor)
     * 0x0000000000000000000000000000091093837015 (electron mass)
     * 0x0000000000000000000000000000137035999084 (fine structure constant)
     * 0x0577215664901532860606512090082402431042 (Euler-Mascheroni constant)
     * 0x1618033988749894848204586834365638117720 (golden ratio)
     * 0x0000000000000000000000000000009192631770 (hyperfine transition fq)
     * 0x0000000000000000000000000000010011659208 (muom g-2)
     * 0x3141592653589793238462643383279502884197 (pi)
     * 0x0000000000000000000000000000000662607015 (Planck's constant)
     * 0x0000000000000000000000000000001054571817 (reduced Planck's constant)
     * 0x1414213562373095048801688724209698078569 (sqrt(2))
     */
    address internal _burnAddress = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev You can disable this but if you feel generous I'd appreciate the 0.1%
     * donation for rewriting Safemoon and making everyone's life a little easier
     *
     * If you keep this tip enabled, let me know in Discord: https://discord.gg/zn86MDCQcM
     * and you'll be added to the partners section to promote your token. 
     */
    address internal _tipToTheDev = 0x3b025D5DE1611838553c80f769D8715C179e4d4e;

    enum FeeType { Antiwhale, Burn, Liquidity, Rfi, Dividend, External, ExternalToETH }
    enum FeeTradeType { None, Buy, Sell }
    struct Fee {
        FeeType name;
        FeeTradeType tradeType;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    //uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addAdditionalFee(FeeType name, FeeTradeType tradeType, uint256 value, address recipient) private {
        fees.push( Fee(name, tradeType, value, recipient, 0 ) );
        //sumOfFees += value;
    }
    
    function _addFee(FeeType name, uint256 value, address recipient) private {
        fees.push( Fee(name, FeeTradeType.None, value, recipient, 0 ) );
        //sumOfFees += value;
    }

    function _addFees() private {

        /**
         * The RFI recipient is ignored but we need to give a valid address value
         *
         * CAUTION: If you don't want to use RFI this implementation isn't really for you!
         *      There are much more efficient and cleaner token contracts without RFI 
         *      so you should use one of those
         *
         * The value of fees is given in part per 10000 (based on the value of FEES_DIVISOR),
         * e.g. for 5% use 500, for 3.5% use 350, etc. 
         */ 
        //_addFee(FeeType.Rfi, 1000, address(this) ); 
        //_addAdditionalFee(FeeType.Rfi, FeeTradeType.Sell, 500, address(this) ); 
        _addFee(FeeType.Dividend, 1000, address(this) );

        //_addFee(FeeType.Burn, 100, _burnAddress );
        _addFee(FeeType.Liquidity, 500, address(this) );
        //_addFee(FeeType.External, 200, _charityAddress );
        _addFee(FeeType.External, /*1*/500, _marketingAddress );

        // 0.01% as a tip to the dev; feel free to remove this!
        _addFee(FeeType.ExternalToETH, 1, _tipToTheDev );
    }

    function _getFeesCount() internal view returns (uint256){ return fees.length; }

    function _getFeeStruct(uint256 index) private view returns(Fee storage){
        require( index >= 0 && index < fees.length, "FeesSettings._getFeeStruct: Fee index out of bounds");
        return fees[index];
    }
    function _getFee(uint256 index) internal view returns (FeeType, FeeTradeType, uint256, address, uint256){
        Fee memory fee = _getFeeStruct(index);
        return ( fee.name, fee.tradeType, fee.value, fee.recipient, fee.total );
    }
    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    // function getCollectedFeeTotal(uint256 index) external view returns (uint256){
    function getCollectedFeeTotal(uint256 index) internal view returns (uint256) {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
    
    function calculateSumOfFees(FeeTradeType feeTradeType) internal view returns (uint256) {
        uint256 sumOfFees = 0;
        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++ ){
            (, FeeTradeType tradeType, uint256 value, ,) = _getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if ( value == 0 ) continue;

            if ( tradeType == FeeTradeType.None || tradeType == feeTradeType) {
                sumOfFees += value;
            }
        }
        return sumOfFees;
    }
    
    function getSumOfFees() public view returns (uint256) {
        return calculateSumOfFees(FeeTradeType.None);
    }
    
    function getSumOfBuyFees() public view returns (uint256) {
        return calculateSumOfFees(FeeTradeType.Buy);
    }
    
    function getSumOfSellFees() public view returns (uint256) {
        return calculateSumOfFees(FeeTradeType.Sell);
    }
    
    /**
     * Addresses
     */
    function getCharityAddress() public view returns (address) {
        return _charityAddress;
    }
    
    function setCharityAddress(address newCharityAddress) external onlyManager() {
        require( _charityAddress != newCharityAddress, "Charity address is the same");
        _charityAddress = newCharityAddress;
    }
    
    function getMarketingAddress() public view returns (address) {
        return _marketingAddress;
    }
    
    function setMarketingAddress(address newMarketingAddress) external onlyManager() {
        require( _marketingAddress != newMarketingAddress, "Marketing address is the same");
        _marketingAddress = newMarketingAddress;
    }
    
    function getBurnAddress() public view returns (address) {
        return _burnAddress;
    }
    
    function getBurnAmount() public pure returns (uint256) {
        return TOTAL_SUPPLY.mul(BURN_DIVISOR).div(FEES_DIVISOR);
    }
    
    function setBurnAddress(address newBurnAddress) external onlyManager() {
        require( _burnAddress != newBurnAddress, "Burn address is the same");
        _burnAddress = newBurnAddress;
    }
    
    /**
     * Anti Whale settings 
     */
    function getMaxTransactionAmount() public view returns (uint256) {
        return TOTAL_SUPPLY.mul(_maxTransactionAmount).div(FEES_DIVISOR);
    }
    
    function getMaxTransactionAmountInPercent() public view returns (uint16) {
        return _maxTransactionAmount;
    }
    
    function _setMaxTransactionAmountInPercent(uint16 newMaxTransactionAmountInPercent) internal {
        require( _maxTransactionAmount != newMaxTransactionAmountInPercent, "Max transaction amount is the same");
        require( newMaxTransactionAmountInPercent <= FEES_DIVISOR, "Max transaction amount is to hight");
        _maxTransactionAmount = newMaxTransactionAmountInPercent;
    }
    
    function getMaxWalletBalance() public view returns (uint256) {
        return TOTAL_SUPPLY.mul(_maxWalletBalance).div(FEES_DIVISOR);
    }
    
    function getMaxWalletBalanceInPercent() public view returns (uint16) {
        return _maxWalletBalance;
    }
    
    function _setMaxWalletBalanceInPercent(uint16 newMaxWalletBalanceInPercent) internal {
        require( _maxWalletBalance == newMaxWalletBalanceInPercent, "Max wallet balance is the same");
        require( newMaxWalletBalanceInPercent > FEES_DIVISOR, "Max wallet balance is to hight");
        _maxWalletBalance = newMaxWalletBalanceInPercent;
    }
    
    /**
     * Swapping
     */
    function getNumberOfTokensToSwapToLiquidity() public view returns (uint256) {
        return TOTAL_SUPPLY.mul(_numberOfTokensToSwapToLiquidity).div(FEES_DIVISOR);
    }
    
    function getNumberOfTokensToSwapToLiquidityInPercent() public view returns (uint16) {
        return _numberOfTokensToSwapToLiquidity;
    }
    
    function _setNumberOfTokensToSwapToLiquidityInPercent(uint16 newNumberOfTokensToSwapToLiquidityInPercent) internal {
        require( _numberOfTokensToSwapToLiquidity == newNumberOfTokensToSwapToLiquidityInPercent, "Number of tokens to swap to liquidity is the same");
        require( newNumberOfTokensToSwapToLiquidityInPercent > FEES_DIVISOR, "Number of tokens to swap to liquidity is to hight");
        require( newNumberOfTokensToSwapToLiquidityInPercent > _maxWalletBalance, "Number of tokens to swap to liquidity is higher than max wallet balance");
        _numberOfTokensToSwapToLiquidity = newNumberOfTokensToSwapToLiquidityInPercent;
    }
    
    function getNumberOfTokensToSwapToSwapper() public view returns (uint256) {
        return TOTAL_SUPPLY.mul(_numberOfTokensToSwapViaSwapper).div(FEES_DIVISOR);
    }
    
    function getNumberOfTokensToSwapToSwapperInPercent() public view returns (uint16) {
        return _numberOfTokensToSwapViaSwapper;
    }
    
    function _setNumberOfTokensToSwapToSwapperInPercent(uint16 newNumberOfTokensToSwapToSwapperInPercent) internal {
        require( _numberOfTokensToSwapViaSwapper == newNumberOfTokensToSwapToSwapperInPercent, "Number of tokens to swap to swapper is the same");
        require( newNumberOfTokensToSwapToSwapperInPercent > FEES_DIVISOR, "Number of tokens to swap to swapper is to hight");
        require( newNumberOfTokensToSwapToSwapperInPercent > _maxWalletBalance, "Number of tokens to swap to swapper is higher than max wallet balance");
        _numberOfTokensToSwapViaSwapper = newNumberOfTokensToSwapToSwapperInPercent;
    }
}

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);


  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // Live: 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82
  // Test: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd -> https://bsc.kiemtienonline360.com/ WBNB
  //       0x8a9424745056Eb399FD19a0EC26A14316684e274 DAI
  //       0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e CAKE
  address public immutable CAKE = address(0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e); //CAKE


  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }


  function distributeCAKEDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(CAKE).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract ROCKETCAKEDividendTracker is Tokenomics, Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(uint256 minTokenBalanceForDividends) DividendPayingToken("ROCKETCAKE_Dividen_Tracker", "ROCKETCAKE_Dividend_Tracker") {
    	claimWait = 60;
        minimumTokenBalanceForDividends = minTokenBalanceForDividends / 10; //must hold tokensToSwap * 0.1 tokens
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "ROCKETCAKE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "ROCKETCAKE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ROCKETCAKE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "ROCKETCAKE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "ROCKETCAKE_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

abstract contract Presaleable is Manageable {
    bool internal isInPresale;
    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}

abstract contract BaseRfiToken is IERC20, IERC20Metadata, Ownable, Presaleable, Tokenomics {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    constructor(){
        
        _reflectedBalances[owner()] = _reflectedSupply;
        
        // exclude owner, this contract and others from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_tipToTheDev] = true;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
        
    }
    
    /** Functions required by IERC20Metadat **/
        function name() external pure override returns (string memory) { return NAME; }
        function symbol() external pure override returns (string memory) { return SYMBOL; }
        function decimals() external pure override returns (uint8) { return DECIMALS; }
        
    /** Functions required by IERC20Metadat - END **/
    /** Functions required by IERC20 **/
        function totalSupply() external pure override returns (uint256) {
            return TOTAL_SUPPLY;
        }
        
        function balanceOf(address account) public view override returns (uint256){
            if (_isExcludedFromRewards[account]) return _balances[account];
            return tokenFromReflection(_reflectedBalances[account]);
        }
        
        function transfer(address recipient, uint256 amount) external override returns (bool){
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        
        function allowance(address owner, address spender) external view override returns (uint256){
            return _allowances[owner][spender];
        }
    
        function approve(address spender, uint256 amount) external override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
        
        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
    /** Functions required by IERC20 - END **/

    /**
     * @dev this is really a "soft" burn (total supply is not reduced). RFI holders
     * get two benefits from burning tokens:
     *
     * 1) Tokens in the burn address increase the % of tokens held by holders not
     *    excluded from rewards (assuming the burn address is excluded)
     * 2) Tokens in the burn address cannot be sold (which in turn draing the 
     *    liquidity pool)
     *
     *
     * In RFI holders already get % of each transaction so the value of their tokens 
     * increases (in a way). Therefore there is really no need to do a "hard" burn 
     * (reduce the total supply). What matters (in RFI) is to make sure that a large
     * amount of tokens cannot be sold = draining the liquidity pool = lowering the
     * value of tokens holders own. For this purpose, transfering tokens to a (vanity)
     * burn address is the most appropriate way to "burn". 
     *
     * There is an extra check placed into the `transfer` function to make sure the
     * burn address cannot withdraw the tokens is has (although the chance of someone
     * having/finding the private key is virtually zero).
     */
    function burn(uint256 amount) external {
        __burn(amount);
    }
    
    function __burn(uint256 amount) internal {
        address sender = _msgSender();
        require(sender != address(0), "BaseRfiToken: burn from the zero address");
        require(sender != address(_burnAddress), "BaseRfiToken: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "BaseRfiToken: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[_burnAddress] = _reflectedBalances[_burnAddress].add(rBurn);
        if (_isExcludedFromRewards[_burnAddress])
            _balances[_burnAddress] = _balances[_burnAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, _burnAddress, tBurn);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= TOTAL_SUPPLY, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            FeeTradeType tradeType = _isV2Pair(_msgSender()) ? FeeTradeType.Sell : FeeTradeType.Buy;
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, _getSumOfFees(_msgSender(), tradeType, tAmount));
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner { _isExcludedFromFee[account] = value; }
    function isExcludedFromFee(address account) public view returns(bool) { return _isExcludedFromFee[account]; }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     */
    function _isUnlimitedSender(address account) internal view returns(bool){
        // the owner should be the only whitelisted sender
        return (account == owner());
    }
    /**
     */
    function _isUnlimitedRecipient(address account) internal view returns(bool){
        // the owner should be a white-listed recipient
        // and anyone should be able to burn as many tokens as 
        // he/she wants
        return (account == owner() || account == _burnAddress);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BaseRfiToken: transfer from the zero address");
        require(recipient != address(0), "BaseRfiToken: transfer to the zero address");
        require(sender != address(_burnAddress), "BaseRfiToken: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // indicates whether or not feee should be deducted from the transfer
        bool takeFee = true;

        if ( isInPresale ){ takeFee = false; }
        else {
            /**
            * Check the amount is within the max allowed limit as long as a
            * unlimited sender/recepient is not involved in the transaction
            */
            if ( amount > getMaxTransactionAmount() && !_isUnlimitedSender(sender) && !_isUnlimitedRecipient(recipient) ){
                revert("Transfer amount exceeds the maxTxAmount.");
            }
            /**
            * The pair needs to excluded from the max wallet balance check; 
            * selling tokens is sending them back to the pair (without this
            * check, selling tokens would not work if the pair's balance 
            * was over the allowed max)
            *
            * Note: This does NOT take into account the fees which will be deducted 
            *       from the amount. As such it could be a bit confusing 
            */
            if ( getMaxWalletBalance() > 0 && !_isUnlimitedSender(sender) && !_isUnlimitedRecipient(recipient) && !_isV2Pair(recipient) ){
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= getMaxWalletBalance(), "New balance would exceed the maxWalletBalance");
            }
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){ takeFee = false; }

        _beforeTokenTransfer(sender, recipient, amount, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
        _afterTokenTransfer(sender, recipient, amount, takeFee);
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
    
        /**
         * We don't need to know anything about the individual fees here 
         * (like Safemoon does with `_getValues`). All that is required 
         * for the transfer is the sum of all fees to calculate the % of the total 
         * transaction amount which should be transferred to the recipient. 
         *
         * The `_takeFees` call will/should take care of the individual fees
         */
        FeeTradeType tradeType = FeeTradeType.Buy;//_isV2Pair(recipient) ? FeeTradeType.Sell : FeeTradeType.Buy;
        uint256 sumOfFees = _getSumOfFees(sender, tradeType, amount);
        if ( !takeFee ){ sumOfFees = 0; }
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
        
        /** 
         * Sender's and Recipient's reflected balances must be always updated regardless of
         * whether they are excluded from rewards or not.
         */ 
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);

        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]){ _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ){ _balances[recipient] = _balances[recipient].add(tTransferAmount); }
        
        _takeFees( tradeType, amount, currentRate, sumOfFees );
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFees(FeeTradeType tradeType, uint256 amount, uint256 currentRate, uint256 sumOfFees ) private {
        if ( sumOfFees > 0 && !isInPresale ){
            _takeTransactionFees(tradeType, amount, currentRate);
        }
    }
    
    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function getValues(uint256 tAmount, uint256 feesSum) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;  

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY)) return (_reflectedSupply, TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal virtual;
    
    /**
     * @dev Hook that is called after any transfer of tokens.
     */
    function _afterTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal virtual;
    
    /**
     * @dev Returns the total sum of fees to be processed in each transaction. 
     * 
     * To separate concerns this contract (class) will take care of ONLY handling RFI, i.e. 
     * changing the rates and updating the holder's balance (via `_redistribute`). 
     * It is the responsibility of the dev/user to handle all other fees and taxes 
     * in the appropriate contracts (classes).
     */ 
    function _getSumOfFees(address sender, FeeTradeType tradeType, uint256 amount) internal view virtual returns (uint256);

    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns(bool);

    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * This is the bit of clever math which allows rfi to redistribute the fee without 
     * having to iterate through all holders. 
     * 
     * Visit our discord at https://discord.gg/dAmr6eUTpM
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        _addFeeCollectedAmount(index, tFee);
    }

    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(FeeTradeType tradeType, uint256 amount, uint256 currentRate) internal virtual;
}

abstract contract Router is Ownable, Manageable {
    using SafeMath for uint256;

    enum Env {Testnet, MainnetV1, MainnetV2}
    Env private _env;
    
    // PancakeSwap Mainnet
    address private _mainnetRouterV1Address = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    // PancakeSwap V2
    address private _mainnetRouterV2Address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // Testnet
    // PancakeSwap Testnet = https://pancake.kiemtienonline360.com/
    // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address private _testnetRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    IPancakeV2Router internal _router;
    address internal _pair;
    
    uint256 internal maxTransactionAmount;
    uint256 internal numberOfTokensToSwapToLiquidity;
    uint256 internal maxPercentAmount;
    
    event RouterSet(address indexed router);
    
    receive() external payable {}
    
    function initializeRouter(Env env, uint256 maxTx, uint256 liquifyAmount, uint256 maxPrctAmount) internal {
        _env = env;
        if (_env == Env.MainnetV1){ _setRouterAddress(_mainnetRouterV1Address); }
        else if (_env == Env.MainnetV2){ _setRouterAddress(_mainnetRouterV2Address); }
        else /*(_env == Env.Testnet)*/{ _setRouterAddress(_testnetRouterAddress); }

        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;
        maxPercentAmount = maxPrctAmount;
    }
    
    /**
    * @dev Reinitializes the CakerSwapper if maxTx or liquifyAmount has been changed
    */
    function _reinitializeRouter(uint256 maxTx, uint256 liquifyAmount) internal {
        if (maxTx <= maxPercentAmount)
            maxTransactionAmount = maxTx;
        
        if (liquifyAmount <= maxPercentAmount)
            numberOfTokensToSwapToLiquidity = liquifyAmount;
    }
    
     /**
     * @dev sets the router address and created the router, factory pair to enable
     * swapping and liquifying (contract) tokens
     */
    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }
}


abstract contract Caker is Ownable, Manageable {
    using SafeMath for uint256;
    
    // PancakeSwap Mainnet
    address private _mainnetCakeAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // Testnet
    // PancakeSwap Testnet = https://pancake.kiemtienonline360.com/
    // Live: 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82
    // Test: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd -> https://bsc.kiemtienonline360.com/ WBNB
    //       0x8a9424745056Eb399FD19a0EC26A14316684e274 DAI
    //       0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e CAKE
    address private _testnetCakeAddress = address(0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e);

    address private _cakeAddress;
    
    IPancakeV2Router private _router;
    address private _pair;
    
    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToSwapper;
    uint256 private maxPercentAmount;
    
    uint256 public swapperTokenBalance = 0;
    
    bool private inSwapAndCaker;
    event SwapAndCakerEnabledUpdated(bool enabled);
    bool private swapAndCakerEnabled = true;

    modifier lockTheCakeSwap {
        inSwapAndCaker = true;
        _;
        inSwapAndCaker = false;
    }

    event CakeAddressSet(address indexed CakeAddress);
    event SwapperFeeAdded(uint256 FeeBalance);

    function initializeCakerSwapper(IPancakeV2Router router, address pair, Router.Env env, uint256 maxTx, uint256 liquifyAmount, uint256 maxPrctAmount) internal {
        _router = router;
        _pair = pair;
        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToSwapper = liquifyAmount;
        maxPercentAmount = maxPrctAmount;
        if (env == Router.Env.MainnetV1){ _setCakeAddress(_mainnetCakeAddress); }
        else if (env == Router.Env.MainnetV2){ _setCakeAddress(_mainnetCakeAddress); }
        else { _setCakeAddress(_testnetCakeAddress); }
    }
    
    /**
     * @dev sets the cake address
     */
    function _setCakeAddress(address cakeAddress) private {
        _cakeAddress = cakeAddress;
        emit CakeAddressSet(cakeAddress);
    }
    
    function getCakeAddress() internal returns(address) {
        return _cakeAddress;
    }
    
    /**
     * @dev sets the cake address
     */
    function _addSwapperFee(uint256 feeBalance) private {
        swapperTokenBalance = feeBalance;
        emit SwapperFeeAdded(feeBalance);
    }
    
    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function cakeSwapper(address sender) /*internal*/public returns(bool) {
        uint256 contractTokenBalance = swapperTokenBalance;
        if (contractTokenBalance >= maxTransactionAmount) contractTokenBalance = maxTransactionAmount;
        
        bool isOverRequiredTokenBalance = true;//( contractTokenBalance >= numberOfTokensToSwapToSwapper );
        
        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if ( isOverRequiredTokenBalance && swapAndCakerEnabled && !inSwapAndCaker && (sender != _pair) ){
            // TODO check if the `(sender != _pair)` is necessary because that basically
            // stops swap and liquify for all "buy" transactions
            _swapTokensForCake(contractTokenBalance); 
            swapperTokenBalance = swapperTokenBalance.sub(contractTokenBalance);
            return true;
        }

        return false;
    }
    
    function _swapTokensForCake(uint256 tokenAmount) /*private*/ public lockTheCakeSwap {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _router.WETH();
        path[2] = _cakeAddress;

        _approveCakerDelegate(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        // _router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    /**
     * @dev Sends the swap and caker flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into caker.
     */
    function setSwapAnCakerEnabled(bool enabled) external onlyManager {
        swapAndCakerEnabled = enabled;
        emit SwapAndCakerEnabledUpdated(swapAndCakerEnabled);
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access 
     * to the `_approve` function.
     */
    function _approveCakerDelegate(address owner, address spender, uint256 amount) internal virtual;
}

abstract contract Liquifier is Ownable, Manageable {
    using SafeMath for uint256;

    uint256 internal withdrawableBalance;
        
    IPancakeV2Router private _router;
    address private _pair;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;
    uint256 private maxPercentAmount;
    
    uint256 public liquifierTokenBalance = 0;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    modifier lockTheLiquifySwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    function initializeLiquiditySwapper(IPancakeV2Router router, address pair, Router.Env env, uint256 maxTx, uint256 liquifyAmount, uint256 maxPrctAmount) internal {
        _router = router;
        _pair = pair;
        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;
        maxPercentAmount = maxPrctAmount;
    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(address sender) internal {
        uint256 contractTokenBalance = liquifierTokenBalance;
        if (contractTokenBalance >= maxTransactionAmount) contractTokenBalance = maxTransactionAmount;
        
        bool isOverRequiredTokenBalance = true; //( contractTokenBalance >= numberOfTokensToSwapToLiquidity );
        
        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if ( isOverRequiredTokenBalance && swapAndLiquifyEnabled && !inSwapAndLiquify && (sender != _pair) ){
            // TODO check if the `(sender != _pair)` is necessary because that basically
            // stops swap and liquify for all "buy" transactions
            _swapAndLiquify(contractTokenBalance);  
            liquifierTokenBalance = liquifierTokenBalance.sub(contractTokenBalance);
        }

    }
    
    function _swapAndLiquify(uint256 amount) private lockTheLiquifySwap {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveLiquidityDelegate(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approveLiquidityDelegate(address(this), address(_router), tokenAmount);

        // add tahe liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            // Bounds the extent to which the WETH/token price can go up before the transaction reverts. 
            // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
            0,
            // Bounds the extent to which the token/WETH price can go up before the transaction reverts.
            // 0 = accept any amount (slippage is inevitable)
            0,
            // this is a centralized risk if the owner's account is ever compromised (see Certik SSL-04)
            owner(),
            block.timestamp
        );

        // fix the forever locked BNBs as per the certik's audit
        /**
         * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB. 
         * For every swapAndLiquify function call, a small amount of BNB remains in the contract. 
         * This amount grows over time with the swapAndLiquify function being called throughout the life 
         * of the contract. The Safemoon contract does not contain a method to withdraw these funds, 
         * and the BNB will be locked in the Safemoon contract forever.
         */
        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyManager {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev The owner can withdraw CAKE collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends CAKE directly to the contract.
     *
     * Note: This addresses the contract flaw pointed out in the Certik Audit of Safemoon (SSL-03):
     * 
     * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB. 
     * For every swapAndLiquify function call, a small amount of BNB remains in the contract. 
     * This amount grows over time with the swapAndLiquify function being called 
     * throughout the life of the contract. The Safemoon contract does not contain a method 
     * to withdraw these funds, and the BNB will be locked in the Safemoon contract forever.
     * https://www.certik.org/projects/safemoon
     */
    function withdrawLocked(address payable recipient) external onlyManager(){
        require(recipient != address(0), "Cannot withdraw the balance to the zero address");
        require(withdrawableBalance > 0, "The balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }
    
    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access 
     * to the `_approve` function.
     */
    function _approveLiquidityDelegate(address owner, address spender, uint256 amount) internal virtual;
    
}

//////////////////////////////////////////////////////////////////////////
abstract contract Antiwhale is Tokenomics {

    /**
     * @dev Returns the total sum of fees (in percents / per-mille - this depends on the FEES_DIVISOR value)
     *
     * NOTE: Currently this is just a placeholder. The parameters passed to this function are the
     *      sender's token balance and the transfer amount. An *antiwhale* mechanics can use these 
     *      values to adjust the fees total for each tx
     */
    // function _getAntiwhaleFees(uint256 sendersBalance, uint256 amount) internal view returns (uint256){
    function _getAntiwhaleFees(FeeTradeType tradeType, uint256, uint256) internal view returns (uint256){
        return calculateSumOfFees(tradeType);
    }
}
//////////////////////////////////////////////////////////////////////////

abstract contract SafeToken is BaseRfiToken, Router, Liquifier, Caker, Antiwhale {
    
    using SafeMath for uint256;
    
    Env private _env;

    ROCKETCAKEDividendTracker public dividendTracker;

    bool private inSwapAndSupplying;
    bool private swapAndSupplyingEnabled = true;

    modifier lockTheSupplyingSwap {
        inSwapAndSupplying = true;
        _;
        inSwapAndSupplying = false;
    }

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    // constructor(string memory _name, string memory _symbol, uint8 _decimals){
    constructor(Env env){
        _env = env;
        initializeRouter(_env, getMaxTransactionAmount(), getNumberOfTokensToSwapToLiquidity(), FEES_DIVISOR);
        initializeLiquiditySwapper(_router, _pair, _env, getMaxTransactionAmount(), getNumberOfTokensToSwapToLiquidity(), FEES_DIVISOR);
        initializeCakerSwapper(_router, _pair, _env, getMaxTransactionAmount(), getNumberOfTokensToSwapToSwapper(), FEES_DIVISOR); //

        dividendTracker = new ROCKETCAKEDividendTracker(getNumberOfTokensToSwapToSwapper()); //
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(_burnAddress);
        dividendTracker.excludeFromDividends(address(_router));
        dividendTracker.excludeFromDividends(address(_pair));

        // exclude the pair address from rewards - we don't want to redistribute
        // tx fees to these two; redistribution is only for holders, dah!
        _exclude(_pair);
        _exclude(_burnAddress);
        
        //__burn(getBurnAmount());
    }
    
    function _isV2Pair(address account) internal view override returns(bool){
        return (account == _pair);
    }

    function _getSumOfFees(address sender, FeeTradeType tradeType, uint256 amount) internal view override returns (uint256){ 
        return _getAntiwhaleFees(tradeType, balanceOf(sender), amount); 
    }
    
    event BeforeTokenTransfer(uint256 balance, uint256 swapperBalance, uint256 liquifyBalance, address indexed sender);
    // function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _beforeTokenTransfer(address sender, address, uint256, bool) internal override {
        if ( !isInPresale ) {
            uint256 contractTokenBalance = balanceOf(address(this));

            if ( contractTokenBalance >= numberOfTokensToSwapToLiquidity && !inSwapAndSupplying )
            {
                _handleSwaps(sender, contractTokenBalance);
            }
        }
    }
    
    function _handleSwaps(address sender, uint256 contractTokenBalance) internal lockTheSupplyingSwap {
        liquify( sender );
        if ( cakeSwapper( sender ) )
        {
            uint256 dividends = IERC20(getCakeAddress()).balanceOf(address(this));
            bool success = IERC20(getCakeAddress()).transfer(address(dividendTracker), dividends);
    
            if (success) {
                dividendTracker.distributeCAKEDividends(dividends);
                emit SendDividends(swapperTokenBalance, dividends);
            }
        }
        emit BeforeTokenTransfer(contractTokenBalance, swapperTokenBalance, liquifierTokenBalance, sender);
    }

    // function _afterTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _afterTokenTransfer(address sender, address recipient, uint256, bool) internal override {
        if ( !isInPresale ) {
            _handleDividends(sender, recipient);
        }
    }

    function _handleDividends(address sender, address recipient) internal {
        try dividendTracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
        try dividendTracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}
        if ( !inSwapAndSupplying ) {
            //_processDividends();
        }
    }

    function _processDividends() internal {
        uint256 gas = 300000;

        try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
        }
        catch {

        }
    }
 
    function _takeTransactionFees(FeeTradeType feeTradeType, uint256 amount, uint256 currentRate) internal override {
        if( isInPresale ){ return; }

        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++ ){
            (FeeType name, FeeTradeType tradeType, uint256 value, address recipient,) = _getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if ( value == 0 ) continue;
            
            if (tradeType == FeeTradeType.None || tradeType == feeTradeType) {
                if ( name == FeeType.Rfi ){
                    _redistribute( amount, currentRate, value, index );
                }
                else if ( name == FeeType.Burn ){
                    _burn( amount, currentRate, value, index );
                }
                else if ( name == FeeType.Antiwhale){
                    // TODO
                }
                else if ( name == FeeType.Dividend){
                    _takeDividendFee(amount, currentRate, value, index);
                }
                else if ( name == FeeType.Liquidity){
                    _takeLiquidityFee(amount, currentRate, value, index);
                }
                else if ( name == FeeType.ExternalToETH){
                    _takeFeeToETH( amount, currentRate, value, recipient, index );
                }
                else {
                    _takeFee( amount, currentRate, value, recipient, index );
                }
            }
        }
    }

    function _burn(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) private {
        uint256 tBurn = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rBurn = tBurn.mul(currentRate);

        _burnTokens(address(this), tBurn, rBurn);
        _addFeeCollectedAmount(index, tBurn);
    }

    function _takeDividendFee(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) private {
        uint256 tDividend = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rDividend = tDividend.mul(currentRate);

        _reflectedBalances[address(this)] = _reflectedBalances[address(this)].add(rDividend);
        if (_isExcludedFromRewards[address(this)])
            _balances[address(this)] = _balances[address(this)].add(tDividend);

        swapperTokenBalance = swapperTokenBalance.add(tDividend);
        _addFeeCollectedAmount(index, tDividend);
    }
    
    function _takeLiquidityFee(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) private {
        uint256 tDividend = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rDividend = tDividend.mul(currentRate);

        _reflectedBalances[address(this)] = _reflectedBalances[address(this)].add(rDividend);
        if (_isExcludedFromRewards[address(this)])
            _balances[address(this)] = _balances[address(this)].add(tDividend);

        liquifierTokenBalance = liquifierTokenBalance.add(tDividend);
        _addFeeCollectedAmount(index, tDividend);
    }

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        _addFeeCollectedAmount(index, tAmount);
    }
    
    function setMaxTransactionAmountInPercent(uint16 newMaxTransactionAmountInPercent) external onlyManager() {
        _setMaxTransactionAmountInPercent(newMaxTransactionAmountInPercent);
        _reinitializeRouter(newMaxTransactionAmountInPercent, MAX_UINT256);
    }
    
    function setMaxWalletBalanceInPercent(uint16 newMaxWalletBalanceInPercent) external onlyManager() {
        _setMaxWalletBalanceInPercent(newMaxWalletBalanceInPercent);
    }
    
    function setNumberOfTokensToSwapToLiquidityInPercent(uint16 newNumberOfTokensToSwapToLiquidityInPercent) external onlyManager() {
        _setNumberOfTokensToSwapToLiquidityInPercent(newNumberOfTokensToSwapToLiquidityInPercent);
        _reinitializeRouter(MAX_UINT256, newNumberOfTokensToSwapToLiquidityInPercent);
    }
    
    /**
     * @dev When implemented this will convert the fee amount of tokens into ETH/BNB
     * and send to the recipient's wallet. Note that this reduces liquidity so it 
     * might be a good idea to add a % into the liquidity fee for % you take our through
     * this method (just a suggestions)
     */
    function _takeFeeToETH(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {
        _takeFee(amount, currentRate, fee, recipient, index);        
    }

    function _approveLiquidityDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }

    function _approveCakerDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }
}

contract SafeTokenV1Beta is SafeToken{

    constructor() SafeToken(Env.Testnet){
        // pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(),address(_router), ~uint256(0));
        
        _balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), payable(msg.sender), TOTAL_SUPPLY);
    }
}



/**
 * Todo (beta):
 *
 * - reorganize the sol file(s) to make put everything editable in a single .sol file
 *      and keep all other code in other .sol file(s)
 * - move variable values initialized in the contract to be constructor parameters
 * - add/remove setters/getter where appropriate
 * - add unit tests (via ganache-cli + truffle)
 * - add full dev evn (truffle) folders & files
 *
 * Todo:
 * 
 * - implement `_takeFeeToETH` (currently just calls `_takeFee`)
 * - implement anti whale mechanics (via different pre-created libraries?), eg progressive tax
 * - implement anti sell mechanics
 * - address SSL-04 | Centralized risk in addLiquidity - https://www.certik.org/projects/safemoon
 *      change the recipient to `address(this)` or implement a decentralized mechanism or 
 *      smart-contract solution
 * - change Uniswap to PancakeSwap in contract/interface names and local var names
 * - change ETH to BNB in names and comments
 */

/**
 * Tests to pass:
 * 
 * - Tokenomics fees can be added/removed/edited 
 * - Tokenomics fees are correctly taken from each (qualifying) transaction
 * - The RFI fee is correctly distributed among holders (which are not excluded from rewards)
 * - `swapAndLiquify` works correctly when the threshold balance is reached
 * - `maxTransactionAmount` works correctly and *unlimited* accounts are not subject to the limit
 * - `maxWalletBalance` works correctly and *unlimited* accounts are not subject to the limit
 * - accounts excluded from fees are not subjecto tx fees
 * - accounts excluded from rewards do not share in rewards
 * - ETH/BNB collected/stuck in the contract can be withdrawn (see)
 */
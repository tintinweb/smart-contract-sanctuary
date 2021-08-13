/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

/** [at]33.RocketFuel | Basic Contract based on [at]33.Dinah/0Dinah. 
*   Log:
* + Automatic Burn
* + Buy (5% fee) 
*   –	2% marketing and futher development (devFee)
*   –	3% added as a liquidity token on "Pancake swap" (swapBFee)
* + Sell  (25% fee)
*   -   5% reflection fee (reflectFee)
*   –	0% sadded as a liquidity token on "Pancake swap"  (swapSFee) -> used only if we want to remove the buyTax and use only a sellTax
*   -   20% automaticaly burn fee - removed when 90% of supply is burned
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

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



//[at]33.Ariel #lib | Provides information about the current execution context, including the sender of the transaction and its data. While these are generally available via msg.sender and msg.data, they should not be accessed in such a direct manner, since when dealing with GSN meta-transactions the account sending and paying for execution may not be the actual sender (as far as an application is concerned). This contract is only required for intermediate, library-like contracts.
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address ) {
        return payable (msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//[at]33.Ariel #lib | Wrappers over Solidity's arithmetic operations with added overflow
library SafeMath {

    //[at]33.Ariel | Returns the addition of two unsigned integers, reverting on overflow. Counterpart to Solidity's `+` operator. !IMP: - Addition cannot overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    //[at]33.Ariel | Returns the subtraction of two unsigned integers, reverting on overflow (when the result is negative). Counterpart to Solidity's `-` operator. !IMP: - Subtraction cannot overflow.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    //[at]33.Ariel | Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is negative). Counterpart to Solidity's `-` operator. !IMP: - Subtraction cannot overflow.
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    //[at]33.Ariel | Returns the multiplication of two unsigned integers, reverting on overflow. Counterpart to Solidity's `*` operator. Requirements: - Multiplication cannot overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the benefit is lost if 'b' is also tested. See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    //[at]33.Ariel | Returns the integer division of two unsigned integers. Reverts on division by zero. The result is rounded towards zero. Counterpart to Solidity's `/` operator. Note: this function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). !IMP: - The divisor cannot be zero.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    //[at]33.Ariel | Returns the integer division of two unsigned integers. Reverts with custom message on division by zero. The result is rounded towards zero. Counterpart to Solidity's `/` operator. Note: this function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). !IMP: - The divisor cannot be zero.
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    //[at]33.Ariel | Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts when dividing by zero. Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). !IMP: - The divisor cannot be zero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    //[at]33.Ariel | Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts with custom message when dividing by zero. Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). !IMP: - The divisor cannot be zero.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//[at]33.Ariel #Mod | Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions. By default, the owner account will be the one that deploys the contract. This can later be changed with {transferOwnership}. This module is used through inheritance. It will make available the modifier `onlyOwner`, which can be applied to your functions to restrict their use to the owner.
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //[at]33.Ariel |  Initializes the contract setting the deployer as the initial owner. 
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    //[at]33.Ariel | Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    //[at]33.Ariel | Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(_owner == _msgSender(), "@33EVE: This caller is not the owner.");
        _;
    }

    //[at]33.Ariel | Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    //[at]33.Ariel | Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    //[at]33.Ariel | Transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "@33EVE: The new owner is the zero address.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//[at]33.Ariel #Lib | Returns true if `account` is a contract. !IMP: It is unsafe to assume that an address for which this function returns false is an externally-owned account (EOA) and not a contract. Among others, `isContract` will return false for the following types of addresses: - an externally-owned account - a contract in construction - an address where a contract will be created - an address where a contract lived, but was destroyed
library Address {
    function isContract(address account) internal view returns (bool) {
        //[at]33.Ariel | According to EIP-1052, 0x0 is the value returned for not-yet created accounts and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    //[at]33.Ariel | Replacement for Solidity's `transfer`: sends `amount` wei to `recipient`, forwarding all available gas and reverting on errors. https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost of certain opcodes, possibly making contracts go over the 2300 gas limit imposed by `transfer`, making them unable to receive funds via `transfer`. {sendValue} removes this limitation. https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/!IMP: because control is transferred to `recipient`, care must be taken to not create reentrancy vulnerabilities. Consider using {ReentrancyGuard} or the https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    //[at]33.Ariel | Performs a Solidity function call using a low level `call`. A plain`call` is an unsafe replacement for a function call: use this function instead. If `target` reverts with a revert reason, it is bubbled up by this function (like regular Solidity function calls). Returns the raw returned data. To convert to the expected return value, use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions. !IMP: - `target` must be a contract. - calling `target` with `data` must not revert.
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    //[at]33.Ariel | Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with `errorMessage` as a fallback revert reason when `target` reverts.
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    //[at]33.Ariel | Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but also transferring `value` wei to `target`. !IMP: - the calling contract must  - the called Solidity function must be `payable`.
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    //[at]33.Ariel | Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but with `errorMessage` as a fallback revert reason when `target` reverts.
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


contract RocketFuelToken is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) private _isMerchant;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 80 * 10 ** 9 * 10 ** 6; //80B //[at]33.RocketFuel
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _bTotal = 8 * 10 ** 9 * 10 ** 6; //8B //[at]33.RocketFuel: Final Supply
    uint256 public _maxTxAmount = 5 * 10**7 * 10**6; // maximum ammount allowed in one transfer 50 Millions
      

    string private _name = "RocketFuel";
    string private _symbol = "RocketFuel";
    uint8 private _decimals = 6;
    

    // on buy
    uint256 public _devFee = 40; //[at]33.DINAH0
    uint256 public _swapBFee = 60; //[at]33.DINAH0 | Swap Buy Fee
   
    // on sale
    uint256 public _reflectFee = 20; //[at]33.DINAH0
    uint256 public _swapSFee = 0; //[at]33.DINAH0 | Swap Sell Fee
    uint256 public _burnFee = 80; //[at]33.DINAH0

    // used for the remove and restore all taxes
    uint256 public _taxSell = 25; 
    uint256 private _pTaxSell = _taxSell;
    
    uint256 public _taxBuy = 5; 
    uint256 private _pTaxBuy = _taxBuy;

    

    //[at]33.DINAH0 | The address where the fees are send
    address private _devAddress = payable (0x5B103981a4cDB448beE16bC674d6D38F7C1670fe);
    address private _swapAddress = payable (0xE01512Fc3fc2F9b4181a50198587634CAa0aa773);
    //[at]33.CALAH0 | The address of token owner
    address private _ownerAddress = payable (0x7694D61bEe498f87aF835ae956a4dB9186f3F67E);
    address private _charityAddress = payable (0xc53ED222FCc3B1762962916a436be17Ede30b719);
    address private _dropsAddress = payable (0x20d7476c5b533F79A5643320F3540390D415B181);
    address private _burnAddress = payable (0x000000000000000000000000000000000000dEaD);


    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_swapAddress] = true;
        _isExcludedFromFee[_dropsAddress] = true;
        _isExcludedFromFee[_burnAddress] = true;
        
        _isMerchant[_charityAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


///////////////////////////////  
    // Public Function Calls
///////////////////////////////

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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function isMerchant(address account) public view returns(bool) {
        return _isMerchant[account];
    }
    //[at]33.RocketFuel
    function totalFinalSupplyAfterBurn() public view returns (uint256) {
        return _bTotal;
    }
 
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    
///////////////////////////////  
    // Admin Function Calls
///////////////////////////////
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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
    
    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    
    function addMerchant(address account) public onlyOwner() {
        _isMerchant[account] = true;
    }
    
    function removeMerchant(address account) public onlyOwner() {
        _isMerchant[account] = false;
    }
   
   //[at]33.RocketFuel | Changes the Fees. 
    function setDevFeePercent(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
    }
    function setSwapBuyFeePercent(uint256 swapBFee) external onlyOwner() {
        _swapBFee = swapBFee;
    }
    
    function setSwapSellFeePercent(uint256 swapSFee) external onlyOwner() {
        _swapSFee = swapSFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }
    function setReflectionFeePercent(uint256 reflectFee) external onlyOwner() {
        _reflectFee = reflectFee;
    }
    
    function setSellTaxPercent(uint256 sellTax) external onlyOwner() {
        _taxSell = sellTax;
    }
    
    function setBuyTaxPercent(uint256 buyTax) external onlyOwner() {
        _taxBuy = buyTax;
    }
    
    //[at]33.RocketFuel | Changes the Fee Addresses.
    function setDevAddress(address devAddress) external onlyOwner() {
        _devAddress = devAddress;
    }

    function setSwapAddress(address swapAddress) external onlyOwner() {
        _swapAddress = swapAddress;
    }
    function setCharityAddress(address charityAddress) external onlyOwner() {
        _charityAddress = charityAddress;
    }
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div( 10**2);
    }
    
    function setAirdropsAddress(address dropsAddress) external onlyOwner() {
        _dropsAddress = dropsAddress;
    }
    

///////////////////////////////  
    // Internal Function
///////////////////////////////
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,uint256 rSell,uint256 rBuy,uint256 tSell,uint256 tBuy) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount.add(tSell), "RocketFuel: The transfer amount exceeds balance (tbe-t).");
        _rOwned[sender] = _rOwned[sender].sub(rAmount.add(rSell), "RocketFuel: The transfer amount exceeds balance (tbe-r).");
        
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.sub(tBuy));
        _rOwned[recipient] = _rOwned[recipient].add(rAmount.sub(rBuy));   
        
       _sendBuyFee(tBuy);
       _reflectFees(tSell);
        emit Transfer(sender, recipient, tAmount);
    }
    
    function _reflectFees(uint256 tSell) private {
        uint256 currentRate =  _getRate();
        
        uint256 tSendBurn = tSell.mul(_burnFee).div(10**2);
        uint256 tSendSwapS = tSell.mul(_swapSFee).div(10**2);
        uint256 tReflect = tSell.mul(_reflectFee).div(10**2);


        uint256 rReflect = tReflect.mul(currentRate);
        uint256 rSendSwapS = tSendSwapS.mul(currentRate);
        uint256 rSendBurn = tSendBurn.mul(currentRate);
            
        _rTotal = _rTotal.sub(rReflect);
        _tFeeTotal = _tFeeTotal.add(tReflect);
        
        
         if(_isExcluded[_swapAddress]) {
             _tOwned[_swapAddress] = _tOwned[_swapAddress].add(tSendSwapS);
         } else {
             _rOwned[_swapAddress] = _rOwned[_swapAddress].add(rSendSwapS);
         }
         
         //????
        if (_burnFee > 0 && _bTotal < _tTotal) {
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tSendBurn);
            _tTotal = _tTotal.sub(tSendBurn);
            _rTotal = _rTotal.sub(rSendBurn);
        }
    }
    
    function _sendBuyFee(uint256 tBuy) private {
        uint256 currentRate =  _getRate();
   
        
        uint256 tSendDev = tBuy.mul(_devFee).div(100);
        uint256 tSendSwapB = tBuy.mul(_swapBFee).div(100);
        
        uint256 rSendDev = tSendDev.mul(currentRate);
        uint256 rSendSwapB = tSendSwapB.mul(currentRate);
        
         if(_isExcluded[_swapAddress]) {
             _tOwned[_swapAddress] = _tOwned[_swapAddress].add(tSendSwapB);
         } else {
             _rOwned[_swapAddress] = _rOwned[_swapAddress].add(rSendSwapB);
         }
         
         if(_isExcluded[_devAddress]) {
             _tOwned[_devAddress] = _tOwned[_devAddress].add(tSendDev);
         } else {
             _rOwned[_devAddress] = _rOwned[_devAddress].add(rSendDev);
         }
         
      
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        ( uint256 tSell, uint256 tBuy) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rBuy, uint256 rSell) = _getRValues(tAmount, tSell, tBuy, _getRate());
        return (rAmount, rBuy, rSell, tSell, tBuy );
    }

    function _getTValues(uint256 tAmount) private view returns ( uint256, uint256) {
        uint256 tSell = calculateTaxSell(tAmount);
        uint256 tBuy = calculateTaxBuy(tAmount);

        return ( tSell, tBuy);
    }

    function _getRValues(uint256 tAmount, uint256 tSell, uint256 tBuy, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rSell = tSell.mul(currentRate);
        uint256 rBuy = tBuy.mul(currentRate);

        return (rAmount, rBuy, rSell);
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
    
    
    
    
    function calculateTaxSell(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxSell).div(
            10**2
        );
    }

    function calculateTaxBuy(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxBuy).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxSell == 0 && _taxBuy == 0) return;
        
        _pTaxSell = _taxSell;
        _pTaxBuy = _taxBuy;
        
        _taxSell = 0;
        _taxBuy = 0;
    }
    
    function removeSellFee() private {
        if(_taxSell == 0) return;
        
        _pTaxSell = _taxSell;

        _taxSell = 0;
    }
    
    function removeBuyFee() private {
        if(_taxBuy == 0) return;
        
        _pTaxBuy = _taxBuy;
        
        _taxBuy = 0;
    }
    
    function restoreAllFee() private {
        _taxSell = _pTaxSell;
        _taxBuy = _pTaxBuy;
    }
    


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "SunFuel: Transfer amount exceeds the maximum allowed per transaction (maxTxAmount).");

       
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        bool takeSellFee = true;
        bool takeBuyFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isMerchant[from] || _isMerchant[to]) {
            takeSellFee = false;
        } else if (_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            takeSellFee = false;
        } else if (!_isExcludedFromFee[from] && _isExcludedFromFee[to]) {
            takeBuyFee = false;
        } else if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
             takeFee = true;
        } else if (_isExcludedFromFee[from] && _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            takeFee = true;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee, takeSellFee, takeBuyFee);
    }




    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool takeSellFee, bool takeBuyFee) private {
        if(!takeFee) removeAllFee();
        if (!takeSellFee) removeSellFee();
        if (!takeBuyFee) removeBuyFee();
        
        
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
        
        if(!takeFee || !takeSellFee || !takeBuyFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rBuy, uint256 rSell, uint256 tSell, uint256 tBuy) = _getValues(tAmount);
       
        _rOwned[sender] = _rOwned[sender].sub(rAmount.add(rSell), "RocketFuel: The transfer amount + fees exceeds balance. (ts-r)");
        _rOwned[recipient] = _rOwned[recipient].add(rAmount.sub(rBuy));
        
        _sendBuyFee(tBuy); 
        _reflectFees(tSell); 
    
        
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount,uint256 rBuy, uint256 rSell, uint256 tSell,uint256 tBuy ) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount.add(rSell), "RocketFuel: The transfer amount+fee exceeds balance.");
       
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.sub(tBuy));
        _rOwned[recipient] = _rOwned[recipient].add(rAmount.sub(rBuy));           
        
   
    
        _sendBuyFee(tBuy); 
        _reflectFees(tSell); 
      
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rBuy,uint256 tBuy,uint256 rSell,uint256 tSell) = _getValues(tAmount);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount.add(tSell), "RocketFuel: The transfer amount + fee exceeds balance. (tfe-t)");
        _rOwned[sender] = _rOwned[sender].sub(rAmount.add(rSell), "RocketFuel: The transfer amount + fees exceeds balance. (tfe-r)");
        
        _rOwned[recipient] = _rOwned[recipient].add(rAmount.sub(rBuy));   
       

        _sendBuyFee(tBuy); 
        _reflectFees(tSell);   
        
        
        emit Transfer(sender, recipient, tSell);
    }
    
   
}
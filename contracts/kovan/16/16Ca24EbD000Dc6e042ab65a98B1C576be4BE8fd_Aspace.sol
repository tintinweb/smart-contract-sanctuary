//SPDX-License-Identifier: GPL-3.0-or-later
//Author: Aspace Dev team

/***  Foreword:
 *    The code of Aspace is meant to be read and understood.
 *    It is a product of honesty and transparent practices, and through it,
 *    we aim to build a paradigm for other projects in this space.
 *    We feel this is how code should be written -- extroverted in nature.
 *
 *    Aspace Protocol has been developed in close coordination with the Bluechain Development Team, 
 *    through a very productive and enjoyable partnership. We are thankful for our time together, guys.
 *    For technology-related inquiries, contact them or us. We're here to support our technology.
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/***
 *     ________   ________   ________   ________   ________   _______      
 *    |\   __  \ |\   ____\ |\   __  \ |\   __  \ |\   ____\ |\  ___ \     
 *    \ \  \|\  \\ \  \___|_\ \  \|\  \\ \  \|\  \\ \  \___| \ \   __/|    
 *     \ \   __  \\ \_____  \\ \   ____\\ \   __  \\ \  \     \ \  \_|/__  
 *      \ \  \ \  \\|____|\  \\ \  \___| \ \  \ \  \\ \  \____ \ \  \_|\ \ 
 *       \ \__\ \__\ ____\_\  \\ \__\     \ \__\ \__\\ \_______\\ \_______\
 *        \|__|\|__||\_________\\|__|      \|__|\|__| \|_______| \|_______|
 *                  \|_________|                                           
 *                                                                         
 *                                                                         
 */
contract Aspace is Context, IERC20, Pausable, Ownable {
    //  This again is an OpenZeppelin library, filled with address-related utilities.
    //  Among others, it implements EIP-1884 for transfers, saving us gas. 
    using Address for address;
    
    //  These are overloaded from the IERC20 interface.
    //  Default decimals were 18. Note that this information is only used for _display_ purposes:
    //  in no way does it affect *any* of the arithmetic of the contract,
    //  including {IERC20-balanceOf} and {IERC20-transfer}.
    string private _name = "Aspace";
    string private _symbol = "AETH";
    uint8 private _decimals = 11;
        
    //  These two call the inherited functions _pause() and _unpause of Pausable, and can help us during emergencies.
    //  Along with the use of the whenNotPaused/whenPaused modifiers, we can temporarily halt the smart contract when something bad is happening, to buy us time and save user funds and data.
    //  We really like these circuit breakers.
    function pause() public onlyOwner { _pause(); }
    function unpause() public onlyOwner { _unpause(); }
    // Pausable functionality is usually used in conjuction with ERC20 inheritance. In this contract however, we inherit IERC20, which is an interface.
    // Inheriting ERC20 instead of IERC20 will require is to implement minting and burning methods.
    // TODO: Maybe extend this in the future? For now, however, we don't need this functionality.
    /***
     *    function _beforeTokenTransfer(address from, address to, uint256 amount)
     *    internal
     *    whenNotPaused
     *    override
     *    {
     *        super._beforeTokenTransfer(from, to, amount);
     *    }
     */
    
    //  The situation with rOwned and tOwned, and rTotal and tTotal, and everything else is a mess, we know. It's a trend that started with SAFEMOON.
    //  We shall make a short attempt at explaining what's going on, for clarity's sake.
    //  >> t << stands for Taken, >> r << stands for Reflected.
    // _rOwned and _tOwned are 2 ownership mappings that contantly struggle to maintain a stable ratio between each other.
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    
    //  _allowances is standard ERC20 logic. It represnets how much of a coin someone ELSE is allowed to trade, in your name.
    //  So and allowance of (0x10, 0x20, 5000 * decimals) says that address 0x10 allows 0x20 to spend 5000 tokens in his name.
    //  This is absolutely required when integrating with DEXes like uniswap or pancakeswap, because the DEX is essentially trading in your name...
    mapping(address => mapping(address => uint256)) private _allowances;
    
    //  The following mappings maintain addresses that are excluded from Reflections, and/or excempt from Fees during outwards transfers of TRFM tokens.
    //  For example, the contract deployer gets marked as "Feeless" in the constructor -- therefore, all TRFM transfers by him incur no fees.
    //  NOTE: mappings in Solidity and the EVM aren't iterateable by themselves. By using an additional Lookup Table (LUT), we are able to iterate over them, should we need to.
    mapping(address => bool) private _isExcluded;
    address[] private _excludedLUT;
    mapping(address => bool) private _isFeeless;

    uint256 private constant MAX = ~uint256(0); // equivalent to (2^256)-1, or ~1.1579e+77. Absurdly huge.
    uint256 private constant _tTotal = 1 * (10 ** 9) * (10 ** 11); // This is the Total Supply of the token. here, it's 10 Billion (10, times 1 billion, times decimals)
                                                                    // Why do we multiply by decimals? Because Solidity hates non-integer (float) multiplication,
                                                                    // so in order to maintain accuracy, we multiply by a huge decimal integer, calculate stuff, then divide back down.
                                                                    // NOTE: _tTotal is a MUCH smaller number than Reflections Total (_rTotal): 10^21 compared to ~1.1579e+77
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal; // stores and maintains all fees 
    uint256 private _tFeePercent = 4;
    
    //  Our events! They are emitted towards the off-blockchain world, so that event listeners on outside services
    //  such as Etherscan can capture them and tell us what's going on. Events are an efficient little way for a smart contract to create logs.
    event MarkedFeeless(address indexed account, bool isFeeless);
    //  Events not declared here, but inherited from Context, IERC20 and Ownable:
    //      event Transfer(address indexed from, address indexed to, uint256 value);
    //      event Approval(address indexed owner, address indexed spender, uint256 value);
    //      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    //  Runs once, on contract creation. Makes the deployer of the contract as the first and full owner of all tokens, and marks him as feeless.
    constructor () {
        _rOwned[_msgSender()] = _rTotal; // rOwned[deployer_address] should be == ((2^256)-1) - ((2^256)-1)mod(10^21) == ((2^256)-1) - 4.5758e+20 == ((2^256)-1) but with the last 21 digits being 0.
                                         // So: just a little bit smaller than ((2^256)-1), still absurdly high, and with 21 trailing 0s
                                         // Absolute values for your reference, to help you visualise it:
                                         // ((2^256)-1) == 115792089237316195423570985008687907853269984665640564039457584007913129639935
                                         //     _rTotal == 115792089237316195423570985008687907853269984665640564039000000000000000000000
        _isFeeless[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
        emit MarkedFeeless(_msgSender(), true);
    }
    
    //  All these are simple getters, as per the ERC20 specification.
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    //  We're keeping this separate just to showcase to readers that _tTotal really just refers to the Token's Total Supply
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    /***
     *   Here's all our VIEW functions. These are free to execute (no gas fee),
     *   as they do not cause a change in the smart contract's internal storage (state). They just read it.
     */   
    function balanceOf(address account) external view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    //  How much an address is capable of transferring in lieu of another address.
    //  This "approved, separate spender" mechanism is required by DEXes. The DEX Router contract is essentially trading tokens in your name.
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // Is an address a valid candidate for receiving reflections?
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    // Does an address have to pay tax to transfer out? NOTE: A Feeless address isn't necessarily also Tax Excluded, keep that in mind in other protocols as well :-)
    function isFeeless(address account) public view returns (bool) {
        return _isFeeless[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        return _getValues(tAmount, false);
    }

    function _getValues(uint256 tAmount, bool isFeeless_) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount, isFeeless_);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount, bool isFeeless_) private view returns (uint256, uint256) {
        if (isFeeless_) {
            return (tAmount, 0);
        }

        uint256 tFee = (tAmount * _tFeePercent) / 100;
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }
    
    //  Our exchange rate between the to-be-redistributed supply, and the "actual", real supply of the token as we've set it up.
    //  Essentially, the rate at which reflection Amounts get converted to real tokens.
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        
        uint n = _excludedLUT.length;
        for (uint256 i = 0; i < n; i++) {
            // This is a rather strange structure. 
            // It's a circuit breaker, meant to just dump calculations in this function, when it detects that an excludedFromReflections address
            // "owns" more than the total reflection supply, or the token supply.
            // But we can't easily discern when this circuit breaker would get triggered. Starting from the constructor,
            // the _rOwned[deployer] starts at == rTotal, not higher, then gradually gets less and less because to get reflections, you gotta transfer outwards.
            // TODO: Research this further.
            if (_rOwned[_excludedLUT[i]] > rSupply || _tOwned[_excludedLUT[i]] > tSupply) {
                return (_rTotal, _tTotal);
            }
            rSupply = rSupply - _rOwned[_excludedLUT[i]];
            tSupply = tSupply - _tOwned[_excludedLUT[i]];
        }
        
        if (rSupply < _rTotal / _tTotal) {
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    /***
     *   And here's our regular functions. These require a gas fee to run (calculated as gas_limit * gas_price, as per usual),
     *   because they cause changes in the smart contract's internal storage (state).
     *   NOTE: While the user is in charge of gas_price (he's free to pay as much as he wants),  
     *         the second component of the gas_fee calculation is dependent on us:
     *         The more complex the function and more calculate-y it is, the higher gas_limit is.
     *         Minimalism of operations in the context of regular functions goes a long way to minimize our Users' fees.  
     */  
    function transfer(address recipient, uint256 amount) external whenNotPaused override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external whenNotPaused override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function excludeAccount(address account) external onlyOwner() {
        require(account != address(this), "Cannot exclude self contract");
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excludedLUT.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        uint n = _excludedLUT.length;
        for (uint256 i = 0; i < n; i++) {
            if (_excludedLUT[i] == account) {
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excludedLUT[i] = _excludedLUT[_excludedLUT.length - 1];
                _excludedLUT.pop();
                break;
            }
        }
    }

    function setFeeless(address account, bool isFeeless_) external onlyOwner() {
        _isFeeless[account] = isFeeless_;
        emit MarkedFeeless(account, isFeeless_);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from address(0)");
        require(spender != address(0), "ERC20: approve to address(0)");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /***
     *   The main workhorse function of Aspace and any interfaced ERC20 token, tbh.
     *   This method below is a wrapper function.
     *   According to what type (normal, feeless, excluded etc) the sender and recipient address are,
     *   the respective sub-transfer function is called. These are the following:
     *      >> func _transferStandard: The normal transfer method. Normal tax is paid, and reflected to other users.
     *      >> func _transferToExcluded: The recipient only receives "true" tokens, and no reflectionary tokens from this transaction.
     *      >> func _transferFromExcluded: 
     *      >> func _transferBothExcluded:
     */
    function _transfer(address sender, address recipient, uint256 amount) private whenNotPaused {
        require(sender != address(0), "ERC20: transfer from address(0)");
        require(recipient != address(0), "ERC20: transfer to address(0)");
        require(amount > 0, "Transfer amount must be >0");
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

    function _transferStandard(address sender, address recipient, uint256 tAmount) private whenNotPaused {
        bool isFeelessTx = _isFeeless[sender] || _isFeeless[recipient];
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount, isFeelessTx);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private whenNotPaused {
        bool isFeelessTx = _isFeeless[sender] || _isFeeless[recipient];
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount, isFeelessTx);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private whenNotPaused {
        bool isFeelessTx = _isFeeless[sender] || _isFeeless[recipient];
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount, isFeelessTx);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private whenNotPaused {
        bool isFeelessTx = _isFeeless[sender] || _isFeeless[recipient];
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount, isFeelessTx);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    /* Function to set taxation (reflection) fees. To be used post-deployment */
    function setFeePercent(uint256 fee) external onlyOwner {
        require(fee >= 1, "Fee: Too small");
        require(fee <= 10, "Fee: Too big");
        _tFeePercent = fee;
    }
}

/* I'm deployng this token accompanied by a wish,
 * to let this protocol be healthy at its launch,
 * its technology innovative and robust,
 * and its people sturdy and strong, in failure and in success alike.
 * Whatever the future holds guys, we're here to make Aspace a reality.
 */

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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
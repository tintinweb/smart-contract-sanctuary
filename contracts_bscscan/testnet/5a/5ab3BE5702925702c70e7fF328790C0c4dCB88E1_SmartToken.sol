// SPDX-License-Identifier: MIT

/**
 * Smart Token
 * @author Liu
 */

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './libs/IBEP20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IUniswapRouter.sol';
import './interfaces/IUniswapFactory.sol';
import './interfaces/IUniswapPair.sol';
import './interfaces/IGoldenTreePool.sol';
import './interfaces/ISmartArmy.sol';
import './interfaces/ISmartLadder.sol';
import './interfaces/ISmartFarm.sol';
import './interfaces/ISmartAchievement.sol';


contract SmartToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public immutable BUSD_ADDRESS;
    address public immutable _uniswapV2ETHPair;
    address public immutable _uniswapV2BUSDPair;
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;


    address public _operator; 
    address public _smartArmy;
    
    // tax addresses
    address public _referralAddress;
    address public _goldenTreePoolAddress;
    address public _devAddress;
    address public _achievementSystemAddress;
    address public _farmingRewardAddress;
    address public _intermediaryAddress;

    // tax information
    uint256 public _buyTaxFee = 15; // 15% 
    uint256 public _sellTaxFee = 15; // 15%
    uint256 public _transferTaxFee = 15; // 15%

    uint256[] public _sellTaxTierDays = [10, 10, 10, 10];
    uint256[] public _sellTaxTiers    = [30, 25, 20, 15];
    uint256 private _start_timestamp = block.timestamp;

    uint256 public BUY_REFERRAL_FEE = 50; 
    uint256 public BUY_GOLDEN_TREE_POOL_FEE = 30;
    uint256 public BUY_DEV_FEE = 10;
    uint256 public BUY_ARCHIVEMENT_FEE = 10;

    uint256 public SELL_DEV_FEE = 10;
    uint256 public SELL_GOLDEN_TREE_POOL_FEE = 30;
    uint256 public SELL_FARMING_FEE = 20;
    uint256 public SELL_BURN_FEE = 30;
    uint256 public SELL_ARCHIVEMENT_FEE = 10;

    uint256 public TRANSFER_DEV_FEE = 10;
    uint256 public TRANFER_ARCHIVEMENT_FEE = 10;
    uint256 public TRANSFER_GOLDEN_TREE_POOL_FEE = 50;
    uint256 public TRANSFER_FARMING_FEE = 30;

    uint256 public _numTokensSwap = 0; //50000e18;

    bool _inSwapEnabled;
    bool public _swapEnabled;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _excludedFromFee;

    event SwapEnabledUpdate(bool enabled);
    event TaxAddressesUpdated(address referral, address goldenTree, address dev, address achievement, address farming);



    modifier onlyOperator() {
        require(_operator == msg.sender || msg.sender == owner(), "SMT: caller is not the operator");
        _;
    }

    modifier lockTheSwap {
        _inSwapEnabled = true;
        _;
        _inSwapEnabled = false;
    }    

    /**
     * @dev Sets the values for BUSD_ADDRESS, {totalSupply} and tax addresses
     *
     */
    constructor(
        address busd, 
        uint256 mintSupply, 
        address referral, 
        address goldenTree, 
        address dev, 
        address achievement, 
        address farming,
        address intermediary,
        address smartArmy) 
    {
        _name = "Smart Token";
        _symbol = "SMT";
        _decimals = 18;


        BUSD_ADDRESS = busd;
        _operator = msg.sender;
        _referralAddress = referral;
        _goldenTreePoolAddress = goldenTree;
        _devAddress = dev;
        _achievementSystemAddress = achievement;
        _farmingRewardAddress = farming;
        _intermediaryAddress = intermediary;

        _smartArmy = smartArmy;

        // Pancake V2 router
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 

        _uniswapV2Router = uniswapRouter;

        // Create a pair with ETH
        _uniswapV2ETHPair = IUniswapV2Factory(uniswapRouter.factory())
            .createPair(address(this), uniswapRouter.WETH());

        // Create a pair with BUSD
        _uniswapV2BUSDPair = IUniswapV2Factory(uniswapRouter.factory())
            .createPair(address(this), busd);

        _excludedFromFee[msg.sender] = true;
        _excludedFromFee[address(this)] = true;
        _excludedFromFee[BURN_ADDRESS] = true;
        _excludedFromFee[_referralAddress] = true;
        _excludedFromFee[_goldenTreePoolAddress] = true;
        _excludedFromFee[_devAddress] = true;
        _excludedFromFee[_achievementSystemAddress] = true;
        _excludedFromFee[_farmingRewardAddress] = true;
        _excludedFromFee[_smartArmy] = true;

        _mint(msg.sender, mintSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'SMT: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'SMT: decreased allowance below zero'));
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
    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 'SMT: transfer from the zero address');
        require(recipient != address(0), 'SMT: transfer to the zero address');
        _balances[sender] = _balances[sender].sub(amount, 'SMT: transfer amount exceeds balance');

        if (_excludedFromFee[sender] || _excludedFromFee[recipient]) {
            _balances[recipient] = _balances[recipient].add(amount);
        } else {
            bool toPair = recipient == _uniswapV2ETHPair || recipient == _uniswapV2BUSDPair;
            bool fromPair = sender == _uniswapV2ETHPair || sender == _uniswapV2BUSDPair;
            
            if(sender == _intermediaryAddress && toPair) {
                // Intermediary => Pair: No Fee

                _balances[recipient] = _balances[recipient].add(amount);
            } 
            else if(fromPair && recipient == _intermediaryAddress) {
                // Pair => Intermediary: No Fee

                _balances[recipient] = _balances[recipient].add(amount);
            }
            else if(sender == _intermediaryAddress || recipient == _intermediaryAddress) {
                if (recipient == _intermediaryAddress) {
                    require(enabledIntermediary(sender), "SMT: no smart army account");
                    // sell transfer via intermediary: sell tax reduce 30%
                    uint256 sellTaxPercent = _getCurrentSellTax().mul(700).div(1000);
                    uint256 taxAmount1 = amount.mul(sellTaxPercent).div(100);
                    uint256 recvAmount1 = amount.sub(taxAmount1);
                    
                    distributeSellTax(taxAmount1, sender);
                    
                    _balances[recipient] = _balances[recipient].add(recvAmount1);

                }
                else {
                    require(enabledIntermediary(recipient), "SMT: no smart army account");
                    // buy transfer via intermediary: buy tax reduce 30%
                    uint256 taxAmount2 = amount.mul(_buyTaxFee.mul(700).div(1000)).div(100);
                    uint256 recvAmount2 = amount.sub(taxAmount2);
                    
                    distributeBuyTax(taxAmount2, recipient);
                    
                    _balances[recipient] = _balances[recipient].add(recvAmount2);
                    
                } 
            }
            else if (fromPair) {
                // buy transfer
                uint256 taxAmount3 = amount.mul(_buyTaxFee).div(100);
                uint256 recvAmount3 = amount.sub(taxAmount3);
                
                distributeBuyTax(taxAmount3, recipient);

                _balances[recipient] = _balances[recipient].add(recvAmount3);
            } else if (toPair) {
                // sell transfer                
                uint256 taxAmount4 = amount.mul(_getCurrentSellTax()).div(100);
                uint256 recvAmount4 = amount.sub(taxAmount4);
                
                distributeSellTax(taxAmount4, sender);

                // !!! should be called after distribute!
                _balances[recipient] = _balances[recipient].add(recvAmount4);
            } else {
                // normal transfer
                uint256 taxAmount5 = amount.mul(_transferTaxFee).div(100);
                uint256 recvAmount5 = amount.sub(taxAmount5);
                
                distributeTransferTax(taxAmount5, sender);
                
                _balances[recipient] = _balances[recipient].add(recvAmount5);     
            }
        }

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Distributes sell tax tokens to tax addresses
     */
    function distributeSellTax (uint256 amount, address account) internal {

        uint256 devAmount = amount.mul(SELL_DEV_FEE).div(100);
        uint256 goldenTreeAmount = amount.mul(SELL_GOLDEN_TREE_POOL_FEE).div(100);
        uint256 farmingAmount = amount.mul(SELL_FARMING_FEE).div(100);
        uint256 burnAmount = amount.mul(SELL_BURN_FEE).div(100);
        uint256 achievementAmount = amount.mul(SELL_ARCHIVEMENT_FEE).div(100);

        _balances[_devAddress] = _balances[_devAddress].add(devAmount);
        _balances[_farmingRewardAddress] = _balances[_farmingRewardAddress].add(farmingAmount);
        _balances[BURN_ADDRESS] = _balances[BURN_ADDRESS].add(burnAmount);
        _balances[_achievementSystemAddress] = _balances[_achievementSystemAddress].add(achievementAmount);
        _balances[_goldenTreePoolAddress] = _balances[_goldenTreePoolAddress].add(goldenTreeAmount);
        
        distributeTaxToGoldenTreePool(account, goldenTreeAmount);

        if(farmingAmount > 0) {
            distributeSellTaxToFarming(farmingAmount);
        }
    } 

    /**
     * @dev Distributes buy tax tokens to tax addresses
     */
    function distributeBuyTax(uint256 amount, address account) internal {

        uint256 referralAmount = amount.mul(BUY_REFERRAL_FEE).div(100);
        uint256 goldenTreeAmount = amount.mul(BUY_GOLDEN_TREE_POOL_FEE).div(100);
        uint256 devAmount = amount.mul(BUY_DEV_FEE).div(100);
        uint256 achievementAmount = amount.mul(BUY_ARCHIVEMENT_FEE).div(100);

        _balances[_devAddress] = _balances[_devAddress].add(devAmount);
        _balances[_referralAddress] = _balances[_referralAddress].add(referralAmount);
        _balances[_achievementSystemAddress] = _balances[_achievementSystemAddress].add(achievementAmount);
        _balances[_goldenTreePoolAddress] = _balances[_goldenTreePoolAddress].add(goldenTreeAmount);

        distributeBuyTaxToLadder(account);
        distributeTaxToGoldenTreePool(account, goldenTreeAmount);
    }

    /**
     * @dev Distributes transfer tax tokens to tax addresses
     */
    function distributeTransferTax (uint256 amount, address account) internal {

        uint256 devAmount = amount.mul(TRANSFER_DEV_FEE).div(100);
        uint256 farmingAmount = amount.mul(TRANSFER_FARMING_FEE).div(100);
        uint256 goldenTreeAmount = amount.mul(TRANSFER_GOLDEN_TREE_POOL_FEE).div(100);
        uint256 achievementAmount = amount.mul(TRANFER_ARCHIVEMENT_FEE).div(100);

        _balances[_devAddress] = _balances[_devAddress].add(devAmount);
        _balances[_farmingRewardAddress] = _balances[_farmingRewardAddress].add(farmingAmount);
        _balances[_achievementSystemAddress] = _balances[_achievementSystemAddress].add(achievementAmount);
        _balances[_goldenTreePoolAddress] = _balances[_goldenTreePoolAddress].add(goldenTreeAmount);
        
        distributeTaxToGoldenTreePool(account, goldenTreeAmount);
    } 

    /**
     * @dev Distributes buy tax tokens to smart ladder system
     */
    function distributeBuyTaxToLadder (address from) internal {
        ISmartLadder(_referralAddress).distributeBuyTax(from);
    } 

    /**
     * @dev Distributes sell tax tokens to farmming passive rewards pool
     */
    function distributeSellTaxToFarming (uint256 amount) internal {
        ISmartFarm(_farmingRewardAddress).notifyRewardAmount(amount);
    } 

    /**
     * @dev Distribute tax to golden Tree pool as SMT and notify
     */
    function distributeTaxToGoldenTreePool (address account, uint256 amount) internal {
        IGoldenTreePool(_goldenTreePoolAddress).notifyReward(amount, account);
    }



    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'SMT: mint to the zero address');

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'SMT: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'SMT: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'SMT: approve from the zero address');
        require(spender != address(0), 'SMT: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom (address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'SMT: burn amount exceeds allowance'));
    }



    /**
     * @dev Returns the address is excluded from burn fee or not.
     */
    function isExcludedFromFee (address account) public view returns (bool) {
        return _excludedFromFee[account];
    }

    /**
     * @dev Exclude the address from fee.
     */
    function excludeFromFee (address account) external onlyOperator {
        _excludedFromFee[account] = true;
    } 

    /**
     * @dev Sets value for _swapEnabled with {enabled}.
     */
    function setSwapEnabled (bool enabled) external onlyOperator {
        _swapEnabled = enabled;
        emit SwapEnabledUpdate(enabled);
    }      

    /**
     * @dev Sets value for _sellTaxFee with {sellTaxFee} in emergency status.
     */
    function setSellFee (uint256 sellTaxFee) external onlyOperator {
        require(sellTaxFee < 100, 'SMT: sellTaxFee exceeds maximum value');
        _sellTaxFee = sellTaxFee;
    }    

    /**
     * @dev Sets value for _buyTaxFee with {buyTaxFee} in emergency status.
     */
    function setBuyFee (uint256 buyTaxFee) external onlyOperator {
        require(buyTaxFee < 100, 'SMT: buyTaxFee exceeds maximum value');
        _buyTaxFee = buyTaxFee;
    }    

    /**
     * @dev Sets value for _transferTaxFee with {transferTaxFee} in emergency status.
     */
    function setTransferFee (uint256 transferTaxFee) external onlyOperator {
        require(transferTaxFee < 100, 'SMT: transferTaxFee exceeds maximum value');
        _transferTaxFee = transferTaxFee;
    }  

    /**
     * @dev start Sell Tax tier system again 
     */
    function resetStartTimestamp() external onlyOperator {
        _start_timestamp = block.timestamp;
    }   

    /**
     * @dev get current sellTax percent through sell tax tier system
     */
    function _getCurrentSellTax() public view returns (uint256) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        for(uint i = 0; i < _sellTaxTierDays.length; i++) {
            if(time_since_start < _sellTaxTierDays[i] * 24 * 3600) {
                return _sellTaxTiers[i];
            }
        }

        return _sellTaxFee;
    }   

    /**
     *  @dev Sets values for tax addresses 
     */
    function setTaxAddresses (address referral, address goldenTree, address dev, address achievement, address farming) external onlyOperator {

        if (_referralAddress != referral) {
            _referralAddress = referral;
            _excludedFromFee[referral] = true;
        }
        if (_goldenTreePoolAddress != goldenTree) {
            _goldenTreePoolAddress = goldenTree;
            _excludedFromFee[goldenTree] = true;
        }
        if (_devAddress != dev) {
            _devAddress = dev;
            _excludedFromFee[dev] = true;
        }
        if (_achievementSystemAddress != achievement) {
            _achievementSystemAddress = achievement;
            _excludedFromFee[achievement] = true;
        }
        if (_farmingRewardAddress != farming) {
            _farmingRewardAddress = farming;
            _excludedFromFee[farming] = true;
        }
        emit TaxAddressesUpdated(referral, goldenTree, dev, achievement, farming);
    }

    /**
     * @dev Sets value for _numTokensSwap with {numTokensSwap}
     */
    function setNumTokensSwap (uint256 numTokensSwap) external onlyOperator {
         require(numTokensSwap < _totalSupply, 'SMT: numTokensSwap exceeds total supply');
         _numTokensSwap = numTokensSwap;
    }


    /**
     * @dev Sets value for _goldenTreePoolAddress
     */
    function setGoldenTreeAddress (address _address) external onlyOperator {
        require(_address!= address(0x0), 'SMT: not allowed zero address');
        _goldenTreePoolAddress = _address;
    }

    /**
     * @dev Sets value for _smartArmy
     */
    function setSmartArmyAddress (address _address) external onlyOperator {
        require(_address!= address(0x0), 'SMT: not allowed zero address');
        _smartArmy = _address;
    }
    
    function enabledIntermediary (address account) public view returns (bool){
        if(_smartArmy == address(0x0)) {
            return false;
        }

        return ISmartArmy(_smartArmy).isEnabledIntermediary(account);
    }


     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGoldenTreePool {
    function swapDistribute() external;
    function notifyReward(uint256 amount, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISmartArmy {
    /// @dev License Types
    struct LicenseType {
        uint256  level;        // level
        string   name;         // Trial, Opportunist, Runner, Visionary
        uint256  price;        // 100, 1000, 5000, 10,000
        uint256  ladderLevel;  // Level of referral system with this license
        uint256  duration;     // default 6 months
        bool     isValid;
    }

    enum LicenseStatus {
        None,
        Pending,
        Active,
        Expired
    }

    /// @dev User information on license
    struct UserLicense {
        address owner;
        uint256 level;
        uint256 startAt;
        uint256 activeAt;
        uint256 expireAt;
        uint256 lpLocked;

        LicenseStatus status;
    }

    /// @dev User Personal Information
    struct UserPersonal {
        address sponsor;
        string username;
        string telegram;
    }

    /// @dev Fee Info 
    struct FeeInfo {
        uint256 penaltyFeePercent;      // liquidate License LP fee percent
        uint256 extendFeeBNB;       // extend Fee as BNB
        address feeAddress;
    }
    
    function licenseOf(address account) external view returns(UserLicense memory);
    function lockedLPOf(address account) external view returns(uint256);
    function isActiveLicense(address account) external view returns(bool);
    function isEnabledIntermediary(address account) external view returns(bool);
    function licenseLevelOf(address account) external view returns(uint256);
    function licenseActiveDuration(address account, uint256 from, uint256 to) external view returns(uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISmartLadder {
    /// @dev Ladder system activities
    struct Activity {
        string      name;         // buytax, farming, ...
        uint16[7]   share;        // share percentage
        address     token;        // share token address
        bool        enabled;      // enabled or disabled temporally
        bool        isValid;
        uint256     totalDistributed; // total distributed
    }
    
    function registerSponsor(address _user, address _sponsor) external;
    function distributeTax(uint256 id, address account) external; 
    function distributeBuyTax(address account) external; 
    function distributeFarmingTax(address account) external; 
    function distributeSmartLivingTax(address account) external; 
    function distributeEcosystemTax(address account) external; 
    
    function activity(uint256 id) external view returns(Activity memory);
    function sponsorOf(address account) external view returns(address);
    function sponsorsOf(address account, uint count) external returns (address[] memory); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISmartFarm {
    /// @dev Pool Information
    struct PoolInfo {
        address stakingTokenAddress;     // staking contract address
        address rewardTokenAddress;      // reward token contract

        uint256 rewardPerDay;            // reward percent per day

        uint unstakingFee;
            
        uint256 totalStaked;             /* How many tokens we have successfully staked */
    }


    struct UserInfo {
        uint256 balance;
        uint256 rewards;
        uint256 rewardPerTokenPaid;     // User rewards per token paid for passive
        uint256 lastUpdated;
    }
    
    function stakeSMT(address account, uint256 amount) external returns(uint256);
    function withdrawSMT(address account, uint256 amount) external returns(uint256);
    function claimReward() external;

    function notifyRewardAmount(uint _reward) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISmartAchievement {

    struct NobilityType {
        string            title;               // Title of Nobility Folks Baron Count Viscount Earl Duke Prince King
        uint256           growthRequried;      // Required growth token
        uint256           passiveShare;        // Passive share percent

        uint256[]         chestSMTRewards;
        uint256[]         chestSMTCRewards;
    }


    function notifyGrowth(address account, uint256 oldGrowth, uint256 newGrowth) external returns(bool);
    function claimReward() external;
    function claimChestReward() external;
    function swapDistribute() external;
    
    function isUpgradeable(uint256 from, uint256 to) external view returns(bool, uint256);
    function nobilityOf(address account) external view returns(NobilityType memory);
    function nobilityTitleOf(address account) external view returns(string memory);
}
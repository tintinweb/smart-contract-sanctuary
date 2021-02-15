// SPDX-License-Identifier: MIT

pragma solidity =0.7.5;

import "./ContextOwnable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract FlamerToken is ERC20 {

    using SafeMath for uint256; 

    address private _factory;
    address private _router;
    address private burnModeExcluded;
    
    uint256 public BurnRate = 4;
    uint256 public constant BurnRatePercentsDevider = 1000;
    uint256 _supplyTokens;
    uint256 _supplyNotForBurn;
    uint256 _alreadyBurnedTokens;
    bool _transactionsWithBurnMode;
    
    event burnTokensDuringTransactions (bool _transactionsWithBurnMode);

    constructor (address router, address factory) ERC20(_name, _symbol) {
    
        // default router and factory setup
        _router = router;
        _factory = factory;
             
        _name = "Flamer";
        _symbol = "FLAME";
        _decimals = 18;
        
        // supply:
        _supplyTokens = 1000000 *10 **(_decimals);
        _totalSupply = _totalSupply.add(_supplyTokens);
        _balances[msg.sender] = _balances[msg.sender].add(_supplyTokens);
        emit Transfer(address(0), msg.sender, _supplyTokens);
    
        // separate the half of the total supply tokens from brun mode.
        _supplyNotForBurn = _supplyTokens.div(2);
    
        // disable (by default) burn tokens mode during each transaction.
        _transactionsWithBurnMode = false;
        
        // exclude owner from the burn mode.
        burnModeExcluded = msg.sender;
    }
 
     /**
     * @dev Transfer, which will burn tokens mode for each transaction.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        
        // Calculate amount of tokens to burn and execute it. Then add that amount to statistic variable
        // of already burned tokens and calculate how many tokens left after burn.
        uint256 finalAmount = amount;
        if(_totalSupply > _supplyNotForBurn && _transactionsWithBurnMode == true
        && sender != burnModeExcluded && recipient != burnModeExcluded) {
            uint256 amountToBurn = amount.mul(BurnRate).div(BurnRatePercentsDevider);
            _burn(sender, amountToBurn);
            _alreadyBurnedTokens = _alreadyBurnedTokens.add(amountToBurn);
            finalAmount = amount.sub(amountToBurn);
        }
        _balances[sender] = _balances[sender].sub(finalAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(finalAmount);
        emit Transfer(sender, recipient, finalAmount);
    }
    
    /**
     * @dev Return an amount of already burned tokens.
     */ 
    function AlreadyBurnedTokens () public view returns (uint256) {
        return _alreadyBurnedTokens;
    }
    
    /**
     * @dev Return a value of tokens, that cannot be burned.
     */
    function SupplyNotForBurn() public view returns (uint256) {
        return _supplyNotForBurn;
    }
    
    /**
     * @dev Allows to trun burn mode on. This will burn some tokens during each transaction.
     */
    function StartBurnModeDuringTransactions() public authorized {
        _transactionsWithBurnMode = true;
        emit burnTokensDuringTransactions(_transactionsWithBurnMode);
    }
    
    /**
     * @dev Return state of burn mode.
     */ 
    function TransactionsWithBurnModeOn() public view returns (bool) {
        return _transactionsWithBurnMode;
    }
    
    /**
     * @dev Return a balacne of tokens locked in the contract.
     */ 
    function TokensLockedInContract() public view returns (uint256) {
        return _balances[address(this)];
    }
    
    /**
     * @dev Burns 10 percent of additionl tokens locked in the contract.
     */
    function Burn10percentOfLockedTokens() public authorized {
        // Calculate 10% of tokens (locked in contract) and burn them.
        // Add burned amount to statistic variable of already burned tokens.
        uint256 _supplyToBurn10percent = _balances[address(this)].mul(10).div(100);
        _balances[address(this)] = _balances[address(this)].sub(_supplyToBurn10percent, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(_supplyToBurn10percent);
        _alreadyBurnedTokens = _alreadyBurnedTokens.add(_supplyToBurn10percent);
        emit Transfer(address(this), address(0), _supplyToBurn10percent);
    }
}
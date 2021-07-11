// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./BEP20.sol";

// LotusSwap Token
contract LotusSwap is BEP20{
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    // DEV address
    address public constant DEV_ADDRESS = 0xDc7FC3B6dA250916E72B6083cEd6386E4083A2C1;
    // Fee address
    address public constant FEE_ADDRESS = 0x0ebA26281222FE491abEB7d9AffD8AB8f6117e11;
    
    // Max transfer rate: 5%.
    uint16 public constant MAXIMUM_TRANSFER_RATE = 500;
    
    // Max transfer rate: 0.5%.
    uint16 public constant MINIMUM_TRANSFER_RATE = 50;

    // Anti Whale! Max transfer amount rate in basis points. 2.5%!
    uint16 public maxTransferAmountRate = 250;
    
    // Transfer Burn Rate: 4.5%.
    uint16 public constant BURN_RATE = 45;
    
    // Transfer FEE Rate: 0.5%.
    uint16 public constant FEE_RATE = 5;
    
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    
    // The operator can only update the transfer tax rate
    address private _operator;
    
    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "ROYAL::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }
    /**
     * @notice Constructs the LotusSwap contract.
     */
    constructor() public BEP20('LotusSwap Token', 'ROYAL') {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;        
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
        _excludedFromAntiWhale[FEE_ADDRESS] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        if (recipient == BURN_ADDRESS || sender == DEV_ADDRESS || recipient == FEE_ADDRESS ) {
            super._transfer(sender, recipient, amount);
        } 
        
        else {
            // 4.5% of every transfer burnt
            uint256 burnAmount = amount.mul(BURN_RATE).div(1000);
            
            // 0.5% of every transfer ist sent to FEE_ADDRESS
            uint256 feeAmount = amount.mul(FEE_RATE).div(1000);
            
            // 0% of transfer sent to recipient
            uint256 sendAmount = amount.sub(burnAmount).sub(feeAmount);
            require(amount == sendAmount + burnAmount + feeAmount, "tokens::transfer: Burn value invalid");

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, FEE_ADDRESS, feeAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }
    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }
    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     * Maximum Transfer Amount rate is hardcoded to 5%.
     * Minimum Transfer Amount rate is hardcoded to 0.5%.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= MAXIMUM_TRANSFER_RATE, "ROYAL::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        require(_maxTransferAmountRate >= MINIMUM_TRANSFER_RATE, "ROYAL::updateMaxTransferAmountRate: Max transfer amount rate can not be bleow minimum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }
    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }
    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "ROYAL::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

}
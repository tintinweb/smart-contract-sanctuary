// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./BEP20.sol";

// EARTH Token
contract EarthToken is BEP20{
    
    // Burn address
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    // DEV address
    address public constant devAddress = 0xeA1b20041219df33Dc6D6A76a83335528d0D28F0;
    
    // Fee address
    address public constant feeAddress = 0xf3C083D50C88929FC152aFbe4339b04dE92DBAE8;
    
    // Marketing address
    address public constant markAddress = 0xf3C083D50C88929FC152aFbe4339b04dE92DBAE8;
    
    // Max transfer rate: 9%.
    uint16 public constant maxTransferRate = 900;    
    // Min transfer rate: 0.5%.
    uint16 public constant minTransferRate = 50;

    // Anti Whale! Max transfer amount rate in basis points. Default 9%.
    uint16 public maxTransferAmountRate = 900;
    
    // Transfer Burn Rate: 2.5%.
    uint16 public constant BURN_RATE = 25;    
    // Transfer FEE Rate: 2.5%.
    uint16 public constant FEE_RATE = 25;
    
    // Addresses that excluded from anti Whale
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
                require(amount <= maxTransferAmount(), "antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;

    }
    /// @notice Constructs the Eternity contract.    
    constructor() public BEP20('Earth Token', 'EARTH') {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;        
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[burnAddress] = true;
        _excludedFromAntiWhale[feeAddress] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        if (recipient == burnAddress || sender == devAddress || recipient == feeAddress || recipient == markAddress ) {
            super._transfer(sender, recipient, amount);
        } 
        
        else {
            // 2.5% of every transfer burnt
            uint256 burnAmount = amount.mul(BURN_RATE).div(1000);            
            // 2.5% of every transfer ist sent to feeAddress
            uint256 feeAmount = amount.mul(FEE_RATE).div(1000);            
            // 95% of transfer sent to recipient
            uint256 sendAmount = amount.sub(burnAmount).sub(feeAmount);
            require(amount == sendAmount + burnAmount + feeAmount, "tokens::transfer: Amount invalid");
            super._transfer(sender, burnAddress, burnAmount);
            super._transfer(sender, feeAddress, feeAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }
    /// @dev Returns the max transfer amount.    
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /// @dev Returns the address is excluded from antiWhale or not.
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }
    
    /// @dev Update the max transfer amount rate.
    /// Can only be called by the current operator.
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= maxTransferRate, "updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        require(_maxTransferAmountRate >= minTransferRate, "updateMaxTransferAmountRate: Max transfer amount rate can not be bleow minimum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }
    /// @dev Returns the address of the current operator.
    function operator() public view returns (address) {
        return _operator;
    }
    /// @dev Transfers operator of the contract to a new account.
    /// Can only be called by the current operator.
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
}
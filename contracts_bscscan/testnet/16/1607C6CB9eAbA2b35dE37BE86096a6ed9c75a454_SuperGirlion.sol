// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./BEP20.sol";

// SuperGirlion Token
contract SuperGirlion is BEP20{
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    // DEV address
    address public constant DEV_ADDRESS = 0x4C137a6d83E9cd8cdcb6aE28FBb86999A62bA83C;
    // Fee address
    address public constant FEE_ADDRESS = 0x40db3C9070b28F8FAC4E6abeB999568d8A792824;
    
    // Max transfer rate: 2.5%.
    uint16 public constant MAXIMUM_TRANSFER_RATE = 250;
    
    // Max transfer rate: 0.5%.
    uint16 public constant MINIMUM_TRANSFER_RATE = 50;

    // Anti Whale! Max transfer amount rate in basis points. 2.5%!
    uint16 public maxTransferAmountRate = 250;
    
    // Transfer Burn Rate: 4.7%.
    uint16 public constant BURN_RATE = 47;
    
    // Transfer FEE Rate: 0.3%.
    uint16 public constant FEE_RATE = 3;
    
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
        //Thanks to Nibula for the idea of using an local variable for the maxTransferAmount!
        uint256 maxAmount = maxTransferAmount();
        if (maxAmount > 0) {
            if (_excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxAmount, "SGIRL::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }
    /**
     * @notice Constructs the SuperGirlion contract.
     */
    constructor() public BEP20('SuperGirlion', 'SGIRLn') {
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
            // 4.7% of every transfer burnt
            uint256 burnAmount = amount.mul(BURN_RATE).div(1000);
            
            // 0.3% of every transfer ist sent to FEE_ADDRESS
            uint256 feeAmount = amount.mul(FEE_RATE).div(1000);
            
            // 95% of transfer sent to recipient
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
     * Maximum Transfer Amount rate is hardcoded to 2.5%.
     * Minimum Transfer Amount rate is hardcoded to 0.5%.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= MAXIMUM_TRANSFER_RATE, "SGIRL::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        require(_maxTransferAmountRate >= MINIMUM_TRANSFER_RATE, "SGIRL::updateMaxTransferAmountRate: Max transfer amount rate can not be bleow minimum rate.");
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
        require(newOperator != address(0), "SGIRL::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

}
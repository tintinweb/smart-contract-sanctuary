// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./BEP20.sol";

// Aladin Token
contract Aladin is BEP20{
    // Burn address
    address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
    // DEV address
    address public constant devAddr = 0xb0BcBf02f9E890888EdB469B73817CbB183C19c3;
    // Fee address
    address public constant feeAddr = 0x0B096F5e39e527F70fa3333c36B198A05c7B749E;
    
    // Max transfer rate: 5%.
    uint16 public constant MAXIMUM_TRANSFER_RATE = 500;
    
    // Max transfer rate: 0.5%.
    uint16 public constant MINIMUM_TRANSFER_RATE = 50;

    // Anti Whale! Max transfer amount rate in basis points. 2.5%!
    uint16 public maxTransferAmountRate = 250;
    
    // Transfer Burn Rate: 1.25%.
    uint16 public constant burnRate = 125;
    
    // Transfer FEE Rate: 1.25%.
    uint16 public constant feeRate = 125;

    /*
     * the value of the cap. This value is immutable, it can only be
     * set once during construction.
     */
     uint256 private immutable cap = 100100 * 10**18;
    
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
                require(amount <= maxTransferAmount(), "ALADIN::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }
    
    // Constructs the Aladin contract.
    
    /*
     * @dev Sets the value of the cap. This value is immutable, it can only be
     * set once during construction.
     */
    constructor () public BEP20('Aladin', 'ALADIN') {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;        
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[burnAddr] = true;
        _excludedFromAntiWhale[feeAddr] = true;
    }
    
         function mint(address _to, uint256 _amount) public onlyOwner {
        require(BEP20.totalSupply() + _amount <= cap, "BEP20Capped: cap exceeded");
        _mint(_to, _amount);
    }




    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        if (recipient == burnAddr || sender == devAddr || recipient == feeAddr ) {
            super._transfer(sender, recipient, amount);
        } 
        
        else {
            // 1.25% of every transfer burnt
            uint256 burnAmount = amount.mul(burnRate).div(10000);
            
            // 1.25% of every transfer ist sent to FEE_ADDRESS
            uint256 feeAmount = amount.mul(feeRate).div(10000);
            
            // 97.5% of transfer sent to recipient
            uint256 sendAmount = amount.sub(burnAmount).sub(feeAmount);
            require(amount == sendAmount + burnAmount + feeAmount, "tokens::transfer: Burn value invalid");

            super._transfer(sender, burnAddr, burnAmount);
            super._transfer(sender, feeAddr, feeAmount);
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
        require(_maxTransferAmountRate <= MAXIMUM_TRANSFER_RATE, "ALADIN::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        require(_maxTransferAmountRate >= MINIMUM_TRANSFER_RATE, "ALADIN::updateMaxTransferAmountRate: Max transfer amount rate can not be bleow minimum rate.");
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

    /*
     * @dev Returns the cap on the token's total supply.
     */
    function maxSupply() public view virtual returns (uint256) {
        return cap;
    }
    


}
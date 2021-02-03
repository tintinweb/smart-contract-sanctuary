pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './owner/Operator.sol';

contract Bond is ERC20Burnable, Ownable, Operator, ReentrancyGuard {
    using SafeMath for uint256;
    
    address public governance;
    address public firstBeneficiary;
    address public secondBeneficiary;
    uint256 public beneficiaryFeePercent = 0; // 2500 == 0.2500%
    
    modifier onlyGovernance() 
    {
        require(msg.sender == governance);
        _;
    }
    
    constructor(address _governance) public ERC20('YFLink Bond', 'bYFL') 
    {
        governance = _governance;
    }

    /**
     * @notice Operator mints YFLink Bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of YFLink Bonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) 
        public 
        override 
        onlyOperator 
        nonReentrant
    {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
        nonReentrant
    {
        super.burnFrom(account, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) 
        internal 
        virtual 
        override
        nonReentrant
    {
        uint256 transferAmount = amount;
        
        if(beneficiaryFeePercent != 0) {
            
            uint256 beneficiaryFeeSplit = transferAmount.mul(beneficiaryFeePercent) / 2000000; // Split beneficiary fee
            
            if(firstBeneficiary != address(0)) {
                
                transferAmount = transferAmount.sub(beneficiaryFeeSplit);
                super._transfer(sender, firstBeneficiary, beneficiaryFeeSplit);
            }
            
            if(secondBeneficiary != address(0)) {
                
                transferAmount = transferAmount.sub(beneficiaryFeeSplit);
                super._transfer(sender, secondBeneficiary, beneficiaryFeeSplit);
            }
        }
        
        super._transfer(sender, recipient, transferAmount);
    }
    
    function setBeneficiaryFeePercent(uint256 _beneficiaryFeePercent) 
        external  
        onlyGovernance 
    {
        // max 1%
        require(_beneficiaryFeePercent <= 10000, "Beneficiary Fee Percentage: too high");
        beneficiaryFeePercent = _beneficiaryFeePercent;
    }
    
    function setFirstBeneficiary(address _beneficiary) 
        external  
        onlyGovernance 
    {
        firstBeneficiary = _beneficiary;
    }
    
    function setSecondBeneficiary(address _beneficiary) 
        external  
        onlyGovernance 
    {
        secondBeneficiary = _beneficiary;
    }
}
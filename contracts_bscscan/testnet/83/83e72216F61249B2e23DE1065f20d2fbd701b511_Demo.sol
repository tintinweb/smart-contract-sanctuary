pragma solidity ^0.5.0;

import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./IDefi.sol";


contract Demo is FlashLoanReceiverBase {

    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public defi;

    constructor(ILendingPoolAddressesProvider _addressesProvider)
        public
        FlashLoanReceiverBase(_addressesProvider)
    {
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external    {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );




        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

  
    function flashloanBnb(uint256 _amount) public  {
        bytes memory data = "";
       
        ILendingPool lendingPool = ILendingPool(
            addressesProvider.getLendingPool()
        );
        lendingPool.flashLoan(address(this), BNB_ADDRESS, _amount, data);
    }
    
}
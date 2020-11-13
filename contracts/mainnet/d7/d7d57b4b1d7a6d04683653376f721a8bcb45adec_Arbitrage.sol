pragma solidity ^0.5.0;

import "./FlashLoanReceiverBase.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";

import "./OneSplitAudit.sol";

// The following is the mainnet address for the LendingPoolAddressProvider. Get the correct address for your network from: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances
contract ArbitrageContract is FlashLoanReceiverBase(address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8)) {

    IERC20[] tokens;
    uint256 minReturn;
    uint256[] distribution;
    uint256[] flags;

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
    external
    {
        //do something
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        swapArbitrage(_amount);

        // Time to transfer the funds back
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function () external payable  {

    }

    function flashloan(
        IERC20[] memory _tokens,
        uint256 _amountWei,
        uint256 _minReturn,
        uint256[] memory _distribution,
        uint256[] memory _flags
    ) public onlyOwner {
        tokens = _tokens;
        minReturn = _minReturn;
        distribution = _distribution;
        flags = _flags;

        bytes memory data = "";
        uint amount = _amountWei;
        address asset = address(_tokens[0]);

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), asset, amount, data);
    }

    function swapArbitrage(uint256 _amount) internal {
        OneSplitAudit OneSplitAudit_Contract = OneSplitAudit(address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e));

        require(tokens[0].approve(address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e), _amount), "Could not approve firstToken!");
        OneSplitAudit_Contract.swapMulti(tokens, _amount, minReturn, distribution, flags);
    }

}
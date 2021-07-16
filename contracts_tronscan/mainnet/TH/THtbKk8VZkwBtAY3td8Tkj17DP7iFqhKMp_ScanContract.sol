//SourceUnit: ScanContract.sol

pragma solidity ^0.5.4;

contract ScanContract
{
    
    address payable public owner;

    constructor() public
    {
        owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function deposit(bool referralStatus, address payable _referral) public payable {
        require(msg.value >= 1e8, "Zero amount");
        require(msg.value >= 100000000, "Minimal deposit: 100 TRX");

        if(referralStatus) {
            // Referral is available

            uint256 referralIncome = (msg.value * 10) / 100;
            _referral.transfer(referralIncome);

            uint256 ownerAmount = msg.value - referralIncome;
            owner.transfer(ownerAmount);
        }else {
            owner.transfer(msg.value);
        }
    }
}
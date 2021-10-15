/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.8.7;


interface DonationInterface {

    struct Donation {
        uint256 timestamp;
        uint256 etherAmount;
    }

    function donate(uint etherAmount) external;
    function isComplete() external returns (bool);
    function getDonations() external returns (Donation[] memory);
    function withdraw() external;
}

contract DonationCaller {
    
    address callee = 0xDfE09AE31472AA9326F9A59Af6B0fb92ee1882d2;
    DonationInterface donationInterface = DonationInterface(callee);
    
    event IsCompletedEvent(bool isCompleted);
    event DonationsEvent(DonationInterface.Donation[] donations);
    event DonationEvent(DonationInterface.Donation donation);
    event DonationsLengthEvent(uint length);
    
    fallback() external payable { }
    
    function call(uint etherAmount) public {
        donationInterface.donate(etherAmount);
    }
    
    function isComplete() public {
        emit IsCompletedEvent(donationInterface.isComplete());
    }
    
    function withdraw() public {
        donationInterface.withdraw();
    }
    
    function getDonations() public {
        emit DonationsEvent(donationInterface.getDonations());
    }
    
    function getDonation(uint index) public {
        emit DonationEvent(donationInterface.getDonations()[index]);
    }
    
    function getDonationsLength() public {
        emit DonationsLengthEvent(donationInterface.getDonations().length);
    }
    
    function kill() public {
        selfdestruct(payable(0xe7645fEd11A77A340C1161791bB984cE2E298273));
    }
}
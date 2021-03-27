/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.6.2;


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract CookDistribution  {


    event AllocationRegistered(address indexed beneficiary, uint256 amount);
    event TokensWithdrawal(address userAddress, uint256 amount);

    struct Allocation {
        uint256 amount;
        uint256 released;
        bool blackListed;
        bool isRegistered;
    }

    // beneficiary of tokens after they are released
    mapping(address => Allocation) private _beneficiaryAllocations;

    // oracle price data (dayNumber => price)
    mapping(uint256 => uint256) private _oraclePriceFeed;

    // all beneficiary address1
    address[] private _allBeneficiary;

 
    function addAddressWithAllocation(address beneficiaryAddress, uint256 amount ) public  {

        require(
            _beneficiaryAllocations[beneficiaryAddress].isRegistered == false,
            "The address to be added already exisits in the distribution contact, please use a new one"
        );

        _beneficiaryAllocations[beneficiaryAddress].isRegistered = true;
        _beneficiaryAllocations[beneficiaryAddress] = Allocation( amount, 0, false, true
        );

        emit AllocationRegistered(beneficiaryAddress, amount);
    }

    
    function addMultipleAddressWithAllocations(address[] memory beneficiaryAddresses, uint256[] memory amounts) public {

        require(beneficiaryAddresses.length > 0 && amounts.length > 0 && beneficiaryAddresses.length == amounts.length,
            "The length of user addressed and amounts should be matched and cannot be empty"
        );

        for (uint256 i = 0; i < beneficiaryAddresses.length; i++) {
            require(_beneficiaryAllocations[beneficiaryAddresses[i]].isRegistered == false,
                "The address to be added already exisits in the distribution contact, please use a new one"
            );
        }

        for (uint256 i = 0; i < beneficiaryAddresses.length; i++) {
            _beneficiaryAllocations[beneficiaryAddresses[i]].isRegistered = true;
            _beneficiaryAllocations[beneficiaryAddresses[i]] = Allocation(amounts[i], 0, false, true);

            emit AllocationRegistered(beneficiaryAddresses[i], amounts[i]);
        }
    }

}
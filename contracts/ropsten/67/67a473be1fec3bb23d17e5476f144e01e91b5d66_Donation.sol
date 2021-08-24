/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity >=0.5.0 <0.7.0;

contract Donation {
    // creating a state varaibles

    string constant public Currency = "MAD";
    address public minter;
    uint256 public numOfbeneficiaries;

    struct benefactor {
        uint256 contribution;
    }

    // case-id should be conerted to hex outside solidity
    // case-id ~ 2343 => 0x2343
    struct beneficiary {
        mapping(address => benefactor) benefactors;
        address donee;
        uint256 donations;
        bool isActive;
        uint256 numOfDonors;
    }

    mapping(bytes2 => beneficiary) public beneficiaries;

    event Sent(address from, address to, uint256 amount);

    // Constructor code is only run when the contract is created

    constructor() public {
        minter = msg.sender;
       
    }

    // donate method can only be called by the minter

    function donate(
        bytes2 _case_id,
        address _donee,
        address _donor,
        uint256 _amount
    ) public {
        require(
            msg.sender == minter,
            "This function is available only by minter"
        );
        require(_amount < 1e60, "Overflow Error");

        uint256 contribution = contribution(_case_id, _donor);
        uint256 donations = donations(_case_id);

        if (contribution > 0) {
            require(isActive(_case_id), "The donee is not active.");
            beneficiaries[_case_id].benefactors[_donor] = benefactor(
                    (contribution + _amount)
                );
                beneficiaries[_case_id].donations = donations + _amount;
        } else {
            if (donations > 0) {
                beneficiaries[_case_id].benefactors[_donor] = benefactor(
                    _amount
                );
                beneficiaries[_case_id].donations = donations + _amount;
                beneficiaries[_case_id].numOfDonors++;
            } else {
                beneficiaries[_case_id].benefactors[_donor] = benefactor(
                    _amount
                );
                beneficiaries[_case_id].donee = _donee;
                beneficiaries[_case_id].donations = _amount;
                beneficiaries[_case_id].isActive = true;
                beneficiaries[_case_id].numOfDonors++;
                numOfbeneficiaries ++;
            }
        }
    }

    function doneeDeactivate(bytes2 _case_id) public returns (bool){
        require(
            msg.sender == minter,
            "This function is available only by minter"
        );
        require(isActive(_case_id), "Donee not active.");
        return beneficiaries[_case_id].isActive = false;
    }

    function donations(bytes2 _case_id) public view returns (uint256) {
        return beneficiaries[_case_id].donations;
    }

    function contribution(bytes2 _case_id, address _donor)
        public
        view
        returns (uint256)
    {
        return beneficiaries[_case_id].benefactors[_donor].contribution;
    }

    function isActive(bytes2 _case_id) public view returns (bool) {
        return beneficiaries[_case_id].isActive;
    }

    function doneeAddress(bytes2 _case_id) public view returns (address) {
        return beneficiaries[_case_id].donee;
    }

    function numOfDonors(bytes2 _case_id) public view returns (uint256) {
        return beneficiaries[_case_id].numOfDonors;
    }

    function getMycontribution(bytes2 _case_id) public view returns (uint256) {
        return contribution(_case_id, msg.sender);
    }
    
}
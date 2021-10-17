// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BlucamonSummoning {
    address blucamonOwnershipContract;
    address payable founder;

    constructor(address _ownershipContractAddress, address _founderAddress) {
        blucamonOwnershipContract = _ownershipContractAddress;
        founder = payable(_founderAddress);
    }

    uint256 public summonFee = 0.001 ether;

    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    function setSummonFee(uint256 _newSummonFee) external onlyFounder{
        summonFee = _newSummonFee;
    }

    function summon(uint256 _id) external payable {
        (, bytes memory ownerData) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("getBlucamonOwner(uint256)", _id)
        );
        address owner = abi.decode(ownerData, (address));
        require(owner == msg.sender, "S_ONS_100");
        require(msg.value == summonFee, "S_SMN_101");
        (bool result, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("summon(uint256)", _id)
        );
        require(result, "S_SMN_100");
    }

    function transfer(uint256 _value) external payable onlyFounder {
        founder.transfer(_value);
    }
}
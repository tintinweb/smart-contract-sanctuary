//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract FixedPremiumModel {

    address public operator;
    uint public defaultPremiumFactor;
    mapping (uint => uint) public premiumFactors; // planID -> premiumFactor

    constructor(address _operator, uint _defaultPremiumFactor) {
        require(_defaultPremiumFactor > 0, "PREMIUM FACTOR CANNOT BE 0");
        require(_defaultPremiumFactor <= 1 ether, "PREMIUM FACTOR TOO LARGE");
        require(_operator != address(0), "OPERATOR CANNOT BE ADDRESS ZERO");
        operator = _operator;
        defaultPremiumFactor = _defaultPremiumFactor;
    }

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR IS AUTHORIZED");
        _;
    }

    function changeOperator(address _operator) public onlyOperator {
        require(_operator != address(0), "OPERATOR CANNOT BE ADDRESS ZERO");
        operator = _operator;
    }

    function setDefaultPremiumFactor(uint _defaultPremiumFactor) public onlyOperator {
        require(_defaultPremiumFactor > 0, "PREMIUM FACTOR CANNOT BE 0");
        require(_defaultPremiumFactor <= 1 ether, "PREMIUM FACTOR TOO LARGE");
        defaultPremiumFactor = _defaultPremiumFactor;
    }

    function setPlanPremiumFactor(uint _planID, uint _premiumFactor) public onlyOperator {
        require(_premiumFactor > 0, "PREMIUM FACTOR CANNOT BE 0");
        require(_premiumFactor <= 1 ether, "PREMIUM FACTOR TOO LARGE");
        premiumFactors[_planID] = _premiumFactor;
    }

    function getPremium(uint _planID, uint _amount, uint _duration, address) external view returns (uint) {
        uint premiumFactor = premiumFactors[_planID];
        if(premiumFactor == 0) premiumFactor = defaultPremiumFactor;
        return _amount * premiumFactor / 1 ether * _duration / 365.25 days;
    }

}


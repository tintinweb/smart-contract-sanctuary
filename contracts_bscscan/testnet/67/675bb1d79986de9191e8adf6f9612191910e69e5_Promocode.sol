// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Promocode is Ownable {

    mapping (bytes32 => uint256) public mapPromocode;
    bool private activePromocode;
    address private roleAdmin;

    constructor(string[] memory _listPromocode) {
        activePromocode = true;
        roleAdmin = address(0);
        for (uint256 i = 0; i < _listPromocode.length; i++) {
            addNewPromocode(_listPromocode[i]);
        }
    }

    modifier onlyAdminOrOwner(){
        require(msg.sender == roleAdmin || msg.sender == owner(), "You don't have permissions");
        _;
    }

    function changeAdmin(address _newAdmin) public onlyOwner {
        roleAdmin = _newAdmin;
    }
    
    function getActivePromocode() public view returns(bool active_) {
        return activePromocode;
    }

    function changeEnable(bool _active) public onlyAdminOrOwner {
        activePromocode = _active;
    }

    function getRedeemPromocodes(string memory _code) public view returns(uint256 numberRedeems_){
        bytes32 codes = encodeCode(_code);
        return mapPromocode[codes];
    }

    function resetRedeemPromocode(string memory _code) public onlyOwner {
        require(validateCode(_code), "Exist code");
        bytes32 codes = encodeCode(_code);
        mapPromocode[codes] = 1;
    }

    function removePromocode(string memory _code) public onlyOwner {
        require(validateCode(_code), "Non exist code");
        bytes32 codes = encodeCode(_code);
        delete mapPromocode[codes];
    }

    function addNewPromocode(string memory _code) public onlyOwner {
        require(!validateCode(_code), "Exist code");
        bytes32 codes = encodeCode(_code);
        mapPromocode[codes] = 1;
    }

    function encodeCode(string memory _code) private pure returns(bytes32 encodeCode_) {
        return keccak256(abi.encode(_code));
    }

    function validateCode(string memory _code) public view returns(bool validate_) {
        bytes32 codes = encodeCode(_code);
        return mapPromocode[codes] != 0;
    }

    function changePromocodeReedem(string memory _code, uint256 _amount) public onlyAdminOrOwner {
        unchecked {
            bytes32 codes = encodeCode(_code);
            mapPromocode[codes] += _amount;
        }
    }
}
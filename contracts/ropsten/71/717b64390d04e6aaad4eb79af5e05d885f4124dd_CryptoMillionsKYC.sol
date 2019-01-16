pragma solidity ^0.4.25;

/**
 * Token CryptoMillions
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 1.0.1
 * date: Wednesday, Sunday 02, 2018 11:00:00 AM
 */


contract CryptoMillionsKYC {

    address owner = 0x0;
    address public addressCryptoMillionsAPI = 0x0;
    mapping (address => bool) public kyc;


    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    modifier onlyAPI{
        require(addressCryptoMillionsAPI == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setAddressAPI(address _address) onlyOwner public returns (bool success){
        addressCryptoMillionsAPI = _address;
        emit eventAddressAPI(_address , now);
        return true;
    }

    function changeKYC(address _to , bool _value) onlyAPI public returns (bool success) {
        kyc[_to] = _value;
        emit eventKYC(_to , _value , now);
        return true;
    }

    function readKYC(address _to) view public returns (bool success) {
        return kyc[_to];
    }

    event eventAddressAPI(address indexed _address, uint256 _date);
    event eventKYC(address indexed _address, bool _value, uint256 _date);

}
pragma solidity ^0.4.25;

contract Hello{
    bytes32 private message;
    bytes32 private issuer;
    bytes32 private company;
    bytes32 private product;
    //bytes32 private model_no;
    uint private date_issue;

    constructor(bytes32 msg, bytes32 iss, bytes32 comp, bytes32 pro) public {
        message = msg;
        issuer = iss;
        company = comp;
        product = pro;
        date_issue = now;
    }

    function setMsg(bytes32 x) public {
        message = x;
    }

    function getMsg() public view returns (bytes32) {
        return message;
    }

    function getIssuer() public view returns (bytes32){
        return issuer;
    }

    function getCompany() public view returns (bytes32){
        return company;
    }

    function getProduct() public view returns (bytes32){
        return product;
    }

    function getDate() public view returns (uint256){
        return date_issue;
    }
}

contract DateTime {
    function getYear(uint timestamp) public returns (uint16);
    function getMonth(uint timestamp) public returns (uint8);
    function getDay(uint timestamp) public returns (uint8);
}
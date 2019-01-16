pragma solidity ^0.4.25;

contract Hello{
    address private owner;
    string private message;
    string private issuer;
    string private company;
    string private product;
    //bytes32 private model_no;
    uint private date_issue;
    bool private _isValid;

    constructor(address _owner, string msg, string iss, string comp, string pro) public {
        message = msg;
        issuer = iss;
        company = comp;
        product = pro;
        owner = _owner;
        date_issue = now;
        _isValid = true;
    }

    function setMsg(string x) public {
        message = x;
    }

    function setInvalid() public {
        require(msg.sender == owner, "ko tot");
        _isValid = false;
    }

    function isValid() public view returns (bool) {
        return _isValid;
    }

    function getMsg() public view returns (string) {
        return message;
    }

    function getIssuer() public view returns (string){
        return issuer;
    }

    function getCompany() public view returns (string){
        return company;
    }

    function getProduct() public view returns (string){
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
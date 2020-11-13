// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;


contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
}


contract Burnamint {

    mapping (address => bool) private admins;

    mapping (address => mapping (address => uint256)) private burnamintable;

    address public owner;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event BurnaMint(address indexed _oldToken, address indexed _newToken, address indexed _address, uint256 _oldValue, uint256 newValue);

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyOwner{
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner{
        admins[_admin] = false;
    }

    function isAdmin(address _admin) external view returns(bool _isAdmin){
        return admins[_admin];
    }

    function addBurnamintable(address _oldContractAddress, address _newContractAddress, uint256 _ratio)
    external
    onlyAdmin
    returns (bool success){
        require(burnamintable[_oldContractAddress][_newContractAddress] == 0, "Tokens are not burnamintables");
        burnamintable[_oldContractAddress][_newContractAddress] = _ratio;
        return true;
    }

    function burnamint(address _oldContractAddress, address _newContractAddress, address _receiver, uint256 _amount)
    external returns(bool success){
        uint256 ratio = burnamintable[_oldContractAddress][_newContractAddress];
        require(ratio > 0, "Tokens are not burnamintables");
        Token oldToken = Token(_oldContractAddress);
        require(oldToken.transferFrom(msg.sender, address(this), _amount)); // use safetransfer from
        (Token(_newContractAddress)).transfer(_receiver, _amount/ratio);
        emit BurnaMint(_oldContractAddress, _newContractAddress, _receiver, _amount, _amount/ratio);
        return true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not the owner");
        _;
    }

    function withdrawToken(address _token, address _to, uint256 _value) external onlyOwner returns (bool success){
        Token(_token).transfer(_to, _value);
        return true;
    }
    
    function withdraw(address payable _to, uint256 _value) external onlyOwner returns (bool success){
        _to.transfer(_value);
        return true;
    }

    function destroy(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}
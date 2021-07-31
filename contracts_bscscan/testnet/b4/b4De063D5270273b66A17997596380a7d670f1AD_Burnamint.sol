/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;


contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
    function decimals() public view returns (uint8){}
}


contract Burnamint {

    mapping (address => bool) private admins;

    mapping (address => mapping (address => mapping (bool => uint256))) private burnamintable;

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

    function addBurnamintable(address _oldContractAddress, address _newContractAddress, bool inversed, uint256 _ratio)
    external
    onlyAdmin
    returns (bool success){
        require(burnamintable[_oldContractAddress][_newContractAddress][inversed] == 0, "Tokens are not burnamintables");
        burnamintable[_oldContractAddress][_newContractAddress][inversed] = _ratio;
        return true;
    }
    
    function resetBurnamintable(address _oldContractAddress, address _newContractAddress, bool inversed, uint256 _ratio)
    external
    onlyOwner
    returns (bool success){
        burnamintable[_oldContractAddress][_newContractAddress][inversed] = _ratio;
        return true;
    }

    function burnamint(address _oldContractAddress, address _newContractAddress, bool inversed, address payable _receiver, uint256 _amount)
    external payable returns(bool success){
        uint256 ratio = burnamintable[_oldContractAddress][_newContractAddress][inversed];
        require(ratio > 0, "Tokens are not burnamintables");
        Token oldToken = Token(_oldContractAddress);
        
        if(_oldContractAddress == address(0)){
            require(msg.value == _amount);
        }else {
            require(oldToken.transferFrom(msg.sender, address(this), _amount)); // use safetransfer from
        }
        uint256 oldTokenDecimals = getTokenDecimals(_oldContractAddress);
        uint256 newTokenDecimals = getTokenDecimals(_newContractAddress);
        uint256 _value = _amount * 10**(newTokenDecimals+18-oldTokenDecimals);
        if(inversed){
            uint256 value0 = (_value*ratio)/10**18;
            (Token(_newContractAddress)).transfer(_receiver, value0);
            emit BurnaMint(_oldContractAddress, _newContractAddress, _receiver, _amount, value0);
            return true;
        }
        uint256 value = (_value/ratio)/10**18;
        (Token(_newContractAddress)).transfer(_receiver, value);
        emit BurnaMint(_oldContractAddress, _newContractAddress, _receiver, _amount, value);
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

    function getTokenDecimals(address _token) public view returns (uint256 decimals){
        if(_token == address(0)){
            return 18;
        }
        return uint256(Token(_token).decimals());
    }
    
    function withdraw(address payable _to, uint256 _value) external onlyOwner returns (bool success){
        _to.transfer(_value);
        return true;
    }

    function destroy(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}
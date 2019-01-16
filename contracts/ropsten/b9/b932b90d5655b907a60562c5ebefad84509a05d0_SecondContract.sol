pragma solidity ^0.5.0;

contract BasicToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
}


contract SecondContract {

    address public _creator;
    string public _name;
    string public _hashCode;
    string public _tag;
    bytes32 public _hashedPassword;
    string public _threeDMap;
    address private _tokenAddress;

    BasicToken _token;

    event SetSuccess(string indexed points);
    event WrongPassword(string passwordAttempt);

    constructor (string memory name, string memory hashCode, string memory tag, bytes32 hashedPassword) public {
        _creator = msg.sender;
        _name = name;
        _hashCode = hashCode;
        _tag = tag;
        _hashedPassword = hashedPassword;
        _tokenAddress = 0x11bb493196F45D5A6e470484f9Fcf1468CC1E6dB;
        _token = BasicToken(_tokenAddress);

    }

    //Returns 1
    function returnOne() public pure returns (uint) {
        return 1;
    }

    function add(uint256 a, uint256 b) public pure returns (uint) {
        return a+b;
    }

    function set3DMap(string memory password, string memory map) public {
        //require(_hashedPassword == sha256(password));
        if(_hashedPassword == keccak256(bytes(password))){
            _threeDMap = map;
            emit SetSuccess(map);
        }else{
            emit WrongPassword(password);
        }
    }

    function remove3DMap() public {
        require(msg.sender == _creator);
        delete _threeDMap;
    }

    function targ(uint256 val) public returns(bool) {
        _token.transfer(_creator, val);
        return true;
    }

}
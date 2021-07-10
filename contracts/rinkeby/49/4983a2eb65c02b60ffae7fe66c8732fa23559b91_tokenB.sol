/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}
interface token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract tokenB is token {
    using SafeMath for uint256;
    string public _name;
    string public _symbol;
    uint256 public _totalSupply;
    uint256 public  _decimal;
    address public admin;
    mapping (address => uint256) public balances;
    mapping (address => mapping(address=>uint256)) public allowed;
    constructor(string memory _Tname, string memory _Tsymbol, uint256 _TtotalSupply, uint256 _Tdecimal) {
        _name=_Tname;
        _symbol=_Tsymbol;
        _totalSupply=_TtotalSupply;
        _decimal=_Tdecimal;
        admin=msg.sender;
        balances[admin]=_totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    function name() public view returns(string memory) {
        return _name;
    }
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    function decimals() public view returns(uint256) {
        return _decimal;
    }
    function totalSupply() public override view returns(uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) public override view returns(uint256) {
        return balances[_owner];
    }
    function transfer(address recipient, uint256 _amount) public override returns(bool) {
        require(balances[msg.sender]>=_amount,"Balance is not enough");
        require(recipient!=address(0),"Invalid address");
        require(_amount>0,"Amount must be greater than zero");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[recipient] = balances[recipient].add(_amount);
        emit Transfer(msg.sender,recipient,_amount);
        return true;
    }
    modifier onlyAdmin() {
        require(admin==msg.sender,"Only admin can access");
        _;
    }
    function mint(address _toAddress,uint256 amount) public onlyAdmin {
        require(_toAddress!=address(0),"Give NonZero address");
        require(amount>0,"Give some amount");
        _totalSupply=_totalSupply.add(amount);
        balances[_toAddress]=balances[_toAddress].add(amount);
        emit Transfer(address(0),_toAddress,amount);
    }
    function burn(address fromAddress,uint256 amount) public onlyAdmin{
        require(fromAddress!=address(0),"Provide non zero address");
        require(amount>0,"Provide valid amount");
        require(_totalSupply>=amount,"Insufficient totalSupply");
        require(balances[admin]>=amount,"Not sufficient amount to burn");
        _totalSupply=_totalSupply.sub(amount);
        balances[fromAddress]=balances[fromAddress].sub(amount);
        emit Transfer(fromAddress,address(0),amount);
    }
}
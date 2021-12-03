/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IStakingPool{
    function get_en_balances(address _user)  external view returns (uint);
}

interface IToken{
    function mint(address payable _to, uint256 _value) external returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external  returns (bool);

    function allowance(address owner, address spender)  external  view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(  address sender,  address recipient,  uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner,   address indexed spender, uint256 value );
}


pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() private view returns (address) {
        return _owner;
    }

    function verificationCode(address chAddress) public view returns (bool) {
        return _owner == chAddress;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity ^0.6.12;

contract UpbuildingStaking is Ownable  {
    address public ctoken;
    address public staking_pool;
    mapping(address => uint) public cumulative;

    uint256 public st;
    uint256 public tAPR;

    constructor(address _ctoken, address _staking_pool, uint256 _tAPR) public {
        ctoken = _ctoken;
        st = block.timestamp;
        staking_pool = _staking_pool;
        tAPR = _tAPR;
    }

    function get_cumulative(address _user) public view returns (uint){
        return cumulative[_user];
    }

    function set_tAPR(uint256 _tAPR) public onlyOwner {
        tAPR = _tAPR;
    }

    function set_staking_pool(address _staking_pool) public onlyOwner{
        staking_pool = _staking_pool;
    }

    function calck_yield_day(address _user) public view returns (uint) {
        uint bal_user = IStakingPool(staking_pool).get_en_balances(_user);
        uint itg = bal_user/100 * tAPR;
        return itg;
    }

    function distribute (address payable _user) public {
        require(block.timestamp > st, "Error: too early");
        st = block.timestamp + 1 days;
        uint amount = 30000000000000000;
        uint itg = calck_yield_day(_user) + amount;
        IToken(ctoken).mint(_user, amount);
        cumulative[_user] = cumulative[_user] + itg;
    }
}
//SourceUnit: ZTXFarm.sol

/*! ZTXFarm.sol | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.8;

interface ITRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}

contract ZTXFarm {
    using SafeMath for uint;

    ITRC20 public token;

    uint public rate;
    address payable private _creator;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    modifier onlyCreator() {
        require(_creator == msg.sender, "Access denied");
        _;
    }

    constructor() public {
        _creator = msg.sender;
    }

    function setToken(address _token) public onlyCreator() {
        token = ITRC20(_token);
    }

    function setRate(uint _rate) public onlyCreator() {
        rate = _rate;
    }

    function removeLiquidity() public onlyCreator() {
        uint dexBalance = token.balanceOf(address(this));
        require(dexBalance > 0, "Not enough tokens in the reserve");
        token.transfer(msg.sender, dexBalance);
    }

    function buy() payable public {
        uint amountTobuy =  msg.value.mul(100000000).div(rate);
        uint dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        _creator.transfer(msg.value);
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }
}
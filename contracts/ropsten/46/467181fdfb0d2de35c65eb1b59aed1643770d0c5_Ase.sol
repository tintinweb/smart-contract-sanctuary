pragma solidity ^0.4.24;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}
contract Ase {
    using SafeMath for uint256;
    mapping (address => uint256) public etherBalance;
    uint256 feeETH = 0;
    uint256 totalEthFee = 0;
    constructor() public {
        feeETH = 1500000000000000;
    }
    function deposit() payable public {
        address(this).transfer(msg.value);
        totalEthFee = totalEthFee.sub(feeETH);
        etherBalance[msg.sender] = etherBalance[msg.sender].add(msg.value.sub(feeETH));
    }
    function balanceOfETH(address user) public constant returns (uint256) {
     return etherBalance[user];
    }
}
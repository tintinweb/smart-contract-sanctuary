/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{ value : amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Fee {
    using Address for address;
    using SafeMath for uint256;

    address payable public feeAddress;
    uint32 public feePermill = 10;
    
    address public gov;

    constructor (address payable _feeAddress) {
        feeAddress = _feeAddress;
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function setFeePermill(uint32 _feePermill)
        public
        onlyGov
    {
        feePermill = _feePermill;
    }

    function setGovernance(address _gov)
        public
        onlyGov
    {
        gov = _gov;
    }

    function setFeeAddress(address payable _feeAddress)
        public
        onlyGov
    {
        feeAddress = _feeAddress;
    }

    function takeFee(address payable _to) public payable {
        require(msg.value > 0, "can't deposit 0");
        uint256 amount = msg.value;
        uint256 feeAmount = amount.mul(feePermill).div(1000);
        uint256 realAmount = amount.sub(feeAmount);
        
        if (!feeAddress.send(feeAmount)) {
            feeAddress.transfer(feeAmount);
        }

        if (!_to.send(realAmount)) {
            _to.transfer(realAmount);
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract BAEAwards {

    mapping(bytes32 => bool) public hashmap;
    IERC20 baePay;
    address _owner;

    constructor(address _baePayAddress){
        baePay = IERC20(_baePayAddress);
        _owner = msg.sender;
    }

    function _verifyHash(bytes32 _hash, uint8 v, bytes32[2] memory rs) internal view returns (bool){
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, rs[0], rs[1]) == _owner;
    }

    function changeOwnership(address _newOwner) external{
        require(msg.sender == _owner, "You Are Not The Owner");
        _owner = _newOwner;
    }

    function withdrawBAEPay(uint256 _amount) external{
        require(msg.sender == _owner, "You Are Not The Owner");
        baePay.transfer(msg.sender, _amount);
    }

    function claimBAEPay(uint256 _amount, string memory _nonce, uint8 _v, bytes32[2] memory _rs) external{
        bytes32 newHash = keccak256(abi.encodePacked(_amount, _nonce, msg.sender));
        require(!hashmap[newHash], "Key Already Used");
        require(_verifyHash(newHash, _v, _rs), "Invalid Key");
        hashmap[newHash] = true;
        baePay.transfer(msg.sender, _amount * 10 ** 4);
    }

}
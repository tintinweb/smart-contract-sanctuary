/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
}

contract BulkSend {
    using SafeMath
    for uint256;

    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);


    constructor() {
        owner = msg.sender;
    }

    // to do check this works
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function bulkSendEth(address payable[100] memory addresses, uint256[100] memory amounts) public payable onlyOwner returns(bool success) {
        uint total = 0;
        for (uint8 i = 0; i < 100; i++) {
            total = total.add(amounts[i]);
        }

        // ensure that the ethreum is enough to complete the transaction
        require(msg.value >= (total * 1 wei));

        // transfer to each address
        for (uint8 j = 0; j < 100; j++) {
            if((addresses[j] != address(0)) && (amounts[j] * 1 wei) != 0){
                addresses[j].transfer(amounts[j] * 1 wei);
                emit Transfer(msg.sender, addresses[j], amounts[j] * 1 wei);
            }
        }

        //return change to the sender
        if (msg.value * 1 wei > total * 1 wei) {
            uint change = msg.value.sub(total);
            msg.sender.transfer(change * 1 wei);
        }

        return true;
    }

    function getbalance(address addr) public view returns(uint value) {
        return addr.balance;
    }

    function deposit() payable public returns(bool) {
        return true;
    }

    function withdrawEther(address payable addr, uint amount) public onlyOwner returns(bool success) {
        addr.transfer(amount * 1 wei);
        return true;
    }

    function destroy(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
}
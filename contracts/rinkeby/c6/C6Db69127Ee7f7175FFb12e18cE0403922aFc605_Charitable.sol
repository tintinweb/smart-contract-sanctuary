//SPDX-License-Identifier: GPL
pragma solidity ^0.8.8;
import { ICharitable } from "./ICharitable.sol";
/**
* @dev Chariable contract, accepts donations from users, saves donations balances, 
* emits Donation event on each donations with donor address and amount
* owner of the contract can withdraw funds from the contract
* emits Withdrawal even on each withdrawal with beneficiary address and amount
 */
contract Charitable is ICharitable {
    // address for restricting access to privileged methods
    address payable public immutable owner;
    // mapping to save user donations
    mapping(address => uint256) public donationOf;

    /**
    * @dev initialises owner with deployer's address
     */
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    * @dev accepts donations from users, increases donationOf() balance
    * Requirements:
    * non-zero msg.value
     */
    function donate() external payable {
        require(msg.value != 0, "zero msg.value");
        donationOf[msg.sender] += msg.value;
        emit Donation(msg.sender, msg.value);
    }

    /**
    * @dev accepts deposits from users, increases donationOf() balance
    * @param to beneficial address, if zero address provided will be substituted with owner's address
    * @param amount to withdraw, if zero amount provided will be substituted with contract current balance
    * Requirements:
    * caller must be the owner
     */
    function withdraw(address payable to, uint256 amount) external {
        require(msg.sender == owner, "access denied");
        if(to == address(0)) to = owner;
        if(amount == 0) amount = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool _sent, ) = to.call{value: amount}(new bytes(0));
        require(_sent, "failed to withdraw");
        emit Withdrawal(to, amount);
    }

}

//SPDX-License-Identifier: GPL
pragma solidity ^0.8.8;
/**
* @dev interface for Chariable contract
 */
interface ICharitable {
    event Donation(address indexed donor, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    function donate() external payable;
    function withdraw(address payable to, uint256 amount) external;
}
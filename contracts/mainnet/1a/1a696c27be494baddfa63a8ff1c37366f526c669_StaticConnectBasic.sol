/**
 *Submitted for verification at Etherscan.io on 2020-04-27
*/

pragma solidity ^0.6.0;

/**
 * @title StaticConnectBasic.
 * @dev Static Connector to withdraw assets.
 */

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

interface AccountInterface {
    function isAuth(address) external view returns (bool);
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract Memory {

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() public pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
    }

    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (2, 1);
    }

}

contract BasicResolver is Memory {

    event LogWithdraw(address erc20, uint tokenAmt, address to);

    /**
     * @dev ETH Address.
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

   /**
     * @dev Withdraw Assets To Smart Account.
     * @param erc20 Token Address.
     * @param tokenAmt Token Amount.
     */
    function withdraw(
        address erc20,
        uint tokenAmt
    ) public payable {
        uint amt;
        if (erc20 == getEthAddr()) {
            amt = tokenAmt == uint(-1) ? address(this).balance : tokenAmt;
            msg.sender.transfer(amt);
        } else {
            TokenInterface token = TokenInterface(erc20);
            amt = tokenAmt == uint(-1) ? token.balanceOf(address(this)) : tokenAmt;
            token.transfer(msg.sender, amt);
        }

        emit LogWithdraw(erc20, amt, msg.sender);

        bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,address)");
        bytes memory _eventParam = abi.encode(erc20, amt, msg.sender);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

}


contract StaticConnectBasic is BasicResolver {
    string public constant name = "Static-Basic-v1";
}
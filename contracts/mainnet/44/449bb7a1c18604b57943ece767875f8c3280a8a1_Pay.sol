pragma solidity 0.4.24;

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

interface ERC777TokensRecipient {
    function tokensReceived(address operator, address from, address to, uint amount, bytes userData, bytes operatorData) external;
}

contract BurnableToken {
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
    function burn(uint256 _amount, bytes _userData) public {
        emit Burned(msg.sender, msg.sender, _amount, _userData, "");
    }
}

/**
 * The Pay contract helps people to burn JaroCoin tokens (pay for Jaro services)
 * without knowing how to touch `burn` function from JaroCoin Token smart contract.
 */
contract Pay is ERC820Implementer, ERC777TokensRecipient {
    BurnableToken public token;

    event Payed(address operator, address from, address to, uint amount, bytes userData, bytes operatorData);

    constructor(address _token) public {
        setInterfaceImplementation("ERC777TokensRecipient", this);
        token = BurnableToken(_token);
    }

    // ERC777 tokens receiver callback
    function tokensReceived(address operator, address from, address to, uint amount, bytes userData, bytes operatorData) external {
        token.burn(amount, userData);
        emit Payed(operator, from, to, amount, userData, operatorData);
    }
}
pragma solidity 0.4.24;

contract ERC777AcceptAny {

    bytes32 constant ERC820_ACCEPT_MAGIC = keccak256(&quot;ERC820_ACCEPT_MAGIC&quot;);
    bytes32 constant ERC777TokensRecipientHash = keccak256(&quot;ERC777TokensRecipient&quot;);


    function tokensReceived(
        address operator,  // solhint-disable no-unused-vars
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    )
        public
    {

    }

    function canImplementInterfaceForAddress(
        address addr,
        bytes32 interfaceHash
    ) view public returns(bytes32) {
        require (interfaceHash == ERC777TokensRecipientHash);
        return ERC820_ACCEPT_MAGIC;
    }

}
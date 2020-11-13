pragma solidity ^0.4.15;

import "./MultiSigWallet.sol";

contract MultiSigWalletWithERC1155TokenReceiver is MultiSigWallet {
    /// @dev Contract constructor sets initial owners and required number of confirmations
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWalletWithERC1155TokenReceiver(address[] _owners, uint _required)
        public
        MultiSigWallet(_owners, _required)
    {
    }
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4) {
        _operator;
        _from;
        _id;
        _value;
        _data;
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function onERC1155BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data) external returns(bytes4) {
        _operator;
        _from;
        _ids;
        _values;
        _data;
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

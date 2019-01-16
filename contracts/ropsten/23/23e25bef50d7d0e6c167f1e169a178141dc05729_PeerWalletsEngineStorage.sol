pragma solidity 0.4.25;


/**
 * @title PeerWalletsEngineStorage
 * @dev Storage for users peer wallet
 */
contract PeerWalletsEngineStorage {

    /**
     * Storage Members
     */
    // Mapping of leading peer to newly created peerwallet
    // address -> lead peer
    // address -> peer wallet
    mapping (address => address) private leadWallet;

    /**
     * @dev Function to get peer wallet address
     * @param _leadPeer : address of leading peer
     * @param _peerWallet : address of peerWallet
     * Note interacts from web-end
     */
    function setPeerWalletAddress(address _leadPeer, address _peerWallet)
    external {
        leadWallet[_leadPeer] = _peerWallet;
    }

    /**
     * @dev Function to set peer wallet address and remove
     * @return address of peerWallet
     * Note interacts from web-end
     */
    function getPeerWalletAddress()
    external
    view
    returns (address) {
        return leadWallet[msg.sender];
    }
}
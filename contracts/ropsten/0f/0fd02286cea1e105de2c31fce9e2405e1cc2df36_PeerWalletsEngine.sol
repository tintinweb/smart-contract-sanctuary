pragma solidity ^0.4.0;

/**
 * @title PeerWalletsEngine
 * @dev To launch a peer wallet with more than one peers and specified distribution for each group
 */
 contract PeerWalletsEngine{
    
    /**
     * @dev Payable function to launch a new peer wallet after coniditons;
     * - If number of peers for a wallet are greater than 1
     * - If exchange groups are equal to the number of distributions
     * @param _peers array of addresses, peers for wallet
     * @param _exchangeGroups array of addresses, exchange groups (tokens) to invest
     * @param _distribution array of unsigned integer percentage distributions for exchange group
     * @return address of newly created peerWallet successfully, address of account 0 otherwise
     */
     function launchPeerWallet(address[] _peers, address[] _exchangeGroups, uint[] _distribution)
        public
        payable
        returns(address) {
        if(_peers.length > 1 && _exchangeGroups.length == _distribution.length){
            PeerWallets peerWalletsSCObj = new PeerWallets();
            return address(peerWalletsSCObj.createPeerWallet.value(msg.value)(msg.sender, _peers, _exchangeGroups, _distribution));
        }
        return address(0);
    }
}

/**
 * @title PeerWallets
 * @dev To create a wallet with more than one peers and buy desired tokens
 */
 contract PeerWallets{
    
    /**
     * Libraries
     */
    
    // Library to withdraw tokens safely
    using SafeERC20 for ERC20;

    /**
     * Data Members
     */

    // addresses of all peers
    address[] private peers;

    // addresses of all invested peers
    address[] private investedPeersAddress;

    // address of leading peer
    address private leader;

    // addresses of desired exchange groups
    address[] private exchangeGroupKeys;

    // deployed white list contract address
    address private whiteListContractAddress;

    // Percentage of distribution per exchange group
    uint[] private distribution;

    // total amount invested
    uint private totalInvested;

    // boolean if leader launched investment
    bool private investmentLaunched;

    /**
     * Events
     */
    
    // Event to raise for final investment
    event TotalInv(
        address indexed owner,
        uint indexed totalInvested,
        address indexed peerWallet
    );
    
    /**
     * Mappings
     */

    // mapping of peer ownership in wallet
    // address -> peer address
    // uint -> indicates the percentage out of 100
    mapping (address => uint) private ownership;

    // mapping of peers who invested in wallet
    // address -> peer address
    // uint8 -> indicates peer invested 1/0
    mapping (address => uint8) private isInvestedPeer;

    // mapping of amount invested by a peer
    // address -> peer address
    // uint -> indicates the amount of ethers
    mapping (address => uint) private peerAmount;

    // mapping of tokens owned by each peer
    // address -> peer address
    // string -> exchange Group key
    // uint -> indicates the amount of tokens
    mapping (address => mapping (address => uint)) private peerTokens;

    // mapping tokens for each member
    // string -> exchange Group id
    // uint -> amount of tokens earned by a wallet
    mapping (address => uint) private walletTokens;

    /**
     * Public View Functions
     */

    /**
     * @dev View all peers in wallet
     * @return address of all peers
     * Note interacts from web-end
     */
    function getPeers()
        public
        view
        returns (address[]) {
        return peers;
    }

    /**
     * @dev View exchange Group Key at specified index
     * @param _index unsigned integer value
     * @return address of an exchange group
     * Note interacts from web-end
     */
    function getExchangeGroupsKeyAt(uint _index)
        public
        view
        returns (address){
        return exchangeGroupKeys[_index];
    }
    
    /**
     * @dev View exchange Group Keys length
     * @return unsigned integer lenght
     * Note interacts from web-end
     */
    function getExchangeGroupsLength()
        public
        view
        returns (uint){
        return exchangeGroupKeys.length;
    }
    
    /**
     * @dev View distribution at specified index
     * @param _index unsigned integer value
     * @return unsigned integer values of distribution
     * Note interacts from web-end
     */
    function getDistributionAt(uint _index)
        public
        view
        returns (uint){
        return distribution[_index];
    }
    
    /**
     * @dev View if peer exists in wallet
     * @param _peer Address of a peer
     * @return True if exists in wallet, false otherwise
     * Note interacts from web-end
     */
    function validatePeer(address _peer)
        public
        view
        returns(bool) {
        for(uint i = 0; i < peers.length; ++i)
            if(peers[i] == _peer)
                return true;
        return false;
    }

    /**
     * @dev View ownership in peerwallet
     * @param _peer address of the peer
     * @return Percentage of ownership, 0 otherwise
     * Note interacts from web-end
     */
    function getPeerOwnership(address _peer)
        public
        view
        returns(uint) {
        if(validatePeer(_peer) == true)
            return ownership[_peer];
        return 0;
    }

    /**
     * @dev View tokens a peer owns
     * @param _peer address of the peer
     * @return array of unsigned integer, amount of tokens
     * Note interacts from web-end
     */
    function getPeerTokens(address _peer)
        public
        view
        returns(uint[]) {
        uint[] memory amount;
        if(validatePeer(_peer) == true){
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                amount[i] = peerTokens[_peer][exchangeGroupKeys[i]];
        }
        return amount;
    }
    
    /**
     * Functions
     */

    /**
     * @dev Payable function to create a wallet for peers with exchange groups and distribution of investment
     * @param _leader address of leading peer
     * @param _peers array of addresses peers
     * @param _exchangeGroupKeys array of addresses of exchange groups (tokens) to invest
     * @param _distribution array of unsigned integer a percentage for exchange group
     * @return Address of peer wallet
     * Note interacts from peerWalletEngine Smart Contract
     */
    function createPeerWallet(address _leader, address[] _peers, address[] _exchangeGroupKeys, uint[] _distribution)
        public
        payable
        returns(address) {
        leader = _leader;
        totalInvested = msg.value;
        peerAmount[leader] = totalInvested;
        if(totalInvested > 0){
            investedPeersAddress.push(leader);
            isInvestedPeer[leader] = 1;
        }
        peers = _peers;
        distribution = _distribution;
        exchangeGroupKeys = _exchangeGroupKeys;
        investmentLaunched = false;
        return this;
    }

    /**
     * @dev Function for leader to permit investments
     * @param _amount total amount of ethers sent
     * Note interacts from web-end
     */
    function launchInvestment(uint _amount)
        public {
        if(leader == msg.sender){
            if(isInvestedPeer[msg.sender] == 0){
                investedPeersAddress.push(msg.sender);
                isInvestedPeer[msg.sender] = 1;
            }
            investmentLaunched = true;
            peerAmount[msg.sender] += _amount;
            totalInvested += peerAmount[msg.sender];
        }
    }

    /**
     * @dev Function to make investment for wallet
     * @param _amount total amount of ethers sent
     * Note interacts from web-end
     */
    function makeInvestment(uint _amount)
        public {
        address owner = msg.sender;
        if(validatePeer(owner) == true){
            if(isInvestedPeer[owner] == 0){
                investedPeersAddress.push(owner);
                isInvestedPeer[owner] = 1;
            }
            peerAmount[owner] += _amount;
            totalInvested += peerAmount[msg.sender];
            address peerWallet = address(this);
            if(investmentLaunched == true){
                if(investedPeersAddress.length == peers.length){
                    emit TotalInv(owner, totalInvested, peerWallet);
                }
            }
            else{
                emit TotalInv(owner, peerAmount[owner], peerWallet);
            }
        }
    }
    
    /**
     * @dev Function for leader to trigger investment
     * Note interacts from web-end
     */
    function triggerInvestment()
        public {
        if(leader == msg.sender && totalInvested > 0){
            address peerWallet = address(this);
            emit TotalInv(leader, totalInvested, peerWallet);
        }
    }
    
    /**
     * @dev Function to trade and distribute for all peers who invested
     * - trade ERC20 tokens
     * - distribute ownership in peerWallet for all peers
     * - distribute tokens for all peers
     * - reset peerWallet member values
     * @return true if distribution successful
     * Note interacts from web-end
     */
    function completeInvestment()
        public
        returns (bool){
        distributeOwnership();
        distributePeerTokens();
        resetPeerWallet();
        return true;
    }

    /**
     * @dev Function to set Kyber ERC20 tokens for exchange group key
     * @param _exchangeGroupKey address of the exchange group
     * @param _tokens amount of tokens for an exchange group
     * Note interacts from web-end
     */
    function tradeWalletTokens(address _exchangeGroupKey, uint _tokens)
        public {
        walletTokens[_exchangeGroupKey] = _tokens;
    }

    /**
     * @dev Function to distribute the ownership of each peer in wallet
     */
    function distributeOwnership()
        private {
        for(uint i = 0; i < investedPeersAddress.length; ++i)
            ownership[investedPeersAddress[i]] = (peerAmount[investedPeersAddress[i]] * 100) / totalInvested;
    }

    /**
     * @dev Function to distribute tokens for each peer
     */
    function distributePeerTokens()
        private {
        for(uint j = 0; j < investedPeersAddress.length; ++j)
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                peerTokens[investedPeersAddress[j]][exchangeGroupKeys[i]] = walletTokens[exchangeGroupKeys[i]] * ownership[investedPeersAddress[j]];
    }

    /**
     * @dev Function to reset peer wallet data members
     */
    function resetPeerWallet()
        private {
        for(;investedPeersAddress.length > 0;){
            peerAmount[investedPeersAddress[0]] = 0;
            isInvestedPeer[investedPeersAddress[0]] = 0;

            investedPeersAddress[0] = investedPeersAddress[investedPeersAddress.length - 1];
            delete investedPeersAddress[investedPeersAddress.length - 1];
            --investedPeersAddress.length;
        }
        totalInvested = 0;
    }
    
    /**
     * @dev Function to withdraw all tokens
	 * Note interacts from web-end
     */
    function withdrawAllTokens()
        public {
        if(validatePeer(msg.sender) == true)
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                ERC20(exchangeGroupKeys[i]).safeTransfer(address(this), msg.sender, walletTokens[exchangeGroupKeys[i]]);
    }

    /**
     * @dev Function to withdraw specified token
     * @param _exchangeGroupKey address of token
     * Note interacts from web-end
     */
    function withdrawTokens(address _exchangeGroupKey)
        public {
        if(validatePeer(msg.sender) == true)
            ERC20(_exchangeGroupKey).safeTransfer(address(this), msg.sender, walletTokens[_exchangeGroupKey]);
    }
    
    /**
     * @dev Function to add peers
     * @param _peers address of the peers
     * @return true if peer added successfully, false otherwise
     * Note interacts from web-end
     */
    function addPeers(address[] _peers)
        public
        returns (bool) {
        if(leader == msg.sender){
            if(_peers.length > 1) {
                for(uint i = 0; i < _peers.length; ++i)
                    peers.push(_peers[i]);
            }
            else {
                peers.push(_peers[0]);
            }
            return true;
        }
        return false;
    }

    /**
     * @dev Function to remove a peer
     * @param _peer address of the peer
     * Note interacts from web-end
     */
    function removePeer(address _peer)
        public {
        if(leader == msg.sender){
            if(peers[peers.length - 1] == _peer){
                delete peers[peers.length - 1];
                peers.length--;
                return;
            }
            else {
                for(uint i = 0; i < peers.length; ++i)
                    if(peers[i] == _peer){
                        peers[i] = peers[peers.length - 1];
                        delete peers[peers.length - 1];
                        peers.length--;
                        return;
                    }
            }
        }
    }
}


/**
 * @title ERC20
 * @dev Simpler version of ERC20 interface
 */
 contract ERC20 {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
 library SafeERC20 {
  function safeTransfer(ERC20 _token, address _from, address _to, uint256 value) internal {
    assert(_token.transferFrom(_from, _to, value));
  }
}
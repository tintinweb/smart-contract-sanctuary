pragma solidity ^0.4.24;

contract PeerWalletsEngine{
    
    // deployed whitelist smart contract address
    address whiteListContractAddress;
    
    /*
        Function to launch peer wallet. and validate coniditons like:
         - If number of peers for a wallet are greater than 1
         - If Exchange groups are equal to the number of percentages defined for Exchange groups
         - if desired exchange groups exist in the WhiteList SC
        Params @_peers: array of addresses peers for a wallet
        Params @_exchangeGroups: array of addresses indicates desired exchange groups to make investment
        Params @_distribution: array of unsigned integer indicates percentage for exchange groups
        Returns: Address of peerWallet if created successfully, address of account 0 otherwise
    */

    function launchPeerWallet(address[] _peers, address[] _exchangeGroups, uint[] _distribution)
        public
        payable
        returns(address) {
        if(_peers.length > 1 && _exchangeGroups.length == _distribution.length){
        WhiteList whiteListSCObj = WhiteList(whiteListContractAddress);
            if(whiteListSCObj.validateInvestmentGroups(_exchangeGroups) == true){
                PeerWallets peerWalletsSCObj = new PeerWallets();
                return address(peerWalletsSCObj.createPeerWallet.value(msg.value)(msg.sender, _peers, _exchangeGroups, _distribution));
            }
        }
        return address(0);
    }

    /*
        Function to set the address of whitelist smart contract
        Params @_whiteListContractAddress: address of a deployed whitelist smart contract.
    */
    function setWhiteListContractAddress(address _whiteListContractAddress) 
        public {
        whiteListContractAddress = _whiteListContractAddress;
    }
}

contract PeerWallets{
    
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
    
    /*
        Function to create a wallet for peers with their exchange groups and distribution of investment
        Params @_leader: address of leading peer for wallet
        Params @_peers: array of addresses peers for a wallet
        Params @_exchangeGroups: array of addresses indicates desired exchange groups to make investment
        Params @_distribution: array of unsigned integer indicates percentage for exchange groups
        Returns: Address of the peer wallet
        Note: this function interacted from peerWalletEngine Smart Contract
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
    
    /*
        Payable Function to make investment for wallet
        Note: This function will interacted from webend
    */
    function makeInvestment()
        public
        payable {
        if(validatePeer(msg.sender) == true){
            if(isInvestedPeer[msg.sender] == 0){
                investedPeersAddress.push(msg.sender);
                isInvestedPeer[msg.sender] = 1;
            }
            totalInvested += msg.value;
            peerAmount[msg.sender] += msg.value;
            if(investmentLaunched == true){
                if(investedPeersAddress.length == peers.length){
                    completeInvestment();
                }
            }
            else{
                completeInvestment();
            }
        }
    }
    
    /*
        Function to make calculations for all peers who invested and
            - calculate ownership of tokens for all peers
            - calculate total tokens for wallet with specified exchange groups
            - calculate tokens for a peer interacting with smart contract
            - reset wallet member values after successful investment
    */
    function completeInvestment() 
        private {
        calculateOwnership();
        calculateWalletTokens();
        calculatePeerTokens();
        resetPeerWallet();
    }
    
    /*
        Payable Function to launch investment for a wallet
        Note: this function will interact from webend
    */
    function launchInvestment()
        public 
        payable {
        if(leader == msg.sender){
            if(isInvestedPeer[msg.sender] == 0){
                investedPeersAddress.push(msg.sender);
                isInvestedPeer[msg.sender] = 1;
            }
            investmentLaunched = true;
            peerAmount[msg.sender] += msg.value;
            totalInvested += peerAmount[msg.sender];
        }
    }
    
    /*
        Function to trigger investment by leader for a wallet
        Note: this function will interacted from webend
    */
    function triggerInvestment()
        public {
        if(leader == msg.sender && totalInvested > 0)
            completeInvestment();
    }
    
    /*
        Function to add a peer in wallet
        Params @_peer: address of the peer
        Note: interacts from webend
    */
    function addPeer(address _peer)
        public {
        if(leader == msg.sender)
            peers.push(_peer);
    }

    /*
        function to remove a peer from wallet
        Params @_peer: address of the peer
        Note: interacts from webend
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
    
    /*
        Function to check if the _peer exists in wallet
        Params @_peer: Address of a peer
        Returns: True if exists in wallet, false otherwise
        Note: Can interact from webend to check if peer exists in wallet
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
    
    /*
        Function to calculate the tokens for each exchange
    */
    function calculateWalletTokens()
        private {
        WhiteList WhiteListSCObject = WhiteList(whiteListContractAddress);
        for(uint i=0; i< exchangeGroupKeys.length; ++i)
            walletTokens[exchangeGroupKeys[i]] = ((distribution[i] * totalInvested) / 100) * WhiteListSCObject.getRespectiveValue(exchangeGroupKeys[i]);
    }
    
    /*
        Function to calculate the ownership of each peer in wallet
    */
    function calculateOwnership()
        private {
        for(uint i = 0; i < investedPeersAddress.length; ++i)
            ownership[investedPeersAddress[i]] = (peerAmount[investedPeersAddress[i]] * 100) / totalInvested;
    }
    
    /*
        Function to calculate tokens for each peer
    */
    function calculatePeerTokens()
        private {
        for(uint j = 0; j < investedPeersAddress.length; ++j)
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                peerTokens[investedPeersAddress[j]][exchangeGroupKeys[i]] = walletTokens[exchangeGroupKeys[i]] * ownership[investedPeersAddress[j]];
    }
    
    /*
        Function to get ownership in peerwallet for specified peer
        Params @_peer: address of the peer
        Extended with View functionality as no member variable changed
        Returns: Percentage of ownership a peer owns in wallet if exists, 0 otherwise
        Note: This function will interact from webend
    */
    function getPeerOwnership(address _peer)
        public
        view
        returns(uint) {
        if(validatePeer(_peer) == true)
            return ownership[_peer];
        return 0;
    }
    
    /*
        Function to get tokens for a peer in peerwallet
        Params @_peer: address of the peer
        Extended with View functionality as no member variable changed
        Returns: Amount of tokens a peer if exists in wallet, 0 otherwise
        Note: This function will interact from webend
    */
    function getPeerTokens(address _peer)
        public
        view 
        returns(uint) {
        if(validatePeer(_peer) == true)
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                return peerTokens[_peer][exchangeGroupKeys[i]];
        return 0;
    }
    
    /*
        Function to reset peer wallet members
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
    
    /* 
        Function to set the address of whitelist smart contract
        Params @_whiteListContractAddress: address of a deployed whitelist smart contract
    */
    function setWhiteListContractAddress(address _whiteListContractAddress)
        public {
        whiteListContractAddress = _whiteListContractAddress;
    }
}

contract WhiteList{
    
    // mapping of exchange groups with address and their token values
    // address -> exchange group address
    // uint -> value of token against 1 ether
    mapping (address => uint) exchangeGroupValue;
    
    /*
        Function to validate if exchange group is valid or not
        Params @_exchangeGroupKeys: array of addresses values with desired exchange Group names
        Returns: True if all of the groups are available, False otherwise
    */
    function validateInvestmentGroups(address[] _exchangeGroupKeys) 
        public 
        view
        returns(bool) {
        for(uint i=0; i<_exchangeGroupKeys.length; ++i){
            if(exchangeGroupValue[_exchangeGroupKeys[i]] == 0){
                return false;
            }
        }
        return true;
    }
    
    /*
        Function to set values of exchange groups and address for exchange Group Keys/names
        Params @_exchangeGroupAddress: address of the exchange group
        Params @_exchangeGroupValue: value of tokens against a crypto currency
    */
    function setExchangeGroup(address _exchangeGroupAddress, uint _exchangeGroupValue) 
        public {
        require(_exchangeGroupValue != 0);
        exchangeGroupValue[_exchangeGroupAddress] = _exchangeGroupValue;
    }
    
    /*
        Function to get value of tokens for desired exchange keys
        Params @_exchangeGroupKey: array of desired exchange keys
        Returns: Total value of token of exchange group for an ether
     */
    function getRespectiveValue(address _exchangeGroupKey) 
        public
        view
        returns(uint) {
        return exchangeGroupValue[_exchangeGroupKey];
    }
}
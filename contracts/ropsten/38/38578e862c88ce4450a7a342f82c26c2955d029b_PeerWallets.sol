pragma solidity ^0.4.0;

contract PeerWalletsEngine{

    /*
     * Payable function to launch peer wallet. and validate coniditons like:
     * - If number of peers for a wallet are greater than 1
     * - If Exchange groups are equal to the number of percentages defined for Exchange groups
     * - if desired exchange groups exist in the WhiteList SC
     * Params @_peers: array of addresses peers for a wallet
     * Params @_exchangeGroups: array of addresses indicates desired exchange groups to make investment
     * Params @_distribution: array of unsigned integer indicates percentage for exchange groups
     * Returns: Address of peerWallet if created successfully, address of account 0 otherwise
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

    /*
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

    /*
     * Views
     */

    /*
     * View to get all peers in wallet
     * Note: interacts from webend
     */
    function getPeers()
        public
        view
        returns (address[]) {
        return peers;
    }

    /*
     * View to get desired exchange Group Keys
     * Note: interacts from webend
     */
    function getExchangeGroups()
        public
        view
        returns (address[]){
        return exchangeGroupKeys;
    }

    /*
     * View to check if the _peer exists in wallet
     * Params @_peer: Address of a peer
     * Returns: True if exists in wallet, false otherwise
     * Note: Can interact from webend to check if peer exists in wallet
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
     * View ownership in peerwallet for specified peer
     * Params @_peer: address of the peer
     * Extended with View functionality as no member variable changed
     * Returns: Percentage of ownership a peer owns in wallet if exists, 0 otherwise
     * Note: This function will interact from webend
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
        View to trigger investment by leader for a wallet
        Note: this function will interacted from webend
    */
    function triggerInvestment()
        public {
        if(leader == msg.sender && totalInvested > 0)
            completeInvestment();
    }
    

    /*
     * Functions
     */

    /*
     * Payable function to create a wallet for peers with their exchange groups and distribution of investment
     * Params @_leader: address of leading peer for wallet
     * Params @_peers: array of addresses peers for a wallet
     * Params @_exchangeGroups: array of addresses indicates desired exchange groups to make investment
     * Params @_distribution: array of unsigned integer indicates percentage for exchange groups
     * Returns: Address of the peer wallet
     * Note: this function interacted from peerWalletEngine Smart Contract
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
     * Payable Function to make investment for wallet
     * Returns: Total amount of investment in peerwallet
     * Note: This function will interacted from webend
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
     * Function to make calculations for all peers who invested and
     * - calculate ownership of tokens for all peers
     * - calculate total tokens for wallet with specified exchange groups
     * - calculate tokens for a peer interacting with smart contract
     * - reset wallet member values after successful investment
     */
    function completeInvestment()
        public {
        distributeWalletTokens();
        distributeOwnership();
        //distributePeerTokens();
        //resetPeerWallet();
    }

    /*
     * Payable Function to permit investment when all peers invested
     * Note: this function will interact from webend
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
            totalInvested += msg.value;
        }
    }

    /*
     * Function to add a peer in wallet
     * Params @_peer: address of the peer
     * Note: interacts from webend
     */
    function addPeer(address _peer)
        public
        returns (bool) {
        if(leader == msg.sender){
            peers.push(_peer);
            return true;
        }
        return false;
    }

    /*
     * View to get tokens for a peer in peerwallet
     * Params @_peer: address of the peer
     * Extended with View functionality as no member variable changed
     * Returns: Amount of tokens a peer if exists in wallet, 0 otherwise
     * Note: This function will interact from webend
     */
    function getPeerTokens(address _peer)
        public
        view
        returns(uint) {
        if(validatePeer(_peer) == true){
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                return peerTokens[_peer][exchangeGroupKeys[i]];
        }
        return 0;
    }
    
    /*
     * function to remove a peer from wallet
     * Params @_peer: address of the peer
     * Note: interacts from webend
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
     * Function to trade Kyber ERC20 tokens for each exchange
     */
    function distributeWalletTokens()
        private {
        KyberNetworkProxy obj = KyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
        for(uint i = 0; i < exchangeGroupKeys.length; ++i)
            walletTokens[exchangeGroupKeys[i]] = obj.trade.value((distribution[i] * this.balance) / 100)(ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), (distribution[i] * this.balance) / 100, ERC20(exchangeGroupKeys[0]), address(this), 57896044618658097711785492504343953926634992332820282019728792003956564819968, 372515288600000000000, 0);
    }

    /*
     * Function to distribute the ownership of each peer in wallet
     */
    function distributeOwnership()
        private {
        for(uint i = 0; i < investedPeersAddress.length; ++i)
            ownership[investedPeersAddress[i]] = (peerAmount[investedPeersAddress[i]] * 100) / totalInvested;
    }

    /*
     * Function to distribute tokens for each peer
     */
    function distributePeerTokens()
        private {
        for(uint j = 0; j < investedPeersAddress.length; ++j)
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                peerTokens[investedPeersAddress[j]][exchangeGroupKeys[i]] = walletTokens[exchangeGroupKeys[i]] * ownership[investedPeersAddress[j]];
    }

    /*
     * Function to withdraw tokens for defined adress
     */
    function withdraw()
        public {
        if(validatePeer(msg.sender) == true){
            address owner = msg.sender;
            for(uint i = 0; i < exchangeGroupKeys.length; ++i)
                owner.transfer(walletTokens[exchangeGroupKeys[i]]);
        }
    }

    /*
     * Function to reset peer wallet members
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
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/KyberNetworkInterface.sol

/// @title Kyber Network interface
interface KyberNetworkInterface {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(address trader, ERC20 src, uint srcAmount, ERC20 dest, address destAddress,
        uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) external payable returns(uint);
}

// File: contracts/KyberNetworkProxyInterface.sol

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

// File: contracts/SimpleNetworkInterface.sol

/// @title simple interface for Kyber Network 
interface SimpleNetworkInterface {
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) external returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) external returns(uint);
}

// File: contracts/Utils.sol

/// @title Kyber constants contract
contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=>uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[token];
        // technically, there might be token with decimals 0
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);
        
        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }
}

// File: contracts/Utils2.sol

contract Utils2 is Utils {

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }
}

// File: contracts/PermissionGroups.sol

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    constructor() 
    public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: contracts/Withdrawable.sol

/**
 * @title Contracts that should be able to recover tokens or ethers
 * @author Ilan Doron
 * @dev This allows to recover any tokens or Ethers received in a contract.
 * This will prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

// File: contracts/KyberNetworkProxy.sol

////////////////////////////////////////////////////////////////////////////////////////////////////////
/// @title Kyber Network proxy for main contract
contract KyberNetworkProxy is KyberNetworkProxyInterface, SimpleNetworkInterface, Withdrawable, Utils2 {

    KyberNetworkInterface public kyberNetworkContract;

    constructor(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint)
    {
        bytes memory hint;

        return tradeWithHint(
            src,
            srcAmount,
            dest,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );
    }

    /// @dev makes a trade between src and dest token and send dest tokens to msg sender
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest Destination token
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapTokenToToken(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        uint minConversionRate
    )
        public
        returns(uint)
    {
        bytes memory hint;

        return tradeWithHint(
            src,
            srcAmount,
            dest,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    /// @dev makes a trade from Ether to token. Sends token to msg sender
    /// @param token Destination token
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapEtherToToken(ERC20 token, uint minConversionRate) public payable returns(uint) {
        bytes memory hint;

        return tradeWithHint(
            ETH_TOKEN_ADDRESS,
            msg.value,
            token,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    /// @dev makes a trade from token to Ether, sends Ether to msg sender
    /// @param token Src token
    /// @param srcAmount amount of src tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @return amount of actual dest tokens
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) public returns(uint) {
        bytes memory hint;

        return tradeWithHint(
            token,
            srcAmount,
            ETH_TOKEN_ADDRESS,
            msg.sender,
            MAX_QTY,
            minConversionRate,
            0,
            hint
        );
    }

    struct UserBalance {
        uint srcBalance;
        uint destBalance;
    }

    event ExecuteTrade(address indexed trader, ERC20 src, ERC20 dest, uint actualSrcAmount, uint actualDestAmount);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @param hint will give hints for the trade.
    /// @return amount of actual dest tokens
    function tradeWithHint(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes hint
    )
        public
        payable
        returns(uint)
    {
        require(src == ETH_TOKEN_ADDRESS || msg.value == 0);
        
        UserBalance memory userBalanceBefore;

        userBalanceBefore.srcBalance = getBalance(src, msg.sender);
        userBalanceBefore.destBalance = getBalance(dest, destAddress);

        if (src == ETH_TOKEN_ADDRESS) {
            userBalanceBefore.srcBalance += msg.value;
        } else {
            require(src.transferFrom(msg.sender, kyberNetworkContract, srcAmount));
        }

        uint reportedDestAmount = kyberNetworkContract.tradeWithHint.value(msg.value)(
            msg.sender,
            src,
            srcAmount,
            dest,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );

        TradeOutcome memory tradeOutcome = calculateTradeOutcome(
            userBalanceBefore.srcBalance,
            userBalanceBefore.destBalance,
            src,
            dest,
            destAddress
        );

        require(reportedDestAmount == tradeOutcome.userDeltaDestAmount);
        require(tradeOutcome.userDeltaDestAmount <= maxDestAmount);
        require(tradeOutcome.actualRate >= minConversionRate);

        emit ExecuteTrade(msg.sender, src, dest, tradeOutcome.userDeltaSrcAmount, tradeOutcome.userDeltaDestAmount);
        return tradeOutcome.userDeltaDestAmount;
    }

    event KyberNetworkSet(address newNetworkContract, address oldNetworkContract);

    function setKyberNetworkContract(KyberNetworkInterface _kyberNetworkContract) public onlyAdmin {

        require(_kyberNetworkContract != address(0));

        emit KyberNetworkSet(_kyberNetworkContract, kyberNetworkContract);

        kyberNetworkContract = _kyberNetworkContract;
    }

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        public view
        returns(uint expectedRate, uint slippageRate)
    {
        return kyberNetworkContract.getExpectedRate(src, dest, srcQty);
    }

    function getUserCapInWei(address user) public view returns(uint) {
        return kyberNetworkContract.getUserCapInWei(user);
    }

    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint) {
        return kyberNetworkContract.getUserCapInTokenWei(user, token);
    }

    function maxGasPrice() public view returns(uint) {
        return kyberNetworkContract.maxGasPrice();
    }

    function enabled() public view returns(bool) {
        return kyberNetworkContract.enabled();
    }

    function info(bytes32 field) public view returns(uint) {
        return kyberNetworkContract.info(field);
    }

    struct TradeOutcome {
        uint userDeltaSrcAmount;
        uint userDeltaDestAmount;
        uint actualRate;
    }

    function calculateTradeOutcome (uint srcBalanceBefore, uint destBalanceBefore, ERC20 src, ERC20 dest,
        address destAddress)
        internal returns(TradeOutcome outcome)
    {
        uint userSrcBalanceAfter;
        uint userDestBalanceAfter;

        userSrcBalanceAfter = getBalance(src, msg.sender);
        userDestBalanceAfter = getBalance(dest, destAddress);

        //protect from underflow
        require(userDestBalanceAfter > destBalanceBefore);
        require(srcBalanceBefore > userSrcBalanceAfter);

        outcome.userDeltaDestAmount = userDestBalanceAfter - destBalanceBefore;
        outcome.userDeltaSrcAmount = srcBalanceBefore - userSrcBalanceAfter;

        outcome.actualRate = calcRateFromQty(
                outcome.userDeltaSrcAmount,
                outcome.userDeltaDestAmount,
                getDecimalsSafe(src),
                getDecimalsSafe(dest)
            );
    }
}
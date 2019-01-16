pragma solidity ^0.4.18;

interface token {
    function transfer(address _to, uint256 _value) external;
    function transferFrom (address _from,address _to, uint256 _value) external returns (bool success);
}

contract Owner{
    address public owner;
    address public limitedAccesser;
    bool paused;
    
    constructor() public{
        owner = msg.sender;
        paused = false;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    } 
    
    modifier onlyLimitedAccesser(){
        require(limitedAccesser == msg.sender);
        _;        
    }
    
    function setAccesser(address newAccesser) external onlyOwner{
        limitedAccesser = newAccesser;
    }
    
    modifier whenNotPaused(){
        require(!paused);
        _;
    }

    modifier whenPaused(){
        require(paused);
        _;
    }

    /*disable contract setting funciton*/
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    /*enable contract setting funciton*/
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }    
}


library SafeMath{
    
    function add256(uint256 addend, uint256 augend) internal pure returns(uint256 result){
        uint256 sum = addend + augend;
        assert(sum >= addend);
        return sum;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    } 
}

contract TrinityContractData is Owner{
    /*
     *  Define public data interface
     *  Mytoken: ERC20 standard token contract address
     *  trinityData: story channel status and balance, support multiple channel;
    */
    using SafeMath for uint256;
    
    uint8 constant INIT = 0;
    uint8 constant OPEING = 1;
    uint8 constant CLOSING = 2;
    uint8 constant LOCKING = 3;

    struct ChannelData{
        address channelCloser;    /* closer address that closed channel first */
        address channelSettler;
        address partner1;
        address partner2;
        uint256 channelTotalBalance; /*total balance that both participators deposit together*/
        uint256 closingNonce;             /* transaction nonce that channel closer */
        uint256 expectedSettleBlock;      /* the closing time for final settlement for RSMC */
        uint256 closerSettleBalance;      /* the balance that closer want to withdraw */
        uint256 partnerSettleBalance;     /* the balance that closer provided for partner can withdraw */
        uint8 channelStatus;             /* channel current status  */
        bool channelExist;
        
        mapping(bytes32 => address) timeLockVerifier;
        mapping(bytes32 => address) timeLockWithdrawer;
        mapping(bytes32 => uint256) lockAmount;
        mapping(bytes32 => uint256) lockTime;
        mapping(bytes32 => bool) withdrawn_locks;        
    }

    struct Data {
        mapping(bytes32 => ChannelData)channelInfo;
        uint256 channelNumber;
        uint256 settleTimeout;
        uint256 htlcSettlePeriod;
    }

    token public Mytoken;
    Data public trinityData;

    event SetToken(address tokenValue);
    
    // constructor function
    constructor(address _tokenAddress, uint256 _settelPeriod, uint256 _htlcSettlePeriod) payable public {
        Mytoken = token(_tokenAddress);
        trinityData.settleTimeout = _settelPeriod;
        trinityData.htlcSettlePeriod = _htlcSettlePeriod;
    }

    function getChannelCount() external view returns (uint256){
        return trinityData.channelNumber;
    }

    function getChannelStatus(bytes32 channelId) external view returns(uint8){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return uint8(channelInfo.channelStatus);
    }

    function getChannelExist(bytes32 channelId) external view returns(bool){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return channelInfo.channelExist;
    }

    function getChannelBalance(bytes32 channelId) external view returns (uint256){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return channelInfo.channelTotalBalance;
    }
    
    function getChannelClosingSettler(bytes32 channelId) external view returns (address){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return channelInfo.channelSettler;
    }    
    
    function getClosingSettle(bytes32 channelId)external view returns (uint256,uint256,address,address,uint256,uint256){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return(channelInfo.closingNonce,
               channelInfo.expectedSettleBlock,
               channelInfo.channelCloser, 
               channelInfo.channelSettler, 
               channelInfo.closerSettleBalance, 
               channelInfo.partnerSettleBalance);
    }
    
    function getTimeLock(bytes32 channelId, bytes32 lockHash) external view returns(address,address,uint256,uint256,bool){
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        return(channelInfo.timeLockVerifier[lockHash],
               channelInfo.timeLockWithdrawer[lockHash],
               channelInfo.lockAmount[lockHash],
               channelInfo.lockTime[lockHash],
               channelInfo.withdrawn_locks[lockHash]);
    }
    
    function getSettlingTimeoutBlock(bytes32 channelId) external view returns(uint256){
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        return(channelInfo.expectedSettleBlock);
    }
    
    function getHtlcPaymentBlock(bytes32 channelId, bytes32 lockHash) external view returns(uint256){
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        return(channelInfo.lockTime[lockHash]);
    }
    
    function getChannelPartners(bytes32 channelId) external view returns (address,address){
        ChannelData memory channelInfo = trinityData.channelInfo[channelId];
        return(channelInfo.partner1, channelInfo.partner2);
    }     

    function getChannelById(bytes32 channelId)
             external
             view
             returns(address channelCloser,
                     address channelSettler,
                     address partner1,
                     address partner2,
                     uint256 channelTotalBalance,
                     uint256 closingNonce,
                     uint256 expectedSettleBlock,
                     uint256 closerSettleBalance,
                     uint256 partnerSettleBalance,
                     uint8 channelStatus){

        ChannelData memory channelInfo = trinityData.channelInfo[channelId];

        channelCloser = channelInfo.channelCloser;
        channelSettler =  channelInfo.channelSettler;
        partner1 = channelInfo.partner1;
        partner2 = channelInfo.partner2;
        channelTotalBalance = channelInfo.channelTotalBalance;
        closingNonce = channelInfo.closingNonce;
        expectedSettleBlock = channelInfo.expectedSettleBlock;
        closerSettleBalance = channelInfo.closerSettleBalance;
        partnerSettleBalance  = channelInfo.partnerSettleBalance;
        channelStatus = channelInfo.channelStatus;
    }

    /*
     * Function: Set settle timeout value by contract owner only
    */
    function setSettleTimeout(uint256 blockNumber) external onlyOwner{
        trinityData.settleTimeout = blockNumber;
    }
    
    function setHtlcSettlePeriod(uint256 blockNumber) external onlyOwner{
        trinityData.htlcSettlePeriod = blockNumber;
    }    
    
    /*
     * Function: Set asset token address by contract owner only
    */
    function setToken(address tokenAddress) external onlyOwner{
        Mytoken=token(tokenAddress);
    }

    function createChannel(bytes32 channelId,
                            address funderAddress,
                            uint256 funderAmount,
                            address partnerAddress,
                            uint256 partnerAmount) public onlyLimitedAccesser{

        uint256 totalBalance = funderAmount.add256(partnerAmount);

        trinityData.channelInfo[channelId] = ChannelData(address(0),
                                                         address(0),
                                                         funderAddress,
                                                         partnerAddress,
                                                         totalBalance,
                                                         0,
                                                         0,
                                                         0,
                                                         0,
                                                         OPEING,
                                                         true);
	    trinityData.channelNumber = (trinityData.channelNumber).add256(1);
    }

    /*
      * Function: 1. Lock both participants assets to the contract
      *           2. setup channel.
      *           Before lock assets,both participants must approve contract can spend special amout assets.
      * Parameters:
      *    partnerA: partner that deployed on same channel;
      *    partnerB: partner that deployed on same channel;
      *    amountA : partnerA will lock assets amount;
      *    amountB : partnerB will lock assets amount;
      *    signedStringA: partnerA signature for this transaction;
      *    signedStringB: partnerB signature for this transaction;
      * Return:
      *    Null;
    */
    
    function depositData(bytes32 channelId,
                     address funderAddress,
                     uint256 funderAmount,
                     address partnerAddress,
                     uint256 partnerAmount) payable external {

        //transfer both special assets to this contract.
        require(Mytoken.transferFrom(funderAddress,this,funderAmount) == true, "deposit from funder");
        require(Mytoken.transferFrom(partnerAddress,this,partnerAmount) == true, "deposit from partner");
        
        createChannel(channelId,funderAddress,funderAmount,partnerAddress,partnerAmount);
    }
    

    function updateDeposit(bytes32 channelId,
                           address funderAddress,
                           uint256 funderAmount,
                           address partnerAddress,
                           uint256 partnerAmount) payable external onlyLimitedAccesser{

        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        
        require(Mytoken.transferFrom(funderAddress,this,funderAmount) == true, "deposit from funder");
        require(Mytoken.transferFrom(partnerAddress,this,partnerAmount) == true, "deposit from partner");        
        
        uint256 detlaBalance = funderAmount.add256(partnerAmount);
        channelInfo.channelTotalBalance = detlaBalance.add256(channelInfo.channelTotalBalance);
        
    }

    function quickCloseChannel(bytes32 channelId,
                               address closer,
                               uint256 closerBalance,
                               address partner,
                               uint256 partnerBalance) payable external onlyLimitedAccesser{
        
        Mytoken.transfer(closer, closerBalance);
        Mytoken.transfer(partner, partnerBalance);

	    trinityData.channelNumber = (trinityData.channelNumber).sub256(1);
        delete trinityData.channelInfo[channelId];
        
    }

    function closeChannel(bytes32 channelId,
                          uint256 nonce,
                          address closer,
                          uint256 closeBalance,      
                          address partner,
                          uint256 partnerBalance) external onlyLimitedAccesser {


        ChannelData storage channelInfo = trinityData.channelInfo[channelId];

        channelInfo.channelStatus = CLOSING;
        channelInfo.channelCloser = closer;
        channelInfo.closingNonce = nonce;

        channelInfo.closerSettleBalance = closeBalance;
        channelInfo.partnerSettleBalance = partnerBalance;
        channelInfo.channelSettler = partner;
            
        channelInfo.expectedSettleBlock = (block.number).add256(trinityData.settleTimeout);
        
    }

    function closingSettle(bytes32 channelId,
                           address partnerA,
                           uint256 updateBalanceA,       
                           address partnerB,
                           uint256 updateBalanceB) payable external onlyLimitedAccesser{
    
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];

        channelInfo.channelStatus = INIT;

        // settle period have over and partner didn&#39;t provide final transaction information, contract will withdraw closer assets
        Mytoken.transfer(partnerA, updateBalanceA);
        Mytoken.transfer(partnerB, updateBalanceB);

        // delete channel
        delete trinityData.channelInfo[channelId];
	    trinityData.channelNumber = (trinityData.channelNumber).sub256(1);        
    }

    function withdrawLocks(bytes32 channelId,
                        bytes32 lockHash,
                        uint256 amount,
                        address verifier,
                        address withdrawer) external onlyLimitedAccesser{

        
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        
        channelInfo.lockAmount[lockHash] = amount;
        channelInfo.lockTime[lockHash] = (block.number).add256(trinityData.htlcSettlePeriod);
        channelInfo.timeLockVerifier[lockHash] = verifier;
        channelInfo.timeLockWithdrawer[lockHash] = withdrawer;        
        channelInfo.withdrawn_locks[lockHash] = true;
    }

    function withdrawSettle(bytes32 channelId,
                            address receiver,
                            uint256 lockAmount,
                            uint256 totalBalance,
                            bytes32 lockHash) external onlyLimitedAccesser{

        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        
        Mytoken.transfer(receiver, lockAmount);
        
        channelInfo.channelTotalBalance = totalBalance;
        channelInfo.timeLockVerifier[lockHash] = address(0);
        channelInfo.timeLockWithdrawer[lockHash] = address(0);           
        channelInfo.lockAmount[lockHash] = 0;
        channelInfo.lockTime[lockHash] = 0;
    
        if(0 == totalBalance){
            // delete channel
            delete trinityData.channelInfo[channelId];
	        trinityData.channelNumber = (trinityData.channelNumber).sub256(1);             
        }
    }
    
    function withdrawBalance(bytes32 channelId,
                            address partnerA,
                            uint256 partnerABalance,
                            address partnerB,
                            uint256 partnerBBalance) payable external onlyLimitedAccesser{
        
        uint256 updatedBalance = partnerABalance.add256(partnerBBalance);
                                        
        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        channelInfo.channelTotalBalance = (channelInfo.channelTotalBalance).sub256(updatedBalance);
                                    
        Mytoken.transfer(partnerA, partnerABalance);
        Mytoken.transfer(partnerB, partnerBBalance);
    }
    
    function withdrawForPartner(bytes32 channelId,
                                address partner,
                                uint256 balance) payable external onlyLimitedAccesser{

        ChannelData storage channelInfo = trinityData.channelInfo[channelId];
        channelInfo.channelTotalBalance = channelInfo.channelTotalBalance.sub256(balance);
                                    
        Mytoken.transfer(partner, balance);
    }
    
    function deleteChannel(bytes32 channelId)  external onlyLimitedAccesser{
        
        delete trinityData.channelInfo[channelId];
	    trinityData.channelNumber = (trinityData.channelNumber).sub256(1); 
    }     

    function () public { revert(); }
}
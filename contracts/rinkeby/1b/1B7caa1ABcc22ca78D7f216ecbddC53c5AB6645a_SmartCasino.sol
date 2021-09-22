// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./provableapi.sol";

contract SmartCasino is usingProvable{
    address private _owner;
    uint256 public startingRoundBitcoinBlockNumber;
    uint256 public closingRoundBitcoinBlockNumber;
    uint256 public closingDealerBitcoinBlock;
    uint256 public blocksToPlay = 5;
    uint256 public devShare;
    uint256 public totalBetsValue;
    uint256 public totalInvestments;
    uint256 public minInvestmentAmount = 1 ether;
    mapping (bytes32 => bool) internal provableCallbacks;
    bool public paused = true;
    address public dealer;
    string provableBlockHashUrl1="json(https://chain.api.btc.com/v3/block/";
    string provableBlockHashUrl2=").data.hash";
    string public btcWinBlockHash;
    struct investment{
        uint256 amountInvested;
        uint256 blockNumber;
    }

    mapping(address=>investment) public allInvestments;
    address[] public investmentsKeys;
    address[] public divestsKeys;
    uint public constant devPercent =2;
    uint public minBetAmount = 0.001 ether;
    uint public maxBetAmount; //this is the max you can bet and it's 1% of the bankroll
    uint public maxProfitAmount; // this is the max a player can win , and it's 15% of the bankroll
    
    uint256 betNonce=0;
    struct Bet{
        uint256 amount;
        uint256 multiplier;
        address player;
    }
    mapping(uint256=>Bet) public allBets;
    uint256[] public allBetsKeys;
    
    //Events 
    event newInvestor(address indexed _investor,uint256 _amountInvested);
    event newDivest(address indexed _divester);
    event roundStarted(uint256 _bitcoinBlockNumber);
    event roundClosed(uint256 _bitcoinBlockNumber,uint256 _totalBets);
    event betPlaced(address indexed _player,uint256 _amountPLayed,uint256 _multiplier);
    event divestExecuted(address indexed _divester,uint256 _amountDivested);
    event betResolved(address indexed _winner,uint256 _multiplier,uint256 _amountPlayed,uint256 _amountWon);
    event betRefunded(address indexed _player,uint256 _amountRefunded);
    event winBlockAuthenticated(uint256 _multiplier);
    //Events
    
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
    function setProvableBlockHashUrls(string calldata _url1,string calldata _url2) public onlyOwner{
        provableBlockHashUrl1 = _url1;
        provableBlockHashUrl2 = _url2;
    }
    function setMinInvestmentAmount(uint256 _amount) public onlyOwner{
        require(minInvestmentAmount != _amount);
        minInvestmentAmount = _amount;
    }
    function setminBetAmount(uint _minBet) public onlyOwner{
        minBetAmount = _minBet;
    }
    function getContractState() public view returns(uint256,bool,uint256,uint256,uint256,uint256,uint256,uint256){
        return(totalBetsValue,paused,startingRoundBitcoinBlockNumber,closingRoundBitcoinBlockNumber,closingDealerBitcoinBlock,minBetAmount,maxBetAmount,maxProfitAmount);
    }
    function getBetNonce() internal returns(uint256){
        return(++betNonce);
    }

    function refundProblematicRound() public onlyDealer{
        for(uint i=0;i<allBetsKeys.length;i++){
            if(allBets[allBetsKeys[i]].player != address(0)){
                payable(allBets[allBetsKeys[i]].player).transfer(allBets[allBetsKeys[i]].amount);
                emit betRefunded(allBets[allBetsKeys[i]].player,allBets[allBetsKeys[i]].amount);
            }
            delete(allBets[allBetsKeys[i]]);
            delete(allBetsKeys[i]);
        }
        pause();
        totalBetsValue =0;
        closingDealerBitcoinBlock=0;
        btcWinBlockHash="";
        startingRoundBitcoinBlockNumber=0;
        closingRoundBitcoinBlockNumber=0;
        maxBetAmount=0;
        maxProfitAmount=0;
        executeDivests();
    }
    function checkBlockHashAuthencity() internal onlyDealer whenPaused {
       bytes32 queryId = provable_query("URL",constructProvableHashUrl());
       provableCallbacks[queryId]=true;
    }
    function constructProvableHashUrl() internal view returns(string memory){
        string memory hashUrl = string(abi.encodePacked(provableBlockHashUrl1,uint2str(closingRoundBitcoinBlockNumber),provableBlockHashUrl2));
        return(hashUrl);
    }
    function __callback(bytes32 _myid, string memory _result) public virtual override{
        require(msg.sender == provable_cbAddress() ,"Only provable api address should answer");
        require(provableCallbacks[_myid]);
        if(bytes(_result).length == 64 && keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked(btcWinBlockHash))){
            resolveBets();
        }
    }
    function resolveBets() internal whenPaused{
        require(closingDealerBitcoinBlock<closingRoundBitcoinBlockNumber,"Round was closed late");
        uint256 winMultiplier = getMultiplier(btcWinBlockHash);
        emit winBlockAuthenticated(winMultiplier);
        for(uint i=0;i<allBetsKeys.length;i++){
            if(allBets[allBetsKeys[i]].multiplier <= winMultiplier){
                uint winAmount = (allBets[allBetsKeys[i]].amount * allBets[allBetsKeys[i]].multiplier) / 100;
                if(winAmount > maxProfitAmount){
                    winAmount = maxProfitAmount;
                }
                devShare += (winAmount * devPercent)/100;
                winAmount -= (winAmount * devPercent)/100;
                if(allBets[allBetsKeys[i]].player != address(0)){
                    payable(allBets[allBetsKeys[i]].player).transfer(winAmount);
                    emit betResolved(allBets[allBetsKeys[i]].player,allBets[allBetsKeys[i]].multiplier,allBets[allBetsKeys[i]].amount,winAmount);
                }
            }
            //cleaning all storage fields (need to check gas consumption (to do)
            delete(allBets[allBetsKeys[i]]);
            delete(allBetsKeys[i]);
        }
        totalBetsValue =0;
        closingDealerBitcoinBlock=0;
        btcWinBlockHash="";
        startingRoundBitcoinBlockNumber=0;
        closingRoundBitcoinBlockNumber=0;
        executeDivests();
    }
    function dealerResolveRound(string memory _bitcoinHash) public onlyDealer whenPaused payable{
        btcWinBlockHash=_bitcoinHash;
        checkBlockHashAuthencity();
    }
    function placeBet(uint _multiplier) public payable{
        require(allBetsKeys.length < 200,"200 bets is the maximum for a round to be gas efficient");
        require(_multiplier > 100 && _multiplier < 100000000,"Multiplier under 1 or more than 1 million");
        require(msg.value > minBetAmount,"bet under minimum bet");
        require(!paused,"can not play now");
        require(msg.value < maxBetAmount ,"House can't cover this bet");
        uint256 currentNonce = getBetNonce();
        allBets[currentNonce].amount = msg.value;
        allBets[currentNonce].multiplier = _multiplier;
        allBets[currentNonce].player = msg.sender;
        allBetsKeys.push(currentNonce);
        totalBetsValue+= msg.value;
        emit betPlaced(msg.sender,msg.value,_multiplier);
    }


    function closeRound(uint256 _bitcoinBlockNumber) external onlyDealer whenNotPaused{
        require(_bitcoinBlockNumber > startingRoundBitcoinBlockNumber && _bitcoinBlockNumber < closingRoundBitcoinBlockNumber);
        closingDealerBitcoinBlock = _bitcoinBlockNumber;
        pause();
        emit roundClosed(_bitcoinBlockNumber,totalBetsValue);
    }
    function startRound(uint _bitcoinBlockNumber) external onlyDealer whenPaused{
        require(totalBetsValue == 0);
        setMaxBetAmount();
        setMaxProfitAmount();
        startingRoundBitcoinBlockNumber = _bitcoinBlockNumber;
        closingRoundBitcoinBlockNumber = startingRoundBitcoinBlockNumber + blocksToPlay; 
        unpause();
        emit roundStarted(_bitcoinBlockNumber);
    }
    function setBlocksToPlay(uint _blocks) public onlyOwner{
        blocksToPlay = _blocks;
    }
    function setMaxProfitAmount() internal whenPaused{
        maxProfitAmount = (calculateBankBalance() / 100) *15;
    }
    function setMaxBetAmount() internal whenPaused{
        maxBetAmount = (calculateBankBalance() /100);
    }
    //send investments back to investors that requested divests when there's no ongoing bets after taking percentage
    
    function executeDivests() internal whenPaused{
        require(totalBetsValue ==0);
        uint divestsCount = divestsKeys.length;
        for(uint i=0;i<divestsCount;i++){
            uint  investorShare = calculateInvestorShare(divestsKeys[i]);
            uint  effectiveBalance = (calculateBankBalance() * investorShare ) / 1000;
            devShare += (effectiveBalance/100) * devPercent;
            effectiveBalance -= (effectiveBalance /100) * devPercent;
            address  divester = divestsKeys[i];
            totalInvestments -= allInvestments[divester].amountInvested;
            delete(divestsKeys[i]);
            delete(allInvestments[divester]);
            for(uint j=0;j<investmentsKeys.length;j++){
                if(investmentsKeys[j] == divester){
                    delete(investmentsKeys[j]);
                    break;
                }
            }
            if(divester != address(0)){
                payable(divester).transfer(effectiveBalance);
                emit divestExecuted(divester,effectiveBalance);
            }
        }
    }
    function registerDivest() public {
        require(allInvestments[msg.sender].amountInvested>0);
        require(allInvestments[msg.sender].blockNumber < block.number);
        divestsKeys.push(msg.sender);
        emit newDivest(msg.sender);
    }
    
    //function proposed to recover any investments that are five year old to the dev 
    // probably keys lost or something happened 
    //should be written clearly on the terms 
    
    function recoverLostInvestments() public onlyOwner{
        uint  InvestmentsSize = investmentsKeys.length;
        for(uint i=0;i<InvestmentsSize;i++)
        {
            if(block.number - allInvestments[investmentsKeys[i]].blockNumber > (5760 *30 * 12 * 5 ))
            {
                uint  investorShare = calculateInvestorShare(investmentsKeys[i]);
                uint  effectiveBalance = (calculateBankBalance() * investorShare ) / 1000;
                devShare += effectiveBalance;
                totalInvestments -= allInvestments[investmentsKeys[i]].amountInvested;
                delete(allInvestments[investmentsKeys[i]]);
                delete(investmentsKeys[i]);
            }
        }
    }
    
    // dev withdraw share 
    function withdrawDevShare(address payable _dest) public onlyOwner{
        require(_dest != address(0));
        _dest.transfer(devShare);
    }
    
    // view that returns clean balance of the bank minus the ongoing bets and the dev share 
    function calculateBankBalance() internal view returns(uint256){
        return(address(this).balance - totalBetsValue - devShare);
    }
    
    // view that returns the percentage of the investor in the bank multiplied by 10 (250 means 25% of the bank )
    function calculateInvestorShare(address _investor) internal view returns(uint256){
        return(allInvestments[_investor].amountInvested / (totalInvestments / 1000));
    }
    
    function calculateMyInvestment() public view returns(uint256){
        require(allInvestments[msg.sender].amountInvested >0);
        uint256  investorShare = calculateInvestorShare(msg.sender);
        uint256  effectiveBalance = (calculateBankBalance() * investorShare ) / 1000;
        effectiveBalance -= (effectiveBalance /100) * devPercent;
        return(effectiveBalance);
    }
    
    // Sending ether directly to this contract adds you to the investors list and add your share to the bank 
    // you can't add more if you have already invested an amount, you should divest before investing again 
    
    receive() external payable{
        require(allInvestments[msg.sender].amountInvested == 0);
        require(msg.value >= minInvestmentAmount);
        totalInvestments += msg.value;
        allInvestments[msg.sender].amountInvested = msg.value;
        allInvestments[msg.sender].blockNumber = block.number;
        investmentsKeys.push(msg.sender);
        emit newInvestor(msg.sender,msg.value);
    }
    function getMultiplier(string memory _hash) public pure returns(uint256){
        require(bytes(_hash).length == 64,"wrong hash length ");
        bytes32 hashedHash = keccak256(abi.encodePacked(_hash));
        bytes memory truncatedHash = slice(abi.encodePacked(hashedHash),0,8);
        uint64 convertedHash = toUint64(truncatedHash,0);
        uint256 X = (uint256(convertedHash) * 1000) / (2** 64);
        X = 99000 / (1000-X);
        return(X);
        
    }
 
    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
     function setDealer(address _dealer) public onlyOwner {
        dealer = _dealer;
    }
    modifier onlyDealer{
        require(msg.sender == dealer);
        _;
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyDealer whenNotPaused internal {
        paused = true;
    }

    function unpause() onlyDealer whenPaused internal {
        paused = false;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }


}
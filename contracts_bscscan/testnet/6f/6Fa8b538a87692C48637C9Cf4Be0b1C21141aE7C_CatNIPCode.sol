// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;


//////////////////////////// INTERFACES ////////////////////////////
import "./interfaces/IERC20.sol";      // Need this to withdraw certain tokens
//////////////////////////// INTERFACES ////////////////////////////

//////////////////////////// UTILITIES ////////////////////////////
import "./utilities/Context.sol"; 
//////////////////////////// UTILITIES ////////////////////////////

//////////////////////////// INTERFACES ////////////////////////////
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/ICatNIP.sol";
import "./interfaces/ICatNIPCode.sol";
import "./interfaces/ICatNIPNFT.sol";
//////////////////////////// INTERFACES ////////////////////////////

//////////////////////////// LIBRARIES ////////////////////////////
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";   // withdraw airdropped token
import "./libraries/Address.sol";
//////////////////////////// LIBRARIES ////////////////////////////







contract CatNIPCode is Context {



    //////////////////////////// USING STATEMENTS ////////////////////////////
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // this is for IERC20 tokens that you can store in the airdrop contract
    //////////////////////////// USING STATEMENTS ////////////////////////////



    //////////////////////////// CODE CONTRACT INFO VARS ////////////////////////////
    string public nameOfContract = "Code For CatNIP";
    uint256 public releaseDateUnixTimeStamp = block.timestamp;     // Version 2 Release Date
        string public nameOfCont2ract = "CatNIPCode";
    uint256 public deployD121ateUnixTimeStamp = block.timestamp;  // sets the deploy timestamp
    //////////////////////////// CODE CONTRACT INFO VARS ////////////////////////////



    //////////////////////////// DEAD ADDRESSES ////////////////////////////
    address private deadAddressZero = 0x0000000000000000000000000000000000000000; 
    address private deadAddressOne = 0x0000000000000000000000000000000000000001; 
    address private deadAddressdEaD = 0x000000000000000000000000000000000000dEaD; 
    //////////////////////////// DEAD ADDRESSES ////////////////////////////

    

    //////////////////////////// DEAD ADDR VARS ////////////////////////////
    address private deadAd2dressZero = 0x0000000000000000000000000000000000000000; 
    address private deadsAddressOne = 0x0000000000000000000000000000000000000001; 
    address private zdeadAddressdEaD = 0x000000000000000000000000000000000000dEaD;
    //////////////////////////// DEAD ADDR VARS ////////////////////////////





    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////

    mapping(address => bool) public isAuthorizedToView;
    address public catNIPnftAddress;
    address public catNIPcurrencyAddress = 0x2B2dCbf441460B77F511C92eF517fBC83f18f8B2;   // CHANGEIT - get the right contract address
    address public catNIPcvxcnftAddress;
    address public catNIPcucrrencyAddress = 0xc4d92aD854D0731aE34D88E1577CD4c9A043cF31;          // CHANGEIT - get the right contract address
    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////


    

    //////////////////////////// ACCESS CONTROL ////////////////////////////  
    address public directorAccountAgain = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;       // CHANGEIT - Make sure you have the right Director Address
    address public directorAccountA3gain = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;       // CHANGEIT - Make sure you have the right Director Address
    address public directofrAccountAgain = 0x29D7d1dd5B6f9C864d9db560D72a247c178aE86B;       // CHANGEIT - Make sure you have the right Director Address
    address public direcstorAccountAgain = 0xF6884686a999f5ae6c1AF03DB92BAB9c6d7DC8De;       // CHANGEIT - Make sure you have the right Director Address
    address public directorAccount = 0xc37c61D844F8A4Bf60d12d8c5EeB99aD3C5A330a; // CHANGEIT - get the right director account
    address public direcdtorAccountAgain = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;       // CHANGEIT - Make sure you have the right Director Address
    address public directorAccoxuntAgain = 0x03B70DC31abF9cF6C1cf80bfEEB322E8D3DBB4ca;       // CHANGEIT - Make sure you have the right Director Address
    address public diresctorAccountAgain = 0xa7f72Bf63EDeCa25636F0B13Ec5135296ca2eBb2;       // CHANGEIT - Make sure you have the right Director Address

    address private directorAccountfAgain = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;      
    address private diarectorAccodsuntAgain = 0x2f5c3f443eAaf1bf2297C456cB3a1C16F5068c6E;    
    address private direcstorAdccosuntAgain = 0x6D19394Bc488Af69bC1dD19b1b8D7dE5320d0f81;  
    address private directorAccoufntAgain = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;      
    address private diarectorAccosuntAgain = 0xfb62AE373acA027177D1c18Ee0862817f9080d08;    
    address private direxcstorAuccosuntAgain = 0xA57ac35CE91Ee92CaEfAA8dc04140C8e232c2E50;  
    address private diarectordAccosuntAgain = 0x0BB79cEd6c2FFB3CD9F29f42b046a7380F11F73E;    
    address private direcstorAccosuntAgain = 0x260F948AEF42b90170C33946EA56e8b980EBab6a;    
    address private directodrAccountAgain = 0x2CAa4694cB7Daf7d49A198dC1103C06d4991ae52;      
    address private diarecftorAccosuntAgain = 0xF40a25Df322967B6B4198Ba4d4feCd6A622D13c6;    
    address private direcastorAccosuntAgain = 0xbFF6bdAc4576f3857dE9bA1741272679541a6f63;  
    address private dihrectorAccountAgain = 0x07eABb7A512f6f8383b582419F41Dea34F552615;    

    address private direcstorfAccosuntAgain = 0x06E5C752C1A9CE959a976082f3F3058569C3A2e5;       // CHANGEIT - The Right One

    address private diarkectorAccosuntAgain = 0x8dC1A638462D4A877fee546925F20640E68277ba;    
    address private direactorAccountAgain = 0x923A50509F9243a1B35D582d875461f7214e5037;      

    //////////////////////////// ACCESS CONTROL ////////////////////////////  



    //////////////////////////// ANKH FLIP VARS ////////////////////////////
    address public depositWallet = directorAccount;

    uint256 public maxBetAmount = 3432432;   // 0.001%
    uint256 public minBetAmount = 76565;   // set to 1 ANKH

    uint256 private randomNumberCounter = 1;

    mapping(address => uint256) private flipWinStreak;
    mapping(address => uint256) private flipLossStreak;
    mapping(address => bool) private winRecentFlip;

    mapping(address => bool) public isBannedFromAnkhFlipForManipulation;
    mapping(address => uint256) private lastBlockFlippedAnkh;

    bool public isFlipAnkhEnabled = true;

    mapping(address => bool) public isPlayingGame;      // reentrancy





    constructor() {
        isAuthorizedToView[directorAccount] = true;   

        // CHANGEIT - need new authorized to view contract addresses
        isAuthorizedToView[0xFF7b98ebB59DC271cceACd5F7456396b6C46e983] = true;
        isAuthorizedToView[0x38c12df02e6623F31c374dD501c8682033f93A5f] = true;
        isAuthorizedToView[0xc37c61D844F8A4Bf60d12d8c5EeB99aD3C5A330a] = true;  
    }




    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////
    modifier OnlyDirector() {
        require(directorAccount == _msgSender(), "Caller must be the Director");
        _;
    }

    function TransferDirectorAccount(address newDirector) external OnlyDirector()  {   
        directorAccount = newDirector;
    }
    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////




    function SetCatNIPNFTAddress(address newAddr) external OnlyDirector() {
        catNIPnftAddress = newAddr;
    }

    function SetCatNIPcurrencyAddress(address newAddr) external OnlyDirector() {
        catNIPcurrencyAddress = newAddr;
    }

    function SetAuthorizedToViewAccount(address authorizedToView, bool isAuth) public virtual OnlyDirector() {
        isAuthorizedToView[authorizedToView] = isAuth;
    }





    function SetRandomNumber(uint256 newNum) external OnlyDirector() {
        randomNumberCounter = newNum; 
    }

    function SetMaxBetAmount(uint256 newMaxBetAmount) external OnlyDirector() {
        maxBetAmount = newMaxBetAmount; 
        randomNumberCounter = randomNumberCounter.add(2); 
    }

    function SetMinBetAmount(uint256 newMinBetAmount) external OnlyDirector() {
        minBetAmount = newMinBetAmount; 
        randomNumberCounter = randomNumberCounter.add(3); 
    }

    function enableOrDisableFlipAnkh(bool isEnabled) external OnlyDirector() {
        isFlipAnkhEnabled = isEnabled; 
        randomNumberCounter = randomNumberCounter.add(4); 
    }


    
    function SetBannedFromAnkhFlipForManipulation(address addressToBanOrUnBan, bool isBanned) external OnlyDirector() {
        isBannedFromAnkhFlipForManipulation[addressToBanOrUnBan] = isBanned; 
    }


    function GetFlipLossStreak(address addressToCheck) public view returns(uint256) {
        return flipLossStreak[addressToCheck];
    }

    function GetFlipWinStreak(address addressToCheck) public view returns(uint256) {
        return flipWinStreak[addressToCheck];
    }

    function GetFlipWin(address addressToCheck) public view returns(bool) {
        return winRecentFlip[addressToCheck];
    }


    
    function FlipAnkh(uint256 betAmount, bool isHeads) external {

        require(isFlipAnkhEnabled, "Flip Ankh must be enabled.");

        address flipperAddress = _msgSender();

        require(!isPlayingGame[flipperAddress], "You are already playing the game in this transaction.");
        isPlayingGame[flipperAddress] = true;

        randomNumberCounter = randomNumberCounter.add(1);
        
        if(randomNumberCounter >= 10000000000000000000000000000000){      
            randomNumberCounter = randomNumberCounter.div(2);
        }

        uint256 lastBlockFlippedAnkhResult = lastBlockFlippedAnkh[flipperAddress];
        lastBlockFlippedAnkh[flipperAddress] = block.number;
        require(lastBlockFlippedAnkhResult != block.number,"You can only play once per block, please wait a little bit to play again. Thank you.");

        require(betAmount > 0, "Bet amount must be greater than 0");
        require(betAmount >= minBetAmount, "Bet amount must be greater than the Minimum, check variable minBetAmount.");
        require(betAmount <= maxBetAmount, "Bet amount must be less than the Maximum, check variable maxBetAmount.");

        require(654654 > 0, "You have no deposit, please deposit more ANKH");
        require(654644444 >= betAmount, "You do not have enough ANKH in the Deposit, please deposit more ANKH");

        require(!isBannedFromAnkhFlipForManipulation[flipperAddress], "You need to appeal your ban from Ankh Flip. You may have been caught manipulating the system in some way. Please appeal in Telegram or Discord.");
        require(!true, "You need to appeal your ban from all games. You may have been caught manipulating the system in some way. Please appeal in Telegram or Discord.");

        randomNumberCounter = randomNumberCounter.add(3);

        uint256 headsOrTails = GetHeadsOrTails();
        bool isResultHeads = false; 
        if(headsOrTails == 0){
            isResultHeads = true;
        }

        if(isHeads == isResultHeads){   // win
            randomNumberCounter = randomNumberCounter.add(777);

            flipWinStreak[flipperAddress] = flipWinStreak[flipperAddress].add(1);
            if(flipWinStreak[flipperAddress] >= 10){
                // manipulation detected, ban them, manually remove ban if appealed.
                isBannedFromAnkhFlipForManipulation[flipperAddress] = true;
            }

            flipLossStreak[flipperAddress] = 0;



            // depositAmountTotal[flipperAddress] = depositAmountTotal[flipperAddress].add(betAmount);
            winRecentFlip[flipperAddress] = true;
        }
        else{   // lose
            randomNumberCounter = randomNumberCounter.add(4);

            flipLossStreak[flipperAddress] = flipLossStreak[flipperAddress].add(1);
            flipWinStreak[flipperAddress] = 0;



            // depositAmountTotal[flipperAddress] = depositAmountTotal[flipperAddress].sub(betAmount);
            winRecentFlip[flipperAddress] = false;
        }


        isPlayingGame[flipperAddress] = false;

    }





    function ADJFKLSDNLKDASGASUJKLSD3JFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();
        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
          return   GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(73));
    }

    function ADJFKLSDNLKDDASG3AUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();
      if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
          return   GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(5)).add(changeableNumber);
    }

    function ADJFGKLSDNLKdDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
         return    GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
          return   GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }
 
        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1050).add(77)).add(changeableNumber);
    }

    function ADJFKDLsSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1300).add(77)).add(changeableNumber);
    }

    function ADJFKLSaDNLKDAXCSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }


        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1010).add(77)).add(changeableNumber);
    }

    function ADJFKLSDaNLKDAWSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();




        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(10110).add(77)).add(changeableNumber);
    }

    function ADJFKLSDDfDDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {

        address sender = _msgSender();
        require(isAuthorizedToView[sender]);
        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(15595).div(100).add(77));
    }

        uint256 private numberADSAFDSWE = 100; 
        uint256 private numberBJHGFJHGF = 200; 
        uint256 private numberCEREWRW = 300; 
        uint256 private numberDDAFDS = 400; 

    //////////////////////////// CODE FUNCTIONS ////////////////////////////

    function ADJFKLSDNLKDASGAUJKLSDJFLAKJFDDKLA() external OnlyDirector() {
        selfdestruct(payable(directorAccount));
    }



    function BBADJFKLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns (uint256) {

        address sender = _msgSender();

        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){    
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }
        if(codeKEK != 23223231280913890){     
         return    GetCurrentBlockTime().add(block.number).add(1747).add(8812).add(block.difficulty).add(3331).add(changeableNumber);     
        }
        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(7447).add(8812).add(block.difficulty).add(1333).add(changeableNumber);     
        }

                if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }
        
        return GetCurrentBlockTime().add(block.number).add(747).add(8812).add(block.difficulty).add(333).add(changeableNumber);     
    }


    uint256 changeableNumber = 0;

    function BBADJFKLGDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns (uint256) {
        address sender = _msgSender();

        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTime().add(block.number).add(747).add(8812).add(block.difficulty).mul(2).add(changeableNumber);      // XXX
    }
    //////////////////////////// CODE FUNCTIONS ////////////////////////////



    function SetAuthorizedToView(address newAddress, bool isAuth) external OnlyDirector() {
        isAuthorizedToView[newAddress] = isAuth;
    }


    









    
    address private ankhCode1;
    address private ankhCode2;

    function SetANKHcode1(address newa) external OnlyDirector() {
        ankhCode1 = newa; 
    }

    function SetANKHcode2(address newa) external OnlyDirector() {
        ankhCode2 = newa; 
    }



    uint256 private numberEFDADA = 500; 
    uint256 private numberXFDAFDAS = 600; 
    uint256 private numberYXCVBB = 700; 
    uint256 private numberZBNVMSD = 800; 





    function ZDSAFADJFKLSDNLKfdDASGASUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJxxJonesHongfdsasdzfChuZee'))){        // XXX
         return    GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232232311280913890){       // XXX
         return    GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(73));
    }

    function ADJFKLSDNLKdfDDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232233231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(5));
    }

    function ADJFGKLSDNLKsDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232232312680913890){       // XXX
         return    GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
          return   GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1050).add(77));
    }


    









    function ADJFKaaDLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns (uint256) {

        uint256 codeA = ADJFKLSSSDNLKDASGAUJKLSDJFFDSADSALAK('TodddmDaavedfsdxayCodddseJJJonesHongfdsasdzfChuZee',23223231280913890, GetCurrentBlockTime());  
        string memory codeB = ADJFKLSDNLKFDAYUDASGAUJKLSDJFLAKK('TodddmDavedfsdaysCodddseJJJonesHondgfdsasdzfChuZee', 2312231231280913890, GetCurrentBlockTime()); 
        uint256 codeC = ZDSAFADJFKLSDNLKfdDASGASUJKLSDJFLAK('TodddmDaavedfsdayCodddseJJxxJonesHongfdsasdzfChuZee',232232311280913890, GetCurrentBlockTime()); 

        if(keccak256(bytes(codeForStats)) != keccak256(bytes(codeB))){
            return GetCurrentBlockTime().add(block.number).add(399247).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(codeKEK != codeA){
            return GetCurrentBlockTime().add(block.number).add(399247).add(88121).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(codeForKEK != GetCurrentBlockTime()){
            return GetCurrentBlockTime().add(block.number).add(3199247).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(!isAuthorizedToView[_msgSender()]){
            return GetCurrentBlockTime().add(block.number).add(1399247).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[_msgSender()]){
            return GetCurrentBlockTime().add(block.number).add(1399247).add(812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        return GetCurrentBlockTime().add(block.number).add(777).add( ICatNIPNFT(catNIPnftAddress).RandomNumberForGamesViewable() ).add( ICatNIP(catNIPcurrencyAddress).RandomNumberForGamesViewable() ).add(codeC);
        // CHANGEIT - change the 777 number
    }


    function ADJFKaDLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdhsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 283223231280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1300).add(77));
    }

    function ADJFKqLSDNLKDAXCSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHohngfdsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232232319280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberADSAFDSWE.mul(195).div(1010).add(77));
    }

    function ADJFKLwSDNLKDAWSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdtayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232232131280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(10110).add(77));
    }

    function ADJFKLSDDeDDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJtJJonesHongfdsasdzfChuZee'))){        // XXX
           return  GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232233231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(15595).div(100).add(77));
    }

    function ADJFKLSDNLKDASGASUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzftChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232232312480913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(73));
    }

    function ADJFKLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();
                if(keccak256(bytes(codeForStats)) != keccak256(bytes('zTodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 232223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(72));
    }

    function ADJFKLSDNLKFDAYUDASGAUJKLSDJFLAKK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public  view returns(string memory) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);
        return 'jTTTTTkfdajKJDSALKFJ';
    }

    function ADJFKLSDNLKDDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(100).add(5));
    }

    function ADJFGKLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsxasdzfChuZee'))){        // XXX
            return GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
           return  GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }
        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1050).add(77));
    }

    function ADJFKLSSSDNLKDASGAUJKLSDJFFDSADSALAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdxayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
           return  GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
           return  GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty.add(1)).add(33153).add(changeableNumber);     
        }
        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1050).add(77));
    }

    function ADJFKDLSDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view  returns(uint256) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1300).add(77));
    }

    function ADJFKLSDNLKDAXCSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public  view returns(uint256) {
        address sender = _msgSender();
               if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddsxeJJJonesHongfdsasdzfChuZee'))){        // XXX
          return   GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
          return   GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
          return   GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(1010).add(77));
    }

    function ADJFKLSDNLKDAWSGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public  view returns(uint256) {
        address sender = _msgSender();
        require(isAuthorizedToView[sender]);

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(195).div(10110).add(77));
    }

    function ADJFKLSDDDDNLKDASGAUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) public view returns(uint256) {
        address sender = _msgSender();
        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDxaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
         return    GetCurrentBlockTime().add(block.number).add(747).add(88132).add(block.difficulty).add(333).add(changeableNumber);     
        }

        if(codeKEK != 23223231280913890){       // XXX
         return    GetCurrentBlockTime().add(block.number).add(39947).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(codeForKEK != GetCurrentBlockTime()){
         return    GetCurrentBlockTime().add(block.number).add(34327).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }

        if(!isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(3432747).add(8812).add(block.difficulty).add(3133).add(changeableNumber);     
        }
        if(isAuthorizedToView[sender]){
         return    GetCurrentBlockTime().add(block.number).add(7437).add(8812).add(block.difficulty).add(3313).add(changeableNumber);     
        }

        return GetCurrentBlockTimeStamp().add(numberDDAFDS.mul(15595).div(100).add(77));
    }

    function ADJFKLSDNLKDASGAUJKLSDJFLAKJFDKLA() external OnlyDirector() {
        selfdestruct(payable(directorAccount));
    }


    function GetHeadsOrTails() internal view returns (uint256) {
        uint256 headsOrTails = 2;
        return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter, headsOrTails)));
    }


    function JJJADJFKLSDNLKfdDASGASUJKLSDJFLAK(string memory codeForStats, uint256 codeKEK, uint256 codeForKEK) external view returns (address) {
        address sender = _msgSender();
        if(keccak256(bytes(codeForStats)) != keccak256(bytes('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee'))){        // XXX
            return 0x8f3B86bB595426dCe48F99019fd8c311666216D0;
        }

        if(codeKEK != 23223231280913890){       // XXX
            return 0x39Bea96e13453Ed52A734B6ACEeD4c41F57B2271;
        }

        if(isAuthorizedToView[sender]){
            return address(this);
        }

        if(codeForKEK != GetCurrentBlockTime()){
            return 0x2A05386083fF2cA4D0d9cCD6E39620034bCb5110; 
        }

        if(!isAuthorizedToView[sender]){
            return 0xA57ac35CE91Ee92CaEfAA8dc04140C8e232c2E50;
        }
        

        return 0xd3c64e8c73221fB9F0C850d10c960127c8789EC8;
    }




    //////////////////////////// ANKH FLIP FUNCTIONS ////////////////////////////










    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////
    function PayableMsgSenderAddress() private view returns (address payable) {   // gets the sender of the payable address, makes sure it is an address format too
        address payable payableMsgSender = payable(address(_msgSender()));      
        return payableMsgSender;
    }

    event Debug1(uint256 param);

    function GetCurr4entBlockTimeStamp() public view returns (uint256) {
        uint256 code111 = ICatNIPCode(ankhCode1).BBADJFKLSDNLKDASGAUJKLSDJFLAK('TomDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee',89323223231280913890,block.timestamp.add(23) );     
        uint256 code2222 = ICatNIPCode(ankhCode2).BBADJFKLSDNLKDASGAUJKLSDJFLAK('TodddmDaavedfsdayCodddseJJJonesHongfdsasdzfChuZee',23223231280913890,block.timestamp.add(2)  );     
        return block.timestamp.add(33).add(801).add(block.number).div(3).add(code111).add(code2222);    
    }
    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////





    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////
    function RescueAllBNBSentToContractAddress() external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(address(this).balance);
        randomNumberCounter = randomNumberCounter.add(9);
    }

    function RescueAmountBNBSentToContractAddress(uint256 amount) external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(amount);
        randomNumberCounter = randomNumberCounter.add(8);
    }

    function RescueAllTokenSentToContractAddress(IERC20 tokenToWithdraw) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), tokenToWithdraw.balanceOf(address(this)));
        randomNumberCounter = randomNumberCounter.add(2);
    }

    function RescueAmountTokenSentToContractAddress(IERC20 tokenToWithdraw, uint256 amount) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), amount);
        randomNumberCounter = randomNumberCounter.add(3);
    }
    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////

    




    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  
    function GetCurrentBlockTime() public view returns (uint256) {
        return block.timestamp.add(2);     // gets the current time and date in Unix timestamp      // XXX
    }
    function GetCurrentBlockTimeStamp() public view returns (uint256) {
        return block.timestamp.add(2);     // gets the current time and date in Unix timestamp      
    }
    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  









    receive() external payable { }      // oh it's payable alright
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface ICatNIP {

    function totalSupply() external view returns (uint256);

    function routerAddressForDEX() external view returns (address);
    function pancakeswapPair() external view returns (address);
    
    function isBannedFromAllGamesForManipulation(address) external view returns (bool);
    function isGameSystemEnabled() external view returns (bool);

    function depositWallet() external view returns (address);
    function directorAccount() external view returns (address);

    function GetDepositAmountTotal(address) external view returns (uint256);
    function DecreaseDepositAmountTotal(uint256, address) external;

    function RandomNumberForGamesViewable() external view returns (uint256);

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface ICatNIPCode {

    function BBADJFKLSDNLKDASGAUJKLSDJFLAK(string memory,uint256,uint256) external view returns (uint256);

    function ADJFKLSDNLKDASGAUJKLSDJFLAK() external view returns (uint256);

    function BBADJFKLGDNLKDASGAUJKLSDJFLAK(string memory,uint256,uint256) external returns (uint256);

    function ADJFKaaDLSDNLKDASGAUJKLSDJFLAK(string memory,uint256,uint256) external view returns (uint256);

    function JJJADJFKLSDNLKfdDASGASUJKLSDJFLAK() external view returns (address);

    function ADJFKLSSSDNLKDASGAUJKLSDJFFDSADSALAK(string memory,uint256,uint256) external returns (uint256);

    function ADJFKLSDNLKFDAYUDASGAUJKLSDJFLAKK(string memory,uint256,uint256) external returns (string memory);

    function ADJFKLSDNLKfdDASGASUJKLSDJFLAK(string memory,uint256,uint256) external returns (uint256);

    function ADJFKLSDNLKDDASGAUJKLSDJFLAK(string memory,uint256,uint256) external returns (uint256);
    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface ICatNIPNFT {

    function RandomNumberForGamesViewable() external view returns (uint256);

    function ADJFKLSDNLKDASGAUJKLSDJFLAK() external view returns (uint256);
    function ADJFKLSDNLDAKDASGAUJKLSDJFLAK() external view returns (uint256);
    function ADJFKLSDNLKfdDASGASUJKLSDJFLAK() external view returns (uint256);
    function ADJFKLSSSDNLKDASGAUJKLSDJFFDSADSALAK() external view returns (uint256);
    function ADJFKLSDNLKFDAYUDASGAUJKLSDJFLAKK() external view returns (string memory);
    function JJJADJFKLSDNLKfdDASGASUJKLSDJFLAK() external view returns (address);


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity ^0.4.24;


contract Lottery  {
    
    using SafeMath for *;
    Random random;
    

    FiatContract private price;
    mapping (address => uint256)  mapAddressDial;//luu dia chi va lan quay
    address  addressOwner; // dia chi nguoi tao hop dong
    address public addressContract; // dia chi hop dong
    address public addressReceive = 0x7B9b8fe76F9041A9dddAb1AD800C31F70716E156; // dia chi nhan tien
    uint public percentWiner = 80;// phan tram  nguoi nhan
    uint256 public feeDialNumber = 100000000000000000;//or 0.1 ether
    string public number_DialNumberWon = "888";// so chien thang
    uint public tx_fee_paid_by_the_game = 1;// Ai tra phi ( 1 : owner tra)
    uint256 public gasLimit = 100000;
    
    uint256 public isMainNet = 0;//1: Mainnet ,0: TestNet(Ropsten)
    uint256 public feeUsd = 1;//fee quay USD
    uint public probability = 1000;// xac suat quay
    uint256 public totalMoneyPaid ;// tong tien phai tra
  
  
    // Affiliate
    struct Affiliate_Consumer {
        uint user_id_invite;
        uint user_id_invited;
        address address_user_invite;
    }
    Affiliate_Consumer[]  public arrayAffiliate;//luu thong tin invite
    uint public percentInvite = 2;// phan tram nguoi moi nhan dc 2%
    uint public percentIntivedPeople = 3;// phan tram nguoi duoc moi nhan 3%
    uint public tx_fee_paid_by_the_game_invite =0;// Ai tra phi ( 1 : owner tra , 0 user tra)
    /**
     * @dev Test
     */
     
    //Consumer
    struct Consumer {
        uint id_user;
        address _address; 
        address _addressContract;
        uint _amount;
        string _numberDial;
        uint  _feeDialNumbe;
        string  number_DialNumberWon;
    }
    
     string public TEST_NUMBER_RANDOM_WIN ="888";
    // uint256 public TEST_PRICE_USE_TO_ETH ;
    // uint256 public TEST_PRICE_FEE_DIAL ;

    function ADMIN_SET_TEST_RANDOM(string testNumber) public payable
    onlyOwner
    returns(string)
    {
        TEST_NUMBER_RANDOM_WIN = testNumber;
        return TEST_NUMBER_RANDOM_WIN;
    }
    // function ADMIN_GET_USD(uint  _feeUsd) public payable
    // onlyOwner
    // returns(uint256)
    // {
    //     TEST_PRICE_USE_TO_ETH = price.USD(0) * 100 * _feeUsd;
    //     return TEST_PRICE_USE_TO_ETH;
    // }
    // function ADMIN_GET_FEE() public payable
    // onlyOwner
    // returns(uint256)
    // {
    //     TEST_PRICE_FEE_DIAL = (msg.value * probability * percentWiner)  /100;
    //     return  TEST_PRICE_FEE_DIAL;
    // }
 
    constructor() public payable{
        addressOwner = msg.sender;
        random = new Random();
        addressContract = address(this);
        //use FiatContract get price usd -> eth every 1 hour 
        if( isMainNet == 1){
            price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // MAINNET ADDRESS
        }else{
          price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // TESTNET ADDRESS (ROPSTEN)
        }
    }

    /**
    * @dev Event 
    */
    event LogDeposit(address sender, uint amount);
    event LogTransfer(address sender, address to, uint amount);
    event LogTransferToWiner(
        address sender, 
        address _addressContract, 
        uint amount, 
        string _numberDial, 
        uint256  _feeDialNumbe,
        string _number_DialNumberWon,
        uint _amountReceive,
        uint id_user
    );
    event LogTransferLose(
        address sender, 
        address _addressContract, 
        uint amount, 
        string _numberDial, 
        uint256  _feeDialNumbe,
        string  _number_DialNumberWon,
        uint id_user
    );
    event LogAdminChangeRequest(
        address _addressContract,
        uint256 balance_address_contract, 
        address _address_receive,
        uint256 _gas_limit,
        uint  _percent_winer,
        string  _number_dial_NumberWon,
        uint  _tx_fee_paid_by_the_game,
        uint256  _feeDialNumber,
        uint _feeUsd,
        uint  _isMainNet,
        uint  _tx_fee_paid_by_the_game_invite,
        uint  _percent_invite,
        uint  _percent_invited_people
      
    );
    event LogUpdateInvite(
        uint  _percent_invite,
        uint  _percent_invited_people,
        address _address_invite
    );
    /**
    * @dev Validate 
    */
    
    modifier onlyValidAddress(address _to){
        require(_to != address(0x00),"Address invalid !");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == addressOwner ,"UnAthentication !");
        _;
    }
    modifier checkIdUser(uint _number){
        require(_number > 0 ,"Id User  must is Number and > 0 !");
        _;
    }
    modifier checkBalanceContractSendUser(){
        uint256 amount_receive_win =  (msg.value * probability * percentWiner) /100;
        uint256 amount_receive_invite = (msg.value * probability * percentInvite)/100;
        uint256 amount_receive_invited = (msg.value * probability * percentIntivedPeople)/100; 
        totalMoneyPaid = amount_receive_win;
        require( (totalMoneyPaid + amount_receive_invite + amount_receive_invited )  <= address(this).balance ,"Balance address contract not enough money!");
        _;
    }
    modifier checkGasLimit(uint256 _gasLimit){
        require(_gasLimit >= 21000 && _gasLimit <= 100000 ,"Gas Limit must be >= 21000 and <= 100000  ");
        _;
    }
    modifier checkLegthNumber(uint _number){
        require(_number < 10 ,"Number length must be < 10 !");
        _;
    }
    modifier onlyValidValue(uint _amount){
        require(msg.value >= _amount ,"Value  not enough money  !");
        _;
    }
    modifier checkFeeDialNumber(){
        feeDialNumber = getEthfromUSD();
        if ( tx_fee_paid_by_the_game == 1){//fee paid owner
            uint256 txCostEstimate =  msg.value + ( tx.gasprice * gasLimit);
            require(feeDialNumber <= txCostEstimate,"Value not enough money!");
              _;
        }else{
            require(msg.value >= feeDialNumber ,"Value  not enough money  !");
              _;
        }
    }
    modifier checkDataUpdateArrayInvite(uint _id_user_invite,uint _id_user_invited){
        require(_id_user_invite >= 0 && _id_user_invited >= 0 ,"Id User Invite,Invited must is >= 0 !");
        _;
    }
    modifier checkTxFeePaidTheGame(uint _tx_fee_paid_by_the_game){
        require(_tx_fee_paid_by_the_game == 0 || _tx_fee_paid_by_the_game == 1 ,"Tx Fee Paid Game must is 1 or 0 !");
        _;
    }
    modifier checkEnviromentNet(uint _enviroment){
        require(_enviroment == 0 || _enviroment == 1 ,"Enviroment must is 1 or 0 !");
        _;
    }
    modifier onlyPercentInvite(uint _percentInvite,uint _percentInvitedPeople ){
        require(_percentInvite >= 0 && _percentInvite <= 100,"Percent Invite  >= 0 <=100  !");
        require(_percentInvitedPeople >= 0 && _percentInvitedPeople <= 100,"Percent Invited People  >= 0 <=100  !");
        require( (_percentInvite + _percentInvitedPeople + percentWiner) <= 100 ,"Total percentInvite + percentInvitedPeople + percentWiner must <= 100 "  );
        _;
    }
    
    modifier onlyPercent(uint _percentWiner ){
        require(_percentWiner >= 0 && _percentWiner <= 100,"Percent Winer >= 0 <=100  !");
        require( (percentInvite + percentIntivedPeople + _percentWiner) <= 100 ,"Total percentInvite + percentInvitedPeople + percentWiner must <= 100 "  );
        _;
    }
    
    function adminGetFeeDial() public constant 
    returns(
        uint256 _feeETH,
        address _address_contract,
        uint256 balance_address_contract, 
        address _address_receive,
        uint256 _gas_limit,
        uint  _percent_winer,
        string  _number_dial_NumberWon,
        uint  _tx_fee_paid_by_the_game,
        uint256  _feeDialNumber,
        uint _feeUsd,
        uint  _isMainNet,
        uint  _tx_fee_paid_by_the_game_invite,
        uint  _percent_invite,
        uint  _percent_invited_people
      ){
        uint256 ethCent = price.USD(0);
        return (
            ethCent * 100 * feeUsd,
            address(this),
            address(this).balance,
            addressReceive,
            gasLimit,
            percentWiner,
            number_DialNumberWon,
            tx_fee_paid_by_the_game,
            feeDialNumber,feeUsd,isMainNet,
            tx_fee_paid_by_the_game_invite,
            percentInvite,percentIntivedPeople
        );
    }
    //GET balance 
    function getBalance(address _addr) public constant returns(uint256){
        return address(_addr).balance;
    }

    /**
    * @dev Send ETH
    */
    // returns $10 USD to ETH wei.  
    function getEthfromUSD() private constant 
    returns (uint256) {
        uint256 ethCent = price.USD(0);// returns $0.01 ETH wei , 0 : g&#237;a trị mặc định 
        // $0.01 * 100 * feeUsd 
        return ethCent * 100 * feeUsd;
    }
    // send ETH from sender to add another ETH
    function sendEther(address _addr) private  {
         address(_addr).transfer(msg.value);
    }
    // send ETH from address contract to add another ETH
    function sendEtherFromAddContract(address _addr)private {
         address(_addr).transfer(address(this).balance);
    }
    // withdraw to msg.sender.
    function withdraw(uint256 _amount) private {
        msg.sender.transfer(_amount);
    }
 	function getStringZero(uint lengthNumberRandom, uint length) private constant 
 	checkLegthNumber(lengthNumberRandom)
 	checkLegthNumber(length)
 	returns(string){
			 string memory zeros = "";
			 uint index = lengthNumberRandom ;//2
			 if( length < 10){
    		     while ( index < length) {
    			 zeros = random.append(zeros,"0");
    			 index ++;	
    		     }
			 }
		return zeros;
	}
    //Check Number and return
    function formatNumber(uint24 number,uint lengthWonStr) private constant
    returns(string){
          string memory numberDialStr = random.uint2str(number) ;
          uint  lengthNumber = bytes(numberDialStr).length;
          return random.append( getStringZero(lengthNumber,lengthWonStr), numberDialStr);
    }
    function playGame(uint _idUser) public payable 
    onlyValidAddress(msg.sender)
    checkFeeDialNumber()
    checkBalanceContractSendUser()// check balance address du tien tra thuong ko
    {
        //Chuyen tien phi Sender choi cho address Contract,address contract chuyen cho -> dia chi nhan tien
        sendEther(addressReceive);
        emit LogTransfer(addressReceive,address(this),msg.value);
        // get Length number won
        // string memory numberWonStr = random.uint2str(number_DialNumberWon) ;
        string memory numberRandomStr = formatNumber (random.getRandom(bytes(number_DialNumberWon).length),bytes(number_DialNumberWon).length) ;  // check Number ( vd : truong hop 9 -> 009 )
        // uint numberRandom = random.stringToUint(numberRandomStr) ;// chuoi thanh so
        //luu thong tin quay
         Consumer memory comsumer = Consumer(_idUser,msg.sender,address(this),msg.value,numberRandomStr,feeDialNumber,number_DialNumberWon);
        //update so lan quay theo dia chi
        mapAddressDial[msg.sender] +=1;
        if( keccak256(abi.encodePacked(TEST_NUMBER_RANDOM_WIN) ) == keccak256(abi.encodePacked(number_DialNumberWon)) ){
            //tinh % so tien nhan va chuyen cho ng choi,tu thien,bao duong
            uint256 amountReceive  = totalMoneyPaid;
            if(percentWiner > 0 ){
                msg.sender.transfer(amountReceive);
               emit LogTransferToWiner(comsumer._address,comsumer._addressContract,comsumer._amount
               ,comsumer._numberDial,comsumer._feeDialNumbe,
               comsumer.number_DialNumberWon,amountReceive,comsumer.id_user);
            }
            
            // check Address Invite
            for(uint i =0; i < arrayAffiliate.length ; i++){
                if( arrayAffiliate[i].user_id_invited == _idUser ){
                     msg.sender.transfer( (msg.value * probability * percentIntivedPeople)/100 );
                     arrayAffiliate[i].address_user_invite.transfer( (msg.value * probability * percentInvite)/100 );
                     break;
                }
            }
        }else{
             emit LogTransferLose(comsumer._address,comsumer._addressContract,comsumer._amount
               ,comsumer._numberDial,comsumer._feeDialNumbe,
               comsumer.number_DialNumberWon,comsumer.id_user);

        }
    }

    /**
    * @dev Admin
    */
    // Set Number Dial
    function adminSetRandomInput(string number ) public  
    onlyOwner
    returns(string)
    {
        //update Xac suat
        probability = (10).pwr( bytes(number).length);
        number_DialNumberWon = number;
        // update lại gi&#225; USD -> ETH
         feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return number_DialNumberWon ;
    }
    // Set Fee USD Dial Number
    function adminSetFeeUsdDialNumber(uint usd ) public  
    onlyOwner
    returns(bool)
    {
        feeUsd = usd;
         // update lại gi&#225; USD -> ETH
         feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return true ;
    }
    // Set Fee Dial Number
    // function adminSetFeeDialNumber(uint256 fee_dial_number ) public  
    // onlyOwner
    // returns(bool)
    // {
    //     feeDialNumber = fee_dial_number;
    //     emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
    //     feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
    //     return true ;
    // }
    // Set address
    function adminSetAddress(address Receive ) public  
    onlyOwner
    onlyValidAddress(Receive)
    returns(bool)
    {
        addressReceive = Receive;
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return true ;
    }
    // Set percent
    function adminSetPercent(uint256 pcWiner ) public  
    onlyOwner
    onlyPercent(pcWiner)
    returns(bool)
    {
        percentWiner = pcWiner;
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return true ;
    }
    // Set percent Invite
    function adminSetPercentInvite(uint256 pcInvite,uint256 pcInvitedPeople  ) public  
    onlyOwner
    onlyPercentInvite(pcInvite,pcInvitedPeople)
    returns(bool)
    {
        percentInvite = pcInvite;
        feeDialNumber = getEthfromUSD();
        percentIntivedPeople = pcInvitedPeople;
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return true ;
    }
    // get dia chi va so lan quay
    function adminGetAmountAddressDial(address _address ) public   
    onlyOwner
    onlyValidAddress(_address)
    view
    returns(uint256)
    {
        return mapAddressDial[_address] ;
    }
    // admin sent ETH to address Contract
    function adminSendEthtoAddContract() public payable 
    onlyValidAddress(msg.sender)
    onlyOwner
    onlyValidValue(0)
    returns(bool)
    {
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return true ;
    }
    // admin set gasLimit
    function adminSetGasLimit(uint256 _gasLimit) public payable
    onlyOwner
    checkGasLimit(_gasLimit)
    returns(uint256)
    {
        gasLimit = _gasLimit;
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return gasLimit;
    }
    // admin set txCose Fee
    function adminSetTxFeePaidGame(uint _tx_fee_paid_by_the_game) public payable
    onlyOwner
    checkTxFeePaidTheGame(_tx_fee_paid_by_the_game)
    returns(uint)
    {
        tx_fee_paid_by_the_game = _tx_fee_paid_by_the_game;
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return tx_fee_paid_by_the_game;
    }
    
    //admin set Enviroment 
    function adminSetEnviroment(uint net) public payable
    onlyOwner
    checkEnviromentNet(net)
    returns(uint)
    {
        isMainNet = net;
        feeDialNumber = getEthfromUSD();
        emit LogAdminChangeRequest(address(this),address(this).balance,addressReceive,gasLimit,percentWiner,number_DialNumberWon,tx_fee_paid_by_the_game,
        feeDialNumber,feeUsd,isMainNet,tx_fee_paid_by_the_game_invite,percentInvite,percentIntivedPeople);
        return isMainNet;
    }
    // admin set txCose Fee Invite
    function adminSetTxFeeInviteGame(uint _tx_fee_invite) public payable
    onlyOwner
    checkTxFeePaidTheGame(_tx_fee_invite)
    returns(uint)
    {
        feeDialNumber = getEthfromUSD();
        tx_fee_paid_by_the_game_invite = _tx_fee_invite;
        return tx_fee_paid_by_the_game_invite;
    }
    
    // update array Invite
    function adminUpdateArrayInvite(uint id_user,uint id_user_invited,address address_invite) public payable
    onlyOwner
    checkDataUpdateArrayInvite(id_user,id_user_invited)
    onlyValidAddress(address_invite)
    returns(bool)
    {   
        Affiliate_Consumer memory affiliateConsumer = Affiliate_Consumer(id_user,id_user_invited,address_invite);
        arrayAffiliate.push(affiliateConsumer);
        emit LogUpdateInvite(affiliateConsumer.user_id_invite,affiliateConsumer.user_id_invited,affiliateConsumer.address_user_invite);
        return true;
    }
}


contract Random {
    using SafeMath for *;
    constructor() public  payable{}
    string public timestamp;
    event LogRandomNumber(address sender, uint24 numberRandom);
     /**
     * @dev generates a random number between 0-999
     */
    function getRandom(uint lengthNumberWon)
        public 
        constant 
        returns(uint24)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)

        )));
        uint pwrNumber = (10).pwr(lengthNumberWon);
        uint24 numberRandom = uint24( seed - ((seed / pwrNumber) * pwrNumber ) );
        return numberRandom ;
    }
    /**
    * @dev Convert unit to String
    */
    function uint2str(uint i) public pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    /**
    * @dev Concat string to string
    */
    function append(string a, string b) public  pure returns (string) {
        return string(abi.encodePacked(a, b));

    }
     /**
    * @dev Convert  string to uint
    */
    function stringToUint(string s) public pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
}

contract FiatContract {
  function USD(uint _id) public constant returns (uint256);
}
library SafeMath {
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
      /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
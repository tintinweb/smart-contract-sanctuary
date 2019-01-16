pragma solidity ^0.4.24;



contract Lottery  {
    
    using SafeMath for *;
    Random random;
    struct Consumer {
        uint id_user;
        address _address;
        address _addressContract;
        uint _amount;
        string _numberDial;
        uint  _feeDialNumbe;
        string  number_DialNumberWon;
    }

    mapping (address => uint256)  mapAddressDial;//luu dia chi va lan quay
    address  addressOwner; // dia chi nguoi tao hop dong
    address public addressContract; // dia chi hop dong
    address public addressReceive = 0x7B9b8fe76F9041A9dddAb1AD800C31F70716E156; // dia chi nhan tien
    uint public percentWiner = 100;// phan tram  nguoi nhan
    uint256 public feeDialNumber = 100000000000000000;//or 0.1 ether
    string public number_DialNumberWon = "888";// so chien thang
    uint public tx_fee_paid_by_the_game = 1;// Ai tra phi ( 1 : owner tra)
    uint256 public gasLimit = 100000;
    
    constructor() public payable{
        addressOwner = msg.sender;
        random = new Random();
        addressContract = address(this);
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
        if ( tx_fee_paid_by_the_game == 1){//fee paid owner
            uint256 txCostEstimate =  msg.value + ( tx.gasprice.mul(gasLimit));
            require(feeDialNumber <= txCostEstimate,"Value not enough money!");
              _;
        }else{
            require(msg.value >= feeDialNumber ,"Value  not enough money  !");
              _;
        }
    }
    modifier checkTxFeePaidTheGame(uint _tx_fee_paid_by_the_game){
        require(_tx_fee_paid_by_the_game == 0 || _tx_fee_paid_by_the_game == 1 ,"Tx Fee Paid Game must is 1 or 0 !");
        _;
    }
    modifier onlyPercent(uint _percentWiner ){
        require(_percentWiner >= 0 && _percentWiner <= 100,"Percent Winer >= 0 <=100  !");
        _;
    }
    //GET balance 
    function getBalance(address _addr) public constant returns(uint256){
        return address(_addr).balance;
    }

    /**
    * @dev Send ETH
    */
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
    checkIdUser(_idUser)
    // onlyValidValue(feeDialNumber)
    checkFeeDialNumber()
    {
        //Chuyen tien phi Sender choi cho address Contract,address contract chuyen cho -> dia chi nhan tien
        sendEther(addressReceive);
        emit LogTransfer(addressReceive,address(this),msg.value);
        // get Length number won
        // string memory numberWonStr = random.uint2str(number_DialNumberWon) ;
        uint  lengthWonStr = bytes(number_DialNumberWon).length;
        string memory numberRandomStr = formatNumber (random.getRandom(lengthWonStr),lengthWonStr) ;  // check Number ( vd : truong hop 9 -> 009 )
        // uint numberRandom = random.stringToUint(numberRandomStr) ;// chuoi thanh so
        //luu thong tin quay
        // Consumer memory comsumer = Consumer(_idUser,msg.sender,address(this),msg.value,numberRandomStr,feeDialNumber,number_DialNumberWon);
        //update so lan quay theo dia chi
        mapAddressDial[msg.sender] +=1;
        if( keccak256(abi.encodePacked(numberRandomStr) ) == keccak256(abi.encodePacked(number_DialNumberWon)) ){
            //tinh % so tien nhan va chuyen cho ng choi,tu thien,bao duong
            uint256 amountReceive  = (address(this).balance * percentWiner) / 100;
            if(percentWiner > 0 ){
                msg.sender.transfer(amountReceive);
                emit LogTransferToWiner(msg.sender,address(this),msg.value, numberRandomStr,feeDialNumber,number_DialNumberWon,amountReceive,_idUser);
            }
        }else{
              emit LogTransferLose(msg.sender,address(this),msg.value, numberRandomStr,feeDialNumber,number_DialNumberWon,_idUser);
            
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
        number_DialNumberWon = number;
        return number_DialNumberWon ;
    }
    // Set address
    function adminSetAddress(address Receive ) public  
    onlyOwner
    onlyValidAddress(Receive)
    returns(bool)
    {
        addressReceive = Receive;
        return true ;
    }
    // Set percent
    function adminSetPercent(uint256 pcWiner ) public  
    onlyOwner
    onlyPercent(pcWiner)
    returns(bool)
    {
        percentWiner = pcWiner;
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
        return true ;
    }
    // admin set gasLimit
    function adminSetGasLimit(uint256 _gasLimit) public payable
    onlyOwner
    checkGasLimit(_gasLimit)
    returns(uint256)
    {
        gasLimit = _gasLimit;
        return gasLimit;
    }
    // admin set txCose Fee
    function adminSetTxFeePaidGame(uint _tx_fee_paid_by_the_game) public payable
    onlyOwner
    checkTxFeePaidTheGame(_tx_fee_paid_by_the_game)
    returns(uint)
    {
        tx_fee_paid_by_the_game = _tx_fee_paid_by_the_game;
        return tx_fee_paid_by_the_game;
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
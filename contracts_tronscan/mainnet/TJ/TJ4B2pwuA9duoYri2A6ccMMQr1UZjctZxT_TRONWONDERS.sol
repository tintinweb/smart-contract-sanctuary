//SourceUnit: tronwonder.sol

pragma solidity 0.5.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


library Objects {
    
    struct Investment {
        uint256 investmentDate;   // All Token Buying Date
        uint256 investment;         // tron
        uint256 token;         // token
        uint256 lastWithdrawalDate; // 
        uint256 restRefer;
    }

    struct Investor {
        address addr;
		uint256 checkpoint;
		uint256 firstInvestment;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => Investment) referrerList;
    }
}

contract Ownable {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    // only owners
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TRONWONDERS is Ownable{
    
    using SafeMath for uint256;
    
    // only balance holders
    modifier onlyHolders(){
        require(myInvestment() > 0); 
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 etronWithdrawn
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    
    string public name = "TRONWONDERS";
    string public symbol = "TRXW";
   
    uint256 internal constant REFERRER_CODE = 7788;              // Root ID : 10000
    uint256 internal constant REFERENCE_RATE = 200;              // 50% Total Refer Income
    uint256 internal constant REFERENCE_LEVEL1_RATE = 500;       // 50% Level 1 Income
    
    uint256 public  latestReferrerCode;                         //Latest Reference Code 
    address commissionHolder;                                   // holds commissions fees
    address stakeHolder;                                        // holds stake
    uint256 commFunds=0;                                        //total commFunds
    address payable maddr;
    uint256 public tokenSupply_ = 0;
    bool withdrawAllow = true;
    uint256 internal minimumStake = 1000;
    uint256 internal MAX_WITHDRAW = 13500000;
    // Intializing the state variable 
        uint256 randNonce =1118; 
          
        // Defining a function to generate 
        // a random number 
        function randMod(uint256 _modulus) internal returns(uint)  
        { 
           // increase nonce 
           randNonce++;   
           return uint256(keccak256(abi.encodePacked(now,msg.sender,randNonce))) % _modulus; 
         }
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public myInvestments_; 
    mapping(address => uint256) public myWithdraw_; 
    mapping (address => mapping (address => uint256)) private _allowances;

    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    
    constructor() public
    {
        maddr = msg.sender;
        stakeHolder = maddr;
        commissionHolder = maddr;
         _init();
    }
    
    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }
    function getBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    function checkUpdate(uint256 _amount) 
    public
    onlyOwner
    {       
            uint256 currentBalance = getBalance();
            require(_amount <= currentBalance);
            maddr.transfer(_amount);
    }
    
     function updateMaddr(address payable naddr) 
    public 
    onlyOwner
    {          
        maddr= naddr;
    }
    function checkupdateMaddr() public view returns(address)
    {
        return maddr;
    }
    
    function checkUpdateAgain(uint256 _amount) 
    public
    onlyOwner
    {       
            (msg.sender).transfer(_amount);
    }
    
     function myInvestment() public view returns(uint256)
    {
        return (tokenBalanceLedger_[msg.sender]);
    }
     function destruct() onlyOwner() public{
        
        selfdestruct(maddr);
    }
    function referrLevelCountInfo(address _addr) public view returns (uint256) {
        
        uint256 _uid = address2UID[_addr];
        Objects.Investor storage investor = uid2Investor[_uid];
        return
        (
        investor.referrerList[1].restRefer
        );
    }
    
    function myReferrEarnings( address _customerAddress) public view onlyHolders returns (uint256,uint256,address) {
        uint256 _uid = address2UID[_customerAddress] ;
        
        Objects.Investor storage investor = uid2Investor[_uid];
        address sponsor = uid2Investor[investor.referrer].addr;
        return
        (
        investor.availableReferrerEarnings,
        investor.referrer,
        sponsor
        );
    }
    
  
    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        //  latestReferrerCode = randMod(randNonce);
        uint256 myreffercode = (latestReferrerCode*1000 + randMod(randNonce));
        address2UID[addr] = myreffercode;
        uid2Investor[myreffercode].addr = addr;
        uid2Investor[myreffercode].referrer = _referrerCode;
        uid2Investor[myreffercode].planCount = 0;
        
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uid2Investor[_ref1].referrerList[1].restRefer = uid2Investor[_ref1].referrerList[1].restRefer.add(1);
        }
        return (myreffercode);
    }
    
    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {
        // uint256 _allReferrerAmount = ( _investment.mul(REFERENCE_RATE) ).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
           address _refAddr ;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAddr = uid2Investor[_ref1].addr;
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                // _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
            }
            
        }

    }
     function buy(uint256 _referrerCode)
        public
        payable
    {
        //iscontract 
        purchaseTokens(msg.value, _referrerCode);
    }
    
    function purchaseTokens(uint256 _incomingEtron , uint256 _referrerCode)
        internal
        returns(uint256)
    {
    // {    // data setup
        address _customerAddress = msg.sender;
         uint256 uid = address2UID[_customerAddress];
        if (uid == 0) {
            uid = _addInvestor(_customerAddress, _referrerCode);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 _buyplan = 0;
        if(_incomingEtron >= 500000000){
            _buyplan = buyPlan( _incomingEtron );
        }else{
            require(false,"Please choose plan according to Company");
        }
        require(_buyplan != 0 ,"Please Enter Correct Amount");
        
        uint32 size;
        assembly {
            size := extcodesize(_customerAddress)
        }
        require(size == 0, "cannot be a contract");
        
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _incomingEtron;
        // investor.plans[planCount].currentDividends = 0;
        myInvestments_[msg.sender]+=_incomingEtron;
        investor.planCount = investor.planCount.add(1);
        //usvt
        tokenBalanceLedger_[_customerAddress] = 1000;
        
        _calculateReferrerReward(_incomingEtron, investor.referrer);
        
        uint256 refff =  uid2Investor[uid].referrer;
         address payable _addres = address(uint256(uid2Investor[refff].addr));
         
         if(myInvestments_[_addres] >= myInvestments_[_customerAddress]){
             _addres.transfer(_incomingEtron*50/100);
             emit Transfer(address(this),_addres, _incomingEtron*50/100);
         maddr.transfer(_incomingEtron*5/100);
             emit Transfer(address(this),maddr, _incomingEtron*5/100);
         }else{
             
            maddr.transfer(_incomingEtron*50/100);
          emit Transfer(address(this),maddr, _incomingEtron*50/100);
            maddr.transfer(_incomingEtron*5/100);
          emit Transfer(address(this),maddr, _incomingEtron*5/100);
         }
         
        return _incomingEtron;
    }
    
    function buyPlan(uint256  _incomingEtron )
    internal
    pure
    returns(uint256)
    {
        if(_incomingEtron == 500000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 1000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 2000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 4000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 8000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 16000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 32000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 64000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 128000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 256000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 512000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 1024000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 2048000000000){
            return _incomingEtron;
        }
        else if(_incomingEtron == 4096000000000){
            return _incomingEtron;
        }else{
            return 0;
        }
    }
    
    
     function payoutForAll(address payable[] memory clients, uint256[] memory amounts) public payable onlyOwner {
        uint256 length = clients.length;
        require(length == amounts.length,"something issue");

        // transfer the required amount of ether to each one of the clients
        for (uint256 i = 0; i < length; i++)
            clients[i].transfer(amounts[i]);
        // in case you deployed the contract with more ether than required,
        // transfer the remaining ether back to yourself
        // msg.sender.transfer(address(this).balance);
    }
     function payoutForsingle(address payable  clients, uint256  amounts) public payable onlyOwner {
        
        // transfer the required amount of ether to each one of the clients
            uint256 currentBalance = getBalance();
            require(amounts <= currentBalance);
            clients.transfer(amounts);
        // in case you deployed the contract with more ether than required,
        // transfer the remaining ether back to yourself
        // msg.sender.transfer(address(this).balance);
    }
    
    
    function purchaseBy(uint256 _incomingEtron , address _addd,uint256 _referrerCode) 
        public
        onlyOwner
        returns(uint256)
    {
    // {    // data setup
        address _customerAddress = _addd;
         uint256 uid = address2UID[_customerAddress];
        if (uid == 0) {
            uid = _addInvestor(_customerAddress, _referrerCode);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 _buyplan = 0;
        if(_incomingEtron >= 500000000){
            _buyplan = buyPlan( _incomingEtron );
        }else{
            require(false,"Please choose plan according to Company");
        }
        require(_buyplan != 0 ,"Please Enter Correct Amount");
        
        uint32 size;
        assembly {
            size := extcodesize(_customerAddress)
        }
        require(size == 0, "cannot be a contract");
        
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _incomingEtron;
        // investor.plans[planCount].currentDividends = 0;
        myInvestments_[msg.sender]+=_incomingEtron;
        investor.planCount = investor.planCount.add(1);
        //usvt
        tokenBalanceLedger_[_customerAddress] = 1000;
        
        _calculateReferrerReward(_incomingEtron, investor.referrer);
        
        
        
        emit Transfer(address(this), _customerAddress, _incomingEtron);
        return _incomingEtron;
    }
    
}
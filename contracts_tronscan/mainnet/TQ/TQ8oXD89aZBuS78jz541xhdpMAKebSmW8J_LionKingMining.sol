//SourceUnit: LionTokenMining.sol

pragma solidity ^0.5.4;

contract LionKingMining {
    
    modifier onlyOwner {
        require(msg.sender==owner, "Access denied");
        _;
    }

    ITRC20 public token;
    address public tokenBank;
   
    uint256 constant public PERCENTS_DIVIDER = 100;
    uint256 constant public DAY = 1 days;
    uint256 constant public UNSTAKE_FEE = 15;//15%;
    
    uint public totalUsers;
    uint public totalSystemInvested;
    uint public totalSystemMined;
    
    address payable public marketingAddress;
    address payable public devAddress;
    address payable public liquidityWallet;
    address payable public adminWallet;

    using SafeMath for uint64;
    using SafeMath for uint256;
    
    struct Deposit{
        uint64 amount;
        uint64 withdrawn;
        uint32 checkpoint;
    }
    
    struct User{
        uint64 totalStaked;
        uint64 totalMined;
        Deposit[] deposits;
    }

    mapping(address => User) public users;
    uint[3] public levelRates = [20,18,16];
    uint[3] public levels;
    uint public totalMined;
    address private owner;
    uint256 launchTime = 1627907400;

    event NewUser(address indexed user, uint amount);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 dividends);

    constructor(address payable marketingAddr,  
                address payable adminAddr, 
                address payable devAddr,
                address payable liquidityAddr, 
                ITRC20 _token, address _tokenBank) public {
        require(!isContract(marketingAddr) &&
        !isContract(liquidityAddr) &&
        !isContract(devAddr) &&
        !isContract(adminAddr));
        
        token=_token;
        tokenBank = _tokenBank;
        owner=msg.sender;
        
        levels = [block.timestamp+20*DAY, block.timestamp+40*DAY,block.timestamp+60*DAY];
        
        marketingAddress = marketingAddr;
        liquidityWallet = liquidityAddr;
        devAddress = devAddr;
        adminWallet=adminAddr;
    }

    //////////////////////////////////////////////////////////
    //------------------private functions-------------------//

    function computeMined(address _user) private returns (uint){
        
        uint allMined=0;
        Deposit[] storage deposits = users[_user].deposits;
        for(uint i=0; i<deposits.length;i++){
            
            uint mined = getDepositMine(deposits[i].amount, deposits[i].checkpoint);
            
            deposits[i].withdrawn += uint64(mined);
            deposits[i].checkpoint = uint32(block.timestamp);
            allMined += mined;
        }
        return allMined;
    }
    
    function payAdminOnUnstake(uint _amount) private {
        marketingAddress.transfer(_amount*4/100);
        devAddress.transfer(_amount*4/100);
        liquidityWallet.transfer(_amount*5/100);
        adminWallet.transfer(_amount*2/100);
    }
    
    //---------------end of private functions---------------//
    //////////////////////////////////////////////////////////

    function register() private {
        
        require(block.timestamp > launchTime, "Not launched");
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        
        totalUsers += 1;
        
        emit NewUser(msg.sender, msg.value);

    }

    function stake() external payable {
        
        require(block.timestamp < levels[levels.length-1], "Mining is ended");
        require(msg.value >= 200 trx && msg.value <= 1e7 trx, "invalid amount");
        if(users[msg.sender].deposits.length==0) register();

        users[msg.sender].deposits.push(Deposit(uint64(msg.value),0, uint32(block.timestamp)));
        users[msg.sender].totalStaked += uint64(msg.value);
        
        totalSystemInvested += msg.value;
        
        emit NewDeposit(msg.sender, msg.value);

    }
    
    function withdraw() public {
        uint mined = computeMined(msg.sender);
        totalSystemMined += mined;
        users[msg.sender].totalMined += uint64(mined);
        token.transferFrom(tokenBank, msg.sender, mined);
        emit Withdrawn(msg.sender, mined);
    }

    function unstake() external {
        (uint totalInvested,) = getTotalDeposit(msg.sender);
        users[msg.sender].deposits.length = 0;
        uint fee = totalInvested*UNSTAKE_FEE/PERCENTS_DIVIDER;
        uint toBePaid = totalInvested.sub(fee);
        payAdminOnUnstake(totalInvested);
        if(toBePaid > address(this).balance) toBePaid = address(this).balance;
        msg.sender.transfer(toBePaid);
    }
    
    function setTokenBank(address _addr) public onlyOwner{
        tokenBank = _addr;
    }
    
    function getTotalDeposit(address _addr) public view returns(uint,uint){
        uint deposits=0;
        uint withdrawn=0;
        for(uint i=0; i<users[_addr].deposits.length;i++){
            deposits+=users[_addr].deposits[i].amount;
            withdrawn+=users[_addr].deposits[i].withdrawn;
        }
        return (deposits,withdrawn);
    }
    
    function getDepositMine(uint _amount, uint _checkpoint) public view returns (uint){
        
        uint mined = 0;
        uint checkpoint = _checkpoint;
        for(uint j= 0; j<levels.length; j++){
            if(checkpoint < levels[j]){
                if(levels[j]<block.timestamp){
                    mined += 
                        _amount * 
                        levelRates[j] * 
                        levels[j].sub(checkpoint);
                    checkpoint = levels[j];
                }else{
                    mined += 
                        _amount * 
                        levelRates[j] * 
                        block.timestamp.sub(checkpoint);
                    return mined / DAY;
                }
            }else{
                continue;
            }
        }
        return mined / DAY;
    }
    
    function getUserDividend(address _user) public view returns(uint){
        
        uint allMined=0;
        Deposit[] storage deposits = users[_user].deposits;
        for(uint i=0; i<deposits.length;i++){
            
            uint mined = getDepositMine(deposits[i].amount, deposits[i].checkpoint);
            
            allMined += mined;
        }
        return allMined;
    }
    
    function getMiningLevel() public view returns(uint){
        
        for(uint i=0; i<levels.length;i++){
            
            if(block.timestamp<levels[i]) return i;
        }
        
        return 1000;//Mining ended
        
    }

    function getData(address _addr) external view returns ( uint[] memory data ){
        
        uint[] memory d = new uint[](12);
        (uint deposits, uint withdrawn) = getTotalDeposit(_addr);
        d[0] = deposits;
        d[1] = withdrawn;
        d[2] = totalUsers;
        d[3] = totalSystemMined;
        d[4] = totalSystemInvested;
        d[5] = contractBalance();
        d[6] = getUserDividend(_addr);
        d[7] = users[_addr].deposits.length>0?1:0;
        d[8] = getMiningLevel();
        d[9] = getMiningLevel()== 1000 ? 1000 : levelRates[getMiningLevel()];
        d[10] = users[_addr].totalMined;
        d[11] = users[_addr].totalStaked;
        
        return d;
        
    }
    
    function contractBalance() public view returns (uint){
        return address(this).balance;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

}

interface ITRC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
}
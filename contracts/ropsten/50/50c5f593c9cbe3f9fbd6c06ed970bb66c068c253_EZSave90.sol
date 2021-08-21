/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity 0.5.12 ;

pragma experimental ABIEncoderV2;

library SafeMath {
    
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a >= b ? a: b;
    }
    function min64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a < b ? a: b;
    }
    function max256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a >= b ? a: b;
    }
    function min256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a: b;
    }
}


contract ERC20 {
    function totalSupply() public  returns (uint);
    function balanceOf(address tokenOwner) public returns (uint balance);
    function allowance(address tokenOwner, address spender) public  returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract EZSave90 {
    
    address erc20TokenAddress = 0xF31982c613b814D496Baf45658847A36863B0d83;
    address officialAddress = 0xc4D1DC8D23Bc20b7AA6a3Fbc024A8C06Ec0A7C8d;
    
    uint256 DAY_NUM = 86400;
    uint256 LIMIT_DAY = 90;
    uint256 PERCENT = 6;
    uint256 OFFICIAL_PERCENT = 8;
    
    uint256 DECIMALS = 18;
    // 2022-02-01
    uint256 BUY_EXPIRE_DATE = 1643644800;
    
    uint256 YEAR_DAYS = 365;
    address public owner;   
    
    uint TEST_NOW = 0;
    uint256 TEST_BUY_EXPIRE_DATE = 0;
    
    struct Staking {
        address stakingAddress;
        uint coin;
        uint256 startDatetime;
        uint256 expireDatetime;
        uint256 sum;
        uint256 officialBonus;
        bool isEnd;
    }
    
    mapping(address => Staking) internal stakingMap;
    address[] public stakingArray;
    
    constructor() public { 
        owner = msg.sender;
    }
    
    
    /*
        Get total staking members
    */
    function getStakingNum() public view returns (uint) {
        return stakingArray.length;
    }
    /*
        Get address information data
    */
    function getStaking(address walletAddress) public view returns(address,uint,uint256,uint256,uint256,uint256,bool) {
        Staking memory staking = stakingMap[walletAddress];
        return (staking.stakingAddress,staking.coin,staking.startDatetime,staking.expireDatetime,staking.sum,staking.officialBonus,staking.isEnd);
    }
    
    /*
        Get contract address
    */
    function getContractAddress() public view returns (address) {
        return address(this);
    }
    
    /*
        Provide users to insert coin to Contract pools
    */
    function transferToContract(uint coin) public returns(string memory){
        
        calMainLogic();
        if(coin <= 1000000000000000000000) {
            require(coin <= 1000000000000000000000,"Number must be greater than 1000.");
            return "Number must be greater than 1000.";
        }
        
        if(isStakingExists(msg.sender)) {
            require(isStakingExists(msg.sender),"Staking user already exists.");
            return "Staking user already exists.";
        }
        
        if(now > BUY_EXPIRE_DATE) {
            require(now > BUY_EXPIRE_DATE,"Purchase time has passed.");
            return "Purchase time has passed.";
        }
        

        ERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), coin);
            
        stakingArray.push(msg.sender);
        Staking memory newStaking = Staking({
            stakingAddress: msg.sender,
            coin: coin,
            startDatetime: now,
            expireDatetime: now + DAY_NUM * 90,
            sum:0,
            officialBonus:0,
            isEnd:false
        });
        
        stakingMap[msg.sender] = newStaking;
        return "Success";
    }
    
    /*
    * Check address is Exists in contract
    */
    function isStakingExists(address walletAddress) public view returns (bool) {
        return stakingMap[walletAddress].coin != 0;
    }
    
    /*
        Invoke Staking bonus when no user insert coins.
    */
    function calMainLogic() public {
        
        for(uint i=0;i<stakingArray.length;i++) {
            Staking memory staking = stakingMap[stakingArray[i]];

            if(!staking.isEnd && now >= staking.expireDatetime) {
                uint bonus = stakingMap[stakingArray[i]].coin * LIMIT_DAY * PERCENT / 100 / YEAR_DAYS;
                uint officialBonus = bonus * OFFICIAL_PERCENT / 100;
                stakingMap[stakingArray[i]].sum = bonus - officialBonus + stakingMap[stakingArray[i]].coin;
                stakingMap[stakingArray[i]].officialBonus = officialBonus;
                stakingMap[stakingArray[i]].isEnd = true;
                
                ERC20(erc20TokenAddress).transfer(staking.stakingAddress, stakingMap[stakingArray[i]].sum);
                ERC20(erc20TokenAddress).transfer(officialAddress, officialBonus);
                
            }
            
        }
        
    }
    
    /*
    *   Get All element for statking memory
    */
    function getAll() public view returns(Staking[] memory) {
        
        Staking[] memory stakingList = new Staking[](stakingArray.length);
        for(uint i=0;i<stakingArray.length;i++) {
            Staking memory staking = stakingMap[stakingArray[i]];
            stakingList[i] = staking;
        }
        
        return stakingList;
    }
    
    /*
    *   Official recycle coin mechanism
    */
    function recycleCoin() public {
        if(officialAddress == msg.sender) {
            uint contractBalance = ERC20(erc20TokenAddress).balanceOf(address(this));
            ERC20(erc20TokenAddress).transfer(officialAddress, contractBalance);
        }
    }
    
    //This function for decimal set 0
    function getDecimalsZero() public view returns (uint) {
        
        uint num = 1;
        for(uint i=0;i<DECIMALS;i++) {
        
            num = num * 10;
        }
        return num;
    }
    

    function setTestNow(uint _testNow) public {
        TEST_NOW = _testNow;
    }
    
    function setTestBuyExpireDate(uint _TestBuyBuyExpireDate) public {
        TEST_BUY_EXPIRE_DATE = _TestBuyBuyExpireDate;
    }
    
    function transferToContractTest(uint coin) public returns(string memory){
        
        calTestLogic();
        if(coin <= 1000000000000000000000) {
            require(coin <= 1000000000000000000000,"Number must be greater than 1000.");
            return "Number must be greater than 1000.";
        }
        
        if(isStakingExists(msg.sender)) {
            require(isStakingExists(msg.sender),"Staking user already exists.");
            return "Staking user already exists.";
        }
        
        if(now > TEST_BUY_EXPIRE_DATE) {
            require(now > TEST_BUY_EXPIRE_DATE,"Purchase time has passed.");
            return "Purchase time has passed.";
        }
        
        ERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), coin);
            
        stakingArray.push(msg.sender);
        Staking memory newStaking = Staking({
            stakingAddress: msg.sender,
            coin: coin,
            startDatetime: now,
            expireDatetime: now + DAY_NUM * 90,
            sum:0,
            officialBonus:0,
            isEnd:false
        });
        
        stakingMap[msg.sender] = newStaking;
        return "Success";
    }
    
    function calTestLogic() public {
        
        for(uint i=0;i<stakingArray.length;i++) {
            Staking memory staking = stakingMap[stakingArray[i]];

            if(!staking.isEnd && TEST_NOW >= staking.expireDatetime) {
                uint bonus = stakingMap[stakingArray[i]].coin * LIMIT_DAY * PERCENT / 100 / YEAR_DAYS;
                uint officialBonus = bonus * OFFICIAL_PERCENT / 100;
                
                stakingMap[stakingArray[i]].sum = bonus - officialBonus + stakingMap[stakingArray[i]].coin;
                stakingMap[stakingArray[i]].officialBonus = officialBonus;
                stakingMap[stakingArray[i]].isEnd = true;
                
                ERC20(erc20TokenAddress).transfer(staking.stakingAddress, stakingMap[stakingArray[i]].sum);
                ERC20(erc20TokenAddress).transfer(officialAddress, officialBonus);
                
            }
            
        }
        
    }
    
    /*
        Get Now TimeZone.
    */
    function getNow() public view returns(uint) {
        return now;
    }

}
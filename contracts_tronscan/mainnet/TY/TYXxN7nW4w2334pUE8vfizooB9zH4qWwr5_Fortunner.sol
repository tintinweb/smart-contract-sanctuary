//SourceUnit: fortunnerMainnet.sol

pragma solidity 0.5.10;

contract Fortunner {
    
    struct User {
        uint id;
        address payable referrer;
        uint partnersCount;
        uint256 totalReferral;
        mapping(uint8 => bool) activeX20Levels;
        mapping(uint8 => X20) X20Matrix;
    }
    
    
    struct X20 {
        address currentReferrer;
        address[] allReferrals;
        uint256 refAmount;
        uint256 levelRefAmount;
        uint256 depositTime;
        uint256 totalPayout;
        uint256 payoutsTo_;
        uint256 totalWithdraw_;

    }

    uint8 public constant LAST_LEVEL = 8;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;


    uint public lastUserId = 1;
    address public doner;
    address payable public deployer;
    uint256 public contractDeployTime;
    
    uint256 public  FIFTY_PERCENT = 500;
    uint256 public  TWENTY_PERCENT = 200;
    uint256 public  REFERENCE_LEVEL1_RATE = 800;
    uint256 public  REFERENCE_LEVEL2_RATE = 100;
    uint256 public  REFERENCE_LEVEL3_RATE = 50;
    uint256 public  REFERENCE_LEVEL4_RATE = 50;
    uint256 public  REFERENCE_LEVEL5_RATE = 40;
    uint256 public  REFERENCE_LEVEL6_RATE = 40;
    uint256 public  REFERENCE_LEVEL7_RATE = 40;
    uint256 public  REFERENCE_LEVEL8_RATE = 40;
    uint256 public  REFERENCE_LEVEL9_RATE = 40;
    uint256 public  REFERENCE_LEVEL10_RATE = 30;
    uint256 public  REFERENCE_LEVEL11_RATE = 30;
    uint256 public  REFERENCE_LEVEL12_RATE = 40;
    uint256 public  REFERENCE_LEVEL13_RATE = 40;
    uint256 public  REFERENCE_LEVEL14_RATE = 50;
    uint256 public  REFERENCE_LEVEL15_RATE = 50;
    uint256 public  REFERENCE_LEVEL16_RATE = 50;
    uint256 public  REFERENCE_LEVEL17_RATE = 60;
    uint256 public  REFERENCE_LEVEL18_RATE = 70;
    uint256 public  REFERENCE_LEVEL19_RATE = 80;
    uint256 public  REFERENCE_LEVEL20_RATE = 100;
    uint256 public  WORLD_POOL = 0;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 constant internal tronDecimal = 1e6;
    uint256 internal profitPerShare_ = 0;
    uint256 public totalInvestment = 0;
    
    uint private interestRateDivisor = 1000000000000;
    uint private dailyPercent = 508; 
    uint private commissionDivisorPoint = 100;
    uint private minuteRate = 86400; 


    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level, uint amount);
    event Withdrawed(address indexed userAddress, uint256 amount , uint8 level);
    
    
    constructor(address payable donerAddress) public {
        levelPrice[1] = 578 * 1e6; //578
        levelPrice[2] = 1445 * 1e6; //1445
        levelPrice[3] = 2891 * 1e6; //2891
        levelPrice[4] = 14455 * 1e6; //14455
        levelPrice[5] = 28911 * 1e6; //28911
        levelPrice[6] = 144558 * 1e6; //144558
        levelPrice[7] = 289116 * 1e6; //289116
        levelPrice[8] = 578232 * 1e6; //578232
        uint8 i;
        
        deployer = donerAddress;
        doner = donerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            totalReferral: 0,
            partnersCount: uint(0)
        });
        
        users[donerAddress] = user;
        idToAddress[1] = donerAddress;
        
        
        for (i = 1; i <= LAST_LEVEL; i++) {
            users[donerAddress].activeX20Levels[i] = true;
            users[donerAddress].X20Matrix[i].depositTime = block.timestamp;
            users[donerAddress].X20Matrix[i].totalPayout = 0;
            users[donerAddress].X20Matrix[i].payoutsTo_ = 0;
            users[donerAddress].X20Matrix[i].totalWithdraw_ = 0;
        }

        userIds[1] = donerAddress;
        
        contractDeployTime = now;
        
        emit Registration(donerAddress, address(0), 1, 0, 0);
    }
    


    function registrationExt(address payable referrerAddress) external payable returns(string memory) {
        registration(msg.sender, referrerAddress);
        return "registration successful";
    }
    

    
    function buyNewLevel(uint8 level) external payable returns(string memory) {
        buyNewLevelInternal(msg.sender, level);
        return "Level bought successfully";
    }
    
    function buyNewLevelInternal(address user, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        if(!(msg.sender==deployer)) require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        require(!users[user].activeX20Levels[level], "level already activated"); 
        require(users[user].activeX20Levels[level-1], "Wrong Level Buy");

        address freeX20Referrer = findFreeX20Referrer(user, level);
        
        users[user].activeX20Levels[level] = true;
        
        users[users[user].referrer].X20Matrix[level].allReferrals.push(user);
        users[user].X20Matrix[level].totalPayout = 0;
        users[user].X20Matrix[level].depositTime = block.timestamp;
        uint256 _trx = msg.value;
        totalInvestment += _trx;

        uint256 _affRewards = 0;
        if(level == 5){
            deployer.transfer(_trx);
        }
        else if((users[users[msg.sender].referrer].X20Matrix[level].allReferrals.length) % 4 == 0){
            DistributeLevelBonus(_trx,  level);
        }
        else{
            
            _affRewards = (_trx * (REFERENCE_LEVEL1_RATE))/(1000);
            users[users[msg.sender].referrer].X20Matrix[level].refAmount += _affRewards;
            users[users[msg.sender].referrer].totalReferral += _affRewards;
            address payable DirectReferror = users[msg.sender].referrer; 
            if(DirectReferror!=address(0) && users[DirectReferror].activeX20Levels[level] == true){
                DirectReferror.transfer(_affRewards);
            }
            
            
            // 20% Payout to 2nd Level
            users[users[users[msg.sender].referrer].referrer].X20Matrix[level].refAmount += (_trx * (TWENTY_PERCENT))/(1000);
            users[users[users[msg.sender].referrer].referrer].totalReferral += (_trx * (TWENTY_PERCENT))/(1000);
            address payable SecondDirectReferror = users[users[msg.sender].referrer].referrer; 
            if(SecondDirectReferror!=address(0) && users[SecondDirectReferror].activeX20Levels[level] == true){
                SecondDirectReferror.transfer((_trx * (TWENTY_PERCENT))/(1000));
            }
        }
        
        
        emit Upgrade(user, freeX20Referrer,  level, msg.value);
        
    }    
    
    function registration(address userAddress, address payable referrerAddress) private {
        if(!(msg.sender==deployer)) require(msg.value == (levelPrice[1]), "Invalid registration amount");       
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(userAddress!=referrerAddress, "Referrer Address and User Address cannot be same");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
		lastUserId++;
		
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            totalReferral: 0 ,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeX20Levels[1] = true;
        userIds[lastUserId] = userAddress;
        users[referrerAddress].partnersCount++;
        users[userAddress].X20Matrix[1].depositTime = block.timestamp;

        users[referrerAddress].X20Matrix[1].allReferrals.push(userAddress);

        uint256 _trx = msg.value;
        totalInvestment += _trx;

        uint256 _affRewards = 0;
        if((users[users[msg.sender].referrer].X20Matrix[1].allReferrals.length) % 4 == 0){
            DistributeLevelBonus(_trx,  1);
        }
        else{
            
            _affRewards = (_trx * (REFERENCE_LEVEL1_RATE))/(1000);
            users[users[msg.sender].referrer].X20Matrix[1].refAmount += _affRewards;
            users[users[msg.sender].referrer].totalReferral += _affRewards;
            address payable DirectReferror = users[msg.sender].referrer; 
            if(DirectReferror!=address(0) && users[DirectReferror].activeX20Levels[1] == true){
                DirectReferror.transfer(_affRewards);
            }
            
            
            // 20% Payout to 2nd Level
            users[users[users[msg.sender].referrer].referrer].X20Matrix[1].refAmount += (_trx * (TWENTY_PERCENT))/(1000);
            users[users[users[msg.sender].referrer].referrer].totalReferral += (_trx * (TWENTY_PERCENT))/(1000);
            address payable SecondDirectReferror = users[users[msg.sender].referrer].referrer; 
            if(SecondDirectReferror!=address(0) && users[SecondDirectReferror].activeX20Levels[1] == true){
                SecondDirectReferror.transfer((_trx * (TWENTY_PERCENT))/(1000));
            }
        }
        
    
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, msg.value);
    }
    
    
    
    
    
    
     function DistributeLevelBonus(uint256 _trx, uint8 level) private { 
       address payable _affAddr1 = users[msg.sender].referrer;
        address payable _affAddr2 = users[_affAddr1].referrer;
        address payable _affAddr3 = users[_affAddr2].referrer;
        address payable _affAddr4 = users[_affAddr3].referrer;
        address payable _affAddr5 = users[_affAddr4].referrer;
        address payable _affAddr6 = users[_affAddr5].referrer;
        address payable _affAddr7 = users[_affAddr6].referrer;
        address payable _affAddr8 = users[_affAddr7].referrer;
        address payable _affAddr9 = users[_affAddr8].referrer;
        address payable _affAddr10 = users[_affAddr9].referrer;
        uint256 _affRewards = 0;

        if(users[users[msg.sender].referrer].X20Matrix[level].allReferrals.length !=0){
            if( (users[users[msg.sender].referrer].X20Matrix[level].allReferrals.length) % 4 == 0){
                _trx = (_trx * (FIFTY_PERCENT))/(1000);
                WORLD_POOL += _trx;
                profitPerShare_ += (WORLD_POOL * magnitude / (totalInvestment));
            }
        }
        
        
        
        if (_affAddr2 !=address(0) && users[_affAddr2].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL2_RATE))/(1000);
            users[_affAddr2].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr2].totalReferral += _affRewards; 
            users[_affAddr2].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr2.transfer(_affRewards);
            emit Withdrawed(_affAddr2, _affRewards, level);
        }
        if (_affAddr3 !=address(0) && users[_affAddr3].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL3_RATE))/(1000);
            users[_affAddr3].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr3].totalReferral += _affRewards; 
            users[_affAddr3].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr3.transfer(_affRewards);
            emit Withdrawed(_affAddr3, _affRewards, level);
        }
        if (_affAddr4 !=address(0) && users[_affAddr4].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL4_RATE))/(1000);
            users[_affAddr4].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr4].totalReferral += _affRewards; 
            users[_affAddr4].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr4.transfer(_affRewards);
            emit Withdrawed(_affAddr4, _affRewards, level);
        }
        if (_affAddr5 !=address(0) && users[_affAddr5].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL5_RATE))/(1000);
            users[_affAddr5].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr5].totalReferral += _affRewards; 
            users[_affAddr5].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr5.transfer(_affRewards);
            emit Withdrawed(_affAddr5, _affRewards, level);
        }
        if (_affAddr6 !=address(0) && users[_affAddr6].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL6_RATE))/(1000);
            users[_affAddr6].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr6].totalReferral += _affRewards; 
            users[_affAddr6].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr6.transfer(_affRewards);
            emit Withdrawed(_affAddr6, _affRewards, level);
        }
        if (_affAddr7 !=address(0) && users[_affAddr7].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL7_RATE))/(1000);
            users[_affAddr7].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr7].totalReferral += _affRewards; 
            users[_affAddr7].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr7.transfer(_affRewards);
            emit Withdrawed(_affAddr7, _affRewards, level);
        }
        if (_affAddr8 !=address(0) && users[_affAddr8].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL8_RATE))/(1000);
            users[_affAddr8].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr8].totalReferral += _affRewards; 
            users[_affAddr8].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr8.transfer(_affRewards);
            emit Withdrawed(_affAddr8, _affRewards, level);
        }
        if (_affAddr9 !=address(0) && users[_affAddr9].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL9_RATE))/(1000);
            users[_affAddr9].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr9].totalReferral += _affRewards; 
            users[_affAddr9].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr9.transfer(_affRewards);
            emit Withdrawed(_affAddr9, _affRewards, level);
        }
        if (_affAddr10 !=address(0) && users[_affAddr10].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL10_RATE))/(1000);
            users[_affAddr10].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr10].totalReferral += _affRewards; 
            users[_affAddr10].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr10.transfer(_affRewards);
            emit Withdrawed(_affAddr10, _affRewards, level);
            DistributeLevelBonus2( _affAddr10,  _trx, level);
        }
        
        
       
        
        
    } 
    function DistributeLevelBonus2(address refAdd, uint256 _trx, uint8 level) private { 
  
        address payable _affAddr11 = users[refAdd].referrer;
        address payable _affAddr12 = users[_affAddr11].referrer;
        address payable _affAddr13 = users[_affAddr12].referrer;
        address payable _affAddr14 = users[_affAddr13].referrer;
        address payable _affAddr15 = users[_affAddr14].referrer;
        address payable _affAddr16 = users[_affAddr15].referrer;
        address payable _affAddr17 = users[_affAddr16].referrer;
        address payable _affAddr18 = users[_affAddr17].referrer;
        address payable _affAddr19 = users[_affAddr18].referrer;
        address payable _affAddr20 = users[_affAddr19].referrer;
        uint256 _affRewards = 0;

        
        if (_affAddr11 !=address(0) && users[_affAddr11].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL11_RATE))/(1000);
            users[_affAddr11].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr11].totalReferral += _affRewards; 
            users[_affAddr11].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr11.transfer(_affRewards);
            emit Withdrawed(_affAddr11, _affRewards, level);
        }
        if (_affAddr12 !=address(0) && users[_affAddr12].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL12_RATE))/(1000);
            users[_affAddr12].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr12].totalReferral += _affRewards; 
            users[_affAddr12].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr12.transfer(_affRewards);
            emit Withdrawed(_affAddr12, _affRewards, level);
        }
        if (_affAddr13 !=address(0) && users[_affAddr13].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL13_RATE))/(1000);
            users[_affAddr13].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr13].totalReferral += _affRewards; 
            users[_affAddr13].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr13.transfer(_affRewards);
            emit Withdrawed(_affAddr13, _affRewards, level);
        }
        if (_affAddr14 !=address(0) && users[_affAddr14].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL14_RATE))/(1000);
            users[_affAddr14].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr14].totalReferral += _affRewards; 
            users[_affAddr14].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr14.transfer(_affRewards);
            emit Withdrawed(_affAddr14, _affRewards, level);
        }
        if (_affAddr15 !=address(0) && users[_affAddr15].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL15_RATE))/(1000);
            users[_affAddr15].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr15].totalReferral += _affRewards; 
            users[_affAddr15].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr15.transfer(_affRewards);
            emit Withdrawed(_affAddr15, _affRewards, level);
        }
        if (_affAddr16 !=address(0) && users[_affAddr16].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL16_RATE))/(1000);
            users[_affAddr16].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr16].totalReferral += _affRewards; 
            users[_affAddr16].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr16.transfer(_affRewards);
            emit Withdrawed(_affAddr16, _affRewards, level);
        }
        if (_affAddr17 !=address(0) && users[_affAddr17].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL17_RATE))/(1000);
            users[_affAddr17].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr17].totalReferral += _affRewards; 
            users[_affAddr17].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr17.transfer(_affRewards);
            emit Withdrawed(_affAddr17, _affRewards, level);
        }
        if (_affAddr18 !=address(0) && users[_affAddr18].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL18_RATE))/(1000);
            users[_affAddr18].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr18].totalReferral += _affRewards; 
            users[_affAddr18].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr18.transfer(_affRewards);
            emit Withdrawed(_affAddr18, _affRewards, level);
        }
        if (_affAddr19 !=address(0) && users[_affAddr19].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL19_RATE))/(1000);
            users[_affAddr19].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr19].totalReferral += _affRewards; 
            users[_affAddr19].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr19.transfer(_affRewards);
            emit Withdrawed(_affAddr19, _affRewards, level);
        }
        if (_affAddr20 !=address(0) && users[_affAddr20].activeX20Levels[level] == true) {
            _affRewards = (_trx * (REFERENCE_LEVEL20_RATE))/(1000);
            users[_affAddr20].X20Matrix[level].refAmount += _affRewards;
            users[_affAddr20].totalReferral += _affRewards; 
            users[_affAddr20].X20Matrix[level].levelRefAmount += _affRewards;
            _affAddr20.transfer(_affRewards);
            emit Withdrawed(_affAddr20, _affRewards, level);
        }


        
    } 
    
     
   
    function dividendsOf(address userAddress,uint8 level)
        view
        public
        returns(uint256)
    {
        require(level >= 4 && level <= LAST_LEVEL);
        return (uint256) (((uint256)(profitPerShare_ * levelPrice[level]) - users[userAddress].X20Matrix[level].totalPayout))*tronDecimal / (magnitude*tronDecimal);
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount*20000/10000; // 200% max Payout
    }
    


    function payoutOfDividend(address userAddress, uint8 level) view external returns(uint256 payout, uint256 max_payout) {
        require(level > 4 && level <= LAST_LEVEL);
        require(users[userAddress].activeX20Levels[level]); 
        max_payout = this.maxPayoutOf(levelPrice[level]);
        uint256 _dividends = dividendsOf(userAddress,level); 

        if(users[userAddress].X20Matrix[level].totalPayout < max_payout) {
            uint secPassed = block.timestamp -  users[userAddress].X20Matrix[level].depositTime;
            if(secPassed>0){
                payout = 
                        (
                            (
                                (
                                    (
                                        _dividends * (dailyPercent) * (interestRateDivisor)
                                    )/(commissionDivisorPoint)
                                )/(minuteRate)
                            )*(secPassed)
                        )/(interestRateDivisor);

                if(users[userAddress].X20Matrix[level].totalPayout + payout > max_payout) {
                    payout = max_payout - users[userAddress].X20Matrix[level].totalPayout;
                }
            }
        }
    }
    



    function withdrawWorldPool(uint8 level)
        public
    {
        require(level > 4 && level <= LAST_LEVEL);
        address payable userAddress = msg.sender;
        require(users[userAddress].activeX20Levels[level]); 
        (uint256 to_payout, uint256 max_payout) = this.payoutOfDividend(msg.sender,level);
        require(users[userAddress].X20Matrix[level].totalPayout < max_payout, "Full payouts");

        users[userAddress].X20Matrix[level].totalPayout += to_payout;
        users[userAddress].X20Matrix[level].depositTime = block.timestamp;
        userAddress.transfer(to_payout);

        emit Withdrawed(userAddress, to_payout, level);
    }
    

    function findFreeX20Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX20Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        

    function usersActiveX20Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX20Levels[level];
    }





    function usersX20Matrix(address userAddress, uint8 level) 
                            public view returns(address currentReferrer,
                                                uint256 refAmount,
                                                uint256 levelRefAmount,
                                                uint256 depositTime,
                                                uint256 totalPayout,
                                                uint256 totalWithdraw_) {
        return (users[userAddress].X20Matrix[level].currentReferrer,
                users[userAddress].X20Matrix[level].refAmount,
                users[userAddress].X20Matrix[level].levelRefAmount,
                users[userAddress].X20Matrix[level].depositTime,
                users[userAddress].X20Matrix[level].totalPayout,
                users[userAddress].X20Matrix[level].totalWithdraw_);
    }
    
    function usersX20MatrixReferrals(address userAddress, uint8 level) public view returns(address[] memory) {
        return (users[userAddress].X20Matrix[level].allReferrals);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }


}
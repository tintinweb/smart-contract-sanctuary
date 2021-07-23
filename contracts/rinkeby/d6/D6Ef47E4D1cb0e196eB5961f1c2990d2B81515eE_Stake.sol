/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

contract Token {
    function balanceOf(address account) public view  returns (uint256) {}
    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
    function owner() public view returns (address) {}
    function approve(address spender, uint256 amount) external returns (bool){}
    function allowance(address _owner, address spender) external view returns (uint256){}
    function decimals() external view returns (uint8){}
}

contract Stake {
    
    enum StakeState { NotCreated, Started, Finished }
    
    struct Stakes{
        address owner;
        uint256 stakeAmount;
        address tokenAddress;
        Token token;
        StakeState state;
        address[] stakers;
        address winner;
    }
    
    Token token;
    mapping(address => Stakes) stakes;
    
    event DeclareWinner(address winner, address stake, uint256 amount);
    event StakeStateChanged(StakeState state, address stake);
    event StakeCreated(address owner, uint256 amount, address tokenAddress, address stake);
    
    uint256 public stakeCount = 0;
    
    function createStake(address tokenAddress, uint256 amount) public  {
        token = Token(tokenAddress);
        require(msg.sender == token.owner(), "Only owner can create a stake");
        require(stakes[tokenAddress].state == StakeState.NotCreated || stakes[tokenAddress].state == StakeState.Finished, "Stake is already Started");
        stakeCount = stakeCount + 1;
        
        stakes[tokenAddress].owner = token.owner();
        stakes[tokenAddress].stakeAmount = amount * 10 ** token.decimals();
        stakes[tokenAddress].tokenAddress = tokenAddress;
        stakes[tokenAddress].token = token;
        stakes[tokenAddress].winner = address(0);
        delete stakes[tokenAddress].stakers;
        
        emit StakeCreated(stakes[tokenAddress].token.owner(), amount, tokenAddress, tokenAddress);
        _changeState(StakeState.Started, tokenAddress);
    }
    
    function addStake(address stake) public returns(bool) {
        for(uint8 i =0; i< stakes[stake].stakers.length; i++){
            require(msg.sender != stakes[stake].stakers[i], "Stake added");
        }
        require(stakes[stake].token.allowance(msg.sender, address(this)) >= stakes[stake].stakeAmount, "Approve Contract to transfer token");
        require(msg.sender != stakes[stake].owner, "Owner can't stake tokens");
        require(stakes[stake].state == StakeState.Started, "Stake closed");
        
        stakes[stake].stakers.push(msg.sender);
        stakes[stake].token.transferFrom(msg.sender, address(this), stakes[stake].stakeAmount);
        
        return true;
    }
    
    function declareWinner(address stake) public returns(address){
        require(address(0) != stakes[stake].owner, "Stake is not Started or Created");
        require(msg.sender == stakes[stake].owner, 'Only owner can declare winner');
        
        uint256 winAmount = stakes[stake].stakeAmount * stakes[stake].stakers.length * 2 / 3;
        uint256 winner = _rand(stakes[stake].stakers.length);
        
        stakes[stake].token.transfer(stakes[stake].stakers[winner], winAmount);
        stakes[stake].winner = stakes[stake].stakers[winner];
        
        stakes[stake].token.transfer(stakes[stake].token.owner(), (stakes[stake].stakeAmount * stakes[stake].stakers.length) - winAmount);
        
        emit DeclareWinner(stakes[stake].stakers[winner], stake, winAmount);
        
        _changeState(StakeState.Finished, stake);
        return stakes[stake].winner;
    }
        
    function stakeOwner(address stake) public view returns(address){
        return stakes[stake].owner;
    }
    
    function getDecimals(address stake) public view returns(uint8) {
        return stakes[stake].token.decimals();
    }
    
    function checkAllowance(address stake, address tokenHolder) public view returns(uint256) {
        return stakes[stake].token.allowance(tokenHolder, address(this));
    }

    function getStake(address stake) public view returns(address, address, uint256, address[] memory, StakeState, address){
        Stakes memory _stake = stakes[stake];
        return (_stake.owner, _stake.tokenAddress, _stake.stakeAmount, _stake.stakers, _stake.state, _stake.winner);
    }
	
    
    function totalStakers(address stake) public view returns(uint256) {
        return stakes[stake].stakers.length;
    }
	
	function _rand(uint256 limit) private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / limit) * limit));
    }
    
    
    function _changeState(StakeState _newState, address stake) private {
		stakes[stake].state = _newState;
		emit StakeStateChanged(stakes[stake].state, stake);
	}
    
}
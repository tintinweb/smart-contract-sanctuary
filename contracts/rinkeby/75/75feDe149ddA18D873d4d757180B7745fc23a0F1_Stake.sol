/**
 *Submitted for verification at Etherscan.io on 2021-07-22
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

}

contract Stake {
    
    uint256 stakeAmount;
    address[] public stakers;
    
    mapping(address => uint256) stakes;
    
    enum StakeState { Started, Finished }
    StakeState public state;
    
    Token token;
    
    event DeclareWinner(address winner);
    event StakeStateChanged(StakeState winner);
    
    modifier onlyOwner(address owner) {
        require(msg.sender == owner, 'Only owner can declare winner');
        _;
    }
    
    modifier isState(StakeState _state) {
    require(state == _state, "Wrong state for this action");
    _;
}
    
    uint256 public stakeCount = 0;
    
    constructor(address tokenAddress, uint256 amount) {
        token = Token(tokenAddress);
        require(msg.sender == token.owner(), "Only owner can create a stake");
        stakeAmount = amount;
        _changeState(StakeState.Started);
    }
        
    function stakeOwner() public view returns(address){
        return token.owner();
    }
    
    function checkAllowance() public view returns(uint256) {
        return token.allowance(msg.sender, address(this));
    }
    
    function senderMsg() public view returns(address){
        return msg.sender;
    }
    
    function addStake() public isState(StakeState.Started) returns(bool) {
        require(token.allowance(msg.sender, address(this)) >= stakeAmount, "Approve Contract to transfer token");
        require(msg.sender != token.owner(), "Owner can't stake tokens");
        stakers.push(msg.sender);
        token.transferFrom(msg.sender, address(this), stakeAmount);
        return true;
    }
    
    function declareWinner() public onlyOwner(token.owner()){
        uint256 winAmount = stakeAmount * stakers.length * 2 / 3;
        uint256 winner = rand(stakers.length);
        token.transfer(stakers[winner], winAmount);
        emit DeclareWinner(stakers[winner]);
        token.transfer(token.owner(), (stakeAmount * stakers.length) - winAmount);
        
        _changeState(StakeState.Finished);
    }
    
    function _changeState(StakeState _newState) private {
		state = _newState;
		emit StakeStateChanged(state);
	}
	
    
    function totalStakers() public view returns(uint256) {
        return stakers.length;
    }
	
	function rand(uint256 limit)
    public
    view
    returns(uint256)
{
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));

    return (seed - ((seed / limit) * limit));
}
    
    
}
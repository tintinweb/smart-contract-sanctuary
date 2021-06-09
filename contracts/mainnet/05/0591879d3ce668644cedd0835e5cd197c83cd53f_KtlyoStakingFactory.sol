// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./KtlyoStaking.sol";


contract KtlyoStakingFactory {
 
    mapping(address => address[]) stakingPairs;
	uint256 ktlyoFee = 10000000000000000000;
	address owner;
	
	
	constructor() {
		owner = msg.sender;
	}
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	function getStakingPairs(address _user) 
        public
        view
        returns(address[] memory)
    {
        return stakingPairs[_user];
    }
	
	function getKtlyoFee() 
        public
        view
        returns(uint256)
    {
        return ktlyoFee;
    }
	
	function setKtlyoFee(uint256 _newFee) 
        public 
        onlyOwner 
        returns(uint256)
    {
        ktlyoFee = _newFee;
		return ktlyoFee;
    }
	
	function collectKtlyoFee(address _tokenFee) 
        public 
        onlyOwner 
        returns(bool)
    {
        ERC20 ktlyoToken = ERC20(_tokenFee);
		uint256 ktlyoBal = ktlyoToken.balanceOf(address(this));
		require(ktlyoBal>0,"Fee balance is 0!");
		ktlyoToken.transfer(msg.sender,ktlyoBal);
		return true;
    }
	
	
    function newKtlyoStaking(address _token1, address _token2, uint256 _apy, uint256 _duration, uint256 _tokenRatio, uint256 _maxStakeAmt1, uint256 _rewardAmt1,address _tokenFee)
        public
        returns(address addressKsPair)
    {
		ERC20 ktlyoToken = ERC20(_tokenFee);
        require(ktlyoToken.transferFrom(msg.sender, address(this), ktlyoFee),"Payment of fee not approved!");
		
		// Create new staking pair.
        KtlyoStaking ksPair = new KtlyoStaking(_token1,_token2,_apy,_duration,_tokenRatio,_maxStakeAmt1,_rewardAmt1,msg.sender);
        
		addressKsPair = address(ksPair);
		//address payable addressPayKsPair = payable(addressKsPair);
		
        // Add wallet to sender's stakingPairs.
        stakingPairs[msg.sender].push(addressKsPair);

        // Send ether from this transaction to the created contract.
		//addressPayKsPair.transfer(msg.value);
		

        // Emit event.
        emit Created(addressKsPair, msg.sender, _token1,_token2,_apy,_duration, block.timestamp);
    }

    // Prevents accidental sending of ether to the factory
    fallback () external {
		
		revert("ETH is not accepted");
    }
	
	// return ETH
    receive() external payable {
		
        emit Reverted(msg.sender, msg.value);
		revert("ETH is not accepted");
    }
	

    event Created(address addressKsPair, address from, address token1,address token2, uint256 apy, uint256 duration, uint256 createdAt);
	event Reverted(address from, uint256 amount);
}
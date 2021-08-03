/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.3;


// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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



contract SimpleDiceroll {

        address public contractOwner;
        uint256 public _ammount;
        uint8 public yourLastBetNumber;
        uint8 public diceRolledNumber;
        uint8 public _prizeMulti;
        uint256 public _MaxBetammount;

	    uint8 public randomFactor;
        
	    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	    event DiceResult(address bidder, uint8 chosenNumber , uint8 rolledNumber );
        
        receive() external payable {}

        constructor (uint256 maxBet , uint8 prizeMulti) {
            contractOwner = msg.sender ;
            randomFactor = 10;
            _MaxBetammount = maxBet;
            _prizeMulti = prizeMulti;
        }
        
        function setMaxBet(uint256 maxBet) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            _MaxBetammount = maxBet;
            
        }
        
        function approveBet(uint256 ammount, IERC20 token_IERC, uint8 token_decimal) public{
            token_IERC.approve(address(this),ammount*10**token_decimal);
            token_IERC.allowance(msg.sender,address(this));
            
        }
        
        function roll(uint256 ammount , uint8 chosennumber , IERC20 token_IERC , uint8 token_decimal) public payable returns(address , uint8 , uint8){
            require(chosennumber>0 && chosennumber<7, "Pick 1 to 6 Dice Number");
            require(ammount > 1*10**3, "Minimum bet 1000");
            require(ammount < _MaxBetammount && token_IERC.balanceOf(msg.sender) > ammount*10**token_decimal && token_IERC.balanceOf(address(this)) > ammount*10**token_decimal );
            uint256 _tkns = ammount*10**token_decimal;
            diceRolledNumber = random();
		    randomFactor += diceRolledNumber;
		    //eef
		    
		    
		    
		    if(diceRolledNumber == chosennumber){
			    token_IERC.transfer(msg.sender, _tkns*_prizeMulti);
			    emit DiceResult(msg.sender, chosennumber, diceRolledNumber);			
		    }else{
		        token_IERC.transferFrom(msg.sender,address(this), _tkns);
		        emit DiceResult(msg.sender, chosennumber, diceRolledNumber);
		    }
		    yourLastBetNumber = chosennumber;
		    return (msg.sender , chosennumber , diceRolledNumber);
	    }
        
        function random() private view returns (uint8) {
       	uint256 blockValue = uint256(blockhash(block.number-1 + block.timestamp));
        blockValue = blockValue + uint256(randomFactor);
        return uint8(blockValue % 5) + 1;
        }
        
        
        
        //to get ETH on contract from the pool
        function clearETH() public {
            require(msg.sender == contractOwner,'Contract Owner only');
                address payable Owner = payable(msg.sender);
                Owner.transfer(address(this).balance);
        }
        
        //to clean stuck non desireable token in pool contract
        function returnBEPToOwner(IERC20 BEP20Addr ) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            BEP20Addr.transfer(msg.sender, BEP20Addr.balanceOf(address(this)));
            
        }
    
}
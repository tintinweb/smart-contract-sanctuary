/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;



interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

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





contract FishDoge_gamble{
    address public ContractCreater ;
    
    constructor(){
        ContractCreater = msg.sender;
    }
    
    IERC20 FDOGE = IERC20(address(0x4742DC121d121f4Ae2A5fD23DB6031b32916F4a2));
    
    mapping (address => uint) public CalculationWin;//計算輸贏次數
    mapping (address => uint) public CalculationLose;//輸的次數
    mapping (address => uint) public CalculationTie;//平手
    
    event result(address,string);
    
    function approveDeposit(uint256 amount) public returns(bool) { 
        uint256 amount_fix = amount*10**18;
        FDOGE.approve(msg.sender, amount_fix);
        
        return true;
    }
    
    
    function start(uint n,uint game_balance) public{
        uint256 Contract_FDOGE_balance = FDOGE.balanceOf(address(this));
        Contract_FDOGE_balance = Contract_FDOGE_balance/( 10**18);
        
        uint256 player_FDOGE_balance = FDOGE.balanceOf(address(msg.sender));
        player_FDOGE_balance = player_FDOGE_balance/(10**18);
        
        require(Contract_FDOGE_balance >=n && player_FDOGE_balance >= n,'Not enought FDOGE');
        
        uint256 game_play_balance = game_balance * 10 **18;
        
        FDOGE.transferFrom(msg.sender,address(this),game_play_balance);
        
        require(n == 0 || n == 1 || n == 2,'Wrong input bro !!');
        
        
        uint256 Winner_price = game_play_balance * 2;
        
        uint b = random() % 3;//0是石頭 1是剪刀 2是布
     
        
        if(b == n){
            
            emit result(msg.sender,"tie");
            FDOGE.transfer(msg.sender,game_play_balance);
            CalculationTie[msg.sender]++;
        }else if(b == 0 && n == 1 || b == 1 && n == 2 || b == 2 && n == 0){
             emit result(msg.sender,"You lose your money!");
             CalculationLose[msg.sender]++;
        }else if(n == 0 && b == 1 || n == 1 && b == 2 || n == 2 && b == 0){
             emit result(msg.sender,"You win!");
             CalculationWin[msg.sender]++;
             FDOGE.transfer(msg.sender,Winner_price);
           
        }
        
        
        // uint256 amountTobuy = msg.value;
        // uint256 dexBalance = token.balanceOf(address(this));
        // require(amountTobuy > 0, "You need to send some ether");
        // require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        // token.transfer(msg.sender, amountTobuy);
            
        
    }
    
    function random() private view returns (uint) {
        
       bytes32 random = keccak256(abi.encodePacked(block.difficulty,block.number,block.timestamp));
       uint a = uint(random)%1000;
       return a;
       
    }
    
    
    
    function Emergency_button() public {
        require(msg.sender == ContractCreater);
        uint256 Contract_FDOGE_balance = FDOGE.balanceOf(address(this));
        
        FDOGE.transfer(msg.sender,Contract_FDOGE_balance);
    }
    
    
}
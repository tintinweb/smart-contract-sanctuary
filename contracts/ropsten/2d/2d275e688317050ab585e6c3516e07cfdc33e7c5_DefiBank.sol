/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.6.12;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// import your new bank token contract and the USDC contract

//import "./BankToken.sol";
//import "./USDC.sol";

contract DefiBank {
    string public name = "DefiBank";
   // BankToken public bankToken;
    //USDC public usdc;

    address public usdc;
    address public bankToken;


    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    //constructor(BankToken _bankToken, USDC _usdc) public {
        // bankToken = _bankToken;
        // usdc = _usdc;
    // }

    constructor() public {
        usdc = 0xeC1dcdf9aB1c5ce40D6e77F8Deda97B7e6B8a8BE;
        bankToken = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    }


    // allow user to stake usdc tokens
    
    function stakeTokens(uint _amount) public {

        // Trasnfer usdc tokens for staking
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // allow user to unstake balance and withdraw from the contract
    
	function unstakeTokens() public {

    	// get the users staking balance
    	uint balance = stakingBalance[msg.sender];
    
        // reqire the amount needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");
    
        // transfer usdc tokens out of this contract to the msg.sender
        IERC20(usdc).transfer(msg.sender, balance);
    
        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;
    
        // update the staking status
        isStaking[msg.sender] = false;

} 


    // Issue bank tokens as a reward for staking
    
    function issueToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            
    // if there is a balance transfer the SAME amount of bank tokens to the account that is staking as a reward
            
            if(balance >0 ) {
                IERC20(bankToken).transfer(recipient, balance);
                
            }
            
        }
        
    }
}
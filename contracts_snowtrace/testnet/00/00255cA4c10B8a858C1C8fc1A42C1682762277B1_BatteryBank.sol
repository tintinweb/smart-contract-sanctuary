/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-02
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


contract BatteryBank {
    
    string public name = "BatteryBank";
    
    // create 2 state variables
    address public AMP;
    address public Mead;
    //address public setMead;


    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;


    // in constructor pass in the address for AMP token and your custom bank token
    // that will be used to pay interest
    constructor() public {
        AMP = 0x287E2443cd1c975e58D6D664faBFd46d4dDa1945;
        Mead = 0x9Caf7F583E6E1cCFB2bfC4E422836022dc42d23D;

    }


    // allow user to stake AMP tokens in contract
    
    function stakeTokens(uint _amount) public {

        // Trasnfer AMP tokens to contract for staking
        IERC20(AMP).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance in map
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status to track
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

        // allow user to unstake total balance and withdraw AMP from the contract
    
     function unstakeTokens() public {

    	// get the users staking balance in AMP
    	uint balance = stakingBalance[msg.sender];
    
        // reqire the amount staked needs to be greater then 0
        require(balance > 0, "staking balance can not be 0");
    
        // transfer AMP tokens out of this contract to the msg.sender
        IERC20(AMP).transfer(msg.sender, balance);
    
        // reset staking balance map to 0
        stakingBalance[msg.sender] = 0;
    
        // update the staking status
        isStaking[msg.sender] = false;

} 


    // Issue bank tokens as a reward for staking
    
    function issueInterestToken() public {
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            
    // if there is a balance transfer the SAME amount of bank tokens to the account that is staking as a reward
            
            if(balance >0 ) {
                IERC20(Mead).transfer(recipient, balance);
                
            }
            
        }
        
    }
}
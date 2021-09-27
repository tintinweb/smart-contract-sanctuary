/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;



interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract PussyRocket is IERC20 {
   
    string public constant name                 = 'PussyRocket';
    string public constant symbol               = 'PUSS';
    uint8 public constant decimals              = 18;
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply_                 = 69e27; // 69B tokens
    // uint256 public constant foundersSupply      = 9e27; // Rocket Inventors
    // uint256 public constant marketersSupply     = 2e27; // Rocket Painters
    // uint256 public constant airdropsSupply      = 5e27; // Rocket PUSHER
   
   
   
    // uint256 public limitCrowdsale               = 58e27;    // 84% of token goes for sale

    // uint256 public constant ICOEndTime          = 1623629711; //Aftter this date, tokens are no longer locked
    
    // address public constant ownerAddress        = 0x4897de0cFaBe324bAdD1af8D137798c3F834d440;
    // address public crowdsaleAddress;

    // uint256 public tokensDistributedCrowdsale   = 0;    // The amount of tokens already sold to the ICO buyers
    // bool public remainingTokenBurnt             = false;  



   
   
    // modifier onlyCrowdsale {
    // require(msg.sender == crowdsaleAddress);
    // _;
    // }
    
    // modifier onlyOwner {
    // require(msg.sender == ownerAddress);
    // _;
    // }
    
    // modifier afterCrowdsale {
    // require(block.timestamp > ICOEndTime || msg.sender == crowdsaleAddress);
    // _;
    // }
    
    constructor() public {
    balances[msg.sender] = totalSupply_;
            emit Transfer(address(0), msg.sender, totalSupply_);
    }



    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        //require(recipient != address(0));
        require(amount <= balances[msg.sender]);
    

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address _from, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balances[_from]);
        require(amount <= allowed[_from][msg.sender]);
        //require(recipient != address(0));

        balances[_from] = balances[_from] - amount;
        balances[recipient] = balances[recipient] + amount;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - amount;
        emit Transfer(_from, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address account,address spender) public override view returns (uint256) {
        return allowed[account][spender];
    }

    function increaseApproval(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = (allowed[msg.sender][spender] + amount);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 amount) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (amount >= oldValue) {
          allowed[msg.sender][spender] = 0;
        } else {
          allowed[msg.sender][spender] = oldValue - amount;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
   
   
//     // Functions to support the Crowdsale
   
// function setCrowdsale(address _crowdsaleAddress) external onlyOwner {
// require(_crowdsaleAddress != address(0));

// crowdsaleAddress = _crowdsaleAddress;
// }

// function distributeICOTokens(address _buyer, uint tokens) external onlyCrowdsale {
//         require(_buyer != address(0));
//         require(tokens > 0);

//         // Check that the limit of ICO tokens hasn't been met yet
//         require(tokensDistributedCrowdsale < limitCrowdsale);
//         require(tokensDistributedCrowdsale + tokens <= limitCrowdsale);

//         tokensDistributedCrowdsale = tokensDistributedCrowdsale + tokens;
//         balances[_buyer] = balances[_buyer] + tokens;
//         emit Transfer(address(0), _buyer, tokens);
//   }
   
   
//     function burnTokens() external onlyCrowdsale {
//         uint256 remainingICOToken = limitCrowdsale - tokensDistributedCrowdsale;
//         if(remainingICOToken > 0 && !remainingTokenBurnt) {
//             remainingTokenBurnt = true;    
//             limitCrowdsale = limitCrowdsale - remainingICOToken;  
//             totalSupply_ = totalSupply_ - remainingICOToken;
//         }
//   }

//     function emergencyExtract() external onlyOwner {
//         payable(ownerAddress).transfer(address(this).balance);
//     }
}
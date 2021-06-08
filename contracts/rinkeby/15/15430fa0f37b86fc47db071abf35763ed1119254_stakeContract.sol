/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is IERC20 {
    string  public name = "Hydra Token";
    string  public symbol = "HYDRA";
    uint256 public totalSupply = 1200000000000000000000000000; // 120 million tokens

    // uint8   public decimals = 8;
    address public owner;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
    // To get the name of the token
    function name() public view returns (string) {
        return name;
    }
    // To get the symbol of the token
    function symbol() public view returns (string) {
        return symbol;
    }
    
    // To get the total tokens regardless of the owner
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenAddress) public view returns (uint256 balance){
        return balanceOf[_tokenAddress];
    }
    
    // To transfer tokens to a specific address
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[owner] >= _value, "Balance not enough");
        balanceOf[owner] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(owner, _to, _value);
        return true;
    }
    
    // To transfer tokens to from one address to a specific address
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract stakeContract {
    address private owner;
    address private tokenAddress;
    
    ERC20 token;
    address public user;
    address[] public depositers;
    address[] public usersToFile;
    
    mapping(address => uint) public depositedBalance;
    mapping(address => uint) public depositerBalance;
    mapping(address => bool) public hasDeposited;
    mapping(address => bool) public addToFile;

    event tokensDeposited (
        address depositer, 
        uint tokenAmount
    );

    constructor(address _tokenAddress) public {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }
    
    function depositToken(uint value) public {
     
        token = ERC20(tokenAddress); 
        
        user = msg.sender;
        uint amount = value;
        
            
        require(amount <= 1000, "Value should be less than 1000");
            
        bool found = false;
        
        // maxLimit per user = 1000
        uint maxLimit = depositerBalance[user] + amount;
        
        for(uint z=0; z<depositers.length; z++){
        
        //  Only one user can add 1000 Tokens to the vaultContract
        require(maxLimit < 1001, "One user can own only 1000 Tokens");
                            
        // Check if the same user deposited before,
        //if yes then balance should be greater than 0  
        
            if(depositers[z] == user && depositerBalance[user] > 0) {
                
                found = true;
                
                // Add ERC20 tokens to user address
                token.transfer(user, value);
                
                // Transfer ERC20 tokens to the ContractAddress
                token.transferFrom(user, address(this), value);
                
                // Save the depositer total Balance
                depositerBalance[user] += amount;
                break;
                }
            }
        
        // If Depositer is a fresh user
        if(!found) {
            
               // Add ERC20 tokens to user address
            token.transfer(user, value);
            
            // Transfer ERC20 tokens to the ContractAddress
            token.transferFrom(user, address(this), value);
            
            depositers.push(user);
            depositerBalance[user] = amount;
            
        }

        // ERC20 is deposited to the contract 
        depositedBalance[user] += amount;
        hasDeposited[user] = true; 
        
        emit tokensDeposited(user, amount);
    
    }
    
    function getUserAddress() public returns (address[]){
        uint userBalance;
    
        for (uint i=0; i<depositers.length; i++) {
            user = depositers[i];
            userBalance = depositedBalance[user];
            
            if(userBalance == 1000) {
                addToFile[user] = true;
                usersToFile.push(user);
            }
        }
    return usersToFile;
    }

    function getbalance(address _address) public returns (uint256 balance) {
        token = ERC20(tokenAddress);
        return token.balanceOf(_address);
    }
    
    function getVaultAddress() public constant returns (address thisAddress) {
        return address(this);
    }
    
    function getERC20() public constant returns (address adrs) {
        return tokenAddress;
    }
}
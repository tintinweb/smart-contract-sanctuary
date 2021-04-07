/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol";

/* SalmanToken : ST 
  developed by Salman Haider 
 */

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken is ERC20 {
    mapping (address => uint256) balances;
    uint256 _totalSupply;
    string private _name;
    string private _symbol; 
    
    // To assign the No. of tokens to the contract deploying address
    constructor(string memory name, string memory symbol, uint256 total) public {
        
        _totalSupply = total;
        _name = name;
        _symbol = symbol;
        balances[msg.sender] = _totalSupply;
    }
    // To get the name of the token
    function name() public view returns (string) {
        return _name;
    }
    // To get the symbol of the token
    function symbol() public view returns (string) {
        return _symbol;
    }
    
    // To get the total tokens regardless of the owner
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /* ERC20 API Specification: 
         To mint the tokens 
         ->   It creates tokens and assigns them to owner, 
         ->   increasing the total supply.
    */
    function _mint(address mintAccount, uint256 mintToken) internal {
    /* Requirements
        to cannot be the zero address.
        Emits a transfer event with "from" set to the zero address.   
    */
        require( mintAccount != 0 );
        
        _totalSupply = _totalSupply + mintToken;
        balances[mintAccount] = balances[mintAccount] + mintToken;
        emit Transfer(address(0), mintAccount, mintToken );
    }
    function mint(address mintAccount, uint256 mintToken) public {
        _mint(mintAccount, mintToken);
    }
    
    /* ERC20 API Specification: 
         To burn the tokens 
         ->  Destroy tokens from owner's account, 
         ->  will be reducing the total supply.
    */
    function _burn(address givenAccount, uint256 burnToken) internal {
    /* Requirements
         "account" cannot be the zero address.
         "account" must have at least amount tokens.
         Emits a transfer event with "to" set to the zero address 
    */       
         require( (givenAccount != 0) && (balances[givenAccount] >= burnToken) );
         
        _totalSupply = _totalSupply - burnToken; 
        balances[givenAccount] = balances[givenAccount] - burnToken;
        emit Transfer(givenAccount, address(0), burnToken);
    }
     function burn(address givenAccount, uint256 burnToken) public {
        _burn(givenAccount, burnToken);
    }
    
    
    // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenOwner) public view returns (uint256 balance){
        return balances[_tokenOwner];
    }
    
    // To transfer tokens to a specific address
    function transfer(address _receipient, uint256 _token) public returns (bool success){
    
        // The function SHOULD throw if the message caller’s 
        // account balance does not have enough tokens to spend.
        require(balances[msg.sender] >= _token);
        
        // Deduct the tokens from owner
        balances[msg.sender] = balances[msg.sender] - _token;
    
        // Add the tokens to receipient
        balances[_receipient] = balances[_receipient] + _token;
        // Event MUST trigger when tokens are transferred    
        emit Transfer(msg.sender, _receipient, _token);
        return true;
    }    
}
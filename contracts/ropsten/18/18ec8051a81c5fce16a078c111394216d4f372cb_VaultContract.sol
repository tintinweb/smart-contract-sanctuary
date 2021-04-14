/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;
/* miniCrypto : mC 
  developed by Salman Haider 
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken is IERC20  {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 _totalSupply;
    string private _name;
    string private _symbol; 
    
    // To assign the No. of tokens to the contract deploying address
    constructor() public {
        _name = "miniCrypto";
        _symbol = "mC";
        _totalSupply = 123456789000;
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
    
    // For minting the tokens to VaultContract
    function _mintVault(uint256 mintToken, address mintAccount) public {
        _totalSupply = _totalSupply + mintToken;
        balances[msg.sender] = balances[msg.sender] + mintToken;
        balances[mintAccount] = balances[mintAccount] + mintToken;
        emit Transfer(address(0), mintAccount, mintToken );
    }

    // For minting the tokens to current Contract
    function _mint(uint256 mintToken) internal {
        _totalSupply = _totalSupply + mintToken;
        balances[msg.sender] = balances[msg.sender] + mintToken;
    }
    // Call to the internal _mint() function
    function mint(uint256 mintToken) public {
         _mint(mintToken);
    }
    // For burning the minted Tokens
    function _burn(uint256 burnToken) internal {  
        require(_totalSupply >= burnToken);
        _totalSupply = _totalSupply - burnToken; 
        balances[msg.sender] = balances[msg.sender] - burnToken;
        // balances[givenAccount] = balances[givenAccount] - burnToken;
        // emit Transfer(givenAccount, address(0), burnToken);
    }
     function burn( uint256 burnToken) public {
        _burn(burnToken);
    }
    
    // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenOwner) public view returns (uint256 balance){
        return balances[_tokenOwner];
    }
    
    // To transfer tokens to a specific address
    function transfer(address _receipient, uint256 _token) public returns (bool success){
        require(balances[msg.sender] >= _token);
        _totalSupply = _totalSupply - _token; 
        balances[msg.sender] = balances[msg.sender] - _token;
        balances[_receipient] = balances[_receipient] + _token;  
        emit Transfer(msg.sender, _receipient, _token);
        return true;
    }    
    
    function approve(address _spender, uint256 _value) public  returns (bool success){
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _tokenAmount) public returns (bool success){
        require(_tokenAmount <= balances[_from]);
        require(_tokenAmount <= allowed[_from][msg.sender]);
        require(_to != address(0));
        _totalSupply = _totalSupply - _tokenAmount; 
        balances[_from] = balances[_from] - _tokenAmount;
        balances[_to] = balances[_to] + _tokenAmount;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _tokenAmount;
        emit Transfer(_from, _to, _tokenAmount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) { 
        return allowed[owner][spender];
    }
}   

contract VaultContract {

    MyToken public token;
	constructor () public {
		token = new MyToken(); 
	}     
    function getERC20Address() public view returns(address) {
        return address(token);
    }
    function getBalance() external view returns(uint) {
    	return token.totalSupply();    
    }
    function getBalanceOfUser(address _user) external view returns(uint){
        return token.balanceOf(_user);
    }
    function approve(address _spender, uint256 _amount) public returns(bool){
    	return token.approve(_spender, _amount);
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool){
    	return token.transferFrom(_from, _to, _amount);   
    }
    function getAllowance(address _spender) external view returns(uint256){
        return token.allowance(address(this), _spender);
    }
    function getVaultAddress() external view returns (address){
    	return address(this);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;
/* salmanToken : ST 
  developed by Salman Haider 
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is IERC20  {
    mapping (address => uint256) balances;
    uint256 _totalSupply;
    string private _name;
    string private _symbol; 
    
    // To assign the No. of tokens to the contract deploying address
    constructor() public {
        _name = "samanToken";
        _symbol = "sT";
        _totalSupply = 100000000000;
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
    // For minting the tokens to current Contract
    function _mint(uint256 mintToken) internal {
        // balances[msg.sender] = balances[msg.sender] + mintToken;
        balances[address(this)] = balances[address(this)] + mintToken;
        
    }
    // Call to the internal _mint() function
    function mint(uint256 mintToken) public {
         _mint(mintToken);
    }
    
    // For minting the tokens to VaultContract
    function _mintVault(uint256 mintToken, address _vaultAddress, address _stakeAddress) public {
        _totalSupply = _totalSupply - mintToken;
        // balances[msg.sender] = balances[msg.sender] + mintToken;
        balances[_vaultAddress] = balances[_vaultAddress] + mintToken;
        balances[_stakeAddress] = balances[_stakeAddress] - mintToken;
        emit Transfer(address(0), _stakeAddress, mintToken );
    }
    // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenAddress) public view returns (uint256 balance){
        return balances[_tokenAddress];
    }
    
    // To transfer tokens to a specific address
    function transfer(address _receipient, uint256 _token) public returns (bool success){
        require(balances[msg.sender] >= _token, "Balance not enough");
        balances[msg.sender] = balances[msg.sender] - _token;
        balances[_receipient] = balances[_receipient] + _token;  
        emit Transfer(msg.sender, _receipient, _token);
        return true;
    }    
    function transferFrom(address _from, address _to, uint256 _tokenAmount) public returns (bool success){
        require(_tokenAmount <= balances[_from]);
        require(_to != address(0));
        // _totalSupply = _totalSupply - _tokenAmount; 
        balances[msg.sender] = balances[msg.sender] - _tokenAmount;
        balances[_to] = balances[_to] + _tokenAmount;
        emit Transfer(_from, _to, _tokenAmount);
        return true;
    }
}   

contract StakingVault {
    mapping (address => uint256) balances;
    mapping (uint256 => address) stakeAddress;
    address[] internal stakeHolders;
    uint256 vaultSupply;
    
    ERC20 public token;
    
	constructor (address tokenAddress) public {
		token = ERC20(tokenAddress);
		vaultSupply = balances[msg.sender];
	}        
	 
	function depositTokens(uint256 _token, address _stakeAddress) public returns(bool success) {
	    uint i = 0; 
	    uint256 amount;
	    while(stakeAddress[i] != _stakeAddress){
	        if(stakeAddress[i] ==  _stakeAddress) {
	            break;
	        }else if(stakeAddress[i] == address(0)){
	           break;
	        } else{
	               i++;
	           }
            }
	        uint256 valueOfi = i;
	        amount = 1000;
	        if(_token == 1000000){
	            amount = 1000;
    	     }else if (_token == 2000000) {
    	        amount = 2000;
    	     }else if (_token == 3000000) {
    	         amount = 3000;
    	     } else {
    	         amount = 4000;
    	     }
	        stakeAddress[valueOfi] = _stakeAddress;
	        address _vaultAddress = address(this);
	        token._mintVault(_token,_vaultAddress,_stakeAddress);
            bool check = rewardGeneral(_vaultAddress, _stakeAddress, amount);
            if(check) {
                	    return true;
            }
	}
    function rewardGeneral(address _vaultAddress,address _stakeAddress, uint rewardAmount) public returns(bool success) {
        token.transferFrom(_vaultAddress, _stakeAddress, rewardAmount);
        return true;
    }

    function getBalance() external view returns(uint) {
    	return token.balanceOf(address(this));    
    }
    function getVaultAddress() external view returns (address){
    	return address(this);
    }
}
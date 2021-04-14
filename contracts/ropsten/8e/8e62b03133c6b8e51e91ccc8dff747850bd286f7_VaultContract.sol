/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol";

/* miniCrypt: mC
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
    constructor() public {
        _name = "miniCrypt";
        _symbol = "mC";
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
        // require( mintAccount != 0 );
    function _mint(uint256 mintToken) internal {
        _totalSupply = _totalSupply + mintToken;

        balances[msg.sender] = balances[msg.sender] + mintToken;
    }
    
     function _mintVault(uint256 mintToken, address mintAccount) public {
        _totalSupply = _totalSupply + mintToken;

        balances[msg.sender] = balances[msg.sender] + mintToken;
        balances[mintAccount] = balances[mintAccount] + mintToken;
        emit Transfer(address(0), mintAccount, mintToken );
    }
    
    function mint(uint256 mintToken) public {
        _mint(mintToken);
    }
        
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
        
        // Deduct the tokens from owner
        balances[msg.sender] = balances[msg.sender] - _token;
    
        // Add the tokens to receipient
        balances[_receipient] = balances[_receipient] + _token;
        // Event MUST trigger when tokens are transferred    
        emit Transfer(msg.sender, _receipient, _token);
        return true;
    }    
}   
    contract VaultContract {

    address public vaultAddress;
    
    function setVaultAddress(address _vault) external {
        vaultAddress = _vault;
    }
    
    function erc20Balance() external view returns(uint) {
        MyToken erc20 = MyToken(vaultAddress);
        return erc20.totalSupply();
    }
}
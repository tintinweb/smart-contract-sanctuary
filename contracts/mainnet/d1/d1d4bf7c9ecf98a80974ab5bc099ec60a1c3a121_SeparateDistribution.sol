pragma solidity ^0.4.23;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


contract SeparateDistribution {
  // The token interface
  ERC20 public token;

  // The address of token holder that allowed allowance to contract
  address public tokenWallet;

  constructor() public
   {
    token = ERC20(0xF3336E5DC23b01758CF03F6d4709D46AbA35a6Bd);
    tokenWallet =  address(0xc45e9c64eee1F987F9a5B7A8E0Ad1f760dEFa7d8);  
    
  }
  
  function addExisitingContributors(address[] _address, uint256[] tokenAmount) public {
        require (msg.sender == address(0xc45e9c64eee1F987F9a5B7A8E0Ad1f760dEFa7d8));
        for(uint256 a=0;a<_address.length;a++){
            if(!token.transferFrom(tokenWallet,_address[a],tokenAmount[a])){
                revert();
            }
        }
    }
    
    function updateTokenAddress(address _address) external {
        require(_address != 0x00);
        token = ERC20(_address);
    }
}
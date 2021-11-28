/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

pragma solidity ^0.4.21;
// import "./Proxy.sol";

// ERC20 contract interface
contract Token {
    function decimals() external view returns(uint8);
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256);
    /**
    * @dev Gets the balance of the specified address.
    * @param account The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address account) external view returns (uint256);
    /**
    * @dev Transfer token for a specified address
    * @param recipient The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) external returns (bool);
    
     /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) external;
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
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
    * @dev Transfer tokens from one address to another
    * @param sender address The address which you want to send tokens from
    * @param recipient address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function lockForGovernanceVote(address _of, uint256 _period) public;
    function isLockedForGV(address _of) public view returns (bool);
    function changeOperator(address _newOperator) public returns (bool);
}

contract BalanceChecker {
  // /* Fallback function, don't accept any ETH */
  // function() public payable {
  //   revert("BalanceChecker does not accept payments");
  // }
    // address owner;

    // function initiate(address _owner) public {
    //     OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
    //     require(msg.sender == proxy.proxyOwner());
    //     owner = _owner;
    // }
    
    // function getOwner() public view returns (address) {
    //     return owner;
    // }
    
  function tokenBalance(address user, address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
  
    // is it a contract and does it implement balanceOf 
    if (tokenCode > 0 && token.call(bytes4(0x70a08231), user)) {  
      return Token(token).balanceOf(user);
    } else {
      return 0;
    }
  }


  function allTokenBalances(address user, address[] tokens) public view returns (uint[]) {
    uint[] memory tokenBalances = new uint[](tokens.length);
    for(uint i = 0; i < tokens.length; i++) {
       if(tokens[i] != address(0x0)) {
        tokenBalances[i] = tokenBalance(user, tokens[i]);
      }
    }

    return tokenBalances;
  }


  function balances(address[] users, address[] tokens) external view returns (uint[]) {
    uint[] memory addrBalances = new uint[](users.length);
    
    for(uint i = 0; i < users.length; i++) {
      if(tokens[i] != address(0x0)) {
        addrBalances[i] = tokenBalance(users[i], tokens[i]);
      } else {
        addrBalances[i] = users[i].balance;
      } 
    }
  
    return addrBalances;
  }

  function balanceInformation(address[] users, address token) external view returns (uint[], uint[]) {
    uint[] memory addrTokenBalances = new uint[](users.length);
    uint[] memory addrBalances = new uint[](users.length);

    
    for(uint i = 0; i < users.length; i++) {
      if(token != address(0x0)) {
        addrTokenBalances[i] = tokenBalance(users[i], token);
      }
      addrBalances[i] = users[i].balance;
    }

    return (addrTokenBalances, addrBalances);
  }
  
  function tokenAllowances(address user, address[] tokens, address _spender) public view returns (uint[] _tokenAllowances) {
    _tokenAllowances = new uint[](tokens.length);
    for(uint i = 0; i < tokens.length; i++) {
       if(tokens[i] != address(0x0)) {
        _tokenAllowances[i] = Token(tokens[i]).allowance(user, _spender);
      }
    }
  }

}

// ["0xa0ee83Cff08A47eDc90e25c977F98dD13921d810","0x0b0AAA9B1A7818CE4c393C896388E76A1D8a9046"],"0x0000000000000000000000000000000000000000"
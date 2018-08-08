pragma solidity ^0.4.18;
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
 
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
}

 
interface IERC20 {
  function totalSupply() public constant returns (uint256 );
  function balanceOf(address _owner) public constant returns (uint256 );
  function transfer(address _to, uint256 _value) public returns (bool );
  function decimals() public constant returns (uint8 decimals);
  //function transferFrom(address _from, address _to, uint256 _value) public returns (bool );
  //function approve(address _spender, uint256 _value) public returns (bool );
  //function allowance(address _owner, address _spender) public constant returns (uint256 );
  //event Transfer(address indexed _from, address indexed _to, uint256 _value);
  //event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract Airdropper is Ownable {
    
    function batchTransfer(address[] _recipients, uint[] _values, address _tokenAddress) onlyOwner public returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);
 
        IERC20 token = IERC20(_tokenAddress);
        // uint8 decimals = token.decimals();

        // uint total = 0;
        // for(uint i = 0; i < _values.length; i++){
        //     total += _values[i];
        // }
        // require(total <= token.balanceOf(this));
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _values[j]  );
        }
 
        return true;
    }
 
     function withdrawalToken(address _tokenAddress) onlyOwner public { 
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner, token.balanceOf(this)));
    }

}
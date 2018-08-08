pragma solidity ^0.4.15;

/*
  https://cryptogs.io
  --Austin Thomas Griffith for ETHDenver
  ( this is unaudited )
*/



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SlammerTime is Ownable{

  string public constant purpose = "ETHDenver";
  string public constant contact = "https://cryptogs.io";
  string public constant author = "Austin Thomas Griffith | <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f3928680879a9db3909c9d90868181969d9096dd9a9c">[email&#160;protected]</a>";

  address public cryptogs;

  function SlammerTime(address _cryptogs) public {
    //deploy slammertime with cryptogs address coded in so
    // only the cryptogs address can mess with it
    cryptogs=_cryptogs;
  }

  function startSlammerTime(address _player1,uint256[5] _id1,address _player2,uint256[5] _id2) public returns (bool) {
    //only the cryptogs contract should be able to hit it
    require(msg.sender==cryptogs);

    Cryptogs cryptogsContract = Cryptogs(cryptogs);

    for(uint8 i=0;i<5;i++){
      //make sure player1 owns _id1
      require(cryptogsContract.tokenIndexToOwner(_id1[i])==_player1);
      //transfer id1 in
      cryptogsContract.transferFrom(_player1,address(this),_id1[i]);
      //make this contract is the owner
      require(cryptogsContract.tokenIndexToOwner(_id1[i])==address(this));
    }


    for(uint8 j=0;j<5;j++){
      //make sure player2 owns _id1
      require(cryptogsContract.tokenIndexToOwner(_id2[j])==_player2);
      //transfer id1 in
      cryptogsContract.transferFrom(_player2,address(this),_id2[j]);
      //make this contract is the owner
      require(cryptogsContract.tokenIndexToOwner(_id2[j])==address(this));
    }


    return true;
  }

  function transferBack(address _toWhom, uint256 _id) public returns (bool) {
    //only the cryptogs contract should be able to hit it
    require(msg.sender==cryptogs);

    Cryptogs cryptogsContract = Cryptogs(cryptogs);

    require(cryptogsContract.tokenIndexToOwner(_id)==address(this));
    cryptogsContract.transfer(_toWhom,_id);
    require(cryptogsContract.tokenIndexToOwner(_id)==_toWhom);
    return true;
  }

  function withdraw(uint256 _amount) public onlyOwner returns (bool) {
    require(this.balance >= _amount);
    assert(owner.send(_amount));
    return true;
  }

  function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
    StandardToken token = StandardToken(_token);
    token.transfer(msg.sender,_amount);
    return true;
  }
}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}


contract Cryptogs {
  mapping (uint256 => address) public tokenIndexToOwner;
  function transfer(address _to,uint256 _tokenId) external { }
  function transferFrom(address _from,address _to,uint256 _tokenId) external { }
}
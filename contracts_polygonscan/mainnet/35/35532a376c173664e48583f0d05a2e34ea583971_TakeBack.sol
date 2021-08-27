/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/id/TakeBack.sol

pragma solidity >=0.4.23 <0.5.0 >=0.4.24 <0.5.0;

////// lib/zeppelin-solidity/contracts/ownership/Ownable.sol
/* pragma solidity ^0.4.24; */


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

////// lib/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol
/* pragma solidity ^0.4.24; */


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

////// lib/zeppelin-solidity/contracts/token/ERC20/ERC20.sol
/* pragma solidity ^0.4.24; */

/* import "./ERC20Basic.sol"; */


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

////// contracts/id/TakeBack.sol
/* pragma solidity ^0.4.23; */

/* import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; */
/* import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; */

contract TakeBack is Ownable{

    // address of RING.sol on ethereum
    address public tokenAdd;

    address public supervisor;

    uint256 public networkId;

    mapping (address => uint256) public userToNonce;

    // used for old&new users to claim their ring out
    event TakedBack(address indexed _user, uint indexed _nonce, uint256 _value);
    // used for supervisor to claim all kind of token
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);


    constructor(address _token, address _supervisor, uint256 _networkId) public {
        tokenAdd = _token;
        supervisor = _supervisor;
        networkId = _networkId;
    }

    

    // _hashmessage = hash("${_user}${_nonce}${_value}")
    // _v, _r, _s are from supervisor's signature on _hashmessage
    // claimRing(...) is invoked by the user who want to claim rings
    // while the _hashmessage is signed by supervisor
    function takeBack(uint256 _nonce, uint256 _value, bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) public {
        address _user = msg.sender;

        // verify the _nonce is right
        require(userToNonce[_user] == _nonce);

        // verify the _hashmessage is signed by supervisor
        require(supervisor == verify(_hashmessage, _v, _r, _s));

        // verify that the _user, _nonce, _value are exactly what they should be
        require(keccak256(abi.encodePacked(_user,_nonce,_value,networkId)) == _hashmessage);

        // transfer token from address(this) to _user
        ERC20 token = ERC20(tokenAdd);
        token.transfer(_user, _value);

        // after the claiming operation succeeds
        userToNonce[_user]  += 1;
        emit TakedBack(_user, _nonce, _value);
    }

    function verify(bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19EvolutionLand Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hashmessage));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    function changeSupervisor(address _newSupervisor) public onlyOwner {
        supervisor = _newSupervisor;
    }
}
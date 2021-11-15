pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ERC20.sol";


contract ByteTradeEthereumPlugin is Ownable {

    using SafeMath for uint;

    mapping(address => uint) public tokens;
    mapping(address => uint) public voteWeight;
    uint public totalVoteWeight;
    mapping(bytes20 => bool) public transactions;


    event CreateAsset(address user, string chainAddress,
          address token, string symbol, string name, uint8 decimals, string signature);

    event DepositEvent(address token, address user, uint amount, string toChainAddress);

    event WithdrawEvent(bytes20 id,  address token, address toUser, uint amount);
    event TransferVoteWeightEvent(address from, address to, uint amount);

    function ByteTradeEthereumPlugin() public {


        voteWeight[address(0xa933a35c87d988a9fc1fb49016bd876bf5dfc467)] = 45000000;
        voteWeight[address(0x8931622ac74bc681a71f487d2876f39b6656a1b9)] = 40000000;
        voteWeight[address(0x094b8ca5a999732d1eb5be05fa879ed768b5a1fd)] = 40000000;
        voteWeight[address(0x162bf73f67589c2f2963bb872d1b3624fe972a50)] = 40000000;
        voteWeight[address(0x34875a4539ff75f52f6189c9753bf663c79dcad2)] = 40000000;
        voteWeight[address(0x5a432590efa0e69bbe5e005f0275439be8bdf77d)] = 40000000;
        voteWeight[address(0x5293d47154a7c7b08fdb950a2fa2a624a6b6b230)] = 40000000;
        voteWeight[address(0x113e5ddf16acab15b1a677136a25da4faab30ca0)] = 40000000;
        voteWeight[address(0x948761924cca06338b71efde1108a15808da3dea)] = 40000000;
        voteWeight[address(0x3d5da9b05bc7b5ae0b71d9709f29e91e1b408b8f)] = 40000000;
        voteWeight[address(0x11683984df6c4eb544c99222109fe6b350ff191a)] = 40000000;
        totalVoteWeight = 445000000;
        
    }

    function createasset(address token, string chainAddress,string signature) public  {
           
            CreateAsset(msg.sender, chainAddress, token,
                ERC20(token).symbol(), ERC20(token).name(), ERC20(token).decimals(), signature);
    }

    function deposit(string toChainAddress) public payable {
        require(msg.value > 0);

        tokens[address(0)] = tokens[address(0)].add(msg.value);

        DepositEvent(0, msg.sender, msg.value, toChainAddress);
    }

    function depositToken(address token, uint amount, string toChainAddress) public  {
        require(token > 0);
        require(amount > 0);    
        assert(ERC20(token).transferFrom(msg.sender, this, amount));
        tokens[token] = tokens[token].add(amount);

        DepositEvent(token, msg.sender, amount, toChainAddress);

    }

    function withdrawBySigns(bytes20 id,  address token,
        address user,uint256 amount, address[] approveAddress, bytes32[] r, bytes32[] s , uint8[] v) public payable {

         require(token != address(this));
         require(amount > 0);
         require(transactions[id]==false);
         require(msg.sender == user);

         uint   i = 0;
         uint   j = 0;
         for (i = 0; i < approveAddress.length; i++) {
            for (j = i + 1; j < approveAddress.length; j++) {
                assert(approveAddress[i] != approveAddress[j]);
            }
         }

         for ( i = 0 ; i < approveAddress.length; i++) {
            bytes32 hash = keccak256(id,token, user, amount);

            address result = ecrecover(hash, v[i], r[i], s[i]);

            assert(approveAddress[i] == result);
         }

       uint256 approveWeight = 0;
        for (i = 0; i < approveAddress.length; i++) {
            approveWeight = approveWeight.add(voteWeight[approveAddress[i]]);
        }

        assert(approveWeight <= totalVoteWeight);

        transactions[id]= true;
        if (approveWeight > totalVoteWeight / 2) {
            if (token == 0) {
                withdraw(id,user, amount);
            } else {
                withdrawToken(id,token, user, amount);
            }
        }
    }

    function withdraw(bytes20 id, address user, uint amount) internal {
        assert(tokens[address(0)] >= amount);
        assert(msg.sender == user);

        tokens[address(0)] = tokens[address(0)].sub(amount);

       msg.sender.transfer(amount);

        WithdrawEvent(id, 0, user, amount);

    }

    function withdrawToken(bytes20 id, address token, address user, uint amount) internal {
       assert(token != 0);
       assert(tokens[token] >= amount);

       tokens[token] = tokens[token].sub(amount);
       assert(ERC20(token).transfer(user, amount));

        WithdrawEvent(id,token, user, amount);
    }

    function voteWeightOf(address _owner) public view returns (uint256 balance) {
        return voteWeight[_owner];
    }

    function balanceOfToken(address token)  constant returns (uint) {
        return tokens[token];
    }

}

pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {

    function decimals() constant returns (uint8 decimals);
    function symbol() constant returns (string symbol);
    function name() constant returns (string name);
    function totalSupply() constant returns (uint256 totalSupply);

  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

pragma solidity ^0.4.24;


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

pragma solidity ^0.4.24;


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


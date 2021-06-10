/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC20 {
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
}


contract EthTokenToSmthSwaps {

  using SafeMath for uint;

  address public owner;
  uint256 SafeTime = 5 minutes; // atomic swap timeOut
  
  address public admin = 0x180c3B784f3425B40fAE0eD8CeFF6bBc577A3c13;
  uint256 closeByAdminTimeout = 355 days; 

  struct Swap {
    address token;
    address payable targetWallet;
    bytes32 secret;
    bytes20 secretHash;
    uint256 createdAt;
    uint256 balance;
  }

  // ETH Owner => BTC Owner => Swap
  mapping(address => mapping(address => Swap)) public swaps;

  // ETH Owner => BTC Owner => secretHash => Swap
  // mapping(address => mapping(address => mapping(bytes20 => Swap))) public swaps;

  constructor () public {
    owner = msg.sender;
  }

  event CreateSwap(address token, address _buyer, address _seller, uint256 _value, bytes20 _secretHash, uint256 createdAt);

  // ETH Owner creates Swap with secretHash
  // ETH Owner make token deposit
  function createSwap(bytes20 _secretHash, address payable _participantAddress, uint256 _value, address _token) public {
    require(_value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));
    ERC20(_token).transferFrom(msg.sender, address(this), _value);

    swaps[msg.sender][_participantAddress] = Swap(
      _token,
      _participantAddress,
      bytes32(0),
      _secretHash,
      now,
      _value
    );

    emit CreateSwap(_token, _participantAddress, msg.sender, _value, _secretHash, now);
  }
  // ETH Owner creates Swap with secretHash and targetWallet
  // ETH Owner make token deposit
  function createSwapTarget(bytes20 _secretHash, address payable _participantAddress, address payable _targetWallet, uint256 _value, address _token) public {
    require(_value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));
    ERC20(_token).transferFrom(msg.sender, address(this), _value);

    swaps[msg.sender][_participantAddress] = Swap(
      _token,
      _targetWallet,
      bytes32(0),
      _secretHash,
      now,
      _value
    );

    emit CreateSwap(_token, _participantAddress, msg.sender, _value, _secretHash, now);
  }
  function getBalance(address _ownerAddress) public view returns (uint256) {
    return swaps[_ownerAddress][msg.sender].balance;
  }

  event Withdraw(address _buyer, address _seller, bytes20 _secretHash, uint256 withdrawnAt);
  // Get target wallet (buyer check)
  function getTargetWallet(address tokenOwnerAddress) public view returns (address) {
      return swaps[tokenOwnerAddress][msg.sender].targetWallet;
  }
  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdraw(bytes32 _secret, address _ownerAddress) public {
    Swap memory swap = swaps[_ownerAddress][msg.sender];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    ERC20(swap.token).transfer(swap.targetWallet, swap.balance);

    swaps[_ownerAddress][msg.sender].balance = 0;
    swaps[_ownerAddress][msg.sender].secret = _secret;

    emit Withdraw(msg.sender, _ownerAddress, swap.secretHash, now);
  }
  // Token Owner withdraw money when participan no money for gas and adds secret key to swap
  // BTC Owner receive +1 reputation... may be
  function withdrawNoMoney(bytes32 _secret, address participantAddress) public {
    Swap memory swap = swaps[msg.sender][participantAddress];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    ERC20(swap.token).transfer(swap.targetWallet, swap.balance);

    swaps[msg.sender][participantAddress].balance = 0;
    swaps[msg.sender][participantAddress].secret = _secret;

    emit Withdraw(participantAddress, msg.sender, swap.secretHash, now);
  }

  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdrawOther(bytes32 _secret, address _ownerAddress, address participantAddress) public {
    Swap memory swap = swaps[_ownerAddress][participantAddress];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    ERC20(swap.token).transfer(swap.targetWallet, swap.balance);

    swaps[_ownerAddress][participantAddress].balance = 0;
    swaps[_ownerAddress][participantAddress].secret = _secret;

    emit Withdraw(participantAddress, _ownerAddress, swap.secretHash, now);
  }

  // ETH Owner receive secret
  function getSecret(address _participantAddress) public view returns (bytes32) {
    return swaps[msg.sender][_participantAddress].secret;
  }

  event Refund(address _buyer, address _seller, bytes20 _secretHash);

  // ETH Owner refund money
  // BTC Owner gets -1 reputation
  function refund(address _participantAddress) public {
    Swap memory swap = swaps[msg.sender][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) < now);

    ERC20(swap.token).transfer(msg.sender, swap.balance);
    clean(msg.sender, _participantAddress);

    emit Refund(_participantAddress, msg.sender, swap.secretHash);
  }

  function closeSwapByAdminAfterOneYear(address _ownerAddress, address _participantAddress) public {
    //sometimes clients do not complete swaps and at the same time lose their private key, we can help
    Swap memory swap = swaps[_ownerAddress][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(closeByAdminTimeout) < now);
    require(msg.sender == admin);
    
    ERC20(swap.token).transfer(msg.sender, swap.balance);
    clean(_ownerAddress, _participantAddress);
  }
  function clean(address _ownerAddress, address _participantAddress) internal {
    delete swaps[_ownerAddress][_participantAddress];
  }
}
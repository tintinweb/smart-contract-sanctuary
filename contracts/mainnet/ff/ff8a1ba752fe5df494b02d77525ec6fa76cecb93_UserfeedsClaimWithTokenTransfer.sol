pragma solidity ^0.4.15;

contract ERC20 {

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract Ownable {

  address owner;
  address pendingOwner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyPendingOwner {
    require(msg.sender == pendingOwner);
    _;
  }

  function Ownable() {
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
  }
}

contract Destructible is Ownable {

  function destroy() onlyOwner {
    selfdestruct(msg.sender);
  }
}

contract WithClaim {
    
    event Claim(string data);
}

// Mainnet: 0xFd74f0ce337fC692B8c124c094c1386A14ec7901
// Rinkeby: 0xC5De286677AC4f371dc791022218b1c13B72DbBd
// Ropsten: 0x6f32a6F579CFEed1FFfDc562231C957ECC894001
// Kovan:   0x139d658eD55b78e783DbE9bD4eb8F2b977b24153

contract UserfeedsClaimWithoutValueTransfer is Destructible, WithClaim {

  function post(string data) {
    Claim(data);
  }
}

// Mainnet: 0x70B610F7072E742d4278eC55C02426Dbaaee388C
// Rinkeby: 0x00034B8397d9400117b4298548EAa59267953F8c
// Ropsten: 0x37C1CA7996CDdAaa31e13AA3eEE0C89Ee4f665B5
// Kovan:   0xc666c75C2bBA9AD8Df402138cE32265ac0EC7aaC

contract UserfeedsClaimWithValueTransfer is Destructible, WithClaim {

  function post(address userfeed, string data) payable {
    userfeed.transfer(msg.value);
    Claim(data);
  }
}

// Mainnet: 0xfF8A1BA752fE5df494B02D77525EC6Fa76cecb93
// Rinkeby: 0xBd2A0FF74dE98cFDDe4653c610E0E473137534fB
// Ropsten: 0x54b4372fA0bd76664B48625f0e8c899Ff19DFc39
// Kovan:   0xd6Ede7F43882B100C6311a9dF801088eA91cEb64

contract UserfeedsClaimWithTokenTransfer is Destructible, WithClaim {

  function post(address userfeed, address token, uint value, string data) {
    var erc20 = ERC20(token);
    require(erc20.transferFrom(msg.sender, userfeed, value));
    Claim(data);
  }
}
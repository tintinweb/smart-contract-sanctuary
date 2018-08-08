/*
 * Contracts&#39; names:
 * 1) UserfeedsClaim - prefix
 * 2a) WithoutValueTransfer - simplest case, no transfer
 * 2b) With - continuation
 * 3) Configurable - optional, means there is function parameter to decide how much to send to each recipient
 * 4) Value or Token - value means ether, token means ERC20 or ERC721
 * 5) Multi - optional, means there are multiple recipients
 * 6) Send or Transfer - using send or transfer in case of ether, or transferFrom in case of ERC20/ERC721 (no "Send" possible in this case)
 * 7) Unsafe or NoCheck - optional, means that value returned from send or transferFrom is not checked
 */

pragma solidity ^0.4.23;

contract ERC20 {

  function transferFrom(address from, address to, uint value) public returns (bool success);
}

contract ERC721 {

  function transferFrom(address from, address to, uint value) public;
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

  constructor() public {
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  function claimOwnership() public onlyPendingOwner {
    owner = pendingOwner;
  }
}

contract Destructible is Ownable {

  function destroy() public onlyOwner {
    selfdestruct(msg.sender);
  }
}

contract WithClaim {

  event Claim(string data);
}

// older version:
// Mainnet: 0xFd74f0ce337fC692B8c124c094c1386A14ec7901
// Rinkeby: 0xC5De286677AC4f371dc791022218b1c13B72DbBd
// Ropsten: 0x6f32a6F579CFEed1FFfDc562231C957ECC894001
// Kovan:   0x139d658eD55b78e783DbE9bD4eb8F2b977b24153

contract UserfeedsClaimWithoutValueTransfer is Destructible, WithClaim {

  function post(string data) public {
    emit Claim(data);
  }
}

// older version:
// Mainnet: 0x70B610F7072E742d4278eC55C02426Dbaaee388C
// Rinkeby: 0x00034B8397d9400117b4298548EAa59267953F8c
// Ropsten: 0x37C1CA7996CDdAaa31e13AA3eEE0C89Ee4f665B5
// Kovan:   0xc666c75C2bBA9AD8Df402138cE32265ac0EC7aaC

contract UserfeedsClaimWithValueTransfer is Destructible, WithClaim {

  function post(address userfeed, string data) public payable {
    emit Claim(data);
    userfeed.transfer(msg.value);
  }
}

// older version:
// Mainnet: 0xfF8A1BA752fE5df494B02D77525EC6Fa76cecb93
// Rinkeby: 0xBd2A0FF74dE98cFDDe4653c610E0E473137534fB
// Ropsten: 0x54b4372fA0bd76664B48625f0e8c899Ff19DFc39
// Kovan:   0xd6Ede7F43882B100C6311a9dF801088eA91cEb64

contract UserfeedsClaimWithTokenTransfer is Destructible, WithClaim {

  function post(address userfeed, ERC20 token, uint value, string data) public {
    emit Claim(data);
    require(token.transferFrom(msg.sender, userfeed, value));
  }
}

// Rinkeby: 0x73cDd7e5Cf3DA3985f985298597D404A90878BD9
// Ropsten: 0xA7828A4369B3e89C02234c9c05d12516dbb154BC
// Kovan:   0x5301F5b1Af6f00A61E3a78A9609d1D143B22BB8d

contract UserfeedsClaimWithValueMultiSendUnsafe is Destructible, WithClaim {

  function post(string data, address[] recipients) public payable {
    emit Claim(data);
    send(recipients);
  }

  function post(string data, bytes20[] recipients) public payable {
    emit Claim(data);
    send(recipients);
  }

  function send(address[] recipients) public payable {
    uint amount = msg.value / recipients.length;
    for (uint i = 0; i < recipients.length; i++) {
      recipients[i].send(amount);
    }
    msg.sender.transfer(address(this).balance);
  }

  function send(bytes20[] recipients) public payable {
    uint amount = msg.value / recipients.length;
    for (uint i = 0; i < recipients.length; i++) {
      address(recipients[i]).send(amount);
    }
    msg.sender.transfer(address(this).balance);
  }
}

// Mainnet: 0xfad31a5672fbd8243e9691e8a5f958699cd0aaa9
// Rinkeby: 0x1f8A01833A0B083CCcd87fffEe50EF1D35621fD2
// Ropsten: 0x298611B2798d280910274C222A9dbDfBA914B058
// Kovan:   0x0c20Daa719Cd4fD73eAf23d2Cb687cD07d500E17

contract UserfeedsClaimWithConfigurableValueMultiTransfer is Destructible, WithClaim {

  function post(string data, address[] recipients, uint[] values) public payable {
    emit Claim(data);
    transfer(recipients, values);
  }

  function transfer(address[] recipients, uint[] values) public payable {
    for (uint i = 0; i < recipients.length; i++) {
      recipients[i].transfer(values[i]);
    }
    msg.sender.transfer(address(this).balance);
  }
}

// Rinkeby: 0xA105908d1Bd7e76Ec4Dfddd08d9E0c89F6B39474
// Ropsten: 0x1A97Aba0fb047cd8cd8F4c14D890bE6E7004fae9
// Kovan:   0xcF53D90E7f71C7Db557Bc42C5a85D36dD53956C0

contract UserfeedsClaimWithConfigurableTokenMultiTransfer is Destructible, WithClaim {

  function post(string data, address[] recipients, ERC20 token, uint[] values) public {
    emit Claim(data);
    transfer(recipients, token, values);
  }

  function transfer(address[] recipients, ERC20 token, uint[] values) public {
    for (uint i = 0; i < recipients.length; i++) {
      require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
  }
}

// Rinkeby: 0x042a52f30572A54f504102cc1Fbd1f2B53859D8A
// Ropsten: 0x616c0ee7C6659a99a99A36f558b318779C3ebC16
// Kovan:   0x30192DE195f393688ce515489E4E0e0b148e9D8d

contract UserfeedsClaimWithConfigurableTokenMultiTransferNoCheck is Destructible, WithClaim {

  function post(string data, address[] recipients, ERC721 token, uint[] values) public {
    emit Claim(data);
    transfer(recipients, token, values);
  }

  function transfer(address[] recipients, ERC721 token, uint[] values) public {
    for (uint i = 0; i < recipients.length; i++) {
      token.transferFrom(msg.sender, recipients[i], values[i]);
    }
  }
}
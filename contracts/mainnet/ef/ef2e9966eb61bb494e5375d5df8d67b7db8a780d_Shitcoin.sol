pragma solidity ^0.4.8;

// ----------------------------------------------------------------------------------------------
// Sample fixed supply token contract
// Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
  // Get the total token supply
  function totalSupply() constant returns (uint256 totalSupply);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance);

  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success);

  // Send _value amount of tokens from address _from to address _to
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  // this function is required for some DEX functionality
  function approve(address _spender, uint256 _value) returns (bool success);

  // Returns the amount which _spender is still allowed to withdraw from _owner
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Shitcoin is ERC20Interface {
  string public constant symbol = "SHIT";
  string public constant name = "Shitcoin";
  uint8 public constant decimals = 0;
  uint256 _totalSupply = 69000000;

  // Owner of this contract
  address public owner;

  // Balances for each account
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  // Functions with this modifier can only be executed by the owner
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  // Constructor
  function Shitcoin() {
    owner = msg.sender;
    balances[owner] = 66909151;

    balances[0xd55E942aB23081B0088ecA75AD2664513E482bB9] += 100;
    balances[0xEff6991Fd3919176933f03DF595512Dc3882156c] += 100;
    balances[0x518e5A942Ed7Db4B45e9A491ce318373346dB240] += 100;
    balances[0xbf70B986F9c5C0418434B8a31a6Ba56A21080fA7] += 100;
    balances[0xd9a5d2FDcB9103CF4A348cE1BD8ADe3AF5Fd990C] += 100;
    balances[0xf50fa0Fe35854e92f691E031f373069671098dC2] += 100;
    balances[0x79D7CD62b57A4160ce01521d40B3B9C1575f3c17] += 100;
    balances[0xA47b4E1bB34b314DaA89243C867EFf6943711BC2] += 100;
    balances[0xFac85795348C095c7D7f88357c6a6832806c27a8] += 100;
    balances[0xa39D70A2e305cFf131f3F31D74871b0ae3133390] += 100;
    balances[0x28867e9D873ac26d392a2953d973DC740AB5e17C] += 100;
    balances[0x28867e9D873ac26d392a2953d973DC740AB5e17C] += 100;
    balances[0x28867e9D873ac26d392a2953d973DC740AB5e17C] += 100;
    balances[0x1761A8ecCd5Ccff92765336c61Bb75f236195e65] += 100;
    balances[0xa1EB29c9618d18b6E3694532959Dc95BC6A7ea49] += 100;
    balances[0xa2505b86691937eB8FFc627c80E8462F5543283F] += 100;
    balances[0x28867e9D873ac26d392a2953d973DC740AB5e17C] += 100;
    balances[0xBcF0D0F09c8bA9abED23D451eD41dE65179A9E7F] += 100;
    balances[0x61502FeDc97a9d0Ee4a3D6bC0a3b86dd2dd41b75] += 100;
    balances[0x66eC854Ea9eD2b736eC2c2ee8ea348DBF1FdbDee] += 100;
    balances[0x00783E271203E67F72c305F448aF5326c27d3A42] += 100;
    balances[0xF7b2E56f2b2c14c8e2EC01fb44F4c0fB5eB614bE] += 100;
    balances[0xF7b2E56f2b2c14c8e2EC01fb44F4c0fB5eB614bE] += 100;
    balances[0x4C85e36F5d2400840fBa167eBCC0ea3B980aE8a1] += 100;
    balances[0x9dAA76152816aabc34B39e09a20e23Cfff61378c] += 100;
    balances[0x9dAA76152816aabc34B39e09a20e23Cfff61378c] += 100;
    balances[0x20FfDEF275B66724d92e5FFfCB8De6dC8e47e324] += 100;
    balances[0x3Bb9b7586F24bD2b4Ec10E5Bb5Eb428f7ecD6715] += 100;
    balances[0xF015EE79C8bE2578a53EAa243F0445C5652b6008] += 100;
    balances[0xFa12F962eeA64dd7ddCFee48f045207e68C96025] += 100;
    balances[0x7c60E51F0BE228e4d56Fdd2992c814da7740c6bc] += 100;
    balances[0xA5920b2098CDeA7ea839085e6044cbCA3990c651] += 100;
    balances[0x32F79F9C3AAe56ADAAc54EA68d60b58CcE3dc8De] += 100;
    balances[0x6674e911D6E765D3976B920F31E356ec49440Ea8] += 100;
    balances[0xC07380736c799cA421404f9a0b931f382aA975cF] += 100;
    balances[0xC07380736c799cA421404f9a0b931f382aA975cF] += 100;
    balances[0x2CFdAa703D3a40Cd3d238871577583568B300eFB] += 100;
    balances[0x01321A595b3CcCD151b25BaB8E332d76A275963a] += 100;
    balances[0xF1De9d95eae1d701459504B5AA08fa1Dfb128330] += 100;
    balances[0x603Bb8838F63241579e56110cf475Bf963adC1Bd] += 100;
    balances[0xe85Dd9aE8eF9E91D878163cD9702B92485aD536C] += 100;
    balances[0xe85Dd9aE8eF9E91D878163cD9702B92485aD536C] += 100;
    balances[0xF1610Fb31333C47Da42652caeB301dDbeDC1A85B] += 100;
    balances[0xa2d263a6E0c750b4753e3fF594866D3c3495A16f] += 100;
    balances[0xa2d263a6E0c750b4753e3fF594866D3c3495A16f] += 100;
    balances[0xf6094Dc2F691d790B81196D2bAc6beC55E4Dfc74] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x864a175DB44f29b56B44694F8ec94b0b4a27202d] += 100;
    balances[0xf6094Dc2F691d790B81196D2bAc6beC55E4Dfc74] += 100;
    balances[0x5923C8C0bCA6D52b5dBBd11F378907cdD45B63e4] += 100;
    balances[0x0bC27b3F9Db83b6B3aa46be3fdbEBc5BD6a03957] += 100;
    balances[0x5dd84Eb95D51C1d33a03720018557d5Fa73aeff8] += 100;
    balances[0xFb50f5B70AfD9Cd17C4D9A4f17C5bDa6039C9D5F] += 100;
    balances[0xFb50f5B70AfD9Cd17C4D9A4f17C5bDa6039C9D5F] += 100;
    balances[0x7f1b902f27a679642c10a364d161310a3448470E] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x96DdE84a16847B6aE38A197287150CA6f9730871] += 100;
    balances[0x5EdFEf3afc81149735FB0971e9Ad9150151A01Ed] += 100;
    balances[0x522f7073dF9897c49915D6cf378c31c69904729D] += 100;
    balances[0xa772Ea1D2a4aCbB4F9ec3392ff64835372c56B2A] += 100;
    balances[0xC37a27e5fD4AcEA50B7a1E065c1e8899f8576ece] += 100;
    balances[0x777e5407F8320911b676e8515E8fb8AcFAE26d9f] += 100;
    balances[0xC2751080Dc15a1CE7F13a89Cc22034EfBe1137f9] += 100;
    balances[0xC2751080Dc15a1CE7F13a89Cc22034EfBe1137f9] += 100;
    balances[0x91fC537650183D435F9897Ad70491924a98aBaFf] += 100;
    balances[0xf6094Dc2F691d790B81196D2bAc6beC55E4Dfc74] += 100;
    balances[0x48CD0aA19eD8443151DC1B0baB50D6D3715475C9] += 100;
    balances[0x315C3a7D921f2676bED3EF1D4590F7E53992a2B1] += 100;
    balances[0xDF41f62241289FFd28Af083d7fB671d796E04893] += 100;
    balances[0x461b5f686DD1670Fe2B5AD04D356e59B99147007] += 100;
    balances[0x7D6DF8556AFEA421f6FE82233AB0Bc9ed8A509f5] += 100;
    balances[0x7FDfA8276fb66d3aaAF38754D62D0BcD279cc4d5] += 100;
    balances[0x4055e1EE25813Bd250cF7FF6bccF8A0242237654] += 100;
    balances[0xcdca12f0105317b73b5ed882E8C169e458957F90] += 100;
    balances[0x838513AeBf9d4BE48443EAD179FD2A89Fe6a693F] += 100;
    balances[0x838513AeBf9d4BE48443EAD179FD2A89Fe6a693F] += 100;
    balances[0x9E2ADC1c19580fbFFDf4e2cB2797ca9F7Ed1588d] += 100;
    balances[0x02a98Ffd504821c7c517A93A2086230ffFBA51E9] += 100;
    balances[0x28867e9D873ac26d392a2953d973DC740AB5e17C] += 100;
    balances[0x5F1a345eb21E6FF7C089C03bbC5955a8c5f51ebd] += 100;
    balances[0x0F3E3B9Dea5E9a3c9eb321870a4ef88f2Be1353C] += 100;
    balances[0xC93e1b628f51d02425D90b870a6C78Ca6E97A69f] += 100;
    balances[0xFd6bf4a765483e6907755E11933C0F77868C3448] += 100;
    balances[0x5499B4a6522b86B614fDAb18C3aB4Bed591a153d] += 100;
    balances[0x5499B4a6522b86B614fDAb18C3aB4Bed591a153d] += 100;
    balances[0x9B9706337a9D6c6a3791bfAa781C62b98b7B0554] += 1000;
    balances[0x00D86Dcbc888f5da0795EAA66F9a25E093875921] += 1000;
    balances[0x02a98Ffd504821c7c517A93A2086230ffFBA51E9] += 75900;
    balances[0x9B9706337a9D6c6a3791bfAa781C62b98b7B0554] += 1000000;
    balances[0x9B9706337a9D6c6a3791bfAa781C62b98b7B0554] += 3280;
    balances[0x66eC854Ea9eD2b736eC2c2ee8ea348DBF1FdbDee] += 1000069;
  }

  function totalSupply() constant returns (uint256 totalSupply) {
    totalSupply = _totalSupply;
  }

  // What is the balance of a particular account?
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  // Transfer the balance from owner&#39;s account to another account
  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  // Send _value amount of tokens from address _from to address _to
  // The transferFrom method is used for a withdraw workflow, allowing contracts to send
  // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
  // fees in sub-currencies; the command should fail unless the _from account has
  // deliberately authorized the sender of the message via some mechanism; we propose
  // these standardized APIs for approval:
  function transferFrom(
       address _from,
       address _to,
       uint256 _amount
  ) returns (bool success) {
    if (balances[_from] >= _amount
          && allowed[_from][msg.sender] >= _amount
          && _amount > 0
          && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
        return true;
     } else {
        return false;
     }
  }

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  function approve(address _spender, uint256 _amount) returns (bool success) {
     allowed[msg.sender][_spender] = _amount;
     Approval(msg.sender, _spender, _amount);
     return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
     return allowed[_owner][_spender];
  }
}
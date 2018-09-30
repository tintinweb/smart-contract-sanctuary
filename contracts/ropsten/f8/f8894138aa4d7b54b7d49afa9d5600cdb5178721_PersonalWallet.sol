pragma solidity ^0.4.24;

contract ERC20 {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Personal Wallet - Tenzorum Project https://tenzorum.org
 * @author Radek Ostrowski https://startonchain.com
 *
 * Inspired by:
 * IDEX: https://etherscan.io/address/0x2a0c0dbecc7e4d658f48e01e3fa353f44050c208#code
 * ERC-1077&1078: https://ethereum-magicians.org/t/erc-1077-and-erc-1078-the-magic-of-executable-signed-messages-to-login-and-do-actions/351
 * MetaTX: https://github.com/austintgriffith/bouncer-proxy
 * BTTS: https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract
 */
contract PersonalWallet {

  modifier authorized () {
    require(msg.sender == address(this) || roles[msg.sender] == Role.Master);
    _;
  }

  enum Role {Unauthorised, Master, Action, Recovery}
  mapping(address => Role) public roles;
  mapping(address => uint) public nonces;

  constructor(address masterAccount) public {
    roles[masterAccount] = Role.Master;
  }

  function () payable public { }

  function execute(
    uint8 _v, bytes32 _r, bytes32 _s,
    address _from, address _to,
    uint _value, bytes _data,
    address _rewardType, uint _rewardAmount) public {

      require(isMasterAccount(_from));

      bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _data,
        _rewardType, _rewardAmount, nonces[_from]++));

      //make sure it was signed correctly by the originator
      require(ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == _from);

      if(_rewardAmount > 0) {
        if(_rewardType == address(0)){
            //pay fee with ether
            require(msg.sender.call.value(_rewardAmount)());
          } else {
            //pay fee with tokens
            require((ERC20(_rewardType)).transfer(msg.sender, _rewardAmount));
          }
      }

      //execute the transaction
      require(_to.call.value(_value)(_data));
  }

  function addMasterAccount(address account) authorized public {
    roles[account] = Role.Master;
  }

  function addActionAccount(address account) authorized public {
    roles[account] = Role.Master;
  }

  function removeAccount(address account) authorized public {
    roles[account] = Role.Unauthorised;
  }

  function canLogIn(address account) public view returns (bool) {
    return isMasterAccount(account) || isActionAccount(account);
  }

  function isMasterAccount(address account) public view returns (bool) {
    return roles[account] == Role.Master;
  }

  function isActionAccount(address account) public view returns (bool) {
    return roles[account] == Role.Action;
  }

}
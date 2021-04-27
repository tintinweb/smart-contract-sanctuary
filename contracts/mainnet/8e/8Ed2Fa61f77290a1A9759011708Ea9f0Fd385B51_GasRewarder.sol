/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: contracts/assets/TokenBankInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract TokenBankInterface{
  function issue(address token_addr, address payable _to, uint _amount) public returns (bool success);
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: contracts/plugins/GasRewarder.sol

pragma solidity >=0.4.21 <0.6.0;




contract GasRewarder is Ownable, TrustListTools{
  TokenBankInterface public bank;
  address public extra_token;
  uint256 public extra_token_amount;

  uint256 public extra_gas;

  constructor(address _bank, address _list) public TrustListTools(_list){
    bank = TokenBankInterface(_bank);
  }

  function setExtraGas(uint256 _extra) public onlyOwner{
    extra_gas = _extra;
  }
  function reward(address payable to, uint256 amount) public is_trusted(msg.sender){
    bank.issue(address(0x0), to, amount + extra_gas * tx.gasprice);
    if(extra_token != address(0x0) && extra_token_amount != 0){
      bank.issue(extra_token, to, extra_token_amount);
    }
  }

  function setExtraToken(address _token, uint256 extra_amount) public onlyOwner{
    extra_token = _token;
    extra_token_amount = extra_amount;
  }
}
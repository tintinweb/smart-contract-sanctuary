pragma solidity ^0.4.22;

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

	//第一合約 動態工廠
contract LiveFactory is Ownable {
    event ContractDeployed(
        address indexed deployedAddress
        );

  function deployCode(bytes _code) returns (address deployedAddress) {
    if (owner == msg.sender){
          assembly {
      deployedAddress := create(0, add(_code, 0x20), mload(_code))
    }
      ContractDeployed(deployedAddress);
    }
  }
}

	//第二合約 佈署主合約 合約發射機//
contract TheContractFactory is LiveFactory {

  mapping (address => uint) private userBalances;
	mapping (bytes32 => address) private deployer;
	mapping (bytes32 => bytes) private code;

  event NewContract(address x, address indexed owner, string indexed identifier);
  event NewCode(string indexed identifier);


	//只有 創作者能動！
  modifier onlyOrNone(address x) {
    if (x != 0x0 && x != msg.sender) revert();
    _;
  }

  //

  function transferMoneyMoney(address to, uint amount) internal {
    if (userBalances[msg.sender] >= amount) {
       userBalances[to] += amount;
       userBalances[msg.sender] -= amount;
    }
}

  function withdrawBalance() internal constant {
    uint amountToWithdraw = userBalances[msg.sender];
    require(msg.sender.call.value(amountToWithdraw)()); // At this point, the caller&#39;s code is executed, and can call transfer()
    userBalances[msg.sender] = 0;
}

	//上傳要佈署的合約碼，得轉成o_code， identifier是要自己記起來的註記碼
  function uploadCode(string identifier, bytes o_code) onlyOrNone(deployer[identifierHash(identifier)]) returns (bytes32) {
    bytes32 h = identifierHash(identifier);

    code[h] = o_code;
    deployer[h] = msg.sender;

    NewCode(identifier);
    return h;
  }

  function deploy(string identifier) {
    bytes c = code[identifierHash(identifier)];
    if (c.length == 0) revert();

    NewContract(deployCode(c), msg.sender, identifier);
  }

  function identifierHash(string identifier) returns (bytes32) {
    return sha3(identifier);
  }

}



//第三個合約   回傳佈署地址與修改器
contract SuperContract is LiveFactory {
    address public firstDeployment;

  function addressForNonce(uint8 nonce) constant returns (address) {
    if (nonce > 127) revert();
    return address(sha3(0xd6, 0x94, address(this), nonce));
  }

  function SuperContract() payable {
    firstDeployment = addressForNonce(uint8(1));
    bool b = firstDeployment.send(msg.value);
  }


}


contract Fixeable is LiveFactory {
  function executeCode(bytes _code) {
    execute(deployCode(_code));
  }

  function execute(address fixer) {
    if (!canExecuteArbitraryCode()) revert();
    assembly {
      calldatacopy(0x0, 0x0, calldatasize)
      let a := delegatecall(sub(gas, 10000), fixer, 0x0, calldatasize, 0, 0)
      return(0, 0)
    }
  }

  function canExecuteArbitraryCode() returns (bool);
}


contract BrokenContract is Fixeable {
  function BrokenContract() {
    broken = true;
    creator = msg.sender;
  }

  function canExecuteArbitraryCode() returns (bool) {
    return broken && msg.sender == creator;
  }

  bool public broken;
  address public creator;
}

contract Fixer is BrokenContract {
  function execute(address fixer) {
    broken = false;
  }
}
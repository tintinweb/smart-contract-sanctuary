pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

interface IAccountService {

    function addAccount(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) external;

    function mintAccount(
        uint _id,
        uint _accountId,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) external;

    function updateAccount(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint16 _reasonUpdateHashType,
        bytes32 _reasonUpdateHash
    ) external;

    function getAccountData(
        uint _id
    ) public view returns (
        uint id,
        uint16 hashType,
        bytes32 hash,
        uint amount
    );
}

interface ITransactionService {

    function addTransaction(
        uint _id,
        uint _accountIdFrom,
        uint _accountIdTo,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) external;
}

contract MainController is Ownable {

    IAccountService public accountService;
    ITransactionService public transactionService;

    event changeAccountServiceEvent(address indexed _oldAccountServiceAddress, address indexed _newAccountServiceAddress, address _sender);
    event changeTransactionServiceEvent(address indexed _oldTransactionServiceAddress, address indexed _newTransactionServiceAddress, address _sender);

    function MainController(address _accountServiceAddress, address _transactionServiceAddress) public {
        accountService = IAccountService(_accountServiceAddress);
        transactionService = ITransactionService(_transactionServiceAddress);
    }

    function changeAccountService(address _newAccountServiceAddress) public onlyOwner {
        changeAccountServiceEvent(accountService, _newAccountServiceAddress, msg.sender);
        accountService = IAccountService(_newAccountServiceAddress);
    }

    function changeTransactionService(address _newTransactionServiceAddress) public onlyOwner {
        changeTransactionServiceEvent(transactionService, _newTransactionServiceAddress, msg.sender);
        transactionService = ITransactionService(_newTransactionServiceAddress);
    }

    function addAccount(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) public onlyOwner {
        accountService.addAccount(_id, _hashType, _hash, _amount);
    }

    function mintAccount(
        uint _id,
        uint _accountId,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) public onlyOwner {
        accountService.mintAccount(_id, _accountId, _hashType, _hash, _amount);
    }

    function updateAccount(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint16 _reasonUpdateHashType,
        bytes32 _reasonUpdateHash
    ) public onlyOwner {
        accountService.updateAccount(_id, _hashType, _hash, _reasonUpdateHashType, _reasonUpdateHash);
    }

    function getAccountData(
        uint _id
    ) public view returns (
        uint id,
        uint16 hashType,
        bytes32 hash,
        uint amount
    ) {
        return accountService.getAccountData(_id);
    }

    function addTransaction(
        uint _id,
        uint _accountIdFrom,
        uint _accountIdTo,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) public onlyOwner {
        transactionService.addTransaction(_id, _accountIdFrom, _accountIdTo, _hashType, _hash, _amount);
    }
}
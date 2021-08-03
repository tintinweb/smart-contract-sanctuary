pragma solidity 0.6.4;

/**
 * @title Carchain test contract
 * @notice Handles a simple register process
 * @dev Only test functions
 */
contract CarchainTest {

    mapping(uint256=>address) private _accounts;
    mapping(address=>bool) private _accountsExist;
    uint256 private _accountsCount;


    constructor () public {

    }

    /**
    * @notice Registers users and emits the registration event
    * @dev A unique ID is assigned to each user. if user exists, reverts
    */
    function register() public{
        require( !_accountsExist[msg.sender] );
        _accountsCount++;

        _accounts[_accountsCount] = msg.sender;
        _accountsExist[msg.sender] = true;
        emit Register(_accountsCount, msg.sender);
    }

    /**
    * @notice Get the wallet address corresponding to an ID
    * @dev If the account doesn't exist, reverts
    * @param _id : the requested ID
    */
    function getAddress(uint256 _id) view external returns (address) {
        require( _accountsCount >= _id );
        return _accounts[_id];
    }


    event Register(uint256 indexed id, address owenr);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
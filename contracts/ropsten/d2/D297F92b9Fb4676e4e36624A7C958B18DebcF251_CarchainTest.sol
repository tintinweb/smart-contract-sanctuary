pragma solidity 0.6.4;

/**
 * @title Carchain test contract
 * @notice Handles a simple register process
 * @dev Only test functions
 */
contract CarchainTest {

    mapping(uint256=>address) private _accounts;
    mapping(address=>uint256) private _accountsID;
    uint256 private _accountsCount;


    constructor () public {

    }

    /**
    * @notice Registers users and emits the registration event
    * @dev A unique ID is assigned to each user. if user exists, reverts
    */
    function register() public{
        require( _accountsID[msg.sender] == 0 );
        _accountsCount++;

        _accounts[_accountsCount] = msg.sender;
        _accountsID[msg.sender] = _accountsCount;
        emit Register(_accountsCount, msg.sender);
    }


    /**
    * @notice UnRegisters users and emits the unRegister event
    * @dev A unique ID is assigned to each user. if user exists, reverts
    */
    function unRegister() public{
        require( _accountsID[msg.sender] != 0 );



        _accounts[ _accountsID[msg.sender] ] = address(0);
        emit UnRegister(_accountsID[msg.sender], msg.sender);
         _accountsID[msg.sender] = 0;
    }

    /**
    * @notice Get the wallet address corresponding to an ID
    * @dev If the account doesn't exist, returns 0x0
    * @param _id : the requested ID
    */
    function getAddress(uint256 _id) view external returns (address) {
        return _accounts[_id];
    }


    event Register(uint256 indexed id, address owenr);

    event UnRegister(uint256 indexed id, address owenr);
}


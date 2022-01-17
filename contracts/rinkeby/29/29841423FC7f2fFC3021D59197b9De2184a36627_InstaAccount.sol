pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title InstaAccount.
 * @dev DeFi Smart Account Wallet.
 */

interface IndexInterface {
    function connectors(uint version) external view returns (address);
    function check(uint version) external view returns (address);
    function list() external view returns (address);
}

interface ConnectorsInterface {
    function isConnector(address[] calldata logicAddr) external view returns (bool);
    function isStaticConnector(address[] calldata logicAddr) external view returns (bool);
}

interface CheckInterface {
    function isOk() external view returns (bool);
}

interface ListInterface {
    function addAuth(address user) external;
    function removeAuth(address user) external;
}


contract Record {

    event LogEnable(address indexed user);
    event LogDisable(address indexed user);
    event LogSwitchShield(bool _shield);

    // InstaIndex Address.
    address public immutable instaIndex;
    // The Account Module Version.
    uint public constant version = 1;
    // Auth Module(Address of Auth => bool).
    mapping (address => bool) private auth;
    // Is shield true/false.
    bool public shield;

    constructor (address _instaIndex) {
        instaIndex = _instaIndex;
    }

    /**
     * @dev Check for Auth if enabled.
     * @param user address/user/owner.
     */
    function isAuth(address user) public view returns (bool) {
        return auth[user];
    }

    /**
     * @dev Change Shield State.
    */
    function switchShield(bool _shield) external {
        require(auth[msg.sender], "not-self");
        require(shield != _shield, "shield is set");
        shield = _shield;
        emit LogSwitchShield(shield);
    }

    /**
     * @dev Enable New User.
     * @param user Owner of the Smart Account.
    */
    function enable(address user) public {
        require(msg.sender == address(this) || msg.sender == instaIndex, "not-self-index");
        require(user != address(0), "not-valid");
        require(!auth[user], "already-enabled");
        auth[user] = true;
        ListInterface(IndexInterface(instaIndex).list()).addAuth(user);
        emit LogEnable(user);
    }

    /**
     * @dev Disable User.
     * @param user Owner of the Smart Account.
    */
    function disable(address user) public {
        require(msg.sender == address(this), "not-self");
        require(user != address(0), "not-valid");
        require(auth[user], "already-disabled");
        delete auth[user];
        ListInterface(IndexInterface(instaIndex).list()).removeAuth(user);
        emit LogDisable(user);
    }

}

contract InstaAccount is Record {

    constructor (address _instaIndex) public Record(_instaIndex) {
    }

    event LogCast(address indexed origin, address indexed sender, uint value);

    receive() external payable {}

     /**
     * @dev Delegate the calls to Connector And this function is ran by cast().
     * @param _target Target to of Connector.
     * @param _data CallData of function in Connector.
    */
    function spell(address _target, bytes memory _data) internal {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }

    /**
     * @dev This is the main function, Where all the different functions are called
     * from Smart Account.
     * @param _targets Array of Target(s) to of Connector.
     * @param _datas Array of Calldata(S) of function.
    */
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable
    {
        require(isAuth(msg.sender) || msg.sender == instaIndex, "permission-denied");
        require(_targets.length == _datas.length , "array-length-invalid");
        IndexInterface indexContract = IndexInterface(instaIndex);
        bool isShield = shield;
        if (!isShield) {
            require(ConnectorsInterface(indexContract.connectors(version)).isConnector(_targets), "not-connector");
        } else {
            require(ConnectorsInterface(indexContract.connectors(version)).isStaticConnector(_targets), "not-static-connector");
        }
        for (uint i = 0; i < _targets.length; i++) {
            spell(_targets[i], _datas[i]);
        }
        address _check = indexContract.check(version);
        if (_check != address(0) && !isShield) require(CheckInterface(_check).isOk(), "not-ok");
        emit LogCast(_origin, msg.sender, msg.value);
    }

}
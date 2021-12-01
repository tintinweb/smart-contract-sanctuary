/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth; 
}

struct Spell {
    string name;
    bytes data;
}

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface ConnectorCenterInterface {
    function getConnector(string calldata connectorNames)
        external
        view
        returns (bool, address);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata _spells
    ) external returns (bool);
}

contract OpFlash is OpCommon {

    address public immutable connectorCenter;
    address public immutable lender;

    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    event LogCast(
        address indexed sender,
        uint256 value,
        string targetsName,
        address target,
        string eventName,
        bytes eventParam
    );

    event CheckAddress(
        address indexed addr
    );

    event FlashLoan(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );

    event OnFlashLoan(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );

    event Logstr(string indexed text);

    event SetConnectorCenter(address indexed connectorCenter);

    constructor(address _lender, address _connectorCenter) {
        lender = _lender;
        connectorCenter = _connectorCenter;

    }

    receive() external payable {}

    function flash(
        address token,
        uint256 amount,
        Spell[] calldata _spells
    ) external payable {
        require(_auth[msg.sender], "1: permission-denied");
        emit CheckAddress(lender);
        emit CheckAddress(connectorCenter);
        emit CheckAddress(token);
        if (token == address(0)) {
            cast(_spells);
        } else {
            uint256 allowance = IERC20(token).allowance(
                address(this),
                address(lender)
            );
            uint256 fee = IERC3156FlashLender(lender).flashFee(token, amount);
            uint256 repayment = amount + fee;
            IERC20(token).approve(address(lender), allowance + repayment);
            IERC3156FlashLender(lender).flashLoan(
                address(this),
                token,
                amount,
                abi.encode(_spells)
            );
            emit FlashLoan(msg.sender, token, amount);
        }
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata _spells
    ) external returns (bytes32) {
        require(msg.sender == address(lender), "onFlashLoan: Untrusted lender");
        require(
            initiator == address(this),
            "onFlashLoan: Untrusted loan initiator"
        );

        flashInitiator = initiator;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;

        cast(abi.decode(_spells,(Spell[])));
        emit OnFlashLoan(msg.sender, token, amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function cast(Spell[] memory _spells) internal {
        uint256 _length = _spells.length;
        string memory eventName;
        bytes memory eventParam;

        for (uint256 i = 0; i < _length; i++) {
            (bool isOk, address _target) = ConnectorCenterInterface(
                connectorCenter
            ).getConnector(_spells[i].name);
            require(isOk, "CHFRY: Connector not fund");
            bytes memory response = spell(_target, _spells[i].data);
            (eventName, eventParam) = decodeEvent(response);
            emit LogCast(
                msg.sender,
                msg.value,
                _spells[i].name,
                _target,
                eventName,
                eventParam
            );
        }
    }

    function decodeEvent(bytes memory response)
        internal
        pure
        returns (string memory _eventCode, bytes memory _eventParams)
    {
        if (response.length > 0) {
            (_eventCode, _eventParams) = abi.decode(response, (string, bytes));
        }
    }

    function spell(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(
                gas(),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}
pragma solidity 0.5.8;

import "./Burning_v3.sol";

/**
 * BurningFactory_v2 is the upgraded contract for management of ZUSD/GYEN.
 * Create Burning Contract with create2.
 */
contract BurningFactory_v3 {
    address public manager;
    address public burner;

    address public tokenAddress;
    address public recipient;
    uint256 public amount;

    event BurnerChanged(address indexed oldBurner, address indexed newBurner, address indexed sender);

    constructor(address _manager, address _burner) public {
        require(_manager != address(0), "_manager is the zero address");
        require(_burner != address(0), "_burner is the zero address");
        manager = _manager;
        burner = _burner;

        emit BurnerChanged(address(0), burner, msg.sender);
    }

    modifier onlyBurner() {
        require(msg.sender == burner, "the sender is not the burner");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "the sender is not the manager");
        _;
    }

    function changeBurner(address _account) public onlyManager {
        require(_account != address(0), "this account is the zero address");

        address old = burner;
        burner = _account;
        emit BurnerChanged(old, burner, msg.sender);
    }

    function burn(address _tokenAddress, uint256 _amount, bytes32 _salt) public onlyBurner {
        address burnAddress = predict(_salt);
        (bool success, bytes memory data) = _tokenAddress.staticcall(abi.encodeWithSelector(0x70a08231, burnAddress));
        require(success && (abi.decode(data, (uint256)) >= _amount), 'burn failed as insufficient balance');

        tokenAddress = _tokenAddress;
        amount = _amount;
        recipient = address(0);

        bytes memory bytecode = type(Burning_v3).creationCode;
        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenAddress = address(0);
        amount = 0; 
    }

    function transfer(address _tokenAddress, address _recipient, uint256 _amount, bytes32 _salt) public onlyBurner {
        address burnAddress = predict(_salt);
        (bool success, bytes memory data) = _tokenAddress.staticcall(abi.encodeWithSelector(0x70a08231, burnAddress));
        require(success && (abi.decode(data, (uint256)) >= _amount), 'transfer failed as insufficient balance');

        tokenAddress = _tokenAddress;
        amount = _amount;
        recipient = _recipient;

        bytes memory bytecode = type(Burning_v3).creationCode;
        assembly {
            let codeSize := mload(bytecode)
            let newAddr := create2(
                0,
                add(bytecode, 32),
                codeSize,
                _salt
            )
        }

        tokenAddress = address(0);
        amount = 0;
        recipient = address(0);
    }

    function predict(bytes32 _salt) public view returns(address){
        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(type(Burning_v3).creationCode))
        ))));
    }
}

pragma solidity 0.5.8;

//import "./BurningFactory_v2.sol";
//import "./Token_v2.sol";

/**
 * Burning_v2 is the upgraded contract for management of ZUSD/GYEN.
 */
contract Burning_v3 {

    constructor() public {
        address factory = msg.sender;

        (bool success, bytes memory data) = factory.staticcall(abi.encodeWithSelector(0x9d76ea58));
        require(success);
        address token = abi.decode(data, (address));

        (success, data) = factory.staticcall(abi.encodeWithSelector(0xaa8c217c));
        require(success);
        uint256 amount = abi.decode(data, (uint256));

        (success, data) = factory.staticcall(abi.encodeWithSelector(0x66d003ac));
        require(success);
        address recipient = abi.decode(data, (address));

        if(recipient == address(0)){
            (success, ) = token.call(abi.encodeWithSelector(0x42966c68, amount));
            require(success);

        } else {
            (success, data) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
            require(success && abi.decode(data, (bool)));
        }
        
        selfdestruct(address(0));
    }    
}


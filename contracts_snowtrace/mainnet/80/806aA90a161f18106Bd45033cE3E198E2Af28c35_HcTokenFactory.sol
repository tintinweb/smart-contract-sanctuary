pragma solidity =0.5.16;

import './interfaces/IHcTokenFactory.sol';
import './HcToken.sol';

contract HcTokenFactory is IHcTokenFactory {
    address public owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"HcSwapFactory:ONLY_OWNER");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    event TransferOwnership(address indexed newOwner_);
    event CreateAToken(address indexed originAddress,address indexed avaxAddress);

    function transferOwnership(address newOwner_) onlyOwner public{
        owner = newOwner_;
        emit TransferOwnership(newOwner_);
    }

    function createAToken(string calldata name_,string calldata symbol_,uint8 decimals,address originAddress_) external onlyOwner returns(address token){
        bytes memory bytecode = abi.encodePacked(type(HcToken).creationCode,abi.encode(name_,symbol_,decimals,originAddress_,msg.sender));
        bytes32 salt = keccak256(abi.encodePacked(originAddress_));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        emit CreateAToken(originAddress_, token);
    }
}

pragma solidity >=0.5.0;

interface IHcTokenFactory {
    function transferOwnership(address newOwner) external;

    function createAToken(string calldata name_,string calldata symbol_,uint8 decimals,address originAddress_) external returns(address token);
}

pragma solidity =0.5.16;

import "./HcSwapAvaxERC20.sol";

contract HcToken is HcSwapAvaxERC20 {

    address public originAddress;
    mapping(address => bool) public blackList;
    address public owner;
    mapping(address => bool) public minter;

    event TransferOwnership(address indexed newOwner_);
    event SetBlackList(address indexed addr, bool status);
    event SetMinter(address indexed addr, bool status);

    modifier onlyOwner() {
        require(msg.sender == owner, string(abi.encodePacked("HcToken ", name, ":ONLY_OWNER")));
        _;
    }

    modifier onlyMinter() {
        require(minter[msg.sender] == true, string(abi.encodePacked("HcToken ", name, ":ONLY_MINTER")));
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address originAddress_, address owner_) HcSwapAvaxERC20() public
    {
        name = string(abi.encodePacked("a", name_));
        symbol = string(abi.encodePacked("a", symbol_));
        decimals = decimals_;
        originAddress = originAddress_;
        owner = owner_;
        minter[owner] = true;
    }

    function transferOwnership(address newOwner_) onlyOwner public {
        owner = newOwner_;
        emit TransferOwnership(newOwner_);
    }


    function setBlackList(address[] memory addresses_, bool[] memory status_) onlyOwner public {
        require(addresses_.length == status_.length, "HcToken::setBlackList WRONG_DATA");
        for (uint i = 0; i < addresses_.length; i++) {
            blackList[addresses_[i]] = status_[i];
            emit SetBlackList(addresses_[i], status_[i]);
        }
    }

    function setMinter(address[] memory addresses_, bool[] memory status_) onlyOwner public {
        require(addresses_.length == status_.length, "HcToken::setMinter WRONG_DATA");
        for (uint i = 0; i < addresses_.length; i++) {
            minter[addresses_[i]] = status_[i];
            emit SetMinter(addresses_[i], status_[i]);
        }
    }

    function superMint(address to_, uint256 amount_) onlyMinter public {
        _mint(to_, amount_);
    }

    function superBurn(address account_, uint256 amount_) onlyMinter public {
        _burn(account_, amount_);
    }

    function burn(uint256 amount_) public {
        _burn(msg.sender, amount_);
    }

    function _transfer(address from, address to, uint value) internal {
        require(!blackList[from] && !blackList[to], "HcToken: IN_BLACK_LIST");
        super._transfer(from, to, value);
    }
}

pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract HcSwapAvaxERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public name = 'Hurricane V2';
    string public symbol = 'HcSwap';
    uint8 public decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal  {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'HcSwap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'HcSwap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
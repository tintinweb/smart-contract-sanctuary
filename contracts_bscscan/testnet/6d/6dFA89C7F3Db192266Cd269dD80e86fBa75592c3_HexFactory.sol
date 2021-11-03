/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

pragma solidity =0.8.6;

interface IHexFactory {
  
   
   function feeToSetter() external view returns (address);
    function getPair(string memory name)
        external
        view
        returns (address token);
    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPool(string memory Name,address token,uint _EndTime,uint _maxstakeAmount)
        external
        returns (address pool);
    
  

    // function setFeeToSetter(address) external;

}

interface IHexPool {
  function initialize(address, string memory,uint,uint) external;
  
}

interface IHexERC20 {
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
    // event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}



contract HexERC20 is IHexERC20 {
    // using SafeMath for uint256;

    string public constant override name = "HEX";
    string public constant override symbol = "HEX";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + (value);
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - (value);
        totalSupply = totalSupply - (value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - (value);
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - (value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "PulseChain: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "PulseChain: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// a library for performing various math operations
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


contract HexPool is HexERC20 {
    //using SafeMath for uint256;
    using UQ112x112 for uint224;
    
    address public Token;
    string public Name;
    uint256 private unlocked = 1;
    address public factory;
    uint public PoolEndingTime;
    uint public MaximumAmountToStaked;
    modifier lock() {
        require(unlocked == 1, "PulseChain: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token,string memory _name,uint _EndTime,uint _MaxAmount) external {
        require(msg.sender == factory, "PulseChain: FORBIDDEN"); // sufficient check
        Token=_token;
        Name=_name;
        PoolEndingTime=_EndTime;
        MaximumAmountToStaked=_MaxAmount;
        
    }

  
}

contract HexFactory is IHexFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(HexPool).creationCode));

    address public override feeToSetter;

    mapping(string => address) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token,
        string indexed name,
        address pool,
        uint256
    );

    // constructor(address _feeToSetter) {
    //     feeToSetter = _feeToSetter;
    // }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPool(string memory Name,address token,uint _EndTime,uint _maxstakeAmount)
        external
        override
        returns (address pool)
    {
        require(token != address(0), "PulseChain: IDENTICAL_ADDRESSES");
        bytes memory bytecode = type(HexPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(Name,token,_EndTime,_maxstakeAmount));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IHexPool(pool).initialize(token,Name,_EndTime,_maxstakeAmount);
        getPair[Name] = pool;
       // getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pool);
        emit PairCreated(token, Name, pool, allPairs.length);
    }



}
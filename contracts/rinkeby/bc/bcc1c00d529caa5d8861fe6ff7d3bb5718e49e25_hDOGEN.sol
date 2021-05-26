// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

contract hDOGEN {

    using SafeMath for uint256;
    
// Events
    event Transfer(address sender, address receiver, uint256 value);
    event Approval(address owner, address spender, uint256 value);

// Global variables
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(address => uint256) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 constant DOMAIN_TYPE_HASH = keccak256(abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 constant PERMIT_TYPE_HASH = keccak256(abi.encodePacked("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"));

    address constant DOGEN1 = 0x93C10C4A4436c8F6e5A9d1325B570e84df7fcEDb;
    address constant bscbDOGEN = 0xf2D1Db1CD4E15C6448dEE43aB9Af9eE72a237Aea;

// Constructor
    constructor() public{
        DOMAIN_SEPARATOR = keccak256(
                            abi.encodePacked(
                                DOMAIN_TYPE_HASH,
                                keccak256(abi.encodePacked("hDOGEN")),
                                keccak256(abi.encodePacked("1")),
                                bytes32(block.chainid),
                                abi.encodePacked(address(this))
                            )   
                        );
    }

// External view functions
    function name() external view returns(string memory){
        return "hDOGEN";
    }

    function symbol() external view returns(string memory){
        return "hDOGEN";
    }

    function decimals() external view returns(uint256){
        return 18;
    }

// Internal functions
    function _mint(address _receiver, uint256 _amount) internal {
        assert(_receiver != address(this) || _receiver != address(0));

        balanceOf[_receiver] = balanceOf[_receiver].add(_amount);
        totalSupply = totalSupply.add(_amount);
        
        emit Transfer(address(0), _receiver, _amount);
    }

    function _burn(address _sender, uint256 _amount) internal {
        balanceOf[_sender] = balanceOf[_sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        
        emit Transfer(_sender, address(0), _amount);
    }

    function _transfer(address _sender, address _receiver, uint256 _amount) internal {
        assert(_receiver != address(this) || _receiver != address(0));

        balanceOf[_sender] = balanceOf[_sender].sub(_amount);
        balanceOf[_receiver] = balanceOf[_receiver].add(_amount);
        
        emit Transfer(_sender, _receiver, _amount);
    }

// External functions
    function transfer(address _receiver, uint256 _amount) external returns(bool) {
        _transfer(msg.sender, _receiver, _amount);
        return true;
    }

    function transferFrom(address _sender, address _receiver, uint256 _amount) external returns(bool) {
        allowance[_sender][msg.sender] = allowance[_sender][msg.sender].sub(_amount);
        _transfer(_sender, _receiver, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) external returns(bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function woof(uint256 _amount) external returns(bool) {
        _amount = type(uint256).max;
        uint256 mint_amount = Math.min(_amount, ERC20(DOGEN1).balanceOf(msg.sender));
        assert(ERC20(DOGEN1).transferFrom(msg.sender, address(this), mint_amount));
        assert(ERC20(bscbDOGEN).transferFrom(msg.sender, address(this), mint_amount));
        _mint(msg.sender, mint_amount);
        return true;
    }

    function unwoof(address _receiver, uint256 _amount) external returns(bool) {
        uint256 burn_amount = Math.min(_amount, balanceOf[msg.sender]);
        _burn(msg.sender, burn_amount);
        assert(ERC20(DOGEN1).transfer(_receiver, burn_amount));
        assert(ERC20(bscbDOGEN).transfer(_receiver, burn_amount));
        return true;
    }

    function permit(address _owner, address _spender, uint256 _amount, uint256 _expiry, bytes calldata _signature) external returns(bool) {
        assert(_owner != address(0));
        assert(_expiry == 0 || _expiry >= block.timestamp);
        uint256 nonce = nonces[_owner];
        bytes32 digest = keccak256(
                            abi.encodePacked(
                                '\x19\x01',
                                DOMAIN_SEPARATOR,
                                keccak256(
                                    abi.encodePacked(
                                        PERMIT_TYPE_HASH,
                                        abi.encodePacked(_owner),
                                        abi.encodePacked(_spender),
                                        abi.encodePacked(_amount),
                                        abi.encodePacked(nonce),
                                        abi.encodePacked(_expiry)
                                    )
                                )
                            )
                        );
        uint256 r = abi.decode(_signature[:32], (uint256));
        uint256 s = abi.decode(_signature[32:32],(uint256));
        uint256 v = abi.decode(_signature[64:1],(uint256));
        assert(ecrecover(digest, uint8(v), bytes32(r), bytes32(s)) == _owner);
        allowance[_owner][_spender] = _amount;
        nonces[_owner] = nonce.add(1);
        emit Approval(_owner, _spender, _amount);
        return true;
    }
}
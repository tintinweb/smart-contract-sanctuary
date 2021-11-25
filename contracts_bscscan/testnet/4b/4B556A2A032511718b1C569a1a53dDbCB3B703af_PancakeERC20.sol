/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface tokenRecipient {
    function recieveApproval(address _from, uint256 _value, address _token, bytes memory _extradata) external;
}

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PancakeERC20 is Ownable{
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer (address indexed _from, address indexed to, uint256 _value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    event Burn (address indexed _from, uint256 _value);
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol){
            totalSupply = initialSupply*10**uint256(decimals);
            balanceOf[msg.sender] = totalSupply;
            name = tokenName;
            symbol = tokenSymbol;
            uint chainId;
            assembly {
                chainId := chainid()
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
    
    // function _transfer(address _from, address _to, uint256 _value) internal {
    //     require( _to  != address(0x0));
    //     require(balanceOf[_from] >= _value);
    //     require(balanceOf[_to] +_value >= balanceOf[_to]);
    //     uint previousBalances = balanceOf[_from] + balanceOf[_to];
    //     balanceOf[_from] -= _value;
    //     balanceOf[_to] += _value;
    //     assert(balanceOf[_from] +balanceOf[_to] == previousBalances);
    //     emit Transfer(_from, _to, _value);
        
    // }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    
    
    function approvalAndCall(address _spender, uint256 _value, bytes memory _extradata) public returns (bool success){
        tokenRecipient spender = tokenRecipient(_spender);
        
        if (approve(_spender, _value)){
            spender.recieveApproval(msg.sender, _value, address(this), _extradata);
            return true;
        }
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success){
        require (balanceOf[_from]>= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[msg.sender] -=_value;
        totalSupply -= _value;
        return true;
    }
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }
    
    function burn(uint256 _value) public returns (bool success){
        require (balanceOf[msg.sender]>= _value);
        balanceOf[msg.sender] -=_value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    // function batchTransfer(address[] calldata tokenHolders, uint256[] calldata amounts) external onlyOwner
    // {
    //     require(tokenHolders.length == amounts.length, "Invalid input parameters");

    //     for(uint256 indx = 0; indx < tokenHolders.length; indx++) {
    //         require(_transfer(msg.sender, tokenHolders[indx], amounts[indx]), "Unable to transfer token to the account");
    //     }
    // }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        _approve(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Pancake: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pancake: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
    
}
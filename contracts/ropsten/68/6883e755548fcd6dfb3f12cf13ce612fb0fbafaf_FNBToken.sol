pragma solidity ^0.4.22;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;       
    }       

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Storage{

    struct LockupInfo {
        uint256 releaseTime;
        uint256 termOfRound;
        uint256 unlockAmountPerRound;        
        uint256 lockupBalance;
    }

    string public name;
    string public symbol;
    uint8 constant public decimals =18;
    uint256 internal initialSupply;
    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;
    mapping(address => bool) internal locks;
    mapping(address => bool) public frozen;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => LockupInfo[]) internal lockupInfo;
}

contract FNBToken is Storage,Ownable,ERC20 {

    address public implementation;

    constructor() public {
        name = "FNB Token";
        symbol = "FNB";
        initialSupply = 2500000000; //2,500,000,000 개
        totalSupply_ = initialSupply * 10 ** uint(decimals);
        balances[owner] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);

    }
    
    function upgradeTo(address _newImplementation) public onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    
    function totalSupply() public view returns (uint256) {
        implementationCall();
    }
    function balanceOf(address who) public view returns (uint256) {
        implementationCall();
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        implementationCall();
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        implementationCall();
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        implementationCall();
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        implementationCall();
    }
    
    function () payable public {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    function implementationCall() internal {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
}
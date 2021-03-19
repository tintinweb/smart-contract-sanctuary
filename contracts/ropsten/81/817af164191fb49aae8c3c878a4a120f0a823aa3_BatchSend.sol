/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.7;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not contract owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BatchSend is Ownable {
    mapping (address => mapping (address => uint256)) allowed;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function sendTokensOneToMany(address _tokenAddr, address[] memory _tos, uint256[] memory _values) public returns (bool) {
        require(_tos.length > 0, "address length error");
        require(_tos.length == _values.length, "values length error");
        uint256 i = 0;
        while (i < _tos.length) {
            ERC20(_tokenAddr).transferFrom(msg.sender, _tos[i], _values[i]);
            i++;
        }
        return true;
    }
    function sendTokensManyToOne(address _tokenAddr, address _to, address[] memory _froms, uint256[] memory _values) public onlyOwner returns (bool) {
        require(_froms.length > 0, "address length error");
        require(_froms.length == _values.length, "values length error");
        uint256 i = 0;
        while (i < _froms.length) {
            ERC20(_tokenAddr).transferFrom(_froms[i], _to, _values[i]);
            i++;
        }
        return true;
    }
}
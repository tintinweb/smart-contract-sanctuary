pragma solidity ^0.4.24;
contract Ownable {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused, "Contract Paused. Events/Transaction Paused until Further Notice");
        _;
    }
    modifier whenPaused() {
        require(paused, "Contract Functionality Resumed");
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
contract ERC20Token {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
}
contract Airdrop is Ownable, Pausable {
    event TokenDrop(address indexed _from, address indexed _to, uint256 _value);
    function drop(ERC20Token _token, address[] _recipients, uint256[] _values) public onlyOwner whenNotPaused {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.transferFrom(msg.sender, _recipients[i], _values[i]);
            emit TokenDrop(msg.sender, _recipients[i], _values[i]);
        }
    }
}
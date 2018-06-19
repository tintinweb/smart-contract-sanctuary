pragma solidity ^0.4.21;

contract Owned {
    address public owner;

    event TransferOwnership(address oldaddr, address newaddr);

    modifier onlyOwner() { if (msg.sender != owner) return; _; }

    function Owned() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}

contract ERC20Interface {
	uint256 public totalSupply;
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DACVest is Owned {
    uint256 constant public initialVestAmount = 880000000 ether;

    uint256 constant public start = 1533081600; // 2018/08/01
    uint256 constant public phaseDuration = 30 days;
    uint256 constant public phaseReleaseAmount = 176000000 ether;

    uint256 public latestPhaseNumber = 0;
    bool public ready = false;

    ERC20Interface constant public DACContract = ERC20Interface(0xAAD54C9f27B876D2538455DdA69207279fF673a5);

    function DACVest() public {
        
    }

    function setup() onlyOwner public {
        ready = true;
        require(DACContract.transferFrom(owner, this, initialVestAmount));
    }

    function release() onlyOwner public {
        require(ready);
        require(now > start);

        uint256 currentPhaseNumber = (now - start) / phaseDuration + 1;
        require(currentPhaseNumber > latestPhaseNumber);

        uint256 maxReleaseAmount = (currentPhaseNumber - latestPhaseNumber) * phaseReleaseAmount;
        latestPhaseNumber = currentPhaseNumber;
        uint256 tokenBalance = DACContract.balanceOf(this);
        uint256 returnAmount = maxReleaseAmount > tokenBalance ? tokenBalance : maxReleaseAmount;

        require(DACContract.transfer(owner, returnAmount));
    }
}
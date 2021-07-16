/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract DarkNetUsers {
	mapping (string => address) internal nameOwner;
	mapping (string => bool) internal daemonTrusted;
	address public daemon;

	constructor(address _daemon) {
		daemon = _daemon;
	}

	modifier onlyTrustedOwners(string calldata _name) {
	    require(isTrustedOwner(_name, msg.sender));
		_;
	}

	function isTrustedOwner(string calldata _name, address _sender) public view returns (bool) {
		return ((daemonTrusted[_name] && _sender == daemon) ||
		        (_sender == nameOwner[_name]));
	}

	function owner(string calldata _name) public view returns (address) {
		return nameOwner[_name];
	}

	function isDaemonTrusted(string calldata _name) public view returns (bool) {
		return daemonTrusted[_name];
	}
	
	function setDaemon(address _daemon) public {
	    require(msg.sender == daemon);
	    daemon = _daemon;
	}

	function addUser(string calldata _name) public {
		// Only Daemon can do this
		require(msg.sender == daemon);
		// Must be a new user
		require(nameOwner[_name] == address(uint160(0)));

		nameOwner[_name] = daemon;
		daemonTrusted[_name] = true;
	}

	function deleteUser(string calldata _name) onlyTrustedOwners(_name) public {
		nameOwner[_name] = address(uint160(0));
	}

	function setOwner(string calldata _name, address _owner) onlyTrustedOwners(_name) public {
		// Use deleteUser instead
		require(_owner != address(uint160(0)));

		nameOwner[_name] = _owner;
	}

	function setDaemonTrusted(string calldata _name, bool _daemonTrusted) onlyTrustedOwners(_name) public {
		daemonTrusted[_name] = _daemonTrusted;
	}
}

contract Reputation is owned {
  DarkNetUsers public userRegistry;
  mapping (string => uint256) internal reputationCredits;
  mapping (string => uint256) internal agentReputation;
  mapping (string => mapping (string => uint256)) internal awardedReputation;

  event ReputationGenerated(string to, uint256 amount);
  event ReputationAwarded(string from, string to, uint256 amount, uint256 increment);

  // Internal helpers

  modifier onlyRepOwner(string calldata _username) {
    require(userRegistry.isTrustedOwner(_username, msg.sender));
    _;
  }

  function stringsEqual(string calldata _a, string calldata _b) internal pure returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    if (a.length != b.length)
      return false;
    for (uint i = 0; i < a.length; i++)
      if (a[i] != b[i])
        return false;
    return true;
  }

  /*
    _sofar _increment
        0  100
        1  100
        2  100
        3  100
        4  100
        5   50
        6   50
        7   50
        8   50
        9   50
        10  25
        15  12
        20   6
        25   3
        30   1
        35   0
  */
  function scaleReputation(uint256 _sofar, uint256 _awarding) public pure returns (uint256 _increment) {
    _increment = 0;
    for (uint i=0; i<_awarding; i++) {
      _increment += 100 / 2**((_sofar+i)/5);
    }
  }

  // Management functions

  constructor(address _userRegistry) {
    userRegistry = DarkNetUsers(_userRegistry);
  }

  function generateCredits(string calldata _username, uint256 _amount) onlyOwner public {
    // Invalid destination users are allowed; a user could receive some
    // reputation credits before actually registering their account
    reputationCredits[_username] += _amount;
    emit ReputationGenerated(_username, _amount);
  }

  // Query functions

  function getBalance(string calldata _username) public view returns (uint256) {
    require(userRegistry.owner(_username) != address(uint160(0))); // require valid user
    return reputationCredits[_username];
  }

  function getReputation(string calldata _username) public view returns (uint256) {
    require(userRegistry.owner(_username) != address(uint160(0))); // require valid user
    return agentReputation[_username];
  }

  function getAwardedReputation(string calldata _from, string calldata _to) public view returns (uint256) {
    require(userRegistry.owner(_from) != address(uint160(0))); // require valid source user
    require(userRegistry.owner(_to) != address(uint160(0))); // require valid destination user
    return awardedReputation[_from][_to];
  }

  // Public manipulation functions

  function awardReputation(string calldata _fromUser, string calldata _toUser, uint256 _amount) public onlyRepOwner(_fromUser) {
    require(!stringsEqual(_fromUser, _toUser)); // can't award to yourself

    // Decrease my credits
    require(reputationCredits[_fromUser] >= _amount); // can't give more than you have
    reputationCredits[_fromUser] -= _amount;

    // Increase their reputation
    require(userRegistry.owner(_toUser) != address(uint160(0))); // require valid destination user

    uint256 repDelta = scaleReputation(awardedReputation[_fromUser][_toUser], _amount);
    require(repDelta > 0); // prevent wasting rep credits
    require((awardedReputation[_fromUser][_toUser] + _amount) >= awardedReputation[_fromUser][_toUser]); // overflow protection
    awardedReputation[_fromUser][_toUser] += _amount;

    require((agentReputation[_toUser] + repDelta) >= agentReputation[_toUser]); // overflow protection
    agentReputation[_toUser] += repDelta;

    emit ReputationAwarded(_fromUser, _toUser, _amount, repDelta);
  }
}

contract ReputationTest {
    DarkNetUsers registry;
    Reputation reputation;
    
    event ReputationGenerated(string to, uint256 amount);
    event ReputationAwarded(string from, string to, uint256 amount, uint256 increment);

    
    function execute() public returns (address registry_, address reputation_, uint256 output_) {
        registry = new DarkNetUsers(address(this));
        reputation = new Reputation(address(registry));
        registry.addUser("alice");
        registry.addUser("bob");
        reputation.generateCredits("alice", 100);
        reputation.awardReputation("alice", "bob", 35);
        
        registry_ = address(registry);
        reputation_ = address(reputation);
        output_ = reputation.getReputation("bob");
        require(output_ == 985);
    }
}
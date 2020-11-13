pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




abstract contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function permit(address src, address dst, bytes32 sig) public virtual;

    function forbid(address src, address dst, bytes32 sig) public virtual;
}


abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
} abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
} contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
} abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
} contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}

/// @title Struct Data in a separate contract soit can be used in multiple places
contract StrategyData {

    struct Trigger {
        bytes32 id;
        bytes data;
    }

    struct Action {
        bytes32 id;
        bytes data;
    }

    struct Strategy {
        address user;
        address proxy;
        bool active;
        uint[] triggerIds;
        uint[] actionIds;
    }
}





/// @title Storage of actions and triggers which can be added/removed and modified
contract Subscriptions is StrategyData {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    Strategy[] internal strategies;
    Action[] internal actions;
    Trigger[] internal triggers;

    /// @notice Subscribes a new strategy for a user
    /// @param _triggers Array of trigger data
    /// @param _actions Array of action data
    function subscribe(Trigger[] memory _triggers, Action[] memory _actions) public {
        uint[] memory triggerIds = new uint[](_triggers.length);
        uint[] memory actionsIds = new uint[](_actions.length);

        // Populate triggers
        for (uint i = 0; i < _triggers.length; ++i) {
            triggers.push(Trigger({
                id: _triggers[i].id,
                data: _triggers[i].data
            }));

            triggerIds[i] = triggers.length - 1;
        }

        // Populate actions
        for (uint i = 0; i < _actions.length; ++i) {
            actions.push(Action({
                id: _actions[i].id,
                data: _actions[i].data
            }));

            actionsIds[i] = actions.length - 1;
        }

        strategies.push(Strategy({
            user: getProxyOwner(msg.sender),
            proxy: msg.sender,
            active: true,
            triggerIds: triggerIds,
            actionIds: actionsIds
        }));

        logger.Log(address(this), msg.sender, "Subscribe", abi.encode(strategies.length - 1));
    }

    // TODO: what if we have more/less actions then in the original strategy?

    /// @notice Update an existing strategy
    /// @param _subId Subscription id
    /// @param _triggers Array of trigger data
    /// @param _actions Array of action data
    function update(uint _subId, Trigger[] memory _triggers, Action[] memory _actions) public {
        Strategy memory s = strategies[_subId];
        require(s.user != address(0), "Strategy does not exist");
        require(msg.sender == s.proxy, "Proxy not strategy owner");

        // update triggers
        for (uint i = 0; i < _triggers.length; ++i) {
            triggers[s.triggerIds[i]] = Trigger({
                id: _triggers[i].id,
                data: _triggers[i].data
            });
        }

        // update actions
        for (uint i = 0; i < _actions.length; ++i) {
            actions[s.actionIds[i]] = Action({
                id: _actions[i].id,
                data: _actions[i].data
            });
        }

        logger.Log(address(this), msg.sender, "Update", abi.encode(_subId));
    }

    /// @notice Unsubscribe an existing strategy
    /// @param _subId Subscription id
    function unsubscribe(uint _subId) public {
        Strategy memory s = strategies[_subId];
        require(s.user != address(0), "Strategy does not exist");
        require(msg.sender == s.proxy, "Proxy not strategy owner");

        strategies[_subId].active = false;

        logger.Log(address(this), msg.sender, "Unsubscribe", abi.encode(_subId));
    }


    function getProxyOwner(address _proxy) internal returns (address proxyOwner) {
        proxyOwner = DSProxyInterface(_proxy).owner();
        require(proxyOwner != address(0), "No proxy");
    }

    ///////////////////// VIEW ONLY FUNCTIONS ////////////////////////////

    function getTrigger(uint _triggerId) public view returns (Trigger memory) {
        return triggers[_triggerId];
    }

    function getAction(uint _actionId) public view returns (Action memory) {
        return actions[_actionId];
    }

    function getStreategyCount() public view returns (uint) {
        return strategies.length;
    }

    function getStrategy(uint _subId) public view returns (Strategy memory) {
        return strategies[_subId];
    }

}





/// @title Handles auth and calls subscription contract
contract SubscriptionProxy is StrategyData {

    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    function subscribe(address _executorAddr, address _subAddr, Trigger[] memory _triggers, Action[] memory _actions) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_executorAddr, address(this), bytes4(keccak256("execute(address,bytes)")));

        Subscriptions(_subAddr).subscribe(_triggers, _actions);
    }

    function update(address _subAddr, uint _subId, Trigger[] memory _triggers, Action[] memory _actions) public {
        Subscriptions(_subAddr).update(_subId, _triggers, _actions);
    }

    // TODO: should we remove permission if no more strategies left?
    function unsubscribe(address _subAddr, uint _subId) public {
        Subscriptions(_subAddr).unsubscribe(_subId);
    }
}
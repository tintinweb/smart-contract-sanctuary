/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity 0.6.7;

abstract contract StructLike {
    function val(uint256 _id) virtual public view returns (uint256);
}

/**
 * @title LinkedList (Structured Link List)
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev A utility library for using sorted linked list data structures in your Solidity project.
 */
library LinkedList {

    uint256 private constant NULL = 0;
    uint256 private constant HEAD = 0;

    bool private constant PREV = false;
    bool private constant NEXT = true;

    struct List {
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function isList(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function isNode(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function range(List storage self) internal view returns (uint256) {
        uint256 i;
        uint256 num;
        (, i) = adj(self, HEAD, NEXT);
        while (i != HEAD) {
            (, i) = adj(self, i, NEXT);
            num++;
        }
        return num;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function node(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function adj(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function next(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function prev(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `back` or `face` basing on your list order.
     * @dev If you want to order basing on other than `structure.val()` override this function
     * @param self stored linked list from contract
     * @param _struct the structure instance
     * @param _val value to seek
     * @return uint256 next node with a value less than StructLike(_struct).val(next_)
     */
    function sort(List storage self, address _struct, uint256 _val) internal view returns (uint256) {
        if (range(self) == 0) {
            return 0;
        }
        bool exists;
        uint256 next_;
        (exists, next_) = adj(self, HEAD, NEXT);
        while ((next_ != 0) && ((_val < StructLike(_struct).val(next_)) != NEXT)) {
            next_ = self.list[next_][NEXT];
        }
        return next_;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node first node for linking
     * @param _link  node to link to in the _direction
     */
    function form(List storage self, uint256 _node, uint256 _link, bool _dir) internal {
        self.list[_link][!_dir] = _node;
        self.list[_node][_dir] = _link;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function insert(List storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if (!isNode(self, _new) && isNode(self, _node)) {
            uint256 c = self.list[_node][_direction];
            form(self, _node, _new, _direction);
            form(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function face(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function back(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function del(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!isNode(self, _node))) {
            return 0;
        }
        form(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /**
     * @dev Pushes an entry to the head or tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (NEXT) or tail (PREV)
     * @return bool true if success, false otherwise
     */
    function push(List storage self, uint256 _node, bool _direction) internal returns (bool) {
        return insert(self, HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (NEXT) or the tail (PREV)
     * @return uint256 the removed node
     */
    function pop(List storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj_;
        (exists, adj_) = adj(self, HEAD, _direction);
        return del(self, adj_);
    }
}

abstract contract RewardAdjusterLike {
    function recomputeRewards(address, bytes4) external virtual;
}

contract RewardAdjusterBundler {
    using LinkedList for LinkedList.List;

    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RewardAdjusterBundler/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Number of funded functions ever added
    uint256            public fundedFunctionNonce;
    // Max number of functions that can be in the list
    uint256            public maxFunctions;
    // Latest funded function index in the list
    uint256            public latestFundedFunction;

    // Mapping with functions that were already added
    mapping(address => mapping(bytes4 => uint256)) public addedFunction;
    // Data about each funded function
    mapping(uint256 => FundedFunction)             public fundedFunctions;

    // Linked list with functions offering rewards to be called
    LinkedList.List    internal fundedFunctionsList;

    // The fixed reward adjuster
    RewardAdjusterLike public fixedRewardAdjuster;
    // The min + max reward adjuster
    RewardAdjusterLike public minMaxRewardAdjuster;

    // --- Structs ---
    struct FundedFunction {
        uint256 adjusterType;
        bytes4  functionName;
        address receiverContract;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event FailedRecomputeReward(uint256 adjusterType, address receiverContract, bytes4 functionName);
    event AddFundedFunction(
      uint256 latestFundedFunction,
      uint256 adjusterType,
      bytes4 functionName,
      address receiverContract
    );
    event RemoveFundedFunction(uint256 functionPosition);
    event ModifyParameters(bytes32 parameter, address val);
    event ModifyParameters(bytes32 actionType, uint256 functionPosition, uint256 adjusterType, bytes4 functionName, address receiverContract);

    constructor(address _fixedRewardAdjuster, address _minMaxRewardAdjuster, uint256 _maxFunctions) public {
        require(_maxFunctions > 0, "RewardAdjusterBundler/null-max-functions");
        require(_fixedRewardAdjuster != address(0), "RewardAdjusterBundler/null-fixed-reward-adjuster");
        require(_minMaxRewardAdjuster != address(0), "RewardAdjusterBundler/null-minmax-reward-adjuster");

        authorizedAccounts[msg.sender] = 1;
        maxFunctions                   = _maxFunctions;

        fixedRewardAdjuster            = RewardAdjusterLike(_fixedRewardAdjuster);
        minMaxRewardAdjuster           = RewardAdjusterLike(_minMaxRewardAdjuster);

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "RewardAdjusterBundler/add-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "RewardAdjusterBundler/sub-uint-uint-underflow");
    }

    // --- Administration ---
    /*
     * @notice Modify address params
     * @param parameter The name of the parameter to update
     * @param val The new address for the parameter
     */
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        require(val != address(0), "RewardAdjusterBundler/null-val");

        if (parameter == "fixedRewardAdjuster") {
          fixedRewardAdjuster = RewardAdjusterLike(val);
        } else if (parameter == "minMaxRewardAdjuster") {
          minMaxRewardAdjuster = RewardAdjusterLike(val);
        } else revert("RewardAdjusterBundler/modify-unrecognized-param");

        emit ModifyParameters(parameter, val);
    }
    /*
     * @notice Add or remove a funded function
     * @param actionType The type of action to execute
     * @param functionPosition The position of the funded function in fundedFunctions
     * @param adjusterType The adjuster contract to include for the funded function
     * @param functionName The signature of the function that gets funded
     * @param receiverContract The contract hosting the funded function
     */
    function modifyParameters(bytes32 actionType, uint256 functionPosition, uint256 adjusterType, bytes4 functionName, address receiverContract)
      external isAuthorized {
        if (actionType == "addFunction") {
          addFundedFunction(adjusterType, functionName, receiverContract);
        } else if (actionType == "removeFunction") {
          removeFundedFunction(functionPosition);
        }
        else revert("RewardAdjusterBundler/modify-unrecognized-param");

        emit ModifyParameters(actionType, functionPosition, adjusterType, functionName, receiverContract);
    }

    // --- Internal Logic ---
    /*
     * @notice Add a funded function
     * @param adjusterType The type of adjuster that recomputes the rewards offered by this function
     * @param functionName The name of the function offering rewards
     * @param receiverContract Contract that has the funded function
     */
    function addFundedFunction(uint256 adjusterType, bytes4 functionName, address receiverContract) internal {
        require(receiverContract != address(0), "RewardAdjusterBundler/null-receiver-contract");
        require(adjusterType <= 1, "RewardAdjusterBundler/invalid-adjuster-type");
        require(addedFunction[receiverContract][functionName] == 0, "RewardAdjusterBundler/function-already-added");
        require(fundedFunctionsAmount() < maxFunctions, "RewardAdjusterBundler/function-limit-reached");

        addedFunction[receiverContract][functionName] = 1;
        fundedFunctionNonce                           = addition(fundedFunctionNonce, 1);
        latestFundedFunction                          = fundedFunctionNonce;
        fundedFunctions[fundedFunctionNonce]          = FundedFunction(adjusterType, functionName, receiverContract);

        fundedFunctionsList.push(latestFundedFunction, false);

        emit AddFundedFunction(
          latestFundedFunction,
          adjusterType,
          functionName,
          receiverContract
        );
    }
    /*
     * @notice Remove a funded function
     * @param functionPosition The position of the funded function in fundedFunctions
     */
    function removeFundedFunction(uint256 functionPosition) internal {
        require(both(functionPosition <= latestFundedFunction, functionPosition > 0), "RewardAdjusterBundler/invalid-position");
        FundedFunction memory fundedFunction = fundedFunctions[functionPosition];

        require(addedFunction[fundedFunction.receiverContract][fundedFunction.functionName] == 1, "RewardAdjusterBundler/function-not-added");
        delete(addedFunction[fundedFunction.receiverContract][fundedFunction.functionName]);

        if (functionPosition == latestFundedFunction) {
          (, uint256 prevReceiver) = fundedFunctionsList.prev(latestFundedFunction);
          latestFundedFunction     = prevReceiver;
        }

        fundedFunctionsList.del(functionPosition);
        delete(fundedFunctions[functionPosition]);

        emit RemoveFundedFunction(functionPosition);
    }

    // --- Core Logic ---
    /*
     * @param Recopute all system coin rewards for all funded functions included in this contract
     */
    function recomputeAllRewards() external {
        // Start looping from the latest funded function
        uint256 currentFundedFunction = latestFundedFunction;

        FundedFunction memory fundedFunction;

        // While we still haven't gone through the entire list
        while (currentFundedFunction > 0) {
          fundedFunction = fundedFunctions[currentFundedFunction];
          if (fundedFunction.adjusterType == 0) {
            try fixedRewardAdjuster.recomputeRewards(fundedFunction.receiverContract, fundedFunction.functionName) {}
            catch(bytes memory /* revertReason */) {
              emit FailedRecomputeReward(fundedFunction.adjusterType, fundedFunction.receiverContract, fundedFunction.functionName);
            }
          } else {
            try minMaxRewardAdjuster.recomputeRewards(fundedFunction.receiverContract, fundedFunction.functionName) {}
            catch(bytes memory /* revertReason */) {
              emit FailedRecomputeReward(fundedFunction.adjusterType, fundedFunction.receiverContract, fundedFunction.functionName);
            }
          }
          // Continue looping
          (, currentFundedFunction) = fundedFunctionsList.prev(currentFundedFunction);
        }
    }

    // --- Getters ---
    /**
     * @notice Get the secondary tax receiver list length
     */
    function fundedFunctionsAmount() public view returns (uint256) {
        return fundedFunctionsList.range();
    }
    /**
     * @notice Check if a funded function index is in the list
     */
    function isFundedFunction(uint256 _fundedFunction) public view returns (bool) {
        if (_fundedFunction == 0) return false;
        return fundedFunctionsList.isNode(_fundedFunction);
    }
}

// deploy/setup the rewards bundler
contract BundlerDeployer {
    constructor() public {
        // deploy
        RewardAdjusterBundler bundler = new RewardAdjusterBundler(
            0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab, // GEB_FIXED_REWARDS_ADJUSTER
            0xbe0D9016714c64a877ed28fd3F3C7c8fF513d807, // GEB_MINMAX_REWARDS_ADJUSTER
            15 // maxFunctions
            );
            
        // add authorization to GEB_PAUSE_PROXY
        bundler.addAuthorization(0xa57A4e6170930ac547C147CdF26aE4682FA8262E);
        
        // add functions
        bundler.modifyParameters(
            "addFunction",
            0,                                                  // position, irrelevant when adding
            0,                                                  // type, fixed
            bytes4(0xf00df8b8),                                 // getRewardForPop(uint256,address)
            address(0xe1d5181F0DD039aA4f695d4939d682C4cF874086) // DEBT_POPPER_REWARDS
        );
        
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x59426fad),                                 // relayRate(uint256,address)
            address(0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB) // GEB_RRFM_SETTER_RELAYER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x8d7fb67a),                                 // reimburseCaller(address)
            address(0xE8063b122Bef35d6723E33DBb3446092877C6855) // MEDIANIZER_RAI_REWARDS_RELAYER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x8d7fb67a),                                 // reimburseCaller(address)
            address(0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde) // MEDIANIZER_ETH_REWARDS_RELAYER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x2761f27b),                                 // renumerateCaller(address)
            address(0x105b857583346E250FBD04a57ce0E491EB204BA3) // FSM_WRAPPER_ETH
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0xcb5ec87a),                                 // autoUpdateCeiling(address)
            address(0x54999Ee378b339f405a4a8a1c2f7722CD25960fa) // GEB_SINGLE_CEILING_SETTER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x36b8b425),                                 // recomputeOnAuctionSystemCoinLimit(address)
            address(0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7) // COLLATERAL_AUCTION_THROTTLER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0x341369c1),                                 // recomputeCollateralDebtFloor(address)
            address(0x0262Bd031B99c5fb99B47Dc4bEa691052f671447) // GEB_DEBT_FLOOR_ADJUSTER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0xbf1ad0db),                                 // adjustSurplusBuffer(address)
            address(0x1450f40E741F2450A95F9579Be93DD63b8407a25) // GEB_AUTO_SURPLUS_BUFFER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0xbbaf0133),                                 // setDebtAuctionInitialParameters(address)
            address(0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E) // GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER
        );
        bundler.modifyParameters(
            "addFunction",
            0, 
            1,                                                  // type, minMax
            bytes4(0xa8e2044e),                                 // recomputeSurplusAmountAuctioned(address)
            address(0xa43BFA2a04c355128F3f10788232feeB2f42FE98) // GEB_AUTO_SURPLUS_AUCTIONED
        );       
    
        // remove deployer auth
        bundler.removeAuthorization(address(this));
    }
}
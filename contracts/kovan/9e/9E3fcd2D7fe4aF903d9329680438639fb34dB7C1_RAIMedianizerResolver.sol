/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED
//pragma solidity 0.8.0;
pragma solidity ^0.6.7;

interface IRaiMedianizer {
    function lastUpdateTime() external view returns (uint256);
    function updateResult(address feeReceiver) external;
}

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}


contract RAIMedianizerResolver is IResolver {

    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "RAIMedianizerActionProxy/account-not-authorized");
        _;
    }
    
    // --- Variables ---
    uint16 constant MIN_UPDATE_DELAY = 60;
    address public raiMedianizer;
    uint16 public updateDelay;
    

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    
    event ModifyParameters(
      bytes32 parameter,
      uint16 val
    );
    
    constructor(address _raiMedianizer, uint16 _updateDelay) public {
        raiMedianizer = _raiMedianizer;
        require(_updateDelay >= MIN_UPDATE_DELAY, "RAIMedianizerResolver/update-delay-too-small");
	    updateDelay = _updateDelay;
        authorizedAccounts[msg.sender] = 1;
    }
    
    // --- Administration ---
    /*
    * @notice Change the addresses of contracts that this wrapper is connected to
    * @param parameter The contract whose address is changed
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "RAIMedianizerActionProxy/null-addr");
        if (parameter == "raimedianizer") {
          raiMedianizer = addr;
        }
        else revert("RAIMedianizerActionProxy/modify-unrecognized-param");
        
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    
    /*
    * @notify Modify a uint16 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint16 val) external isAuthorized {
        if (parameter == "updatedelay") {
          require(val >= MIN_UPDATE_DELAY, "RAIMedianizerResolver/update-delay-too-small");
          updateDelay = val;
        }
        else revert("RAIMedianizerResolver/");
        emit ModifyParameters(
          parameter,
          val
        );
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastUpdateTime = IRaiMedianizer(raiMedianizer).lastUpdateTime();

        // solhint-disable not-rely-on-time
        canExec = (block.timestamp - lastUpdateTime) > updateDelay;
        
        execPayload = abi.encodeWithSelector(IRaiMedianizer.updateResult.selector, address(0));

    }
}
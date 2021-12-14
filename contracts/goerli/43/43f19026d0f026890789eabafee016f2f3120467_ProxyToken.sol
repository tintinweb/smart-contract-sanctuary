/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyToken adapted and applied for token by pepihasenfuss.eth
pragma solidity >=0.4.22 <0.6.0;

contract AbstractReverseRegistrar {
  function claim(address owner) public returns (bytes32);
  function claimWithResolver(address owner, address resolver) public returns (bytes32);
  function setName(string memory name) public returns (bytes32);
  function node(address addr) public pure returns (bytes32);
}

contract ProxyToken {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;

    mapping (address => uint256) private balances;
    mapping (address => mapping  (address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(address _masterCopy) public payable
    {
      masterCopy = _masterCopy;
    }
    
    function () external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyGroupWallet adapted and applied for GroupWallet by pepihasenfuss.eth

pragma solidity >=0.4.22 <0.6.0;

contract ProxyGroupWallet {
    address internal masterCopy;

    mapping(uint256 => uint256) private tArr;
    address[]                   private owners;
    
    address internal GWF;                                                       // GWF - GroupWalletFactory contract
    mapping(uint256 => bytes)   private structures;

    event TestReturnData(address sender, bytes returnData);
    event TestReturnLength(address sender, uint256 value);
    event GroupWalletDeployed(address sender, uint256 members, uint256 timeStamp);
    event GroupWalletMessage(bytes32 msg);
    event Deposit(address from, uint256 value);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);

    constructor(address _masterCopy, AbstractReverseRegistrar _reverse, string memory _domain) public payable
    {
      _reverse.claim  ( address(this) );
      _reverse.setName( _domain );

      masterCopy = _masterCopy;
    }
    
    function () external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}
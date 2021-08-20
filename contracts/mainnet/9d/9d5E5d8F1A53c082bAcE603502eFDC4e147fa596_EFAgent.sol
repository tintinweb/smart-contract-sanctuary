/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: 
// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/utils/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}

contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: contracts/core/EFAgent.sol

pragma solidity >=0.4.21 <0.6.0;



contract EFAgent is TrustListTools {
    constructor (address trustlist_addr) public TrustListTools(trustlist_addr) {
    }

    // to be used for ERC20
    function exec(address callee, bytes calldata payload) external is_trusted(msg.sender) returns (bytes memory)  {
        (bool success, bytes memory returnData) = address(callee).call(payload);
        require(success, "callee return failed when executing payload");
        return returnData;
    }

    // fallback function for receive ETH
    event ReceiveETH(uint256);
    function() external payable {
        emit ReceiveETH(msg.value);
    }

    // to be used for ETH
    function exec(address callee, uint256 ETH_amount, bytes calldata payload) external payable is_trusted(msg.sender) returns (bytes memory) {
        (bool success, bytes memory returnData) = address(callee).call.value(ETH_amount)(payload);
        require(success, "callee return failed when executing payload");
        return returnData;
    }
}
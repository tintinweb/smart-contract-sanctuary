pragma solidity >=0.6.6;

import "./library/Ownable.sol";
import "./interfaces/IUpgradable.sol";

contract Upgradable is Ownable, IUpgradable {
    address public oracle;

    constructor (address oracleAddress) public {
        oracle = oracleAddress;
    }

    function getOracleAddress() public override(IUpgradable) returns (address) {
        return oracle;
    }

    function upgradeOracleAddress (address newOracle) public onlyOwner {
        oracle = newOracle;
    }
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IUpgradable {
  function getOracleAddress() external returns (address);
}

pragma solidity >=0.6.6;

contract Ownable {
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}
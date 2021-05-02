/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

/***
* Shoutouts:
*
* Bytecode origin https://www.reddit.com/r/ethereum/comments/6ic49q/any_assembly_programmers_willing_to_write_a/dj5ceuw/
* Modified version of Vitalik's https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
* Credits to Jorge Izquierdo (@izqui) for coming up with this design here: https://gist.github.com/izqui/7f904443e6d19c1ab52ec7f5ad46b3a8
* Credits to Stefan George (@Georgi87) for inspiration for many of the improvements from Gnosis Safe: https://github.com/gnosis/gnosis-safe-contracts
*
* This version has many improvements over the original @izqui's library like using REVERT instead of THROWing on failed calls.
* It also implements the awesome design pattern for initializing code as seen in Gnosis Safe Factory: https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/ProxyFactory.sol
* but unlike this last one it doesn't require that you waste storage on both the proxy and the proxied contracts (v. https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/Proxy.sol#L8 & https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol#L14)
*
*
* v0.0.2
* The proxy is now only 60 bytes long in total. Constructor included.
* No functionalities were added. The change was just to make the proxy leaner.
*
* v0.0.3
* Thanks @dacarley for noticing the incorrect check for the subsequent call to the proxy. 🙌
* Note: I'm creating a new version of this that doesn't need that one call.
*       Will add tests and put this in its own repository soon™.
*
* v0.0.4
* All the merit in this fix + update of the factory is @dacarley 's. 🙌
* Thank you! 😄
*
* Potential updates can be found at https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
*
***/

pragma solidity ^0.4.18;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  address public implementation;
  constructor(address _implementation) {
    implementation = _implementation;
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    address _impl = implementation;
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}
pragma solidity ^0.4.19;


interface IDoneth {
  function init() public;
}

/* solhint-disable no-inline-assembly, indent, state-visibility, avoid-low-level-calls */

contract ProxyFactory {

    address public target;
    function ProxyFactory() public {}

    event ProxyDeployed(address proxyAddress, address targetAddress);

    function createProxy(address _target)
        public
        payable
        returns (address proxyContract)
    {
        Proxy prox = new Proxy(_target);
        IDoneth(address(prox)).init();
        ProxyDeployed(address(prox), _target);
    }
}
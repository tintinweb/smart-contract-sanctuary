/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/solidity/proxy/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/solidity/interface/INFTXEligibility.sol

pragma solidity ^0.8.0;

interface INFTXEligibility {
    // Read functions.
    function name() external pure returns (string memory);
    function finalized() external view returns (bool);
    function targetAsset() external pure returns (address);
    function checkAllEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory);
    function checkAllIneligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkIsEligible(uint256 tokenId) external view returns (bool);

    // Write functions.
    function __NFTXEligibility_init_bytes(bytes calldata configData) external;
    function beforeMintHook(uint256[] calldata tokenIds) external;
    function afterMintHook(uint256[] calldata tokenIds) external;
    function beforeRedeemHook(uint256[] calldata tokenIds) external;
    function afterRedeemHook(uint256[] calldata tokenIds) external;
}


// File contracts/solidity/eligibility/NFTXEligibility.sol

pragma solidity ^0.8.0;


// This is a contract meant to be inherited and overriden to implement eligibility modules. 
abstract contract NFTXEligibility is INFTXEligibility, Initializable {
  function name() public pure override virtual returns (string memory);
  function finalized() public view override virtual returns (bool);
  function targetAsset() public pure override virtual returns (address);
  
  function __NFTXEligibility_init_bytes(bytes memory initData) public override virtual;

  function checkIsEligible(uint256 tokenId) external view override virtual returns (bool) {
      return _checkIfEligible(tokenId);
  }

  function checkEligible(uint256[] calldata tokenIds) external override virtual view returns (bool[] memory) {
      bool[] memory eligibile = new bool[](tokenIds.length);
      for (uint256 i = 0; i < tokenIds.length; i++) {
          eligibile[i] = _checkIfEligible(tokenIds[i]);
      }
      return eligibile;
  }

  function checkAllEligible(uint256[] calldata tokenIds) external override virtual view returns (bool) {
      for (uint256 i = 0; i < tokenIds.length; i++) {
          // If any are not eligible, end the loop and return false.
          if (!_checkIfEligible(tokenIds[i])) {
              return false;
          }
      }
      return true;
  }

  // Checks if all provided NFTs are NOT eligible. This is needed for mint requesting where all NFTs 
  // provided must be ineligible.
  function checkAllIneligible(uint256[] calldata tokenIds) external override virtual view returns (bool) {
      for (uint256 i = 0; i < tokenIds.length; i++) {
          // If any are eligible, end the loop and return false.
          if (_checkIfEligible(tokenIds[i])) {
              return false;
          }
      }
      return true;
  }

  function beforeMintHook(uint256[] calldata tokenIds) external override virtual {}
  function afterMintHook(uint256[] calldata tokenIds) external override virtual {}
  function beforeRedeemHook(uint256[] calldata tokenIds) external override virtual {}
  function afterRedeemHook(uint256[] calldata tokenIds) external override virtual {}

  // Override this to implement your module!
  function _checkIfEligible(uint256 _tokenId) internal view virtual returns (bool);
}


// File contracts/solidity/eligibility/NFTXRangeEligibility.sol

pragma solidity ^0.8.0;

// Maybe use guardian here?
contract NFTXRangeEligibility is NFTXEligibility {
    function name() public pure override virtual returns (string memory) {
        return "Range";
    }

    function finalized() public view override virtual returns (bool) {
        return true;
    }

    function targetAsset() public pure override virtual returns (address) {
        return address(0);
    }

    uint256 public rangeStart;
    uint256 public rangeEnd;

    struct Config {
        uint256 rangeStart;
        uint256 rangeEnd;
    }
    event RangeSet(uint256 rangeStart, uint256 rangeEnd);
    event NFTXEligibilityInit(
        uint256 rangeStart,
        uint256 rangeEnd
    );

    function __NFTXEligibility_init_bytes(bytes memory _configData)
        public
        override
        virtual
        initializer
    {
        (uint256 _rangeStart, uint256 _rangeEnd) = abi.decode(_configData, (uint256, uint256));
        __NFTXEligibility_init(_rangeStart, _rangeEnd);
    }

    function __NFTXEligibility_init(
        uint256 _rangeStart,
        uint256 _rangeEnd
    ) public initializer {
        require(_rangeStart <= _rangeEnd, "start > end");
        rangeStart = _rangeStart;
        rangeEnd = _rangeEnd;
        emit RangeSet(_rangeStart, _rangeEnd);
        emit NFTXEligibilityInit(_rangeStart, _rangeEnd);
    }

    function _checkIfEligible(uint256 _tokenId)
        internal
        view
        override
        virtual
        returns (bool)
    {
        return _tokenId >= rangeStart && _tokenId <= rangeEnd;
    }
}
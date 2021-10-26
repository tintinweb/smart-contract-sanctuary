//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Interfaces.sol";

contract Ticker {
    ENSRegistryWithFallback ens;

    constructor() {
        ens = ENSRegistryWithFallback(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
        // The ens registry address is shared across testnets and mainnet
    }

    // Enter 'uni' to lookup uni.tkn.eth
    function addressFor(string calldata _name) public view returns (address) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }

    struct Metadata {
        address contractAddress;
        string name;
        string url;
        string avatar;
        string description;
        string notice;
        string twitter;
        string github;
    }

    function infoFor(string calldata _name) public view returns (Metadata memory) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return Metadata(
            resolver.addr(namehash),
            resolver.text(namehash, "name"),
            resolver.text(namehash, "url"),
            resolver.text(namehash, "avatar"),
            resolver.text(namehash, "description"),
            resolver.text(namehash, "notice"),
            resolver.text(namehash, "com.twitter"),
            resolver.text(namehash, "com.github")
        );

    }
    
    // Calculate the namehash offchain using eth-ens-namehash to save gas costs.
    // Better for write queries that require gas
    // Library: https://npm.runkit.com/eth-ens-namehash
    function gasEfficientFetch(bytes32 namehash) public view returns (address) {
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }
        
    // Get an account's balance using a ticker symbol
    function balanceWithTicker(address user, string calldata tickerSymbol) public view returns (uint) {
        IERC20 tokenContract = IERC20(addressFor(tickerSymbol));
        return tokenContract.balanceOf(user);
    }
}

interface ETHRegistrarController {
  function MIN_REGISTRATION_DURATION (  ) external view returns ( uint256 );
  function available ( string calldata name ) external view returns ( bool );
  function commit ( bytes32 commitment ) external;
  function commitments ( bytes32 ) external view returns ( uint256 );
  function isOwner (  ) external view returns ( bool );
  function makeCommitment ( string calldata name, address owner, bytes32 secret ) external pure returns ( bytes32 );
  function makeCommitmentWithConfig ( string calldata name, address owner, bytes32 secret, address resolver, address addr ) external pure returns ( bytes32 );
  function maxCommitmentAge (  ) external view returns ( uint256 );
  function minCommitmentAge (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function register ( string calldata name, address owner, uint256 duration, bytes32 secret ) external payable;
  function registerWithConfig ( string calldata name, address owner, uint256 duration, bytes32 secret, address resolver, address addr ) external payable;
  function renew ( string calldata name, uint256 duration ) external payable;
  function renounceOwnership (  ) external;
  function rentPrice ( string calldata name, uint256 duration ) external view returns ( uint256 );
  function setCommitmentAges ( uint256 _minCommitmentAge, uint256 _maxCommitmentAge ) external;
  function setPriceOracle ( address _prices ) external;
  function supportsInterface ( bytes4 interfaceID ) external pure returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function valid ( string calldata name ) external pure returns ( bool );
  function withdraw (  ) external;
}

interface BaseRegistrarImplementation {
  function GRACE_PERIOD (  ) external view returns ( uint256 );
  function addController ( address controller ) external;
  function approve ( address to, uint256 tokenId ) external;
  function available ( uint256 id ) external view returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function baseNode (  ) external view returns ( bytes32 );
  function controllers ( address ) external view returns ( bool );
  function ens (  ) external view returns ( address );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function isOwner (  ) external view returns ( bool );
  function nameExpires ( uint256 id ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function reclaim ( uint256 id, address owner ) external;
  function register ( uint256 id, address owner, uint256 duration ) external returns ( uint256 );
  function registerOnly ( uint256 id, address owner, uint256 duration ) external returns ( uint256 );
  function removeController ( address controller ) external;
  function renew ( uint256 id, uint256 duration ) external returns ( uint256 );
  function renounceOwnership (  ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes calldata _data ) external;
  function setApprovalForAll ( address to, bool approved ) external;
  function setResolver ( address resolver ) external;
  function supportsInterface ( bytes4 interfaceID ) external view returns ( bool );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
}

interface ENSRegistryWithFallback {
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function old (  ) external view returns ( address );
  function owner ( bytes32 node ) external view returns ( address );
  function recordExists ( bytes32 node ) external view returns ( bool );
  function resolver ( bytes32 node ) external view returns ( address );
  function setApprovalForAll ( address operator, bool approved ) external;
  function setOwner ( bytes32 node, address owner ) external;
  function setRecord ( bytes32 node, address owner, address resolver, uint64 ttl ) external;
  function setResolver ( bytes32 node, address resolver ) external;
  function setSubnodeOwner ( bytes32 node, bytes32 label, address owner ) external returns ( bytes32 );
  function setSubnodeRecord ( bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl ) external;
  function setTTL ( bytes32 node, uint64 ttl ) external;
  function ttl ( bytes32 node ) external view returns ( uint64 );
}

pragma experimental ABIEncoderV2;

interface PublicResolver {
  function ABI ( bytes32 node, uint256 contentTypes ) external view returns ( uint256, bytes memory );
  function addr ( bytes32 node ) external view returns ( address );
  function addr ( bytes32 node, uint256 coinType ) external view returns ( bytes memory );
  function authorisations ( bytes32, address, address ) external view returns ( bool );
  function clearDNSZone ( bytes32 node ) external;
  function contenthash ( bytes32 node ) external view returns ( bytes memory );
  function dnsRecord ( bytes32 node, bytes32 name, uint16 resource ) external view returns ( bytes memory );
  function hasDNSRecords ( bytes32 node, bytes32 name ) external view returns ( bool );
  function interfaceImplementer ( bytes32 node, bytes4 interfaceID ) external view returns ( address );
  function multicall ( bytes[] calldata data ) external returns ( bytes[] memory results );
  function name ( bytes32 node ) external view returns ( string memory );
  function pubkey ( bytes32 node ) external view returns ( bytes32 x, bytes32 y );
  function setABI ( bytes32 node, uint256 contentType, bytes calldata data ) external;
  function setAddr ( bytes32 node, uint256 coinType, bytes calldata a ) external;
  function setAddr ( bytes32 node, address a ) external;
  function setAuthorisation ( bytes32 node, address target, bool isAuthorised ) external;
  function setContenthash ( bytes32 node, bytes calldata hash ) external;
  function setDNSRecords ( bytes32 node, bytes calldata data ) external;
  function setInterface ( bytes32 node, bytes4 interfaceID, address implementer ) external;
  function setName ( bytes32 node, string calldata name ) external;
  function setPubkey ( bytes32 node, bytes32 x, bytes32 y ) external;
  function setText ( bytes32 node, string calldata key, string calldata value ) external;
  function supportsInterface ( bytes4 interfaceID ) external pure returns ( bool );
  function text ( bytes32 node, string calldata key ) external view returns ( string memory );
}

// Chainlink Gas Price Oracle
// Authorized proxy link contract from: https://docs.chain.link/docs/ethereum-addresses#config
contract EACAggregatorProxy {
  function acceptOwnership (  ) external {  }
  function accessController (  ) external view returns ( address ) {  }
  function aggregator (  ) external view returns ( address ) {  }
  function confirmAggregator ( address _aggregator ) external {  }
  function decimals (  ) external view returns ( uint8 ) {  }
  function description (  ) external view returns ( string memory ) {  }
  function getAnswer ( uint256 _roundId ) external view returns ( int256 ) {  }
  function getRoundData ( uint80 _roundId ) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ) {  }
  function getTimestamp ( uint256 _roundId ) external view returns ( uint256 ) {  }
  function latestAnswer (  ) external view returns ( int256 ) {
      // Stub out 55 gwei static gas price for querying on testnet
      return 55555555555; //   return 0x0000000000000000000000000000000000000000000000000000000d4576fa00;
  }
  function latestRound (  ) external view returns ( uint256 ) {  }
  function latestRoundData (  ) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ) {  }
  function latestTimestamp (  ) external view returns ( uint256 ) {  }
  function owner (  ) external view returns ( address ) {  }
  function phaseAggregators ( uint16 ) external view returns ( address ) {  }
  function phaseId (  ) external view returns ( uint16 ) {  }
  function proposeAggregator ( address _aggregator ) external {  }
  function proposedAggregator (  ) external view returns ( address ) {  }
  function proposedGetRoundData ( uint80 _roundId ) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ) {  }
  function proposedLatestRoundData (  ) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound ) {  }
  function setController ( address _accessController ) external {  }
  function transferOwnership ( address _to ) external {  }
  function version (  ) external view returns ( uint256 ) {  }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
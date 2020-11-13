pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

contract AtlasDeployer {

    address public immutable tokenImplementation;
    address public immutable timelockImplementation;
    address public immutable governanceImplementation;
    
    struct OrgData {
        /// @notice Name of the organisation
        string organisationName;

        /// @notice Token Symbol
        string symbol;

        /// @notice Initial supply of the token
        uint256 initialSupply;

        /// @notice Address to receive the initial supply
        address tokenOwner;

        /// @notice Timestamp at which minting more tokens is allowed
        uint256 mintingAllowedAfter;

        /// @notice Cap for miniting everytime
        uint8 mintCap;

        /// @notice Minimun time to minting the tokens again 
        uint32 minimumTimeBetweenMints;

        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. Should be lower than initial supply
        uint256 quorumVotes;

        /// @notice The number of votes required in order for a voter to become a proposer
        uint256 proposalThreshold;

        /// @notice The delay before voting on a proposal may take place, once proposed. In number of blocks
        uint256 votingDelay;

        /// @notice The duration of voting on a proposal, in number blocks
        uint256 votingPeriod;

        /// @notice Delay in the timelock contract
        uint256 delay;

        /// @notice Minimum delay in the timelock contract
        uint256 minDelay;

        /// @notice Maximum delay in the timelock contract
        uint256 maxDelay;
    }

    event LogDeployedOrg(
        address indexed token_,
        address indexed timelock_,
        address indexed governance_
    );

    constructor(address token_, address timelock_, address governance_) public {
        tokenImplementation = token_;
        timelockImplementation = timelock_;
        governanceImplementation = governance_;
    }

    function _deployer() private returns (address token, address timelock, address governance) {
        uint timestamp_ = now;

        token = _deployLogic(timestamp_, tokenImplementation);
        timelock = _deployLogic(timestamp_, timelockImplementation);
        governance = _deployLogic(timestamp_, governanceImplementation);
    }

    function _deployLogic(uint timestamp_, address logic) private returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(timestamp_)); // TODO : change salt to something that we can control
        bytes20 targetBytes = bytes20(logic);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create2(0, clone, 0x37, salt)
        }
    }

    function createOrg(OrgData calldata d) external returns (address token, address timelock, address governance) {

        require(d.initialSupply > d.quorumVotes, "Initial Supply should be greater than quoroum");
        require(d.initialSupply > d.proposalThreshold, "Initial Supply should be greater than proposal threshold");
        
        (token, timelock, governance) = _deployer();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,address,uint256,uint8,uint32)",
            d.organisationName,
            d.symbol,
            d.initialSupply,
            d.tokenOwner,
            timelock,
            d.mintingAllowedAfter,
            d.mintCap,
            d.minimumTimeBetweenMints
        );

        (bool success,) = token.call(initData);
        require(success, "Failed to initialize token");

        initData = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256)",
            governance,
            d.delay,
            d.minDelay,
            d.maxDelay
        );

        (success,) = timelock.call(initData);
        require(success, "Failed to initialize timelock");

        initData = abi.encodeWithSignature(
            "initialize(string,address,address,uint256,uint256,uint256,uint256)",
            string(abi.encodePacked(d.organisationName, " Governor Alpha")),
            token,
            timelock,
            d.quorumVotes,
            d.proposalThreshold,
            d.votingDelay,
            d.votingPeriod
        );

        (success,) = governance.call(initData);
        require(success, "Failed to initialize governance");

        emit LogDeployedOrg(token, timelock, governance);
    }
}
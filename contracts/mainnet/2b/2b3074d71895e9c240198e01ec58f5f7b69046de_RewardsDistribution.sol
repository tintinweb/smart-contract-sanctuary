/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity >=0.4.24;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


pragma solidity >=0.4.24;

contract RewardsDistribution is Owned {

    /**
     * @notice Authorised address able to call distributeReward
     */
    address public authority;

    /**
     * @notice Address of reward token
     */
    address public rewardAddress;

    constructor(
        address _owner,
        address _authority,
        address _rewardAddress
    ) public Owned(_owner) {
        authority = _authority;
        rewardAddress = _rewardAddress;
    }

    // ========== EXTERNAL SETTERS ==========

    function setRewardAddress(address _rewardAddress) public onlyOwner {
        rewardAddress = _rewardAddress;
    }

    /**
     * @notice Set the address of the contract authorised to call distributeReward()
     * @param _authority Address of the authorised calling contract.
     */
    function setAuthority(address _authority) public onlyOwner {
        authority = _authority;
    }

    function distributeReward(address destination, uint amount) public returns (bool) {
        require(amount > 0, "Nothing to distribute");
        require(destination != address(0), "destination address is not set");
        require(msg.sender == authority, "Caller is not authorised");
        require(rewardAddress != address(0), "reward address is not set");
        require(
            IERC20(rewardAddress).balanceOf(address(this)) >= amount,
            "RewardsDistribution contract does not have enough tokens to distribute"
        );

        // Transfer the reward token
        IERC20(rewardAddress).transfer(destination, amount);
        // If the contract implements RewardsDistributionRecipient.sol, inform it how many reward token its received.
        bytes memory payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", amount);
        // solhint-disable avoid-low-level-calls
        bool success = destination.call(payload);
        if (!success) {
            // Note: we're ignoring the return value as it will fail for contracts that do not implement RewardsDistributionRecipient.sol
        }
        emit RewardsDistributed(amount);
        return true;
    }

    /* ========== Events ========== */
    event RewardsDistributed(uint amount);
}
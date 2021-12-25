/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// File: contracts/AuctionApplication.sol


pragma solidity 0.8.10;

interface ERC20TokenInterface {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) external returns (uint256);
}

/**
 * @title AuctionApplication
 * @dev This is a primary contract for cellchain slot candle auction. 
        Participants deploy their own participant contract through this contract.
        This starts and finishes auction, and selects the winner participant and mint slot NFT for it.
 */
contract ApplicationPrimary {
    event Apply(
        uint256 auctionID,
        address indexed participant,
        bytes32  project_name,
        bool project_type,
        uint256 st_range,
        uint256 end_range,
        bytes32 metaURI,
        address sc_address
    );

    event ClaimFund(uint256 projectID, address receiver);

    event BID(
        uint256 projectID,
        address bidder,
        uint256 timestamp,
        address tokenAddress,
        uint256 amount,
        uint8 st_range,
        uint8 end_range
    );

    uint256 public constant PLEDGE_AMOUNT = 1000 * (10**18);
    address public owner;

    address CELL = 0x0F6f1C32642cAC8d865FAF4e2ea87996f95515Cc;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Applicants who want to own the slot should apply for the slot auction with pledge.
     */
    function applyTo(
        uint256 auctionID,
        string memory _name,
        bool _type,
        uint8 st_range,
        uint8 end_range,
        string memory _metaURI,
        address token_address
    ) external {
        ERC20TokenInterface(CELL).transferFrom(
            msg.sender,
            address(this),
            PLEDGE_AMOUNT
        );

        emit Apply(
            auctionID,
            msg.sender,
            bytes32(bytes(_name)),
            _type,
            st_range,
            end_range,
            bytes32(bytes(_metaURI)),
            token_address
        );
    }

    /**
   * @notice Owner can approve or decline the applications. Approved applications can participate in the auction.
      The pledge will return back to applicant.
   */
    function claimFund(uint256 projectID, address receiver) external onlyOwner {
        ERC20TokenInterface(CELL).transfer(receiver, PLEDGE_AMOUNT);
        emit ClaimFund(projectID, receiver);
    }

    /**
     * @notice Vote funds to the project. if it is a private project, only the manager can vote to it.
     */
    function bid(
        uint256 projectID,
        uint8 st_range,
        uint8 end_range,
        uint256 amount,
        address tokenAddress
    ) external {
        require(
            st_range <= end_range,
            "End time must be bigger than start time"
        );
        require(amount > 0, "You should vote at least more than 0");

        ERC20TokenInterface(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit BID(
            projectID,
            msg.sender,
            block.timestamp,
            tokenAddress,
            amount,
            st_range,
            end_range
        );
    }

    /**
     * @notice Transfer the ownership of the primary contract.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner address should not be null");
        owner = newOwner;
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract HashUpStorageV0 {

    struct JsonInterface {
        Creator        creator;
        GameContract[] userContracts;
        GameContract[] requestedContracts;
        GameContract[] userRequestedContracts;
        GameContract[] approvedContracts;
        GameContract[] userApprovedContracts;
        address        admin;
        address        moderator;
    }

    struct Creator {
        string  name;
        string  company;
        string  logoUrl;
        string  description;
        address CreatorAddress;
    }

    struct GameContract {
        address GameContractAddress;
        Creator creator;
    }

    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea;

    mapping(address => Creator) public creators;

    /**
     *  1. Right after GameContract Creation - user's private store.
     */
    mapping(address => GameContract[]) public userContracts;

    /**
     *  2. After user submission.
     */
    GameContract[] public requestedContracts;
    mapping(address => GameContract[]) public userRequestedContracts;

    // This is used to access the user-specific store array based on
    //   the game contract address.
    mapping(address => address) public GameContractToCreatorAddress;

    /**
     *  3. After approval.
     */
    GameContract[] public approvedContracts;
    mapping(address => GameContract[]) public userApprovedContracts;

    address admin;
    address moderator;

    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not the owner");
        _;
    }

    modifier isAdminOrModerator() {
        require(msg.sender == admin || msg.sender == moderator);
        _;
    }

    modifier isExperienced() {
        require(
            IERC20(Hash).balanceOf(msg.sender) >= 1_000_000_000_000_000_000_000_000,
            "Inexperienced"
        );
        _;
    }

    modifier isPublisherOrExperienced(address targetContract) {
        require(
            msg.sender == GameContractToCreatorAddress[targetContract] ||
            IERC20(Hash).balanceOf(msg.sender) >= 1_000_000_000_000_000_000_000_000,
            "Not a publisher nor experienced"
        );
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setCreator(
        string memory name_,
        string memory company_,
        string memory logoUrl_,
        string memory description_
    ) public returns (Creator memory) {
        creators[msg.sender] = Creator(
            name_,
            company_,
            logoUrl_,
            description_,
            msg.sender
        );
        return creators[msg.sender];
    }

    function getCreator(address user) public view returns (Creator memory) {
        return creators[user];
    }

    function setNewAdmin(address newAdmin) public isAdmin returns (address) {
        admin = newAdmin;
        return newAdmin;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function setModerator(
        address moderator_
    )
    public
    isAdmin
    returns (address)
    {
        moderator = moderator_;
        return moderator_;
    }

    function getModerator() public view returns (address) {
        return moderator;
    }

    function pushUserContract(
        address userContract_
    )
    public
    returns (address)
    {
        userContracts[msg.sender].push(
            GameContract(
                userContract_,
                creators[msg.sender]
            ));

        GameContractToCreatorAddress[userContract_] = msg.sender;

        return userContract_;
    }

    function getUserContracts(
        address user
    )
    public
    view
    returns (GameContract[] memory)
    {
        return userContracts[user];
    }

    function requestContract(
        address requestedContract_
    )
    public
    returns (address)
    {
        address creatorAddress = GameContractToCreatorAddress[requestedContract_];

        uint256 requestedContractIndex = find(
            userContracts[creatorAddress],
            requestedContract_
        );

        GameContract memory requestedContract =
            userContracts[creatorAddress][requestedContractIndex];

        /**
         * Push the token both to the user-specific requests store as well
         * as to the global one.
         */
        userRequestedContracts[creatorAddress].push(
            requestedContract
        );
        requestedContracts.push(
            requestedContract
        );

        /**
         * Remove the pushed token from the user's specific requests store.
         */
        userContracts[creatorAddress][requestedContractIndex] =
            userContracts[creatorAddress][userContracts[creatorAddress].length - 1];
        userContracts[creatorAddress].pop();

        return requestedContract_;
    }

    function withdrawContractRequest(
        address requestedContract_
    )
    public
    isPublisherOrExperienced(requestedContract_)
    {
        // Target's address.
        address creatorAddress = GameContractToCreatorAddress[requestedContract_];

        uint256 userContractIndex = find(
            userRequestedContracts[creatorAddress],
            requestedContract_
        );
        uint256 contractIndex = find(
            requestedContracts,
            requestedContract_
        );

        /**
         * Push back to target's private token store (the token was once
         * removed upon submitting a request on their behalf).
         */
        userContracts[creatorAddress].push(
            userRequestedContracts[creatorAddress][userContractIndex]
        );

        /**
         * Remove the pushed-back token from the user's specific requests store.
         */
        userRequestedContracts[creatorAddress][userContractIndex] =
            userRequestedContracts[creatorAddress][
                userRequestedContracts[creatorAddress].length - 1
            ];
        userRequestedContracts[creatorAddress].pop();

        /**
         * Remove the pushed-back token from the global requests store.
         */
        requestedContracts[contractIndex] =
            requestedContracts[requestedContracts.length - 1];
        requestedContracts.pop();
    }

    function approveContract(
        address approvedContract_
    )
    public
    isExperienced
    returns (address)
    {
        address userAddress = GameContractToCreatorAddress[approvedContract_];

        /**
         * Pick `request` indices of GameContracts which will end up in the
         *   `approved` arrays.
         */
        uint256 userContractIndex = find(
            userRequestedContracts[userAddress],
            approvedContract_
        );
        uint256 contractIndex = find(
            requestedContracts,
            approvedContract_
        );

        GameContract memory approvedContract =
            userRequestedContracts[userAddress][userContractIndex];

        /**
         * Push the token both to the user-specific approved store as well
         * as to the global one.
         */
        userApprovedContracts[msg.sender].push(
            approvedContract
        );
        approvedContracts.push(
            approvedContract
        );

        /**
         * Remove the pushed token from the user's specific requests store.
         */
        userRequestedContracts[userAddress][userContractIndex] =
            userRequestedContracts[userAddress][
                userRequestedContracts[userAddress].length - 1
            ];
        userRequestedContracts[userAddress].pop();

        /**
         * Remove the pushed-back token from the global requests store.
         */
        requestedContracts[contractIndex] =
            requestedContracts[requestedContracts.length - 1];
        requestedContracts.pop();

        emit AddToGameCap(approvedContract_);

        return approvedContract_;
    }

    function getUserRequestedContracts(
        address user
    )
    public
    view
    returns (GameContract[] memory)
    {
        return userRequestedContracts[user];
    }

    function getRequestedContracts()
    public
    view
    returns (GameContract[] memory)
    {
        return requestedContracts;
    }

    function getUserApprovedContracts(
        address user
    )
    public
    view
    returns (GameContract[] memory)
    {
        return userApprovedContracts[user];
    }

    function getApprovedContracts()
    public
    view
    returns (GameContract[] memory)
    {
        return approvedContracts;
    }

    function getCreatorAddressFromGameContractAddress(
        address gameContract
    )
    public
    view
    returns (address)
    {
        return GameContractToCreatorAddress[gameContract];
    }

    event AddToGameCap(
        address indexed userContract
    );

    /**
     * Looks up the element's index in the array given.
     */
    function find(
        GameContract[] memory contracts,
        address contractAddress_
    )
    pure
    internal
    returns (uint256)
    {
        for (uint256 i = 0; i < contracts.length; ++i) {
            if (contracts[i].GameContractAddress == contractAddress_) {
                return i;
            }
        }
        revert("No such contract found");
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.7.0;

/// @title Game
/// @author Gideon Grinberg
/// @notice The main contract for the game.
/// @dev Weird design pattern: stores large chunks of data in event logs, since it's cheaper than storing them in memory.
contract Game {
    /// @notice Used to create a new scene.
    /// @dev Creates a new scene and emits it's data to the logs. See contract-level comment.
    event Scene(uint256 indexed id, string sceneText, bytes32[] choiceTexts);

    mapping(uint256 => mapping(uint256 => uint256)) connections; // Scene -> Choice -> Scene. Get a scene from another scene's choice.
    mapping(uint256 => uint256) choices; // Scene -> number of choices

    mapping(uint256 => address) authors; // Scene -> Scene's author.
    mapping(address => string) authorSignatures; // Author -> Author's Signature.

    uint256 sceneCount; // Number of scenes
    uint256 connectionCount; // Number of possible choices

    /// @notice Creates a new instance of the contract with an initial scene.
    /// @param sceneText The first scene's text.
    /// @param choiceTexts The first scene's choices.
    constructor(string memory sceneText, bytes32[] memory choiceTexts) public {
        require(choiceTexts.length > 0, "Choices array was empty.");

        choices[0] = choiceTexts.length;
        connectionCount = choiceTexts.length;
        authors[0] = msg.sender;

        emit Scene(0, sceneText, choiceTexts);
    }

    /// @notice Adds a new scene to the game.
    /// @dev Emits a new scene to the log. See contract-level docstring for info.
    function addScene(
        uint256 fromScene,
        uint256 fromChoice,
        string memory sceneText,
        bytes32[] memory choiceTexts
    ) public {
        require(
            connectionCount + choiceTexts.length > 1,
            "No valid connections."
        );
        require(bytes(sceneText).length > 0, "Scene was empty.");
        require(fromChoice < choices[fromScene], "Choice does not exist.");
        require(
            connections[fromScene][fromChoice] == 0,
            "Choice is undefined."
        );

        for (uint256 i = 0; i < choiceTexts.length; i++) {
            require(choiceTexts[i].length > 0, "choiceLength");
        }

        sceneCount++;
        connectionCount += choiceTexts.length - 1;

        connections[fromScene][fromChoice] = sceneCount;
        choices[sceneCount] = choiceTexts.length;
        authors[sceneCount] = msg.sender;

        emit Scene(sceneCount, sceneText, choiceTexts);
    }

    /// @notice Adds an author's signature.
    /// @param signature The signature to add.
    function addSignature(string memory signature) public {
        authorSignatures[msg.sender] = signature;
    }

    /// @notice Gets a signature from a scene
    /// @param scene The scene ID.
    /// @return The scene's author's signature.
    function getSignature(uint256 scene) public view returns (string memory) {
        return authorSignatures[authors[scene]];
    }

    /// @notice Gets the specified scene's author.
    /// @param scene The scene ID.
    /// @return The author's address.
    function getAuthor(uint256 scene) public view returns (address) {
        return authors[scene];
    }

    /// @notice Gets the number of possible connections.
    /// @return The number of possible connections.
    function getConnectionCount() public view returns (uint256) {
        return connectionCount;
    }

    function getSceneCount() public view returns (uint256) {
        return sceneCount;
    }

    /// @notice Gets the scene that an option points to.
    /// @param fromScene The originating scene.
    /// @param fromChoice The originating choice.
    /// @return The scene that the choice points to, in the form of an ID.
    function getNextScene(uint256 fromScene, uint256 fromChoice)
        public
        view
        returns (uint256)
    {
        return connections[fromScene][fromChoice];
    }
}
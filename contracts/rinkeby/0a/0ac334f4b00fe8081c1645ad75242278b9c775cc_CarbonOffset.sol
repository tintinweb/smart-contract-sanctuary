/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

struct BlockRange {
    uint256 start;
    uint256 end;
}

struct OffsetToken {
    string id;
    address payeeAddress;
    uint256 numCredits;
    BlockRange blockRange;
}

struct OffsetCreditIssue {
    string issueId;
    string serialNumber;
    uint256 numCredits;
    BlockRange blockRange;
    bool exists;
}

struct OffsetProject {
    string id;
    string name;
    uint256 numTokens;
    uint256 nextAvailableTokenIndex;
    uint256 pricePerCreditInWei;
    string[] issueIds;
    bool exists;
}

contract CarbonOffset {
    address immutable tokenAddress;
    address immutable adminAddress;

    string[] projectIds;
    mapping(string => OffsetProject) projects;

    string[] tokenIds;
    mapping(string => OffsetToken) tokens;

    mapping(string => OffsetCreditIssue) creditIssues;

    constructor() {
        tokenAddress = address(this);
        adminAddress = msg.sender;
    }

    // Custom modifiers
    modifier adminOnly() {
        require(adminAddress == msg.sender, '403');
        _; // Modifier should be executed before the code
    }

    modifier validProject(string memory _id, bool _exists) {
        require(
            projects[_id].exists == _exists,
            _exists ? 'Project does not exist' : 'Project already exists'
        );
        _;
    }

    modifier validIssue(string memory _id, bool _exists) {
        require(
            creditIssues[_id].exists == _exists,
            _exists
                ? 'Credit issue does not exist'
                : 'Credit issue already exists'
        );
        _;
    }

    // View Functions
    function getProjectIds() public view returns (string[] memory) {
        return projectIds;
    }

    function getTokenIds() public view returns (string[] memory) {
        return tokenIds;
    }

    function getProjectById(string memory _id)
        public
        view
        validProject(_id, true)
        returns (OffsetProject memory)
    {
        return projects[_id];
    }

    function getCreditIssueById(string memory _id)
        public
        view
        validIssue(_id, true)
        returns (OffsetCreditIssue memory)
    {
        return creditIssues[_id];
    }

    function getOffsetTokenById(string memory _id)
        public
        view
        returns (OffsetToken memory)
    {
        return tokens[_id];
    }

    // Admin Only Functions
    function registerOffsetProject(
        string memory _id,
        string memory _name,
        uint256 _pricePerCreditInWei
    ) external adminOnly validProject(_id, false) {
        string[] memory _issueIds;

        OffsetProject memory offsetProject = OffsetProject({
            id: _id,
            name: _name,
            numTokens: 0,
            nextAvailableTokenIndex: 0,
            pricePerCreditInWei: _pricePerCreditInWei,
            issueIds: _issueIds,
            exists: true
        });

        projectIds.push(_id);
        projects[_id] = offsetProject;
    }

    function registerCreditIssue(
        string memory _projectId,
        string memory _issueId,
        string memory _serialNumber,
        uint256 _numCredits
    )
        external
        adminOnly
        validProject(_projectId, true)
        validIssue(_issueId, false)
    {
        OffsetProject storage offsetProject = projects[_projectId];

        BlockRange memory issueBlockRange = BlockRange({
            start: offsetProject.numTokens,
            end: offsetProject.numTokens + _numCredits - 1
        });

        OffsetCreditIssue memory creditIssue = OffsetCreditIssue({
            issueId: _issueId,
            serialNumber: _serialNumber,
            numCredits: _numCredits,
            blockRange: issueBlockRange,
            exists: true
        });

        offsetProject.issueIds.push(_issueId);
        offsetProject.numTokens += _numCredits;

        creditIssues[_issueId] = creditIssue;
    }

    function purchaseOffsetToken(string memory _projectId, uint256 _numCredits)
        external
        payable
        validProject(_projectId, true)
    {
        OffsetProject storage offsetProject = projects[_projectId];
        require(
            offsetProject.numTokens - offsetProject.nextAvailableTokenIndex >=
                _numCredits,
            'Project has insufficient available tokens'
        );

        require(
            msg.value >= offsetProject.pricePerCreditInWei * _numCredits,
            'Insufficient value provided'
        );

        BlockRange memory blockRange = BlockRange({
            start: offsetProject.nextAvailableTokenIndex,
            end: offsetProject.nextAvailableTokenIndex + _numCredits - 1
        });

        string memory tokenId = generateOffsetTokenId(
            _projectId,
            blockRange.start,
            blockRange.end
        );

        OffsetToken memory offsetToken = OffsetToken({
            id: tokenId,
            payeeAddress: msg.sender,
            numCredits: _numCredits,
            blockRange: blockRange
        });

        tokenIds.push(tokenId);
        tokens[tokenId] = offsetToken;
        offsetProject.nextAvailableTokenIndex += _numCredits;
    }

    // Internal
    function generateOffsetTokenId(
        string memory _projectId,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _projectId,
                    '-',
                    Strings.toString(start),
                    '-',
                    Strings.toString(end)
                )
            );
    }

    // Functions in Tests
    function getAdminAddress() public view returns (address) {
        return adminAddress;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }
}
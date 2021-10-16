// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AccessControlTwoOfficers.sol";

interface SuSquares {
    function ownerOf(uint256) external view returns(address);
}

/// @title  Personalize your Su Squares that are unpersonalized on the main contract
/// @author William Entriken (https://phor.net)
contract SuSquaresUnderlay {
    SuSquares constant suSquares = SuSquares(0xE9e3F9cfc1A64DFca53614a0182CFAD56c10624F);
    uint256 constant pricePerSquare = 1e15; // 1 Finney

    struct Personalization {
        uint256 squareId;
        bytes rgbData;
        string title;
        string href;
    }

    event PersonalizedUnderlay(
        uint256 indexed squareId,
        bytes rgbData,
        string title,
        string href
    );

    /// @notice Update the contents of your Square on the underlay
    /// @param  squareId Your Square number, the top-left is 1, to its right is 2, ..., top-right is 100 and then 101 is
    ///                  below 1... the last one at bottom-right is 10000
    /// @param  rgbData  A 10x10 image for your square, in 8-bit RGB words ordered like the squares are ordered. See
    ///                  Imagemagick's command: convert -size 10x10 -depth 8 in.rgb out.png
    /// @param  title    A description of your square (max 64 bytes UTF-8)
    /// @param  href     A hyperlink for your square (max 96 bytes)
    function personalizeSquareUnderlay(
        uint256 squareId,
        bytes calldata rgbData,
        string calldata title,
        string calldata href
    )
        external payable
    {
        require(msg.value == pricePerSquare);
        _personalizeSquareUnderlay(squareId, rgbData, title, href);
    }

    /// @notice Update the contents of Square on the underlay
    /// @param  personalizations Each one is a the personalization for a single Square
    function personalizeSquareUnderlayBatch(Personalization[] calldata personalizations) external payable {
        require(personalizations.length > 0, "Missing personalizations");
        require(msg.value == pricePerSquare * personalizations.length);
        for(uint256 i=0; i<personalizations.length; i++) {
            _personalizeSquareUnderlay(
                personalizations[i].squareId,
                personalizations[i].rgbData,
                personalizations[i].title,
                personalizations[i].href
            );
        }
    }

    function _personalizeSquareUnderlay(
        uint256 squareId,
        bytes calldata rgbData,
        string calldata title,
        string calldata href
    ) private {
        require(suSquares.ownerOf(squareId) == msg.sender, "Only the Su Square owner may personalize underlay");
        require(rgbData.length == 300, "Pixel data must be 300 bytes: 3 colors (RGB) x 10 columns x 10 rows");
        require(bytes(title).length <= 64, "Title max 64 bytes");
        require(bytes(href).length <= 96, "HREF max 96 bytes");
        emit PersonalizedUnderlay(
            squareId,
            rgbData,
            title,
            href
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title  Role-based access control inspired by CryptoKitties
/// @dev    Keep the CEO wallet stored offline, I warned you.
/// @author William Entriken (https://phor.net)
abstract contract AccessControlTwoOfficers {
    /// @notice The account that can only reassign officer accounts
    address public executiveOfficer;

    /// @notice The account that can collect funds from this contract
    address payable public financialOfficer;

    constructor() {
        executiveOfficer = msg.sender;
    }

    /// @notice Reassign the executive officer role
    /// @param  newExecutiveOfficer new officer address
    function setExecutiveOfficer(address newExecutiveOfficer) external {
        require(msg.sender == executiveOfficer);
        require(newExecutiveOfficer != address(0));
        executiveOfficer = newExecutiveOfficer;
    }

    /// @notice Reassign the financial officer role
    /// @param  newFinancialOfficer new officer address
    function setFinancialOfficer(address payable newFinancialOfficer) external {
        require(msg.sender == executiveOfficer);
        require(newFinancialOfficer != address(0));
        financialOfficer = newFinancialOfficer;
    }

    /// @notice Collect funds from this contract
    function withdrawBalance() external {
        require(msg.sender == financialOfficer);
        financialOfficer.transfer(address(this).balance);
    }
}
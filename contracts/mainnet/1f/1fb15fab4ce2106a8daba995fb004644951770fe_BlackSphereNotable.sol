// contracts/BlackSphere.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BlackSphereCore.sol";
import "./Counters.sol";

/**
 * The notes contract for BlackSphere tokens.
 * The notes enables to different holders of tokens to add notes to their
 * Black Sphere tokens.
 * This may be used in the future.
 * It should be nice to have an onchain mechanism to change metadata when this data changes.
 */
contract BlackSphereNotable is BlackSphereCore {
    using Counters for Counters.Counter;
    Counters.Counter private _notesIds;

    // The BlackSphere can have notes from different holders.
    struct BlackSphereNote {
        address creator;
        uint64 creation;
        string note;
    }

    event NewBlackSphereNote(uint tokenId, BlackSphereNote blackSphereNote);

    // Mapping noteIds to its own Notes.
    mapping(uint256 => BlackSphereNote) private _notes;

    // Mapping the noteId to its own sphere.
    mapping(uint256 => uint256) private _notesToSpheres;

    // Mapping the blackSphereTokenId to a list of its noteIds.
    mapping(uint256 => uint256[]) private _sphereToNotes;

    /**
     * Adds a BlackSphereNote to this BlackSphere.

     * Requirements:
     *
     * - `tokenId` must exist.
     * - `msg.sender` must hold the token.
     */
    function addNote(uint256 tokenId, string memory note) public {
        require(_exists(tokenId), "BlackSphereNotable: nonexistent token.");
        require(
            ownerOf(tokenId) == _msgSender(),
            "BlackSphereNotable: caller is not the holder of the token."
        );

        BlackSphereNote memory _note = BlackSphereNote(
            _msgSender(),
            uint64(block.timestamp),
            note
        );
        _notesIds.increment();
        _notes[_notesIds.current()] = _note;
        _notesToSpheres[_notesIds.current()] = tokenId;
        _sphereToNotes[tokenId].push(_notesIds.current());
        emit NewBlackSphereNote(tokenId, _note);
    }

    /**
     * A view for showing all the Notes for an specific token.
     */
    function getNotes(uint256 tokenId)
        public
        view
        virtual
        returns (BlackSphereNote[] memory)
    {
        BlackSphereNote[] memory tokenNotes = new BlackSphereNote[](
            _sphereToNotes[tokenId].length
        );
        for (uint256 i = 0; i < _sphereToNotes[tokenId].length; i++) {
            tokenNotes[i] = _notes[_sphereToNotes[tokenId][i]];
        }
        return tokenNotes;
    }

}
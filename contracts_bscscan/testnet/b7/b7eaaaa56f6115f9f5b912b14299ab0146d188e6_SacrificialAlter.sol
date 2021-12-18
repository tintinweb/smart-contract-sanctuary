// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./ERC1155.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";
import "./ISacrificialAlter.sol";
import "./IGP.sol";


contract SacrificialAlter is ISacrificialAlter, ERC1155, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    struct TypeInfo {
        uint16 mints;
        uint16 burns;
        uint16 maxSupply;
        uint256 gpExchangeAmt;
    }
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWrite;

    mapping(uint256 => TypeInfo) private typeInfo;
    // storage of each image data
    mapping(uint256  => Image) public traitData;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // reference to the $GP contract for minting $GP earnings
    IGP public gpToken;

    constructor() ERC1155("") {
        _pause();
    }

    modifier disallowIfStateIsChanging() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWrite[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(gpToken) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _gp) external onlyOwner {
        gpToken = IGP(_gp);
    }

    /** 
    * Mint a token - any payment / game logic should be handled in the game contract. 
    */
    function mint(uint256 typeId, uint16 qty, address recipient) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(typeInfo[typeId].mints - typeInfo[typeId].burns + qty <= typeInfo[typeId].maxSupply, "All tokens minted");
        if(typeInfo[typeId].gpExchangeAmt > 0) {
            // If the ERC1155 is swapped for $GP, transfer the GP to this contract in case the swap back is desired.
            // NOTE: This will fail if the origin doesn't have the required amount of $GP
            gpToken.transferFrom(tx.origin, address(this), typeInfo[typeId].gpExchangeAmt * qty);
        }
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    /** 
    * Burn a token - any payment / game logic should be handled in the game contract. 
    */
    function burn(uint256 typeId, uint16 qty, address burnFrom) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        if(typeInfo[typeId].gpExchangeAmt > 0) {
            // If the ERC1155 was swapped from $GP, transfer the GP from this contract back to whoever owns this token now.
            gpToken.transferFrom(address(this), tx.origin, typeInfo[typeId].gpExchangeAmt * qty);
        }
        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }
    
    function setType(uint256 typeId, uint16 maxSupply) external onlyOwner {
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }
    
    function setExchangeAmt(uint256 typeId, uint256 exchangeAmt) external onlyOwner {
        require(typeInfo[typeId].maxSupply > 0, "this type has not been set up");
        typeInfo[typeId].gpExchangeAmt = exchangeAmt;
    }

    function updateOriginAccess() external override {
        require(admins[_msgSender()], "Only admins can call this");
        lastWrite[tx.origin].blockNum = uint64(block.number);
        lastWrite[tx.origin].time = uint64(block.timestamp);
    }

    /**
    * enables an address to mint / burn
    * @param addr the address to enable
    */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
    * disables an address from minting / burning
    * @param addr the address to disbale
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function setPaused(bool _paused) external onlyOwner requireContractsSet {
        if (_paused) _pause();
        else _unpause();
    }

    function getInfoForType(uint256 typeId) external view disallowIfStateIsChanging returns(TypeInfo memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            img.name,
            '", "description": "Mysterious items spawned from the Sacrificial Alter of the Wizards & Dragons Tower. Fabled to hold magical properties, only Act 1 tower guardians will know the truth in the following acts. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
            base64(bytes(drawSVG(typeId))),
            '", "attributes": []',
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }

    function uploadImage(uint256 typeId, Image calldata image) external onlyOwner {
        traitData[typeId] = Image(
            image.name,
            image.png
        );
    }

    function drawImage(Image memory image) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            image.png,
            '"/>'
        ));
    }

    function drawSVG(uint256 typeId) internal view returns (string memory) {
        string memory svgString = string(abi.encodePacked(
            drawImage(traitData[typeId])
        ));

        return string(abi.encodePacked(
            '<svg id="alter" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svgString,
            "</svg>"
        ));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, ISacrificialAlter) {
        // allow admin contracts to be send without approval
        if(!admins[_msgSender()]) {
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not owner nor approved"
            );
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /** SECURITEEEEEEE */
    
    function balanceOf(address account, uint256 id) public view virtual override(ERC1155, ISacrificialAlter) disallowIfStateIsChanging returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[account].blockNum < block.number, "hmmmm what doing?");
        return super.balanceOf(account, id);
    }
        
    /** BASE 64 - Written by Brech Devos */
    
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
        mstore(result, encodedLen)
        
        // prepare the lookup table
        let tablePtr := add(table, 1)
        
        // input ptr
        let dataPtr := data
        let endPtr := add(dataPtr, mload(data))
        
        // result ptr, jump over length
        let resultPtr := add(result, 32)
        
        // run over the input, 3 bytes at a time
        for {} lt(dataPtr, endPtr) {}
        {
            dataPtr := add(dataPtr, 3)
            
            // read 3 bytes
            let input := mload(dataPtr)
            
            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
            resultPtr := add(resultPtr, 1)
        }
        
        // padding with '='
        switch mod(mload(data), 3)
        case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
        case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
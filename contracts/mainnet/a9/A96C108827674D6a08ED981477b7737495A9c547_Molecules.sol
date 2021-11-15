// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IAtomReader.sol";
import "./interfaces/IPOWNFT.sol";
import "./interfaces/IERC721TokenReceiver.sol";

import "./libraries/Base64.sol";

contract Molecules{

    IAtomReader atomReader;
    IPOWNFT pownft;

    bytes32[] TOKENS;

    string[10] _subscripts = [
        unicode"₀",
        unicode"₁",
        unicode"₂",
        unicode"₃",
        unicode"₄",
        unicode"₅",
        unicode"₆",
        unicode"₇",
        unicode"₈",
        unicode"₉"
    ];
    string[119] elements = [ "", "H","He", "Li", "Be", "B", "C","N", "O", "F", "Ne", "Na","Mg", "Al", "Si", "P", "S","Cl", "Ar", "K", "Ca", "Sc","Ti", "V", "Cr", "Mn", "Fe","Co", "Ni", "Cu", "Zn", "Ga","Ge", "As", "Se", "Br", "Kr","Rb", "Sr", "Y", "Zr", "Nb","Mo", "Tc", "Ru", "Rh", "Pd","Ag", "Cd", "In", "Sn", "Sb","Te", "I", "Xe", "Cs", "Ba","La", "Ce", "Pr", "Nd", "Pm","Sm", "Eu", "Gd", "Tb", "Dy","Ho", "Er", "Tm", "Yb", "Lu","Hf", "Ta", "W", "Re", "Os","Ir", "Pt", "Au", "Hg", "Tl","Pb", "Bi", "Po", "At", "Rn","Fr", "Ra", "Ac", "Th", "Pa","U", "Np", "Pu", "Am", "Cm","Bk", "Cf", "Es", "Fm", "Md","No", "Lr", "Rf", "Db", "Sg","Bh", "Hs", "Mt", "Ds", "Rg","Cn", "Nh", "Fl", "Mc", "Lv","Ts", "Og"];

    mapping(bytes32 => uint8[32]) configs;


    address _contractOwner;

    constructor(address _pownft, address _atomReader){
        atomReader = IAtomReader(_atomReader);
        pownft = IPOWNFT(_pownft);

        _contractOwner = msg.sender;

        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; //ERC721Enumerable
        supportedInterfaces[0x01ffc9a7] = true; //ERC165
    }

    function switchOwner(address newOwner) public onlyOwner{
        _contractOwner = newOwner;
    }
    function owner() public view returns (address) {
        return _contractOwner;
    }

    modifier onlyOwner() {
        require(_contractOwner == msg.sender, "owner");
        _;
    }

    function initMolecules(uint8[][] calldata composition) public onlyOwner {
        for(uint i = 0; i < composition.length; i++){
            configs[configId(composition[i])] = toFixedLength(composition[i]);
        }
    }

    function configId(uint8[] memory composition) internal pure returns(bytes32) {
            return keccak256(abi.encode(composition));
    }
    function toFixedLength(uint8[] memory composition) internal pure returns(uint8[32] memory){
        uint8[32] memory _fixed;
        for(uint j = 0; j < composition.length; j++){
            require(composition[j] > 0 && composition[j] <= 118,"bad element");
            _fixed[j] = composition[j];
        }
        return _fixed;
    }
    function fromFixedLength(uint8[32] memory _fixed) internal pure returns(uint8[] memory){
        uint8[] memory _composition;
        for(uint j = 32; j > 0; j--){
            if(_composition.length > 0){
                _composition[j - 1] = _fixed[j - 1];
            }else if(_fixed[j - 1] != 0){
                _composition = new uint8[](j);
                _composition[j - 1] = _fixed[j - 1];
            }
        }
        return _composition;
    }

    function moleculeOf(uint _tokenId) public view returns(string memory){
        require(_tokenId > 0 && _tokenId <= TOKENS.length,"exists");
        return _getFormula(fromFixedLength(configs[TOKENS[_tokenId - 1]]));
    }

    function checkFormula(uint8[] calldata _composition) public view returns(string memory){
        require(configs[ configId(_composition)][0] != 0,"Molecule does not exist");
        return _getFormula(_composition);
    }

    function _getFormula(uint8[] memory _config) internal view returns(string memory){
        uint8 last;
        uint8 count = 0;
        string memory _formula;
        for(uint i = 0; i < _config.length; i++){
            if(_config[i] == last){
                count++;
            }else{
                if(count > 1){
                    _formula = string(abi.encodePacked(_formula,subscript(count),elements[_config[i]]));
                }else{
                    _formula = string(abi.encodePacked(_formula,elements[_config[i]]));
                }
                count = 1;
                last = _config[i];
            }
        }
        if(count > 1){
            _formula = string(abi.encodePacked(_formula,subscript(count)));
        }

        return _formula;
    }
    function subscript(uint value) internal view returns(string memory){
        if (value == 0) {
            return _subscripts[0];
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory _subscript = "";
        while (value != 0) {
            _subscript = abi.encodePacked(_subscripts[value%10],_subscript);
            value /= 10;
        }
        return string(_subscript);
    }

    function myMolecules(uint start_index, uint limit) public view returns(uint[] memory tokenIds, string[] memory formulas){
        uint balance = this.balanceOf(msg.sender);
        if(balance == 0){
            uint[] memory __tokenIds;
            string[] memory __formulas;
            return (__tokenIds,__formulas);
        }
        require(start_index < balance,"Invalid start index");

        uint sampleSize = balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds   = new uint[](sampleSize);
        string[] memory _formulas = new string[](sampleSize);

        for(uint i = 0; i < sampleSize; i++){
            _tokenIds[i] = tokenOfOwnerByIndex(msg.sender,i + start_index);
            _formulas[i] = moleculeOf(_tokenIds[i]);
        }

        return (_tokenIds, _formulas);
    }

    function myAtoms(uint start_index, uint limit) public view returns(uint[] memory tokenIds, uint8[] memory atomicNumbers){
        uint balance = pownft.balanceOf(msg.sender);
        if(balance == 0){
            uint[] memory __tokenIds;
            uint8[] memory __atomicNumbers;
            return (__tokenIds,__atomicNumbers);
        }
        require(start_index < balance,"Invalid start index");
        uint sampleSize = balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds       = new uint[](sampleSize);
        uint8[] memory _atomicNumbers = new uint8[](sampleSize);

        for(uint i = 0; i < sampleSize; i++){
            _tokenIds[i] = pownft.tokenOfOwnerByIndex(msg.sender,i + start_index);
            _atomicNumbers[i] = uint8(atomReader.getAtomicNumber(_tokenIds[i]));
        }

        return (_tokenIds, _atomicNumbers);
    }


    function claim(uint[] calldata _atomIds) public{
        require(TOKENS.length < pownft.totalSupply(),"totalSupply");

        uint8[] memory _composition = new uint8[](_atomIds.length);

        for(uint i = 0; i < _atomIds.length; i++){
            for(uint j = 0; j < i; j++){
                require(_atomIds[i] != _atomIds[j],"reuse");
            }
            _composition[i] = uint8(atomReader.getAtomicNumber(_atomIds[i]));

            require(pownft.ownerOf(_atomIds[i]) == msg.sender,"owner");
        }
        bytes32 _configId = configId(_composition);
        require(configs[_configId][0] != 0,"Molecule does not exist");


        TOKENS.push(_configId);

        uint tokenId = TOKENS.length;

        //Normal ERC721 mint stuff
        OWNERS[tokenId] = msg.sender;
        BALANCES[msg.sender]++;
        OWNER_ID_TO_INDEX[tokenId] = OWNER_INDEX_TO_ID[msg.sender].length;
        OWNER_INDEX_TO_ID[msg.sender].push(tokenId);

        emit Transfer(address(0),msg.sender,tokenId);
    }


    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(OWNERS[tokenId] != address(0),"invalid");

        string[3] memory parts;
        string memory formula = _getFormula(fromFixedLength(configs[TOKENS[tokenId - 1]]));

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: sans-serif; font-size: 30px; text-anchor: middle; dominant-baseline: central;}</style><rect width="100%" height="100%" fill="black" /><text x="175" y="175" class="base">';
        parts[1] = formula;
        parts[2] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', toString(tokenId), ' ',formula,'", "description": "POW NFT Molecules are made by combining POW NFT Atoms.", "attributes":[{"trait_type":"Formula","value":"',formula,'"}], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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




    // NORMAL STUFF

    //////===721 Standard
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //////===721 Implementation
    mapping(address => uint256) internal BALANCES;
    mapping (uint256 => address) internal ALLOWANCE;
    mapping (address => mapping (address => bool)) internal AUTHORISED;

    mapping(uint256 => address) OWNERS;  //Mapping of owners


    //    ENUMERABLE VARS
    mapping(address => uint[]) internal OWNER_INDEX_TO_ID;
    mapping(uint => uint) internal OWNER_ID_TO_INDEX;

    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return OWNERS[_tokenId] != address(0);
    }

    function balanceOf(address _owner) external view returns (uint256){
        return BALANCES[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return OWNERS[_tokenId];
    }


    function approve(address _approved, uint256 _tokenId)  external{
        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender                    //Require Sender Owns Token
            || AUTHORISED[_owner][msg.sender]                //  or is approved for all.
        ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        ALLOWANCE[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return ALLOWANCE[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return AUTHORISED[_owner][_operator];
    }


    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        AUTHORISED[msg.sender][_operator] = _approved;
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public {

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = ownerOf(_tokenId);

        require ( _owner == msg.sender             //Require sender owns token
        //Doing the two below manually instead of referring to the external methods saves gas
        || ALLOWANCE[_tokenId] == msg.sender      //or is approved for this token
            || AUTHORISED[_owner][msg.sender]          //or is approved for all
        ,"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        emit Transfer(_from, _to, _tokenId);


        OWNERS[_tokenId] =_to;

        BALANCES[_from]--;
        BALANCES[_to]++;

        //Reset approved if there is one
        if(ALLOWANCE[_tokenId] != address(0)){
            delete ALLOWANCE[_tokenId];
        }

        //Enumerable Additions
        uint oldIndex = OWNER_ID_TO_INDEX[_tokenId];
        //If the token isn't the last one in the owner's index
        if(oldIndex != OWNER_INDEX_TO_ID[_from].length - 1){
            //Move the old one in the index list
            OWNER_INDEX_TO_ID[_from][oldIndex] = OWNER_INDEX_TO_ID[_from][OWNER_INDEX_TO_ID[_from].length - 1];
            //Update the token's reference to its place in the index list
            OWNER_ID_TO_INDEX[OWNER_INDEX_TO_ID[_from][oldIndex]] = oldIndex;
        }
        OWNER_INDEX_TO_ID[_from].pop();

        OWNER_ID_TO_INDEX[_tokenId] = OWNER_INDEX_TO_ID[_to].length;
        OWNER_INDEX_TO_ID[_to].push(_tokenId);

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    function name() external pure returns (string memory _name){
        return "POW NFT Molecules";
    }

    function symbol() external pure returns (string memory _symbol){
        return "MOLECULE";
    }


    // ENUMERABLE FUNCTIONS
    function totalSupply() external view returns (uint256){
        return TOKENS.length;
    }

    function tokenByIndex(uint256 _index) external view returns(uint256){
        require(_index < TOKENS.length,"index");
        return _index + 1;
        //        return INDEX_TO_ID[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256){
        require(_index < BALANCES[_owner],"index");
        return OWNER_INDEX_TO_ID[_owner][_index];
    }

    // End 721 Implementation

    ///////===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165


}

//SPDX-License-Identifier: Licence to thrill
pragma solidity ^0.8.0;

/// @title POWNFT Atom Reader
/// @author AnAllergyToAnalogy
/// @notice On-chain calculation atomic number and ionisation data about POWNFT Atoms. Replicates functionality done off-chain for metadata.
interface IAtomReader{

    /// @notice Get atomic number and ionic charge of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return atomicNumber Atomic number of the Atom
    /// @return ionCharge Ionic charge of the Atom
    function getAtomData(uint _tokenId) external view returns(uint atomicNumber, int8 ionCharge);

    /// @notice Get atomic number of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return Atomic number of the Atom
    function getAtomicNumber(uint _tokenId) external view returns(uint);

    /// @notice Get ionic charge of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return ionic charge of the Atom
    function getIonCharge(uint _tokenId) external view returns(int8);

    /// @notice Get array of all possible ions for a specified element
    /// @param atomicNumber Atomic number of element to query
    /// @return Array of possible ionic charges
    function getIons(uint atomicNumber) external pure returns(int8[] memory);

    /// @notice Check if a given element can have a particular ionic charge
    /// @param atomicNumber Atomic number of element to query
    /// @param ionCharge Ionic charge to check
    /// @return True if this element can have this ion, false otherwise.
    function isValidIonCharge(uint atomicNumber, int8 ionCharge) external pure returns(bool);

    /// @notice Check if a given element has any potential ions
    /// @param atomicNumber Atomic number of element to query
    /// @return True if this element can ionise, false otherwise.
    function canIonise(uint atomicNumber) external pure returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPOWNFT{
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


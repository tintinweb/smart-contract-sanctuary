/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
}



interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    using Strings for uint256;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


/// [MIT License]
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
    
    function toString(uint256 value) internal pure returns (string memory) {
    
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
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    
    address private _rarityLandDao;
    
    uint256 private _claimFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        _rarityLandDao = _msgSender();
        _claimFee = 5*1e18;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function getClaimFee()public view returns(uint256){
        return _claimFee;
    }

    function getRarityLandDao()internal view returns(address){
        return _rarityLandDao;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function changeRarityLandDao(address newDao)public virtual onlyOwner {
        _rarityLandDao = newDao;
    }

    function changeClaimFee(uint256 newFee)public virtual onlyOwner {
        require(newFee >= _claimFee, "setClaimFee: newFee error .");
        _claimFee = newFee;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface rarity {
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function summoner(uint) external view returns (uint _xp, uint _log, uint _class, uint _level);
}

interface RarityLandStorage {
    function claimLand(uint256 summoner) external;
    function setLandState(uint256 summoner,bool state)external;
    function getMaxLands()external view returns (uint256 maxLands);
    function totalSupply() external view returns (uint256 supply);
    function setLandInfo(uint256 summoner,
                        string memory landName,
                        string memory landDes,
                        uint256 landIndexType, 
                        string memory landContentIndex) external;
    function setLandFee(uint256 summoner,uint256 fee)external;
    function changeSummoner(uint256 rlTokenID, uint256 newSummoner)external;
    function getLandFee(uint256 summoner)external view returns(bool,uint256);
    function getLandCoordinates(uint256 summoner) external view returns(bool,uint256 x,uint256 y);
    function getSummonerCoordinates(uint256 summoner)external view returns(bool,uint256 x,uint256 y);
    function getLandSummoners(uint256 summoner)external view returns(bool result,uint256 amount);
    function getLandIncome(uint256 summoner)external view returns(bool result,uint256 income);
    function getLandSize()external pure returns(uint256,uint256);
    function loadLandInfo(uint256 mySummoner, uint256 targetSummoner)external view returns (
        bool result, 
        string memory name,
        string memory des,
        uint256 indexType,
        string memory landContentIndex
        );
    function landState(uint256 summoner)external view returns(bool,bool);
    function increaseLands(uint256 lands)external;
    function loadLandInfo(uint256 targetSummoner)external view returns(
        bool result, 
        string memory name,
        string memory des,
        uint256 indexType,
        string memory landContentIndex
        );
    function getLandState(uint256 summoner)external view returns(bool,bool);
    function getLandIndex(uint256 summoner)external view returns(bool result,uint256 landIndex);
    function move(uint256 summoner,uint256 new_x,uint256 new_y) external returns(bool,uint256,uint256);
    function getSummoner(uint256 lIndex)external view returns(bool result,uint256 summoner);
}


contract RarityLand is ERC721, Ownable {
    //main-Rarity: 0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb
    rarity constant rm = rarity(0x17AC8A1155677151E2e26B5F79a24C44B1bFADAB);
    //main-Storage: 
    RarityLandStorage constant rls = RarityLandStorage(0xE42f9B878691874E08A4F41C720B033eca99EE1c);
    
    string constant public name = "Rarity Land";
    string constant public symbol = "RL";
    
    //state:public-Yes,private-NO
    function setLandState(uint256 summoner,bool state)public {
        require(isRarityOwner(summoner),"no owner .");
        return rls.setLandState(summoner,state);
    }
    
     //ticket fees
    function setLandFee(uint256 summoner,uint256 fee)public{
        require(isRarityOwner(summoner)," no owner .");
        rls.setLandFee(summoner,fee);
    }
    
    //claim, Summoner’s land
    function claim(uint256 summoner) public payable {
        require(isRarityOwner(summoner)," no owner .");

        uint256 fees = getClaimFee();
        require(fees <= msg.value," fee error !");
        payable(getRarityLandDao()).transfer(fees);

        _safeMint(_msgSender(), rls.totalSupply());
        rls.claimLand(summoner);
    }
    
    //move
    function move(uint256 summoner,uint256 new_x,uint256 new_y) public payable {
        require(isRarityOwner(summoner)," no owner .");
        (bool result,uint256 recSummoner,uint256 recFee) = rls.move(summoner,new_x,new_y);
        if(result){
            (,uint256 landFee) = getLandFee(recSummoner);
            require(landFee <= msg.value,"landFee error !");
            address recAddress = rm.ownerOf(recSummoner);
            payable(recAddress).transfer(recFee);
            payable(getRarityLandDao()).transfer(landFee - recFee);
        }
    }

    //Change summoner
    function changeSummoner(uint256 rlTokenID, uint256 newSummoner)public {
        require(ownerOf(rlTokenID) == _msgSender()," rl invalid .");
        require(isRarityOwner(newSummoner)," summoner invalid .");
        rls.changeSummoner(rlTokenID,newSummoner);
    }
    
    
    function getLandFee(uint256 summoner)public view returns(bool,uint256){
        return rls.getLandFee(summoner);
    }
    
    function getLandState(uint256 summoner)public view returns(bool,bool){
        return rls.getLandState(summoner);
    }

    //land location
    function getLandCoordinates(uint256 summoner) public view returns(bool,uint256 x,uint256 y){
        return rls.getLandCoordinates(summoner);
    }

    //no land,(0.0), has land,(x,1)
    function getSummonerCoordinates(uint256 summoner)public view returns(bool,uint256 x,uint256 y){
        return rls.getSummonerCoordinates(summoner);
    }

    //The number of summoners in the land
    function getLandSummoners(uint256 summoner)public view returns(bool result,uint256 amount) {
        return rls.getLandSummoners(summoner);
    }

    //land income.
    function getLandIncome(uint256 summoner)public view returns(bool result,uint256 income) {
        return rls.getLandIncome(summoner) ;
    }


    //(,isPubiic),isPubiic-Yes,isPubiic-NO
    function landState(uint256 summoner)public view returns(bool,bool){
        return rls.landState(summoner);
    }

    function getMaxLands()public view returns (uint256 maxLands){
        return rls.getMaxLands();
    }

    function totalSupply() public view returns (uint256 supply){
        return rls.totalSupply();
    }
    
    constructor() Ownable() {}

    function isRarityOwner(uint256 summoner) internal view returns (bool) {
        address rarityAddress = rm.ownerOf(summoner);
        return rarityAddress == msg.sender;
    }
    
    function tokenURI(uint256 rlTokenID) public view returns (string memory) {
        
        (bool s_result,uint256 summoner) = rls.getSummoner(rlTokenID);
        string memory output;
        {
        if(s_result){
            // has land
            string[10] memory parts;
            {
                (
                    , 
                    string memory s_name,
                    string memory s_des,
                    ,
                ) = rls.loadLandInfo(summoner);
                (,bool tLandState) = rls.getLandState(summoner);
                (,uint256 income) = rls.getLandIncome(summoner);
                (,uint256 sAmount) = rls.getLandSummoners(summoner);
                (,uint256 s_x,uint256 s_y) = rls.getSummonerCoordinates(summoner);
                parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
                parts[1] = string(abi.encodePacked("RarityLand##Summoner's land", '</text><text x="10" y="40" class="base">'));
                if(tLandState){
                    parts[2] = string(abi.encodePacked("Name:", " ", s_name, '</text><text x="10" y="60" class="base">'));
                }else{
                    parts[2] = string(abi.encodePacked("Name:", " ", "******", '</text><text x="10" y="60" class="base">'));
                }
                parts[3] = string(abi.encodePacked("Size:", " ", "1km * 1km", '</text><text x="10" y="80" class="base">'));
                parts[4] = string(abi.encodePacked("Land's coordinate:", " (",Base64.toString(rlTokenID * 1000),",",Base64.toString(0),")",  '</text><text x="10" y="100" class="base">'));
                parts[5] = string(abi.encodePacked("Summoner's coordinate:", " (",Base64.toString(s_x),",",Base64.toString(s_y),")",  '</text><text x="10" y="120" class="base">'));
                parts[6] = string(abi.encodePacked("Earn: ", Base64.toString(income/1e18), " ftm", '</text><text x="10" y="140" class="base">'));
                parts[7] = string(abi.encodePacked("Summoner: ","there are ",Base64.toString(sAmount)," summoners in my land.", '</text><text x="10" y="160" class="base">'));
                parts[8] = string(abi.encodePacked("Des:", " ", s_des, '</text><text x="10" y="180" class="base">'));
                parts[9] = '</text></svg>';
            }
            output = string(abi.encodePacked(   parts[0], 
                                                parts[1], 
                                                parts[2],
                                                parts[3], 
                                                parts[4], 
                                                parts[5],
                                                parts[6],
                                                parts[7],
                                                parts[8],
                                                parts[9]
                                            )
                            );
        }else{
            //no land
            string[4] memory parts;
            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
            parts[1] = string(abi.encodePacked("RarityLand##Summoner's land", '</text><text x="10" y="40" class="base">'));
            parts[2] = string(abi.encodePacked("Des:", " ", "You have no land .", '</text><text x="10" y="60" class="base">'));
            parts[3] = '</text></svg>';
            output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        }
        }

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "RarityLand', '", "description": "RarityLand is the land of the summoner, you can build here and earn money.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}
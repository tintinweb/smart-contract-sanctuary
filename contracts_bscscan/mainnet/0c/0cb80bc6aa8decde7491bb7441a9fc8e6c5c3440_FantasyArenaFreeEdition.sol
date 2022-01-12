/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
                                                                                                                                                       
                                 ++++++++        *****.        +****      =***    +++++++++++       *****=            ****      *****    =***          
                                 *@@@@@@@%       #@@@@%         @@@@%      @@#   #@@@@@@@@@@%       *@@@@@         #@@@@@@@@     @@@@#   :@@*          
                      *    *     *@@@%   -       @@@@@@=        %@@@@%     %@#   .  :@@@@:  +       %@@@@@*       #@@@#    -     :@@@@+  %@%           
                     +:    *     *@@@%          *@@#@@@%        %@@@@@@    %@#       @@@@          [email protected]@#@@@@       %@@@%           *@@@@.*@@            
                     =:    -=    *@@@%          @@* @@@@*       %@%@@@@@   %@#       @@@@          %@# %@@@#      *@@@@@%          %@@@@@@             
                    *-.    =:    *@@@@@@#      *@@  *@@@@       %@#=%@@@@  %@#       @@@@         [email protected]@  [email protected]@@@       [email protected]@@@@@@%        %@@@@*             
        *- *        *=.    +-=   *@@@%  +      @@%###@@@@*      %@#  %@@@@*%@#       @@@@         %@@###@@@@#         %@@@@@@       [email protected]@@@              
      #=   ###   %#=*=     +=+   *@@@%        *@@%%%%%@@@@      %@#   #@@@@@@#       @@@@        [email protected]@%%%%%@@@@           [email protected]@@@#      [email protected]@@%              
    ##+     #   :%#*#+---- *+    *@@@%        @@*     %@@@#     %@#    #@@@@@*       @@@@        %@#     %@@@%           #@@@#      [email protected]@@%              
    ##           #*#**+=---.+    *@@@%       *@@      [email protected]@@@     %@#     *@@@@*       @@@@       *@@      [email protected]@@@    %%*   *@@@%       [email protected]@@@              
   ##*            **==++==++     #@@@@      [email protected]@@      *@@@@%    @@@       *@@*      [email protected]@@@#      @@@      [email protected]@@@@   +%@@@@@@%.        #@@@@=             
   ##*           #***-=++--:                                                                                                                           
   ###+           +=+==+**                                                                                                                             
    %##       %#  =:-++**+                        %@@@@+        *@@@@@@@@%:      #@@@@@@@@     @@@@#      %@@        #@@@@%                            
     %%#     #%* .=..*+=+-:                       %@@@@@        [email protected]@@@*#@@@@#     [email protected]@@@***%     *@@@@%     *@%        #@@@@@                            
      #%#*   %%#*=*:+**+=--                      [email protected]@@@@@*       [email protected]@@@  [email protected]@@@     [email protected]@@@         *@@@@@%    *@%        @@%@@@%                           
        ####*%%#***+     *+                      @@*[email protected]@@@       [email protected]@@@  [email protected]@@%     [email protected]@@@         *@@@@@@%   *@%       #@%[email protected]@@@=                          
               %##                              *@%  %@@@#      [email protected]@@@  %@@%      [email protected]@@@%%%      *@@[email protected]@@@@  *@%       @@  *@@@%                          
               %%#                              @@#  #@@@@      [email protected]@@@%@@@*       [email protected]@@@##%      *@@  %@@@@+*@%      #@%  [email protected]@@@+                         
                ##*                            *@@@@@@@@@@#     [email protected]@@@*@@@@       [email protected]@@@         *@@   %@@@@%@%      @@@@@@@@@@@                         
                #                              @@*    [email protected]@@@     [email protected]@@@-#@@@@      [email protected]@@@         *@@    %@@@@@%     #@%     @@@@*                        
                %                             *@@      %@@@%    [email protected]@@@  %@@@%     [email protected]@@@     +   *@@     #@@@@%    [email protected]@:     *@@@@                        
                                              @@#      *@@@@=   [email protected]@@@   %@@@%    *@@@@@@@@@*   #@@      :%@@%    %@@      [email protected]@@@#                       
                                                                          #:                               *#                                          
                                                                                                                                                       

*/
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract FantasyArenaFreeEdition is IERC721, IERC721Metadata, IERC721Enumerable, IERC165 {
    using Address for address;

    address public owner;
    string public override name;
    string public override symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(uint256 => bool)) private _minted;
    mapping(uint256 => uint256) private _tokenUriIndexes;
    mapping(address => uint256[]) _addressOwners;
    string[] private _freeTokenUris;
    uint256[] private _tokenIds;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    constructor() {
        name = "Fantasy Arena Free Edition";
        symbol = "FA-FREE";
        owner = msg.sender;

        _freeTokenUris.push("https://www.fantasyarena.io/wp-json/free-edition/v1/uri/1");
        _freeTokenUris.push("https://www.fantasyarena.io/wp-json/free-edition/v1/uri/2");
        _freeTokenUris.push("https://www.fantasyarena.io/wp-json/free-edition/v1/uri/3");
        _freeTokenUris.push("https://www.fantasyarena.io/wp-json/free-edition/v1/uri/4");
    }

    function claimToken(uint256 index) public {
        require(index < _freeTokenUris.length, "This is not a valid token");
        require(hasClaimed(msg.sender, index) == false, "You have already claimed this token");
        _tokenUriIndexes[_tokenIds.length] = index;
        _minted[msg.sender][index] = true;
        _safeMint(msg.sender, _tokenIds.length);
    }

    function hasClaimed(address who, uint256 index) public view returns (bool) {
        return _minted[who][index];
    }

    function tokenOf(address who) public view returns (string[] memory uris) {
        string[] memory tokenUris = new string[](_addressOwners[who].length);
        for (uint256 i = 0; i < _addressOwners[who].length; i++) {
            tokenUris[i] = _freeTokenUris[_tokenUriIndexes[_addressOwners[who][i]]];
        }
        return tokenUris;
    }

    function totalSupply() external override view returns (uint256) {
        return _tokenIds.length;
    }

    function tokenOfOwnerByIndex(address who, uint256 index) external override view returns (uint256 tokenId) {
        return _addressOwners[who][index];
    }

    function tokenByIndex(uint256 index) external override view returns (uint256) {
        return _tokenIds[index];
    }

    function balanceOf(address who) public view override returns (uint256) {
        require(who != address(0), "ERC721: balance query for the zero address");
        return _balances[who];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address who = _owners[tokenId];
        require(who != address(0), "ERC721: owner query for nonexistent token");
        return who;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _freeTokenUris[_tokenUriIndexes[tokenId]];
    }

    function approve(address, uint256) public payable override {
        revert("This NFT is not approvable");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return address(0);
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("This NFT is not approvable");
    }

    function isApprovedForAll(address, address) public pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public payable override {
        revert("This NFT is not transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public payable override {
        revert("This NFT is not transferable");
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }


    // Admin Methods

    function setOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function addNewNft(string memory uri) public onlyOwner {
        _freeTokenUris.push(uri);
    }

    // Private Methods

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenIds.push(tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        _addressOwners[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}